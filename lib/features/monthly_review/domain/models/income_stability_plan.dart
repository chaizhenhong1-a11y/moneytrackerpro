enum IncomeStabilityStatus { noHistory, stable, watch, volatile }

class IncomeStabilityPlan {
  const IncomeStabilityPlan({
    required this.currentIncome,
    required this.previousIncome,
    required this.currentExpenses,
    required this.conservativeIncomeBaseline,
    required this.recommendedIncomeReserve,
    required this.safeSpendingBaseline,
    required this.stabilityScore,
    required this.status,
    required this.reserveRate,
    required this.summary,
    this.incomeChangePercent,
  });

  final double currentIncome;
  final double previousIncome;
  final double currentExpenses;
  final double conservativeIncomeBaseline;
  final double recommendedIncomeReserve;
  final double safeSpendingBaseline;
  final double stabilityScore;
  final IncomeStabilityStatus status;
  final double reserveRate;
  final String summary;
  final double? incomeChangePercent;

  double get spendingHeadroom => safeSpendingBaseline - currentExpenses;
  bool get insideSafeBaseline => currentExpenses <= safeSpendingBaseline;

  String get statusLabel => switch (status) {
        IncomeStabilityStatus.noHistory => 'Building history',
        IncomeStabilityStatus.stable => 'Stable',
        IncomeStabilityStatus.watch => 'Watch',
        IncomeStabilityStatus.volatile => 'Volatile',
      };
}
