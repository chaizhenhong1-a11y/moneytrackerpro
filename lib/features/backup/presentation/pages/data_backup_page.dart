import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../../category_budgets/presentation/controllers/category_budget_controller.dart';
import '../../../accounts/presentation/controllers/account_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../recurring/presentation/controllers/recurring_transaction_controller.dart';
import '../../../goals/presentation/controllers/savings_goal_controller.dart';
import '../../../debts/presentation/controllers/debt_controller.dart';
import '../../application/moneytracker_backup_service.dart';

class DataBackupPage extends StatelessWidget {
  const DataBackupPage({
    required this.dashboardController,
    required this.settingsController,
    required this.accountController,
    required this.recurringController,
    required this.savingsGoalController,
    required this.categoryController,
    required this.categoryBudgetController,
    required this.debtController,
    super.key,
  });

  final DashboardController dashboardController;
  final SettingsController settingsController;
  final AccountController accountController;
  final RecurringTransactionController recurringController;
  final SavingsGoalController savingsGoalController;
  final CategoryController categoryController;
  final CategoryBudgetController categoryBudgetController;
  final DebtController debtController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([dashboardController, settingsController, accountController, recurringController, savingsGoalController, categoryController, categoryBudgetController, debtController]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Data & backup', style: TextStyle(fontWeight: FontWeight.w800))),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _DataSummary(transactionCount: dashboardController.transactions.length),
            const SizedBox(height: 22),
            const Text('BACKUP', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .8)),
            const SizedBox(height: 9),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const _DataIcon(icon: Icons.copy_all_outlined),
                    title: const Text('Copy backup', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Copy all local finance data as JSON'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _copyBackup(context),
                  ),
                  const Divider(height: 1, indent: 64),
                  ListTile(
                    leading: const _DataIcon(icon: Icons.settings_backup_restore_rounded),
                    title: const Text('Restore backup', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Paste a MoneyTracker Pro backup'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showRestoreDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('DANGER ZONE', style: TextStyle(color: AppColors.expense, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .8)),
            const SizedBox(height: 9),
            Card(
              child: ListTile(
                leading: const _DataIcon(icon: Icons.delete_sweep_outlined, danger: true),
                title: const Text('Clear all transactions', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700)),
                subtitle: const Text('This cannot be undone without a backup'),
                onTap: () => _confirmClear(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyBackup(BuildContext context) async {
    final backup = MoneyTrackerBackupService.encode(
      transactions: dashboardController.transactions,
      settings: settingsController.settings,
      accounts: accountController.accounts,
      recurringRules: recurringController.rules,
      savingsGoals: savingsGoalController.goals,
      categories: categoryController.categories,
      categoryBudgets: categoryBudgetController.budgets,
      debts: debtController.debts,
    );
    await Clipboard.setData(ClipboardData(text: backup));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup copied to clipboard.')),
    );
  }

  Future<void> _showRestoreDialog(BuildContext context) async {
    final textController = TextEditingController();
    final backup = await showDialog<MoneyTrackerBackupData>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore backup'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: textController,
            minLines: 7,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Paste backup JSON here',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              try {
                final parsed = MoneyTrackerBackupService.decode(textController.text.trim());
                Navigator.pop(dialogContext, parsed);
              } on BackupFormatException catch (error) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
            child: const Text('Validate'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (backup == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Replace existing data?'),
            content: Text('This backup contains ${backup.transactions.length} transactions. Current transactions and settings will be replaced.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Restore')),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final settingsSaved = await settingsController.replaceSettings(backup.settings);
    final accountsSaved = await accountController.replaceAll(backup.accounts);
    final transactionsSaved = await dashboardController.replaceAllTransactions(backup.transactions);
    final recurringSaved = await recurringController.replaceAll(backup.recurringRules);
    final goalsSaved = await savingsGoalController.replaceAll(backup.savingsGoals);
    final categoriesSaved = await categoryController.replaceAll(backup.categories);
    final categoryBudgetsSaved = await categoryBudgetController.replaceAll(backup.categoryBudgets);
    final debtsSaved = await debtController.replaceAll(backup.debts);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(settingsSaved && accountsSaved && transactionsSaved && recurringSaved && goalsSaved && categoriesSaved && categoryBudgetsSaved && debtsSaved ? 'Backup restored successfully.' : 'Some backup data could not be restored.')),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Clear all transactions?'),
            content: const Text('Create a backup first if you may need this data again.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Clear all'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final cleared = await dashboardController.replaceAllTransactions(const []);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(cleared ? 'All transactions cleared.' : 'Unable to clear transactions.')),
    );
  }
}

class _DataSummary extends StatelessWidget {
  const _DataSummary({required this.transactionCount});
  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF826CEB), AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), shape: BoxShape.circle), child: const Icon(Icons.cloud_done_outlined, color: Colors.white)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$transactionCount saved transactions', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 4), const Text('Stored locally on this device', style: TextStyle(color: Color(0xFFDCD6FF), fontSize: 12))])),
        ],
      ),
    );
  }
}

class _DataIcon extends StatelessWidget {
  const _DataIcon({required this.icon, this.danger = false});
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.expense : AppColors.primary;
    return Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20));
  }
}
