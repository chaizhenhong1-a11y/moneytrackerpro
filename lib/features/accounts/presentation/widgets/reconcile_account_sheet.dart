import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/finance_account.dart';

class ReconcileAccountSheet extends StatefulWidget {
  const ReconcileAccountSheet({
    required this.account,
    required this.bookBalance,
    required this.controller,
    super.key,
  });

  final FinanceAccount account;
  final double bookBalance;
  final DashboardController controller;

  @override
  State<ReconcileAccountSheet> createState() => _ReconcileAccountSheetState();
}

class _ReconcileAccountSheetState extends State<ReconcileAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _actualBalanceController;
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _actualBalanceController = TextEditingController(
      text: widget.bookBalance.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _actualBalanceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? get _actualBalance => double.tryParse(_actualBalanceController.text.trim());
  double get _difference => (_actualBalance ?? widget.bookBalance) - widget.bookBalance;

  @override
  Widget build(BuildContext context) {
    final difference = _difference;
    final isMatched = difference.abs() < .005;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .92),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 34),
                const SizedBox(height: 10),
                const Text(
                  'Reconcile account',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Match ${widget.account.name} to the balance shown by your bank, wallet, or cash count.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 22),
                _BalanceComparison(
                  bookBalance: widget.bookBalance,
                  actualBalance: _actualBalance,
                  difference: difference,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _actualBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: _decoration('Actual balance', Icons.account_balance_wallet_outlined)
                      .copyWith(prefixText: 'RM '),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || !amount.isFinite) return 'Enter a valid account balance';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration('Note (optional)', Icons.notes_rounded),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: _decoration('Reconciliation date', Icons.calendar_today_rounded),
                    child: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _isSaving || isMatched ? null : _save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.done_all_rounded),
                  label: Text(isMatched ? 'Already reconciled' : 'Create adjustment'),
                ),
                const SizedBox(height: 10),
                const Text(
                  'The adjustment changes the real account balance, but is excluded from income, expenses, budgets, and statistics.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final actualBalance = _actualBalance;
    if (actualBalance == null) return;

    setState(() => _isSaving = true);
    final saved = await widget.controller.reconcileAccount(
      accountId: widget.account.id,
      accountName: widget.account.name,
      bookBalance: widget.bookBalance,
      actualBalance: actualBalance,
      date: _date,
      note: _noteController.text,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) {
      Navigator.pop(context, true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.controller.errorMessage ?? 'Unable to reconcile this account.')),
    );
  }
}

class _BalanceComparison extends StatelessWidget {
  const _BalanceComparison({
    required this.bookBalance,
    required this.actualBalance,
    required this.difference,
  });

  final double bookBalance;
  final double? actualBalance;
  final double difference;

  @override
  Widget build(BuildContext context) {
    final color = difference.abs() < .005
        ? AppColors.success
        : difference > 0
            ? AppColors.primary
            : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _BalanceValue(label: 'Book balance', amount: bookBalance)),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceValue(
                  label: 'Actual balance',
                  amount: actualBalance ?? bookBalance,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                const Text('Difference', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  '${difference >= 0 ? '+' : '-'}${CurrencyFormatter.myr(difference.abs())}',
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceValue extends StatelessWidget {
  const _BalanceValue({required this.label, required this.amount, this.alignEnd = false});

  final String label;
  final double amount;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.myr(amount),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
