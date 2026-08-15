import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _displayNameKey = 'moneytracker.settings.displayName.v1';
  static const _monthlyBudgetKey = 'moneytracker.settings.monthlyBudget.v1';
  static const _budgetAlertsKey = 'moneytracker.settings.budgetAlerts.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppSettings> load() async {
    const defaults = AppSettings.defaults();
    return AppSettings(
      displayName: await _preferences.getString(_displayNameKey) ?? defaults.displayName,
      monthlyBudget: await _preferences.getDouble(_monthlyBudgetKey) ?? defaults.monthlyBudget,
      budgetAlertsEnabled: await _preferences.getBool(_budgetAlertsKey) ?? defaults.budgetAlertsEnabled,
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _preferences.setString(_displayNameKey, settings.displayName),
      _preferences.setDouble(_monthlyBudgetKey, settings.monthlyBudget),
      _preferences.setBool(_budgetAlertsKey, settings.budgetAlertsEnabled),
    ]);
  }
}
