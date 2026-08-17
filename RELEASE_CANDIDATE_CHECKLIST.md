# MoneyTracker Pro — v1.0 Release Candidate Checklist

Increment 074 is a stability / release-cleanup pass. It does not introduce new
features or change the persistence architecture.

## Automated gate

Run from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\release_cleanup_074.ps1"
```

Target:

- `flutter analyze` → `No issues found!`
- `flutter test` → `All tests passed!`

## Manual smoke test

Run:

```powershell
flutter run -d chrome --web-port=5000
```

Check:

- Home opens.
- Add an income transaction.
- Add an expense transaction.
- Edit a transaction.
- Delete a transaction.
- Accounts opens.
- Transfers still work.
- Reconciliation still works.
- Budgets open and can be edited.
- Savings Goals open and can be edited.
- Debts open and can be edited.
- Recurring Money opens and can be edited.
- Insights opens.
- More opens.
- Backup screen opens.

## Scope

This release candidate continues to use the project's existing local repository
persistence after the SQLite rollback. No database migration is part of 074.
