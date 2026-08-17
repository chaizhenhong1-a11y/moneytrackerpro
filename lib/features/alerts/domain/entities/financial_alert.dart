enum FinancialAlertType {
  budgetWarning,
  budgetExceeded,
  largeExpense,
  positiveSavings,
  noActivity
}

enum FinancialAlertSeverity { info, success, warning, critical }

class FinancialAlert {
  const FinancialAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
  });

  final String id;
  final FinancialAlertType type;
  final FinancialAlertSeverity severity;
  final String title;
  final String message;
}
