import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/monthly_financial_review.dart';
import '../../domain/models/savings_target_plan.dart';
import '../../domain/services/savings_target_service.dart';

class SavingsTargetPlannerPage extends StatefulWidget {
  const SavingsTargetPlannerPage({required this.review, super.key});

  final MonthlyFinancialReview review;

  @override
  State<SavingsTargetPlannerPage> createState() =>
      _SavingsTargetPlannerPageState();
}

class _SavingsTargetPlannerPageState extends State<SavingsTargetPlannerPage> {
  double _targetRate = 30;

  @override
  Widget build(BuildContext context) {
    final plan = SavingsTargetService.build(
      widget.review,
      targetSavingsRate: _targetRate,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Savings Target',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _TargetHero(plan: plan),
          const SizedBox(height: 22),
          const Text(
            'Choose your target savings rate',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Move the slider to see the maximum monthly spending that still protects your target.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Target rate',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(
                        '${_targetRate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _targetRate,
                    min: 0,
                    max: 80,
                    divisions: 16,
                    label: '${_targetRate.toStringAsFixed(0)}%',
                    onChanged: (value) => setState(() => _targetRate = value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [Text('0%'), Text('80%')],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Target breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _MetricCard(
            icon: Icons.savings_outlined,
            title: 'Target savings',
            value: CurrencyFormatter.myr(plan.targetSavingsAmount),
            subtitle:
                '${plan.targetSavingsRate.toStringAsFixed(0)}% of this month\'s income',
          ),
          const SizedBox(height: 10),
          _MetricCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Maximum monthly spending',
            value: CurrencyFormatter.myr(plan.maxMonthlyExpenses),
            subtitle: 'Stay at or below this amount to protect the target',
          ),
          const SizedBox(height: 10),
          _MetricCard(
            icon: plan.targetMet
                ? Icons.check_circle_outline_rounded
                : Icons.content_cut_rounded,
            title: plan.targetMet
                ? 'Room before target is missed'
                : 'Expense reduction needed',
            value: CurrencyFormatter.myr(plan.targetMet
                ? plan.extraRoom
                : plan.requiredExpenseReduction),
            subtitle: plan.targetMet
                ? 'Current spending is already inside the target ceiling'
                : 'Reduce spending by this amount to reach the selected rate',
            emphasized: !plan.targetMet,
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    plan.targetMet
                        ? Icons.auto_awesome_outlined
                        : Icons.tips_and_updates_outlined,
                    color:
                        plan.targetMet ? AppColors.success : AppColors.primary,
                  ),
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

class _TargetHero extends StatelessWidget {
  const _TargetHero({required this.plan});

  final SavingsTargetPlan plan;

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
            'Current vs target savings rate',
            style: TextStyle(color: Color(0xFFDCD6FF)),
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.currentSavingsRate.toStringAsFixed(1)}%  →  ${plan.targetSavingsRate.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            plan.targetMet
                ? 'You are currently inside the spending limit for this target.'
                : 'Your spending needs an adjustment to reach this target.',
            style: const TextStyle(color: Color(0xFFE8E4FF), height: 1.35),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (emphasized ? AppColors.expense : AppColors.primary)
                    .withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: emphasized ? AppColors.expense : AppColors.primary,
              ),
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
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
