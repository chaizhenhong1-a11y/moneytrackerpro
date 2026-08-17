import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../recurring/presentation/controllers/recurring_transaction_controller.dart';
import '../../../transactions/domain/entities/transaction_category.dart';
import '../../../transactions/domain/entities/transaction_entry.dart';
import '../controllers/category_controller.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({
    required this.controller,
    required this.dashboardController,
    required this.recurringController,
    super.key,
  });

  final CategoryController controller;
  final DashboardController dashboardController;
  final RecurringTransactionController recurringController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Categories',
              style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'Add category',
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                children: [
                  const _HintCard(),
                  const SizedBox(height: 22),
                  _CategorySection(
                    title: 'EXPENSE',
                    categories: controller.categories
                        .where((category) =>
                            category.type == TransactionType.expense)
                        .toList(),
                    onEdit: (category) =>
                        _openEditor(context, category: category),
                    onArchive: (category) => controller.setArchived(
                        category.id, !category.isArchived),
                  ),
                  const SizedBox(height: 24),
                  _CategorySection(
                    title: 'INCOME',
                    categories: controller.categories
                        .where((category) =>
                            category.type == TransactionType.income)
                        .toList(),
                    onEdit: (category) =>
                        _openEditor(context, category: category),
                    onArchive: (category) => controller.setArchived(
                        category.id, !category.isArchived),
                  ),
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.expense),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context,
      {TransactionCategory? category}) async {
    final result = await showModalBottomSheet<_CategoryDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryEditorSheet(category: category),
    );
    if (result == null || !context.mounted) return;

    if (category == null) {
      await controller.addCategory(
        name: result.name,
        type: result.type,
        icon: result.icon,
        color: result.color,
      );
      return;
    }

    final oldName = category.name;
    final updated = category.copyWith(
      name: result.name,
      icon: result.icon,
      color: result.color,
    );
    final saved = await controller.updateCategory(
      id: category.id,
      name: result.name,
      icon: result.icon,
      color: result.color,
    );
    if (!saved || oldName == result.name) return;

    await dashboardController.renameCategoryReferences(
        oldName: oldName, category: updated);
    await recurringController.renameCategoryReferences(
        oldName: oldName, newName: result.name);
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.categories,
    required this.onEdit,
    required this.onArchive,
  });

  final String title;
  final List<TransactionCategory> categories;
  final ValueChanged<TransactionCategory> onEdit;
  final ValueChanged<TransactionCategory> onArchive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 9),
        Card(
          child: Column(
            children: [
              for (var index = 0; index < categories.length; index++) ...[
                _CategoryTile(
                  category: categories[index],
                  onEdit: () => onEdit(categories[index]),
                  onArchive: () => onArchive(categories[index]),
                ),
                if (index != categories.length - 1)
                  const Divider(height: 1, indent: 64),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onArchive,
  });

  final TransactionCategory category;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(category.icon, color: category.color, size: 21),
      ),
      title: Text(
        category.name,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: category.isArchived ? AppColors.textSecondary : null,
        ),
      ),
      subtitle: Text(category.isArchived
          ? 'Inactive'
          : category.isSystem
              ? 'Built-in category'
              : 'Custom category'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => value == 'edit' ? onEdit() : onArchive(),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(
            value: 'archive',
            child: Text(category.isArchived ? 'Restore' : 'Deactivate'),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(22)),
      child: const Row(
        children: [
          Icon(Icons.category_rounded, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Create categories that match your life. Inactive categories stay on historical records but are hidden from new transactions.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({this.category});
  final TransactionCategory? category;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  static const _icons = <IconData>[
    Icons.restaurant_rounded,
    Icons.directions_car_rounded,
    Icons.shopping_bag_rounded,
    Icons.home_rounded,
    Icons.favorite_rounded,
    Icons.sports_esports_rounded,
    Icons.flight_rounded,
    Icons.school_rounded,
    Icons.savings_rounded,
    Icons.work_rounded,
    Icons.pets_rounded,
    Icons.more_horiz_rounded,
  ];
  static const _colors = <Color>[
    Color(0xFF7057E8),
    Color(0xFFFF8B5C),
    Color(0xFF5D9CEC),
    Color(0xFFE96CB5),
    Color(0xFFF4B740),
    Color(0xFF21B978),
    Color(0xFF7C8BA1),
    Color(0xFF35A67B),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late TransactionType _type;
  late IconData _icon;
  late Color _color;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _type = category?.type ?? TransactionType.expense;
    _icon = category?.icon ?? _icons.first;
    _color = category?.color ?? _colors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 22),
                Text(widget.category == null ? 'New category' : 'Edit category',
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 22),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                        value: TransactionType.expense, label: Text('Expense')),
                    ButtonSegment(
                        value: TransactionType.income, label: Text('Income')),
                  ],
                  selected: {_type},
                  onSelectionChanged: widget.category == null
                      ? (value) => setState(() => _type = value.first)
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Category name',
                      prefixIcon: Icon(Icons.edit_rounded),
                      border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Enter at least 2 characters'
                      : null,
                ),
                const SizedBox(height: 18),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Icon',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _icons
                      .map((icon) => _ChoiceCircle(
                            selected: icon.codePoint == _icon.codePoint,
                            onTap: () => setState(() => _icon = icon),
                            child: Icon(icon, color: _color),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 18),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Color',
                        style: TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _colors
                      .map((color) => _ChoiceCircle(
                            selected: color.toARGB32() == _color.toARGB32(),
                            onTap: () => setState(() => _color = color),
                            child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                    color: color, shape: BoxShape.circle)),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(
                        widget.category == null
                            ? 'Create category'
                            : 'Save changes',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _CategoryDraft(
          name: _nameController.text.trim(),
          type: _type,
          icon: _icon,
          color: _color),
    );
  }
}

class _ChoiceCircle extends StatelessWidget {
  const _ChoiceCircle(
      {required this.selected, required this.onTap, required this.child});
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1),
        ),
        child: child,
      ),
    );
  }
}

class _CategoryDraft {
  const _CategoryDraft(
      {required this.name,
      required this.type,
      required this.icon,
      required this.color});
  final String name;
  final TransactionType type;
  final IconData icon;
  final Color color;
}
