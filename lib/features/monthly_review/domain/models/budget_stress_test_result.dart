enum BudgetStressLevel { safe, caution, danger }

class BudgetStressTestResult {
  const BudgetStressTestResult({
    required this.incomeDropPercent,
    required this.extraExpense,
    required this.projectedIncome,
    required this.projectedExpenses,
    required this.projectedNetCashFlow,
    required this.projectedSavingsRate,
    required this.level,
    required this.headline,
    required this.guidance,
  });

  final double incomeDropPercent;
  final double extraExpense;
  final double projectedIncome;
  final double projectedExpenses;
  final double projectedNetCashFlow;
  final double projectedSavingsRate;
  final BudgetStressLevel level;
  final String headline;
  final String guidance;
}
