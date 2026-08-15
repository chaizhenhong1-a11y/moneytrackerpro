import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../domain/entities/finance_account.dart';

class TransferFundsSheet extends StatefulWidget {
  const TransferFundsSheet({
    required this.controller,
    required this.accounts,
    this.transaction,
    super.key,
  });

  final DashboardController controller;
  final List<FinanceAccount> accounts;
  final TransactionEntry? transaction;

  @override
  State<TransferFundsSheet> createState() => _TransferFundsSheetState();
}

class _TransferFundsSheetState extends State<TransferFundsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _fromAccountId;
  late String _toAccountId;
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    if (transaction != null) {
      final pair = widget.controller.transferPairFor(transaction);
      TransactionEntry? outgoing;
      TransactionEntry? incoming;
      for (final item in pair) {
        if (item.isIncome) {
          incoming = item;
        } else {
          outgoing = item;
        }
      }
      _fromAccountId = outgoing?.accountId ?? widget.accounts.first.id;
      _toAccountId = incoming?.accountId ?? (widget.accounts.length > 1 ? widget.accounts[1].id : widget.accounts.first.id);
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _date = transaction.date;
      final generatedOut = outgoing == null ? '' : 'Transfer to ${_accountName(incoming?.accountId)}';
      final generatedIn = incoming == null ? '' : 'Transfer from ${_accountName(outgoing?.accountId)}';
      if (transaction.title != generatedOut && transaction.title != generatedIn) {
        _noteController.text = transaction.title;
      }
    } else {
      _fromAccountId = widget.accounts.first.id;
      _toAccountId = widget.accounts.length > 1 ? widget.accounts[1].id : widget.accounts.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
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
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 22),
                Text(widget.transaction == null ? 'Transfer funds' : 'Edit transfer', textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  widget.transaction == null
                      ? 'Move money between your accounts without changing income or spending totals.'
                      : 'Update both linked account entries together so balances stay in sync.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 22),
                DropdownButtonFormField<String>(
                  initialValue: _fromAccountId,
                  decoration: _decoration('From account', Icons.north_east_rounded),
                  items: widget.accounts.map((account) => DropdownMenuItem(value: account.id, child: Text(account.name))).toList(),
                  onChanged: (value) => setState(() => _fromAccountId = value ?? _fromAccountId),
                  validator: (_) => _fromAccountId == _toAccountId ? 'Choose a different source account' : null,
                ),
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
                    child: IconButton(
                      tooltip: 'Swap accounts',
                      onPressed: _swapAccounts,
                      icon: const Icon(Icons.swap_vert_rounded, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _toAccountId,
                  decoration: _decoration('To account', Icons.south_west_rounded),
                  items: widget.accounts.map((account) => DropdownMenuItem(value: account.id, child: Text(account.name))).toList(),
                  onChanged: (value) => setState(() => _toAccountId = value ?? _toAccountId),
                  validator: (_) => _fromAccountId == _toAccountId ? 'Choose a different destination account' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('Amount', Icons.payments_outlined).copyWith(prefixText: 'RM '),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) return 'Enter a valid amount greater than 0';
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
                    decoration: _decoration('Date', Icons.calendar_today_rounded),
                    child: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.swap_horiz_rounded),
                  label: Text(
                    _isSaving
                        ? (widget.transaction == null ? 'Transferring...' : 'Saving...')
                        : (widget.transaction == null ? 'Transfer funds' : 'Save changes'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    );
  }

  String _accountName(String? accountId) {
    if (accountId == null) return '';
    for (final account in widget.accounts) {
      if (account.id == accountId) return account.name;
    }
    return '';
  }

  void _swapAccounts() {
    setState(() {
      final current = _fromAccountId;
      _fromAccountId = _toAccountId;
      _toAccountId = current;
    });
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
    final from = widget.accounts.firstWhere((account) => account.id == _fromAccountId);
    final to = widget.accounts.firstWhere((account) => account.id == _toAccountId);
    setState(() => _isSaving = true);
    final amount = double.parse(_amountController.text.trim());
    final transaction = widget.transaction;
    final saved = transaction == null
        ? await widget.controller.transferFunds(
            fromAccountId: from.id,
            fromAccountName: from.name,
            toAccountId: to.id,
            toAccountName: to.name,
            amount: amount,
            date: _date,
            note: _noteController.text,
          )
        : await widget.controller.updateTransfer(
            transaction: transaction,
            fromAccountId: from.id,
            fromAccountName: from.name,
            toAccountId: to.id,
            toAccountName: to.name,
            amount: amount,
            date: _date,
            note: _noteController.text,
          );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.errorMessage ?? 'Unable to save the transfer.')),
      );
    }
  }
}
