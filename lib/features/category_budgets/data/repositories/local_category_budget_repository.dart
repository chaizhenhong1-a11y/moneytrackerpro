import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/category_budget.dart';
import '../../domain/repositories/category_budget_repository.dart';

class LocalCategoryBudgetRepository implements CategoryBudgetRepository {
  LocalCategoryBudgetRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'moneytracker.categoryBudgets.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<CategoryBudget>> getAll() async {
    final stored = await _preferences.getString(_storageKey);
    if (stored == null) return const [];
    final decoded = jsonDecode(stored) as List<dynamic>;
    return List.unmodifiable(decoded.map((item) {
      final json = item as Map<String, dynamic>;
      return CategoryBudget(
        categoryId: json['categoryId'] as String,
        monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      );
    }));
  }

  @override
  Future<void> replaceAll(List<CategoryBudget> budgets) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode(budgets
          .map((budget) => {
                'categoryId': budget.categoryId,
                'monthlyLimit': budget.monthlyLimit,
              })
          .toList()),
    );
  }
}
