import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../dashboard/presentation/widgets/transaction_tile.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../domain/entities/category_budget.dart';
import '../controllers/category_budget_controller.dart';
import 'category_budgets_page.dart';

class BudgetAlertsPage extends StatelessWidget {
  const BudgetAlertsPage({
    required this.budgetController,
    required this.categoryController,
    required this.dashboardController,
    super.key,
  });

  final CategoryBudgetController budgetController;
  final CategoryController categoryController;
  final DashboardController dashboardController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        budgetController,
        categoryController,
        dashboardController,
      ]),
      builder: (context, _) {
        final alerts = _buildAlerts();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Budget alerts',
                style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Manage category budgets',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CategoryBudgetsPage(
                      controller: budgetController,
                      categoryController: categoryController,
                      dashboardController: dashboardController,
                    ),
                  ),
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: alerts.isEmpty
              ? _NoBudgetAlerts(
                  hasBudgets: budgetController.budgets
                      .any((item) => item.monthlyLimit > 0),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    _AlertOverview(alerts: alerts),
                    const SizedBox(height: 18),
                    for (final alert in alerts) ...[
                      _BudgetAlertCard(alert: alert),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        );
      },
    );
  }

  List<_BudgetAlertData> _buildAlerts() {
    final now = DateTime.now();
    final result = <_BudgetAlertData>[];

    for (final budget in budgetController.budgets) {
      if (budget.monthlyLimit <= 0) continue;
      final categoryMatches = categoryController.categories.where(
        (category) => category.id == budget.categoryId,
      );
      if (categoryMatches.isEmpty) continue;
      final category = categoryMatches.first;
      final transactions = dashboardController.transactions
          .where((item) =>
              item.countsAsExpense &&
              item.category == category.name &&
              item.date.year == now.year &&
              item.date.month == now.month)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final spent =
          transactions.fold<double>(0, (sum, item) => sum + item.amount);
      final ratio =
          budget.monthlyLimit == 0 ? 0.0 : spent / budget.monthlyLimit;
      if (ratio < .8) continue;
      result.add(
        _BudgetAlertData(
          budget: budget,
          categoryName: category.name,
          categoryIcon: category.icon,
          categoryColor: category.color,
          spent: spent,
          transactions: transactions.take(3).toList(),
        ),
      );
    }

    result.sort((a, b) => b.ratio.compareTo(a.ratio));
    return result;
  }
}

class _BudgetAlertData {
  const _BudgetAlertData({
    required this.budget,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.spent,
    required this.transactions,
  });

  final CategoryBudget budget;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final double spent;
  final List<TransactionEntry> transactions;

  double get ratio =>
      budget.monthlyLimit <= 0 ? 0 : spent / budget.monthlyLimit;
  double get remaining => budget.monthlyLimit - spent;

  _BudgetAlertLevel get level {
    if (spent > budget.monthlyLimit) return _BudgetAlertLevel.over;
    if (spent >= budget.monthlyLimit) return _BudgetAlertLevel.reached;
    return _BudgetAlertLevel.warning;
  }
}

enum _BudgetAlertLevel { warning, reached, over }

class _AlertOverview extends StatelessWidget {
  const _AlertOverview({required this.alerts});

  final List<_BudgetAlertData> alerts;

  @override
  Widget build(BuildContext context) {
    final over =
        alerts.where((item) => item.level == _BudgetAlertLevel.over).length;
    final reached =
        alerts.where((item) => item.level == _BudgetAlertLevel.reached).length;
    final warning =
        alerts.where((item) => item.level == _BudgetAlertLevel.warning).length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Budget alerts appear once a category reaches 80% of its monthly limit.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: _OverviewMetric(value: '$warning', label: 'Warning')),
              const SizedBox(width: 8),
              Expanded(
                  child: _OverviewMetric(value: '$reached', label: 'Reached')),
              const SizedBox(width: 8),
              Expanded(child: _OverviewMetric(value: '$over', label: 'Over')),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _BudgetAlertCard extends StatelessWidget {
  const _BudgetAlertCard({required this.alert});

  final _BudgetAlertData alert;

  @override
  Widget build(BuildContext context) {
    final levelLabel = switch (alert.level) {
      _BudgetAlertLevel.warning => 'Approaching limit',
      _BudgetAlertLevel.reached => 'Budget reached',
      _BudgetAlertLevel.over => 'Over budget',
    };
    final levelColor = alert.level == _BudgetAlertLevel.warning
        ? const Color(0xFFF0A429)
        : AppColors.expense;
    final progress = alert.ratio.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: alert.categoryColor.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(alert.categoryIcon, color: alert.categoryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(levelLabel,
                        style: TextStyle(
                            color: levelColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Text(
                '${(alert.ratio * 100).round()}%',
                style:
                    TextStyle(color: levelColor, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.background,
              color: levelColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${CurrencyFormatter.myr(alert.spent)} of ${CurrencyFormatter.myr(alert.budget.monthlyLimit)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              Text(
                alert.remaining >= 0
                    ? '${CurrencyFormatter.myr(alert.remaining)} left'
                    : '${CurrencyFormatter.myr(-alert.remaining)} over',
                style: TextStyle(
                    fontSize: 12,
                    color: levelColor,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (alert.transactions.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),
            const Text('Recent spending',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final transaction in alert.transactions)
              TransactionTile(transaction: transaction),
          ],
        ],
      ),
    );
  }
}

class _NoBudgetAlerts extends StatelessWidget {
  const _NoBudgetAlerts({required this.hasBudgets});

  final bool hasBudgets;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.notifications_none_rounded,
                  color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              hasBudgets
                  ? 'All category budgets are on track'
                  : 'No category budgets yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasBudgets
                  ? 'Nothing has reached the 80% warning level this month.'
                  : 'Set a monthly category budget to start receiving spending alerts.',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
