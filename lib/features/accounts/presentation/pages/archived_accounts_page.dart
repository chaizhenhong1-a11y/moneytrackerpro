import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../domain/entities/finance_account.dart';
import '../controllers/account_controller.dart';
import 'account_detail_page.dart';

class ArchivedAccountsPage extends StatelessWidget {
  const ArchivedAccountsPage({
    required this.controller,
    required this.dashboardController,
    super.key,
  });

  final AccountController controller;
  final DashboardController dashboardController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, dashboardController]),
      builder: (context, _) {
        final archived = controller.archivedAccounts;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Archived accounts',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: archived.isEmpty
              ? const _EmptyArchivedAccounts()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.archive_outlined, color: AppColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Archived accounts keep all historical activity and still count toward your total balance, but cannot be used for new transactions or transfers until restored.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    ...archived.map((account) {
                      final transactions = dashboardController.transactions
                          .where((item) => item.accountId == account.id)
                          .toList();
                      final balance = transactions.fold<double>(
                        0,
                        (sum, item) => sum + item.signedAmount,
                      );
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.border.withValues(alpha: .6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          title: Text(
                            account.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${transactions.length} transactions • ${CurrencyFormatter.myr(balance)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => AccountDetailPage(
                                account: account,
                                dashboardController: dashboardController,
                                allAccounts: controller.accounts,
                              ),
                            ),
                          ),
                          trailing: FilledButton.tonalIcon(
                            onPressed: () => _restore(context, account),
                            icon: const Icon(Icons.unarchive_outlined, size: 18),
                            label: const Text('Restore'),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _restore(BuildContext context, FinanceAccount account) async {
    final restored = await controller.restoreAccount(account.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored
              ? '${account.name} restored to active accounts.'
              : controller.errorMessage ?? 'Unable to restore account.',
        ),
      ),
    );
  }
}

class _EmptyArchivedAccounts extends StatelessWidget {
  const _EmptyArchivedAccounts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.archive_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No archived accounts',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            const Text(
              'Accounts you archive will appear here so you can review their history or restore them later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
