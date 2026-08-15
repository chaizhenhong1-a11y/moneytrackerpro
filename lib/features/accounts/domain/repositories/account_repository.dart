import '../entities/finance_account.dart';

abstract interface class AccountRepository {
  Future<List<FinanceAccount>> getAll();
  Future<void> replaceAll(List<FinanceAccount> accounts);
}
