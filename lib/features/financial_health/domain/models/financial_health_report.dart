class FinancialHealthFactor {
  const FinancialHealthFactor({
    required this.title,
    required this.score,
    required this.maxScore,
    required this.summary,
    required this.recommendation,
  });

  final String title;
  final int score;
  final int maxScore;
  final String summary;
  final String recommendation;

  double get progress => maxScore == 0 ? 0 : score / maxScore;
}

class FinancialHealthReport {
  const FinancialHealthReport({
    required this.score,
    required this.factors,
  });

  final int score;
  final List<FinancialHealthFactor> factors;

  String get label {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Healthy';
    if (score >= 55) return 'Fair';
    if (score >= 40) return 'Needs attention';
    return 'At risk';
  }

  String get headline {
    if (score >= 85) return 'Your finances are in strong shape.';
    if (score >= 70) return 'You have a solid financial foundation.';
    if (score >= 55) return 'You are doing okay, with room to improve.';
    if (score >= 40) return 'A few areas need attention this month.';
    return 'Focus on cash flow and essential spending first.';
  }
}
