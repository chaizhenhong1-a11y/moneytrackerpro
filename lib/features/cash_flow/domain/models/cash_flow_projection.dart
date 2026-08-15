import '../../../recurring/domain/entities/recurring_transaction_rule.dart';

class CashFlowProjectionPoint {
  const CashFlowProjectionPoint({
    required this.date,
    required this.balance,
    required this.change,
    required this.rules,
  });

  final DateTime date;
  final double balance;
  final double change;
  final List<RecurringTransactionRule> rules;
}

class CashFlowProjection {
  const CashFlowProjection({
    required this.openingBalance,
    required this.closingBalance,
    required this.lowestBalance,
    required this.projectedIncome,
    required this.projectedExpense,
    required this.points,
    this.firstNegativeDate,
  });

  final double openingBalance;
  final double closingBalance;
  final double lowestBalance;
  final double projectedIncome;
  final double projectedExpense;
  final List<CashFlowProjectionPoint> points;
  final DateTime? firstNegativeDate;

  double get netChange => closingBalance - openingBalance;
  bool get hasShortfall => firstNegativeDate != null;
}
