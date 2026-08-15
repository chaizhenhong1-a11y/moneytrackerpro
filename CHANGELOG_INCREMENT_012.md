# Increment 012 — Safe deletion and working dashboard navigation

## Added

- Undo action after transaction deletion
- Controller-level restoration using the original transaction ID
- Delete confirmation on the dashboard
- Dashboard callback into the shared application shell

## Changed

- `See all` now switches directly to the Transactions tab
- Dashboard and history use the same delete-and-undo behavior
- Static section actions no longer look incorrectly interactive

## Data safety

Undo restores the complete original transaction object, including its ID, date, category, type, amount, icon, and color.
