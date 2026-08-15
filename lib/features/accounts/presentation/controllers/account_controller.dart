import 'package:flutter/foundation.dart';

import '../../domain/entities/finance_account.dart';
import '../../domain/repositories/account_repository.dart';

class AccountController extends ChangeNotifier {
  AccountController(this._repository);

  final AccountRepository _repository;
  List<FinanceAccount> _accounts = const [FinanceAccount.cash()];
  bool _isLoading = false;
  String? _errorMessage;

  List<FinanceAccount> get accounts => _accounts;
  List<FinanceAccount> get activeAccounts =>
      List.unmodifiable(_accounts.where((account) => !account.isArchived));
  List<FinanceAccount> get archivedAccounts =>
      List.unmodifiable(_accounts.where((account) => account.isArchived));
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _accounts = await _repository.getAll();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Unable to load accounts.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addAccount({required String name, required FinanceAccountType type}) async {
    final next = FinanceAccount(
      id: 'account_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      type: type,
    );
    return _save([..._accounts, next]);
  }


  Future<bool> archiveAccount(String id) async {
    if (id == FinanceAccountIds.cash) {
      _errorMessage = 'The default Cash account cannot be archived.';
      notifyListeners();
      return false;
    }
    final next = _accounts
        .map((account) => account.id == id ? account.copyWith(isArchived: true) : account)
        .toList();
    return _save(next);
  }

  Future<bool> restoreAccount(String id) async {
    final next = _accounts
        .map((account) => account.id == id ? account.copyWith(isArchived: false) : account)
        .toList();
    return _save(next);
  }

  Future<bool> deleteAccount(String id, {required bool isUsed}) async {
    if (id == FinanceAccountIds.cash || isUsed) {
      _errorMessage = isUsed ? 'Move or delete this account’s transactions first.' : 'The default Cash account cannot be deleted.';
      notifyListeners();
      return false;
    }
    return _save(_accounts.where((account) => account.id != id).toList());
  }

  Future<bool> replaceAll(List<FinanceAccount> accounts) {
    return _save(accounts.isEmpty ? const [FinanceAccount.cash()] : accounts);
  }

  Future<bool> _save(List<FinanceAccount> next) async {
    final previous = _accounts;
    _accounts = List.unmodifiable(next);
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.replaceAll(next);
      return true;
    } catch (_) {
      _accounts = previous;
      _errorMessage = 'Unable to save accounts.';
      notifyListeners();
      return false;
    }
  }
}
