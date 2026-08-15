# MoneyTracker Pro — Increment 022

## Recurring transaction editing & next-run preview

- Added safe editing for existing recurring transaction rules.
- Edit name, amount, income/expense type, category, active account, repeat frequency, and next due date.
- Preserves the recurring rule ID so already-generated occurrences remain deduplicated.
- Added human-friendly next-run previews such as `Due tomorrow` and `Due in 5 days`.
- Existing pause/resume/delete behavior is unchanged.
- Archived accounts remain unavailable for new recurring postings; editing a rule tied to an archived account requires selecting an active account before saving.
- No storage schema migration is required; existing Increment 021 recurring-rule data remains compatible.
