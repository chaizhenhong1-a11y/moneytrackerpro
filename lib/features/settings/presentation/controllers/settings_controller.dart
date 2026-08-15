import 'package:flutter/foundation.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;
  AppSettings _settings = const AppSettings.defaults();
  bool _isLoading = false;
  String? _errorMessage;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _settings = await _repository.load();
    } catch (_) {
      _errorMessage = 'Unable to load settings.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({required String displayName, required double monthlyBudget}) {
    return _save(
      _settings.copyWith(
        displayName: displayName.trim(),
        monthlyBudget: monthlyBudget,
      ),
    );
  }

  Future<bool> setBudgetAlerts(bool enabled) {
    return _save(_settings.copyWith(budgetAlertsEnabled: enabled));
  }

  Future<bool> replaceSettings(AppSettings settings) {
    return _save(settings);
  }

  Future<bool> _save(AppSettings next) async {
    final previous = _settings;
    _settings = next;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.save(next);
      return true;
    } catch (_) {
      _settings = previous;
      _errorMessage = 'Unable to save settings.';
      notifyListeners();
      return false;
    }
  }
}
