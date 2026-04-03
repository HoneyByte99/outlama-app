# Firebase Safety

Security is deny-by-default.

Never weaken Firestore or Storage rules for convenience.
If a rule must change, explain:
- why the current rule blocks the feature,
- the minimum safe change,
- the abuse risk,
- how the change is validated.

Prefer transactional correctness and explicit authorization checks over convenience.
Critical booking mutations must remain server-authoritative.
