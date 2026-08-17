import '../../../transactions/domain/entities/transaction_entry.dart';

class MonthlyFinancialReview {
  const MonthlyFinancialReview({
    required this.month,
    required this.previousMonth,
    required this.income,
    required this.expenses,
    required this.previousIncome,
    required this.previousExpenses,
    required this.averageDailySpend,
    required this.previousAverageDailySpend,
    required this.savingsRate,
    required this.previousSavingsRate,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.largestExpense,
    required this.expenseCount,
    required this.previousExpenseCount,
  });

  final DateTime month;
  final DateTime previousMonth;
  final double income;
  final double expenses;
  final double previousIncome;
  final double previousExpenses;
  final double averageDailySpend;
  final double previousAverageDailySpend;
  final double savingsRate;
  final double previousSavingsRate;
  final String? topCategory;
  final double topCategoryAmount;
  final TransactionEntry? largestExpense;
  final int expenseCount;
  final int previousExpenseCount;

  double get netCashFlow => income - expenses;
  double get previousNetCashFlow => previousIncome - previousExpenses;
  double get expenseChange => expenses - previousExpenses;
  double get incomeChange => income - previousIncome;
  double get averageDailySpendChange =>
      averageDailySpend - previousAverageDailySpend;
  double get savingsRateChange => savingsRate - previousSavingsRate;

  double? get expenseChangePercent =>
      _percentChange(previousExpenses, expenses);
  double? get incomeChangePercent => _percentChange(previousIncome, income);

  static double? _percentChange(double previous, double current) {
    if (previous == 0) return current == 0 ? 0 : null;
    return ((current - previous) / previous) * 100;
  }
}
