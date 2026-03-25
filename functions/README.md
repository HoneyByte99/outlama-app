# Outlama — Cloud Functions (Gen 2)

This directory contains Firebase **Cloud Functions Gen 2** implemented in **TypeScript**.

## Prerequisites

- Node.js 20
- Firebase CLI installed (`npm i -g firebase-tools`)
- Logged in to Firebase (`firebase login`)

## Install

```bash
cd functions
npm install
```

## Lint & Build

```bash
npm run lint
npm run build
```

## Emulators (Functions only)

From `functions/`:

```bash
npm run serve
```

> Note: You will typically also run Firestore/Auth emulators depending on your local setup.

## Deploy

From `functions/` (uses `../firebase.json`):

```bash
npm run deploy
```

## Implemented functions

- `createBooking` (HTTPS callable): creates a booking with status `pending`.
- `acceptBooking` / `rejectBooking` (HTTPS callable): provider-only actions.
  - **Booking-gated chat**: a chat is created **only on accept**.
- `onMessageCreate` (Firestore trigger): `chats/{chatId}/messages/{messageId}`
  - Placeholder for notifications (currently logs only; do not ship secrets here).
- `setAdminClaim` (HTTPS callable): **admin-only**; sets custom claim `{ admin: true }`.

## Data model (minimal contract)

Collections used by these functions:

- `bookings/{bookingId}`
  - `customerId: string`
  - `providerId: string`
  - `status: 'pending' | 'accepted' | 'rejected'`
  - `createdAt: Timestamp`
  - `acceptedAt?: Timestamp`
  - `rejectedAt?: Timestamp`
  - `chatId?: string`
- `chats/{chatId}`
  - `bookingId: string`
  - `customerId: string`
  - `providerId: string`
  - `createdAt: Timestamp`

The `chatId` is deterministic: `chat_${bookingId}`.
