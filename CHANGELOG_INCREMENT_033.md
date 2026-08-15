# Increment 033 — Debt Payoff Planner

## Added
- Added a dedicated Debt Payoff Planner accessible from Debts & liabilities.
- Added Avalanche strategy ordering debts by highest APR first.
- Added Snowball strategy ordering debts by smallest outstanding balance first.
- Added an editable monthly payoff budget for scenario planning.
- Added projected payoff duration, projected interest, payoff order, and per-debt target payoff month.
- Added a safety state when the entered monthly budget cannot overcome projected interest.

## Notes
- This increment is analysis-only and does not add persistence keys or change the backup schema.
- The projection is intentionally simplified: monthly APR compounding plus strategy-ordered payments. It does not model lender minimum payments, fees, promotional rates, or changing APRs.
