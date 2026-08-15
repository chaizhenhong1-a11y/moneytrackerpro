# MoneyTracker Pro — Increment 019

## Account Reconciliation

- Added account reconciliation from Account Detail.
- Enter the actual balance from a bank, e-wallet, savings account, or cash count.
- Automatically calculates the difference between book balance and actual balance.
- Creates a dedicated reconciliation adjustment to bring the ledger back in sync.
- Supports positive and negative real-world balances.
- Reconciliation adjustments affect real account balances and total dashboard balance.
- Reconciliation adjustments are excluded from income, expenses, budgets, alerts, and statistics.
- Monthly statements now show reconciliation adjustments separately from income, expenses, and transfers.
- Transactions adds a Reconcile filter and dedicated reconciliation details dialog.
- Dashboard system-record hardening prevents transfers and reconciliation adjustments from being edited or deleted as ordinary transactions.
- No storage-key, backup-schema, or transaction-record migration is required.
