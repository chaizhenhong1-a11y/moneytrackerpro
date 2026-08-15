# MoneyTracker Pro — Increment 016

## Safe transfer cancellation & paired transfer management

### Added
- Transfer entries now expose their shared transfer group ID so the outgoing and incoming sides can be handled as one atomic operation.
- Tapping a transfer in **Transactions** opens a transfer details dialog with amount, source account, destination account, date, and note.
- Added **Cancel transfer** support that removes both linked transfer records together.
- Added **UNDO** after cancelling a transfer; both linked records are restored together.
- Transfer records can also be cancelled safely from an **Account Detail** page.
- Incomplete or malformed transfer pairs are protected and will not be partially removed.

### Fixed
- Account Detail `Current balance` now includes transfer inflows/outflows, matching the balance shown on the Accounts page.
- Income and spending metrics continue to exclude transfers, so transfers do not inflate reports, budgets, or spending totals.

### Data compatibility
- No SharedPreferences storage key changes.
- No backup schema changes.
- Existing Increment 015 transfer IDs are used to derive transfer pairing, so no migration is required.
