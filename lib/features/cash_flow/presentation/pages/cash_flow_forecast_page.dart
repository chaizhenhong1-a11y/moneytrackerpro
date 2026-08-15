import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../accounts/presentation/controllers/account_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../recurring/presentation/controllers/recurring_transaction_controller.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../domain/models/cash_flow_projection.dart';
import '../../domain/services/cash_flow_forecast_service.dart';

class CashFlowForecastPage extends StatelessWidget {
  const CashFlowForecastPage({
    required this.dashboardController,
    required this.recurringController,
    required this.accountController,
    super.key,
  });

  final DashboardController dashboardController;
  final RecurringTransactionController recurringController;
  final AccountController accountController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([dashboardController, recurringController, accountController]),
      builder: (context, _) {
        final projection = CashFlowForecastService.project(
          openingBalance: dashboardController.balance,
          rules: recurringController.rules,
          activeAccountIds: accountController.activeAccounts.map((account) => account.id).toSet(),
        );
        return Scaffold(
          appBar: AppBar(title: const Text('Cash flow forecast', style: TextStyle(fontWeight: FontWeight.w800))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _HealthCard(projection: projection),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: '30-day income',
                      value: projection.projectedIncome,
                      icon: Icons.south_west_rounded,
                      valueColor: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: '30-day expenses',
                      value: projection.projectedExpense,
                      icon: Icons.north_east_rounded,
                      valueColor: AppColors.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Lowest balance',
                      value: projection.lowestBalance,
                      icon: Icons.trending_down_rounded,
                      valueColor: projection.lowestBalance < 0 ? AppColors.expense : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Day 30 balance',
                      value: projection.closingBalance,
                      icon: Icons.flag_outlined,
                      valueColor: projection.closingBalance < 0 ? AppColors.expense : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text('Projected timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                'Based on active recurring income and expenses for the next 30 days.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 14),
              if (projection.points.isEmpty)
                const _EmptyTimeline()
              else
                ...projection.points.map((point) => _ProjectionTile(point: point)),
            ],
          ),
        );
      },
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.projection});

  final CashFlowProjection projection;

  @override
  Widget build(BuildContext context) {
    final danger = projection.hasShortfall;
    final netPositive = projection.netChange >= 0;
    final headline = danger
        ? 'Potential cash shortfall'
        : netPositive
            ? 'Cash flow looks healthy'
            : 'Cash flow is trending down';
    final description = danger
        ? 'Projected balance may fall below zero on ${_formatDate(projection.firstNegativeDate!)}.'
        : 'Projected 30-day change: ${netPositive ? '+' : '-'}${CurrencyFormatter.myr(projection.netChange.abs())}.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: danger ? const Color(0xFFFFEEEE) : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Icon(danger ? Icons.warning_amber_rounded : Icons.auto_graph_rounded, color: danger ? AppColors.expense : AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                const SizedBox(height: 10),
                Text(
                  'Starts at ${CurrencyFormatter.myr(projection.openingBalance)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.valueColor});

  final String label;
  final double value;
  final IconData icon;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text(CurrencyFormatter.myr(value), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor)),
        ],
      ),
    );
  }
}

class _ProjectionTile extends StatelessWidget {
  const _ProjectionTile({required this.point});

  final CashFlowProjectionPoint point;

  @override
  Widget build(BuildContext context) {
    final positive = point.change >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                child: Text('${point.date.day}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(point.date), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      '${point.rules.length} scheduled ${point.rules.length == 1 ? 'item' : 'items'}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${positive ? '+' : '-'}${CurrencyFormatter.myr(point.change.abs())}',
                    style: TextStyle(fontWeight: FontWeight.w800, color: positive ? AppColors.success : AppColors.expense),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    CurrencyFormatter.myr(point.balance),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: point.balance < 0 ? AppColors.expense : AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...point.rules.map(
            (rule) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    rule.type == TransactionType.income ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                    size: 16,
                    color: rule.type == TransactionType.income ? AppColors.success : AppColors.expense,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rule.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                  Text(
                    '${rule.type == TransactionType.income ? '+' : '-'}${CurrencyFormatter.myr(rule.amount)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
      child: const Column(
        children: [
          Icon(Icons.event_available_outlined, size: 42, color: AppColors.primary),
          SizedBox(height: 12),
          Text('No scheduled cash flow', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(
            'Active recurring transactions due in the next 30 days will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
