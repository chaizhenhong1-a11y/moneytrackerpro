import 'package:flutter/material.dart';

import '../../domain/entities/transaction_entry.dart';

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.dateIso,
    required this.type,
    required this.iconCodePoint,
    required this.colorValue,
    required this.accountId,
  });

  factory TransactionRecord.fromEntity(TransactionEntry entity) {
    return TransactionRecord(
      id: entity.id,
      title: entity.title,
      category: entity.category,
      amount: entity.amount,
      dateIso: entity.date.toIso8601String(),
      type: entity.type.name,
      iconCodePoint: entity.icon.codePoint,
      colorValue: entity.color.toARGB32(),
      accountId: entity.accountId,
    );
  }

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      dateIso: json['date'] as String,
      type: json['type'] as String,
      iconCodePoint: json['iconCodePoint'] as int,
      colorValue: json['colorValue'] as int,
      accountId: json['accountId'] as String? ?? 'account_cash',
    );
  }

  final String id;
  final String title;
  final String category;
  final double amount;
  final String dateIso;
  final String type;
  final int iconCodePoint;
  final int colorValue;
  final String accountId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'amount': amount,
        'date': dateIso,
        'type': type,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'accountId': accountId,
      };

  TransactionEntry toEntity() {
    return TransactionEntry(
      id: id,
      title: title,
      category: category,
      amount: amount,
      date: DateTime.parse(dateIso),
      type: type == TransactionType.income.name
          ? TransactionType.income
          : TransactionType.expense,
      icon: IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
      color: Color(colorValue),
      accountId: accountId,
    );
  }
}
