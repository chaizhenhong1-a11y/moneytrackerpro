import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../transactions/domain/entities/transaction_category.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../domain/repositories/category_repository.dart';

class LocalCategoryRepository implements CategoryRepository {
  LocalCategoryRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'moneytracker.categories.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<TransactionCategory>> getAll() async {
    final stored = await _preferences.getString(_storageKey);
    if (stored == null) {
      final defaults = TransactionCategories.defaults();
      await replaceAll(defaults);
      return defaults;
    }

    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      final categories = decoded.map((item) {
        final json = item as Map<String, dynamic>;
        return TransactionCategory(
          id: json['id'] as String,
          name: json['name'] as String,
          icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
          color: Color(json['colorValue'] as int),
          type: TransactionType.values.byName(json['type'] as String),
          isArchived: json['isArchived'] as bool? ?? false,
          isSystem: json['isSystem'] as bool? ?? false,
        );
      }).toList();
      return categories.isEmpty ? TransactionCategories.defaults() : List.unmodifiable(categories);
    } catch (_) {
      throw const CategoryStorageException('Stored category data is invalid.');
    }
  }

  @override
  Future<void> replaceAll(List<TransactionCategory> categories) async {
    final encoded = categories
        .map((category) => {
              'id': category.id,
              'name': category.name,
              'iconCodePoint': category.icon.codePoint,
              'colorValue': category.color.toARGB32(),
              'type': category.type.name,
              'isArchived': category.isArchived,
              'isSystem': category.isSystem,
            })
        .toList();
    await _preferences.setString(_storageKey, jsonEncode(encoded));
  }
}

class CategoryStorageException implements Exception {
  const CategoryStorageException(this.message);
  final String message;
}
