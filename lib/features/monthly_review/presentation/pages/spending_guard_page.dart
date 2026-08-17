import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/monthly_financial_review.dart';
import '../../domain/models/spending_guard_result.dart';
import '../../domain/services/spending_guard_service.dart';

class SpendingGuardPage extends StatefulWidget {
  const SpendingGuardPage({required this.review, super.key});

  final MonthlyFinancialReview review;

  @override
  State<SpendingGuardPage> createState() => _SpendingGuardPageState();
}

class _SpendingGuardPageState extends State<SpendingGuardPage> {
  final _amountController = TextEditingController();
  SpendingGuardResult? _result;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spending guard',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const _IntroCard(),
          const SizedBox(height: 22),
          const Text(
            'Check a purchase',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Purchase amount',
              prefixText: 'RM ',
              prefixIcon: const Icon(Icons.shopping_bag_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _evaluate(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [20, 50, 100, 200]
                .map(
                  (amount) => ActionChip(
                    label: Text('RM $amount'),
                    onPressed: () {
                      _amountController.text = amount.toString();
                      _evaluate();
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _evaluate,
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Check this purchase'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 22),
            _ResultCard(result: _result!),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Left after purchase',
                    value: CurrencyFormatter.myr(_result!.safeToSpendAfter),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'New daily limit',
                    value: CurrencyFormatter.myr(_result!.dailyAllowanceAfter),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _UsageCard(result: _result!),
          ],
        ],
      ),
    );
  }

  void _evaluate() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount greater than 0.')),
      );
      return;
    }
    setState(() {
      _result = SpendingGuardService.evaluate(
        review: widget.review,
        amount: amount,
      );
    });
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF826CEB), AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.security_rounded, color: Colors.white, size: 30),
          SizedBox(height: 12),
          Text(
            'Know before you spend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Enter a planned purchase and MoneyTracker Pro will show how it affects your current safe-to-spend allowance.',
            style: TextStyle(color: Color(0xFFE8E4FF), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final SpendingGuardResult result;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (result.level) {
      SpendingGuardLevel.safe => (
          Icons.check_circle_outline_rounded,
          AppColors.success,
          const Color(0xFFEAF9F2),
        ),
      SpendingGuardLevel.caution => (
          Icons.warning_amber_rounded,
          const Color(0xFFD88B00),
          const Color(0xFFFFF5DE),
        ),
      SpendingGuardLevel.overLimit => (
          Icons.block_rounded,
          AppColors.expense,
          const Color(0xFFFFECE8),
        ),
      SpendingGuardLevel.unavailable => (
          Icons.info_outline_rounded,
          AppColors.textSecondary,
          const Color(0xFFF0F1F5),
        ),
    };

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
                  result.title,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(result.message, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

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
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.result});

  final SpendingGuardResult result;

  @override
  Widget build(BuildContext context) {
    final progress = (result.usagePercent / 100).clamp(0.0, 1.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Allowance used by this purchase',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${result.usagePercent.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: AppColors.primarySoft,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${result.daysRemaining} day${result.daysRemaining == 1 ? '' : 's'} remaining · before purchase ${CurrencyFormatter.myr(result.safeToSpendBefore)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
