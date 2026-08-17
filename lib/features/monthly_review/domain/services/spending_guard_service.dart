import '../models/monthly_financial_review.dart';
import '../models/spending_guard_result.dart';
import 'safe_to_spend_service.dart';

abstract final class SpendingGuardService {
  static SpendingGuardResult evaluate({
    required MonthlyFinancialReview review,
    required double amount,
    DateTime? now,
  }) {
    final plan = SafeToSpendService.build(review, now: now);
    final normalizedAmount = amount < 0 ? 0.0 : amount;
    final remaining = (plan.safeToSpend - normalizedAmount)
        .clamp(0, double.infinity)
        .toDouble();
    final usagePercent = plan.safeToSpend <= 0
        ? 0.0
        : (normalizedAmount / plan.safeToSpend) * 100;
    final dailyAfter =
        plan.daysRemaining <= 0 ? 0.0 : remaining / plan.daysRemaining;

    if (plan.safeToSpend <= 0 || plan.daysRemaining <= 0) {
      return SpendingGuardResult(
        amount: normalizedAmount,
        safeToSpendBefore: plan.safeToSpend,
        safeToSpendAfter: remaining,
        dailyAllowanceAfter: dailyAfter,
        daysRemaining: plan.daysRemaining,
        usagePercent: usagePercent,
        level: SpendingGuardLevel.unavailable,
        title: 'No live allowance available',
        message: plan.daysRemaining <= 0
            ? 'This month is already complete, so there is no live spending allowance to protect.'
            : 'Your current cash flow does not leave a flexible spending allowance yet.',
      );
    }

    if (normalizedAmount > plan.safeToSpend) {
      final overBy = normalizedAmount - plan.safeToSpend;
      return SpendingGuardResult(
        amount: normalizedAmount,
        safeToSpendBefore: plan.safeToSpend,
        safeToSpendAfter: 0,
        dailyAllowanceAfter: 0,
        daysRemaining: plan.daysRemaining,
        usagePercent: usagePercent,
        level: SpendingGuardLevel.overLimit,
        title: 'Over your safe limit',
        message:
            'This purchase is RM ${overBy.toStringAsFixed(2)} above your current flexible spending allowance.',
      );
    }

    if (usagePercent >= 50 || dailyAfter < plan.dailyAllowance * 0.5) {
      return SpendingGuardResult(
        amount: normalizedAmount,
        safeToSpendBefore: plan.safeToSpend,
        safeToSpendAfter: remaining,
        dailyAllowanceAfter: dailyAfter,
        daysRemaining: plan.daysRemaining,
        usagePercent: usagePercent,
        level: SpendingGuardLevel.caution,
        title: 'Affordable, but a big hit',
        message:
            'You can afford this inside the current limit, but it uses a large share of the money left for flexible spending.',
      );
    }

    return SpendingGuardResult(
      amount: normalizedAmount,
      safeToSpendBefore: plan.safeToSpend,
      safeToSpendAfter: remaining,
      dailyAllowanceAfter: dailyAfter,
      daysRemaining: plan.daysRemaining,
      usagePercent: usagePercent,
      level: SpendingGuardLevel.safe,
      title: 'Looks safe',
      message:
          'This purchase stays inside your current flexible spending allowance and keeps your savings and cash buffer protected.',
    );
  }
}
