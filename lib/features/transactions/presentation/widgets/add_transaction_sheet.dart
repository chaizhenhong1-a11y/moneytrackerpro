import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_selector_style.dart';
import '../../../../core/widgets/app_form_style.dart';
import '../../../accounts/domain/entities/finance_account.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/transaction_category.dart';
import '../../domain/entities/transaction_entry.dart';

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    required this.controller,
    required this.categories,
    this.accounts = const [FinanceAccount.cash()],
    this.transaction,
    super.key,
  });

  final DashboardController controller;
  final List<TransactionCategory> categories;
  final List<FinanceAccount> accounts;
  final TransactionEntry? transaction;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  TransactionType _type = TransactionType.expense;
  late TransactionCategory _category;
  DateTime _date = DateTime.now();
  bool _isSaving = false;
  late String _accountId;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _accountId = transaction?.accountId ?? widget.accounts.first.id;
    _category = _defaultCategoryFor(transaction?.type ?? _type);
    _titleController = TextEditingController(text: transaction?.title ?? '');
    _amountController = TextEditingController(
      text: transaction == null ? '' : transaction.amount.toStringAsFixed(2),
    );
    if (transaction != null) {
      _type = transaction.type;
      _date = transaction.date;
      _category = widget.categories.firstWhere(
        (category) =>
            category.name == transaction.category &&
            category.type == transaction.type,
        orElse: () => _defaultCategoryFor(transaction.type),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  _isEditing ? 'Edit transaction' : 'Add transaction',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 22),
                SegmentedButton<TransactionType>(
                  style: AppSelectorStyle.segmentedButtonStyle(),
                  segments: const [
                    ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Expense'),
                        icon: Icon(Icons.north_east_rounded)),
                    ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Income'),
                        icon: Icon(Icons.south_west_rounded)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) => setState(() {
                    _type = selection.first;
                    _category = _defaultCategoryFor(_type);
                  }),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      _decoration('Transaction name', Icons.edit_rounded),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a transaction name'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('Amount', Icons.payments_outlined)
                      .copyWith(prefixText: 'RM '),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<TransactionCategory>(
                  key: ValueKey(_category.id),
                  initialValue: _category,
                  decoration: _decoration('Category', Icons.category_outlined),
                  items: _categoryOptions()
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Row(children: [
                              Icon(category.icon,
                                  color: category.color, size: 20),
                              const SizedBox(width: 10),
                              Text(category.name)
                            ]),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue:
                      widget.accounts.any((account) => account.id == _accountId)
                          ? _accountId
                          : widget.accounts.first.id,
                  decoration: _decoration(
                      'Account', Icons.account_balance_wallet_outlined),
                  items: widget.accounts
                      .map((account) => DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _accountId = value ?? _accountId),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration:
                        _decoration('Date', Icons.calendar_today_rounded),
                    child: Text('${_date.day}/${_date.month}/${_date.year}'),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isEditing ? 'Save changes' : 'Save transaction',
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

  List<TransactionCategory> _categoryOptions() {
    final active = widget.categories
        .where((category) => category.type == _type && !category.isArchived)
        .toList();
    if (!active.any((category) => category.id == _category.id) &&
        _category.type == _type) {
      active.add(_category);
    }
    return active;
  }

  TransactionCategory _defaultCategoryFor(TransactionType type) {
    return widget.categories.firstWhere(
      (category) => category.type == type && !category.isArchived,
      orElse: () => TransactionCategories.fallbackFor(type),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return AppFormStyle.decoration(
      label: label,
      icon: icon,
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      builder: AppSelectorStyle.datePickerBuilder,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final amount = double.parse(_amountController.text.trim());
    final transaction = widget.transaction;
    final saved = transaction == null
        ? await widget.controller.addTransaction(
            title: _titleController.text,
            amount: amount,
            type: _type,
            category: _category,
            date: _date,
            accountId: _accountId,
          )
        : await widget.controller.updateTransaction(
            id: transaction.id,
            title: _titleController.text,
            amount: amount,
            type: _type,
            category: _category,
            date: _date,
            accountId: _accountId,
          );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) Navigator.pop(context, true);
  }
}
