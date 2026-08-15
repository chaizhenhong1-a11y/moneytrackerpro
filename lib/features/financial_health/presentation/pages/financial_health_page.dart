import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/financial_health_report.dart';

class FinancialHealthPage extends StatelessWidget {
  const FinancialHealthPage({required this.report, super.key});

  final FinancialHealthReport report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Financial health')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _ScoreCard(report: report),
          const SizedBox(height: 24),
          const Text('Score breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...report.factors.map((factor) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FactorCard(factor: factor),
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This score is a planning indicator based on the data recorded in MoneyTracker Pro. It is not a credit score or financial advice.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.report});

  final FinancialHealthReport report;

  @override
  Widget build(BuildContext context) {
    final danger = report.score < 55;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: danger ? AppColors.expense.withValues(alpha: .3) : AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: report.score / 100,
                  strokeWidth: 9,
                  backgroundColor: AppColors.primarySoft,
                  color: danger ? AppColors.expense : AppColors.primary,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${report.score}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const Text('/ 100', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: danger ? AppColors.expense : AppColors.primary)),
                const SizedBox(height: 6),
                Text(report.headline, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactorCard extends StatelessWidget {
  const _FactorCard({required this.factor});

  final FinancialHealthFactor factor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(factor.title, style: const TextStyle(fontWeight: FontWeight.w800))),
              Text('${factor.score}/${factor.maxScore}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: factor.progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: AppColors.primarySoft,
            ),
          ),
          const SizedBox(height: 12),
          Text(factor.summary, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(factor.recommendation, style: const TextStyle(fontSize: 12, height: 1.4))),
            ],
          ),
        ],
      ),
    );
  }
}
