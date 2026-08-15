import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/debt.dart';

enum DebtPayoffStrategy { snowball, avalanche }

class DebtPayoffPlannerPage extends StatefulWidget {
  const DebtPayoffPlannerPage({required this.debts, super.key});

  final List<Debt> debts;

  @override
  State<DebtPayoffPlannerPage> createState() => _DebtPayoffPlannerPageState();
}

class _DebtPayoffPlannerPageState extends State<DebtPayoffPlannerPage> {
  DebtPayoffStrategy _strategy = DebtPayoffStrategy.avalanche;
  late final TextEditingController _monthlyBudgetController;

  @override
  void initState() {
    super.initState();
    final outstanding = _activeDebts.fold<double>(0, (sum, debt) => sum + debt.currentBalance);
    final suggestion = outstanding <= 0 ? 500.0 : math.max(100.0, outstanding / 24);
    _monthlyBudgetController = TextEditingController(text: suggestion.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  List<Debt> get _activeDebts => widget.debts.where((debt) => !debt.isPaidOff).toList();

  @override
  Widget build(BuildContext context) {
    final monthlyBudget = double.tryParse(_monthlyBudgetController.text.trim()) ?? 0;
    final projection = _buildProjection(_activeDebts, monthlyBudget, _strategy);

    return Scaffold(
      appBar: AppBar(title: const Text('Debt payoff planner')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _IntroCard(activeDebtCount: _activeDebts.length),
          const SizedBox(height: 18),
          _StrategySelector(
            value: _strategy,
            onChanged: (value) => setState(() => _strategy = value),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _monthlyBudgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monthly payoff budget',
              prefixText: 'RM ',
              helperText: 'Amount you plan to put toward tracked debts each month.',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),
          if (_activeDebts.isEmpty)
            const _EmptyPlannerState()
          else if (monthlyBudget <= 0)
            const _InvalidBudgetCard()
          else ...[
            _ProjectionSummary(projection: projection),
            const SizedBox(height: 20),
            const Text('Payoff order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...projection.items.asMap().entries.map(
              (entry) => _PayoffItemCard(index: entry.key + 1, item: entry.value),
            ),
            const SizedBox(height: 10),
            const _ProjectionNote(),
          ],
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.activeDebtCount});

  final int activeDebtCount;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.route_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Build a payoff path', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(
                    '$activeDebtCount active ${activeDebtCount == 1 ? 'debt' : 'debts'} available for planning. Compare a balance-first Snowball plan with an interest-first Avalanche plan.',
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StrategySelector extends StatelessWidget {
  const _StrategySelector({required this.value, required this.onChanged});

  final DebtPayoffStrategy value;
  final ValueChanged<DebtPayoffStrategy> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<DebtPayoffStrategy>(
        segments: const [
          ButtonSegment(
            value: DebtPayoffStrategy.avalanche,
            icon: Icon(Icons.trending_down_rounded),
            label: Text('Avalanche'),
          ),
          ButtonSegment(
            value: DebtPayoffStrategy.snowball,
            icon: Icon(Icons.snowing),
            label: Text('Snowball'),
          ),
        ],
        selected: {value},
        onSelectionChanged: (values) => onChanged(values.first),
      );
}

class _ProjectionSummary extends StatelessWidget {
  const _ProjectionSummary({required this.projection});

  final DebtPayoffProjection projection;

  @override
  Widget build(BuildContext context) {
    final monthsText = projection.isPayoffPossible
        ? '${projection.monthsToPayoff} ${projection.monthsToPayoff == 1 ? 'month' : 'months'}'
        : 'Not reachable';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Projection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Outstanding', value: CurrencyFormatter.myr(projection.startingBalance))),
              const SizedBox(width: 10),
              Expanded(child: _Metric(label: 'Estimated payoff', value: monthsText)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Projected interest', value: CurrencyFormatter.myr(projection.projectedInterest))),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  label: 'Strategy',
                  value: projection.strategy == DebtPayoffStrategy.avalanche ? 'Avalanche' : 'Snowball',
                ),
              ),
            ],
          ),
          if (!projection.isPayoffPossible) ...[
            const SizedBox(height: 12),
            const Text(
              'The selected monthly budget is too low to overcome projected interest. Increase the monthly payoff budget.',
              style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      );
}

class _PayoffItemCard extends StatelessWidget {
  const _PayoffItemCard({required this.index, required this.item});

  final int index;
  final DebtPayoffItem item;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                foregroundColor: AppColors.primary,
                child: Text('$index', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.debt.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      '${item.debt.interestRate.toStringAsFixed(2)}% APR · ${CurrencyFormatter.myr(item.debt.currentBalance)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.payoffMonth == null ? '—' : 'Month ${item.payoffMonth}', style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  const Text('target payoff', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      );
}

class _ProjectionNote extends StatelessWidget {
  const _ProjectionNote();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 19, color: AppColors.textSecondary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Planning estimate only. This simplified model compounds each debt monthly at its recorded APR and applies the entered budget in strategy order. It does not model lender minimum payments, fees, promotional rates, or changing APRs.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 12),
              ),
            ),
          ],
        ),
      );
}

