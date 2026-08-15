import 'package:flutter/material.dart';

import '../../transactions/domain/entities/transaction_entry.dart';

abstract final class DashboardDemoData {
  static final transactions = <TransactionEntry>[
    TransactionEntry(
      id: 'tx_001',
      title: 'Salary',
      category: 'Income',
      amount: 4250,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      type: TransactionType.income,
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF21B978),
    ),
    TransactionEntry(
      id: 'tx_002',
      title: 'Food & Drinks',
      category: 'Dining',
      amount: 28.50,
      date: DateTime.now().subtract(const Duration(hours: 4)),
      type: TransactionType.expense,
      icon: Icons.restaurant_rounded,
      color: const Color(0xFFFF8B5C),
    ),
    TransactionEntry(
      id: 'tx_003',
      title: 'Petrol',
      category: 'Transport',
      amount: 70,
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: TransactionType.expense,
      icon: Icons.local_gas_station_rounded,
      color: const Color(0xFF5D9CEC),
    ),
    TransactionEntry(
      id: 'tx_004',
      title: 'Online Shopping',
      category: 'Shopping',
      amount: 129.90,
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: TransactionType.expense,
      icon: Icons.shopping_bag_rounded,
      color: const Color(0xFFE96CB5),
    ),
  ];
}
