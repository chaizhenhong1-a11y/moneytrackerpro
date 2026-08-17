# MoneyTracker Pro --- Changelog

> Consolidated product and engineering history covering Increment 002
> through Increment 043, including the Increment 025.1 test-environment
> hotfix. This document replaces the fragmented per-increment changelog
> files as the canonical development history.

## Product evolution at a glance

MoneyTracker Pro evolved from a functional local transaction tracker
into a cross-platform personal-finance system with persistent
transactions, multi-account ledgers, transfers, recurring transactions,
savings goals, category budgeting, debt tracking, forecasting,
financial-health analysis, net-worth reporting, backup/restore, and a
growing set of monthly planning tools.

The implementation consistently separates domain logic, persistence,
controllers, and presentation. Financial system records such as
transfers and reconciliation adjustments are deliberately excluded from
income/expense analytics where appropriate, preserving accounting
correctness across dashboards, budgets, statistics, alerts, and
forecasts.

## Major capability areas

-   **Transactions & reporting:** create, edit, delete/undo, search,
    filter, dated history, statistics, month navigation, monthly
    reviews, and spending trends.
-   **Accounts & ledger integrity:** multi-account balances, account
    detail ledgers, paired transfers, transfer editing/cancellation,
    monthly statements, reconciliation, and account archiving.
-   **Planning & automation:** recurring transactions, upcoming
    reminders, savings goals, category budgets, budget alerts, debt
    payoff planning, emergency-fund planning, savings targets, and
    surplus allocation.
-   **Financial intelligence:** cash-flow forecasting, Financial Health
    Score, net worth, Safe-to-Spend, Spending Guard, spending pace
    projections, stress testing, action plans, and income-stability
    analysis.
-   **Customization & resilience:** profile/preferences, custom
    categories, local persistence, versioned backup/restore,
    backward-compatible migrations, and engineering/test hardening.

## Data and backup evolution

  Backup version   Introduced                Data added
  ---------------- ------------------------- -----------------------------
  v1               Early backup foundation   Transactions and settings
  v2               Increment 013             Accounts
  v3               Increment 021             Recurring transaction rules
  v4               Increment 024             Savings goals
  v5               Increment 026             Custom categories
  v6               Increment 027             Category budgets
  v7               Increment 032             Debts and liabilities

Older supported backup versions remain backward compatible according to
the migration notes in the corresponding increments.

## Detailed history

Entries are listed newest first. Dates are intentionally omitted because
the source increment changelogs do not contain release dates.

## Increment 074 — Release Cleanup & Stability Pass

### Changed

- Added a guarded release-cleanup script that fixes the remaining analyzer flow-control brace diagnostics against the **current local source tree**, avoiding stale-file replacement.
- The script previews `dart fix` changes before applying them and stops if unexpected diagnostic migrations are detected.
- Formats production and test Dart code after cleanup.
- Runs `flutter analyze` and `flutter test` as mandatory release gates.
- Saves the current Git diff before automated edits when Git is available.

### Added

- Added a v1.0 Release Candidate smoke-test checklist covering Transactions, Accounts, Transfers, Reconciliation, Budgets, Goals, Debts, Recurring Money, Insights, More, and Backup.

### Architecture

- No new features.
- No storage migration.
- No SQLite / Drift reintroduction.
- Existing Repository and SharedPreferences persistence remain unchanged.

### Release target

- `flutter analyze` → `No issues found!`
- `flutter test` → `All tests passed!`

## Increment 073.2 — Complete SQLite Rollback

### Changed

- Reverted Transactions from `SqliteTransactionRepository` back to `LocalTransactionRepository`.
- Removed `AppDatabase` creation and disposal from `HomeShell`.
- Stopped the database migration path before Accounts, Categories, Goals, Debts, Budgets, Recurring Rules, or Settings were moved.

### Cleanup

- Added `scripts/rollback_sqlite.ps1` to remove Drift database source/generated files.
- Removes the temporary Drift Web WASM and worker assets.
- Removes `drift`, `drift_flutter`, `drift_dev`, and `build_runner` packages added for the SQLite experiment.
- Removes the SQLite migration documentation and setup/generation scripts.

### Persistence after rollback

- Transactions return to SharedPreferences through the existing repository contract.
- Other modules remain on their pre-database local persistence implementations.
- Experimental SQLite-only test transactions are not imported back into SharedPreferences.

### Architecture decision

SQLite development is paused and completely removed from the active application path. The Repository architecture is preserved so a different persistence or cloud-backend strategy can be introduced later without rebuilding the UI/controllers.

## Increment 073.1 — Remove Demo Transactions from SQLite Migration

### Fixed

- Removed `DashboardDemoData.transactions` from the legacy transaction repository used by the SQLite migration.
- New installations now start with real user data only instead of automatically seeding Salary, Food & Drinks, Petrol, and Online Shopping demo records.
- Added a one-time SQLite cleanup that removes the four known demo rows if Increment 073 already imported them.
- Added filtering during legacy SharedPreferences import so known demo records are never copied into SQLite again.

### Data safety

- Cleanup only removes records matching the known demo IDs **and** their expected demo title/category/amount signatures.
- User-created transactions are otherwise untouched.
- Existing real SharedPreferences transaction data can still be imported once into SQLite.
- The old SharedPreferences store remains available as a rollback copy.

## Increment 073 — Transactions SQLite Migration

### Added

- Added the real `AppDatabase` Drift database class and generated-code entrypoint.
- Added `SqliteTransactionRepository`, implementing the existing `TransactionRepository` contract on SQLite.
- Added a one-time legacy transaction importer from the existing SharedPreferences repository into SQLite.
- Added a migration-complete marker so legacy data is imported only once.
- Added scripts for Drift code generation and Chrome/Web SQLite asset setup.

### Changed

- `HomeShell` now creates one shared `AppDatabase` instance.
- Dashboard and recurring transaction flows now receive the SQLite-backed transaction repository.
- The database is explicitly closed when `HomeShell` is disposed.

### Data safety

- Existing SharedPreferences transaction data is read and copied into SQLite before SQLite becomes the source of truth.
- The legacy SharedPreferences transaction store is intentionally left intact as a rollback safety copy.
- If SQLite already contains transactions, legacy import is skipped to prevent duplicate rows.
- Accounts, Categories, Goals, Debts, Budgets, Recurring Rules, and Settings remain on their current persistence layer.

### Verification target

After applying this increment:

1. Generate Drift code.
2. Install web assets when running Chrome.
3. Run `flutter analyze`.
4. Run the app and verify old transactions are present.
5. Add, edit, delete, transfer, and reconcile transactions.
6. Restart the app and verify those changes persist.

## Increment 072 — Database Foundation

### Added

- Introduced the first real relational-database foundation for MoneyTracker Pro using Drift / SQLite.
- Added schema declarations for Accounts, Categories, Transactions, Category Budgets, Savings Goals, Debts, Recurring Rules, and Settings.
- Added database name and schema-version metadata with a defined staged migration order.
- Added a PowerShell dependency setup script so Drift dependencies are added to the user's existing `pubspec.yaml` instead of replacing the file with an assumed baseline.
- Added a database migration README documenting the staged move away from SharedPreferences persistence.

### Architecture

- Existing SharedPreferences repositories remain active in this increment.
- Increment 072 intentionally does **not** switch production reads/writes yet.
- Transactions will be the first repository migrated to SQLite in the next database increment.
- Legacy persistence will only be removed after data-import and parity validation are complete.

