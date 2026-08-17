import 'package:flutter/foundation.dart';

import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';

class DebtController extends ChangeNotifier {
  DebtController(this._repository);

  final DebtRepository _repository;
  List<Debt> _debts = const [];
  String? _errorMessage;

  List<Debt> get debts => _debts;
  String? get errorMessage => _errorMessage;
  double get totalOutstanding =>
      _debts.fold(0, (sum, debt) => sum + debt.currentBalance);
  int get activeCount => _debts.where((debt) => !debt.isPaidOff).length;

  Future<void> load() async {
    try {
      _debts = await _repository.getAll();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Unable to load debts.';
    }
    notifyListeners();
  }

  Future<bool> addDebt({
    required String name,
    required DebtType type,
    required double originalAmount,
    required double currentBalance,
    required double interestRate,
    required DateTime dueDate,
  }) =>
      _save([
        ..._debts,
        Debt(
          id: 'debt_${DateTime.now().microsecondsSinceEpoch}',
          name: name.trim(),
          type: type,
          originalAmount: originalAmount,
          currentBalance: currentBalance,
          interestRate: interestRate,
          dueDate: dueDate,
        ),
      ]);

  Future<bool> updateDebt(Debt debt) => _save([
        for (final item in _debts)
          if (item.id == debt.id) debt else item,
      ]);

  Future<bool> recordPayment(String id, double amount) {
    final next = _debts.map((debt) {
      if (debt.id != id) return debt;
      return debt.copyWith(
          currentBalance: (debt.currentBalance - amount)
              .clamp(0.0, debt.currentBalance)
              .toDouble());
    }).toList();
    return _save(next);
  }

  Future<bool> deleteDebt(String id) =>
      _save(_debts.where((debt) => debt.id != id).toList());
  Future<bool> replaceAll(List<Debt> debts) => _save(debts);

  Future<bool> _save(List<Debt> next) async {
    final previous = _debts;
    _debts = List.unmodifiable(next);
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.replaceAll(next);
      return true;
    } catch (_) {
      _debts = previous;
      _errorMessage = 'Unable to save debts.';
      notifyListeners();
      return false;
    }
  }
}
