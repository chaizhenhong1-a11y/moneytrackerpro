class NetWorthPoint {
  const NetWorthPoint({required this.date, required this.value});

  final DateTime date;
  final double value;
}

class AccountNetWorthSlice {
  const AccountNetWorthSlice({
    required this.accountId,
    required this.accountName,
    required this.balance,
    required this.isArchived,
  });

  final String accountId;
  final String accountName;
  final double balance;
  final bool isArchived;
}

class NetWorthReport {
  const NetWorthReport({
    required this.currentNetWorth,
    required this.change30Days,
    required this.history,
    required this.accounts,
    required this.totalLiabilities,
  });

  final double currentNetWorth;
  final double change30Days;
  final List<NetWorthPoint> history;
  final List<AccountNetWorthSlice> accounts;
  final double totalLiabilities;

  double get positiveAssets => accounts
      .where((item) => item.balance > 0)
      .fold(0, (sum, item) => sum + item.balance);

  double get negativeBalances => accounts
      .where((item) => item.balance < 0)
      .fold(0, (sum, item) => sum + item.balance.abs());
}
