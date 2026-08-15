import 'dart:convert';

import 'package:flutter/material.dart';

import '../../settings/domain/entities/app_settings.dart';
import '../../recurring/domain/entities/recurring_transaction_rule.dart';
import '../../accounts/domain/entities/finance_account.dart';
import '../../goals/domain/entities/savings_goal.dart';
import '../../transactions/data/models/transaction_record.dart';
import '../../transactions/domain/entities/transaction_entry.dart';
import '../../transactions/domain/entities/transaction_category.dart';
import '../../category_budgets/domain/entities/category_budget.dart';
import '../../debts/domain/entities/debt.dart';

class MoneyTrackerBackupData {
  const MoneyTrackerBackupData({
    required this.transactions,
    required this.settings,
    required this.accounts,
    required this.recurringRules,
    required this.savingsGoals,
    required this.categories,
    required this.categoryBudgets,
    required this.debts,
  });

  final List<TransactionEntry> transactions;
  final AppSettings settings;
  final List<FinanceAccount> accounts;
  final List<RecurringTransactionRule> recurringRules;
  final List<SavingsGoal> savingsGoals;
  final List<TransactionCategory> categories;
  final List<CategoryBudget> categoryBudgets;
  final List<Debt> debts;
}

abstract final class MoneyTrackerBackupService {
  static const schemaVersion = 7;
  static const format = 'moneytrackerpro-backup';

