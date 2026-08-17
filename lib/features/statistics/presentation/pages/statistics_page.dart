import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../../monthly_review/domain/services/monthly_financial_review_service.dart';
import '../../../monthly_review/presentation/pages/monthly_financial_review_page.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({required this.controller, super.key});

  final DashboardController controller;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final monthly = widget.controller.transactions
            .where((item) =>
                item.date.year == _selectedMonth.year &&
                item.date.month == _selectedMonth.month)
            .toList();
        final income = monthly
            .where((item) => item.countsAsIncome)
            .fold<double>(0, (sum, item) => sum + item.amount);
        final expenses = monthly
            .where((item) => item.countsAsExpense)
            .fold<double>(0, (sum, item) => sum + item.amount);
        final savingsRate = income == 0
            ? 0.0
            : ((income - expenses) / income * 100).clamp(-999, 100).toDouble();
        final categories = _buildCategoryTotals(monthly);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Statistics',
                style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded)),
              Container(
                constraints: const BoxConstraints(minWidth: 82),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(
                  '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: _canMoveForward ? () => _changeMonth(1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              IconButton(
                tooltip: 'Monthly review',
                onPressed: _openMonthlyReview,
                icon: const Icon(Icons.auto_graph_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: widget.controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                _SavingsCard(
                  income: income,
                  expenses: expenses,
                  savingsRate: savingsRate,
                ),
                const SizedBox(height: 22),
                const _SectionTitle(
                    title: 'Last 7 days', subtitle: 'Daily expenses'),
                const SizedBox(height: 12),
                _WeeklyExpenseCard(
                    transactions: monthly, month: _selectedMonth),
                const SizedBox(height: 22),
                const _SectionTitle(
                    title: 'Spending by category', subtitle: 'This month'),
                const SizedBox(height: 12),
                if (categories.isEmpty)
                  const _EmptyStatistics()
                else
                  _CategoryBreakdownCard(categories: categories),
              ],
            ),
          ),
        );
      },
    );
  }

  bool get _canMoveForward {
    final now = DateTime.now();
    return _selectedMonth.isBefore(DateTime(now.year, now.month));
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
  }

  void _openMonthlyReview() {
    final review = MonthlyFinancialReviewService.build(
      transactions: widget.controller.transactions,
      month: _selectedMonth,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) => MonthlyFinancialReviewPage(review: review)),
    );
  }

  List<_CategoryTotal> _buildCategoryTotals(
      List<TransactionEntry> transactions) {
    final totals = <String, _CategoryTotal>{};
    for (final item in transactions.where((item) => item.countsAsExpense)) {
      final current = totals[item.category];
      totals[item.category] = _CategoryTotal(
        name: item.category,
        amount: (current?.amount ?? 0) + item.amount,
        color: item.color,
        icon: item.icon,
      );
    }
    final result = totals.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard(
      {required this.income,
      required this.expenses,
      required this.savingsRate});

  final double income;
  final double expenses;
  final double savingsRate;

  @override
  Widget build(BuildContext context) {
    final positive = savingsRate >= 0;
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
              color: AppColors.primary.withValues(alpha: .22),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly savings rate',
              style: TextStyle(color: Color(0xFFDCD6FF))),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${savingsRate.toStringAsFixed(1)}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Icon(
                  positive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: positive
                      ? const Color(0xFF85F0C1)
                      : const Color(0xFFFFB59C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                  child: _MoneyMetric(
                      label: 'Income',
                      value: income,
                      color: const Color(0xFF85F0C1))),
              const SizedBox(width: 12),
              Expanded(
                  child: _MoneyMetric(
                      label: 'Expenses',
                      value: expenses,
                      color: const Color(0xFFFFB59C))),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyMetric extends StatelessWidget {
  const _MoneyMetric(
      {required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text(label,
                style: const TextStyle(color: Color(0xFFDCD6FF), fontSize: 12))
          ]),
          const SizedBox(height: 6),
          Text(CurrencyFormatter.myr(value),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WeeklyExpenseCard extends StatelessWidget {
  const _WeeklyExpenseCard({required this.transactions, required this.month});

  final List<TransactionEntry> transactions;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = month.year == now.year && month.month == now.month;
    final endDate = isCurrentMonth
        ? DateTime(now.year, now.month, now.day)
        : DateTime(month.year, month.month + 1, 0);
    final days = List.generate(7, (index) {
      final date = endDate.subtract(Duration(days: 6 - index));
      final total = transactions
          .where((item) =>
              item.countsAsExpense &&
              item.date.year == date.year &&
              item.date.month == date.month &&
              item.date.day == date.day)
          .fold<double>(0, (sum, item) => sum + item.amount);
      return _DailyExpense(date: date, amount: total);
    });
    final total = days.fold<double>(0, (sum, item) => sum + item.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(CurrencyFormatter.myr(total),
                style:
                    const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Total spent in the last 7 days',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 22),
            SizedBox(
                height: 145,
                child: CustomPaint(
                    painter: _WeeklyBarPainter(days),
                    child: const SizedBox.expand())),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBarPainter extends CustomPainter {
  const _WeeklyBarPainter(this.days);

  final List<_DailyExpense> days;

  @override
  void paint(Canvas canvas, Size size) {
    final maxAmount =
        days.fold<double>(0, (max, item) => math.max(max, item.amount));
    final chartHeight = size.height - 24;
    final slot = size.width / days.length;
    final barWidth = math.min(24.0, slot * .46);
    final background = Paint()..color = AppColors.primarySoft;
    final foreground = Paint()..color = AppColors.primary;

    for (var i = 0; i < days.length; i++) {
      final centerX = slot * i + slot / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - barWidth / 2, 0, barWidth, chartHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, background);

      final ratio = maxAmount == 0 ? 0.0 : days[i].amount / maxAmount;
      final height = chartHeight * ratio;
      if (height > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
                centerX - barWidth / 2, chartHeight - height, barWidth, height),
            const Radius.circular(8),
          ),
          foreground,
        );
      }

      final label = TextPainter(
        text: TextSpan(
            text: _weekday(days[i].date.weekday),
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(centerX - label.width / 2, size.height - 14));
    }
  }

  static String _weekday(int weekday) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

  @override
  bool shouldRepaint(covariant _WeeklyBarPainter oldDelegate) =>
      oldDelegate.days != days;
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.categories});

  final List<_CategoryTotal> categories;

  @override
  Widget build(BuildContext context) {
    final total = categories.fold<double>(0, (sum, item) => sum + item.amount);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                      size: const Size.square(170),
                      painter: _DonutPainter(categories, total)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 3),
                      Text(CurrencyFormatter.myr(total),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...categories.map((category) {
              final percentage =
                  total == 0 ? 0.0 : category.amount / total * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                            color: category.color.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(category.icon,
                            color: category.color, size: 19)),
                    const SizedBox(width: 11),
                    Expanded(
                        child: Text(category.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                    Text('${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    SizedBox(
                        width: 86,
                        child: Text(CurrencyFormatter.myr(category.amount),
                            textAlign: TextAlign.end,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700))),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.categories, this.total);

  final List<_CategoryTotal> categories;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 14;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;
    var start = -math.pi / 2;
    const gap = .035;

    for (final category in categories) {
      final sweep = total == 0 ? 0.0 : category.amount / total * math.pi * 2;
      paint.color = category.color;
      canvas.drawArc(
          rect, start + gap / 2, math.max(0.0, sweep - gap), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.categories != categories || oldDelegate.total != total;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontSize: 19, fontWeight: FontWeight.w700))),
      Text(subtitle,
          style: const TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w600))
    ]);
  }
}

class _EmptyStatistics extends StatelessWidget {
  const _EmptyStatistics();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(34),
        child: Column(
          children: [
            Icon(Icons.donut_large_rounded,
                color: AppColors.textSecondary, size: 40),
            SizedBox(height: 12),
            Text('No expenses this month',
                style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 5),
            Text('Expense categories will appear here.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _CategoryTotal {
  const _CategoryTotal(
      {required this.name,
      required this.amount,
      required this.color,
      required this.icon});
  final String name;
  final double amount;
  final Color color;
  final IconData icon;
}

class _DailyExpense {
  const _DailyExpense({required this.date, required this.amount});
  final DateTime date;
  final double amount;
}
