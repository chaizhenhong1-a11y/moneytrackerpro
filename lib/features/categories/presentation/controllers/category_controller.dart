import 'package:flutter/material.dart';

import '../../../transactions/domain/entities/transaction_category.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryController extends ChangeNotifier {
  CategoryController(this._repository);

  final CategoryRepository _repository;
  List<TransactionCategory> _categories = TransactionCategories.defaults();
  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionCategory> get categories => _categories;
  List<TransactionCategory> get activeCategories =>
      List.unmodifiable(_categories.where((category) => !category.isArchived));
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TransactionCategory> activeFor(TransactionType type) =>
      List.unmodifiable(
        _categories
            .where((category) => category.type == type && !category.isArchived),
      );

  TransactionCategory resolve(String name, TransactionType type) {
    for (final category in _categories) {
      if (category.name == name && category.type == type) return category;
    }
    return TransactionCategories.fallbackFor(type);
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _repository.getAll();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Unable to load categories.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCategory({
    required String name,
    required TransactionType type,
    required IconData icon,
    required Color color,
  }) {
    final normalized = name.trim();
    if (_categories.any((category) =>
        category.name.toLowerCase() == normalized.toLowerCase())) {
      _errorMessage = 'A category with this name already exists.';
      notifyListeners();
      return Future.value(false);
    }
    return _save([
      ..._categories,
      TransactionCategory(
        id: 'category_${DateTime.now().microsecondsSinceEpoch}',
        name: normalized,
        icon: icon,
        color: color,
        type: type,
      ),
    ]);
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    final normalized = name.trim();
    if (_categories.any((category) =>
        category.id != id &&
        category.name.toLowerCase() == normalized.toLowerCase())) {
      _errorMessage = 'A category with this name already exists.';
      notifyListeners();
      return Future.value(false);
    }
    return _save(
      _categories
          .map((category) => category.id == id
              ? category.copyWith(name: normalized, icon: icon, color: color)
              : category)
          .toList(),
    );
  }

  Future<bool> setArchived(String id, bool isArchived) {
    final category = _categories.firstWhere((item) => item.id == id);
    if (isArchived && activeFor(category.type).length <= 1) {
      _errorMessage =
          'Keep at least one active ${category.type.name} category.';
      notifyListeners();
      return Future.value(false);
    }
    return _save(
      _categories
          .map((item) =>
              item.id == id ? item.copyWith(isArchived: isArchived) : item)
          .toList(),
    );
  }

  Future<bool> replaceAll(List<TransactionCategory> categories) {
    return _save(categories.isEmpty
        ? TransactionCategories.defaults()
        : List.of(categories));
  }

  Future<bool> _save(List<TransactionCategory> next) async {
    final previous = _categories;
    _categories = List.unmodifiable(next);
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.replaceAll(_categories);
      return true;
    } catch (_) {
      _categories = previous;
      _errorMessage = 'Unable to save categories.';
      notifyListeners();
      return false;
    }
  }
}
