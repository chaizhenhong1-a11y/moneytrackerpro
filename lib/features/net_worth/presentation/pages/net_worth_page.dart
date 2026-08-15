import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/net_worth_report.dart';

class NetWorthPage extends StatelessWidget {
  const NetWorthPage({required this.report, super.key});

  final NetWorthReport report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Net worth')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _HeroCard(report: report),
          const SizedBox(height: 18),
          const Text('6-month trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _TrendCard(points: report.history),
          const SizedBox(height: 20),
          const Text('Account breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (report.accounts.isEmpty)
            const _EmptyAccounts()
          else
            ...report.accounts.map((item) => _AccountRow(item: item, totalAssets: report.positiveAssets)),
          const SizedBox(height: 16),
          const Text(
            'Net worth is calculated as recorded account balances minus tracked liabilities. Transfers move money between accounts without changing total net worth. Historical points use the current tracked liability balance until debt payment history is introduced.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.report});

  final NetWorthReport report;

  @override
  Widget build(BuildContext context) {
    final change = report.change30Days;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Current net worth', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.myr(report.currentNetWorth),
          style: const TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Icon(change >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 7),
          Text(
            '${change >= 0 ? '+' : '-'}${CurrencyFormatter.myr(change.abs())} over 30 days',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _Metric(label: 'Positive assets', value: CurrencyFormatter.myr(report.positiveAssets))),
          const SizedBox(width: 12),
          Expanded(child: _Metric(label: 'Tracked liabilities', value: CurrencyFormatter.myr(report.totalLiabilities))),
        ]),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
      ]),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points});
  final List<NetWorthPoint> points;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final maxAbs = points.fold<double>(1, (max, point) => point.value.abs() > max ? point.value.abs() : max);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
      child: SizedBox(
        height: 190,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: points.map((point) {
            final height = 26 + (point.value.abs() / maxAbs * 112);
            return Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(
                  _compact(point.value),
                  style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Container(
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: point.value >= 0 ? AppColors.primarySoft : const Color(0xFFFFE8E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: point.value >= 0 ? AppColors.primary.withValues(alpha: .2) : AppColors.expense.withValues(alpha: .2)),
                  ),
                ),
                const SizedBox(height: 7),
                Text(_months[point.date.month - 1], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _compact(double value) {
    final absolute = value.abs();
    final sign = value < 0 ? '-' : '';
    if (absolute >= 1000000) return '$sign${(absolute / 1000000).toStringAsFixed(1)}m';
    if (absolute >= 1000) return '$sign${(absolute / 1000).toStringAsFixed(1)}k';
    return '$sign${absolute.toStringAsFixed(0)}';
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.item, required this.totalAssets});
  final AccountNetWorthSlice item;
  final double totalAssets;

  @override
  Widget build(BuildContext context) {
    final share = item.balance > 0 && totalAssets > 0 ? item.balance / totalAssets : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(item.accountName, style: const TextStyle(fontWeight: FontWeight.w800))),
            if (item.isArchived) ...[
              const SizedBox(width: 7),
              const Text('Archived', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ]),
          const SizedBox(height: 4),
          Text(
            item.balance > 0 ? '${(share * 100).toStringAsFixed(1)}% of positive assets' : 'Negative account balance',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ])),
        const SizedBox(width: 8),
        Text(
          CurrencyFormatter.myr(item.balance),
          style: TextStyle(fontWeight: FontWeight.w800, color: item.balance < 0 ? AppColors.expense : AppColors.textPrimary),
        ),
      ]),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(child: Text('No account balances to show.', style: TextStyle(color: AppColors.textSecondary))),
    );
  }
}
