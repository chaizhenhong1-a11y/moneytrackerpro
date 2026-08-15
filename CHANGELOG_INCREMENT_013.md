# Increment 013 — Multi-account and wallet system

## Added

- Cash, bank, E-Wallet, and savings account types
- Persistent account repository and shared controller
- Account management page with per-account balances
- Account selector in create and edit transaction forms
- Used-account deletion protection
- Default Cash account deletion protection

## Changed

- Transactions now store a stable account ID
- Existing transactions without an account automatically migrate to Cash
- Profile shows account management and live account count
- Backup schema upgraded to version 2 with accounts
- Version 1 backups remain importable and migrate to Cash

## Data integrity

Backup restore rejects missing account references and duplicate account IDs. Accounts with linked transactions cannot be deleted.