### Data safety

- No existing local user data is deleted or transformed in this increment.
- No backup schema is changed yet.
- The staged migration avoids replacing a working persistence layer in one large step.

## Increment 071 — Typography & Section Hierarchy Foundation

### Added

- Added a reusable `AppTypography` system for consistent page titles, section titles, card titles, body copy, secondary copy, labels, and money amounts.
- Standardized font sizes, weights, line heights, and text colors for the most common UI hierarchy levels.
- Added dedicated large and medium amount styles for financial values.

### UX rationale

The visual system now has shared surfaces, forms, selectors, actions, dialogs, states, and feedback. Typography is the next foundation layer: users should be able to identify page hierarchy, section importance, supporting copy, and money values instantly.

### Migration strategy

- This increment only introduces the shared typography foundation.
- Existing screens remain visually unchanged until they are migrated in smaller follow-up increments, avoiding large baseline-sensitive rewrites.

### Data impact

- No database, repository, transaction, account, budget, settings, backup-schema, or migration changes.

## Increment 070.1 — Analyzer Warning Hotfix

### Fixed

- Removed unused `AppActionStyle` imports from the transaction and recurring form sheets.
- Clears the two analyzer warnings introduced in Increment 070.
- Leaves the existing form layout, save behavior, validation, and data logic unchanged.

### Data impact

- No database, repository, transaction, recurring-rule, backup-schema, or migration changes.

## Increment 070 — Buttons & Action Hierarchy Polish

### Added

- Added a reusable `AppActionStyle` foundation for primary, secondary, destructive, and compact primary actions.
- Standardized button height and rounded geometry so save/add actions feel consistent across sheets and dialogs.

### Changed

- Applied the shared primary action style to transaction and recurring save/create flows.
- Began applying the compact primary action style to account, savings-goal, and debt form actions.
- Kept destructive confirmation styling owned by the shared confirmation dialog from Increment 064.

### UX rationale

Users should immediately understand which action completes a task, which action is secondary, and which action is destructive. A consistent button hierarchy reduces hesitation in finance-entry workflows.

### Data impact

- No database, repository, transaction, recurring-rule, account, goal, debt, backup-schema, or migration changes.
- Save, delete, archive, validation, and persistence behavior remain unchanged.

## Increment 069 — Date Picker & Selector Polish

### Added

- Added a reusable `AppSelectorStyle` foundation for segmented controls and date-picker dialogs.
- Standardized segmented-button padding and rounded selection surfaces.
- Standardized the date-picker dialog shape with the same rounded visual language used across MoneyTracker Pro.

### Changed

- Applied the shared selector treatment to transaction type selection.
- Applied the same selector treatment to recurring transaction type selection.
- Applied the shared date-picker treatment to transaction dates and recurring due dates.
- Existing dropdown fields continue using the shared `AppFormStyle`, keeping selectors and text inputs visually aligned.

### Data impact

- No transaction, recurring-rule, category, repository, backup-schema, or migration changes.
- Date ranges, selected values, validation, and persistence behavior remain unchanged.

## Increment 068 — Recurring & Budget Form Polish

### Changed

- Extended the shared `AppFormStyle` to recurring-transaction and category-budget entry flows.
- Recurring rule title, amount, category, account, frequency, and due-date decorators now share the same field treatment through the existing `_decoration` helper.
- Category Budget monthly-limit editing now uses the same filled input surface, currency prefix, focus border, and error-state language as other money forms.
- Preserved recurring-rule editing, custom-category support, archived-category filtering, schedule generation, and category-budget calculations.

### UX rationale

Recurring money and category budgets are planning workflows, but they should feel identical to transaction, account, goal, and debt entry. This completes the core form-style rollout without changing financial behavior.

### Data impact

- No database, repository, recurring-rule, budget, category, backup-schema, or migration changes.
- Existing validation, persistence, and automatic recurring posting behavior remain unchanged.

## Increment 067 — Accounts, Goals & Debts Form Polish

### Changed

- Extended the shared `AppFormStyle` from transaction entry into Accounts, Savings Goals, and Debts.
- Standardized account-name and account-type fields.
- Standardized savings-goal name, target amount, and linked-account fields.
- Standardized debt name, type, original amount, outstanding balance, APR, and payment-amount fields.
- Preserved all existing validators, controllers, save flows, custom category behavior, and financial calculations.

### UX rationale

The most important money-entry forms now share one visual language. Users see consistent field radii, focus states, error states, icons, currency prefixes, and spacing across core finance workflows.

### Data impact

- No database, repository, account, goal, debt, transaction, backup-schema, or migration changes.
- Validation and persistence behavior remain unchanged.

## Increment 066.1 — Category-aware Transaction Sheet Hotfix

### Fixed

- Restored the required `categories` parameter on `AddTransactionSheet` after Increment 066 accidentally overwrote the newer category-aware transaction sheet with an older baseline.
- Restored custom-category selection, archived-category filtering, and category fallback behavior introduced earlier in the project.
- Preserved the Increment 066 shared `AppFormStyle` treatment by routing the transaction sheet's field decoration through the new form-style helper.
- Restores compatibility with Home and Transactions callers that already pass `categories:`.

### Data impact

- No transaction schema, repository, category storage, backup-schema, or migration changes.
- Existing custom categories and transaction data remain unchanged.

## Increment 066 — Form & Input Polish Foundation

### Added

- Added a reusable `AppFormStyle` foundation for consistent finance-entry forms.
- Standardized input radii, filled surfaces, focused/error borders, spacing, and full-width primary/secondary form button sizing.
- Began the migration with the transaction add/edit sheet, using the shared decoration for compatible simple fields.

### UX rationale

Transaction entry is the most frequent form workflow in MoneyTracker Pro. Starting here creates a stable input standard before migrating account, goal, debt, and recurring forms in smaller follow-up increments.

### Data impact

- No database, repository, transaction schema, validation rules, backup-schema, storage, or migration changes.
- Existing save/edit behavior remains unchanged.

## Increment 065 — Shared Confirmation Migration

### Changed

- Migrated transaction deletion to the shared destructive confirmation dialog.
- Migrated account archiving to the same confirmation system while preserving account history and restore behavior.
- Migrated Savings Goal deletion to the shared destructive confirmation dialog.
- Migrated Debt deletion to the shared destructive confirmation dialog.
- Standardized consequence-focused copy, destructive coloring, cancel/confirm order, and confirmation styling.

### UX rationale

Destructive actions now look and behave consistently across core money-management areas. Users receive clearer consequences before confirming without changing the underlying operation.

### Data impact

- No database, repository, transaction, account, goal, debt, backup-schema, storage, or migration changes.
- Delete, archive, restore, and undo behavior remain unchanged.

## Increment 064 — Dialog & Confirmation Foundation

### Added

- Added a reusable `AppConfirmDialog` component for consistent confirmation flows.
- Added normal and destructive confirmation tones.
- Standardized title hierarchy, explanatory copy, button order, rounded dialog shape, icon treatment, and destructive-action coloring.
- Added a dedicated `destructive()` helper for delete/archive-style operations.
- Cancel remains the safe default and destructive actions require an explicit confirmation.

### UX rationale

Confirmation dialogs are high-attention moments. A consistent structure reduces accidental actions and makes destructive operations easier to recognize across the app.

### Data impact

