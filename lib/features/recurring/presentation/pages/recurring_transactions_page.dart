import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../accounts/presentation/controllers/account_controller.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../domain/entities/recurring_transaction_rule.dart';
import '../controllers/recurring_transaction_controller.dart';
import '../widgets/add_recurring_rule_sheet.dart';

class RecurringTransactionsPage extends StatelessWidget {
  const RecurringTransactionsPage({
    required this.controller,
    required this.accountController,
    required this.categoryController,
    super.key,
  });

  final RecurringTransactionController controller;
  final AccountController accountController;
  final CategoryController categoryController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, accountController, categoryController]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Recurring', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'Add recurring transaction',
              onPressed: accountController.activeAccounts.isEmpty ? null : () => _openAdd(context),
              icon: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : controller.rules.isEmpty
                ? _EmptyState(onAdd: () => _openAdd(context))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(22)),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                            SizedBox(width: 12),
                            Expanded(child: Text('Due rules are posted automatically when MoneyTracker opens.', style: TextStyle(fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...controller.rules.map((rule) => _RuleCard(
                            rule: rule,
                            accountName: _accountNameFor(rule.accountId),
                            onEdit: () => _openEdit(context, rule),
                            onPause: () => controller.togglePaused(rule),
                            onDelete: () => _delete(context, rule),
                          )),
                    ],
                  ),
      ),
    );
  }

  String _accountNameFor(String id) {
    for (final account in accountController.accounts) {
      if (account.id == id) return account.name;
    }
    return 'Unavailable account';
  }

  Future<void> _openAdd(BuildContext context) async {
    final accounts = accountController.activeAccounts;
    if (accounts.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRecurringRuleSheet(
        controller: controller,
        accounts: accounts,
        categories: categoryController.categories,
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, RecurringTransactionRule rule) async {
    final accounts = accountController.activeAccounts;
    if (accounts.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddRecurringRuleSheet(
        controller: controller,
        accounts: accounts,
        categories: categoryController.categories,
        initialRule: rule,
      ),
    );
  }

  Future<void> _delete(BuildContext context, RecurringTransactionRule rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recurring rule?'),
        content: Text('Future “${rule.title}” transactions will no longer be created. Existing transactions stay unchanged.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteRule(rule.id);
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.accountName,
    required this.onEdit,
    required this.onPause,
    required this.onDelete,
  });

  final RecurringTransactionRule rule;
  final String accountName;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final frequency = switch (rule.frequency) {
      RecurringFrequency.weekly => 'Weekly',
      RecurringFrequency.monthly => 'Monthly',
      RecurringFrequency.yearly => 'Yearly',
    };
    final sign = rule.type.name == 'income' ? '+' : '-';
    final duePreview = _duePreview(rule.nextDueDate);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: rule.isPaused ? AppColors.border : AppColors.primarySoft,
              child: Icon(rule.isPaused ? Icons.pause_rounded : Icons.repeat_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '$frequency • $accountName',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$duePreview • ${rule.nextDueDate.day}/${rule.nextDueDate.month}/${rule.nextDueDate.year}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  if (rule.isPaused) const Padding(padding: EdgeInsets.only(top: 4), child: Text('Paused', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$sign${CurrencyFormatter.myr(rule.amount)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'pause':
                        onPause();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'pause', child: Text(rule.isPaused ? 'Resume' : 'Pause')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _duePreview(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final days = due.difference(today).inDays;
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days > 1) return 'Due in $days days';
    if (days == -1) return '1 day overdue';
    return '${-days} days overdue';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_repeat_rounded, size: 58, color: AppColors.primary),
              const SizedBox(height: 18),
              const Text('No recurring transactions yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Automate salary, rent, subscriptions, insurance and other repeating money movements.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Create recurring rule')),
            ],
          ),
        ),
      );
}
