import '../models/emergency_fund_plan.dart';
import '../models/monthly_financial_review.dart';

abstract final class EmergencyFundService {
  static EmergencyFundPlan build({
    required MonthlyFinancialReview review,
    required double currentFund,
    required int coverageMonths,
    required int timelineMonths,
  }) {
    final monthlyEssentials = _baselineMonthlyExpenses(review);
    final targetAmount = monthlyEssentials * coverageMonths;
    final safeCurrentFund = currentFund < 0 ? 0.0 : currentFund;
    final gap =
        (targetAmount - safeCurrentFund).clamp(0, double.infinity).toDouble();
    final safeTimeline = timelineMonths <= 0 ? 1 : timelineMonths;
    final monthlyContribution = gap / safeTimeline;
    final progress = targetAmount <= 0
        ? 1.0
        : (safeCurrentFund / targetAmount).clamp(0, 1).toDouble();
    final currentCoverage =
        monthlyEssentials <= 0 ? 0.0 : safeCurrentFund / monthlyEssentials;

    return EmergencyFundPlan(
      monthlyEssentials: monthlyEssentials,
      coverageMonths: coverageMonths,
      targetAmount: targetAmount,
      currentFund: safeCurrentFund,
      gap: gap,
      timelineMonths: safeTimeline,
      monthlyContribution: monthlyContribution,
      coverageProgress: progress,
      currentCoverageMonths: currentCoverage,
    );
  }

  static double _baselineMonthlyExpenses(MonthlyFinancialReview review) {
    if (review.expenses > 0 && review.previousExpenses > 0) {
      return (review.expenses + review.previousExpenses) / 2;
    }
    if (review.expenses > 0) return review.expenses;
    if (review.previousExpenses > 0) return review.previousExpenses;
    return 0;
  }
}