- No database, repository, transaction, account, settings, backup-schema, or migration changes.
- Existing page behavior remains unchanged until individual dialogs are migrated in later increments.

## Increment 063.1 — Analyzer Warning Hotfix

### Fixed

- Removed unused `AppFeedback` imports from Accounts, Savings Goals, and Transactions where the existing page structure did not yet use the shared feedback helper.
- Removed an unused `AppStateView` import from Accounts.
- Restores a warning-free analyzer state for the Increment 063 changes while preserving current UI and business behavior.

### Data impact

- No database, repository, transaction, account, goals, backup-schema, storage, or migration changes.

## Increment 063 — Shared Feedback Migration

### Changed

- Began migrating user-action feedback to the shared `AppFeedback` system introduced in Increment 062.
- Transactions now uses the shared feedback style for supported add/update/delete-with-undo flows.
- Accounts now uses the same success feedback for supported reconciliation and archive actions.
- Savings Goals now uses shared success feedback for supported save/delete actions.
- Preserved existing controller methods, undo behavior, navigation, and data mutations.

### UX rationale

Users should receive the same visual confirmation language regardless of which money feature they are using. This migration reduces one-off SnackBar styling while keeping action semantics unchanged.

### Data impact

- No database, repository, transaction, account, goals, backup-schema, storage, or migration changes.
- No undo or delete behavior was changed.

## Increment 062 — Feedback System Foundation

### Added

- Added a reusable `AppFeedback` utility for consistent in-app feedback.
- Added standardized success, error, informational, and undo feedback methods.
- Unified floating SnackBar shape, spacing, icon treatment, duration, and action styling.
- Added automatic replacement of the currently visible SnackBar so repeated actions do not stack multiple messages.

### UX rationale

Loading, empty, and error states are now standardized. The next layer of consistency is action feedback after users save, delete, restore, or encounter an operation failure. This foundation lets future screens migrate to one predictable feedback language without duplicating SnackBar styling.

### Data impact

- No database, repository, transaction, account, settings, backup-schema, or migration changes.
- No existing page behavior is changed until individual screens are migrated to `AppFeedback`.

## Increment 061 — Unified Loading & Retry States

### Changed

- Migrated the Transactions loading state to the shared `AppStateView`.
- Migrated the Home recent-activity loading state to the same shared loading pattern.
- Replaced the inline Accounts error message with the shared retry state and a direct **Try again** action.
- Standardized loading and failure language across the most frequently used areas without changing controller or repository behavior.

### UX rationale

Loading and failure should feel like part of the product rather than temporary developer placeholders. Users now see the same visual language and recovery pattern across Home, Transactions, and Accounts.

### Data impact

- No database, repository, transaction, account, backup-schema, storage, or migration changes.
- Existing controller load/retry behavior is reused as-is.

## Increment 060.1 — Transactions Empty-state Hotfix

### Fixed

- Removed the final leftover `_NoResults()` reference in Transactions after the shared `AppStateView` migration.
- Restores successful compilation without changing transaction filtering or data behavior.

### Data impact

- No data, repository, storage, backup, or migration changes.

## Increment 060 — Shared Empty States Migration

### Changed

- Migrated Transactions, Savings Goals, and Debts empty states to the shared `AppStateView` introduced in Increment 059.
- Preserved the first-use guidance and direct actions from Increment 052 while removing page-specific duplicate empty-state widgets.
- Standardized icon treatment, typography, spacing, and CTA behavior across migrated screens.
- Began using the same shared error-state component in Accounts when account loading reports an error.

### UX rationale

Users should not have to relearn what an empty or failed screen looks like in every feature. Shared states make the app feel intentionally designed while keeping each screen's message and next action contextual.

### Data impact

- No database, repository, storage, transaction, account, backup-schema, or migration changes.
- No existing add/edit/delete workflow was changed.

## Increment 059 — Loading, Empty & Error State Foundation

### Added

- Added a reusable `AppStateView` component for consistent **loading**, **empty**, and **error** states across MoneyTracker Pro.
- Standardized state typography, spacing, icon treatment, retry/action buttons, and maximum content width.
- Added dedicated constructors for loading, empty, and error scenarios so future pages can use the same product language without rebuilding one-off placeholders.

### UX rationale

The main navigation and first-use flows are now organized. The next layer of polish is consistency when content is unavailable, still loading, or fails to load. This shared component creates that foundation without changing existing financial behavior.

### Data impact

- No database, repository, storage, backup-schema, navigation, or migration changes.
- Existing pages remain behaviorally unchanged until migrated to the shared state component in subsequent increments.

## Increment 058 — Navigation & Icon Polish

### Changed

- Refined the bottom navigation icon language so each destination communicates its role more clearly.
- Changed **Insights** from a pie-chart metaphor to the dedicated `insights` icon.
- Changed **More** from a profile/person icon to a grid-style management icon, matching the broader setup and configuration role introduced in earlier UX consolidation.
- Removed bottom-navigation elevation and kept labels always visible for a cleaner, more stable primary navigation experience.
- Preserved the existing four-destination structure, IndexedStack state retention, and tab switching behavior.

### UX rationale

Navigation icons should describe the destination, not just the feature that originally occupied that tab. Insights is now clearly analytical, while More visually communicates a collection of management tools rather than a profile-only page.

### Data impact

- No database, repository, settings-storage, backup-schema, or migration changes.
- No navigation destination or feature was removed.

## Increment 057.1 — Transactions Warning Hotfix

### Fixed

- Removed the unused `_TransactionsSectionHeader` helper introduced in Increment 057.
- Clears the new `unused_element` analyzer warning without changing transaction UI behavior or data logic.

### Data impact

- No data, repository, storage, backup, or migration changes.

## Increment 057 — Transactions Priority Cleanup

### Changed

- Refined the **Transactions** screen into a clearer daily money-activity workspace.
- Simplified the orientation copy so users immediately understand that Transactions is for reviewing money in and out.
- Added a dedicated **Activity** section label to separate page guidance from the actual transaction history.
- Strengthened title and section hierarchy without changing search, filters, add/edit flows, or transaction behavior.
- Preserved all existing transaction types, transfer/reconciliation protections, repositories, and persistence.

### UX rationale

Transactions should feel like the operational history of the app, not another analytics page. This cleanup keeps the focus on records first and supporting controls second.

### Data impact

- No transaction schema, repository, storage, backup, or migration changes.
- No existing transaction functionality was removed.

## Increment 056 — More Priority Cleanup

### Changed

- Simplified the **More** screen hierarchy so the highest-value money-management tasks appear first.
- Renamed the top groups to clearer user-facing language: **Money Management**, **Planning**, **Your Preferences**, and **More Settings**.
- Kept Accounts as the primary structural entry and clarified that it manages balances and transfers.
- Renamed **Category budgets** to **Budgets** and **Recurring transactions** to **Recurring money** for simpler navigation language.
- Moved **Categories** into **More Settings** because category maintenance is lower-frequency than account, budget, goal, debt, and recurring-money management.
- Shortened the orientation message at the top of More.

### UX rationale

The More screen should surface the things users actively manage and push lower-frequency configuration one level down. This reduces scanning without removing any existing capability.

### Data impact

- No database, repository, backup-schema, settings-storage, or migration changes.
- No feature or navigation destination was removed.

## Increment 055 — Insights Priority Cleanup

### Changed

