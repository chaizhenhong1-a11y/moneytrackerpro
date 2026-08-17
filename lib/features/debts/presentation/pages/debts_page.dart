import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_action_style.dart';
import '../../../../core/widgets/app_form_style.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/debt.dart';
import '../controllers/debt_controller.dart';
import 'debt_payoff_planner_page.dart';

class DebtsPage extends StatelessWidget {
  const DebtsPage({required this.controller, super.key});

  final DebtController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Debts & liabilities'),
          actions: [
            IconButton(
              tooltip: 'Payoff planner',
              icon: const Icon(Icons.route_outlined),
              onPressed: controller.debts
                      .where((debt) => !debt.isPaidOff)
                      .isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              DebtPayoffPlannerPage(debts: controller.debts),
                        ),
                      ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showDebtSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add debt'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            _SummaryCard(controller: controller),
            const SizedBox(height: 20),
            if (controller.debts.isEmpty)
              AppStateView.empty(
                title: 'No debts to manage',
                message: 'If you have a credit card, loan, or other liability, '
                    'add it here so net worth and payoff planning stay accurate.',
                icon: Icons.credit_card_off_outlined,
                actionLabel: 'Add a debt',
                onAction: () => _showDebtSheet(context),
              )
            else
              ...controller.debts.map((debt) => _DebtCard(
                    debt: debt,
                    onTap: () => _showDebtSheet(context, debt: debt),
                    onPayment: () => _showPaymentSheet(context, debt),
                    onDelete: () => _delete(context, debt),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Debt debt) async {
    final confirmed = await AppConfirmDialog.destructive(
      context,
      title: 'Delete debt?',
      message:
          '${debt.name} will be removed from liability tracking and future '
          'net-worth calculations.',
      confirmLabel: 'Delete',
    );
    if (confirmed) await controller.deleteDebt(debt.id);
  }

  Future<void> _showPaymentSheet(BuildContext context, Debt debt) async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Record payment · ${debt.name}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              TextFormField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: AppFormStyle.decoration(
                  label: 'Payment amount',
                  prefixText: 'RM ',
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  if (amount > debt.currentBalance) {
                    return 'Payment exceeds outstanding balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: AppActionStyle.compactPrimary(),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final saved = await controller.recordPayment(
                          debt.id, double.parse(amountController.text.trim()));
                      if (saved && sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                    child: const Text('Save payment'),
                  )),
            ]),
          ),
        ),
      ),
    );
    amountController.dispose();
  }

  Future<void> _showDebtSheet(BuildContext context, {Debt? debt}) async {
    final nameController = TextEditingController(text: debt?.name ?? '');
    final originalController = TextEditingController(
        text: debt?.originalAmount.toStringAsFixed(2) ?? '');
    final balanceController = TextEditingController(
        text: debt?.currentBalance.toStringAsFixed(2) ?? '');
    final interestController = TextEditingController(
        text: debt?.interestRate.toStringAsFixed(2) ?? '');
    var type = debt?.type ?? DebtType.creditCard;
    var dueDate =
        debt?.dueDate ?? DateTime.now().add(const Duration(days: 365));
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30))),
              child: Form(
                key: formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(debt == null ? 'Add debt' : 'Edit debt',
                      style: const TextStyle(
                          fontSize: 21, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 18),
                  TextFormField(
                      controller: nameController,
                      decoration: AppFormStyle.decoration(label: 'Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter a name'
                              : null),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DebtType>(
                    initialValue: type,
                    decoration: AppFormStyle.decoration(label: 'Debt type'),
                    items: DebtType.values
                        .map((item) => DropdownMenuItem(
                            value: item, child: Text(_typeLabel(item))))
                        .toList(),
                    onChanged: (value) =>
                        setSheetState(() => type = value ?? type),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: TextFormField(
                            controller: originalController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: AppFormStyle.decoration(
                              label: 'Original amount',
                              prefixText: 'RM ',
                            ),
                            validator: _positiveAmountValidator)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextFormField(
                            controller: balanceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: AppFormStyle.decoration(
                              label: 'Outstanding',
                              prefixText: 'RM ',
                            ),
                            validator: _nonNegativeAmountValidator)),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: interestController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: AppFormStyle.decoration(
                        label: 'Interest rate (APR)',
                        suffixText: '%',
                      ),
                      validator: _nonNegativeAmountValidator),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined,
                        color: AppColors.primary),
                    title: const Text('Target payoff / due date'),
                    subtitle:
                        Text('${dueDate.day}/${dueDate.month}/${dueDate.year}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                          context: sheetContext,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDate: dueDate);
                      if (picked != null) setSheetState(() => dueDate = picked);
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final original =
                              double.parse(originalController.text.trim());
                          final outstanding =
                              double.parse(balanceController.text.trim());
                          if (outstanding > original) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Outstanding balance cannot exceed original amount.')));
                            return;
                          }
                          final next = Debt(
                            id: debt?.id ?? '',
                            name: nameController.text.trim(),
                            type: type,
                            originalAmount: original,
                            currentBalance: outstanding,
                            interestRate:
                                double.parse(interestController.text.trim()),
                            dueDate: dueDate,
                          );
                          final saved = debt == null
                              ? await controller.addDebt(
                                  name: next.name,
                                  type: next.type,
                                  originalAmount: next.originalAmount,
                                  currentBalance: next.currentBalance,
                                  interestRate: next.interestRate,
                                  dueDate: next.dueDate)
                              : await controller.updateDebt(next);
                          if (saved && sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        child: Text(debt == null ? 'Add debt' : 'Save changes'),
                      )),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
    nameController.dispose();
    originalController.dispose();
    balanceController.dispose();
    interestController.dispose();
  }

  static String? _positiveAmountValidator(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    return amount == null || amount <= 0 ? 'Enter a valid amount' : null;
  }

  static String? _nonNegativeAmountValidator(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    return amount == null || amount < 0 ? 'Enter 0 or more' : null;
  }
}

String _typeLabel(DebtType type) => switch (type) {
      DebtType.creditCard => 'Credit card',
      DebtType.personalLoan => 'Personal loan',
      DebtType.carLoan => 'Car loan',
      DebtType.mortgage => 'Mortgage',
      DebtType.other => 'Other',
    };

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});
  final DebtController controller;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(28)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total outstanding',
              style: TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(CurrencyFormatter.myr(controller.totalOutstanding),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
              '${controller.activeCount} active ${controller.activeCount == 1 ? 'liability' : 'liabilities'}',
              style: const TextStyle(color: Colors.white70)),
        ]),
      );
}

class _DebtCard extends StatelessWidget {
  const _DebtCard(
      {required this.debt,
      required this.onTap,
      required this.onPayment,
      required this.onDelete});
  final Debt debt;
  final VoidCallback onTap;
  final VoidCallback onPayment;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(debt.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(
                        '${_typeLabel(debt.type)} · ${debt.interestRate.toStringAsFixed(2)}% APR',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ])),
              Text(CurrencyFormatter.myr(debt.currentBalance),
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: debt.isPaidOff
                          ? AppColors.success
                          : AppColors.expense)),
            ]),
            const SizedBox(height: 13),
            ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                    value: debt.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.border)),
            const SizedBox(height: 8),
            Text(
                '${(debt.progress * 100).toStringAsFixed(0)}% repaid · Due ${debt.dueDate.day}/${debt.dueDate.month}/${debt.dueDate.year}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 10),
            Row(children: [
              TextButton.icon(
                  onPressed: onPayment,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Payment')),
              const Spacer(),
              IconButton(
                  onPressed: onTap,
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined)),
              IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.expense)),
            ]),
          ]),
        ),
      );
}
