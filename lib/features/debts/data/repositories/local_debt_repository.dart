import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/debt.dart';
import '../../domain/repositories/debt_repository.dart';

class LocalDebtRepository implements DebtRepository {
  LocalDebtRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'moneytracker.debts.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<Debt>> getAll() async {
    final raw = await _preferences.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const [];
    final items = jsonDecode(raw) as List<dynamic>;
    return items.map((item) {
      final json = item as Map<String, dynamic>;
      return Debt(
        id: json['id'] as String,
        name: json['name'] as String,
        type: DebtType.values.byName(json['type'] as String),
        originalAmount: (json['originalAmount'] as num).toDouble(),
        currentBalance: (json['currentBalance'] as num).toDouble(),
        interestRate: (json['interestRate'] as num).toDouble(),
        dueDate: DateTime.parse(json['dueDate'] as String),
      );
    }).toList(growable: false);
  }

  @override
  Future<void> replaceAll(List<Debt> debts) async {
    final raw = jsonEncode(debts
        .map((debt) => {
              'id': debt.id,
              'name': debt.name,
              'type': debt.type.name,
              'originalAmount': debt.originalAmount,
              'currentBalance': debt.currentBalance,
              'interestRate': debt.interestRate,
              'dueDate': debt.dueDate.toIso8601String(),
            })
        .toList());
    await _preferences.setString(_key, raw);
  }
}
