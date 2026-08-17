import 'package:flutter/material.dart';

import '../../../accounts/domain/entities/finance_account.dart';

enum TransactionType { income, expense }

class TransactionEntry {
  const TransactionEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.type,
    required this.icon,
    required this.color,
    this.accountId = FinanceAccountIds.cash,
  });

  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final IconData icon;
  final Color color;
  final String accountId;

  bool get isIncome => type == TransactionType.income;
  bool get isTransfer => category == 'Transfer';
  bool get isReconciliation => category == 'Reconciliation';

  String? get transferGroupId {
    if (!isTransfer) return null;
    final match = RegExp(r'^transfer_(.+)_(out|in)$').firstMatch(id);
    return match?.group(1);
  }

  bool isSameTransfer(TransactionEntry other) {
    final groupId = transferGroupId;
    return groupId != null && groupId == other.transferGroupId;
  }

  bool get countsAsIncome => isIncome && !isTransfer && !isReconciliation;
  bool get countsAsExpense => !isIncome && !isTransfer && !isReconciliation;
  double get signedAmount => isIncome ? amount : -amount;
}
