import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/transaction_entry.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_record.dart';

class LocalTransactionRepository implements TransactionRepository {
  LocalTransactionRepository({
    SharedPreferencesAsync? preferences,
    List<TransactionEntry> seed = const [],
  })  : _preferences = preferences ?? SharedPreferencesAsync(),
        _seed = List.unmodifiable(seed);

  static const _storageKey = 'moneytracker.transactions.v1';

  final SharedPreferencesAsync _preferences;
  final List<TransactionEntry> _seed;

  @override
  Future<List<TransactionEntry>> getAll() async {
    final storedValue = await _preferences.getString(_storageKey);

    if (storedValue == null) {
      if (_seed.isNotEmpty) await _write(_seed);
      return _sort(_seed);
    }

    try {
      final decoded = jsonDecode(storedValue) as List<dynamic>;
      final transactions = decoded
          .map((item) =>
              TransactionRecord.fromJson(item as Map<String, dynamic>)
                  .toEntity())
          .toList();
      return _sort(transactions);
    } on FormatException {
      throw const TransactionStorageException(
          'Stored transaction data is invalid.');
    } on TypeError {
      throw const TransactionStorageException(
          'Stored transaction format is unsupported.');
    }
  }

  @override
  Future<void> create(TransactionEntry transaction) async {
    final transactions = await getAll();
    await _write([...transactions, transaction]);
  }

  @override
  Future<void> update(TransactionEntry transaction) async {
    final transactions = await getAll();
    final index = transactions.indexWhere((item) => item.id == transaction.id);
    if (index == -1) {
      throw TransactionStorageException(
          'Transaction not found: ${transaction.id}');
    }
    final updated = List<TransactionEntry>.of(transactions);
    updated[index] = transaction;
    await _write(updated);
  }

  @override
  Future<void> delete(String transactionId) async {
    final transactions = await getAll();
    await _write(
        transactions.where((item) => item.id != transactionId).toList());
  }

  @override
  Future<void> replaceAll(List<TransactionEntry> transactions) {
    return _write(transactions);
  }

  Future<void> _write(List<TransactionEntry> transactions) async {
    final records = transactions
        .map(TransactionRecord.fromEntity)
        .map((record) => record.toJson())
        .toList();
    await _preferences.setString(_storageKey, jsonEncode(records));
  }

  List<TransactionEntry> _sort(Iterable<TransactionEntry> transactions) {
    final result = List<TransactionEntry>.of(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(result);
  }
}

class TransactionStorageException implements Exception {
  const TransactionStorageException(this.message);

  final String message;

  @override
  String toString() => 'TransactionStorageException: $message';
}
