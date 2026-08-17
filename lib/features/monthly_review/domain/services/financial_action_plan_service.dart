import '../models/financial_action_plan.dart';
import '../models/monthly_financial_review.dart';

abstract final class FinancialActionPlanService {
  static FinancialActionPlan build(MonthlyFinancialReview review) {
    final actions = <FinancialActionItem>[];
    final positiveCashFlow = review.netCashFlow > 0;
    final recommendedSavings =
        positiveCashFlow ? review.netCashFlow * 0.60 : 0.0;
    final recommendedBuffer =
        positiveCashFlow ? review.netCashFlow * 0.20 : 0.0;

    if (review.income == 0 && review.expenses == 0) {
      actions.add(
        const FinancialActionItem(
          title: 'Log your first transactions',
          description:
              'Add income and expenses for this month so the action plan can become specific to your spending.',
          priority: FinancialActionPriority.high,
        ),
      );
    } else {
      if (review.savingsRate < 10) {
        actions.add(
          FinancialActionItem(
            title: 'Protect your cash flow first',
            description: review.netCashFlow < 0
                ? 'Expenses are above income. Start by reducing optional spending before increasing savings targets.'
                : 'Your savings margin is thin. Keep more of the next income you receive before adding optional spending.',
            priority: FinancialActionPriority.high,
            targetAmount: positiveCashFlow ? recommendedSavings : null,
          ),
        );
      } else if (review.savingsRate < 20) {
        actions.add(
          FinancialActionItem(
            title: 'Push savings above 20%',
            description:
                'You already have positive momentum. Move part of this month’s surplus into savings before the month closes.',
            priority: FinancialActionPriority.medium,
            targetAmount: recommendedSavings,
          ),
        );
      } else {
        actions.add(
          FinancialActionItem(
            title: 'Lock in this month’s surplus',
            description:
                'Your savings rate is healthy. Reserve the surplus intentionally instead of leaving all of it available to spend.',
            priority: FinancialActionPriority.low,
            targetAmount: recommendedSavings,
          ),
        );
      }

      if (review.expenseChange > 0 && review.previousExpenses > 0) {
        actions.add(
          FinancialActionItem(
            title: 'Review rising spending',
            description:
                'Expenses increased versus last month. Check ${review.topCategory ?? 'your largest category'} first and decide what can be reduced next month.',
            priority: FinancialActionPriority.high,
            targetAmount: review.expenseChange,
          ),
        );
      } else if (review.topCategory != null && review.topCategoryAmount > 0) {
        actions.add(
          FinancialActionItem(
            title: 'Set a cap for ${review.topCategory}',
            description:
                'This is your biggest spending category this month. Use its current total as the reference point for a tighter target next month.',
            priority: FinancialActionPriority.medium,
            targetAmount: review.topCategoryAmount * 0.90,
          ),
        );
      }

      if (review.largestExpense != null) {
        actions.add(
          FinancialActionItem(
            title: 'Check your largest purchase',
            description:
                '${review.largestExpense!.title} is your largest expense this month. Confirm whether it was planned, recurring, or avoidable.',
            priority: FinancialActionPriority.medium,
            targetAmount: review.largestExpense!.amount,
          ),
        );
      }

      if (positiveCashFlow) {
        actions.add(
          FinancialActionItem(
            title: 'Keep a flexible cash buffer',
            description:
                'Keep a small portion of the monthly surplus available for unexpected expenses so your savings do not need to be reversed later.',
            priority: FinancialActionPriority.low,
            targetAmount: recommendedBuffer,
          ),
        );
      }
    }

    final score = _score(review);
    return FinancialActionPlan(
      month: review.month,
      score: score,
      headline: _headline(score),
      summary: _summary(review, score),
      actions: actions.take(4).toList(growable: false),
      recommendedBuffer: recommendedBuffer,
      recommendedSavings: recommendedSavings,
    );
  }

  static int _score(MonthlyFinancialReview review) {
    if (review.income == 0 && review.expenses == 0) return 0;

    var score = 50;
    if (review.netCashFlow > 0) score += 20;
    if (review.savingsRate >= 20) {
      score += 15;
    } else if (review.savingsRate >= 10) {
      score += 8;
    } else if (review.savingsRate < 0) {
      score -= 20;
    }

    if (review.expenseChange < 0) score += 10;
    if (review.expenseChange > 0 && review.previousExpenses > 0) score -= 10;
    if (review.savingsRateChange > 0) score += 5;

    return score.clamp(0, 100).toInt();
  }

  static String _headline(int score) {
    if (score >= 85) return 'Excellent monthly position';
    if (score >= 70) return 'Strong, with room to optimize';
    if (score >= 50) return 'Stable, but watch the details';
    if (score > 0) return 'Cash flow needs attention';
    return 'Build your first action plan';
  }

  static String _summary(MonthlyFinancialReview review, int score) {
    if (score == 0) {
      return 'Once you add transactions, MoneyTracker Pro will turn your monthly review into a prioritized action plan.';
    }
    if (review.netCashFlow < 0) {
      return 'The first goal is to bring monthly cash flow back above zero. Focus on the highest-impact expense changes before setting aggressive savings targets.';
    }
    if (review.savingsRate >= 20) {
      return 'You are keeping a healthy share of income. The next step is to allocate the surplus deliberately and keep large categories controlled.';
    }
    return 'Your cash flow is positive, but the savings margin can be stronger. A few targeted changes can improve next month without overcorrecting.';
  }
}