  static String encode({
    required List<TransactionEntry> transactions,
    required AppSettings settings,
    required List<FinanceAccount> accounts,
    required List<RecurringTransactionRule> recurringRules,
    required List<SavingsGoal> savingsGoals,
    required List<TransactionCategory> categories,
    required List<CategoryBudget> categoryBudgets,
    required List<Debt> debts,
  }) {
    final payload = <String, dynamic>{
      'format': format,
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': {
        'displayName': settings.displayName,
        'monthlyBudget': settings.monthlyBudget,
        'budgetAlertsEnabled': settings.budgetAlertsEnabled,
      },
      'accounts': accounts
          .map((account) => {
                'id': account.id,
                'name': account.name,
                'type': account.type.name,
                'isArchived': account.isArchived,
              })
          .toList(),
      'transactions': transactions
          .map(TransactionRecord.fromEntity)
          .map((record) => record.toJson())
          .toList(),
      'recurringRules': recurringRules
          .map((rule) => {
                'id': rule.id,
                'title': rule.title,
                'amount': rule.amount,
                'type': rule.type.name,
                'category': rule.category,
                'accountId': rule.accountId,
                'frequency': rule.frequency.name,
                'nextDueDate': rule.nextDueDate.toIso8601String(),
                'isPaused': rule.isPaused,
              })
          .toList(),
      'savingsGoals': savingsGoals
          .map((goal) => {
                'id': goal.id,
                'name': goal.name,
                'targetAmount': goal.targetAmount,
                'accountId': goal.accountId,
                'deadline': goal.deadline.toIso8601String(),
              })
          .toList(),
      'categories': categories
          .map((category) => {
                'id': category.id,
                'name': category.name,
                'iconCodePoint': category.icon.codePoint,
                'colorValue': category.color.toARGB32(),
                'type': category.type.name,
                'isArchived': category.isArchived,
                'isSystem': category.isSystem,
              })
          .toList(),
      'categoryBudgets': categoryBudgets
          .map((budget) => {
                'categoryId': budget.categoryId,
                'monthlyLimit': budget.monthlyLimit,
              })
          .toList(),
      'debts': debts
          .map((debt) => {
                'id': debt.id,
                'name': debt.name,
                'type': debt.type.name,
                'originalAmount': debt.originalAmount,
                'currentBalance': debt.currentBalance,
                'interestRate': debt.interestRate,
                'dueDate': debt.dueDate.toIso8601String(),
              })
          .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static MoneyTrackerBackupData decode(String source) {
    try {
      final json = jsonDecode(source) as Map<String, dynamic>;
      if (json['format'] != format) {
        throw const BackupFormatException('This is not a MoneyTracker Pro backup.');
      }
      final version = json['schemaVersion'] as int;
      if (version < 1 || version > schemaVersion) {
        throw BackupFormatException('Unsupported backup version: ${json['schemaVersion']}.');
      }

      final settingsJson = json['settings'] as Map<String, dynamic>;
      final settings = AppSettings(
        displayName: settingsJson['displayName'] as String,
        monthlyBudget: (settingsJson['monthlyBudget'] as num).toDouble(),
        budgetAlertsEnabled: settingsJson['budgetAlertsEnabled'] as bool,
      );
      if (settings.displayName.trim().length < 2 || settings.monthlyBudget <= 0) {
        throw const BackupFormatException('Backup settings contain invalid values.');
      }

      final transactionJson = json['transactions'] as List<dynamic>;
      final transactions = transactionJson
          .map((item) => TransactionRecord.fromJson(item as Map<String, dynamic>).toEntity())
          .toList();

      final accounts = version == 1
          ? const <FinanceAccount>[FinanceAccount.cash()]
          : (json['accounts'] as List<dynamic>).map((item) {
              final account = item as Map<String, dynamic>;
              return FinanceAccount(
                id: account['id'] as String,
                name: account['name'] as String,
                type: FinanceAccountType.values.byName(account['type'] as String),
                isArchived: account['isArchived'] as bool? ?? false,
              );
            }).toList();
      if (accounts.isEmpty || accounts.map((item) => item.id).toSet().length != accounts.length) {
        throw const BackupFormatException('Backup contains invalid accounts.');
      }
      final accountIds = accounts.map((item) => item.id).toSet();
      if (transactions.any((item) => !accountIds.contains(item.accountId))) {
        throw const BackupFormatException('A transaction references an account missing from the backup.');
      }

      final recurringRules = version < 3
          ? const <RecurringTransactionRule>[]
          : (json['recurringRules'] as List<dynamic>).map((item) {
              final rule = item as Map<String, dynamic>;
              return RecurringTransactionRule(
                id: rule['id'] as String,
                title: rule['title'] as String,
                amount: (rule['amount'] as num).toDouble(),
                type: TransactionType.values.byName(rule['type'] as String),
                category: rule['category'] as String,
                accountId: rule['accountId'] as String,
                frequency: RecurringFrequency.values.byName(rule['frequency'] as String),
                nextDueDate: DateTime.parse(rule['nextDueDate'] as String),
                isPaused: rule['isPaused'] as bool? ?? false,
              );
            }).toList();
      if (recurringRules.any((rule) =>
          rule.title.trim().isEmpty ||
          rule.amount <= 0 ||
          !accountIds.contains(rule.accountId))) {
        throw const BackupFormatException('Backup contains invalid recurring transactions.');
      }
      if (recurringRules.map((rule) => rule.id).toSet().length != recurringRules.length) {
        throw const BackupFormatException('Backup contains duplicate recurring rule IDs.');
      }


      final savingsGoals = version < 4
          ? const <SavingsGoal>[]
          : (json['savingsGoals'] as List<dynamic>).map((item) {
              final goal = item as Map<String, dynamic>;
              return SavingsGoal(
                id: goal['id'] as String,
                name: goal['name'] as String,
                targetAmount: (goal['targetAmount'] as num).toDouble(),
                accountId: goal['accountId'] as String,
                deadline: DateTime.parse(goal['deadline'] as String),
              );
            }).toList();
      if (savingsGoals.any((goal) =>
          goal.name.trim().isEmpty ||
          goal.targetAmount <= 0 ||
          !accountIds.contains(goal.accountId))) {
        throw const BackupFormatException('Backup contains invalid savings goals.');
      }
      if (savingsGoals.map((goal) => goal.id).toSet().length != savingsGoals.length) {
        throw const BackupFormatException('Backup contains duplicate savings goal IDs.');
      }


      final categories = version < 5
          ? TransactionCategories.defaults()
          : (json['categories'] as List<dynamic>).map((item) {
              final category = item as Map<String, dynamic>;
              return TransactionCategory(
                id: category['id'] as String,
                name: category['name'] as String,
                icon: IconData(category['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
                color: Color(category['colorValue'] as int),
                type: TransactionType.values.byName(category['type'] as String),
                isArchived: category['isArchived'] as bool? ?? false,
                isSystem: category['isSystem'] as bool? ?? false,
              );
            }).toList();
      if (categories.isEmpty || categories.map((item) => item.id).toSet().length != categories.length) {
        throw const BackupFormatException('Backup contains invalid categories.');
      }
      if (categories.any((item) => item.name.trim().isEmpty)) {
        throw const BackupFormatException('Backup contains invalid category names.');
      }

      final categoryIds = categories.map((item) => item.id).toSet();
      final categoryBudgets = version < 6
          ? const <CategoryBudget>[]
          : (json['categoryBudgets'] as List<dynamic>).map((item) {
              final budget = item as Map<String, dynamic>;
              return CategoryBudget(
                categoryId: budget['categoryId'] as String,
                monthlyLimit: (budget['monthlyLimit'] as num).toDouble(),
              );
            }).toList();
      if (categoryBudgets.any((budget) =>
          budget.monthlyLimit <= 0 || !categoryIds.contains(budget.categoryId))) {
        throw const BackupFormatException('Backup contains invalid category budgets.');
      }
      if (categoryBudgets.map((item) => item.categoryId).toSet().length != categoryBudgets.length) {
        throw const BackupFormatException('Backup contains duplicate category budgets.');
      }

      final debts = version < 7
          ? const <Debt>[]
          : (json['debts'] as List<dynamic>).map((item) {
              final debt = item as Map<String, dynamic>;
              return Debt(
                id: debt['id'] as String,
                name: debt['name'] as String,
                type: DebtType.values.byName(debt['type'] as String),
                originalAmount: (debt['originalAmount'] as num).toDouble(),
                currentBalance: (debt['currentBalance'] as num).toDouble(),
                interestRate: (debt['interestRate'] as num).toDouble(),
                dueDate: DateTime.parse(debt['dueDate'] as String),
              );
            }).toList();
      if (debts.any((debt) =>
          debt.name.trim().isEmpty ||
          debt.originalAmount <= 0 ||
          debt.currentBalance < 0 ||
          debt.currentBalance > debt.originalAmount ||
          debt.interestRate < 0)) {
        throw const BackupFormatException('Backup contains invalid debts.');
      }
      if (debts.map((item) => item.id).toSet().length != debts.length) {
        throw const BackupFormatException('Backup contains duplicate debt IDs.');
      }

      final ids = transactions.map((item) => item.id).toSet();
      if (ids.length != transactions.length) {
        throw const BackupFormatException('Backup contains duplicate transaction IDs.');
      }
      if (transactions.any((item) => item.title.trim().isEmpty || item.amount <= 0)) {
        throw const BackupFormatException('Backup contains invalid transactions.');
      }

      return MoneyTrackerBackupData(
        transactions: List.unmodifiable(transactions),
        settings: settings,
        accounts: List.unmodifiable(accounts),
        recurringRules: List.unmodifiable(recurringRules),
        savingsGoals: List.unmodifiable(savingsGoals),
        categories: List.unmodifiable(categories),
        categoryBudgets: List.unmodifiable(categoryBudgets),
        debts: List.unmodifiable(debts),
      );
    } on BackupFormatException {
      rethrow;
    } on FormatException {
      throw const BackupFormatException('The pasted text is not valid JSON.');
    } on TypeError {
      throw const BackupFormatException('The backup structure is incomplete or invalid.');
    } on ArgumentError {
      throw const BackupFormatException('The backup contains an unsupported account type.');
    }
  }
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}
