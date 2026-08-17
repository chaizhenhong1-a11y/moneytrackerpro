import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/monthly_financial_review.dart';
import '../../domain/models/surplus_allocation_plan.dart';
import '../../domain/services/surplus_allocation_service.dart';

class SurplusAllocationPage extends StatefulWidget {
  const SurplusAllocationPage({required this.review, super.key});

  final MonthlyFinancialReview review;

  @override
  State<SurplusAllocationPage> createState() => _SurplusAllocationPageState();
}

class _SurplusAllocationPageState extends State<SurplusAllocationPage> {
  SurplusAllocationStrategy _strategy = SurplusAllocationStrategy.balanced;

  @override
  Widget build(BuildContext context) {
    final plan = SurplusAllocationService.build(
      widget.review,
      strategy: _strategy,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Surplus Allocation',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _SurplusHero(plan: plan),
          const SizedBox(height: 22),
          const Text(
            'Choose your priority',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SurplusAllocationStrategy.values.map((strategy) {
              return ChoiceChip(
                label: Text(_strategyLabel(strategy)),
                selected: _strategy == strategy,
                onSelected: (_) => setState(() => _strategy = strategy),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            plan.summary,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Suggested split',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _AllocationTile(
            icon: Icons.health_and_safety_outlined,
            title: 'Emergency fund',
            amount: plan.emergencyFund,
            total: plan.availableSurplus,
          ),
          const SizedBox(height: 10),
          _AllocationTile(
            icon: Icons.credit_score_outlined,
            title: 'Extra debt payment',
            amount: plan.extraDebtPayment,
            total: plan.availableSurplus,
          ),
          const SizedBox(height: 10),
          _AllocationTile(
            icon: Icons.flag_outlined,
            title: 'Savings goals',
            amount: plan.savingsGoals,
            total: plan.availableSurplus,
          ),
          const SizedBox(height: 10),
          _AllocationTile(
            icon: Icons.wallet_outlined,
            title: 'Flexible money',
            amount: plan.flexibleMoney,
            total: plan.availableSurplus,
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      plan.hasSurplus
                          ? 'This is a planning guide, not an automatic transfer. Adjust the split when your real priorities change.'
                          : 'Once your monthly cash flow becomes positive, this page will automatically turn the surplus into a suggested allocation plan.',
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _strategyLabel(SurplusAllocationStrategy strategy) {
    return switch (strategy) {
      SurplusAllocationStrategy.balanced => 'Balanced',
      SurplusAllocationStrategy.safetyFirst => 'Safety first',
      SurplusAllocationStrategy.debtFirst => 'Debt first',
      SurplusAllocationStrategy.goalsFirst => 'Goals first',
    };
  }
}

class _SurplusHero extends StatelessWidget {
  const _SurplusHero({required this.plan});

  final SurplusAllocationPlan plan;

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
            'Available monthly surplus',
            style: TextStyle(color: Color(0xFFDCD6FF)),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.myr(plan.availableSurplus),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Turn positive cash flow into a clear plan instead of letting it disappear into unplanned spending.',
            style: TextStyle(color: Color(0xFFE8E4FF), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _AllocationTile extends StatelessWidget {
  const _AllocationTile({
    required this.icon,
    required this.title,
    required this.amount,
    required this.total,
  });

  final IconData icon;
  final String title;
  final double amount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final percent = total <= 0 ? 0.0 : (amount / total) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
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
                    '${percent.toStringAsFixed(0)}% of this month\'s surplus',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              CurrencyFormatter.myr(amount),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
