# Increment 027 — Category Budgets

## Added
- Per-category monthly budget limits for expense categories.
- Dashboard summary showing how many category budgets are on track or exceeded.
- Category budget management from Profile and Transactions.
- Current-month spent, remaining, and over-budget progress per category.
- Local persistence using SharedPreferencesAsync.
- Backup schema v6 with category budget export/restore support.

## Compatibility
- Existing category and transaction data remains unchanged.
- Transfers and reconciliation adjustments are excluded from category spending.
- Backup versions v1–v5 remain restorable; they simply start with no category budgets.
