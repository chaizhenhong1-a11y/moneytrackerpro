import '../entities/category_budget.dart';

abstract interface class CategoryBudgetRepository {
  Future<List<CategoryBudget>> getAll();
  Future<void> replaceAll(List<CategoryBudget> budgets);
}
