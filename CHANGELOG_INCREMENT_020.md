# Increment 020 — Account Archiving

## Added

- Archive inactive bank, e-wallet, savings, and custom accounts without deleting their history.
- Archived Accounts manager with account balance, transaction count, historical detail access, and one-tap restore.
- Undo action immediately after archiving an account.
- Backward-compatible persistence for the new `isArchived` account flag.
- Backup export/import now preserves archived account state.

## Behaviour

- Archived accounts are hidden from the normal Accounts list.
- Archived accounts cannot be selected for new transactions or new transfers until restored.
- Historical transactions remain untouched and archived balances continue to count toward the user's real combined balance.
- Existing transactions and transfers can still resolve archived account names correctly.
- The default Cash account cannot be archived.

## Compatibility

- Existing stored accounts without `isArchived` load as active automatically.
- Existing backup files remain importable; missing `isArchived` values default to `false`.
- No transaction schema or transfer pairing format changes are required.
