import 'package:flutter/material.dart';

import 'transaction_entry.dart';

class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isArchived = false,
    this.isSystem = false,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;
  final bool isArchived;
  final bool isSystem;

  TransactionCategory copyWith({
    String? name,
    IconData? icon,
    Color? color,
    TransactionType? type,
    bool? isArchived,
  }) {
    return TransactionCategory(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isArchived: isArchived ?? this.isArchived,
      isSystem: isSystem,
    );
  }
}

abstract final class TransactionCategories {
  static const values = <TransactionCategory>[
    TransactionCategory(
      id: 'food',
      name: 'Food & Drinks',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFF8B5C),
      type: TransactionType.expense,
      isSystem: true,
    ),
    TransactionCategory(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF5D9CEC),
      type: TransactionType.expense,
      isSystem: true,
    ),
    TransactionCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFE96CB5),
      type: TransactionType.expense,
      isSystem: true,
    ),
    TransactionCategory(
      id: 'bills',
      name: 'Bills',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFF4B740),
      type: TransactionType.expense,
      isSystem: true,
    ),
    TransactionCategory(
      id: 'salary',
      name: 'Salary',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF21B978),
      type: TransactionType.income,
      isSystem: true,
    ),
    TransactionCategory(
      id: 'other_income',
      name: 'Other Income',
      icon: Icons.savings_rounded,
      color: Color(0xFF35A67B),
      type: TransactionType.income,
      isSystem: true,
    ),
    TransactionCategory(
      id: 'other',
      name: 'Other',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF8D8E9B),
      type: TransactionType.expense,
      isSystem: true,
    ),
  ];

  static List<TransactionCategory> defaults() => List.unmodifiable(values);

  static TransactionCategory fallbackFor(TransactionType type) {
    return values.firstWhere(
      (category) => category.type == type && category.id.startsWith('other'),
      orElse: () => values.firstWhere((category) => category.type == type),
    );
  }
}
