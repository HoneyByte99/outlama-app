# Architecture Rules

## Core principles
- MVP first
- Keep the domain pure
- Keep Firebase details isolated
- Prefer explicit flows over hidden magic
- Make server transitions authoritative

## Rules by layer

### Domain
- Pure Dart only
- No Firebase imports
- Models, enums, repository contracts, value objects

### Data
- Firestore converters
- Repository implementations
- Cloud Function clients
- Serialization and mapping

### Application
- Riverpod providers
- Notifiers
- Use cases
- Thin orchestration layer between data and UI

### Features
- Pages, widgets, controllers
- No hidden business policy in widgets
- Must consume application-layer abstractions

## Non-negotiables
- No status transition logic duplicated inconsistently across layers
- No direct `.collection()` scattering in UI
- No rules weakening for convenience
- No giant god-notifiers
- No untyped dynamic maps crossing boundaries if a typed model should exist
