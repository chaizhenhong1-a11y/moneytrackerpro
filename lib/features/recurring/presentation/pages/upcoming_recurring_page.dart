import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../accounts/presentation/controllers/account_controller.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../domain/entities/recurring_transaction_rule.dart';
import '../controllers/recurring_transaction_controller.dart';
import 'recurring_transactions_page.dart';

class UpcomingRecurringPage extends StatelessWidget {
  const UpcomingRecurringPage({
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
      builder: (context, _) {
        final today = _dateOnly(DateTime.now());
        final activeIds = accountController.activeAccounts.map((account) => account.id).toSet();
        final visible = controller.rules.where((rule) => !rule.isPaused).toList()
          ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
        final attention = visible
            .where((rule) => !activeIds.contains(rule.accountId) || _dateOnly(rule.nextDueDate).isBefore(today))
            .toList();
        final upcoming = visible
            .where((rule) {
              if (!activeIds.contains(rule.accountId)) return false;
              final due = _dateOnly(rule.nextDueDate);
              final days = due.difference(today).inDays;
              return days >= 0 && days <= 7;
            })
            .toList();
        final later = visible
            .where((rule) {
              if (!activeIds.contains(rule.accountId)) return false;
              return _dateOnly(rule.nextDueDate).difference(today).inDays > 7;
            })
            .toList();
        final next30 = visible.where((rule) {
          if (!activeIds.contains(rule.accountId)) return false;
          final days = _dateOnly(rule.nextDueDate).difference(today).inDays;
          return days >= 0 && days <= 30;
        });
        final income30 = next30
            .where((rule) => rule.type == TransactionType.income)
            .fold<double>(0, (sum, rule) => sum + rule.amount);
        final expense30 = next30
            .where((rule) => rule.type == TransactionType.expense)
            .fold<double>(0, (sum, rule) => sum + rule.amount);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Upcoming recurring', style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Manage recurring rules',
                onPressed: () => _openManage(context),
                icon: const Icon(Icons.tune_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: visible.isEmpty
              ? _EmptyState(onManage: () => _openManage(context))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _ForecastCard(
                      upcomingCount: upcoming.length,
                      income: income30,
                      expense: expense30,
                    ),
                    if (attention.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionTitle(title: 'Needs attention', icon: Icons.error_outline_rounded),
                      const SizedBox(height: 10),
                      ...attention.map(
                        (rule) => _RecurringReminderTile(
                          rule: rule,
                          accountName: _accountName(rule.accountId),
                          accountAvailable: activeIds.contains(rule.accountId),
                        ),
                      ),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionTitle(title: 'Next 7 days', icon: Icons.upcoming_outlined),
                      const SizedBox(height: 10),
                      ...upcoming.map(
                        (rule) => _RecurringReminderTile(
                          rule: rule,
                          accountName: _accountName(rule.accountId),
                          accountAvailable: true,
                        ),
                      ),
                    ],
                    if (later.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const _SectionTitle(title: 'Later', icon: Icons.event_outlined),
                      const SizedBox(height: 10),
                      ...later.map(
                        (rule) => _RecurringReminderTile(
                          rule: rule,
                          accountName: _accountName(rule.accountId),
                          accountAvailable: true,
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  String _accountName(String id) {
    for (final account in accountController.accounts) {
      if (account.id == id) return account.name;
    }
    return 'Unavailable account';
  }

  Future<void> _openManage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecurringTransactionsPage(
          controller: controller,
          accountController: accountController,
          categoryController: categoryController,
        ),
      ),
    );
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({
    required this.upcomingCount,
    required this.income,
    required this.expense,
  });

  final int upcomingCount;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_repeat_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                '$upcomingCount due in the next 7 days',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _ForecastValue(label: '30-day income', value: income, isIncome: true)),
              const SizedBox(width: 12),
              Expanded(child: _ForecastValue(label: '30-day expenses', value: expense, isIncome: false)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForecastValue extends StatelessWidget {
  const _ForecastValue({required this.label, required this.value, required this.isIncome});

  final String label;
  final double value;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            '${isIncome ? '+' : '-'}${CurrencyFormatter.myr(value)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isIncome ? AppColors.success : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _RecurringReminderTile extends StatelessWidget {
  const _RecurringReminderTile({
    required this.rule,
    required this.accountName,
    required this.accountAvailable,
  });

  final RecurringTransactionRule rule;
  final String accountName;
  final bool accountAvailable;

  @override
  Widget build(BuildContext context) {
    final isIncome = rule.type == TransactionType.income;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: accountAvailable ? AppColors.primarySoft : AppColors.border,
              child: Icon(
                accountAvailable ? Icons.repeat_rounded : Icons.archive_outlined,
                color: accountAvailable ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    accountAvailable ? '$accountName • ${_dueLabel(rule.nextDueDate)}' : '$accountName • Account unavailable',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${rule.nextDueDate.day}/${rule.nextDueDate.month}/${rule.nextDueDate.year}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.myr(rule.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isIncome ? AppColors.success : AppColors.expense,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dueLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);
    final days = due.difference(today).inDays;
    if (days < 0) return '${-days}d overdue';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due in ${days}d';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_active_outlined, size: 58, color: AppColors.primary),
            const SizedBox(height: 18),
            const Text('Nothing scheduled yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Create recurring income or expenses to see upcoming money reminders here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.event_repeat_rounded),
              label: const Text('Manage recurring'),
            ),
          ],
        ),
      ),
    );
  }
}
