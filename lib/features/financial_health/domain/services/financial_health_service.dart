import '../../../cash_flow/domain/services/cash_flow_forecast_service.dart';
import '../../../category_budgets/domain/entities/category_budget.dart';
import '../../../goals/domain/entities/savings_goal.dart';
import '../../../recurring/domain/entities/recurring_transaction_rule.dart';
import '../../../transactions/domain/entities/transaction_category.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../models/financial_health_report.dart';

abstract final class FinancialHealthService {
  static FinancialHealthReport evaluate({
    required List<TransactionEntry> transactions,
    required List<TransactionCategory> categories,
    required List<CategoryBudget> categoryBudgets,
    required List<SavingsGoal> savingsGoals,
    required List<RecurringTransactionRule> recurringRules,
    required Set<String> activeAccountIds,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final currentMonth = transactions.where((item) =>
        item.date.year == today.year &&
        item.date.month == today.month &&
        !item.isTransfer &&
        !item.isReconciliation);
    final income = currentMonth
        .where((item) => item.countsAsIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = currentMonth
        .where((item) => item.countsAsExpense)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final balance = transactions.fold<double>(0, (sum, item) => sum + item.signedAmount);

    final projection = CashFlowForecastService.project(
      openingBalance: balance,
      rules: recurringRules,
      activeAccountIds: activeAccountIds,
      from: today,
    );

    final factors = <FinancialHealthFactor>[
      _cashFlowFactor(projection.hasShortfall, projection.closingBalance, projection.openingBalance),
      _budgetFactor(
        transactions: transactions,
        categories: categories,
        budgets: categoryBudgets,
        now: today,
      ),
      _goalsFactor(
        transactions: transactions,
        goals: savingsGoals,
      ),
      _savingsRateFactor(income: income, expense: expense),
    ];

    final score = factors.fold<int>(0, (sum, factor) => sum + factor.score).clamp(0, 100).toInt();
    return FinancialHealthReport(score: score, factors: List.unmodifiable(factors));
  }

  static FinancialHealthFactor _cashFlowFactor(bool hasShortfall, double closing, double opening) {
    if (hasShortfall) {
      return const FinancialHealthFactor(
        title: 'Cash flow outlook',
        score: 4,
        maxScore: 30,
        summary: 'Your 30-day forecast falls below zero.',
        recommendation: 'Review upcoming recurring expenses and keep a larger cash buffer.',
      );
    }
    if (closing >= opening) {
      return const FinancialHealthFactor(
        title: 'Cash flow outlook',
        score: 30,
        maxScore: 30,
        summary: 'Your projected 30-day balance stays positive and grows.',
        recommendation: 'Keep the same buffer and review the forecast after major expenses.',
      );
    }
    return const FinancialHealthFactor(
      title: 'Cash flow outlook',
      score: 22,
      maxScore: 30,
      summary: 'Your balance stays positive, but is projected to decline.',
      recommendation: 'Reduce flexible spending or increase your buffer before scheduled bills.',
    );
  }

  static FinancialHealthFactor _budgetFactor({
    required List<TransactionEntry> transactions,
    required List<TransactionCategory> categories,
    required List<CategoryBudget> budgets,
    required DateTime now,
  }) {
    if (budgets.isEmpty) {
      return const FinancialHealthFactor(
        title: 'Budget discipline',
        score: 15,
        maxScore: 25,
        summary: 'No category budgets are being tracked yet.',
        recommendation: 'Set limits for your largest expense categories to improve this score.',
      );
    }

    var ratios = 0.0;
    var tracked = 0;
    var over = 0;
    for (final budget in budgets) {
      if (budget.monthlyLimit <= 0) continue;
      final matches = categories.where((category) => category.id == budget.categoryId);
      if (matches.isEmpty) continue;
      final category = matches.first;
      final spent = transactions.where((item) =>
          item.countsAsExpense &&
          item.category == category.name &&
          item.date.year == now.year &&
          item.date.month == now.month).fold<double>(0, (sum, item) => sum + item.amount);
      final ratio = spent / budget.monthlyLimit;
      ratios += ratio.clamp(0, 1.5);
      tracked++;
      if (ratio > 1) over++;
    }

    if (tracked == 0) {
      return const FinancialHealthFactor(
        title: 'Budget discipline',
        score: 15,
        maxScore: 25,
        summary: 'Your saved budgets do not match active categories.',
        recommendation: 'Review category budgets and reconnect any missing categories.',
      );
    }

    final average = ratios / tracked;
    final score = average <= .7
        ? 25
        : average <= .85
            ? 22
            : average <= 1
                ? 18
                : average <= 1.15
                    ? 10
                    : 4;
    return FinancialHealthFactor(
      title: 'Budget discipline',
      score: score,
      maxScore: 25,
      summary: over == 0
          ? '$tracked category budgets are currently within their limits.'
          : '$over of $tracked category budgets are over their monthly limit.',
      recommendation: over == 0
          ? 'Keep monitoring categories that are above 80% of their limit.'
          : 'Review the categories over budget and trim non-essential spending.',
    );
  }

  static FinancialHealthFactor _goalsFactor({
    required List<TransactionEntry> transactions,
    required List<SavingsGoal> goals,
  }) {
    if (goals.isEmpty) {
      return const FinancialHealthFactor(
        title: 'Savings goals',
        score: 10,
        maxScore: 20,
        summary: 'You have not created a savings goal yet.',
        recommendation: 'Create one realistic target to make your saving progress measurable.',
      );
    }

    var progress = 0.0;
    var completed = 0;
    for (final goal in goals) {
      final accountBalance = transactions
          .where((item) => item.accountId == goal.accountId)
          .fold<double>(0, (sum, item) => sum + item.signedAmount);
      final ratio = goal.targetAmount <= 0 ? 0.0 : (accountBalance / goal.targetAmount).clamp(0.0, 1.0);
      progress += ratio;
      if (ratio >= 1) completed++;
    }
    final average = progress / goals.length;
    final score = (8 + average * 12).round().clamp(0, 20);
    return FinancialHealthFactor(
      title: 'Savings goals',
      score: score,
      maxScore: 20,
      summary: '$completed of ${goals.length} goals reached · ${(average * 100).round()}% average progress.',
      recommendation: average >= .75
          ? 'You are close to your targets. Keep contributions consistent.'
          : 'Increase regular contributions to the goals with the nearest deadlines.',
    );
  }

  static FinancialHealthFactor _savingsRateFactor({required double income, required double expense}) {
    if (income <= 0) {
      return const FinancialHealthFactor(
        title: 'Monthly savings rate',
        score: 8,
        maxScore: 25,
        summary: 'No regular income has been recorded this month yet.',
        recommendation: 'Record income so the app can measure your true monthly savings rate.',
      );
    }
    final rate = (income - expense) / income;
    final score = rate >= .2
        ? 25
        : rate >= .1
            ? 21
            : rate >= 0
                ? 15
                : rate >= -.15
                    ? 7
                    : 0;
    return FinancialHealthFactor(
      title: 'Monthly savings rate',
      score: score,
      maxScore: 25,
      summary: 'You are keeping ${(rate * 100).round()}% of recorded income this month.',
      recommendation: rate >= .2
          ? 'A 20%+ savings rate is a strong base. Keep it consistent.'
          : rate >= 0
              ? 'Aim to move toward a 20% savings rate by reducing flexible expenses.'
              : 'Expenses currently exceed income. Prioritize essential costs and restore positive cash flow.',
    );
  }
}
