import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../domain/entities/finance_account.dart';

class AccountStatementPage extends StatefulWidget {
  const AccountStatementPage({
    required this.account,
    required this.dashboardController,
    super.key,
  });

  final FinanceAccount account;
  final DashboardController dashboardController;

  @override
  State<AccountStatementPage> createState() => _AccountStatementPageState();
}

class _AccountStatementPageState extends State<AccountStatementPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.dashboardController,
      builder: (context, _) {
        final all = widget.dashboardController.transactions
            .where((item) => item.accountId == widget.account.id)
            .toList(growable: false);
        final start = DateTime(_month.year, _month.month);
        final end = DateTime(_month.year, _month.month + 1);
        final openingBalance = all
            .where((item) => item.date.isBefore(start))
            .fold<double>(0, (sum, item) => sum + item.signedAmount);
        final period = all
            .where(
                (item) => !item.date.isBefore(start) && item.date.isBefore(end))
            .toList(growable: false)
          ..sort((a, b) => b.date.compareTo(a.date));
        final income = period
            .where((item) => item.countsAsIncome)
            .fold<double>(0, (sum, item) => sum + item.amount);
        final expenses = period
            .where((item) => item.countsAsExpense)
            .fold<double>(0, (sum, item) => sum + item.amount);
        final transferIn = period
            .where((item) => item.isTransfer && item.isIncome)
            .fold<double>(0, (sum, item) => sum + item.amount);
        final transferOut = period
            .where((item) => item.isTransfer && !item.isIncome)
            .fold<double>(0, (sum, item) => sum + item.amount);
        final reconciliation = period
            .where((item) => item.isReconciliation)
            .fold<double>(0, (sum, item) => sum + item.signedAmount);
        final periodMovement =
            period.fold<double>(0, (sum, item) => sum + item.signedAmount);
        final closingBalance = openingBalance + periodMovement;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Monthly statement',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _MonthSelector(
                month: _month,
                onPrevious: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
                canGoNext: _canGoNext,
              ),
              const SizedBox(height: 14),
              _StatementHero(
                accountName: widget.account.name,
                month: _month,
                openingBalance: openingBalance,
                closingBalance: closingBalance,
              ),
              const SizedBox(height: 16),
              _MovementGrid(
                income: income,
                expenses: expenses,
                transferIn: transferIn,
                transferOut: transferOut,
                reconciliation: reconciliation,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text('Statement activity',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ),
                  Text(
                    '${period.length} ${period.length == 1 ? 'record' : 'records'}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (period.isEmpty)
                const _EmptyStatement()
              else
                ...period.map(
                    (item) => _StatementTransactionTile(transaction: item)),
            ],
          ),
        );
      },
    );
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  void _changeMonth(int delta) {
    if (delta > 0 && !_canGoNext) return;
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded)),
            Expanded(
              child: Column(
                children: [
                  Text(_monthName(month.month),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('${month.year}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementHero extends StatelessWidget {
  const _StatementHero({
    required this.accountName,
    required this.month,
    required this.openingBalance,
    required this.closingBalance,
  });

  final String accountName;
  final DateTime month;
  final double openingBalance;
  final double closingBalance;

  @override
  Widget build(BuildContext context) {
    final change = closingBalance - openingBalance;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF826CEB), AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(accountName,
              style: const TextStyle(
                  color: Color(0xFFDCD6FF), fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(
            '${_monthName(month.month)} ${month.year}',
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                  child:
                      _BalancePoint(label: 'Opening', amount: openingBalance)),
              const Icon(Icons.arrow_forward_rounded,
                  color: Color(0xFFDCD6FF), size: 18),
              const SizedBox(width: 12),
              Expanded(
                  child: _BalancePoint(
                      label: 'Closing',
                      amount: closingBalance,
                      alignEnd: true)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  change >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Net account movement  ${change >= 0 ? '+' : '-'}${CurrencyFormatter.myr(change.abs())}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalancePoint extends StatelessWidget {
  const _BalancePoint(
      {required this.label, required this.amount, this.alignEnd = false});
  final String label;
  final double amount;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFFDCD6FF), fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.myr(amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _MovementGrid extends StatelessWidget {
  const _MovementGrid({
    required this.income,
    required this.expenses,
    required this.transferIn,
    required this.transferOut,
    required this.reconciliation,
  });

  final double income;
  final double expenses;
  final double transferIn;
  final double transferOut;
  final double reconciliation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _MovementCard(
                    label: 'Income',
                    amount: income,
                    icon: Icons.south_west_rounded,
                    color: AppColors.success)),
            const SizedBox(width: 12),
            Expanded(
                child: _MovementCard(
                    label: 'Expenses',
                    amount: expenses,
                    icon: Icons.north_east_rounded,
                    color: AppColors.expense)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _MovementCard(
                    label: 'Transfer in',
                    amount: transferIn,
                    icon: Icons.call_received_rounded,
                    color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(
                child: _MovementCard(
                    label: 'Transfer out',
                    amount: transferOut,
                    icon: Icons.call_made_rounded,
                    color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: 12),
        _MovementCard(
          label: 'Reconciliation adjustment',
          amount: reconciliation.abs(),
          icon: Icons.fact_check_outlined,
          color: reconciliation < 0 ? AppColors.expense : AppColors.primary,
          prefix: reconciliation == 0 ? '' : (reconciliation > 0 ? '+' : '-'),
        ),
      ],
    );
  }
}

class _MovementCard extends StatelessWidget {
  const _MovementCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    this.prefix = '',
  });
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)),
                  const SizedBox(height: 3),
                  Text(
                    '$prefix${CurrencyFormatter.myr(amount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatementTransactionTile extends StatelessWidget {
  const _StatementTransactionTile({required this.transaction});
  final TransactionEntry transaction;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: transaction.color.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(transaction.icon, color: transaction.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.category} · ${_dateLabel(transaction.date)}',
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
    );
  }
}

class _EmptyStatement extends StatelessWidget {
  const _EmptyStatement();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.calendar_view_month_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 13),
            const Text('No activity this month',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
              'The opening and closing balances still reflect activity from earlier months.',
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

String _monthName(int month) => const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month - 1];

String _dateLabel(DateTime date) {
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
    'Dec'
  ];
  return '${date.day} ${months[date.month - 1]}';
}
