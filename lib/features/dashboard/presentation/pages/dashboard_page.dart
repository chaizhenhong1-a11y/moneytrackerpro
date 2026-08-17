import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../alerts/domain/services/financial_alert_service.dart';
import '../../../accounts/presentation/controllers/account_controller.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../../category_budgets/presentation/controllers/category_budget_controller.dart';
import '../../../category_budgets/presentation/pages/budget_alerts_page.dart';
import '../../../cash_flow/domain/services/cash_flow_forecast_service.dart';
import '../../../cash_flow/presentation/pages/cash_flow_forecast_page.dart';
import '../../../financial_health/domain/services/financial_health_service.dart';
import '../../../financial_health/presentation/pages/financial_health_page.dart';
import '../../../net_worth/domain/services/net_worth_service.dart';
import '../../../net_worth/presentation/pages/net_worth_page.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../../recurring/presentation/controllers/recurring_transaction_controller.dart';
import '../../../recurring/presentation/pages/upcoming_recurring_page.dart';
import '../../../goals/presentation/controllers/savings_goal_controller.dart';
import '../../../goals/presentation/pages/savings_goals_page.dart';
import '../../../debts/presentation/controllers/debt_controller.dart';
import '../../../debts/presentation/pages/debts_page.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/spending_chart_card.dart';
import '../widgets/transaction_tile.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    required this.controller,
    required this.settingsController,
    required this.onShowTransactions,
    required this.accountController,
    required this.recurringController,
    required this.savingsGoalController,
    required this.categoryController,
    required this.categoryBudgetController,
    required this.debtController,
    super.key,
  });

  final DashboardController controller;
  final SettingsController settingsController;
  final VoidCallback onShowTransactions;
  final AccountController accountController;
  final RecurringTransactionController recurringController;
  final SavingsGoalController savingsGoalController;
  final CategoryController categoryController;
  final CategoryBudgetController categoryBudgetController;
  final DebtController debtController;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller,
        widget.settingsController,
        widget.accountController,
        widget.recurringController,
        widget.savingsGoalController,
        widget.categoryController,
        widget.categoryBudgetController,
        widget.debtController,
      ]),
      builder: (context, _) {
        final alertCount = FinancialAlertService.generate(
          transactions: _controller.transactions,
          settings: widget.settingsController.settings,
        ).length;
        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  sliver: SliverList.list(
                    children: [
                      _DashboardHeader(
                        name: widget.settingsController.settings.displayName,
                        alertCount: alertCount,
                        onAlertsTap: _openAlerts,
                      ),
                      const SizedBox(height: 24),
                      BalanceCard(
                        balance: _controller.balance,
                        income: _controller.income,
                        expense: _controller.expense,
                      ),
                      const SizedBox(height: 16),
                      BudgetProgressCard(
                        spent: _currentMonthExpense,
                        budget:
                            widget.settingsController.settings.monthlyBudget,
                      ),
                      const SizedBox(height: 12),
                      _NetWorthCard(
                        dashboardController: _controller,
                        accountController: widget.accountController,
                        debtController: widget.debtController,
                        onTap: _openNetWorth,
                      ),
                      const SizedBox(height: 12),
                      _DebtSummaryCard(
                          controller: widget.debtController, onTap: _openDebts),
                      const SizedBox(height: 12),
                      _FinancialHealthCard(
                        dashboardController: _controller,
                        accountController: widget.accountController,
                        recurringController: widget.recurringController,
                        savingsGoalController: widget.savingsGoalController,
                        categoryController: widget.categoryController,
                        categoryBudgetController:
                            widget.categoryBudgetController,
                        onTap: _openFinancialHealth,
                      ),
                      const SizedBox(height: 12),
                      _CategoryBudgetSummaryCard(
                        budgetController: widget.categoryBudgetController,
                        categoryController: widget.categoryController,
                        dashboardController: _controller,
                        onTap: _openBudgetAlerts,
                      ),
                      const SizedBox(height: 16),
                      _UpcomingRecurringCard(
                        controller: widget.recurringController,
                        accountController: widget.accountController,
                        onTap: _openUpcomingRecurring,
                      ),
                      const SizedBox(height: 12),
                      _CashFlowForecastCard(
                        balance: _controller.balance,
                        recurringController: widget.recurringController,
                        accountController: widget.accountController,
                        onTap: _openCashFlowForecast,
                      ),
                      const SizedBox(height: 12),
                      _SavingsGoalsCard(
                        controller: widget.savingsGoalController,
                        dashboardController: _controller,
                        onTap: _openSavingsGoals,
                      ),
                      const SizedBox(height: 25),
                      const _SectionHeader(
                          title: 'Spending overview', action: 'This week'),
                      const SizedBox(height: 14),
                      SpendingChartCard(transactions: _controller.transactions),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: 'Recent transactions',
                        action: 'See all',
                        onTap: widget.onShowTransactions,
                      ),
                      const SizedBox(height: 10),
                      if (_controller.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_controller.transactions.isEmpty)
                        const _EmptyTransactions()
                      else
                        ..._controller.transactions.map(
                          (item) => item.isTransfer || item.isReconciliation
                              ? TransactionTile(
                                  transaction: item,
                                  onTap: () => _showProtectedRecord(item),
                                )
                              : Dismissible(
                                  key: ValueKey(item.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (_) => _confirmDelete(item),
                                  background: Container(
                                    margin: const EdgeInsets.only(bottom: 11),
                                    padding: const EdgeInsets.only(right: 22),
                                    alignment: Alignment.centerRight,
                                    decoration: BoxDecoration(
                                      color: AppColors.expense,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.white),
                                  ),
                                  onDismissed: (_) => _deleteWithUndo(item),
                                  child: TransactionTile(
                                    transaction: item,
                                    onTap: () =>
                                        _showEditTransactionSheet(item),
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTransactionSheet,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, size: 30),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  double get _currentMonthExpense {
    final now = DateTime.now();
    return _controller.transactions
        .where((item) =>
            item.countsAsExpense &&
            item.date.year == now.year &&
            item.date.month == now.month)
        .fold(0, (sum, item) => sum + item.amount);
  }

  void _showAddTransactionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        controller: _controller,
        categories: widget.categoryController.categories,
        accounts: widget.accountController.activeAccounts,
      ),
    );
  }

  void _showEditTransactionSheet(TransactionEntry transaction) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        controller: _controller,
        categories: widget.categoryController.categories,
        accounts: widget.accountController.accounts,
        transaction: transaction,
      ),
    );
  }

  Future<void> _showProtectedRecord(TransactionEntry transaction) async {
    final isTransfer = transaction.isTransfer;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isTransfer ? 'Transfer record' : 'Reconciliation record'),
        content: Text(
          isTransfer
              ? 'Transfers are linked records. Open Transactions or the account activity to edit or cancel the complete transfer safely.'
              : 'Reconciliation adjustments are system balance corrections. Open Transactions to review or remove this adjustment.',
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done')),
        ],
      ),
    );
  }

  void _openUpcomingRecurring() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UpcomingRecurringPage(
          controller: widget.recurringController,
          accountController: widget.accountController,
          categoryController: widget.categoryController,
        ),
      ),
    );
  }

  void _openCashFlowForecast() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CashFlowForecastPage(
          dashboardController: _controller,
          recurringController: widget.recurringController,
          accountController: widget.accountController,
        ),
      ),
    );
  }

  void _openNetWorth() {
    final report = NetWorthService.build(
      accounts: widget.accountController.accounts,
      transactions: _controller.transactions,
      debts: widget.debtController.debts,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => NetWorthPage(report: report)),
    );
  }

  void _openDebts() {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => DebtsPage(controller: widget.debtController)));
  }

  void _openFinancialHealth() {
    final report = FinancialHealthService.evaluate(
      transactions: _controller.transactions,
      categories: widget.categoryController.categories,
      categoryBudgets: widget.categoryBudgetController.budgets,
      savingsGoals: widget.savingsGoalController.goals,
      recurringRules: widget.recurringController.rules,
      activeAccountIds: widget.accountController.activeAccounts
          .map((account) => account.id)
          .toSet(),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) => FinancialHealthPage(report: report)),
    );
  }

  void _openSavingsGoals() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavingsGoalsPage(
          controller: widget.savingsGoalController,
          accountController: widget.accountController,
          dashboardController: _controller,
        ),
      ),
    );
  }

  void _openAlerts() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AlertsPage(
          dashboardController: _controller,
          settingsController: widget.settingsController,
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(TransactionEntry transaction) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: Text('${transaction.title} will be removed.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteWithUndo(TransactionEntry transaction) async {
    await _controller.deleteTransaction(transaction.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${transaction.title} deleted.'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => _controller.restoreTransaction(transaction),
          ),
        ),
      );
  }

  void _openBudgetAlerts() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BudgetAlertsPage(
          budgetController: widget.categoryBudgetController,
          categoryController: widget.categoryController,
          dashboardController: _controller,
        ),
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({
    required this.dashboardController,
    required this.accountController,
    required this.debtController,
    required this.onTap,
  });

  final DashboardController dashboardController;
  final AccountController accountController;
  final DebtController debtController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final report = NetWorthService.build(
      accounts: accountController.accounts,
      transactions: dashboardController.transactions,
      debts: debtController.debts,
    );
    final change = report.change30Days;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Net worth',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '${CurrencyFormatter.myr(report.currentNetWorth)} · ${change >= 0 ? '+' : '-'}${CurrencyFormatter.myr(change.abs())} / 30d',
                  style: TextStyle(
                    color: change < 0
                        ? AppColors.expense
                        : AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: change < 0 ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  const _DebtSummaryCard({required this.controller, required this.onTap});

  final DebtController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outstanding = controller.totalOutstanding;
    final subtitle = controller.debts.isEmpty
        ? 'Track credit cards and loans'
        : '${controller.activeCount} active · ${CurrencyFormatter.myr(outstanding)} outstanding';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.credit_card_rounded,
                  color: AppColors.expense)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Debts & liabilities',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35)),
              ])),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

