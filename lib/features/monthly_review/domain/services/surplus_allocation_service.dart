import '../models/monthly_financial_review.dart';
import '../models/surplus_allocation_plan.dart';

class SurplusAllocationService {
  const SurplusAllocationService._();

  static SurplusAllocationPlan build(
    MonthlyFinancialReview review, {
    required SurplusAllocationStrategy strategy,
  }) {
    final surplus = review.netCashFlow > 0 ? review.netCashFlow : 0.0;

    if (surplus <= 0) {
      return SurplusAllocationPlan(
        strategy: strategy,
        availableSurplus: 0,
        emergencyFund: 0,
        extraDebtPayment: 0,
        savingsGoals: 0,
        flexibleMoney: 0,
        summary:
            'There is no positive monthly surplus to allocate yet. Focus on restoring positive cash flow first.',
      );
    }

    final weights = switch (strategy) {
      SurplusAllocationStrategy.balanced => const [0.35, 0.25, 0.25, 0.15],
      SurplusAllocationStrategy.safetyFirst => const [0.55, 0.20, 0.15, 0.10],
      SurplusAllocationStrategy.debtFirst => const [0.20, 0.55, 0.15, 0.10],
      SurplusAllocationStrategy.goalsFirst => const [0.20, 0.20, 0.50, 0.10],
    };

    return SurplusAllocationPlan(
      strategy: strategy,
      availableSurplus: surplus,
      emergencyFund: surplus * weights[0],
      extraDebtPayment: surplus * weights[1],
      savingsGoals: surplus * weights[2],
      flexibleMoney: surplus * weights[3],
      summary: _summary(strategy),
    );
  }

  static String _summary(SurplusAllocationStrategy strategy) {
    return switch (strategy) {
      SurplusAllocationStrategy.balanced =>
        'Spread your surplus across safety, debt reduction, goals, and a small flexible allowance.',
      SurplusAllocationStrategy.safetyFirst =>
        'Build resilience first by sending the largest share of your surplus to your emergency fund.',
      SurplusAllocationStrategy.debtFirst =>
        'Accelerate debt payoff while still keeping smaller contributions toward savings and goals.',
      SurplusAllocationStrategy.goalsFirst =>
        'Push your savings goals forward faster while keeping a basic safety and debt contribution.',
    };
  }
}
