# SQLite rollback

This rollback intentionally removes the Drift / SQLite experiment introduced in
Increments 072–073.1.

After rollback:

- Transactions use `LocalTransactionRepository`.
- Persistence returns to SharedPreferences.
- Accounts, categories, budgets, goals, debts, recurring rules and settings keep
  their existing persistence implementations.
- Drift database source files and generated files are deleted.
- Drift web WASM / worker assets are deleted.
- Drift and code-generation packages added for the database experiment are
  removed from pubspec.

## Important

Transactions created only inside the temporary SQLite database are not copied
back into SharedPreferences by this rollback. The SQLite work was being tested
with non-production data, so this rollback intentionally favors a clean project
state instead of importing experimental rows.

Run the cleanup script from the project root after copying this increment:

```powershell
powershell -ExecutionPolicy Bypass -File ".\scripts\rollback_sqlite.ps1"
```
