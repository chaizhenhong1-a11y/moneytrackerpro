# Increment 024 — Savings Goals

## Added
- Local Savings Goals persistence with SharedPreferences.
- Create savings goals with target amount, linked account, and deadline.
- Goal progress is calculated automatically from the linked account balance.
- Remaining amount, percentage complete, and suggested monthly saving amount.
- Savings Goals shortcut card on the Dashboard.
- Account deletion guard when a savings goal is linked to the account.
- Savings Goals are included in backup/restore.

## Backup
- Backup schema upgraded from v3 to v4.
- v1, v2, and v3 backups remain supported.