class _EmptyPlannerState extends StatelessWidget {
  const _EmptyPlannerState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.celebration_outlined, size: 50, color: AppColors.success),
            SizedBox(height: 12),
            Text('No active debt to plan.', style: TextStyle(fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text('Add a liability or keep enjoying the zero-balance view.', style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      );
}

class _InvalidBudgetCard extends StatelessWidget {
  const _InvalidBudgetCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(18)),
        child: const Text('Enter a monthly payoff budget greater than RM 0 to build the projection.'),
      );
}

class DebtPayoffProjection {
  const DebtPayoffProjection({
    required this.strategy,
    required this.startingBalance,
    required this.projectedInterest,
    required this.monthsToPayoff,
    required this.items,
    required this.isPayoffPossible,
  });

  final DebtPayoffStrategy strategy;
  final double startingBalance;
  final double projectedInterest;
  final int monthsToPayoff;
  final List<DebtPayoffItem> items;
  final bool isPayoffPossible;
}

class DebtPayoffItem {
  const DebtPayoffItem({required this.debt, required this.payoffMonth});

  final Debt debt;
  final int? payoffMonth;
}

DebtPayoffProjection _buildProjection(
  List<Debt> source,
  double monthlyBudget,
  DebtPayoffStrategy strategy,
) {
  final ordered = [...source]..sort((a, b) {
      if (strategy == DebtPayoffStrategy.snowball) {
        final balanceCompare = a.currentBalance.compareTo(b.currentBalance);
        return balanceCompare != 0 ? balanceCompare : b.interestRate.compareTo(a.interestRate);
      }
      final rateCompare = b.interestRate.compareTo(a.interestRate);
      return rateCompare != 0 ? rateCompare : a.currentBalance.compareTo(b.currentBalance);
    });

  final startingBalance = ordered.fold<double>(0, (sum, debt) => sum + debt.currentBalance);
  if (ordered.isEmpty || monthlyBudget <= 0) {
    return DebtPayoffProjection(
      strategy: strategy,
      startingBalance: startingBalance,
      projectedInterest: 0,
      monthsToPayoff: 0,
      items: [for (final debt in ordered) DebtPayoffItem(debt: debt, payoffMonth: null)],
      isPayoffPossible: ordered.isEmpty,
    );
  }

  final balances = <String, double>{for (final debt in ordered) debt.id: debt.currentBalance};
  final payoffMonths = <String, int>{};
  var projectedInterest = 0.0;
  var month = 0;
  var previousTotal = startingBalance;
  var stagnantMonths = 0;
  const maxMonths = 1200;

  while (balances.values.any((value) => value > 0.005) && month < maxMonths) {
    month++;

    for (final debt in ordered) {
      final balance = balances[debt.id] ?? 0;
      if (balance <= 0.005) continue;
      final interest = balance * (debt.interestRate / 100) / 12;
      balances[debt.id] = balance + interest;
      projectedInterest += interest;
    }

    var available = monthlyBudget;
    for (final debt in ordered) {
      if (available <= 0.005) break;
      final balance = balances[debt.id] ?? 0;
      if (balance <= 0.005) continue;
      final payment = math.min(balance, available);
      final remaining = balance - payment;
      balances[debt.id] = remaining;
      available -= payment;
      if (remaining <= 0.005) payoffMonths[debt.id] = month;
    }

    final currentTotal = balances.values.fold<double>(0, (sum, value) => sum + value);
    if (currentTotal >= previousTotal - 0.005) {
      stagnantMonths++;
    } else {
      stagnantMonths = 0;
    }
    previousTotal = currentTotal;
    if (stagnantMonths >= 12) break;
  }

  final isPayoffPossible = balances.values.every((value) => value <= 0.005);
  return DebtPayoffProjection(
    strategy: strategy,
    startingBalance: startingBalance,
    projectedInterest: projectedInterest,
    monthsToPayoff: isPayoffPossible ? month : maxMonths,
    items: [
      for (final debt in ordered)
        DebtPayoffItem(debt: debt, payoffMonth: payoffMonths[debt.id]),
    ],
    isPayoffPossible: isPayoffPossible,
  );
}
