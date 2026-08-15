import '../../../recurring/domain/entities/recurring_transaction_rule.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../models/cash_flow_projection.dart';

abstract final class CashFlowForecastService {
  static CashFlowProjection project({
    required double openingBalance,
    required List<RecurringTransactionRule> rules,
    required Set<String> activeAccountIds,
    int days = 30,
    DateTime? from,
  }) {
    final start = _dateOnly(from ?? DateTime.now());
    final end = start.add(Duration(days: days > 0 ? days - 1 : 0));
    final occurrences = <DateTime, List<RecurringTransactionRule>>{};

    for (final rule in rules) {
      if (rule.isPaused || !activeAccountIds.contains(rule.accountId)) continue;
      var due = _dateOnly(rule.nextDueDate);
      var safety = 0;
      while (!due.isAfter(end) && safety < 120) {
        if (!due.isBefore(start)) {
          occurrences.putIfAbsent(due, () => []).add(rule);
        }
        due = _nextDate(due, rule.frequency);
        safety++;
      }
    }

    final dates = occurrences.keys.toList()..sort();
    final points = <CashFlowProjectionPoint>[];
    var balance = openingBalance;
    var lowest = openingBalance;
    var income = 0.0;
    var expense = 0.0;
    DateTime? firstNegativeDate;

    for (final date in dates) {
      final dueRules = occurrences[date]!;
      var change = 0.0;
      for (final rule in dueRules) {
        if (rule.type == TransactionType.income) {
          income += rule.amount;
          change += rule.amount;
        } else {
          expense += rule.amount;
          change -= rule.amount;
        }
      }
      balance += change;
      if (balance < lowest) lowest = balance;
      if (balance < 0 && firstNegativeDate == null) firstNegativeDate = date;
      points.add(
        CashFlowProjectionPoint(
          date: date,
          balance: balance,
          change: change,
          rules: List.unmodifiable(dueRules),
        ),
      );
    }

    return CashFlowProjection(
      openingBalance: openingBalance,
      closingBalance: balance,
      lowestBalance: lowest,
      projectedIncome: income,
      projectedExpense: expense,
      points: List.unmodifiable(points),
      firstNegativeDate: firstNegativeDate,
    );
  }

  static DateTime _nextDate(DateTime date, RecurringFrequency frequency) {
    return switch (frequency) {
      RecurringFrequency.weekly => date.add(const Duration(days: 7)),
      RecurringFrequency.monthly => _addMonths(date, 1),
      RecurringFrequency.yearly => _addMonths(date, 12),
    };
  }

  static DateTime _addMonths(DateTime date, int months) {
    final targetMonth = date.month - 1 + months;
    final year = date.year + targetMonth ~/ 12;
    final month = targetMonth % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }

  static DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
}