- Reduced the default Insights surface to one **Recommended for you** action plus three high-frequency tools: **Monthly Review**, **Safe to Spend**, and **Statistics**.
- Moved advanced planning and protection tools into an expandable **More tools** section instead of showing every capability at once.
- Kept Spending Pace, Spending Guard, Budget Stress Test, Action Plan, Emergency Fund, Savings Target, Surplus Allocation, and Income Stability fully accessible.
- Preserved the existing recommendation logic and monthly overview summary.

### UX rationale

Insights should guide, not overwhelm. Most users only need a small set of recurring actions; advanced tools remain available when intentionally requested.

### Data impact

- No database, repository, backup-schema, settings, or migration changes.
- No financial feature was removed.

## Increment 054 — Home Priority Cleanup

### Changed

- Simplified Home so it behaves like a daily financial dashboard instead of repeating report-style information.
- Removed the separate **This month net cash flow** card because the balance hero and Insights already communicate the same monthly position.
- Grouped the monthly budget and contextual guidance under one clear **This month** section.
- Moved **Recent transactions** ahead of the spending chart so the most actionable day-to-day information appears sooner.
- Kept the spending overview as a secondary section rather than a primary dashboard block.
- Preserved Quick Start for incomplete first-run setup and kept all existing financial calculations available through Insights.

### UX rationale

Home should answer **“What matters right now?”** with as little duplication as possible. Detailed monthly interpretation belongs in Insights, while Home prioritizes balance, budget status, guidance, and recent activity.

### Data impact

- No database, repository, transaction, settings, backup-schema, or migration changes.
- No financial feature was removed; only Home presentation priority changed.

## Increment 053 — Quick Start Onboarding

### Added

- Added a compact **Quick start** checklist to Home for users who have not finished basic setup.
- Guides first-time users through three practical steps: add real accounts, record the first transaction, and confirm a monthly budget.
- Shows setup progress and hides itself automatically once all three basics are ready.
- Added direct actions from the checklist to **More**, the add-transaction flow, and a lightweight monthly-budget editor.

### UX rationale

The app now teaches the minimum useful workflow without introducing a separate tutorial carousel. New users can start directly from the real Home screen and see each step disappear as their setup becomes complete.

### Data impact

- Uses existing account, transaction, and settings data.
- No database, repository, backup-schema, or migration changes.

## Increment 052 — Empty States & First-use Experience

### Changed

- Added action-oriented first-use guidance instead of leaving new users with blank or passive screens.
- Transactions now distinguishes a genuinely empty history from a search/filter with no results and offers a direct **Add first transaction** action.
- Savings Goals now explains the account dependency and offers **Create first goal** when an account is available.
- Debts now explains why liability tracking matters and offers a direct **Add a debt** action.
- Accounts now shows a lightweight first-use card when the app only has the default Cash account and no transaction history, guiding users to add real bank or e-wallet accounts.

### UX rationale

Empty states are part of the product flow, not error states. A first-time user should always understand what a screen is for, why it matters, and what the next useful action is.

### Data impact

- No database, repository, backup-schema, storage, or migration changes.
- No existing financial feature or record type was changed.

## Increment 051 — Visual System Unification

### Changed

- Unified the visual rhythm across **Home**, **Insights**, **Transactions**, and **More**.
- Standardized primary card radii, hero-card radii, compact surface radii, and section spacing so the four main destinations feel like one product.
- Tightened oversized spacing on the More and Insights screens while preserving readability.
- Refined the Transactions orientation panel to match the rest of the app’s card language.
- Added a shared `AppSurfaceTokens` foundation for future UI work so new screens can follow the same spacing and surface conventions.

### UX rationale

The app’s information architecture is now clearer after Increments 044–050. This increment makes that structure visually consistent, reducing the feeling that individual features were built at different times.

### Data impact

- No database, repository, backup-schema, transaction, account, or migration changes.
- No financial calculations or navigation destinations were removed.

## Increment 050 — Transactions UX Cleanup

### Changed

- Continued the navigation consolidation by clarifying the role of the **Transactions** destination.
- Added a lightweight orientation panel that explains Transactions as the place to review money activity and locate specific entries.
- Kept the existing transaction list, filters, search, add/edit flows, repositories, and persistence behavior intact.
- Strengthened the Transactions page title hierarchy without adding another financial feature.

### UX rationale

The four primary destinations now follow a simple mental model: **Home** shows the current state, **Insights** explains and guides, **Transactions** shows money movement, and **More** manages setup.

### Data impact

- No transaction schema, repository, storage, backup, or migration changes.

## Increment 049 — More Information Architecture

### Changed

- Reorganized the **More** screen into four clear groups: **Accounts & Structure**, **Planning & Automation**, **Personal Setup**, and **App & Data**.
- Added direct, organized access to existing **Savings Goals** and **Recurring Transactions** from More.
- Kept Accounts and Categories together as structural setup rather than mixing them with budgeting preferences.
- Grouped Category Budgets, Savings Goals, Debts, and Recurring Transactions around ongoing money management.
- Grouped personal details, monthly budget, and budget alerts under Personal Setup.
- Kept backup, currency, language, and app information under App & Data.
- Corrected the page title to **More** so the page itself matches the bottom-navigation label.

### UX rationale

The More area now answers **“What do I want to manage?”** without forcing users to scan one long mixed settings list. Existing features are organized by intent rather than implementation.

### Data impact

- No database, repository, backup-schema, or migration changes.
- No existing feature was removed or recreated.

## Increment 048 — Primary Navigation Cleanup

### Changed

- Renamed the fourth bottom-navigation destination from **Profile** to **More** so the label matches the broader management role introduced in Increment 047.
- The four primary destinations now have distinct jobs: **Home**, **Insights**, **Transactions**, and **More**.
- Kept the existing profile/settings page and navigation behavior intact; this is an information-architecture cleanup, not a feature removal.

### UX rationale

The previous **Profile** label suggested the page was only about the user's identity, even though it also contains account setup, planning tools, categories, backup, and preferences. **More** better communicates that this is the management area for lower-frequency tasks.

### Data impact

- No database, repository, backup-schema, or migration changes.

## Increment 047 — Profile / More Organization

### Changed

- Continued the UX consolidation by turning the last bottom-navigation area into a clearer **More** management destination.
- Added a short orientation panel explaining that account setup, budgets, goals, recurring items, and app preferences belong in this area, while Insights remains focused on financial guidance.
- Renamed management-oriented section language to be easier to understand without changing the underlying financial features or navigation actions.
- Preserved existing Profile identity/settings behavior and all existing management destinations.

### UX rationale

Home answers **“Where am I now?”**, Insights answers **“What does my money mean and what should I do?”**, Transactions answers **“What moved?”**, and More answers **“What do I want to manage?”**. This gives each primary navigation area one clear job.

### Data impact

- No database, repository, backup-schema, or migration changes.
- No existing financial feature was removed.

## Increment 045 — Focused Monthly Review

### Changed

- Simplified the primary Monthly Review experience into a focused financial report instead of a launcher for every advanced planner.
- Removed the long stack of action buttons from the Monthly Review opened through **Insights**.
- Monthly Review now concentrates on net cash flow, month-over-month comparisons, spending highlights, and the contextual monthly insight.
- Added a compact guidance card that directs users back to **Insights** when they want planning or decision tools.
- Existing advanced tools remain available and organized in the Insights hub; no financial capability was removed.

### UX rationale

A report answers **“What happened?”** while Insights answers **“What should I do next?”**. Separating those jobs reduces duplicate navigation and makes the app easier to understand for first-time users.

