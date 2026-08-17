class SafeToSpendPlan {
  const SafeToSpendPlan({
    required this.month,
    required this.daysRemaining,
    required this.availableCash,
    required this.savingsReserve,
    required this.bufferReserve,
    required this.safeToSpend,
    required this.dailyAllowance,
    required this.weeklyAllowance,
    required this.status,
    required this.message,
  });

  final DateTime month;
  final int daysRemaining;
  final double availableCash;
  final double savingsReserve;
  final double bufferReserve;
  final double safeToSpend;
  final double dailyAllowance;
  final double weeklyAllowance;
  final String status;
  final String message;
}
