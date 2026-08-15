import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../goals/presentation/controllers/savings_goal_controller.dart';
import '../../domain/entities/finance_account.dart';
import '../controllers/account_controller.dart';
import '../widgets/transfer_funds_sheet.dart';
import 'account_detail_page.dart';
import 'archived_accounts_page.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({required this.controller, required this.dashboardController, required this.savingsGoalController, super.key});

  final AccountController controller;
  final DashboardController dashboardController;
  final SavingsGoalController savingsGoalController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, dashboardController, savingsGoalController]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Accounts', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'Transfer funds',
              onPressed: controller.activeAccounts.length < 2 ? null : () => _showTransfer(context),
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
            IconButton(onPressed: () => _showAddAccount(context), icon: const Icon(Icons.add_circle_outline_rounded)),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _AccountsSummary(
              count: controller.activeAccounts.length,
              balance: dashboardController.balance,
            ),
            const SizedBox(height: 20),
            ...controller.activeAccounts.map((account) {
              final transactions = dashboardController.transactions.where((item) => item.accountId == account.id).toList();
              final balance = transactions.fold<double>(0, (sum, item) => sum + item.signedAmount);
              return _AccountCard(
                account: account,
                balance: balance,
                transactionCount: transactions.length,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => AccountDetailPage(
                      account: account,
                      dashboardController: dashboardController,
                      allAccounts: controller.accounts,
                    ),
                  ),
                ),
                onArchive: account.id == FinanceAccountIds.cash
                    ? null
                    : () => _archiveAccount(context, account),
                onDelete: () => _deleteAccount(
                  context,
                  account,
                  transactions.isNotEmpty || savingsGoalController.goals.any((goal) => goal.accountId == account.id),
                ),
              );
            }),
            if (controller.archivedAccounts.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.archive_outlined, color: AppColors.primary),
                  title: const Text('Archived accounts', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${controller.archivedAccounts.length} hidden from daily use'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => ArchivedAccountsPage(
                        controller: controller,
                        dashboardController: dashboardController,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (controller.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(controller.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.expense)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTransfer(BuildContext context) async {
    if (controller.activeAccounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least two accounts before transferring funds.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransferFundsSheet(
        controller: dashboardController,
        accounts: controller.activeAccounts,
      ),
    );
  }

  Future<void> _showAddAccount(BuildContext context) async {
    final nameController = TextEditingController();
    var type = FinanceAccountType.bank;
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add account'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Account name', prefixIcon: Icon(Icons.account_balance_wallet_outlined), border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().length < 2 ? 'Enter at least 2 characters' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<FinanceAccountType>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Account type', border: OutlineInputBorder()),
                  items: FinanceAccountType.values.map((value) => DropdownMenuItem(value: value, child: Text(_typeName(value)))).toList(),
                  onChanged: (value) => setDialogState(() => type = value ?? type),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final saved = await controller.addAccount(name: nameController.text, type: type);
                if (saved && dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
  }

  Future<void> _archiveAccount(BuildContext context, FinanceAccount account) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Archive account?'),
            content: Text(
              '${account.name} will be hidden from new transactions and transfers. Its balance and history will be preserved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archive'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    final archived = await controller.archiveAccount(account.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          archived
              ? '${account.name} archived.'
              : controller.errorMessage ?? 'Unable to archive account.',
        ),
        action: archived
            ? SnackBarAction(
                label: 'UNDO',
                onPressed: () => controller.restoreAccount(account.id),
              )
            : null,
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, FinanceAccount account, bool isUsed) async {
    final linkedGoal = savingsGoalController.goals.any((goal) => goal.accountId == account.id);
    if (linkedGoal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete or move savings goals linked to this account first.')),
      );
      return;
    }
    final deleted = await controller.deleteAccount(account.id, isUsed: isUsed);
    if (!context.mounted || deleted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(controller.errorMessage ?? 'Unable to delete account.')),
    );
  }

  static String _typeName(FinanceAccountType type) => switch (type) {
        FinanceAccountType.cash => 'Cash',
        FinanceAccountType.bank => 'Bank account',
        FinanceAccountType.eWallet => 'E-Wallet',
        FinanceAccountType.savings => 'Savings',
      };
}

class _AccountsSummary extends StatelessWidget {
  const _AccountsSummary({required this.count, required this.balance});
  final int count;
  final double balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF826CEB), AppColors.primaryDark]), borderRadius: BorderRadius.circular(26)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Combined transaction balance', style: TextStyle(color: Color(0xFFDCD6FF))), const SizedBox(height: 5), Text(CurrencyFormatter.myr(balance), style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800))])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(16)), child: Text('$count accounts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.balance,
    required this.transactionCount,
    required this.onTap,
    required this.onDelete,
    this.onArchive,
  });
  final FinanceAccount account;
  final double balance;
  final int transactionCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final style = _style(account.type);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: style.color.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)), child: Icon(style.icon, color: style.color)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(account.name, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 5), Text('$transactionCount transactions', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(CurrencyFormatter.myr(balance), style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 2), Row(mainAxisSize: MainAxisSize.min, children: [if (onArchive != null) InkWell(onTap: onArchive, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.archive_outlined, color: AppColors.textSecondary, size: 18))), if (account.id != FinanceAccountIds.cash) InkWell(onTap: onDelete, child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 18))), const SizedBox(width: 2), const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20)])]),
          ]),
        ),
      ),
    );
  }

  _AccountStyle _style(FinanceAccountType type) => switch (type) {
        FinanceAccountType.cash => const _AccountStyle(Icons.payments_outlined, AppColors.success),
        FinanceAccountType.bank => const _AccountStyle(Icons.account_balance_outlined, AppColors.primary),
        FinanceAccountType.eWallet => const _AccountStyle(Icons.phone_android_rounded, Color(0xFF5D9CEC)),
        FinanceAccountType.savings => const _AccountStyle(Icons.savings_outlined, Color(0xFFE96CB5)),
      };
}

class _AccountStyle {
  const _AccountStyle(this.icon, this.color);
  final IconData icon;
  final Color color;
}
