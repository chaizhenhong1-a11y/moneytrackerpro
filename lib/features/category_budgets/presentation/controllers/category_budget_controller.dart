import 'package:flutter/foundation.dart';

import '../../domain/entities/category_budget.dart';
import '../../domain/repositories/category_budget_repository.dart';

class CategoryBudgetController extends ChangeNotifier {
  CategoryBudgetController(this._repository);

  final CategoryBudgetRepository _repository;
  List<CategoryBudget> _budgets = const [];
  String? _errorMessage;

  List<CategoryBudget> get budgets => _budgets;
  String? get errorMessage => _errorMessage;

  double limitFor(String categoryId) {
    for (final budget in _budgets) {
      if (budget.categoryId == categoryId) return budget.monthlyLimit;
    }
    return 0;
  }

  Future<void> load() async {
    try {
      _budgets = await _repository.getAll();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Unable to load category budgets.';
    }
    notifyListeners();
  }

  Future<bool> setBudget(String categoryId, double amount) async {
    if (!amount.isFinite || amount < 0) return false;
    final next =
        _budgets.where((item) => item.categoryId != categoryId).toList();
    if (amount > 0) {
      next.add(CategoryBudget(categoryId: categoryId, monthlyLimit: amount));
    }
    return replaceAll(next);
  }

  Future<bool> replaceAll(List<CategoryBudget> budgets) async {
    final previous = _budgets;
    _budgets = List.unmodifiable(budgets);
    notifyListeners();
    try {
      await _repository.replaceAll(_budgets);
      _errorMessage = null;
      return true;
    } catch (_) {
      _budgets = previous;
      _errorMessage = 'Unable to save category budgets.';
      notifyListeners();
      return false;
    }
  }
}
