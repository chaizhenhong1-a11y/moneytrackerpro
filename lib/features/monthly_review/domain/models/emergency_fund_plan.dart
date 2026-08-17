class EmergencyFundPlan {
  const EmergencyFundPlan({
    required this.monthlyEssentials,
    required this.coverageMonths,
    required this.targetAmount,
    required this.currentFund,
    required this.gap,
    required this.timelineMonths,
    required this.monthlyContribution,
    required this.coverageProgress,
    required this.currentCoverageMonths,
  });

  final double monthlyEssentials;
  final int coverageMonths;
  final double targetAmount;
  final double currentFund;
  final double gap;
  final int timelineMonths;
  final double monthlyContribution;
  final double coverageProgress;
  final double currentCoverageMonths;

  bool get isFullyFunded => gap <= 0;
}
