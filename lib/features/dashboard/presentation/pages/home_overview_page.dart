import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../accounts/presentation/controllers/account_controller.dart';
import '../../../alerts/domain/services/financial_alert_service.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../../category_budgets/presentation/controllers/category_budget_controller.dart';
import '../../../debts/presentation/controllers/debt_controller.dart';
import '../../../goals/presentation/controllers/savings_goal_controller.dart';
import '../../../monthly_review/domain/models/monthly_financial_review.dart';
import '../../../monthly_review/domain/services/monthly_financial_review_service.dart';
import '../../../monthly_review/domain/services/safe_to_spend_service.dart';
import '../../../recurring/presentation/controllers/recurring_transaction_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/balance_card.dart';
import '../widgets/budget_progress_card.dart';
import '../widgets/spending_chart_card.dart';
import '../widgets/transaction_tile.dart';

class HomeOverviewPage extends StatefulWidget {
  const HomeOverviewPage({
    required this.controller,
    required this.settingsController,
    required this.onShowTransactions,
    required this.onShowMore,
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
  final VoidCallback onShowMore;
  final AccountController accountController;
  final RecurringTransactionController recurringController;
  final SavingsGoalController savingsGoalController;
  final CategoryController categoryController;
  final CategoryBudgetController categoryBudgetController;
  final DebtController debtController;

  @override
  State<HomeOverviewPage> createState() => _HomeOverviewPageState();
}

class _HomeOverviewPageState extends State<HomeOverviewPage> {
  DashboardController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller,
        widget.settingsController,
        widget.accountController,
      ]),
      builder: (context, _) {
        final now = DateTime.now();
        final review = MonthlyFinancialReviewService.build(
          transactions: _controller.transactions,
          month: DateTime(now.year, now.month),
        );
        final safeToSpend = SafeToSpendService.build(review);
        final alertCount = FinancialAlertService.generate(
          transactions: _controller.transactions,
          settings: widget.settingsController.settings,
        ).length;
        final recent = _controller.transactions.take(5).toList(growable: false);

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _controller.load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                    sliver: SliverList.list(
                      children: [
                        _HomeHeader(
                          name: widget.settingsController.settings.displayName,
                          alertCount: alertCount,
                          onAlertsTap: _openAlerts,
                        ),
                        const SizedBox(height: 22),
                        BalanceCard(
                          balance: _controller.balance,
                          income: review.income,
                          expense: review.expenses,
                        ),
                        if (_showQuickStart) ...[
                          const SizedBox(height: 14),
                          _QuickStartCard(
                            hasRealAccount:
                                widget.accountController.activeAccounts.length >
                                    1,
                            hasTransaction: _controller.transactions.isNotEmpty,
                            hasBudget: widget
                                    .settingsController.settings.monthlyBudget >
                                0,
                            onAccounts: widget.onShowMore,
                            onTransaction: _showAddTransactionSheet,
                            onBudget: _showBudgetSetup,
                          ),
                        ],
                        const SizedBox(height: 14),
                        const _SectionHeader(
                          title: 'This month',
                          action: 'Plan',
                        ),
                        const SizedBox(height: 10),
                        BudgetProgressCard(
                          spent: review.expenses,
                          budget:
                              widget.settingsController.settings.monthlyBudget,
                        ),
                        const SizedBox(height: 14),
                        _ForYouCard(
                          review: review,
                          safeToSpend: safeToSpend.safeToSpend,
                          dailyAllowance: safeToSpend.dailyAllowance,
                          daysRemaining: safeToSpend.daysRemaining,
                        ),
                        const SizedBox(height: 25),
                        _SectionHeader(
                          title: 'Recent transactions',
                          action: 'See all',
                          onTap: widget.onShowTransactions,
                        ),
                        const SizedBox(height: 10),
                        if (_controller.isLoading)
                          const AppStateView.loading(
                            title: 'Loading recent activity',
                            message: 'Refreshing your latest transactions…',
                          )
                        else if (recent.isEmpty)
                          const _EmptyTransactions()
                        else
                          ...recent.map(
                            (transaction) => TransactionTile(
                              transaction: transaction,
                              onTap: () => _openTransaction(transaction),
                            ),
                          ),
                        const SizedBox(height: 25),
                        const _SectionHeader(
                          title: 'Spending overview',
                          action: 'This week',
                        ),
                        const SizedBox(height: 12),
                        SpendingChartCard(
                          transactions: _controller.transactions,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

  bool get _showQuickStart {
    final hasRealAccount = widget.accountController.activeAccounts.length > 1;
    final hasTransaction = _controller.transactions.isNotEmpty;
    final hasBudget = widget.settingsController.settings.monthlyBudget > 0;
    return !(hasRealAccount && hasTransaction && hasBudget);
  }

  Future<void> _showBudgetSetup() async {
    final current = widget.settingsController.settings;
    final budgetController = TextEditingController(
      text: current.monthlyBudget.toStringAsFixed(2),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set monthly budget'),
        content: TextField(
          controller: budgetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Monthly budget',
            prefixText: 'RM ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(
                budgetController.text.replaceAll(',', '').trim(),
              );
              if (parsed == null || parsed <= 0) return;
              Navigator.pop(dialogContext, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    budgetController.dispose();
    if (value == null || !mounted) return;

    await widget.settingsController.updateProfile(
      displayName: current.displayName,
      monthlyBudget: value,
    );
  }

  void _showAddTransactionSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        controller: _controller,
        categories: widget.categoryController.activeCategories,
        accounts: widget.accountController.accounts,
      ),
    );
  }

  void _openTransaction(TransactionEntry transaction) {
    if (transaction.isTransfer || transaction.isReconciliation) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(transaction.isTransfer ? 'Transfer' : 'Reconciliation'),
          content: Text(
            transaction.isTransfer
                ? 'Transfers are managed from Accounts so both sides of the transfer remain in sync.'
                : 'Reconciliation records are managed from the account ledger.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        controller: _controller,
        categories: widget.categoryController.activeCategories,
        accounts: widget.accountController.accounts,
        transaction: transaction,
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
}

class _QuickStartCard extends StatelessWidget {
  const _QuickStartCard({
    required this.hasRealAccount,
    required this.hasTransaction,
    required this.hasBudget,
    required this.onAccounts,
    required this.onTransaction,
    required this.onBudget,
  });

  final bool hasRealAccount;
  final bool hasTransaction;
  final bool hasBudget;
  final VoidCallback onAccounts;
  final VoidCallback onTransaction;
  final VoidCallback onBudget;

  @override
  Widget build(BuildContext context) {
    final completed = [hasRealAccount, hasTransaction, hasBudget]
        .where((value) => value)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.rocket_launch_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick start',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completed of 3 ready',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completed / 3,
              minHeight: 7,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 14),
            _QuickStartStep(
              done: hasRealAccount,
              title: 'Add the accounts you actually use',
              subtitle: hasRealAccount
                  ? 'Account setup is ready.'
                  : 'Cash is ready. Add your bank or e-wallet from More.',
              action: hasRealAccount ? null : 'Open More',
              onTap: hasRealAccount ? null : onAccounts,
            ),
            const Divider(height: 20),
            _QuickStartStep(
              done: hasTransaction,
              title: 'Record your first transaction',
              subtitle: hasTransaction
                  ? 'Your activity is already feeding Home and Insights.'
                  : 'Add one income or expense to make the dashboard useful.',
              action: hasTransaction ? null : 'Add transaction',
              onTap: hasTransaction ? null : onTransaction,
            ),
            const Divider(height: 20),
            _QuickStartStep(
              done: hasBudget,
              title: 'Set a monthly spending guardrail',
              subtitle: hasBudget
                  ? 'Your monthly budget is active.'
                  : 'Choose a realistic amount for this month.',
              action: hasBudget ? null : 'Set budget',
              onTap: hasBudget ? null : onBudget,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStartStep extends StatelessWidget {
  const _QuickStartStep({
    required this.done,
    required this.title,
    required this.subtitle,
    this.action,
    this.onTap,
  });

  final bool done;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: done ? AppColors.success : AppColors.primary,
          size: 22,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              if (action != null && onTap != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(action!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.alertCount,
    required this.onAlertsTap,
  });

  final String name;
  final int alertCount;
  final VoidCallback onAlertsTap;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppColors.primary,
            size: 30,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton.filledTonal(
              onPressed: onAlertsTap,
              icon: const Icon(Icons.notifications_none_rounded),
            ),
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
                    color: AppColors.expense,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    alertCount > 9 ? '9+' : '$alertCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ForYouCard extends StatelessWidget {
  const _ForYouCard({
    required this.review,
    required this.safeToSpend,
    required this.dailyAllowance,
    required this.daysRemaining,
  });

  final MonthlyFinancialReview review;
  final double safeToSpend;
  final double dailyAllowance;
  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    final hasSurplus = review.netCashFlow > 0;
    final title = hasSurplus ? 'You are on track' : 'Protect your cash flow';
    final message = hasSurplus
        ? daysRemaining > 0
            ? 'You can safely spend about ${CurrencyFormatter.myr(dailyAllowance)} per day for the rest of this month.'
            : 'This month is complete. Use Insights to plan your next month.'
        : 'There is no flexible spending allowance yet. Keep non-essential spending low until cash flow is positive.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'For you',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (hasSurplus) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${CurrencyFormatter.myr(safeToSpend)} flexible this month',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
            child: Row(
              children: [
                Text(
                  action,
                  style: TextStyle(
                    color: onTap == null
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
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
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 13),
            const Text(
              'No transactions yet',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Tap + to record your first transaction.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
