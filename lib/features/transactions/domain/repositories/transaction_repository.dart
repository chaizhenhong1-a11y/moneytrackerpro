import '../entities/transaction_entry.dart';

abstract interface class TransactionRepository {
  Future<List<TransactionEntry>> getAll();
  Future<void> create(TransactionEntry transaction);
  Future<void> update(TransactionEntry transaction);
  Future<void> delete(String transactionId);
  Future<void> replaceAll(List<TransactionEntry> transactions);
}
