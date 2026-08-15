import '../entities/debt.dart';

abstract class DebtRepository {
  Future<List<Debt>> getAll();
  Future<void> replaceAll(List<Debt> debts);
}
