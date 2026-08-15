import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../features/dashboard/data/dashboard_demo_data.dart';
import '../features/categories/data/repositories/local_category_repository.dart';
import '../features/categories/presentation/controllers/category_controller.dart';
import '../features/category_budgets/data/repositories/local_category_budget_repository.dart';
import '../features/category_budgets/presentation/controllers/category_budget_controller.dart';
import '../features/accounts/data/repositories/local_account_repository.dart';
import '../features/accounts/presentation/controllers/account_controller.dart';
import '../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/statistics/presentation/pages/statistics_page.dart';
import '../features/settings/data/repositories/local_settings_repository.dart';
import '../features/recurring/data/repositories/local_recurring_transaction_repository.dart';
import '../features/goals/data/repositories/local_savings_goal_repository.dart';
import '../features/debts/data/repositories/local_debt_repository.dart';
import '../features/debts/presentation/controllers/debt_controller.dart';
import '../features/goals/presentation/controllers/savings_goal_controller.dart';
import '../features/recurring/presentation/controllers/recurring_transaction_controller.dart';
import '../features/settings/presentation/controllers/settings_controller.dart';
import '../features/settings/presentation/pages/profile_page.dart';
import '../features/transactions/data/repositories/local_transaction_repository.dart';
import '../features/transactions/presentation/pages/transactions_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final DashboardController _controller;
  late final SettingsController _settingsController;
  late final AccountController _accountController;
  late final RecurringTransactionController _recurringController;
  late final SavingsGoalController _savingsGoalController;
  late final DebtController _debtController;
  late final CategoryController _categoryController;
  late final CategoryBudgetController _categoryBudgetController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final transactionRepository = LocalTransactionRepository(seed: DashboardDemoData.transactions);
    _controller = DashboardController(transactionRepository);
    _settingsController = SettingsController(LocalSettingsRepository());
    _accountController = AccountController(LocalAccountRepository());
    _categoryController = CategoryController(LocalCategoryRepository());
    _categoryBudgetController = CategoryBudgetController(LocalCategoryBudgetRepository());
    _recurringController = RecurringTransactionController(
      LocalRecurringTransactionRepository(),
      transactionRepository,
      _categoryController,
    );
    _savingsGoalController = SavingsGoalController(LocalSavingsGoalRepository());
    _debtController = DebtController(LocalDebtRepository());
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _settingsController.load(),
      _accountController.load(),
      _categoryController.load(),
      _categoryBudgetController.load(),
      _recurringController.load(),
      _savingsGoalController.load(),
      _debtController.load(),
    ]);
    await _recurringController.processDueTransactions(
      activeAccountIds: _accountController.activeAccounts.map((account) => account.id).toSet(),
    );
    await _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _settingsController.dispose();
    _accountController.dispose();
    _recurringController.dispose();
    _savingsGoalController.dispose();
    _debtController.dispose();
    _categoryController.dispose();
    _categoryBudgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardPage(
            controller: _controller,
            settingsController: _settingsController,
            onShowTransactions: () => setState(() => _selectedIndex = 2),
            accountController: _accountController,
            recurringController: _recurringController,
            savingsGoalController: _savingsGoalController,
            categoryController: _categoryController,
            categoryBudgetController: _categoryBudgetController,
            debtController: _debtController,
          ),
          StatisticsPage(controller: _controller),
          TransactionsPage(
            controller: _controller,
            accountController: _accountController,
            recurringController: _recurringController,
            categoryController: _categoryController,
            categoryBudgetController: _categoryBudgetController,
          ),
          ProfilePage(
            controller: _settingsController,
            dashboardController: _controller,
            accountController: _accountController,
            recurringController: _recurringController,
            savingsGoalController: _savingsGoalController,
            categoryController: _categoryController,
            categoryBudgetController: _categoryBudgetController,
            debtController: _debtController,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primarySoft,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
