import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../accounts/domain/entities/finance_account.dart';
import '../../../transactions/domain/entities/transaction_category.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../../domain/entities/recurring_transaction_rule.dart';
import '../controllers/recurring_transaction_controller.dart';

class AddRecurringRuleSheet extends StatefulWidget {
  const AddRecurringRuleSheet({
    required this.controller,
    required this.accounts,
    required this.categories,
    this.initialRule,
    super.key,
  });

  final RecurringTransactionController controller;
  final List<FinanceAccount> accounts;
  final List<TransactionCategory> categories;
  final RecurringTransactionRule? initialRule;

  @override
  State<AddRecurringRuleSheet> createState() => _AddRecurringRuleSheetState();
}

class _AddRecurringRuleSheetState extends State<AddRecurringRuleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  late TransactionCategory _category;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  DateTime _firstDueDate = DateTime.now();
  late String _accountId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final rule = widget.initialRule;
    _category = _defaultCategoryFor(rule?.type ?? _type);
    if (rule == null) {
      _accountId = widget.accounts.first.id;
      return;
    }

    _titleController.text = rule.title;
    _amountController.text = rule.amount.toStringAsFixed(2);
    _type = rule.type;
    _category = widget.categories.firstWhere(
      (item) => item.name == rule.category && item.type == rule.type,
      orElse: () => _defaultCategoryFor(rule.type),
    );
    _frequency = rule.frequency;
    _firstDueDate = rule.nextDueDate;
    _accountId = widget.accounts.any((account) => account.id == rule.accountId)
        ? rule.accountId
        : widget.accounts.first.id;
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
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.initialRule == null ? 'New recurring transaction' : 'Edit recurring transaction',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 22),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                    ButtonSegment(value: TransactionType.income, label: Text('Income')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) => setState(() {
                    _type = selection.first;
                    _category = _defaultCategoryFor(_type);
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: _decoration('Name', Icons.edit_rounded),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('Amount', Icons.payments_outlined).copyWith(prefixText: 'RM '),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    return amount == null || amount <= 0 ? 'Enter a valid amount' : null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<TransactionCategory>(
                  initialValue: _category,
                  decoration: _decoration('Category', Icons.category_outlined),
                  items: _categoryOptions()
                      .map((category) => DropdownMenuItem(value: category, child: Text(category.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _accountId,
                  decoration: _decoration('Account', Icons.account_balance_wallet_outlined),
                  items: widget.accounts
                      .map((account) => DropdownMenuItem(value: account.id, child: Text(account.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _accountId = value ?? _accountId),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<RecurringFrequency>(
                  initialValue: _frequency,
                  decoration: _decoration('Repeat', Icons.repeat_rounded),
                  items: const [
                    DropdownMenuItem(value: RecurringFrequency.weekly, child: Text('Weekly')),
                    DropdownMenuItem(value: RecurringFrequency.monthly, child: Text('Monthly')),
                    DropdownMenuItem(value: RecurringFrequency.yearly, child: Text('Yearly')),
                  ],
                  onChanged: (value) => setState(() => _frequency = value ?? _frequency),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: _decoration(
                      widget.initialRule == null ? 'First due date' : 'Next due date',
                      Icons.event_repeat_rounded,
                    ),
                    child: Text('${_firstDueDate.day}/${_firstDueDate.month}/${_firstDueDate.year}'),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          widget.initialRule == null ? 'Create recurring rule' : 'Save changes',
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
    if (!active.any((category) => category.id == _category.id) && _category.type == _type) {
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

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstDueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _firstDueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final rule = widget.initialRule;
    final saved = rule == null
        ? await widget.controller.addRule(
            title: _titleController.text,
            amount: double.parse(_amountController.text.trim()),
            type: _type,
            category: _category,
            accountId: _accountId,
            frequency: _frequency,
            firstDueDate: _firstDueDate,
          )
        : await widget.controller.updateRule(
            id: rule.id,
            title: _titleController.text,
            amount: double.parse(_amountController.text.trim()),
            type: _type,
            category: _category,
            accountId: _accountId,
            frequency: _frequency,
            nextDueDate: _firstDueDate,
          );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) Navigator.pop(context, true);
  }
}
