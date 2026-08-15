# Increment 004 — App shell and transaction history

## Added

- Shared application shell with persistent bottom navigation
- Full transaction history page
- Search by transaction title or category
- All, income, and expense filters
- Filtered record count and signed total
- Pull-to-refresh
- Delete confirmation dialog
- Add transaction action from the history page

## Changed

- Dashboard and transaction history now share one controller and repository
- Bottom navigation now changes real pages instead of only changing icon state
- Dashboard controller lifecycle is owned by the application shell

## Architecture

`HomeShell` is now the composition root for signed-in application features. This prevents duplicate repositories and keeps financial state synchronized across tabs.
