# FlutterFlow Migration Strategy

## Purpose
Use `outalma_service_app` to accelerate delivery without inheriting generated-code complexity.

## Reuse directly
- screen inventory
- UX flows
- visual hierarchy
- component ideas
- theme tokens
- loading / empty / error states

## Do not reuse blindly
- generated architecture
- generated state handling
- generated backend coupling
- verbose widget trees when a clean abstraction is better

## Migration method
1. pick one target flow,
2. inspect equivalent FlutterFlow screens,
3. extract UX intent,
4. align with canonical models,
5. rebuild inside the clean architecture,
6. compare visually before closing the task.