### Data impact

- No persistence, database, repository, backup-schema, or migration changes.

## Increment 044 — Financial Insights Hub & UX Consolidation

### Changed

- Reorganized advanced financial-analysis features behind a dedicated **Insights** destination instead of adding more top-level features.
- Replaced the bottom-navigation **Statistics** destination with **Insights**; full Statistics remains available inside Insights.
- Added a single **Recommended for you** card that selects one useful next action from the current month's data.
- Grouped existing tools into **Reports**, **Spend safely**, and **Plan ahead** so users do not need to understand every planner before using the app.
- Added an at-a-glance summary for net cash flow, savings rate, and Safe-to-Spend.
- Existing Increment 034–043 tools remain available; no financial logic was removed.

### Navigation

Home → Insights

### Data impact

- No database, repository, backup-schema, or migration changes.
- This increment reorganizes discovery and navigation around existing capabilities.

## Increment 043 --- Income Stability Planner --- Added

-   New Income Stability Planner under Monthly Financial Review.
-   Compares current-month income with the previous month and produces a
    0--100 stability score.
-   Classifies recent income as Building history, Stable, Watch, or
    Volatile.
-   Builds a conservative income baseline from recent income instead of
    budgeting from the strongest month.
-   Recommends an income reserve that automatically widens as income
    becomes more volatile.
-   Calculates a safe spending baseline and shows current spending
    headroom or overshoot.

### Navigation

Statistics → Monthly Review → Check my income stability

### Data

No database or persistence changes are required. The planner uses the
existing monthly review data.

## Increment 042 --- Savings Target Planner --- Added

-   Added a Savings Target Planner to Monthly Financial Review.
-   Added an adjustable 0--80% savings-rate target.
-   Calculates the savings amount required for the selected target.
-   Calculates the maximum monthly spending ceiling that protects the
    target.
-   Shows how much spending must be reduced when the target is not
    currently achievable.
-   Shows extra spending room when the current month is already ahead of
    the selected target.
-   Added contextual guidance for months with no income, targets already
    met, and targets requiring spending cuts.

### Navigation

Statistics → Monthly Review → Set a savings-rate target

## Increment 041 --- Surplus Allocation Planner --- Added

-   Added a monthly surplus allocation planner to Monthly Financial
    Review.
-   Added four allocation strategies: Balanced, Safety First, Debt
    First, and Goals First.
-   Automatically splits positive monthly net cash flow across emergency
    savings, extra debt payments, savings goals, and flexible money.
-   Added a dedicated allocation page with percentages, MYR amounts,
    strategy switching, and guidance for months without a positive
    surplus.

### Changed

-   Added a new `Allocate this month's surplus` entry point to Monthly
    Financial Review.

### Data impact

-   No database or repository migration is required.
-   The feature is calculated from the existing monthly financial review
    data.

## Increment 040 --- Emergency Fund Planner

Added a dedicated emergency-fund planning workflow to Monthly Financial
Review.

#### New

-   Calculates a recommended 3, 6, 9, or 12 month emergency reserve from
    recent monthly spending.
-   Lets the user enter the emergency fund they already have saved.
-   Calculates target amount, remaining gap, current months of coverage,
    and funding progress.
-   Supports a 3--36 month completion timeline and calculates the
    required monthly contribution.
-   Provides contextual guidance for zero history, low coverage,
    in-progress funding, and fully funded states.
-   Adds a new **Plan my emergency fund** entry point to Monthly
    Financial Review.

## Increment 039 --- Budget Stress Test --- Added

-   Added a Budget Stress Test to the Monthly Financial Review flow.
-   Simulate an income drop from 0% to 60%.
-   Add a hypothetical unexpected expense in MYR.
-   Recalculate projected income, expenses, net cash flow, and savings
    rate.
-   Classify the scenario as Safe, Caution, or Danger.
-   Provide contextual guidance based on the projected financial margin.

### Navigation

Statistics -\> Monthly Review -\> Run a budget stress test

## Increment 038 --- Spending Pace & Month-End Projection --- Added

-   Added a dedicated Spending Pace page from Monthly Financial Review.
-   Projects month-end expenses from the user's average daily spending
    pace.
-   Shows projected month-end net cash flow using currently recorded
    income.
-   Shows month elapsed and days remaining.
-   Compares the projected expense total with the previous month when
    comparison data exists.
-   Adds Ahead, Steady, and Watch states with plain-language guidance.

### Notes

-   This is a planning estimate based on spending recorded so far in the
    selected month.
-   No persistence keys, transaction schema, or backup schema changes
    are required.

## Increment 037 --- Spending Guard --- Added

-   Added a Spending Guard tool to evaluate a planned purchase before
    spending.
-   Shows whether a purchase is safe, cautionary, over the current
    limit, or unavailable.
-   Recalculates remaining safe-to-spend money and the daily allowance
    after the purchase.
-   Shows how much of the current flexible allowance the purchase would
    consume.
-   Added quick amount presets for common purchase checks.

### Navigation

-   Monthly Financial Review → Check a purchase with Spending Guard.

## Increment 036 --- Safe-to-Spend Limit --- Added

-   Safe-to-Spend calculator built from the selected monthly financial
    review.
-   Daily and weekly flexible-spending allowances.
-   Automatic 60% savings reserve and 20% emergency/flexible cash
    buffer.
-   Clear spending status for positive, negative, completed, or fully
    allocated months.
-   New entry point from Monthly Financial Review.

### Files

-   `lib/features/monthly_review/domain/models/safe_to_spend_plan.dart`
-   `lib/features/monthly_review/domain/services/safe_to_spend_service.dart`
-   `lib/features/monthly_review/presentation/pages/safe_to_spend_page.dart`
-   `lib/features/monthly_review/presentation/pages/monthly_financial_review_page.dart`

## Increment 035 --- Financial Action Plan

-   Added a new Financial Action Plan flow from Monthly Financial
    Review.
-   Added a 0--100 monthly action score based on cash flow, savings
    rate, spending direction, and savings momentum.
-   Added prioritized High / Medium / Low action items generated from
    the selected month's review.
-   Added recommended surplus allocation for savings and a flexible cash
    buffer.
-   Added category-focused and largest-expense recommendations when
    relevant.
-   Added a "Build my action plan" entry point to the Monthly Financial
    Review page.

### Files

-   `lib/features/monthly_review/domain/models/financial_action_plan.dart`
-   `lib/features/monthly_review/domain/services/financial_action_plan_service.dart`
-   `lib/features/monthly_review/presentation/pages/financial_action_plan_page.dart`
-   `lib/features/monthly_review/presentation/pages/monthly_financial_review_page.dart`
-   `CHANGELOG_INCREMENT_035.md`

## Increment 034 --- Monthly Financial Review

-   Added a dedicated monthly review accessible from the Statistics app
    bar.
-   Added month-over-month comparison for spending, income, savings
    rate, daily average spend and expense count.
-   Added current-month net cash flow, top spending category and largest
    expense highlights.
-   Added contextual review insights that react to improving savings,
    rising spending and falling spending.
-   Previous-month comparisons automatically follow the month currently
    selected in Statistics.
-   Transfers and reconciliation adjustments remain excluded from income
    and expense analytics.
-   No persistence keys, transaction schema changes or backup schema
    upgrades are required for this increment.

## Increment 033 --- Debt Payoff Planner --- Added

