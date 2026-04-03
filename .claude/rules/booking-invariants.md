# Booking Invariants

## Canonical statuses

```
requested   → client created, awaiting provider
accepted    → provider accepted, chat unlocked
in_progress → service underway
done        → service completed, reviews unlocked
rejected    → provider rejected
cancelled   → cancelled before accept
```

## State machine

```
requested → accepted     (provider: acceptBooking)
requested → rejected     (provider: rejectBooking)
requested → cancelled    (client OR provider: cancelBooking)
accepted  → in_progress  (provider: markInProgress)
in_progress → done       (client: confirmDone)
```

No other transitions are valid. No cancellation after `accepted` in MVP.

## Rules

- Client creates booking requests via `createBooking()`.
- Provider accepts or rejects via `acceptBooking()` / `rejectBooking()`.
- Either party can cancel via `cancelBooking()` only when status=`requested`.
- Provider triggers `in_progress` via `markInProgress()`.
- Client confirms completion via `confirmDone()`.
- Chat is created only by `acceptBooking()`. Inaccessible before accept and after reject/cancel.
- Phone number (PhoneShare) is readable by participants when `status ∈ {accepted, in_progress, done}`.
- Reviews are bilateral: after `done`, both client and provider can leave a review.
- All status transitions are server-authoritative (Cloud Functions only).
- Dart, Firestore documents, Firestore rules, and TypeScript must use identical status strings.

## Non-negotiable

If any booking contract is ambiguous between layers, stop and align to
`docs/domain-model-canonical.md` before building further.
