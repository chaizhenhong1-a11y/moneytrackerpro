import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';

class SpendingChartCard extends StatelessWidget {
  const SpendingChartCard({required this.transactions, super.key});

  final List<TransactionEntry> transactions;

  @override
  Widget build(BuildContext context) {
    final overview = _WeeklyOverview.from(transactions);
    final positiveChange = overview.changePercent <= 0;

    return Card(
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 21, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    CurrencyFormatter.myr(overview.currentTotal),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 9),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: positiveChange
                          ? AppColors.success.withValues(alpha: .1)
                          : AppColors.expense.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      overview.changeLabel,
                      style: TextStyle(
                        color: positiveChange ? AppColors.success : AppColors.expense,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              const Text(
                'Compared with the previous 7 days',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: CustomPaint(
                  painter: _SpendingChartPainter(overview.days),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyOverview {
  const _WeeklyOverview({
    required this.days,
    required this.currentTotal,
    required this.previousTotal,
  });

  factory _WeeklyOverview.from(List<TransactionEntry> transactions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentStart = today.subtract(const Duration(days: 6));
    final previousStart = currentStart.subtract(const Duration(days: 7));
    final previousEnd = currentStart.subtract(const Duration(days: 1));

    final days = List.generate(7, (index) {
      final date = currentStart.add(Duration(days: index));
      final amount = transactions.where((item) {
        final itemDate = DateTime(item.date.year, item.date.month, item.date.day);
        return item.countsAsExpense && itemDate == date;
      }).fold<double>(0, (sum, item) => sum + item.amount);
      return _ChartDay(date: date, amount: amount);
    });

    final currentTotal = days.fold<double>(0, (sum, item) => sum + item.amount);
    final previousTotal = transactions.where((item) {
      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);
      return item.countsAsExpense && !itemDate.isBefore(previousStart) && !itemDate.isAfter(previousEnd);
    }).fold<double>(0, (sum, item) => sum + item.amount);

    return _WeeklyOverview(
      days: days,
      currentTotal: currentTotal,
      previousTotal: previousTotal,
    );
  }

  final List<_ChartDay> days;
  final double currentTotal;
  final double previousTotal;

  double get changePercent {
    if (previousTotal == 0) return currentTotal == 0 ? 0 : 100;
    return (currentTotal - previousTotal) / previousTotal * 100;
  }

  String get changeLabel {
    if (previousTotal == 0 && currentTotal > 0) return 'New activity';
    if (currentTotal == 0 && previousTotal == 0) return 'No change';
    final prefix = changePercent > 0 ? '+' : '';
    return '$prefix${changePercent.toStringAsFixed(1)}%';
  }
}

class _SpendingChartPainter extends CustomPainter {
  const _SpendingChartPainter(this.days);

  final List<_ChartDay> days;

  @override
  void paint(Canvas canvas, Size size) {
    final chartHeight = size.height - 24;
    final grid = Paint()
      ..color = const Color(0xFFF0F0F4)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = chartHeight * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final maxAmount = days.fold<double>(0, (maximum, day) => math.max(maximum, day.amount));
    final points = List.generate(days.length, (index) {
      final x = size.width * index / (days.length - 1);
      final ratio = maxAmount == 0 ? .5 : days[index].amount / maxAmount;
      final y = chartHeight - (chartHeight * .82 * ratio) - chartHeight * .08;
      return Offset(x, y);
    });

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final middleX = (current.dx + next.dx) / 2;
      linePath.cubicTo(middleX, current.dy, middleX, next.dy, next.dx, next.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, chartHeight)
      ..lineTo(0, chartHeight)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x407057E8), Color(0x007057E8)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );

    for (var i = 0; i < points.length; i++) {
      if (days[i].amount <= 0) continue;
      canvas.drawCircle(points[i], 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(points[i], 3.2, Paint()..color = AppColors.primary);
    }

    for (var i = 0; i < days.length; i++) {
      final label = TextPainter(
        text: TextSpan(
          text: _weekday(days[i].date.weekday),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final rawX = size.width * i / (days.length - 1) - label.width / 2;
      label.paint(
        canvas,
        Offset(math.max(0, math.min(rawX, size.width - label.width)), size.height - 13),
      );
    }
  }

  static String _weekday(int weekday) {
    return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
  }

  @override
  bool shouldRepaint(covariant _SpendingChartPainter oldDelegate) {
    if (oldDelegate.days.length != days.length) return true;
    for (var i = 0; i < days.length; i++) {
      if (oldDelegate.days[i].amount != days[i].amount || oldDelegate.days[i].date != days[i].date) {
        return true;
      }
    }
    return false;
  }
}

class _ChartDay {
  const _ChartDay({required this.date, required this.amount});

  final DateTime date;
  final double amount;
}
