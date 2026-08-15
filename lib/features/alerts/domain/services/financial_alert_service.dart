import '../../../settings/domain/entities/app_settings.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../entities/financial_alert.dart';

abstract final class FinancialAlertService {
  static List<FinancialAlert> generate({
    required List<TransactionEntry> transactions,
    required AppSettings settings,
  }) {
    final now = DateTime.now();
    final monthly = transactions.where(
      (item) => item.date.year == now.year && item.date.month == now.month,
    ).toList();
    final expenses = monthly.where((item) => item.countsAsExpense).toList();
    final incomeTotal = monthly
        .where((item) => item.countsAsIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenseTotal = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final alerts = <FinancialAlert>[];

    if (settings.budgetAlertsEnabled && settings.monthlyBudget > 0) {
      final ratio = expenseTotal / settings.monthlyBudget;
      if (ratio >= 1) {
        alerts.add(
          FinancialAlert(
            id: 'budget_exceeded_${now.year}_${now.month}',
            type: FinancialAlertType.budgetExceeded,
            severity: FinancialAlertSeverity.critical,
            title: 'Monthly budget exceeded',
            message: 'You are RM ${(expenseTotal - settings.monthlyBudget).toStringAsFixed(2)} over your monthly budget.',
          ),
        );
      } else if (ratio >= .8) {
        alerts.add(
          FinancialAlert(
            id: 'budget_warning_${now.year}_${now.month}',
            type: FinancialAlertType.budgetWarning,
            severity: FinancialAlertSeverity.warning,
            title: 'Budget is nearly used',
            message: 'You have used ${(ratio * 100).toStringAsFixed(0)}% of this month’s budget.',
          ),
        );
      }
    }

    if (settings.monthlyBudget > 0 && expenses.isNotEmpty) {
      final largest = expenses.reduce((a, b) => a.amount >= b.amount ? a : b);
      if (largest.amount >= settings.monthlyBudget * .25) {
        alerts.add(
          FinancialAlert(
            id: 'large_expense_${largest.id}',
            type: FinancialAlertType.largeExpense,
            severity: FinancialAlertSeverity.warning,
            title: 'Large expense detected',
            message: '${largest.title} used RM ${largest.amount.toStringAsFixed(2)}, at least 25% of your monthly budget.',
          ),
        );
      }
    }

    if (incomeTotal > expenseTotal && incomeTotal > 0) {
      alerts.add(
        FinancialAlert(
          id: 'positive_savings_${now.year}_${now.month}',
          type: FinancialAlertType.positiveSavings,
          severity: FinancialAlertSeverity.success,
          title: 'Positive savings this month',
          message: 'Income is ahead of expenses by RM ${(incomeTotal - expenseTotal).toStringAsFixed(2)}.',
        ),
      );
    }

    if (monthly.isEmpty) {
      alerts.add(
        FinancialAlert(
          id: 'no_activity_${now.year}_${now.month}',
          type: FinancialAlertType.noActivity,
          severity: FinancialAlertSeverity.info,
          title: 'Start tracking this month',
          message: 'Record your first transaction to unlock spending insights and budget progress.',
        ),
      );
    }

    return List.unmodifiable(alerts);
  }
}
