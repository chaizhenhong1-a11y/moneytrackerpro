class SpendingPaceForecast {
  const SpendingPaceForecast({
    required this.daysElapsed,
    required this.daysInMonth,
    required this.daysRemaining,
    required this.currentExpenses,
    required this.projectedExpenses,
    required this.projectedNetCashFlow,
    required this.previousExpenses,
    required this.paceVsLastMonthPercent,
    required this.status,
    required this.message,
  });

  final int daysElapsed;
  final int daysInMonth;
  final int daysRemaining;
  final double currentExpenses;
  final double projectedExpenses;
  final double projectedNetCashFlow;
  final double previousExpenses;
  final double? paceVsLastMonthPercent;
  final SpendingPaceStatus status;
  final String message;

  double get monthProgress => daysInMonth == 0 ? 0 : daysElapsed / daysInMonth;

  double get projectedAdditionalSpend => (projectedExpenses - currentExpenses)
      .clamp(0, double.infinity)
      .toDouble();
}

enum SpendingPaceStatus { ahead, steady, watch }
