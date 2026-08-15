# Increment 005 — Live financial statistics

## Added

- Functional statistics tab backed by real transaction state
- Current-month income, expenses, and savings-rate summary
- Native seven-day expense bar chart
- Native spending-category donut chart
- Category totals, percentages, colors, and icons
- Empty statistics state and pull-to-refresh

## Changed

- Statistics placeholder replaced by a production page
- Every statistic now updates when a transaction is created or deleted

## Technical notes

Charts are painted with Flutter `CustomPainter`; no chart dependency was added. All values are derived from the shared dashboard controller, so no duplicate analytics data is stored.
