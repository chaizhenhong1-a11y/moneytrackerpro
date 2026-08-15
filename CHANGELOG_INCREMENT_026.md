# MoneyTracker Pro — Increment 026

## Custom Categories

- Added persistent custom income and expense categories.
- Added category management under Profile > Categories.
- Categories can be created with a name, icon, color, and transaction type.
- Existing categories can be renamed, recolored, re-iconed, deactivated, and restored.
- Deactivated categories remain attached to historical transactions and existing recurring rules, but are hidden from new selections.
- Transaction and recurring editors now share the same active category source.
- Renaming a category updates existing transaction and recurring-rule references.
- Recurring auto-posting resolves custom categories so generated transactions keep the configured icon and color.
- Backup schema upgraded to v5 and now includes categories.
- Backup versions v1-v4 remain compatible and restore with default categories.
