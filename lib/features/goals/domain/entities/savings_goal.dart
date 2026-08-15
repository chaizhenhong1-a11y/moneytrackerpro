class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.accountId,
    required this.deadline,
  });

  final String id;
  final String name;
  final double targetAmount;
  final String accountId;
  final DateTime deadline;

  SavingsGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    String? accountId,
    DateTime? deadline,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      accountId: accountId ?? this.accountId,
      deadline: deadline ?? this.deadline,
    );
  }
}
