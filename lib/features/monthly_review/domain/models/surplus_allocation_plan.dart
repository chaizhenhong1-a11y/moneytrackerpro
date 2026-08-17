enum SurplusAllocationStrategy {
  balanced,
  safetyFirst,
  debtFirst,
  goalsFirst,
}

class SurplusAllocationPlan {
  const SurplusAllocationPlan({
    required this.strategy,
    required this.availableSurplus,
    required this.emergencyFund,
    required this.extraDebtPayment,
    required this.savingsGoals,
    required this.flexibleMoney,
    required this.summary,
  });

  final SurplusAllocationStrategy strategy;
  final double availableSurplus;
  final double emergencyFund;
  final double extraDebtPayment;
  final double savingsGoals;
  final double flexibleMoney;
  final String summary;

  bool get hasSurplus => availableSurplus > 0;
}
