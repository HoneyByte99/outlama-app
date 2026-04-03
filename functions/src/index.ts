import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as logger from 'firebase-functions/logger';
import { assertAdminClaim, assertAuthenticated, requireBoolean, requireString } from './common';

admin.initializeApp();
const db = admin.firestore();

// ---------------------------------------------------------------------------
// Push notification helper
// ---------------------------------------------------------------------------

async function sendPushToUsers(
  uids: string[],
  notification: { title: string; body: string }
): Promise<void> {
  if (uids.length === 0) return;

  // Fetch push tokens from user documents
  const snapshots = await Promise.all(
    uids.map(uid => db.collection('users').doc(uid).get())
  );

  const tokens: string[] = [];
  for (const snap of snapshots) {
    const token = snap.data()?.pushToken as string | undefined;
    if (token) tokens.push(token);
  }

  if (tokens.length === 0) return;

  // Send multicast
  const result = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  });

  logger.info('Push sent', {
    successCount: result.successCount,
    failureCount: result.failureCount,
  });
}

// ---------------------------------------------------------------------------
// In-app notification helper
// ---------------------------------------------------------------------------

async function createNotification(
  uid: string,
  data: {
    type: string;
    title: string;
    body: string;
    bookingId?: string;
    chatId?: string;
  }
): Promise<void> {
  await db
    .collection('notifications')
    .doc(uid)
    .collection('items')
    .add({
      type: data.type,
      title: data.title,
      body: data.body,
      bookingId: data.bookingId ?? null,
      chatId: data.chatId ?? null,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

type BookingStatus =
  | 'requested'
  | 'accepted'
  | 'rejected'
  | 'cancelled'
  | 'in_progress'
  | 'done';

function chatIdForBooking(bookingId: string): string {
  return `chat_${bookingId}`;
}

export const createBooking = onCall(async (request) => {
  const uid = request.auth?.uid;
  assertAuthenticated(uid);

  const providerId = requireString(request.data?.providerId, 'providerId');
  const serviceId = requireString(request.data?.serviceId, 'serviceId');
  const requestMessage = requireString(request.data?.requestMessage, 'requestMessage');

  // schedule/addressSnapshot are intentionally permissive for MVP; validate in app + tighten later.
  const schedule = request.data?.schedule ?? null;
  const addressSnapshot = request.data?.addressSnapshot ?? null;

  const bookingRef = db.collection('bookings').doc();
  await bookingRef.set({
    customerId: uid,
    providerId,
    serviceId,
    status: 'requested' as BookingStatus,
    requestMessage,
    schedule,
    addressSnapshot,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { bookingId: bookingRef.id };
});

export const acceptBooking = onCall(async (request) => {
  const uid = request.auth?.uid;
  assertAuthenticated(uid);

  const bookingId = requireString(request.data?.bookingId, 'bookingId');
  const bookingRef = db.collection('bookings').doc(bookingId);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(bookingRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');

    const booking = snap.data() as {
      customerId?: string;
      providerId?: string;
      status?: BookingStatus;
      chatId?: string;
    };

    if (!booking.providerId || !booking.customerId) {
      throw new HttpsError('failed-precondition', 'Booking is missing required fields.');
    }

    if (booking.status !== 'requested') {
      throw new HttpsError(
        'failed-precondition',
        `Booking is not requested (status=${booking.status ?? 'unknown'}).`
      );
    }

    // Provider-only accept (admins can bypass)
    const isAdmin = request.auth?.token?.admin === true;
    if (!isAdmin && booking.providerId !== uid) {
      throw new HttpsError('permission-denied', 'Only the provider can accept this booking.');
    }

    const chatId = booking.chatId ?? chatIdForBooking(bookingId);
    const chatRef = db.collection('chats').doc(chatId);

    // Create chat only on accept (booking-gated chat)
    tx.set(
      chatRef,
      {
        bookingId,
        participantIds: [booking.customerId, booking.providerId],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastMessageAt: null
      },
      { merge: true }
    );

    tx.update(bookingRef, {
      status: 'accepted' as BookingStatus,
      acceptedAt: admin.firestore.FieldValue.serverTimestamp(),
      chatId
    });

    return { bookingId, chatId };
  });

  return result;
});

export const rejectBooking = onCall(async (request) => {
  const uid = request.auth?.uid;
  assertAuthenticated(uid);

  const bookingId = requireString(request.data?.bookingId, 'bookingId');
  const bookingRef = db.collection('bookings').doc(bookingId);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(bookingRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');

    const booking = snap.data() as {
      providerId?: string;
      status?: BookingStatus;
    };

    if (!booking.providerId) {
      throw new HttpsError('failed-precondition', 'Booking is missing providerId.');
    }

    if (booking.status !== 'requested') {
      throw new HttpsError(
        'failed-precondition',
        `Booking is not requested (status=${booking.status ?? 'unknown'}).`
      );
    }

    const isAdmin = request.auth?.token?.admin === true;
    if (!isAdmin && booking.providerId !== uid) {
      throw new HttpsError('permission-denied', 'Only the provider can reject this booking.');
    }

    // IMPORTANT: do NOT create a chat on reject.
    tx.update(bookingRef, {
      status: 'rejected' as BookingStatus,
      rejectedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { bookingId };
  });

  return result;
});

export const onMessageCreate = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const { chatId } = event.params;
    const message = event.data?.data() as {
      senderId?: string;
      text?: string;
    } | undefined;

    if (!message) return;

    // Get chat to find participants and bookingId
    const chatSnap = await db.collection('chats').doc(chatId).get();
    if (!chatSnap.exists) return;
    const chat = chatSnap.data() as {
      participantIds?: string[];
      bookingId?: string;
    };
    const participants = chat.participantIds ?? [];
    const bookingId = chat.bookingId;

    // Update lastMessageAt on the chat document
    await db.collection('chats').doc(chatId).update({
      lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Notify all participants except the sender
    const recipients = participants.filter(uid => uid !== message.senderId);
    const notifTitle = 'Nouveau message';
    const notifBody = message.text ?? 'Message reçu';

    await sendPushToUsers(recipients, {
      title: notifTitle,
      body: notifBody,
    });

    for (const uid of recipients) {
      await createNotification(uid, {
        type: 'new_message',
        title: notifTitle,
        body: notifBody,
        chatId,
        bookingId,
      });
    }
  }
);

export const onBookingStatusChange = onDocumentUpdated(
  'bookings/{bookingId}',
  async (event) => {
    const before = event.data?.before.data() as {
      status?: string;
      customerId?: string;
      providerId?: string;
    } | undefined;
    const after = event.data?.after.data() as {
      status?: string;
      customerId?: string;
      providerId?: string;
    } | undefined;

    if (!before || !after) return;
    if (before.status === after.status) return;

    const { customerId, providerId } = after;
    const status = after.status;

    logger.info('Booking status changed', { from: before.status, to: status });

    const bookingId = event.params.bookingId;

    type NotifEntry = {
      uids: string[];
      type: string;
      title: string;
      body: string;
    };
    const notifications: NotifEntry[] = [];

    switch (status) {
      case 'accepted':
        if (customerId) {
          notifications.push({
            uids: [customerId],
            type: 'booking_accepted',
            title: 'Demande acceptée',
            body: 'Votre prestataire a accepté votre demande. Vous pouvez maintenant discuter.',
          });
        }
        break;
      case 'rejected':
        if (customerId) {
          notifications.push({
            uids: [customerId],
            type: 'booking_rejected',
            title: 'Demande refusée',
            body: 'Votre demande a été refusée. Vous pouvez en soumettre une nouvelle.',
          });
        }
        break;
      case 'in_progress':
        if (customerId) {
          notifications.push({
            uids: [customerId],
            type: 'booking_in_progress',
            title: 'Service démarré',
            body: 'Votre prestataire a démarré le service.',
          });
        }
        break;
      case 'done':
        if (customerId) {
          notifications.push({
            uids: [customerId],
            type: 'booking_done',
            title: 'Service terminé',
            body: 'Le service est terminé. Laissez un avis !',
          });
        }
        if (providerId) {
          notifications.push({
            uids: [providerId],
            type: 'booking_done',
            title: 'Service terminé',
            body: 'Le service est marqué comme terminé. Laissez un avis au client !',
          });
        }
        break;
    }

    for (const n of notifications) {
      await sendPushToUsers(n.uids, { title: n.title, body: n.body });
      for (const uid of n.uids) {
        await createNotification(uid, {
          type: n.type,
          title: n.title,
          body: n.body,
          bookingId,
        });
      }
    }
  }
);

export const cancelBooking = onCall(async (request) => {
  const uid = request.auth?.uid;
  assertAuthenticated(uid);

  const bookingId = requireString(request.data?.bookingId, 'bookingId');
  const bookingRef = db.collection('bookings').doc(bookingId);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(bookingRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');

    const booking = snap.data() as {
      customerId?: string;
      providerId?: string;
      status?: BookingStatus;
    };

    if (!booking.customerId || !booking.providerId) {
      throw new HttpsError('failed-precondition', 'Booking is missing required fields.');
    }

    if (booking.status !== 'requested') {
      throw new HttpsError(
        'failed-precondition',
        `Booking cannot be cancelled from status=${booking.status ?? 'unknown'}.`
      );
    }

    const isAdmin = request.auth?.token?.admin === true;
    if (!isAdmin && booking.customerId !== uid && booking.providerId !== uid) {
      throw new HttpsError('permission-denied', 'Only a booking participant can cancel.');
    }

    tx.update(bookingRef, {
      status: 'cancelled' as BookingStatus,
      cancelledAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { bookingId };
  });

  return result;
});

export const markInProgress = onCall(async (request) => {
  const uid = request.auth?.uid;
  assertAuthenticated(uid);

  const bookingId = requireString(request.data?.bookingId, 'bookingId');
  const bookingRef = db.collection('bookings').doc(bookingId);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(bookingRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');

    const booking = snap.data() as {
      providerId?: string;
      status?: BookingStatus;
    };

    if (!booking.providerId) {
      throw new HttpsError('failed-precondition', 'Booking is missing providerId.');
    }

    if (booking.status !== 'accepted') {
      throw new HttpsError(
        'failed-precondition',
        `Booking is not accepted (status=${booking.status ?? 'unknown'}).`
      );
    }

    const isAdmin = request.auth?.token?.admin === true;
    if (!isAdmin && booking.providerId !== uid) {
      throw new HttpsError('permission-denied', 'Only the provider can mark a booking in progress.');
    }

    tx.update(bookingRef, {
      status: 'in_progress' as BookingStatus,
      startedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { bookingId };
  });

  return result;
});

export const confirmDone = onCall(async (request) => {
  const uid = request.auth?.uid;
  assertAuthenticated(uid);

  const bookingId = requireString(request.data?.bookingId, 'bookingId');
  const bookingRef = db.collection('bookings').doc(bookingId);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(bookingRef);
    if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');

    const booking = snap.data() as {
      customerId?: string;
      status?: BookingStatus;
    };

    if (!booking.customerId) {
      throw new HttpsError('failed-precondition', 'Booking is missing customerId.');
    }

    if (booking.status !== 'in_progress') {
      throw new HttpsError(
        'failed-precondition',
        `Booking is not in_progress (status=${booking.status ?? 'unknown'}).`
      );
    }

    const isAdmin = request.auth?.token?.admin === true;
    if (!isAdmin && booking.customerId !== uid) {
      throw new HttpsError('permission-denied', 'Only the client can confirm the booking as done.');
    }

    tx.update(bookingRef, {
      status: 'done' as BookingStatus,
      doneAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { bookingId };
  });

  return result;
});

export const setAdminClaim = onCall(async (request) => {
  const callerUid = request.auth?.uid;
  assertAuthenticated(callerUid);

  assertAdminClaim(request.auth?.token?.admin);

  const targetUid = requireString(request.data?.uid, 'uid');
  const isAdmin = requireBoolean(request.data?.admin, 'admin');

  await admin.auth().setCustomUserClaims(targetUid, { admin: isAdmin });

  return { uid: targetUid, admin: isAdmin };
});
