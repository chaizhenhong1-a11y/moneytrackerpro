import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../domain/entities/finance_account.dart';
import '../widgets/reconcile_account_sheet.dart';
import '../widgets/transfer_funds_sheet.dart';
import 'account_statement_page.dart';

class AccountDetailPage extends StatelessWidget {
  const AccountDetailPage({
    required this.account,
    required this.dashboardController,
    required this.allAccounts,
    super.key,
  });

  final FinanceAccount account;
  final DashboardController dashboardController;
  final List<FinanceAccount> allAccounts;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: dashboardController,
      builder: (context, _) {
        final transactions = dashboardController.transactions
            .where((item) => item.accountId == account.id)
            .toList(growable: false)
          ..sort((a, b) => b.date.compareTo(a.date));
        final income = transactions
            .where((item) => item.countsAsIncome)
            .fold<double>(0, (sum, item) => sum + item.amount);
        final expenses = transactions
            .where((item) => item.countsAsExpense)
            .fold<double>(0, (sum, item) => sum + item.amount);
        final balance = transactions.fold<double>(
            0, (sum, item) => sum + item.signedAmount);
        final style = _style(account.type);

        return Scaffold(
          appBar: AppBar(
            title: Text(account.name,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Reconcile account',
                onPressed: () => _openReconciliation(context, balance),
                icon: const Icon(Icons.fact_check_outlined),
              ),
              IconButton(
                tooltip: 'Monthly statement',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => AccountStatementPage(
                      account: account,
                      dashboardController: dashboardController,
                    ),
                  ),
                ),
                icon: const Icon(Icons.calendar_month_outlined),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _AccountHero(
                account: account,
                balance: balance,
                transactionCount: transactions.length,
                icon: style.icon,
                color: style.color,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Total income',
                      amount: income,
                      icon: Icons.south_west_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Total spent',
                      amount: expenses,
                      icon: Icons.north_east_rounded,
                      color: AppColors.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Activity',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${transactions.length} ${transactions.length == 1 ? 'transaction' : 'transactions'}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (transactions.isEmpty)
                const _EmptyActivity()
              else
                ..._buildGroupedTransactions(context, transactions),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGroupedTransactions(
      BuildContext context, List<TransactionEntry> transactions) {
    final widgets = <Widget>[];
    DateTime? previousDay;

    for (final item in transactions) {
      final day = DateTime(item.date.year, item.date.month, item.date.day);
      if (previousDay != day) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 7, 4, 8),
            child: Text(
              _dateLabel(day),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
        previousDay = day;
      }
      widgets.add(
        _AccountTransactionTile(
          transaction: item,
          onTap: item.isTransfer
              ? () => _showTransferActions(context, item)
              : null,
        ),
      );
    }

    return widgets;
  }

  Future<void> _openReconciliation(
      BuildContext context, double bookBalance) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReconcileAccountSheet(
        account: account,
        bookBalance: bookBalance,
        controller: dashboardController,
      ),
    );
    if (!context.mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account reconciled successfully.')),
    );
  }

  Future<void> _showTransferActions(
      BuildContext context, TransactionEntry transaction) async {
    final pair = dashboardController.transferPairFor(transaction);
    if (pair.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'This transfer pair is incomplete and cannot be changed safely.')),
      );
      return;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Transfer actions'),
        content: Text(
          '${CurrencyFormatter.myr(transaction.amount)} is linked across both account records. '
          'Edit or cancel it as one transfer to keep balances in sync.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close')),
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogContext, 'edit'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'cancel'),
            child: const Text('Cancel transfer'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      await _editTransfer(context, transaction);
      return;
    }
    if (action != 'cancel') return;

    final removed = await dashboardController.cancelTransfer(transaction);
    if (!context.mounted) return;
    if (removed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(dashboardController.errorMessage ??
                'Unable to cancel the transfer.')),
      );
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Transfer cancelled.'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => dashboardController.restoreTransactions(removed),
          ),
        ),
      );
  }

  Future<void> _editTransfer(
      BuildContext context, TransactionEntry transaction) async {
    if (allAccounts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Add at least two accounts before editing a transfer.')),
      );
      return;
    }
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransferFundsSheet(
        controller: dashboardController,
        accounts: allAccounts,
        transaction: transaction,
      ),
    );
    if (!context.mounted || updated != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transfer updated.')),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static _AccountStyle _style(FinanceAccountType type) => switch (type) {
        FinanceAccountType.cash =>
          const _AccountStyle(Icons.payments_outlined, AppColors.success),
        FinanceAccountType.bank => const _AccountStyle(
            Icons.account_balance_outlined, AppColors.primary),
        FinanceAccountType.eWallet =>
          const _AccountStyle(Icons.phone_android_rounded, Color(0xFF5D9CEC)),
        FinanceAccountType.savings =>
          const _AccountStyle(Icons.savings_outlined, Color(0xFFE96CB5)),
      };
}

class _AccountHero extends StatelessWidget {
  const _AccountHero({
    required this.account,
    required this.balance,
    required this.transactionCount,
    required this.icon,
    required this.color,
  });

  final FinanceAccount account;
  final double balance;
  final int transactionCount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF826CEB), AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _typeName(account.type),
                      style: const TextStyle(
                          color: Color(0xFFDCD6FF), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Current balance',
              style: TextStyle(color: Color(0xFFDCD6FF), fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            CurrencyFormatter.myr(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '$transactionCount ${transactionCount == 1 ? 'record' : 'records'} linked to this account',
            style: const TextStyle(color: Color(0xFFDCD6FF), fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _typeName(FinanceAccountType type) => switch (type) {
        FinanceAccountType.cash => 'Cash',
        FinanceAccountType.bank => 'Bank account',
        FinanceAccountType.eWallet => 'E-Wallet',
        FinanceAccountType.savings => 'Savings',
      };
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 13),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.myr(amount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTransactionTile extends StatelessWidget {
  const _AccountTransactionTile({required this.transaction, this.onTap});

  final TransactionEntry transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: transaction.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(transaction.icon, color: transaction.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.category,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${transaction.isIncome ? '+' : '-'}${CurrencyFormatter.myr(transaction.amount)}',
                style: TextStyle(
                  color: transaction.isTransfer
                      ? AppColors.primary
                      : transaction.isIncome
                          ? AppColors.success
                          : AppColors.expense,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.receipt_long_outlined,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            const Text('No activity yet',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
              'Transactions assigned to this account will appear here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountStyle {
  const _AccountStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}
