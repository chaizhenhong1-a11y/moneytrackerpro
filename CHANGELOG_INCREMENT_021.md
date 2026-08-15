# MoneyTracker Pro — Increment 021

## Recurring Transactions

- Added recurring transaction rules for repeating income and expenses.
- Supports weekly, monthly, and yearly schedules.
- Added a Recurring management page from the Transactions screen.
- Rules can be paused, resumed, or deleted without affecting already-posted transactions.
- Due occurrences are posted automatically when the app starts and when returning from the Recurring page.
- Added deterministic occurrence IDs to prevent duplicate posting when the app is opened repeatedly.
- Missed occurrences are caught up safely, with a defensive processing limit.
- Recurring rules only post to active accounts; archived accounts are skipped until restored.
- Recurring data is stored locally in SharedPreferences using a versioned storage key, ready for future database migration.
- Backup schema upgraded to v3 so recurring rules are included in copy/restore; v1/v2 backups remain compatible.
