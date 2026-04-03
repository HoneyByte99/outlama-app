# Testing Strategy

## Main target
Aim for extremely high confidence in critical flows. The aspirational target is 90% coverage on domain, application, and server business logic.

## Priority pyramid
1. Domain logic
2. Booking state machine
3. Repository behavior
4. Cloud Functions
5. Riverpod providers/notifiers
6. Widget tests for critical flows

## Minimum expectation per important feature
- Unit tests for business rules
- At least one regression test for bug fixes
- Happy path + one failure path

## Critical journeys to protect
- Sign up / sign in
- Switch role mode (client ↔ provider)
- Create booking
- Accept booking (chat created, chatId set, acceptedAt set)
- Reject booking
- Cancel booking (only when status=requested)
- Mark in progress (provider only, status must be accepted)
- Confirm done (client only, status must be in_progress)
- Access chat only after acceptance — not before, not after cancel/reject
- PhoneShare readable when status ∈ {accepted, in_progress, done} — not before
- Client leaves review on provider after done
- Provider leaves review on client after done
- Booking status cannot be written directly by client (server-authoritative)

## Notes
Coverage percentage is not the only metric. Business-critical transitions must be tested even if broad UI coverage remains lower.
