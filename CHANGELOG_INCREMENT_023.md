# MoneyTracker Pro — Increment 023

## Upcoming recurring reminder center

- Added a dashboard `Upcoming recurring` card so scheduled money is visible without opening the recurring rules manager.
- Added a dedicated reminder center with:
  - rules needing attention,
  - recurring transactions due in the next 7 days,
  - later scheduled rules,
  - 30-day recurring income and expense forecast.
- Archived or unavailable accounts are surfaced as attention items instead of silently disappearing.
- Paused rules stay out of reminder totals until resumed.
- The reminder center links back to the existing Recurring manager for editing, pausing, resuming, or deleting rules.
- No persistence schema changes are required; Increment 021/022 recurring data remains compatible.
