enum FinancialActionPriority { high, medium, low }

class FinancialActionItem {
  const FinancialActionItem({
    required this.title,
    required this.description,
    required this.priority,
    this.targetAmount,
  });

  final String title;
  final String description;
  final FinancialActionPriority priority;
  final double? targetAmount;
}

class FinancialActionPlan {
  const FinancialActionPlan({
    required this.month,
    required this.score,
    required this.headline,
    required this.summary,
    required this.actions,
    required this.recommendedBuffer,
    required this.recommendedSavings,
  });

  final DateTime month;
  final int score;
  final String headline;
  final String summary;
  final List<FinancialActionItem> actions;
  final double recommendedBuffer;
  final double recommendedSavings;
}
