import 'package:flutter/material.dart';

import '../../../transactions/domain/entities/transaction_category.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../domain/entities/recurring_transaction_rule.dart';
import '../../domain/repositories/recurring_transaction_repository.dart';

class RecurringTransactionController extends ChangeNotifier {
  RecurringTransactionController(this._repository, this._transactionRepository, this._categoryController);

  final RecurringTransactionRepository _repository;
  final TransactionRepository _transactionRepository;
  final CategoryController _categoryController;

  List<RecurringTransactionRule> _rules = const [];
  bool _isLoading = false;
  String? _errorMessage;
  int _generatedCount = 0;

  List<RecurringTransactionRule> get rules => _rules;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get generatedCount => _generatedCount;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _rules = await _repository.getAll();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Unable to load recurring transactions.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addRule({
    required String title,
    required double amount,
    required TransactionType type,
    required TransactionCategory category,
    required String accountId,
    required RecurringFrequency frequency,
    required DateTime firstDueDate,
  }) async {
    final rule = RecurringTransactionRule(
      id: 'recurring_${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(),
      amount: amount,
      type: type,
      category: category.name,
      accountId: accountId,
      frequency: frequency,
      nextDueDate: _dateOnly(firstDueDate),
    );
    return _save([..._rules, rule]);
  }

  Future<bool> updateRule({
    required String id,
    required String title,
    required double amount,
    required TransactionType type,
    required TransactionCategory category,
    required String accountId,
    required RecurringFrequency frequency,
    required DateTime nextDueDate,
  }) {
    return _save(
      _rules
          .map(
            (item) => item.id == id
                ? item.copyWith(
                    title: title.trim(),
                    amount: amount,
                    type: type,
                    category: category.name,
                    accountId: accountId,
                    frequency: frequency,
                    nextDueDate: _dateOnly(nextDueDate),
                  )
                : item,
          )
          .toList(),
    );
  }


  Future<bool> renameCategoryReferences({
    required String oldName,
    required String newName,
  }) {
    return _save(
      _rules
          .map((rule) => rule.category == oldName ? rule.copyWith(category: newName) : rule)
          .toList(),
    );
  }

  Future<bool> togglePaused(RecurringTransactionRule rule) {
    return _save(
      _rules
          .map((item) => item.id == rule.id ? item.copyWith(isPaused: !item.isPaused) : item)
          .toList(),
    );
  }

  Future<bool> deleteRule(String id) {
    return _save(_rules.where((item) => item.id != id).toList());
  }

  Future<bool> replaceAll(List<RecurringTransactionRule> rules) {
    return _save(List.of(rules));
  }

  Future<int> processDueTransactions({required Set<String> activeAccountIds}) async {
    if (_rules.isEmpty) return 0;

    try {
      final today = _dateOnly(DateTime.now());
      final transactions = await _transactionRepository.getAll();
      final existingIds = transactions.map((item) => item.id).toSet();
      final generated = <TransactionEntry>[];
      final updatedRules = <RecurringTransactionRule>[];

      for (final rule in _rules) {
        if (rule.isPaused || !activeAccountIds.contains(rule.accountId)) {
          updatedRules.add(rule);
          continue;
        }

        var due = _dateOnly(rule.nextDueDate);
        var safety = 0;
        while (!due.isAfter(today) && safety < 120) {
          final id = _occurrenceId(rule.id, due);
          if (!existingIds.contains(id)) {
            final category = _categoryController.resolve(rule.category, rule.type);
            generated.add(
              TransactionEntry(
                id: id,
                title: rule.title,
                category: category.name,
                amount: rule.amount,
                date: due,
                type: rule.type,
                icon: category.icon,
                color: category.color,
                accountId: rule.accountId,
              ),
            );
            existingIds.add(id);
          }
          due = _nextDate(due, rule.frequency);
          safety++;
        }
        updatedRules.add(rule.copyWith(nextDueDate: due));
      }

      if (generated.isNotEmpty) {
        await _transactionRepository.replaceAll([...transactions, ...generated]);
      }
      await _repository.replaceAll(updatedRules);
      _rules = List.unmodifiable(updatedRules..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate)));
      _generatedCount = generated.length;
      _errorMessage = null;
      notifyListeners();
      return generated.length;
    } catch (_) {
      _errorMessage = 'Unable to process due recurring transactions.';
      notifyListeners();
      return 0;
    }
  }

  Future<bool> _save(List<RecurringTransactionRule> next) async {
    final previous = _rules;
    _rules = List.unmodifiable(next..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate)));
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.replaceAll(_rules);
      return true;
    } catch (_) {
      _rules = previous;
      _errorMessage = 'Unable to save recurring transactions.';
      notifyListeners();
      return false;
    }
  }

  DateTime _nextDate(DateTime date, RecurringFrequency frequency) {
    return switch (frequency) {
      RecurringFrequency.weekly => date.add(const Duration(days: 7)),
      RecurringFrequency.monthly => _addMonths(date, 1),
      RecurringFrequency.yearly => _addMonths(date, 12),
    };
  }

  DateTime _addMonths(DateTime date, int months) {
    final targetMonth = date.month - 1 + months;
    final year = date.year + targetMonth ~/ 12;
    final month = targetMonth % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  String _occurrenceId(String ruleId, DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${ruleId}_${date.year}$month$day';
  }
}
