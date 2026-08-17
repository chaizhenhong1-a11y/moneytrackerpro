import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/budget_stress_test_result.dart';
import '../../domain/models/monthly_financial_review.dart';
import '../../domain/services/budget_stress_test_service.dart';

class BudgetStressTestPage extends StatefulWidget {
  const BudgetStressTestPage({required this.review, super.key});

  final MonthlyFinancialReview review;

  @override
  State<BudgetStressTestPage> createState() => _BudgetStressTestPageState();
}

class _BudgetStressTestPageState extends State<BudgetStressTestPage> {
  double _incomeDrop = 10;
  final _extraExpenseController = TextEditingController(text: '500');
  BudgetStressTestResult? _result;

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  @override
  void dispose() {
    _extraExpenseController.dispose();
    super.dispose();
  }

  void _runTest() {
    final extraExpense =
        double.tryParse(_extraExpenseController.text.trim()) ?? 0;
    setState(() {
      _result = BudgetStressTestService.run(
        review: widget.review,
        incomeDropPercent: _incomeDrop,
        extraExpense: extraExpense,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result!;
    final statusColor = switch (result.level) {
      BudgetStressLevel.safe => AppColors.success,
      BudgetStressLevel.caution => const Color(0xFFF59E0B),
      BudgetStressLevel.danger => AppColors.expense,
    };
    final statusLabel = switch (result.level) {
      BudgetStressLevel.safe => 'SAFE',
      BudgetStressLevel.caution => 'CAUTION',
      BudgetStressLevel.danger => 'DANGER',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Stress Test',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Container(
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
                const Text('Test your financial resilience',
                    style: TextStyle(color: Color(0xFFDCD6FF))),
                const SizedBox(height: 8),
                const Text(
                  'See what happens if income falls or an unexpected expense hits this month.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2),
                ),
                const SizedBox(height: 18),
                Text(
                  'Current net cash flow: ${CurrencyFormatter.myr(widget.review.netCashFlow, showSign: true)}',
                  style: const TextStyle(
                      color: Color(0xFFE8E4FF), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('Income drop',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('${_incomeDrop.toStringAsFixed(0)}%',
              style: const TextStyle(color: AppColors.textSecondary)),
          Slider(
            value: _incomeDrop,
            min: 0,
            max: 60,
            divisions: 12,
            label: '${_incomeDrop.toStringAsFixed(0)}%',
            onChanged: (value) {
              setState(() => _incomeDrop = value);
            },
            onChangeEnd: (_) => _runTest(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _extraExpenseController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Unexpected extra expense',
              prefixText: 'RM ',
              border: OutlineInputBorder(),
              helperText:
                  'Example: car repair, medical bill, emergency purchase',
            ),
            onSubmitted: (_) => _runTest(),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _runTest,
            icon: const Icon(Icons.science_outlined),
            label: const Text('Run stress test'),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: statusColor.withValues(alpha: .28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(statusLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 12),
                Text(result.headline,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(result.guidance,
                    style: const TextStyle(
                        color: AppColors.textSecondary, height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Projected income',
                  value: CurrencyFormatter.myr(result.projectedIncome),
                  icon: Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Projected expenses',
                  value: CurrencyFormatter.myr(result.projectedExpenses),
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Net cash flow',
                  value: CurrencyFormatter.myr(result.projectedNetCashFlow,
                      showSign: true),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  label: 'Savings rate',
                  value: '${result.projectedSavingsRate.toStringAsFixed(1)}%',
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 5),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
