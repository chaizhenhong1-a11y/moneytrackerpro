enum FinanceAccountType { cash, bank, eWallet, savings }

abstract final class FinanceAccountIds {
  static const cash = 'account_cash';
}

class FinanceAccount {
  const FinanceAccount({
    required this.id,
    required this.name,
    required this.type,
    this.isArchived = false,
  });

  const FinanceAccount.cash()
      : id = FinanceAccountIds.cash,
        name = 'Cash',
        type = FinanceAccountType.cash,
        isArchived = false;

  final String id;
  final String name;
  final FinanceAccountType type;
  final bool isArchived;

  FinanceAccount copyWith({
    String? id,
    String? name,
    FinanceAccountType? type,
    bool? isArchived,
  }) {
    return FinanceAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
