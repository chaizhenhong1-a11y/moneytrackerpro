class AppSettings {
  const AppSettings({
    required this.displayName,
    required this.monthlyBudget,
    required this.budgetAlertsEnabled,
  });

  const AppSettings.defaults()
      : displayName = 'Stanley',
        monthlyBudget = 2500,
        budgetAlertsEnabled = true;

  final String displayName;
  final double monthlyBudget;
  final bool budgetAlertsEnabled;

  AppSettings copyWith({
    String? displayName,
    double? monthlyBudget,
    bool? budgetAlertsEnabled,
  }) {
    return AppSettings(
      displayName: displayName ?? this.displayName,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
    );
  }
}
