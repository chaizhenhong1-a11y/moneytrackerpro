import '../models/monthly_financial_review.dart';
import '../models/spending_pace_forecast.dart';

abstract final class SpendingPaceForecastService {
  static SpendingPaceForecast build(
    MonthlyFinancialReview review, {
    DateTime? now,
  }) {
    final effectiveNow = now ?? DateTime.now();
    final month = DateTime(review.month.year, review.month.month);
    final currentMonth = DateTime(effectiveNow.year, effectiveNow.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final int daysElapsed;
    if (month.isBefore(currentMonth)) {
      daysElapsed = daysInMonth;
    } else if (month.isAfter(currentMonth)) {
      daysElapsed = 0;
    } else {
      daysElapsed = effectiveNow.day.clamp(1, daysInMonth);
    }

    final daysRemaining = (daysInMonth - daysElapsed).clamp(0, daysInMonth);
    final projectedExpenses =
        daysElapsed == 0 ? 0.0 : review.expenses / daysElapsed * daysInMonth;
    final projectedNetCashFlow = review.income - projectedExpenses;
    final paceVsLastMonthPercent = _percentChange(
      review.previousExpenses,
      projectedExpenses,
    );

    final status = _status(
      projectedNetCashFlow: projectedNetCashFlow,
      paceVsLastMonthPercent: paceVsLastMonthPercent,
    );

    return SpendingPaceForecast(
      daysElapsed: daysElapsed,
      daysInMonth: daysInMonth,
      daysRemaining: daysRemaining,
      currentExpenses: review.expenses,
      projectedExpenses: projectedExpenses,
      projectedNetCashFlow: projectedNetCashFlow,
      previousExpenses: review.previousExpenses,
      paceVsLastMonthPercent: paceVsLastMonthPercent,
      status: status,
      message: _message(status, daysRemaining),
    );
  }

  static SpendingPaceStatus _status({
    required double projectedNetCashFlow,
    required double? paceVsLastMonthPercent,
  }) {
    if (projectedNetCashFlow < 0 ||
        (paceVsLastMonthPercent != null && paceVsLastMonthPercent > 15)) {
      return SpendingPaceStatus.watch;
    }
    if (paceVsLastMonthPercent != null && paceVsLastMonthPercent < -5) {
      return SpendingPaceStatus.ahead;
    }
    return SpendingPaceStatus.steady;
  }

  static String _message(SpendingPaceStatus status, int daysRemaining) {
    return switch (status) {
      SpendingPaceStatus.ahead =>
        'Your current spending pace is lower than last month. Keep the same rhythm for the remaining $daysRemaining days.',
      SpendingPaceStatus.steady =>
        'Your spending pace is broadly stable. Small daily choices can still improve the month-end result.',
      SpendingPaceStatus.watch =>
        'Your current pace may put pressure on month-end cash flow. Consider slowing flexible spending for the remaining $daysRemaining days.',
    };
  }

  static double? _percentChange(double previous, double current) {
    if (previous == 0) return current == 0 ? 0 : null;
    return ((current - previous) / previous) * 100;
  }
}
