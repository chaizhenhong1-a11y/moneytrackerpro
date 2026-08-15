import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../accounts/presentation/controllers/account_controller.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../../category_budgets/presentation/controllers/category_budget_controller.dart';
import '../../../category_budgets/presentation/pages/category_budgets_page.dart';
import '../../../accounts/presentation/widgets/transfer_funds_sheet.dart';
import '../../../recurring/presentation/controllers/recurring_transaction_controller.dart';
import '../../../recurring/presentation/pages/recurring_transactions_page.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/transaction_entry.dart';
import '../widgets/add_transaction_sheet.dart';
import '../../../dashboard/presentation/widgets/transaction_tile.dart';

enum TransactionFilter { all, income, expense, transfer, reconciliation }
enum TransactionPeriod { thisMonth, lastMonth, all }

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    required this.controller,
    required this.accountController,
    required this.recurringController,
    required this.categoryController,
    required this.categoryBudgetController,
    super.key,
  });

  final DashboardController controller;
  final AccountController accountController;
  final RecurringTransactionController recurringController;
  final CategoryController categoryController;
  final CategoryBudgetController categoryBudgetController;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _searchController = TextEditingController();
  TransactionFilter _filter = TransactionFilter.all;
  TransactionPeriod _period = TransactionPeriod.thisMonth;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.accountController, widget.categoryController, widget.categoryBudgetController]),
      builder: (context, _) {
        final transactions = _filteredTransactions(widget.controller.transactions);
        final total = transactions.fold<double>(0, (sum, item) => sum + item.signedAmount);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Transactions', style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Category budgets',
                onPressed: _openCategoryBudgets,
                icon: const Icon(Icons.donut_small_rounded),
              ),
              IconButton(
                tooltip: 'Recurring transactions',
                onPressed: _openRecurringTransactions,
                icon: const Icon(Icons.event_repeat_rounded),
              ),
              IconButton(
                tooltip: 'Add transaction',
                onPressed: _openAddTransaction,
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: widget.controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                _SummaryCard(count: transactions.length, total: total),
                const SizedBox(height: 18),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search transactions',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<TransactionFilter>(
                    segments: const [
                      ButtonSegment(value: TransactionFilter.all, label: Text('All')),
                      ButtonSegment(value: TransactionFilter.income, label: Text('Income')),
                      ButtonSegment(value: TransactionFilter.expense, label: Text('Expense')),
                      ButtonSegment(value: TransactionFilter.transfer, label: Text('Transfer')),
                      ButtonSegment(value: TransactionFilter.reconciliation, label: Text('Reconcile')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (value) => setState(() => _filter = value.first),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TransactionPeriod>(
                  initialValue: _period,
                  decoration: InputDecoration(
                    labelText: 'Period',
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: TransactionPeriod.thisMonth, child: Text('This month')),
                    DropdownMenuItem(value: TransactionPeriod.lastMonth, child: Text('Last month')),
                    DropdownMenuItem(value: TransactionPeriod.all, child: Text('All time')),
                  ],
                  onChanged: (value) => setState(() => _period = value ?? _period),
                ),
                const SizedBox(height: 20),
                if (widget.controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (transactions.isEmpty)
                  const _NoResults()
                else
                  ..._buildGroupedTransactions(transactions),
              ],
            ),
          ),
        );
      },
    );
  }

  List<TransactionEntry> _filteredTransactions(List<TransactionEntry> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((item) {
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      final matchesFilter = switch (_filter) {
        TransactionFilter.all => true,
        TransactionFilter.income => item.countsAsIncome,
        TransactionFilter.expense => item.countsAsExpense,
        TransactionFilter.transfer => item.isTransfer,
        TransactionFilter.reconciliation => item.isReconciliation,
      };
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1);
      final matchesPeriod = switch (_period) {
        TransactionPeriod.thisMonth => item.date.year == now.year && item.date.month == now.month,
        TransactionPeriod.lastMonth => item.date.year == lastMonth.year && item.date.month == lastMonth.month,
        TransactionPeriod.all => true,
      };
      return matchesQuery && matchesFilter && matchesPeriod;
    }).toList();
  }

  List<Widget> _buildGroupedTransactions(List<TransactionEntry> transactions) {
    final widgets = <Widget>[];
    DateTime? previousDay;

    for (final transaction in transactions) {
      final day = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      if (previousDay != day) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
            child: Text(
              _dateGroupLabel(day),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        );
        previousDay = day;
      }
      if (transaction.isTransfer) {
        widgets.add(
          TransactionTile(
            transaction: transaction,
            onTap: () => _openTransferDetails(transaction),
          ),
        );
      } else {
        widgets.add(
          Dismissible(
            key: ValueKey('history_${transaction.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(transaction),
            onDismissed: (_) => _deleteWithUndo(transaction),
            background: Container(
              margin: const EdgeInsets.only(bottom: 11),
              padding: const EdgeInsets.only(right: 22),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(color: AppColors.expense, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            child: TransactionTile(
              transaction: transaction,
              onTap: transaction.isReconciliation
                  ? () => _openReconciliationDetails(transaction)
                  : () => _openEditTransaction(transaction),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  String _dateGroupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'TODAY';
    if (date == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _openCategoryBudgets() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CategoryBudgetsPage(
          controller: widget.categoryBudgetController,
          categoryController: widget.categoryController,
          dashboardController: widget.controller,
        ),
      ),
    );
  }

  Future<void> _openRecurringTransactions() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecurringTransactionsPage(
          controller: widget.recurringController,
          accountController: widget.accountController,
          categoryController: widget.categoryController,
        ),
      ),
    );
    if (!mounted) return;
    await widget.recurringController.processDueTransactions(
      activeAccountIds: widget.accountController.activeAccounts.map((account) => account.id).toSet(),
    );
    await widget.controller.load();
  }

  Future<void> _openAddTransaction() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        controller: widget.controller,
        categories: widget.categoryController.categories,
        accounts: widget.accountController.activeAccounts,
      ),
    );
  }

  Future<void> _openTransferDetails(TransactionEntry transaction) async {
    final pair = widget.controller.transferPairFor(transaction);
    if (pair.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This transfer pair is incomplete and cannot be changed safely.')),
      );
      return;
    }

    final outgoing = pair.firstWhere((item) => !item.isIncome);
    final incoming = pair.firstWhere((item) => item.isIncome);
    final fromName = _accountName(outgoing.accountId);
    final toName = _accountName(incoming.accountId);
    final action = await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Transfer details'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.myr(outgoing.amount),
                  style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _TransferDetailRow(label: 'From', value: fromName),
                _TransferDetailRow(label: 'To', value: toName),
                _TransferDetailRow(label: 'Date', value: _transferDate(outgoing.date)),
                if (outgoing.title.isNotEmpty)
                  _TransferDetailRow(label: 'Note', value: outgoing.title),
                const SizedBox(height: 8),
                const Text(
                  'Cancelling removes both linked entries so account balances stay in sync.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
              TextButton.icon(
                onPressed: () => Navigator.pop(dialogContext, 'edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, 'cancel'),
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Cancel transfer'),
              ),
            ],
          ),
        );

    if (action == 'edit') {
      await _editTransfer(transaction);
      return;
    }
    if (action != 'cancel') return;
    final removed = await widget.controller.cancelTransfer(transaction);
    if (!mounted) return;
    if (removed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage ?? 'Unable to cancel the transfer.')),
      );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Transfer from $fromName to $toName cancelled.'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => widget.controller.restoreTransactions(removed),
          ),
        ),
      );
  }

  Future<void> _editTransfer(TransactionEntry transaction) async {
    if (widget.accountController.accounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least two accounts before editing a transfer.')),
      );
      return;
    }
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransferFundsSheet(
        controller: widget.controller,
        accounts: widget.accountController.accounts,
        transaction: transaction,
      ),
    );
    if (!mounted || updated != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer updated.')),
    );
  }

  String _accountName(String accountId) {
    for (final account in widget.accountController.accounts) {
      if (account.id == accountId) return account.name;
    }
    return 'Unknown account';
  }

  String _transferDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _openReconciliationDetails(TransactionEntry transaction) async {
    final accountName = _accountName(transaction.accountId);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fact_check_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Reconciliation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transaction.isIncome ? '+' : '-'}${CurrencyFormatter.myr(transaction.amount)}',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _TransferDetailRow(label: 'Account', value: accountName),
            _TransferDetailRow(label: 'Date', value: _transferDate(transaction.date)),
            _TransferDetailRow(label: 'Note', value: transaction.title),
            const SizedBox(height: 8),
            const Text(
              'This is a balance correction. It affects the account balance but is excluded from income and expense reporting. Swipe it left to remove the adjustment.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done')),
        ],
      ),
    );
  }

  Future<void> _openEditTransaction(TransactionEntry transaction) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        controller: widget.controller,
        categories: widget.categoryController.categories,
        accounts: widget.accountController.accounts,
        transaction: transaction,
      ),
    );
  }

  Future<bool> _confirmDelete(TransactionEntry transaction) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete transaction?'),
            content: Text('${transaction.title} will be permanently removed.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteWithUndo(TransactionEntry transaction) async {
    await widget.controller.deleteTransaction(transaction.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${transaction.title} deleted.'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => widget.controller.restoreTransaction(transaction),
          ),
        ),
      );
  }
}

class _TransferDetailRow extends StatelessWidget {
  const _TransferDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.count, required this.total});

  final int count;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF826CEB), AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtered total', style: TextStyle(color: Color(0xFFDCD6FF))),
                const SizedBox(height: 5),
                Text(
                  CurrencyFormatter.myr(total, showSign: true),
                  style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(18)),
            child: Text('$count records', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.textSecondary, size: 42),
          SizedBox(height: 12),
          Text('No matching transactions', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 5),
          Text('Try another search or filter.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
