class SavingsTargetPlan {
  const SavingsTargetPlan({
    required this.targetSavingsRate,
    required this.currentSavingsRate,
    required this.targetSavingsAmount,
    required this.currentSavingsAmount,
    required this.maxMonthlyExpenses,
    required this.currentExpenses,
    required this.requiredExpenseReduction,
    required this.extraRoom,
    required this.summary,
  });

  final double targetSavingsRate;
  final double currentSavingsRate;
  final double targetSavingsAmount;
  final double currentSavingsAmount;
  final double maxMonthlyExpenses;
  final double currentExpenses;
  final double requiredExpenseReduction;
  final double extraRoom;
  final String summary;

  bool get targetMet => requiredExpenseReduction <= 0;
}
