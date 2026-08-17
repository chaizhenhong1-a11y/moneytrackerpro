import '../../../accounts/domain/entities/finance_account.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../../debts/domain/entities/debt.dart';
import '../models/net_worth_report.dart';

abstract final class NetWorthService {
  static NetWorthReport build({
    required List<FinanceAccount> accounts,
    required List<TransactionEntry> transactions,
    List<Debt> debts = const [],
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final liabilities =
        debts.fold<double>(0, (sum, debt) => sum + debt.currentBalance);
    final currentAssets = _balanceThrough(transactions, today);
    final current = currentAssets - liabilities;
    final thirtyDaysAgo = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 30));
    final previous = _balanceThrough(transactions, thirtyDaysAgo) - liabilities;

    final accountSlices = accounts.map((account) {
      final balance = transactions
          .where((item) =>
              item.accountId == account.id && !item.date.isAfter(today))
          .fold<double>(0, (sum, item) => sum + item.signedAmount);
      return AccountNetWorthSlice(
        accountId: account.id,
        accountName: account.name,
        balance: balance,
        isArchived: account.isArchived,
      );
    }).toList()
      ..sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));

    return NetWorthReport(
      currentNetWorth: current,
      change30Days: current - previous,
      history: _monthlyHistory(transactions, today, liabilities),
      accounts: List.unmodifiable(accountSlices),
      totalLiabilities: liabilities,
    );
  }

  static double _balanceThrough(
      List<TransactionEntry> transactions, DateTime through) {
    final end =
        DateTime(through.year, through.month, through.day, 23, 59, 59, 999);
    return transactions
        .where((item) => !item.date.isAfter(end))
        .fold<double>(0, (sum, item) => sum + item.signedAmount);
  }

  static List<NetWorthPoint> _monthlyHistory(
      List<TransactionEntry> transactions, DateTime now, double liabilities) {
    final points = <NetWorthPoint>[];
    for (var offset = 5; offset >= 1; offset--) {
      final month =
          DateTime(now.year, now.month - offset + 1, 0, 23, 59, 59, 999);
      points.add(NetWorthPoint(
          date: month,
          value: _balanceThrough(transactions, month) - liabilities));
    }
    points.add(
      NetWorthPoint(
        date: DateTime(now.year, now.month, now.day),
        value: _balanceThrough(transactions, now) - liabilities,
      ),
    );
    return List.unmodifiable(points);
  }
}
