# Increment 006 — Profile, preferences, and budgeting

## Added

- Persistent profile and application settings repository
- Shared settings controller with optimistic updates and rollback
- Functional profile tab
- Editable display name and monthly budget
- Persistent budget-alert preference
- Monthly budget progress card with warning and overspend states
- Application information dialog

## Changed

- Dashboard greeting uses the saved display name
- Dashboard derives current-month spending for the budget card
- Profile placeholder replaced by a production settings page
- App shell owns and disposes both shared controllers

## Storage

Settings use separately versioned keys so future migrations can be introduced without affecting saved transactions.
