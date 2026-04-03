When the user runs `/align-models`, do the following:

1. Read `docs/domain-model-canonical.md` — this is the source of truth.
2. Read every Dart model in `lib/src/domain/models/` and every enum in `lib/src/domain/enums/`.
3. For each model and enum, diff it against the canonical:
   - missing fields
   - wrong field names
   - wrong types
   - enum values that don't match
4. Read `lib/src/data/firestore/firestore_collections.dart` and diff converters against canonical field names.
5. Read `functions/src/index.ts` and diff TypeScript types against canonical.
6. Produce a gap table: model | issue | canonical value | current value.
7. Fix all gaps in this order: enums first, then models, then converters.
8. Run `flutter analyze` after changes.
9. Summarize what changed and propose a commit message.
