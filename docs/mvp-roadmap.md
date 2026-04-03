# MVP Roadmap

Outalma MVP — France + Senegal, Android + iOS + Web.

---

## Phase 1 — Backend integrity (current blocker)

Nothing can be built on top of misaligned contracts. This phase has no UI.

- [ ] Align `BookingStatus` enum: `requested | accepted | in_progress | done | rejected | cancelled`
- [ ] Complete `Booking` model: add `customerId`, `providerId`, `requestMessage`, `schedule`, `addressSnapshot`, `chatId`, `acceptedAt`, `rejectedAt`, `doneAt` — remove `userId`, `updatedAt`
- [ ] Complete `AppUser` model: add `activeMode`, `country`, `phoneE164`, `pushToken` — rename `photoUrl → photoPath`
- [ ] Complete `Service` model: rename `ownerId → providerId`, add `categoryId`, `photos`, `published`, `priceType`, `serviceArea` — replace `priceCents` with `price`
- [ ] Add `Chat` model + Firestore converter (`chats/{chatId}`)
- [ ] Add `Provider` model + Firestore converter (`providers/{uid}`)
- [ ] Add `Review` model + Firestore converter (`reviews/{reviewId}`)
- [ ] Add `PhoneShare` + `Report` models
- [ ] Remove redundant `fromJson` on models — converters are the single deserialization path
- [ ] Implement `FirestoreUserRepository`
- [ ] Implement `FirestoreBookingRepository`
- [ ] Implement `FirestoreServiceRepository`
- [ ] Implement `FirestoreChatRepository`
- [ ] Add serialization tests (BookingStatus roundtrip, Timestamp variants, null safety)
- [ ] Add booking state machine unit tests
- [ ] Add Cloud Functions: `cancelBooking`, `markInProgress`, `confirmDone`
- [ ] Add Cloud Functions trigger: `onBookingStatusChange` → push notification

---

## Phase 2 — Auth + app shell

First pixels. Design tokens, navigation scaffold, auth flow.

- [ ] Design tokens: colors, typography, spacing (extracted from FlutterFlow reference)
- [ ] GoRouter setup: all named routes declared, guarded by auth state
- [ ] Riverpod: `authStateProvider`, `currentUserProvider`
- [ ] Sign up (email + phone option)
- [ ] Sign in
- [ ] Profile setup after signup (displayName, country, photo)
- [ ] Auth guard: redirect unauthenticated users to sign in
- [ ] Mode switch UI (client ↔ provider toggle)
- [ ] Bottom navigation shell

---

## Phase 3 — Core client journey

Discovery → booking request. The central MVP loop for the client.

- [ ] Home page: categories, top services, search bar
- [ ] Category browse + filter (price, rating)
- [ ] Service detail page: photos, description, price, map/zone, provider info
- [ ] Booking request flow: slot picker + address + message
- [ ] Booking history: active + completed tabs
- [ ] Booking detail / status timeline

---

## Phase 4 — Provider journey

Everything a provider needs to operate.

- [ ] Provider onboarding: activate provider mode (bio, zone, no approval needed)
- [ ] Service CRUD: create, edit, publish/unpublish
- [ ] Provider inbox: list of booking requests
- [ ] Accept / reject booking
- [ ] Provider booking history

---

## Phase 5 — Chat + trust layer

Post-accept communication and review system.

- [ ] Chat: accessible only after booking accepted
- [ ] Real-time message list + send
- [ ] Image in chat
- [ ] Contact unlock (phone visible after accept)
- [ ] Review flow: bilateral — client reviews provider + provider reviews client after `done`
- [ ] Push notifications: new booking request, accept/reject, new message, review received
- [ ] Report flow (basic)

---

## Phase 6 — Hardening + release

- [ ] Error states on all critical screens
- [ ] Offline / no connection handling
- [ ] Performance: image caching, pagination on lists
- [ ] Firestore rules audit (all rules tested with 2 accounts)
- [ ] Coverage at 90%+ on domain, repositories, Cloud Functions, notifiers
- [ ] App store assets: icon, splash, store listings
- [ ] Release build passes on Android + iOS + Web

---

## Out of scope for MVP

- Payments (Stripe, mobile money)
- AI features
- Advanced admin tooling beyond basic moderation
- Growth loops, referrals, promotions
- Premium subscriptions
- Multi-language UI (FR first, SN later)
