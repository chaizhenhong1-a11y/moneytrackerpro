# MoneyTracker Pro — Increment 017

## Transfer editing

- Added safe editing for existing account transfers.
- Transfer source account, destination account, amount, date, and note can now be changed.
- Both linked transfer records are updated atomically through `replaceAll`, keeping account balances synchronized.
- Existing transfer IDs are preserved, so Increment 016 cancel/undo pairing remains compatible.
- Added **Edit** actions to transfer details on the Transactions page.
- Added **Edit** actions to transfer activity inside Account Detail.
- Reused the existing Transfer Funds sheet in edit mode with pre-filled values and edit-specific copy.
- Transfer edits continue to be excluded from income, expense, budget, statistics, and alert totals.

## Compatibility

- No SharedPreferences key changes.
- No transaction JSON/schema changes.
- Existing Increment 015/016 transfers remain editable.
