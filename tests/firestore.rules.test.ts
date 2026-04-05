/**
 * Firestore security rules tests.
 *
 * Prerequisites:
 *   firebase emulators:start --only firestore
 *   (from the tests/ directory) npm install && npm test
 */

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';
import {
  collectionGroup,
  doc,
  getDoc,
  getDocs,
  query,
  orderBy,
  limit,
  where,
  setDoc,
} from 'firebase/firestore';
import { afterAll, beforeAll, describe, it } from 'vitest';

const __dirname = dirname(fileURLToPath(import.meta.url));
const RULES_PATH = resolve(__dirname, '../firebase/firestore.rules');

let testEnv: RulesTestEnvironment;

// ---------------------------------------------------------------------------
// Setup / teardown
// ---------------------------------------------------------------------------

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'outalmaservice-d1e59',
    firestore: {
      rules: readFileSync(RULES_PATH, 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });

  // Seed all fixtures once — rules tests care about auth claims, not data shape.
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    // user_sessions fixtures
    await setDoc(doc(db, 'user_sessions/u1'), { uid: 'u1', lastPlatform: 'android' });
    await setDoc(doc(db, 'user_sessions/u1/events/e1'), {
      uid: 'u1', platform: 'android', ip: '1.2.3.4',
      countryCode: 'FR', country: 'France', loggedAt: new Date(),
    });
    await setDoc(doc(db, 'user_sessions/u2'), { uid: 'u2', lastPlatform: 'ios' });
    await setDoc(doc(db, 'user_sessions/u2/events/e2'), {
      uid: 'u2', platform: 'ios', ip: '5.6.7.8',
      countryCode: 'SN', country: 'Sénégal', loggedAt: new Date(),
    });

    // user_roles fixture
    await setDoc(doc(db, 'user_roles/admin-uid'), { uid: 'admin-uid', admin: true });

    // users fixture
    await setDoc(doc(db, 'users/user1'), { id: 'user1', email: 'user1@example.com' });
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const admin = () => testEnv.authenticatedContext('admin-uid', { admin: true });
const moderator = () => testEnv.authenticatedContext('mod-uid', { moderator: true });
const user = (uid = 'user-uid') => testEnv.authenticatedContext(uid);
const anon = () => testEnv.unauthenticatedContext();

// ---------------------------------------------------------------------------
// user_sessions — direct reads
// ---------------------------------------------------------------------------

describe('user_sessions — direct reads', () => {
  it('admin can read summary doc', async () => {
    await assertSucceeds(getDoc(doc(admin().firestore(), 'user_sessions/u1')));
  });

  it('admin can read event sub-doc', async () => {
    await assertSucceeds(getDoc(doc(admin().firestore(), 'user_sessions/u1/events/e1')));
  });

  it('regular user cannot read another user session doc', async () => {
    await assertFails(getDoc(doc(user('other').firestore(), 'user_sessions/u1')));
  });

  it('anonymous user cannot read session doc', async () => {
    await assertFails(getDoc(doc(anon().firestore(), 'user_sessions/u1')));
  });

  it('moderator cannot read session docs', async () => {
    await assertFails(getDoc(doc(moderator().firestore(), 'user_sessions/u1')));
  });
});

// ---------------------------------------------------------------------------
// user_sessions — collection group queries
// ---------------------------------------------------------------------------

describe('user_sessions — collection group query on events', () => {
  it('admin can query collectionGroup events ordered by loggedAt', async () => {
    await assertSucceeds(
      getDocs(query(
        collectionGroup(admin().firestore(), 'events'),
        orderBy('loggedAt', 'desc'),
        limit(10),
      ))
    );
  });

  it('admin can query collectionGroup events with platform filter', async () => {
    await assertSucceeds(
      getDocs(query(
        collectionGroup(admin().firestore(), 'events'),
        where('platform', '==', 'android'),
        orderBy('loggedAt', 'desc'),
        limit(10),
      ))
    );
  });

  it('regular user cannot query collectionGroup events', async () => {
    await assertFails(
      getDocs(query(
        collectionGroup(user().firestore(), 'events'),
        orderBy('loggedAt', 'desc'),
        limit(10),
      ))
    );
  });

  it('anonymous user cannot query collectionGroup events', async () => {
    await assertFails(
      getDocs(query(
        collectionGroup(anon().firestore(), 'events'),
        orderBy('loggedAt', 'desc'),
        limit(10),
      ))
    );
  });

  it('moderator cannot query collectionGroup events', async () => {
    await assertFails(
      getDocs(query(
        collectionGroup(moderator().firestore(), 'events'),
        orderBy('loggedAt', 'desc'),
        limit(10),
      ))
    );
  });
});

// ---------------------------------------------------------------------------
// user_sessions — write protection
// ---------------------------------------------------------------------------

describe('user_sessions — write protection', () => {
  it('admin cannot write session doc from client', async () => {
    await assertFails(
      setDoc(doc(admin().firestore(), 'user_sessions/u1'), { uid: 'u1' })
    );
  });

  it('admin cannot write event doc from client', async () => {
    await assertFails(
      setDoc(doc(admin().firestore(), 'user_sessions/u1/events/new'), {
        uid: 'u1', loggedAt: new Date(),
      })
    );
  });

  it('regular user cannot write session doc', async () => {
    await assertFails(
      setDoc(doc(user().firestore(), 'user_sessions/user-uid'), { uid: 'user-uid' })
    );
  });
});

// ---------------------------------------------------------------------------
// user_roles — admin-only
// ---------------------------------------------------------------------------

describe('user_roles', () => {
  it('admin can read user_roles', async () => {
    await assertSucceeds(getDoc(doc(admin().firestore(), 'user_roles/admin-uid')));
  });

  it('moderator cannot read user_roles', async () => {
    await assertFails(getDoc(doc(moderator().firestore(), 'user_roles/admin-uid')));
  });

  it('regular user cannot read user_roles', async () => {
    await assertFails(getDoc(doc(user().firestore(), 'user_roles/admin-uid')));
  });

  it('nobody can write user_roles from client (even admin)', async () => {
    await assertFails(
      setDoc(doc(admin().firestore(), 'user_roles/someone'), { uid: 'someone', admin: true })
    );
  });
});

// ---------------------------------------------------------------------------
// users — signed-in read, self-or-admin write
// ---------------------------------------------------------------------------

describe('users', () => {
  it('signed-in user can read any user doc', async () => {
    await assertSucceeds(getDoc(doc(user('other').firestore(), 'users/user1')));
  });

  it('anonymous user cannot read user doc', async () => {
    await assertFails(getDoc(doc(anon().firestore(), 'users/user1')));
  });

  it('user can update own doc', async () => {
    await assertSucceeds(
      setDoc(doc(user('user1').firestore(), 'users/user1'),
        { id: 'user1', email: 'new@example.com' }, { merge: true })
    );
  });

  it('user cannot update another user doc', async () => {
    await assertFails(
      setDoc(doc(user('user2').firestore(), 'users/user1'),
        { email: 'hack@example.com' }, { merge: true })
    );
  });
});