class _FinancialHealthCard extends StatelessWidget {
  const _FinancialHealthCard({
    required this.dashboardController,
    required this.accountController,
    required this.recurringController,
    required this.savingsGoalController,
    required this.categoryController,
    required this.categoryBudgetController,
    required this.onTap,
  });

  final DashboardController dashboardController;
  final AccountController accountController;
  final RecurringTransactionController recurringController;
  final SavingsGoalController savingsGoalController;
  final CategoryController categoryController;
  final CategoryBudgetController categoryBudgetController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final report = FinancialHealthService.evaluate(
      transactions: dashboardController.transactions,
      categories: categoryController.categories,
      categoryBudgets: categoryBudgetController.budgets,
      savingsGoals: savingsGoalController.goals,
      recurringRules: recurringController.rules,
      activeAccountIds:
          accountController.activeAccounts.map((account) => account.id).toSet(),
    );
    final needsAttention = report.score < 55;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: needsAttention
                  ? AppColors.expense.withValues(alpha: .35)
                  : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: needsAttention
                    ? const Color(0xFFFFEEEE)
                    : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${report.score}',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color:
                        needsAttention ? AppColors.expense : AppColors.primary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Financial health',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    '${report.label} · ${report.headline}',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CategoryBudgetSummaryCard extends StatelessWidget {
  const _CategoryBudgetSummaryCard({
    required this.budgetController,
    required this.categoryController,
    required this.dashboardController,
    required this.onTap,
  });

