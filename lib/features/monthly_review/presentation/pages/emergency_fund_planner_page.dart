import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/emergency_fund_plan.dart';
import '../../domain/models/monthly_financial_review.dart';
import '../../domain/services/emergency_fund_service.dart';

class EmergencyFundPlannerPage extends StatefulWidget {
  const EmergencyFundPlannerPage({required this.review, super.key});

  final MonthlyFinancialReview review;

  @override
  State<EmergencyFundPlannerPage> createState() =>
      _EmergencyFundPlannerPageState();
}

class _EmergencyFundPlannerPageState extends State<EmergencyFundPlannerPage> {
  final _currentFundController = TextEditingController(text: '0');
  int _coverageMonths = 6;
  int _timelineMonths = 12;

  @override
  void dispose() {
    _currentFundController.dispose();
    super.dispose();
  }

  double get _currentFund =>
      double.tryParse(_currentFundController.text.trim()) ?? 0;

  EmergencyFundPlan get _plan => EmergencyFundService.build(
        review: widget.review,
        currentFund: _currentFund,
        coverageMonths: _coverageMonths,
        timelineMonths: _timelineMonths,
      );

  @override
  Widget build(BuildContext context) {
    final plan = _plan;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency Fund Planner',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _HeroCard(plan: plan),
          const SizedBox(height: 22),
          const _SectionTitle('Plan setup'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _currentFundController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Emergency fund saved now',
                      prefixText: 'RM ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  const Text('Target coverage',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [3, 6, 9, 12]
                        .map(
                          (months) => ChoiceChip(
                            label: Text('$months months'),
                            selected: _coverageMonths == months,
                            onSelected: (_) =>
                                setState(() => _coverageMonths = months),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Build it within',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('$_timelineMonths months',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ],
                  ),
                  Slider(
                    value: _timelineMonths.toDouble(),
                    min: 3,
                    max: 36,
                    divisions: 11,
                    label: '$_timelineMonths months',
                    onChanged: (value) => setState(
                        () => _timelineMonths = (value / 3).round() * 3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Your target'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.flag_outlined,
                  label: 'Target fund',
                  value: CurrencyFormatter.myr(plan.targetAmount),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.savings_outlined,
                  label: 'Still needed',
                  value: CurrencyFormatter.myr(plan.gap),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'Monthly save',
                  value: CurrencyFormatter.myr(plan.monthlyContribution),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.shield_outlined,
                  label: 'Coverage now',
                  value: '${plan.currentCoverageMonths.toStringAsFixed(1)} mo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _ProgressCard(plan: plan),
          const SizedBox(height: 14),
          _GuidanceCard(plan: plan),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.plan});

  final EmergencyFundPlan plan;

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
          const Text('Recommended emergency reserve',
              style: TextStyle(color: Color(0xFFDCD6FF))),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.myr(plan.targetAmount),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1),
          ),
          const SizedBox(height: 8),
          Text(
            'Built from ${CurrencyFormatter.myr(plan.monthlyEssentials)} estimated monthly expenses × ${plan.coverageMonths} months.',
            style: const TextStyle(color: Color(0xFFE8E4FF), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.icon, required this.label, required this.value});

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
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 5),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.plan});

  final EmergencyFundPlan plan;

  @override
  Widget build(BuildContext context) {
    final percent = (plan.coverageProgress * 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Funding progress',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                Text('$percent%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                  value: plan.coverageProgress, minHeight: 10),
            ),
            const SizedBox(height: 12),
            Text(
              plan.isFullyFunded
                  ? 'Your selected emergency fund target is fully covered.'
                  : 'Save ${CurrencyFormatter.myr(plan.monthlyContribution)} per month to close the gap in ${plan.timelineMonths} months.',
              style: const TextStyle(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({required this.plan});

  final EmergencyFundPlan plan;

  @override
  Widget build(BuildContext context) {
    final message = plan.monthlyEssentials <= 0
        ? 'Add expense transactions first so MoneyTracker Pro can estimate a realistic emergency-fund target.'
        : plan.isFullyFunded
            ? 'Target reached. Keep this money liquid and separate from daily spending so it stays available for real emergencies.'
            : plan.currentCoverageMonths < 1
                ? 'Priority: build the first month of expenses as quickly as your cash flow allows, then work toward the full target.'
                : 'You already have a useful buffer. Continue the monthly contribution until you reach your selected coverage target.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(height: 1.45))),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      );
}
