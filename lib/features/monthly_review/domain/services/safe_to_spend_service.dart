import '../models/monthly_financial_review.dart';
import '../models/safe_to_spend_plan.dart';

abstract final class SafeToSpendService {
  static SafeToSpendPlan build(
    MonthlyFinancialReview review, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final month = DateTime(review.month.year, review.month.month);
    final currentMonth = DateTime(current.year, current.month);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;

    int daysRemaining;
    if (month.isBefore(currentMonth)) {
      daysRemaining = 0;
    } else if (month.isAfter(currentMonth)) {
      daysRemaining = lastDay;
    } else {
      daysRemaining = (lastDay - current.day + 1).clamp(0, lastDay);
    }

    final availableCash = review.netCashFlow > 0 ? review.netCashFlow : 0.0;
    final savingsReserve = availableCash * 0.60;
    final bufferReserve = availableCash * 0.20;
    final safeToSpend = (availableCash - savingsReserve - bufferReserve)
        .clamp(0, double.infinity)
        .toDouble();
    final dailyAllowance =
        daysRemaining == 0 ? 0.0 : safeToSpend / daysRemaining;
    final weeklyAllowance = dailyAllowance * 7;

    final (status, message) = _status(review, safeToSpend, daysRemaining);

    return SafeToSpendPlan(
      month: month,
      daysRemaining: daysRemaining,
      availableCash: availableCash,
      savingsReserve: savingsReserve,
      bufferReserve: bufferReserve,
      safeToSpend: safeToSpend,
      dailyAllowance: dailyAllowance,
      weeklyAllowance: weeklyAllowance,
      status: status,
      message: message,
    );
  }

  static (String, String) _status(
    MonthlyFinancialReview review,
    double safeToSpend,
    int daysRemaining,
  ) {
    if (review.netCashFlow <= 0) {
      return (
        'Hold spending',
        'There is no positive monthly surplus available yet. Focus on essential spending until cash flow returns above zero.',
      );
    }
    if (daysRemaining == 0) {
      return (
        'Month complete',
        'This month is already complete. Use the result as a reference for the next month instead of a live spending limit.',
      );
    }
    if (safeToSpend <= 0) {
      return (
        'Fully allocated',
        'Your current surplus is fully reserved for savings and your cash buffer.',
      );
    }
    return (
      'On track',
      'This allowance protects 60% of your current surplus for savings and 20% as a flexible buffer.',
    );
  }
}
