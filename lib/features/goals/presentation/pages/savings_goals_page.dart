import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../accounts/domain/entities/finance_account.dart';
import '../../../accounts/presentation/controllers/account_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/savings_goal.dart';
import '../controllers/savings_goal_controller.dart';

class SavingsGoalsPage extends StatelessWidget {
  const SavingsGoalsPage({
    required this.controller,
    required this.accountController,
    required this.dashboardController,
    super.key,
  });

  final SavingsGoalController controller;
  final AccountController accountController;
  final DashboardController dashboardController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, accountController, dashboardController]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Savings goals', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'Add goal',
              onPressed: accountController.activeAccounts.isEmpty ? null : () => _showAddGoal(context),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: controller.goals.isEmpty
            ? const _EmptyGoals()
            : ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  _GoalSummary(
                    goalCount: controller.goals.length,
                    totalTarget: controller.goals.fold(0, (sum, goal) => sum + goal.targetAmount),
                  ),
                  const SizedBox(height: 18),
                  ...controller.goals.map((goal) {
                    final account = _accountFor(goal.accountId);
                    final saved = math.max(0.0, _accountBalance(goal.accountId)).toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GoalCard(
                        goal: goal,
                        accountName: account?.name ?? 'Unavailable account',
                        savedAmount: saved,
                        onDelete: () => _deleteGoal(context, goal),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  FinanceAccount? _accountFor(String id) {
    for (final account in accountController.accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  double _accountBalance(String accountId) => dashboardController.transactions
      .where((item) => item.accountId == accountId)
      .fold(0, (sum, item) => sum + item.signedAmount);

  Future<void> _showAddGoal(BuildContext context) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    var accountId = accountController.activeAccounts.first.id;
    var deadline = DateTime.now().add(const Duration(days: 180));
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 45, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 22),
                    const Text('Create savings goal', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Goal name', prefixIcon: Icon(Icons.flag_outlined), border: OutlineInputBorder()),
                      validator: (value) => value == null || value.trim().length < 2 ? 'Enter a goal name' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Target amount', prefixText: 'RM ', prefixIcon: Icon(Icons.savings_outlined), border: OutlineInputBorder()),
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');
                        return amount == null || amount <= 0 ? 'Enter a valid target amount' : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: accountId,
                      decoration: const InputDecoration(labelText: 'Linked savings account', border: OutlineInputBorder()),
                      items: accountController.activeAccounts
                          .map((account) => DropdownMenuItem(value: account.id, child: Text(account.name)))
                          .toList(),
                      onChanged: (value) => accountId = value ?? accountId,
                    ),
                    const SizedBox(height: 14),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(side: const BorderSide(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.event_outlined, color: AppColors.primary),
                      title: const Text('Target date'),
                      subtitle: Text('${deadline.day}/${deadline.month}/${deadline.year}'),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: deadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) setSheetState(() => deadline = picked);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final saved = await controller.addGoal(
                            name: nameController.text,
                            targetAmount: double.parse(amountController.text.trim()),
                            accountId: accountId,
                            deadline: deadline,
                          );
                          if (saved && sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                        child: const Text('Create goal', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    nameController.dispose();
    amountController.dispose();
  }

  Future<void> _deleteGoal(BuildContext context, SavingsGoal goal) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete savings goal?'),
            content: Text('${goal.name} will be removed. Your account transactions will not be changed.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (confirmed) await controller.deleteGoal(goal.id);
  }
}

class _GoalSummary extends StatelessWidget {
  const _GoalSummary({required this.goalCount, required this.totalTarget});
  final int goalCount;
  final double totalTarget;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF826CEB), AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Savings plan', style: TextStyle(color: Color(0xFFDCD6FF), fontSize: 12)),
        const SizedBox(height: 6),
        Text('$goalCount active ${goalCount == 1 ? 'goal' : 'goals'}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Combined target ${CurrencyFormatter.myr(totalTarget)}', style: const TextStyle(color: Color(0xFFDCD6FF))),
      ]),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.accountName, required this.savedAmount, required this.onDelete});
  final SavingsGoal goal;
  final String accountName;
  final double savedAmount;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount <= 0 ? 0.0 : (savedAmount / goal.targetAmount).clamp(0.0, 1.0).toDouble();
    final remaining = math.max(0.0, goal.targetAmount - savedAmount);
    final now = DateTime.now();
    final months = math.max(1, (goal.deadline.year - now.year) * 12 + goal.deadline.month - now.month + 1);
    final monthly = remaining / months;
    final completed = progress >= 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)), child: Icon(completed ? Icons.check_rounded : Icons.savings_outlined, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), const SizedBox(height: 3), Text(accountName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))])),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded), tooltip: 'Delete goal'),
          ]),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress, minHeight: 9, borderRadius: BorderRadius.circular(99), backgroundColor: AppColors.primarySoft),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${CurrencyFormatter.myr(savedAmount)} saved', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${(progress * 100).round()}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          Text(completed ? 'Goal reached' : '${CurrencyFormatter.myr(remaining)} remaining • Save about ${CurrencyFormatter.myr(monthly)}/month', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35)),
          const SizedBox(height: 4),
          Text('Target ${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.savings_outlined, size: 58, color: AppColors.primary),
          SizedBox(height: 14),
          Text('No savings goals yet', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          SizedBox(height: 7),
          Text('Create a goal and link it to an account to track progress automatically.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
        ]),
      ),
    );
  }
}
