# Increment 002 — Functional transaction core

## Added

- Repository contract with an in-memory implementation
- Dashboard `ChangeNotifier` controller and derived financial totals
- Validated add-transaction form
- Income and expense selector
- Category and transaction-date selection
- Swipe-to-delete transaction interaction
- Loading and empty dashboard states

## Changed

- Dashboard balance, income, expenses, and recent activity now update from live state
- Add transaction sheet moved into the transactions feature

## Next migration boundary

The in-memory repository intentionally isolates persistence. A later increment can replace it with SQLite or Firestore without changing dashboard widgets.
