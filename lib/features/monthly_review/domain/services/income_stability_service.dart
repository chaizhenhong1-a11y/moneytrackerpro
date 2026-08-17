import '../models/income_stability_plan.dart';
import '../models/monthly_financial_review.dart';

abstract final class IncomeStabilityService {
  static IncomeStabilityPlan build(MonthlyFinancialReview review) {
    final currentIncome = review.income;
    final previousIncome = review.previousIncome;
    final currentExpenses = review.expenses;

    if (currentIncome <= 0 && previousIncome <= 0) {
      return const IncomeStabilityPlan(
        currentIncome: 0,
        previousIncome: 0,
        currentExpenses: 0,
        conservativeIncomeBaseline: 0,
        recommendedIncomeReserve: 0,
        safeSpendingBaseline: 0,
        stabilityScore: 0,
        status: IncomeStabilityStatus.noHistory,
        reserveRate: 0,
        summary:
            'Add income transactions for at least two months to build a useful income stability baseline.',
      );
    }

    if (previousIncome <= 0) {
      final baseline = currentIncome * .80;
      final reserveRate = .20;
      final reserve = baseline * reserveRate;
      return IncomeStabilityPlan(
        currentIncome: currentIncome,
        previousIncome: previousIncome,
        currentExpenses: currentExpenses,
        conservativeIncomeBaseline: baseline,
        recommendedIncomeReserve: reserve,
        safeSpendingBaseline: baseline - reserve,
        stabilityScore: 50,
        status: IncomeStabilityStatus.noHistory,
        reserveRate: reserveRate,
        summary:
            'There is not enough previous-month income history yet, so the planner uses a conservative 80% income baseline and a larger reserve.',
      );
    }

    final changePercent =
        ((currentIncome - previousIncome) / previousIncome) * 100;
    final variation = changePercent.abs();
    final stabilityScore = (100 - (variation * 2)).clamp(0, 100).toDouble();

    final IncomeStabilityStatus status;
    final double reserveRate;
    if (variation <= 10) {
      status = IncomeStabilityStatus.stable;
      reserveRate = .10;
    } else if (variation <= 25) {
      status = IncomeStabilityStatus.watch;
      reserveRate = .15;
    } else {
      status = IncomeStabilityStatus.volatile;
      reserveRate = .25;
    }

    final baseline =
        currentIncome < previousIncome ? currentIncome : previousIncome;
    final reserve = baseline * reserveRate;
    final safeSpending =
        (baseline - reserve).clamp(0, double.infinity).toDouble();

    final summary = switch (status) {
      IncomeStabilityStatus.stable =>
        'Income is relatively consistent month to month. Keep a modest reserve and budget from the lower of the two months.',
      IncomeStabilityStatus.watch =>
        'Income moved enough to deserve a wider buffer. Avoid building fixed spending around the stronger month.',
      IncomeStabilityStatus.volatile =>
        'Income is moving sharply. Use the lower month as your budget ceiling and keep a larger portion untouched for uneven months.',
      IncomeStabilityStatus.noHistory => '',
    };

    return IncomeStabilityPlan(
      currentIncome: currentIncome,
      previousIncome: previousIncome,
      currentExpenses: currentExpenses,
      conservativeIncomeBaseline: baseline,
      recommendedIncomeReserve: reserve,
      safeSpendingBaseline: safeSpending,
      stabilityScore: stabilityScore,
      status: status,
      reserveRate: reserveRate,
      summary: summary,
      incomeChangePercent: changePercent,
    );
  }
}
