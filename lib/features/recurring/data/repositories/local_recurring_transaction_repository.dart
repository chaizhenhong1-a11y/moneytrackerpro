import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../domain/entities/recurring_transaction_rule.dart';
import '../../domain/repositories/recurring_transaction_repository.dart';

class LocalRecurringTransactionRepository
    implements RecurringTransactionRepository {
  LocalRecurringTransactionRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'moneytracker.recurring_rules.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<RecurringTransactionRule>> getAll() async {
    final value = await _preferences.getString(_storageKey);
    if (value == null || value.isEmpty) return const [];

    final decoded = jsonDecode(value) as List<dynamic>;
    final rules = decoded.map((item) {
      final json = item as Map<String, dynamic>;
      return RecurringTransactionRule(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TransactionType.values.byName(json['type'] as String),
        category: json['category'] as String,
        accountId: json['accountId'] as String,
        frequency:
            RecurringFrequency.values.byName(json['frequency'] as String),
        nextDueDate: DateTime.parse(json['nextDueDate'] as String),
        isPaused: json['isPaused'] as bool? ?? false,
      );
    }).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    return List.unmodifiable(rules);
  }

  @override
  Future<void> replaceAll(List<RecurringTransactionRule> rules) async {
    final encoded = rules
        .map((rule) => {
              'id': rule.id,
              'title': rule.title,
              'amount': rule.amount,
              'type': rule.type.name,
              'category': rule.category,
              'accountId': rule.accountId,
              'frequency': rule.frequency.name,
              'nextDueDate': rule.nextDueDate.toIso8601String(),
              'isPaused': rule.isPaused,
            })
        .toList();
    await _preferences.setString(_storageKey, jsonEncode(encoded));
  }
}
