import '../../../transactions/domain/entities/transaction_entry.dart';
import '../models/monthly_financial_review.dart';

abstract final class MonthlyFinancialReviewService {
  static MonthlyFinancialReview build({
    required List<TransactionEntry> transactions,
    required DateTime month,
    DateTime? now,
  }) {
    final normalizedMonth = DateTime(month.year, month.month);
    final previousMonth = DateTime(month.year, month.month - 1);
    final effectiveNow = now ?? DateTime.now();

    final current = transactions
        .where((item) => _isSameMonth(item.date, normalizedMonth))
        .toList();
    final previous = transactions
        .where((item) => _isSameMonth(item.date, previousMonth))
        .toList();

    final currentIncome = _sumIncome(current);
    final currentExpenses = _sumExpenses(current);
    final previousIncome = _sumIncome(previous);
    final previousExpenses = _sumExpenses(previous);

    final currentExpenseItems =
        current.where((item) => item.countsAsExpense).toList();
    final previousExpenseItems =
        previous.where((item) => item.countsAsExpense).toList();

    final currentDays = _comparisonDays(normalizedMonth, effectiveNow);
    final previousDays = _comparisonDays(previousMonth, effectiveNow);
    final categoryTotals = <String, double>{};
    for (final item in currentExpenseItems) {
      categoryTotals[item.category] =
          (categoryTotals[item.category] ?? 0) + item.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    TransactionEntry? largestExpense;
    for (final item in currentExpenseItems) {
      if (largestExpense == null || item.amount > largestExpense.amount) {
        largestExpense = item;
      }
    }

    return MonthlyFinancialReview(
      month: normalizedMonth,
      previousMonth: previousMonth,
      income: currentIncome,
      expenses: currentExpenses,
      previousIncome: previousIncome,
      previousExpenses: previousExpenses,
      averageDailySpend: currentDays == 0 ? 0 : currentExpenses / currentDays,
      previousAverageDailySpend:
          previousDays == 0 ? 0 : previousExpenses / previousDays,
      savingsRate: _savingsRate(currentIncome, currentExpenses),
      previousSavingsRate: _savingsRate(previousIncome, previousExpenses),
      topCategory: sortedCategories.isEmpty ? null : sortedCategories.first.key,
      topCategoryAmount:
          sortedCategories.isEmpty ? 0 : sortedCategories.first.value,
      largestExpense: largestExpense,
      expenseCount: currentExpenseItems.length,
      previousExpenseCount: previousExpenseItems.length,
    );
  }

  static double _sumIncome(List<TransactionEntry> items) => items
      .where((item) => item.countsAsIncome)
      .fold<double>(0, (sum, item) => sum + item.amount);

  static double _sumExpenses(List<TransactionEntry> items) => items
      .where((item) => item.countsAsExpense)
      .fold<double>(0, (sum, item) => sum + item.amount);

  static double _savingsRate(double income, double expenses) {
    if (income == 0) return 0;
    return (((income - expenses) / income) * 100).clamp(-999, 100).toDouble();
  }

  static bool _isSameMonth(DateTime date, DateTime month) =>
      date.year == month.year && date.month == month.month;

  static int _comparisonDays(DateTime month, DateTime now) {
    final currentMonth = DateTime(now.year, now.month);
    if (month.isAfter(currentMonth)) return 0;
    if (month.year == now.year && month.month == now.month) return now.day;
    return DateTime(month.year, month.month + 1, 0).day;
  }
}
