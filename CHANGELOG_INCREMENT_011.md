# Increment 011 — Data backup and restore

## Added

- Versioned MoneyTracker Pro JSON backup format
- Full transaction and settings export
- Clipboard-based cross-platform backup copying
- Backup validation before restoration
- Duplicate ID and invalid value detection
- Restore confirmation and live application refresh
- Clear-all workflow with destructive confirmation
- Data & Backup destination in Profile

## Changed

- Transaction repositories support atomic full-list replacement
- Shared controllers expose controlled restore operations

## Compatibility

The clipboard workflow works on Android, iOS, Web, Windows, macOS, and Linux without adding platform-specific file permissions.
