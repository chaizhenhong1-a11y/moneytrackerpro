# Increment 009 — Live dashboard spending overview

## Added

- Real seven-day expense aggregation
- Previous seven-day comparison period
- Dynamic percentage increase or decrease
- Safe labels for new activity and zero-to-zero comparisons
- Dynamic chart points and weekday labels

## Changed

- Dashboard spending total is no longer hardcoded
- Dashboard line chart now responds to transaction create, update, and delete operations
- Expense decreases use a positive success state; increases use a warning state

## Data integrity

Only expense transactions are included. Income transactions do not distort spending trends.
