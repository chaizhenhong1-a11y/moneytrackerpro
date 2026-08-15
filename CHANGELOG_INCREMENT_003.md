# Increment 003 — Cross-platform local persistence

## Added

- `shared_preferences` 2.5.5 using the modern asynchronous API
- Versioned local storage key: `moneytracker.transactions.v1`
- Transaction JSON record mapping isolated from the domain entity
- Persistent repository implementation
- Storage format validation and typed storage exceptions

## Changed

- Dashboard now uses `LocalTransactionRepository`
- Added and deleted transactions survive application restarts
- Delete failures are handled by the dashboard controller

## Compatibility

The selected persistence layer supports Android, iOS, Web, Windows, macOS, and Linux. The repository contract remains unchanged, allowing migration to SQLite or Firestore later.

## Replaced implementation

`in_memory_transaction_repository.dart` is no longer used. It may remain in the project for tests or be deleted manually.
