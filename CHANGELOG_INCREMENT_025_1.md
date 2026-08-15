# MoneyTracker Pro — Increment 025.1

## Test environment hotfix

- Replaces the full-app widget smoke test with a root-construction test.
- Avoids instantiating `SharedPreferencesAsync` inside a Flutter widget-test environment where no desktop plugin implementation is registered.
- Keeps production repositories, UI, account data, transactions, recurring rules, savings goals, and backup schemas unchanged.
- `flutter analyze` remains unaffected; this hotfix targets the failing `flutter test` path reported after Increment 025.
