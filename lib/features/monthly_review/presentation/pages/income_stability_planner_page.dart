import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/income_stability_plan.dart';
import '../../domain/models/monthly_financial_review.dart';
import '../../domain/services/income_stability_service.dart';

class IncomeStabilityPlannerPage extends StatelessWidget {
  const IncomeStabilityPlannerPage({required this.review, super.key});

  final MonthlyFinancialReview review;

  @override
  Widget build(BuildContext context) {
    final plan = IncomeStabilityService.build(review);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Income Stability',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _StabilityHero(plan: plan),
          const SizedBox(height: 22),
          const Text(
            'Conservative budget baseline',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Instead of budgeting from your strongest income month, this planner builds a safer ceiling from recent income history.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _MetricCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Conservative income baseline',
            value: CurrencyFormatter.myr(plan.conservativeIncomeBaseline),
            subtitle: 'Income amount used for safer monthly planning',
          ),
          const SizedBox(height: 10),
          _MetricCard(
            icon: Icons.shield_outlined,
            title: 'Recommended income reserve',
            value: CurrencyFormatter.myr(plan.recommendedIncomeReserve),
            subtitle:
                '${(plan.reserveRate * 100).toStringAsFixed(0)}% buffer for income uncertainty',
          ),
          const SizedBox(height: 10),
          _MetricCard(
            icon: Icons.speed_outlined,
            title: 'Safe spending baseline',
            value: CurrencyFormatter.myr(plan.safeSpendingBaseline),
            subtitle: 'Suggested spending ceiling after protecting the reserve',
            emphasized: !plan.insideSafeBaseline,
          ),
          const SizedBox(height: 10),
          _MetricCard(
            icon: plan.insideSafeBaseline
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            title: plan.insideSafeBaseline
                ? 'Current spending headroom'
                : 'Spending above baseline',
            value: CurrencyFormatter.myr(plan.spendingHeadroom.abs()),
            subtitle: plan.insideSafeBaseline
                ? 'Room left before reaching the conservative spending ceiling'
                : 'Amount current spending exceeds the conservative ceiling',
            emphasized: !plan.insideSafeBaseline,
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(plan.summary,
                        style: const TextStyle(height: 1.45)),
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

class _StabilityHero extends StatelessWidget {
  const _StabilityHero({required this.plan});

  final IncomeStabilityPlan plan;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${plan.stabilityScore.toStringAsFixed(0)}/100',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.incomeChangePercent == null
                ? 'More income history will make this score more precise.'
                : '${plan.incomeChangePercent! >= 0 ? '+' : ''}${plan.incomeChangePercent!.toStringAsFixed(1)}% income change vs last month',
            style: const TextStyle(color: Color(0xFFE8E4FF), height: 1.35),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'This month',
                  value: CurrencyFormatter.myr(plan.currentIncome),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Last month',
                  value: CurrencyFormatter.myr(plan.previousIncome),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFFDCD6FF), fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final accent = emphasized ? AppColors.expense : AppColors.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w900, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
