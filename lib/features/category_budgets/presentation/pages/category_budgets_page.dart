import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../controllers/category_budget_controller.dart';

class CategoryBudgetsPage extends StatelessWidget {
  const CategoryBudgetsPage({
    required this.controller,
    required this.categoryController,
    required this.dashboardController,
    super.key,
  });

  final CategoryBudgetController controller;
  final CategoryController categoryController;
  final DashboardController dashboardController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, categoryController, dashboardController]),
      builder: (context, _) {
        final categories = categoryController.categories
            .where((category) => category.type == TransactionType.expense)
            .toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Category budgets', style: TextStyle(fontWeight: FontWeight.w800))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              const Text('Set a monthly limit for each expense category. Transfer and reconciliation activity is excluded.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 18),
              for (final category in categories) ...[
                _BudgetCard(
                  name: category.name,
                  icon: category.icon,
                  color: category.color,
                  spent: _spentFor(category.name),
                  limit: controller.limitFor(category.id),
                  onTap: () => _editBudget(context, category.id, category.name),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }

  double _spentFor(String categoryName) {
    final now = DateTime.now();
    return dashboardController.transactions
        .where((item) =>
            item.countsAsExpense &&
            item.category == categoryName &&
            item.date.year == now.year &&
            item.date.month == now.month)
        .fold(0, (total, item) => total + item.amount);
  }

  Future<void> _editBudget(BuildContext context, String categoryId, String categoryName) async {
    final existing = controller.limitFor(categoryId);
    final textController = TextEditingController(text: existing == 0 ? '' : existing.toStringAsFixed(2));
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$categoryName budget'),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Monthly limit', prefixText: 'RM ', border: OutlineInputBorder()),
        ),
        actions: [
          if (existing > 0)
            TextButton(onPressed: () => Navigator.pop(dialogContext, 0.0), child: const Text('Remove')),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(textController.text.trim());
              if (parsed != null && parsed > 0) Navigator.pop(dialogContext, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (amount == null) return;
    await controller.setBudget(categoryId, amount);
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.spent,
    required this.limit,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final Color color;
  final double spent;
  final double limit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
    final over = limit > 0 && spent > limit;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color)),
                const SizedBox(width: 12),
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700))),
                Text(limit <= 0 ? 'Set budget' : CurrencyFormatter.myr(limit), style: TextStyle(fontWeight: FontWeight.w700, color: limit <= 0 ? AppColors.primary : null)),
              ]),
              if (limit > 0) ...[
                const SizedBox(height: 14),
                ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: ratio, minHeight: 8, backgroundColor: AppColors.background, color: over ? AppColors.expense : color)),
                const SizedBox(height: 8),
                Text(
                  over ? '${CurrencyFormatter.myr(spent - limit)} over budget' : '${CurrencyFormatter.myr(spent)} spent · ${CurrencyFormatter.myr(limit - spent)} left',
                  style: TextStyle(fontSize: 12, color: over ? AppColors.expense : AppColors.textSecondary, fontWeight: over ? FontWeight.w700 : FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