-   Added a dedicated Debt Payoff Planner accessible from Debts &
    liabilities.
-   Added Avalanche strategy ordering debts by highest APR first.
-   Added Snowball strategy ordering debts by smallest outstanding
    balance first.
-   Added an editable monthly payoff budget for scenario planning.
-   Added projected payoff duration, projected interest, payoff order,
    and per-debt target payoff month.
-   Added a safety state when the entered monthly budget cannot overcome
    projected interest.

### Notes

-   This increment is analysis-only and does not add persistence keys or
    change the backup schema.
-   The projection is intentionally simplified: monthly APR compounding
    plus strategy-ordered payments. It does not model lender minimum
    payments, fees, promotional rates, or changing APRs.

## Increment 032 --- Debt & Liability Tracking

-   Added a dedicated Debts & Liabilities module for credit cards,
    personal loans, car loans, mortgages and other liabilities.
-   Added original amount, outstanding balance, APR and target
    payoff/due date tracking.
-   Added repayment progress and direct payment recording.
-   Added Dashboard and Profile entry points with total outstanding debt
    summaries.
-   Updated Net Worth to subtract tracked liabilities from recorded
    account balances.
-   Updated Net Worth details to show tracked liabilities separately
    from account balances.
-   Backup schema upgraded to v7 and now includes debts; backup versions
    v1--v6 remain supported.

## Increment 031 --- Net Worth Tracking --- Added

-   Dashboard Net Worth summary card with current value and 30-day
    movement.
-   Dedicated Net Worth page with positive assets, negative balances and
    account allocation.
-   Six-month net worth trend calculated from existing transaction
    history.
-   Archived accounts remain part of net worth because archived money is
    still owned.

### Accounting behavior

-   Transfers remain net-zero at the portfolio level.
-   Reconciliation adjustments affect net worth because they correct
    recorded balances.
-   No new persistence key, transaction schema change or backup schema
    upgrade is required.

## Increment 030 --- Financial Health Score

-   Added a 0--100 Financial Health Score on the Dashboard.
-   Added a detailed Financial Health page with four weighted factors:
    -   Cash flow outlook (30 points)
    -   Budget discipline (25 points)
    -   Savings goals (20 points)
    -   Monthly savings rate (25 points)
-   Added plain-language summaries and recommended next actions for
    every factor.
-   Reuses existing transactions, category budgets, recurring rules,
    accounts, savings goals, and the 30-day cash-flow forecast.
-   No new persistence keys, transaction schema changes, or backup
    schema changes.
-   The score is clearly labeled as a planning indicator rather than a
    credit score or financial advice.

## Increment 029 --- Cash Flow Forecast

-   Added a dedicated 30-day cash flow forecast page.
-   Projects future recurring income and expenses from active accounts.
-   Shows projected income, projected expenses, lowest balance, and
    day-30 balance.
-   Detects the first projected date where the overall balance may fall
    below zero.
-   Added a detailed projected timeline grouped by due date.
-   Added a Dashboard cash-flow summary card with shortfall warnings.
-   Paused recurring rules and rules linked to archived accounts are
    excluded from the forecast.
-   No persistence or backup schema changes are required for this
    increment.

## Increment 028 --- Budget Alerts --- Added

-   Added a dedicated Budget Alerts center for monthly category budgets.
-   Added automatic 80% warning, 100% reached, and over-budget states.
-   Added recent spending context inside each alert so users can see
    what pushed a category toward its limit.
-   Added a one-tap path from Budget Alerts to Category Budget
    management.

### Dashboard

-   Category Budgets summary now reports categories that need attention,
    not only categories that are already over budget.
-   Tapping the Dashboard Category Budgets summary now opens Budget
    Alerts first.

### Accounting behavior

-   Alerts use current-month expense transactions only.
-   Transfers and reconciliation adjustments remain excluded through
    `countsAsExpense`.
-   No persistence or backup schema changes are required in this
    increment.

## Increment 027 --- Category Budgets --- Added

-   Per-category monthly budget limits for expense categories.
-   Dashboard summary showing how many category budgets are on track or
    exceeded.
-   Category budget management from Profile and Transactions.
-   Current-month spent, remaining, and over-budget progress per
    category.
-   Local persistence using SharedPreferencesAsync.
-   Backup schema v6 with category budget export/restore support.

### Compatibility

-   Existing category and transaction data remains unchanged.
-   Transfers and reconciliation adjustments are excluded from category
    spending.
-   Backup versions v1--v5 remain restorable; they simply start with no
    category budgets.

## Increment 026 --- Custom Categories

-   Added persistent custom income and expense categories.
-   Added category management under Profile \> Categories.
-   Categories can be created with a name, icon, color, and transaction
    type.
-   Existing categories can be renamed, recolored, re-iconed,
    deactivated, and restored.
-   Deactivated categories remain attached to historical transactions
    and existing recurring rules, but are hidden from new selections.
-   Transaction and recurring editors now share the same active category
    source.
-   Renaming a category updates existing transaction and recurring-rule
    references.
-   Recurring auto-posting resolves custom categories so generated
    transactions keep the configured icon and color.
-   Backup schema upgraded to v5 and now includes categories.
-   Backup versions v1-v4 remain compatible and restore with default
    categories.

## Increment 025.1 --- Test environment hotfix

-   Replaces the full-app widget smoke test with a root-construction
    test.
-   Avoids instantiating `SharedPreferencesAsync` inside a Flutter
    widget-test environment where no desktop plugin implementation is
    registered.
-   Keeps production repositories, UI, account data, transactions,
    recurring rules, savings goals, and backup schemas unchanged.
-   `flutter analyze` remains unaffected; this hotfix targets the
    failing `flutter test` path reported after Increment 025.

## Increment 025 --- Engineering health cleanup

-   Replaced the stale Flutter counter widget test with a MoneyTracker
    Pro smoke test.
-   Added mocked SharedPreferences state so the app shell can be
    exercised without touching real local data.
-   Added a mounted guard after the transfer-actions dialog async gap.
-   No transaction, account, recurring, savings-goal, backup, or UI
    behavior was changed.

### Verification target

Run:

``` powershell
flutter analyze
flutter test
flutter run
```

## Increment 024 --- Savings Goals --- Added

-   Local Savings Goals persistence with SharedPreferences.
-   Create savings goals with target amount, linked account, and
    deadline.
-   Goal progress is calculated automatically from the linked account
    balance.
-   Remaining amount, percentage complete, and suggested monthly saving
    amount.
-   Savings Goals shortcut card on the Dashboard.
-   Account deletion guard when a savings goal is linked to the account.
-   Savings Goals are included in backup/restore.

### Backup

-   Backup schema upgraded from v3 to v4.
-   v1, v2, and v3 backups remain supported.

## Increment 023 --- Upcoming recurring reminder center

-   Added a dashboard `Upcoming recurring` card so scheduled money is
    visible without opening the recurring rules manager.
-   Added a dedicated reminder center with:
    -   rules needing attention,
    -   recurring transactions due in the next 7 days,
    -   later scheduled rules,
    -   30-day recurring income and expense forecast.
-   Archived or unavailable accounts are surfaced as attention items
    instead of silently disappearing.
-   Paused rules stay out of reminder totals until resumed.
-   The reminder center links back to the existing Recurring manager for
    editing, pausing, resuming, or deleting rules.
-   No persistence schema changes are required; Increment 021/022
    recurring data remains compatible.

## Increment 022 --- Recurring transaction editing & next-run preview

