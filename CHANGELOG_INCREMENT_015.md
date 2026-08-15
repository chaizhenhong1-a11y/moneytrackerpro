# Increment 015 — Account-to-account transfers

## Added

- Transfer funds action on the Accounts page
- Source and destination account selectors with one-tap swap
- Transfer amount, optional note, and date fields
- Atomic two-sided transfer entries so both account ledgers stay synchronized
- Transfer filter in transaction history

## Accounting behavior

- Transfers reduce the source account balance and increase the destination account balance
- Transfers do not count as income, spending, budget usage, savings rate, spending charts, or financial alerts
- Transfer history is protected from single-sided edit/delete actions to prevent broken account balances

## Compatibility

This increment reuses the existing transaction storage and backup format. No SharedPreferences key or backup schema migration is required.
