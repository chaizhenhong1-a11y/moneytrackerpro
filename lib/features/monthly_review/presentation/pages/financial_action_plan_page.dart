import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/financial_action_plan.dart';

class FinancialActionPlanPage extends StatelessWidget {
  const FinancialActionPlanPage({required this.plan, super.key});

  final FinancialActionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial action plan')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _ScoreCard(plan: plan),
          const SizedBox(height: 22),
          const Text(
            'Recommended allocation',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AllocationCard(
                  icon: Icons.savings_outlined,
                  label: 'Move to savings',
                  amount: plan.recommendedSavings,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AllocationCard(
                  icon: Icons.shield_outlined,
                  label: 'Keep as buffer',
                  amount: plan.recommendedBuffer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Priority actions',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...plan.actions.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ActionCard(index: entry.key + 1, item: entry.value),
                ),
              ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.plan});

  final FinancialActionPlan plan;

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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly action score',
            style: TextStyle(color: Color(0xFFDCD6FF)),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${plan.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 4, left: 4),
                child: Text(
                  '/100',
                  style: TextStyle(color: Color(0xFFDCD6FF), fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            plan.headline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            plan.summary,
            style: const TextStyle(color: Color(0xFFE8E4FF), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({
    required this.icon,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final String label;
  final double amount;

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
              CurrencyFormatter.myr(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.index, required this.item});

  final int index;
  final FinancialActionItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _priorityColor(item.priority).withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$index',
                style: TextStyle(
                  color: _priorityColor(item.priority),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _PriorityBadge(priority: item.priority),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (item.targetAmount != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Reference: ${CurrencyFormatter.myr(item.targetAmount!)}',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final FinancialActionPriority priority;

  @override
  Widget build(BuildContext context) {
    final label = switch (priority) {
      FinancialActionPriority.high => 'High',
      FinancialActionPriority.medium => 'Medium',
      FinancialActionPriority.low => 'Low',
    };
    final color = _priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

Color _priorityColor(FinancialActionPriority priority) {
  return switch (priority) {
    FinancialActionPriority.high => AppColors.expense,
    FinancialActionPriority.medium => AppColors.primary,
    FinancialActionPriority.low => AppColors.success,
  };
}
