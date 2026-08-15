# Increment 014 — Account detail ledger

## Added

- Dedicated detail page for every Cash, Bank, E-Wallet, and Savings account
- Live per-account balance, total income, and total spending metrics
- Date-grouped transaction activity scoped to the selected account
- Today and yesterday labels for recent account activity
- Empty-state guidance for accounts without transactions

## Changed

- Account cards are now tappable destinations instead of management-only rows
- Account cards now expose a chevron while preserving safe delete behavior
- Account detail values react to the shared dashboard transaction state

## Compatibility

This increment is presentation-only and does not change transaction, account, settings, or backup storage formats. Existing Increment 013 data works without migration.