-   Added safe editing for existing recurring transaction rules.
-   Edit name, amount, income/expense type, category, active account,
    repeat frequency, and next due date.
-   Preserves the recurring rule ID so already-generated occurrences
    remain deduplicated.
-   Added human-friendly next-run previews such as `Due tomorrow` and
    `Due in 5 days`.
-   Existing pause/resume/delete behavior is unchanged.
-   Archived accounts remain unavailable for new recurring postings;
    editing a rule tied to an archived account requires selecting an
    active account before saving.
-   No storage schema migration is required; existing Increment 021
    recurring-rule data remains compatible.

## Increment 021 --- Recurring Transactions

-   Added recurring transaction rules for repeating income and expenses.
-   Supports weekly, monthly, and yearly schedules.
-   Added a Recurring management page from the Transactions screen.
-   Rules can be paused, resumed, or deleted without affecting
    already-posted transactions.
-   Due occurrences are posted automatically when the app starts and
    when returning from the Recurring page.
-   Added deterministic occurrence IDs to prevent duplicate posting when
    the app is opened repeatedly.
-   Missed occurrences are caught up safely, with a defensive processing
    limit.
-   Recurring rules only post to active accounts; archived accounts are
    skipped until restored.
-   Recurring data is stored locally in SharedPreferences using a
    versioned storage key, ready for future database migration.
-   Backup schema upgraded to v3 so recurring rules are included in
    copy/restore; v1/v2 backups remain compatible.

## Increment 020 --- Account Archiving --- Added

-   Archive inactive bank, e-wallet, savings, and custom accounts
    without deleting their history.
-   Archived Accounts manager with account balance, transaction count,
    historical detail access, and one-tap restore.
-   Undo action immediately after archiving an account.
-   Backward-compatible persistence for the new `isArchived` account
    flag.
-   Backup export/import now preserves archived account state.

### Behaviour

-   Archived accounts are hidden from the normal Accounts list.
-   Archived accounts cannot be selected for new transactions or new
    transfers until restored.
-   Historical transactions remain untouched and archived balances
    continue to count toward the user's real combined balance.
-   Existing transactions and transfers can still resolve archived
    account names correctly.
-   The default Cash account cannot be archived.

### Compatibility

-   Existing stored accounts without `isArchived` load as active
    automatically.
-   Existing backup files remain importable; missing `isArchived` values
    default to `false`.
-   No transaction schema or transfer pairing format changes are
    required.

## Increment 019 --- Account Reconciliation

-   Added account reconciliation from Account Detail.
-   Enter the actual balance from a bank, e-wallet, savings account, or
    cash count.
-   Automatically calculates the difference between book balance and
    actual balance.
-   Creates a dedicated reconciliation adjustment to bring the ledger
    back in sync.
-   Supports positive and negative real-world balances.
-   Reconciliation adjustments affect real account balances and total
    dashboard balance.
-   Reconciliation adjustments are excluded from income, expenses,
    budgets, alerts, and statistics.
-   Monthly statements now show reconciliation adjustments separately
    from income, expenses, and transfers.
-   Transactions adds a Reconcile filter and dedicated reconciliation
    details dialog.
-   Dashboard system-record hardening prevents transfers and
    reconciliation adjustments from being edited or deleted as ordinary
    transactions.
-   No storage-key, backup-schema, or transaction-record migration is
    required.

## Increment 018 --- Account monthly statements

-   Added a dedicated monthly statement view for every finance account.
-   Added month-by-month navigation from the account detail page.
-   Added opening balance and closing balance calculations for the
    selected month.
-   Added separate monthly totals for normal income, normal expenses,
    transfer-in, and transfer-out.
-   Added net account movement for the selected statement period.
-   Added a statement activity ledger scoped to the selected account and
    month.
-   Transfer records continue to affect real account balances without
    being misclassified as income or expenses.
-   Existing transaction storage, transfer pairing, backup data, and
    account schemas remain unchanged.

## Increment 017 --- Transfer editing

-   Added safe editing for existing account transfers.
-   Transfer source account, destination account, amount, date, and note
    can now be changed.
-   Both linked transfer records are updated atomically through
    `replaceAll`, keeping account balances synchronized.
-   Existing transfer IDs are preserved, so Increment 016 cancel/undo
    pairing remains compatible.
-   Added **Edit** actions to transfer details on the Transactions page.
-   Added **Edit** actions to transfer activity inside Account Detail.
-   Reused the existing Transfer Funds sheet in edit mode with
    pre-filled values and edit-specific copy.
-   Transfer edits continue to be excluded from income, expense, budget,
    statistics, and alert totals.

### Compatibility

-   No SharedPreferences key changes.
-   No transaction JSON/schema changes.
-   Existing Increment 015/016 transfers remain editable.

## Increment 016 --- Safe transfer cancellation & paired transfer management

#### Added

-   Transfer entries now expose their shared transfer group ID so the
    outgoing and incoming sides can be handled as one atomic operation.
-   Tapping a transfer in **Transactions** opens a transfer details
    dialog with amount, source account, destination account, date, and
    note.
-   Added **Cancel transfer** support that removes both linked transfer
    records together.
-   Added **UNDO** after cancelling a transfer; both linked records are
    restored together.
-   Transfer records can also be cancelled safely from an **Account
    Detail** page.
-   Incomplete or malformed transfer pairs are protected and will not be
    partially removed.

#### Fixed

-   Account Detail `Current balance` now includes transfer
    inflows/outflows, matching the balance shown on the Accounts page.
-   Income and spending metrics continue to exclude transfers, so
    transfers do not inflate reports, budgets, or spending totals.

#### Data compatibility

-   No SharedPreferences storage key changes.
-   No backup schema changes.
-   Existing Increment 015 transfer IDs are used to derive transfer
    pairing, so no migration is required.

## Increment 015 --- Account-to-account transfers --- Added

-   Transfer funds action on the Accounts page
-   Source and destination account selectors with one-tap swap
-   Transfer amount, optional note, and date fields
-   Atomic two-sided transfer entries so both account ledgers stay
    synchronized
-   Transfer filter in transaction history

### Accounting behavior

-   Transfers reduce the source account balance and increase the
    destination account balance
-   Transfers do not count as income, spending, budget usage, savings
    rate, spending charts, or financial alerts
-   Transfer history is protected from single-sided edit/delete actions
    to prevent broken account balances

### Compatibility

This increment reuses the existing transaction storage and backup
format. No SharedPreferences key or backup schema migration is required.

## Increment 014 --- Account detail ledger --- Added

-   Dedicated detail page for every Cash, Bank, E-Wallet, and Savings
    account
-   Live per-account balance, total income, and total spending metrics
-   Date-grouped transaction activity scoped to the selected account
-   Today and yesterday labels for recent account activity
-   Empty-state guidance for accounts without transactions

### Changed

-   Account cards are now tappable destinations instead of
    management-only rows
-   Account cards now expose a chevron while preserving safe delete
    behavior
-   Account detail values react to the shared dashboard transaction
    state

### Compatibility

This increment is presentation-only and does not change transaction,
account, settings, or backup storage formats. Existing Increment 013
data works without migration.

## Increment 013 --- Multi-account and wallet system --- Added

-   Cash, bank, E-Wallet, and savings account types
-   Persistent account repository and shared controller
-   Account management page with per-account balances
-   Account selector in create and edit transaction forms
-   Used-account deletion protection
-   Default Cash account deletion protection

