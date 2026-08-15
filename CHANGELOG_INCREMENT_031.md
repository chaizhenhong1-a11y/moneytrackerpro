# Increment 031 — Net Worth Tracking

## Added
- Dashboard Net Worth summary card with current value and 30-day movement.
- Dedicated Net Worth page with positive assets, negative balances and account allocation.
- Six-month net worth trend calculated from existing transaction history.
- Archived accounts remain part of net worth because archived money is still owned.

## Accounting behavior
- Transfers remain net-zero at the portfolio level.
- Reconciliation adjustments affect net worth because they correct recorded balances.
- No new persistence key, transaction schema change or backup schema upgrade is required.