  final CategoryBudgetController budgetController;
  final CategoryController categoryController;
  final DashboardController dashboardController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    var alerts = 0;
    var over = 0;
    var tracked = 0;
    for (final budget in budgetController.budgets) {
      if (budget.monthlyLimit <= 0) continue;
      final matches = categoryController.categories
          .where((item) => item.id == budget.categoryId);
      if (matches.isEmpty) continue;
      final category = matches.first;
      tracked++;
      final spent = dashboardController.transactions
          .where((item) =>
              item.countsAsExpense &&
              item.category == category.name &&
              item.date.year == now.year &&
              item.date.month == now.month)
          .fold<double>(0, (sum, item) => sum + item.amount);
      final ratio =
          budget.monthlyLimit <= 0 ? 0.0 : spent / budget.monthlyLimit;
      if (ratio >= .8) alerts++;
      if (spent > budget.monthlyLimit) over++;
    }
    final subtitle = tracked == 0
        ? 'Set monthly limits for Food, Transport and more'
        : alerts == 0
            ? '$tracked category budgets on track'
            : over > 0
                ? '$alerts budget alerts · $over over limit'
                : '$alerts categor${alerts == 1 ? 'y needs' : 'ies need'} attention';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.donut_small_rounded,
                  color: AppColors.primary)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Category budgets',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        color: alerts > 0
                            ? AppColors.expense
                            : AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight:
                            alerts > 0 ? FontWeight.w700 : FontWeight.w400)),
              ])),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

