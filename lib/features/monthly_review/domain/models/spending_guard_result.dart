enum SpendingGuardLevel { safe, caution, overLimit, unavailable }

class SpendingGuardResult {
  const SpendingGuardResult({
    required this.amount,
    required this.safeToSpendBefore,
    required this.safeToSpendAfter,
    required this.dailyAllowanceAfter,
    required this.daysRemaining,
    required this.usagePercent,
    required this.level,
    required this.title,
    required this.message,
  });

  final double amount;
  final double safeToSpendBefore;
  final double safeToSpendAfter;
  final double dailyAllowanceAfter;
  final int daysRemaining;
  final double usagePercent;
  final SpendingGuardLevel level;
  final String title;
  final String message;

  bool get canAfford =>
      level == SpendingGuardLevel.safe || level == SpendingGuardLevel.caution;
}
