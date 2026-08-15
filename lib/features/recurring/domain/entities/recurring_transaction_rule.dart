import '../../../transactions/domain/entities/transaction_entry.dart';

enum RecurringFrequency { weekly, monthly, yearly }

class RecurringTransactionRule {
  const RecurringTransactionRule({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.accountId,
    required this.frequency,
    required this.nextDueDate,
    this.isPaused = false,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String accountId;
  final RecurringFrequency frequency;
  final DateTime nextDueDate;
  final bool isPaused;

  RecurringTransactionRule copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    String? accountId,
    RecurringFrequency? frequency,
    DateTime? nextDueDate,
    bool? isPaused,
  }) {
    return RecurringTransactionRule(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
