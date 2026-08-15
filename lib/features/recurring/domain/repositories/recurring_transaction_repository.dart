import '../entities/recurring_transaction_rule.dart';

abstract interface class RecurringTransactionRepository {
  Future<List<RecurringTransactionRule>> getAll();
  Future<void> replaceAll(List<RecurringTransactionRule> rules);
}
