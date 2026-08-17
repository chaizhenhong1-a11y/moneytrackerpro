import '../models/budget_stress_test_result.dart';
import '../models/monthly_financial_review.dart';

abstract final class BudgetStressTestService {
  static BudgetStressTestResult run({
    required MonthlyFinancialReview review,
    required double incomeDropPercent,
    required double extraExpense,
  }) {
    final normalizedDrop = incomeDropPercent.clamp(0, 100).toDouble();
    final normalizedExpense = extraExpense < 0 ? 0.0 : extraExpense;

    final projectedIncome = review.income * (1 - normalizedDrop / 100);
    final projectedExpenses = review.expenses + normalizedExpense;
    final projectedNetCashFlow = projectedIncome - projectedExpenses;
    final projectedSavingsRate = projectedIncome == 0
        ? (projectedExpenses == 0 ? 0.0 : -100.0)
        : ((projectedNetCashFlow / projectedIncome) * 100)
            .clamp(-999, 100)
            .toDouble();

    final BudgetStressLevel level;
    final String headline;
    final String guidance;

    if (projectedNetCashFlow < 0) {
      level = BudgetStressLevel.danger;
      headline = 'This scenario pushes cash flow negative';
      guidance =
          'Reduce flexible spending, postpone non-essential purchases, or increase your cash buffer before this scenario happens.';
    } else if (projectedSavingsRate < 20) {
      level = BudgetStressLevel.caution;
      headline = 'You stay positive, but your margin gets thin';
      guidance =
          'You can absorb this shock, but it would leave little room for savings. Consider trimming discretionary spending first.';
    } else {
      level = BudgetStressLevel.safe;
      headline = 'Your budget can absorb this scenario';
      guidance =
          'Cash flow remains healthy after the stress test. Keep your current buffer and continue monitoring larger expenses.';
    }

    return BudgetStressTestResult(
      incomeDropPercent: normalizedDrop,
      extraExpense: normalizedExpense,
      projectedIncome: projectedIncome,
      projectedExpenses: projectedExpenses,
      projectedNetCashFlow: projectedNetCashFlow,
      projectedSavingsRate: projectedSavingsRate,
      level: level,
      headline: headline,
      guidance: guidance,
    );
  }
}
