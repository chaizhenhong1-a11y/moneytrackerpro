import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/spending_pace_forecast.dart';

class SpendingPacePage extends StatelessWidget {
  const SpendingPacePage({required this.forecast, super.key});

  final SpendingPaceForecast forecast;

  @override
  Widget build(BuildContext context) {
    final progress = forecast.monthProgress.clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spending pace',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _HeroCard(forecast: forecast),
          const SizedBox(height: 22),
          const Text(
            'Month-end projection',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Projected expenses',
                  value: CurrencyFormatter.myr(forecast.projectedExpenses),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Projected cash flow',
                  value: CurrencyFormatter.myr(
                    forecast.projectedNetCashFlow,
                    showSign: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.timelapse_rounded,
                  label: 'Month elapsed',
                  value: '${(progress * 100).toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'Days remaining',
                  value: '${forecast.daysRemaining}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _PaceCard(forecast: forecast),
          const SizedBox(height: 16),
          Text(
            'Projection uses your average spending so far this month. It is a planning estimate, not a guarantee.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.forecast});

  final SpendingPaceForecast forecast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF826CEB), AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current spending',
            style: TextStyle(color: Color(0xFFDCD6FF)),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.myr(forecast.currentExpenses),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: forecast.monthProgress.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: .18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '${forecast.daysElapsed} of ${forecast.daysInMonth} days recorded',
            style: const TextStyle(color: Color(0xFFE8E4FF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 13),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaceCard extends StatelessWidget {
  const _PaceCard({required this.forecast});

  final SpendingPaceForecast forecast;

  @override
  Widget build(BuildContext context) {
    final (icon, title, color, background) = switch (forecast.status) {
      SpendingPaceStatus.ahead => (
          Icons.check_circle_outline_rounded,
          'Ahead of last month',
          AppColors.success,
          const Color(0xFFEAF9F2),
        ),
      SpendingPaceStatus.steady => (
          Icons.horizontal_rule_rounded,
          'Steady pace',
          AppColors.primary,
          AppColors.primarySoft,
        ),
      SpendingPaceStatus.watch => (
          Icons.warning_amber_rounded,
          'Watch your pace',
          AppColors.expense,
          const Color(0xFFFFECE8),
        ),
    };

    final comparison = forecast.paceVsLastMonthPercent == null
        ? 'No comparable spending last month'
        : '${forecast.paceVsLastMonthPercent! >= 0 ? '+' : ''}${forecast.paceVsLastMonthPercent!.toStringAsFixed(1)}% projected vs last month';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  comparison,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(forecast.message, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
