import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_goal_repository.dart';

class LocalSavingsGoalRepository implements SavingsGoalRepository {
  LocalSavingsGoalRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'moneytracker.savingsGoals.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<List<SavingsGoal>> getAll() async {
    final raw = await _preferences.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const [];
    final items = jsonDecode(raw) as List<dynamic>;
    return items.map((item) {
      final json = item as Map<String, dynamic>;
      return SavingsGoal(
        id: json['id'] as String,
        name: json['name'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        accountId: json['accountId'] as String,
        deadline: DateTime.parse(json['deadline'] as String),
      );
    }).toList(growable: false);
  }

  @override
  Future<void> replaceAll(List<SavingsGoal> goals) async {
    final raw = jsonEncode(goals.map((goal) => {
      'id': goal.id,
      'name': goal.name,
      'targetAmount': goal.targetAmount,
      'accountId': goal.accountId,
      'deadline': goal.deadline.toIso8601String(),
    }).toList());
    await _preferences.setString(_key, raw);
  }
}
