import '../../domain/entities/transaction_entry.dart';
import '../../domain/repositories/transaction_repository.dart';

class InMemoryTransactionRepository implements TransactionRepository {
  InMemoryTransactionRepository({List<TransactionEntry> seed = const []})
      : _transactions = List.of(seed);

  final List<TransactionEntry> _transactions;

  @override
  Future<List<TransactionEntry>> getAll() async {
    final result = List<TransactionEntry>.of(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(result);
  }

  @override
  Future<void> create(TransactionEntry transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<void> update(TransactionEntry transaction) async {
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    if (index == -1) throw StateError('Transaction not found: ${transaction.id}');
    _transactions[index] = transaction;
  }

  @override
  Future<void> delete(String transactionId) async {
    _transactions.removeWhere((item) => item.id == transactionId);
  }

  @override
  Future<void> replaceAll(List<TransactionEntry> transactions) async {
    _transactions
      ..clear()
      ..addAll(transactions);
  }
}
