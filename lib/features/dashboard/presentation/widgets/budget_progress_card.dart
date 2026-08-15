import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({required this.spent, required this.budget, super.key});

  final double spent;
  final double budget;

  @override
  Widget build(BuildContext context) {
    final ratio = budget <= 0 ? 0.0 : spent / budget;
    final progress = ratio.clamp(0.0, 1.0);
    final remaining = budget - spent;
    final warning = ratio >= .8;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: warning ? const Color(0xFFFFE8E1) : AppColors.primarySoft, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.flag_outlined, color: warning ? AppColors.expense : AppColors.primary, size: 20)),
                const SizedBox(width: 11),
                const Expanded(child: Text('Monthly budget', style: TextStyle(fontWeight: FontWeight.w700))),
                Text('${(ratio * 100).toStringAsFixed(0)}%', style: TextStyle(color: warning ? AppColors.expense : AppColors.primary, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: progress, minHeight: 9, backgroundColor: AppColors.primarySoft, color: warning ? AppColors.expense : AppColors.primary),
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(child: Text('${CurrencyFormatter.myr(spent)} spent', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                Text(remaining >= 0 ? '${CurrencyFormatter.myr(remaining)} left' : '${CurrencyFormatter.myr(remaining.abs())} over', style: TextStyle(color: remaining >= 0 ? AppColors.textSecondary : AppColors.expense, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
