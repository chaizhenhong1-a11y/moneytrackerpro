import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/finance_account.dart';
import '../../domain/repositories/account_repository.dart';

class LocalAccountRepository implements AccountRepository {
  LocalAccountRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'moneytracker.accounts.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<FinanceAccount>> getAll() async {
    final stored = await _preferences.getString(_storageKey);
    if (stored == null) {
      const defaults = [FinanceAccount.cash()];
      await replaceAll(defaults);
      return defaults;
    }
    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      final accounts = decoded.map((item) {
        final json = item as Map<String, dynamic>;
        return FinanceAccount(
          id: json['id'] as String,
          name: json['name'] as String,
          type: FinanceAccountType.values.byName(json['type'] as String),
          isArchived: json['isArchived'] as bool? ?? false,
        );
      }).toList();
      if (accounts.isEmpty) return const [FinanceAccount.cash()];
      return List.unmodifiable(accounts);
    } catch (_) {
      throw const AccountStorageException('Stored account data is invalid.');
    }
  }

  @override
  Future<void> replaceAll(List<FinanceAccount> accounts) async {
    final encoded = accounts
        .map((account) => {
              'id': account.id,
              'name': account.name,
              'type': account.type.name,
              'isArchived': account.isArchived,
            })
        .toList();
    await _preferences.setString(_storageKey, jsonEncode(encoded));
  }
}

class AccountStorageException implements Exception {
  const AccountStorageException(this.message);
  final String message;
}
