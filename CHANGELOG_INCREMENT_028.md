# Increment 028 — Budget Alerts

## Added
- Added a dedicated Budget Alerts center for monthly category budgets.
- Added automatic 80% warning, 100% reached, and over-budget states.
- Added recent spending context inside each alert so users can see what pushed a category toward its limit.
- Added a one-tap path from Budget Alerts to Category Budget management.

## Dashboard
- Category Budgets summary now reports categories that need attention, not only categories that are already over budget.
- Tapping the Dashboard Category Budgets summary now opens Budget Alerts first.

## Accounting behavior
- Alerts use current-month expense transactions only.
- Transfers and reconciliation adjustments remain excluded through `countsAsExpense`.
- No persistence or backup schema changes are required in this increment.
