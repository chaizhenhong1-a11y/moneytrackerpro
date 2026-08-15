import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../controllers/settings_controller.dart';
import '../../../backup/presentation/pages/data_backup_page.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../accounts/presentation/controllers/account_controller.dart';
import '../../../accounts/presentation/pages/accounts_page.dart';
import '../../../categories/presentation/controllers/category_controller.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../../category_budgets/presentation/controllers/category_budget_controller.dart';
import '../../../category_budgets/presentation/pages/category_budgets_page.dart';
import '../../../recurring/presentation/controllers/recurring_transaction_controller.dart';
import '../../../goals/presentation/controllers/savings_goal_controller.dart';
import '../../../debts/presentation/controllers/debt_controller.dart';
import '../../../debts/presentation/pages/debts_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.controller,
    required this.dashboardController,
    required this.accountController,
    required this.recurringController,
    required this.savingsGoalController,
    required this.categoryController,
    required this.categoryBudgetController,
    required this.debtController,
    super.key,
  });

  final SettingsController controller;
  final DashboardController dashboardController;
  final AccountController accountController;
  final RecurringTransactionController recurringController;
  final SavingsGoalController savingsGoalController;
  final CategoryController categoryController;
  final CategoryBudgetController categoryBudgetController;
  final DebtController debtController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, dashboardController, accountController, categoryController, debtController]),
      builder: (context, _) {
        final settings = controller.settings;
        return Scaffold(
          appBar: AppBar(title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800))),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _ProfileHeader(name: settings.displayName),
              const SizedBox(height: 22),
              const _GroupLabel('FINANCIAL PREFERENCES'),
              const SizedBox(height: 9),
              Card(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Accounts',
                      subtitle: '${accountController.accounts.length} connected accounts',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => AccountsPage(
                            controller: accountController,
                            dashboardController: dashboardController,
                            savingsGoalController: savingsGoalController,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 64),
                    _SettingsTile(
                      icon: Icons.credit_card_outlined,
                      title: 'Debts & liabilities',
                      subtitle: '${debtController.activeCount} active · ${CurrencyFormatter.myr(debtController.totalOutstanding)}',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (context) => DebtsPage(controller: debtController)),
                      ),
                    ),
                    const Divider(height: 1, indent: 64),
                    _SettingsTile(
                      icon: Icons.category_outlined,
                      title: 'Categories',
                      subtitle: '${categoryController.activeCategories.length} active categories',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => CategoriesPage(
                            controller: categoryController,
                            dashboardController: dashboardController,
                            recurringController: recurringController,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 64),
                    _SettingsTile(
                      icon: Icons.donut_small_rounded,
                      title: 'Category budgets',
                      subtitle: '${categoryBudgetController.budgets.length} monthly limits',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => CategoryBudgetsPage(
                            controller: categoryBudgetController,
                            categoryController: categoryController,
                            dashboardController: dashboardController,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 64),
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal details',
                      subtitle: settings.displayName,
                      onTap: () => _showEditProfile(context),
                    ),
                    const Divider(height: 1, indent: 64),
                    _SettingsTile(
                      icon: Icons.flag_outlined,
                      title: 'Monthly budget',
                      subtitle: CurrencyFormatter.myr(settings.monthlyBudget),
                      onTap: () => _showEditProfile(context),
                    ),
                    const Divider(height: 1, indent: 64),
                    SwitchListTile(
                      secondary: const _SettingsIcon(icon: Icons.notifications_active_outlined),
                      title: const Text('Budget alerts', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Warn me when spending approaches the limit'),
                      value: settings.budgetAlertsEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: controller.setBudgetAlerts,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _GroupLabel('APPLICATION'),
              const SizedBox(height: 9),
              Card(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.cloud_sync_outlined,
                      title: 'Data & backup',
                      subtitle: '${dashboardController.transactions.length} saved transactions',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => DataBackupPage(
                            dashboardController: dashboardController,
                            settingsController: controller,
                            accountController: accountController,
                            recurringController: recurringController,
                            savingsGoalController: savingsGoalController,
                            categoryController: categoryController,
                            categoryBudgetController: categoryBudgetController,
                            debtController: debtController,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 64),
                    const _SettingsTile(icon: Icons.currency_exchange_rounded, title: 'Currency', subtitle: 'Malaysian Ringgit (MYR)'),
                    const Divider(height: 1, indent: 64),
                    const _SettingsTile(icon: Icons.language_rounded, title: 'Language', subtitle: 'English'),
                    const Divider(height: 1, indent: 64),
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About MoneyTracker Pro',
                      subtitle: 'Version 1.0.0',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'MoneyTracker Pro',
                        applicationVersion: '1.0.0',
                        applicationLegalese: 'Personal finance, made clear.',
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(controller.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.expense)),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditProfile(BuildContext context) async {
    final nameController = TextEditingController(text: controller.settings.displayName);
    final budgetController = TextEditingController(text: controller.settings.monthlyBudget.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 45, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 22),
                const Text('Edit profile', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 22),
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Display name', prefixIcon: Icon(Icons.person_outline_rounded), border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().length < 2 ? 'Enter at least 2 characters' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: budgetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monthly budget', prefixText: 'RM ', prefixIcon: Icon(Icons.flag_outlined), border: OutlineInputBorder()),
                  validator: (value) {
                    final amount = double.tryParse(value?.trim() ?? '');
                    return amount == null || amount <= 0 ? 'Enter a valid budget greater than 0' : null;
                  },
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final saved = await controller.updateProfile(
                      displayName: nameController.text,
                      monthlyBudget: double.parse(budgetController.text.trim()),
                    );
                    if (saved && sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    nameController.dispose();
    budgetController.dispose();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(width: 68, height: 68, decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 39)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)), const SizedBox(height: 5), const Text('MoneyTracker Pro member', style: TextStyle(color: AppColors.textSecondary))])),
            const Icon(Icons.verified_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _SettingsIcon(icon: icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primary, size: 20));
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(left: 4), child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .8)));
  }
}
