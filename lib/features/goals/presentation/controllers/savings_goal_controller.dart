import 'package:flutter/foundation.dart';

import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_goal_repository.dart';

class SavingsGoalController extends ChangeNotifier {
  SavingsGoalController(this._repository);

  final SavingsGoalRepository _repository;
  List<SavingsGoal> _goals = const [];
  String? _errorMessage;

  List<SavingsGoal> get goals => _goals;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    try {
      _goals = await _repository.getAll();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Unable to load savings goals.';
    }
    notifyListeners();
  }

  Future<bool> addGoal({
    required String name,
    required double targetAmount,
    required String accountId,
    required DateTime deadline,
  }) {
    return _save([
      ..._goals,
      SavingsGoal(
        id: 'goal_${DateTime.now().microsecondsSinceEpoch}',
        name: name.trim(),
        targetAmount: targetAmount,
        accountId: accountId,
        deadline: deadline,
      ),
    ]);
  }

  Future<bool> deleteGoal(String id) =>
      _save(_goals.where((goal) => goal.id != id).toList());

  Future<bool> replaceAll(List<SavingsGoal> goals) => _save(goals);

  Future<bool> _save(List<SavingsGoal> next) async {
    final previous = _goals;
    _goals = List.unmodifiable(next);
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.replaceAll(next);
      return true;
    } catch (_) {
      _goals = previous;
      _errorMessage = 'Unable to save savings goals.';
      notifyListeners();
      return false;
    }
  }
}