class _CashFlowForecastCard extends StatelessWidget {
  const _CashFlowForecastCard({
    required this.balance,
    required this.recurringController,
    required this.accountController,
    required this.onTap,
  });

  final double balance;
  final RecurringTransactionController recurringController;
  final AccountController accountController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final projection = CashFlowForecastService.project(
      openingBalance: balance,
      rules: recurringController.rules,
      activeAccountIds:
          accountController.activeAccounts.map((account) => account.id).toSet(),
    );
    final danger = projection.hasShortfall;
    final change = projection.netChange;
    final subtitle = danger
        ? 'Possible shortfall on ${projection.firstNegativeDate!.day}/${projection.firstNegativeDate!.month}'
        : projection.points.isEmpty
            ? 'No scheduled cash flow in the next 30 days'
            : '30-day forecast: ${change >= 0 ? '+' : '-'}${CurrencyFormatter.myr(change.abs())}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: danger
                  ? AppColors.expense.withValues(alpha: .35)
                  : AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: danger ? const Color(0xFFFFEEEE) : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                danger ? Icons.warning_amber_rounded : Icons.auto_graph_rounded,
                color: danger ? AppColors.expense : AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cash flow forecast',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SavingsGoalsCard extends StatelessWidget {
  const _SavingsGoalsCard(
      {required this.controller,
      required this.dashboardController,
      required this.onTap});

  final SavingsGoalController controller;
  final DashboardController dashboardController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final goals = controller.goals;
    final completed = goals.where((goal) {
      final balance = dashboardController.transactions
          .where((item) => item.accountId == goal.accountId)
          .fold<double>(0, (sum, item) => sum + item.signedAmount);
      return balance >= goal.targetAmount;
    }).length;
    final subtitle = goals.isEmpty
        ? 'Create a target and track it from a linked account'
        : '$completed of ${goals.length} goals reached';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.savings_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Savings goals',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.35)),
              ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

class _UpcomingRecurringCard extends StatelessWidget {
  const _UpcomingRecurringCard({
    required this.controller,
    required this.accountController,
    required this.onTap,
  });

  final RecurringTransactionController controller;
  final AccountController accountController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeIds =
        accountController.activeAccounts.map((account) => account.id).toSet();
    final upcoming = controller.rules.where((rule) {
      if (rule.isPaused || !activeIds.contains(rule.accountId)) return false;
      final due = DateTime(
          rule.nextDueDate.year, rule.nextDueDate.month, rule.nextDueDate.day);
      final days = due.difference(today).inDays;
      return days >= 0 && days <= 7;
    }).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    final blocked = controller.rules.where((rule) {
      if (rule.isPaused || activeIds.contains(rule.accountId)) return false;
      return !DateTime(rule.nextDueDate.year, rule.nextDueDate.month,
              rule.nextDueDate.day)
          .isAfter(today);
    }).length;

    final next = upcoming.isEmpty ? null : upcoming.first;
    final subtitle = blocked > 0
        ? '$blocked recurring ${blocked == 1 ? 'rule needs' : 'rules need'} attention'
        : next == null
            ? 'No recurring transactions due in the next 7 days'
            : '${upcoming.length} due soon • Next: ${next.title} on ${next.nextDueDate.day}/${next.nextDueDate.month}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.notifications_active_outlined,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upcoming recurring',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader(
      {required this.name,
      required this.alertCount,
      required this.onAlertsTap});

  final String name;
  final int alertCount;
  final VoidCallback onAlertsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.person_rounded,
              color: AppColors.primary, size: 30),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Good morning',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 3),
              Text(name,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
                onPressed: onAlertsTap,
                icon: const Icon(Icons.notifications_none_rounded)),
            if (alertCount > 0)
              Positioned(
                right: -2,
                top: -3,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.expense, shape: BoxShape.circle),
                  child: Text(alertCount > 9 ? '9+' : '$alertCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, this.onTap});

  final String title;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.w700))),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Row(
              children: [
                Text(action,
                    style: TextStyle(
                        color: onTap == null
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        fontWeight: FontWeight.w600)),
                if (onTap != null)
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: AppColors.primarySoft, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text('No transactions yet',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            const Text('Tap + to record your first transaction.',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
