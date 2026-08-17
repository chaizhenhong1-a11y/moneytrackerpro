enum DebtType { creditCard, personalLoan, carLoan, mortgage, other }

class Debt {
  const Debt({
    required this.id,
    required this.name,
    required this.type,
    required this.originalAmount,
    required this.currentBalance,
    required this.interestRate,
    required this.dueDate,
  });

  final String id;
  final String name;
  final DebtType type;
  final double originalAmount;
  final double currentBalance;
  final double interestRate;
  final DateTime dueDate;

  double get paidAmount =>
      (originalAmount - currentBalance).clamp(0.0, originalAmount).toDouble();
  double get progress => originalAmount <= 0
      ? 0
      : (paidAmount / originalAmount).clamp(0.0, 1.0).toDouble();
  bool get isPaidOff => currentBalance <= 0.005;

  Debt copyWith({
    String? id,
    String? name,
    DebtType? type,
    double? originalAmount,
    double? currentBalance,
    double? interestRate,
    DateTime? dueDate,
  }) {
    return Debt(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      originalAmount: originalAmount ?? this.originalAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      interestRate: interestRate ?? this.interestRate,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
