# Architecture

Clean architecture for the Outalma Flutter app.

## Goals

- Keep UI free of Firestore serialization details.
- Keep domain logic free of Flutter and Firebase imports.
- Provide a clean seam for testing each layer independently.
- Stay minimal: no over-engineering before the feature exists.

---

## Layer structure

```
lib/
  main.dart                        # Firebase init + ProviderScope + app entry
  src/
    domain/                        # Pure Dart — no Flutter, no Firebase
      enums/                       # BookingStatus, ServiceStatus, UserRole, MessageType...
      models/                      # AppUser, Booking, Service, Chat, ChatMessage, Provider...
      repositories/                # Abstract interfaces only (no implementation)
      domain.dart                  # Barrel export

    data/                          # Firebase-specific — Firestore, Storage, Functions
      firestore/
        firestore_collections.dart # withConverter typed refs (users, services, bookings, chats)
        firestore_serialization.dart # dateTimeFromFirestore / dateTimeToFirestore
      repositories/                # Concrete Firestore-backed implementations
      functions/                   # Callable Cloud Functions wrappers (createBooking, etc.)
      data.dart                    # Barrel export

    application/                   # Riverpod providers, notifiers, use cases
      auth/                        # authStateProvider, currentUserProvider
      booking/                     # bookingListNotifier, createBookingUseCase...
      service/                     # serviceListNotifier, serviceDetailProvider...
      chat/                        # chatNotifier, sendMessageUseCase...
      providers.dart               # Barrel export

    features/                      # UI only — pages, widgets, no business logic
      auth/
      home/
      switch_mode/
      booking/
      service/
      chat/
      provider_onboarding/
      profile/
```

---

## Layer rules

### domain/
- Pure Dart only. Zero Flutter imports. Zero Firebase imports.
- Models are immutable value objects with `copyWith`.
- Repository interfaces expose `Stream<T>` for live data and `Future<T>` for commands.
- Enums have a `fromString(String)` factory with a safe fallback.

### data/
- Owns all Firestore, Storage, and Cloud Functions interaction.
- Converters live in `FirestoreCollections` using `withConverter`.
- Repository implementations inject `FirebaseFirestore` and implement domain interfaces.
- Cloud Function wrappers in `data/functions/` call `FirebaseFunctions.instance.httpsCallable`.
- No business logic here — only serialization and network.

### application/
- Riverpod providers and `AsyncNotifier` / `Notifier` subclasses.
- Injects repository implementations via Riverpod.
- Owns use-case orchestration (e.g. createBooking checks preconditions then calls repo).
- No Firestore imports allowed.
- No widget imports allowed.

### features/
- Flutter widgets and pages only.
- Consumes `application/` via `ref.watch` / `ref.read`.
- No direct Firestore calls. No business policy.
- Must handle loading, error, and empty states.

---

## Key patterns

### Firestore withConverter

All Firestore access goes through typed `CollectionReference<T>` via `FirestoreCollections`:

```dart
FirestoreCollections.bookings(db).doc(id).snapshots()
```

Never use raw `Map<String, dynamic>` across layer boundaries.

### Timestamp handling

`firestore_serialization.dart` handles all timestamp input variants:
- `Timestamp` (preferred — Firestore native)
- `String` ISO-8601
- `int` epoch millis
- `null` → epoch zero (defensive fallback)

Always store as `Timestamp` via `dateTimeToFirestore()`.

### Cloud Functions for critical transitions

Booking status transitions (`createBooking`, `acceptBooking`, `rejectBooking`) are
server-authoritative. The client calls the callable function — never writes status directly.

### Riverpod injection

```dart
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return FirestoreBookingRepository(FirebaseFirestore.instance);
});
```

Application layer notifiers depend on repository providers, not on Firestore directly.

---

## Naming conventions

| Concept | Convention |
|---|---|
| Files | `snake_case.dart` |
| Classes | `PascalCase` |
| Domain models | No suffix (e.g. `Booking`, not `BookingModel`) |
| Repository interfaces | `*Repository` (e.g. `BookingRepository`) |
| Repository implementations | `Firestore*Repository` (e.g. `FirestoreBookingRepository`) |
| Riverpod providers | `*Provider` or `*Notifier` |
| Pages | `*Page` (e.g. `BookingDetailPage`) |
| Reusable widgets | `*Widget` or plain name (e.g. `BookingCard`) |
| User model | `AppUser` (avoids clash with `firebase_auth.User`) |
| Dates | Domain always uses `DateTime` in UTC |

---

## Platform targets

The app targets **Android, iOS, and web** — same codebase, single Flutter project.
Platform-specific config lives in `android/`, `ios/`, `web/`.
No platform-specific Dart code unless unavoidable (e.g. notifications).