### Changed

-   Transactions now store a stable account ID
-   Existing transactions without an account automatically migrate to
    Cash
-   Profile shows account management and live account count
-   Backup schema upgraded to version 2 with accounts
-   Version 1 backups remain importable and migrate to Cash

### Data integrity

Backup restore rejects missing account references and duplicate account
IDs. Accounts with linked transactions cannot be deleted.

## Increment 012 --- Safe deletion and working dashboard navigation --- Added

-   Undo action after transaction deletion
-   Controller-level restoration using the original transaction ID
-   Delete confirmation on the dashboard
-   Dashboard callback into the shared application shell

### Changed

-   `See all` now switches directly to the Transactions tab
-   Dashboard and history use the same delete-and-undo behavior
-   Static section actions no longer look incorrectly interactive

### Data safety

Undo restores the complete original transaction object, including its
ID, date, category, type, amount, icon, and color.

## Increment 011 --- Data backup and restore --- Added

-   Versioned MoneyTracker Pro JSON backup format
-   Full transaction and settings export
-   Clipboard-based cross-platform backup copying
-   Backup validation before restoration
-   Duplicate ID and invalid value detection
-   Restore confirmation and live application refresh
-   Clear-all workflow with destructive confirmation
-   Data & Backup destination in Profile

### Changed

-   Transaction repositories support atomic full-list replacement
-   Shared controllers expose controlled restore operations

### Compatibility

The clipboard workflow works on Android, iOS, Web, Windows, macOS, and
Linux without adding platform-specific file permissions.

## Increment 010 --- Financial alerts center --- Added

-   Rule-based financial alert service
-   Budget-near-limit and budget-exceeded alerts
-   Large single-expense detection
-   Positive monthly savings insight
-   No-activity onboarding alert
-   Functional alerts page with severity styling
-   Live notification badge on the dashboard bell

### Changed

-   Dashboard notification button now opens a real destination
-   Alert count updates after transactions or settings change
-   Disabling budget alerts immediately removes budget warnings

### Privacy

Alerts are derived locally from the existing transaction and settings
state. No financial data is transmitted.

## Increment 009 --- Live dashboard spending overview --- Added

-   Real seven-day expense aggregation
-   Previous seven-day comparison period
-   Dynamic percentage increase or decrease
-   Safe labels for new activity and zero-to-zero comparisons
-   Dynamic chart points and weekday labels

### Changed

-   Dashboard spending total is no longer hardcoded
-   Dashboard line chart now responds to transaction create, update, and
    delete operations
-   Expense decreases use a positive success state; increases use a
    warning state

### Data integrity

Only expense transactions are included. Income transactions do not
distort spending trends.

## Increment 008 --- Month navigation and dated history --- Added

-   Previous and next month navigation on Statistics
-   Future-month navigation guard
-   This month, last month, and all-time transaction periods
-   Date-grouped transaction history
-   Today and yesterday labels

### Changed

-   Monthly income, expense, savings rate, category chart, and seven-day
    chart now follow the selected month
-   Transaction count and filtered total include the selected period
-   Past-month seven-day chart ends on the final day of that month

### Compatibility

This increment changes presentation-derived filters only. Existing saved
transaction data requires no migration.

## Increment 007 --- Complete transaction editing --- Added

-   Repository-level transaction update operation
-   Controller update workflow with error handling
-   Edit mode for the shared transaction form
-   Pre-filled title, amount, type, category, and date
-   Tap-to-edit interactions on dashboard and transaction history

### Changed

-   Transaction tiles now support an optional action with Material touch
    feedback
-   The same validated form handles both create and update operations
-   Updated transactions immediately refresh balance, budget,
    statistics, and history

### Persistence

Edits replace the matching stored record by stable transaction ID and
remain available after application restart.

## Increment 006 --- Profile, preferences, and budgeting --- Added

-   Persistent profile and application settings repository
-   Shared settings controller with optimistic updates and rollback
-   Functional profile tab
-   Editable display name and monthly budget
-   Persistent budget-alert preference
-   Monthly budget progress card with warning and overspend states
-   Application information dialog

### Changed

-   Dashboard greeting uses the saved display name
-   Dashboard derives current-month spending for the budget card
-   Profile placeholder replaced by a production settings page
-   App shell owns and disposes both shared controllers

### Storage

Settings use separately versioned keys so future migrations can be
introduced without affecting saved transactions.

## Increment 005 --- Live financial statistics --- Added

-   Functional statistics tab backed by real transaction state
-   Current-month income, expenses, and savings-rate summary
-   Native seven-day expense bar chart
-   Native spending-category donut chart
-   Category totals, percentages, colors, and icons
-   Empty statistics state and pull-to-refresh

### Changed

-   Statistics placeholder replaced by a production page
-   Every statistic now updates when a transaction is created or deleted

### Technical notes

Charts are painted with Flutter `CustomPainter`; no chart dependency was
added. All values are derived from the shared dashboard controller, so
no duplicate analytics data is stored.

## Increment 004 --- App shell and transaction history --- Added

-   Shared application shell with persistent bottom navigation
-   Full transaction history page
-   Search by transaction title or category
-   All, income, and expense filters
-   Filtered record count and signed total
-   Pull-to-refresh
-   Delete confirmation dialog
-   Add transaction action from the history page

### Changed

-   Dashboard and transaction history now share one controller and
    repository
-   Bottom navigation now changes real pages instead of only changing
    icon state
-   Dashboard controller lifecycle is owned by the application shell

### Architecture

`HomeShell` is now the composition root for signed-in application
features. This prevents duplicate repositories and keeps financial state
synchronized across tabs.

## Increment 003 --- Cross-platform local persistence --- Added

-   `shared_preferences` 2.5.5 using the modern asynchronous API
-   Versioned local storage key: `moneytracker.transactions.v1`
-   Transaction JSON record mapping isolated from the domain entity
-   Persistent repository implementation
-   Storage format validation and typed storage exceptions

### Changed

-   Dashboard now uses `LocalTransactionRepository`
-   Added and deleted transactions survive application restarts
-   Delete failures are handled by the dashboard controller

### Compatibility

The selected persistence layer supports Android, iOS, Web, Windows,
macOS, and Linux. The repository contract remains unchanged, allowing
migration to SQLite or Firestore later.

### Replaced implementation

`in_memory_transaction_repository.dart` is no longer used. It may remain
in the project for tests or be deleted manually.

## Increment 002 --- Functional transaction core --- Added

-   Repository contract with an in-memory implementation
-   Dashboard `ChangeNotifier` controller and derived financial totals
-   Validated add-transaction form
-   Income and expense selector
-   Category and transaction-date selection
-   Swipe-to-delete transaction interaction
-   Loading and empty dashboard states

### Changed

-   Dashboard balance, income, expenses, and recent activity now update
    from live state
-   Add transaction sheet moved into the transactions feature

### Next migration boundary

The in-memory repository intentionally isolates persistence. A later
increment can replace it with SQLite or Firestore without changing
dashboard widgets.

------------------------------------------------------------------------

## Changelog maintenance policy

Going forward, new work should be appended to this single `CHANGELOG.md`
rather than creating another fragmented changelog file. Each increment
should document user-visible additions, behavior changes, fixes,
data/backup impact, and compatibility notes when relevant. Pure
formatting or refactoring work should only be recorded when it
materially affects maintainability, testing, architecture, or release
safety.
