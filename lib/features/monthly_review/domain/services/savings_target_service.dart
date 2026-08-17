import '../models/monthly_financial_review.dart';
import '../models/savings_target_plan.dart';

class SavingsTargetService {
  const SavingsTargetService._();

  static SavingsTargetPlan build(
    MonthlyFinancialReview review, {
    required double targetSavingsRate,
  }) {
    final normalizedRate = targetSavingsRate.clamp(0.0, 90.0).toDouble();
    final targetSavingsAmount = review.income * normalizedRate / 100;
    final maxMonthlyExpenses = (review.income - targetSavingsAmount)
        .clamp(0.0, double.infinity)
        .toDouble();
    final currentSavingsAmount = (review.income - review.expenses)
        .clamp(0.0, double.infinity)
        .toDouble();
    final requiredReduction = (review.expenses - maxMonthlyExpenses)
        .clamp(0.0, double.infinity)
        .toDouble();
    final extraRoom = (maxMonthlyExpenses - review.expenses)
        .clamp(0.0, double.infinity)
        .toDouble();

    return SavingsTargetPlan(
      targetSavingsRate: normalizedRate,
      currentSavingsRate: review.savingsRate,
      targetSavingsAmount: targetSavingsAmount,
      currentSavingsAmount: currentSavingsAmount,
      maxMonthlyExpenses: maxMonthlyExpenses,
      currentExpenses: review.expenses,
      requiredExpenseReduction: requiredReduction,
      extraRoom: extraRoom,
      summary: _summary(
        income: review.income,
        currentSavingsRate: review.savingsRate,
        targetSavingsRate: normalizedRate,
        requiredReduction: requiredReduction,
        extraRoom: extraRoom,
      ),
    );
  }

  static String _summary({
    required double income,
    required double currentSavingsRate,
    required double targetSavingsRate,
    required double requiredReduction,
    required double extraRoom,
  }) {
    if (income <= 0) {
      return 'Add income for this month before setting a savings-rate target. A percentage target needs positive income to calculate a realistic spending ceiling.';
    }

    if (requiredReduction > 0) {
      return 'Your current spending is above the ceiling for this target. Reduce expenses by the amount shown below, or lower the target until it matches your priorities.';
    }

    if (currentSavingsRate >= targetSavingsRate && extraRoom > 0) {
      return 'You are already ahead of this savings target. The extra room is how much additional spending you could absorb and still finish at the selected rate.';
    }

    return 'Your current month is aligned with this target. Keep total expenses at or below the spending ceiling to protect the selected savings rate.';
  }
}
