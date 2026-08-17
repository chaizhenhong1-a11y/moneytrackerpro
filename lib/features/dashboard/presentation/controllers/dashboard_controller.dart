import 'package:flutter/material.dart';

import '../../../transactions/domain/entities/transaction_category.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';

enum DashboardStatus { initial, loading, ready, failure }

class DashboardController extends ChangeNotifier {
  DashboardController(this._repository);

  final TransactionRepository _repository;
  List<TransactionEntry> _transactions = const [];
  DashboardStatus _status = DashboardStatus.initial;
  String? _errorMessage;

  List<TransactionEntry> get transactions => _transactions;
  DashboardStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == DashboardStatus.loading;
  bool get hasError => _status == DashboardStatus.failure;

  double get income => _transactions
      .where((item) => item.countsAsIncome)
      .fold(0, (total, item) => total + item.amount);

  double get expense => _transactions
      .where((item) => item.countsAsExpense)
      .fold(0, (total, item) => total + item.amount);

  double get balance =>
      _transactions.fold(0, (total, item) => total + item.signedAmount);

  Future<void> load() async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _repository.getAll();
      _status = DashboardStatus.ready;
    } catch (_) {
      _status = DashboardStatus.failure;
      _errorMessage = 'Unable to load your transactions.';
    }
    notifyListeners();
  }

  Future<bool> renameCategoryReferences({
    required String oldName,
    required TransactionCategory category,
  }) async {
    final next = _transactions.map((item) {
      if (item.category != oldName ||
          item.isTransfer ||
          item.isReconciliation) {
        return item;
      }
      return TransactionEntry(
        id: item.id,
        title: item.title,
        category: category.name,
        amount: item.amount,
        date: item.date,
        type: item.type,
        icon: category.icon,
        color: category.color,
        accountId: item.accountId,
      );
    }).toList();
    try {
      await _repository.replaceAll(next);
      _transactions = await _repository.getAll();
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to update existing category references.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required TransactionCategory category,
    required DateTime date,
    String accountId = 'account_cash',
  }) async {
    try {
      await _repository.create(
        TransactionEntry(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title.trim(),
          category: category.name,
          amount: amount,
          date: date,
          type: type,
          icon: category.icon,
          color: category.color,
          accountId: accountId,
        ),
      );
      _transactions = await _repository.getAll();
      _status = DashboardStatus.ready;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to save the transaction.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> reconcileAccount({
    required String accountId,
    required String accountName,
    required double bookBalance,
    required double actualBalance,
    required DateTime date,
    String note = '',
  }) async {
    if (!bookBalance.isFinite || !actualBalance.isFinite) {
      _errorMessage = 'Enter a valid balance before reconciling.';
      notifyListeners();
      return false;
    }

    final difference = actualBalance - bookBalance;
    if (difference.abs() < .005) {
      _errorMessage = '$accountName is already reconciled.';
      notifyListeners();
      return false;
    }

    final detail = note.trim();
    final adjustment = TransactionEntry(
      id: 'reconcile_${DateTime.now().microsecondsSinceEpoch}',
      title: detail.isEmpty ? 'Balance reconciliation' : detail,
      category: 'Reconciliation',
      amount: difference.abs(),
      date: date,
      type: difference >= 0 ? TransactionType.income : TransactionType.expense,
      icon: Icons.fact_check_outlined,
      color: const Color(0xFF7057E8),
      accountId: accountId,
    );

    try {
      await _repository.create(adjustment);
      _transactions = await _repository.getAll();
      _errorMessage = null;
      _status = DashboardStatus.ready;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to save the reconciliation adjustment.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> transferFunds({
    required String fromAccountId,
    required String fromAccountName,
    required String toAccountId,
    required String toAccountName,
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    if (fromAccountId == toAccountId || amount <= 0) {
      _errorMessage = 'Choose two different accounts and enter a valid amount.';
      notifyListeners();
      return false;
    }

    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final detail = note.trim();
    final transferOut = TransactionEntry(
      id: 'transfer_${stamp}_out',
      title: detail.isEmpty ? 'Transfer to $toAccountName' : detail,
      category: 'Transfer',
      amount: amount,
      date: date,
      type: TransactionType.expense,
      icon: Icons.swap_horiz_rounded,
      color: const Color(0xFF7057E8),
      accountId: fromAccountId,
    );
    final transferIn = TransactionEntry(
      id: 'transfer_${stamp}_in',
      title: detail.isEmpty ? 'Transfer from $fromAccountName' : detail,
      category: 'Transfer',
      amount: amount,
      date: date,
      type: TransactionType.income,
      icon: Icons.swap_horiz_rounded,
      color: const Color(0xFF7057E8),
      accountId: toAccountId,
    );

    try {
      await _repository.replaceAll([..._transactions, transferOut, transferIn]);
      _transactions = await _repository.getAll();
      _errorMessage = null;
      _status = DashboardStatus.ready;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to save the transfer.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransfer({
    required TransactionEntry transaction,
    required String fromAccountId,
    required String fromAccountName,
    required String toAccountId,
    required String toAccountName,
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    final groupId = transaction.transferGroupId;
    if (groupId == null || fromAccountId == toAccountId || amount <= 0) {
      _errorMessage = 'Choose two different accounts and enter a valid amount.';
      notifyListeners();
      return false;
    }

    final pair = transferPairFor(transaction);
    final hasIncome = pair.any((item) => item.type == TransactionType.income);
    final hasExpense = pair.any((item) => item.type == TransactionType.expense);
    if (pair.length != 2 || !hasIncome || !hasExpense) {
      _errorMessage =
          'This transfer pair is incomplete, so it was not changed.';
      notifyListeners();
      return false;
    }

    final detail = note.trim();
    final outgoing =
        pair.firstWhere((item) => item.type == TransactionType.expense);
    final incoming =
        pair.firstWhere((item) => item.type == TransactionType.income);
    final updatedOut = TransactionEntry(
      id: outgoing.id,
      title: detail.isEmpty ? 'Transfer to $toAccountName' : detail,
      category: 'Transfer',
      amount: amount,
      date: date,
      type: TransactionType.expense,
      icon: Icons.swap_horiz_rounded,
      color: const Color(0xFF7057E8),
      accountId: fromAccountId,
    );
    final updatedIn = TransactionEntry(
      id: incoming.id,
      title: detail.isEmpty ? 'Transfer from $fromAccountName' : detail,
      category: 'Transfer',
      amount: amount,
      date: date,
      type: TransactionType.income,
      icon: Icons.swap_horiz_rounded,
      color: const Color(0xFF7057E8),
      accountId: toAccountId,
    );

    try {
      await _repository.replaceAll([
        ..._transactions.where((item) => item.transferGroupId != groupId),
        updatedOut,
        updatedIn,
      ]);
      _transactions = await _repository.getAll();
      _errorMessage = null;
      _status = DashboardStatus.ready;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to update the transfer.';
      notifyListeners();
      return false;
    }
  }

  List<TransactionEntry> transferPairFor(TransactionEntry transaction) {
    final groupId = transaction.transferGroupId;
    if (groupId == null) return const [];
    return _transactions
        .where((item) => item.transferGroupId == groupId)
        .toList(growable: false);
  }

  Future<List<TransactionEntry>?> cancelTransfer(
      TransactionEntry transaction) async {
    final groupId = transaction.transferGroupId;
    if (groupId == null) {
      _errorMessage = 'This transfer cannot be matched to its linked entry.';
      notifyListeners();
      return null;
    }

    final pair = transferPairFor(transaction);
    final hasIncome = pair.any((item) => item.type == TransactionType.income);
    final hasExpense = pair.any((item) => item.type == TransactionType.expense);
    if (pair.length != 2 || !hasIncome || !hasExpense) {
      _errorMessage =
          'This transfer pair is incomplete, so it was not changed.';
      notifyListeners();
      return null;
    }

    try {
      await _repository.replaceAll(
        _transactions.where((item) => item.transferGroupId != groupId).toList(),
      );
      _transactions = await _repository.getAll();
      _errorMessage = null;
      _status = DashboardStatus.ready;
      notifyListeners();
      return pair;
    } catch (_) {
      _errorMessage = 'Unable to cancel the transfer.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> restoreTransactions(List<TransactionEntry> transactions) async {
    if (transactions.isEmpty) return false;
    try {
      final restoredIds = transactions.map((item) => item.id).toSet();
      await _repository.replaceAll([
        ..._transactions.where((item) => !restoredIds.contains(item.id)),
        ...transactions,
      ]);
      _transactions = await _repository.getAll();
      _errorMessage = null;
      _status = DashboardStatus.ready;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to restore the transfer.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction({
    required String id,
    required String title,
    required double amount,
    required TransactionType type,
    required TransactionCategory category,
    required DateTime date,
    String accountId = 'account_cash',
  }) async {
    try {
      await _repository.update(
        TransactionEntry(
          id: id,
          title: title.trim(),
          category: category.name,
          amount: amount,
          date: date,
          type: type,
          icon: category.icon,
          color: category.color,
          accountId: accountId,
        ),
      );
      _transactions = await _repository.getAll();
      _errorMessage = null;
      _status = DashboardStatus.ready;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to update the transaction.';
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteTransaction(String id) async {
    final previous = _transactions;
    _transactions =
        _transactions.where((item) => item.id != id).toList(growable: false);
    notifyListeners();
    try {
      await _repository.delete(id);
      _transactions = await _repository.getAll();
      _errorMessage = null;
    } catch (_) {
      _transactions = previous;
      _errorMessage = 'Unable to delete the transaction.';
    }
    notifyListeners();
  }

  Future<bool> restoreTransaction(TransactionEntry transaction) async {
    try {
      await _repository.create(transaction);
      _transactions = await _repository.getAll();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to restore the transaction.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> replaceAllTransactions(
      List<TransactionEntry> transactions) async {
    try {
      await _repository.replaceAll(transactions);
      _transactions = await _repository.getAll();
      _errorMessage = null;
      _status = DashboardStatus.ready;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to replace transaction data.';
      notifyListeners();
      return false;
    }
  }
}
