import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/monthly_financial_review.dart';

class MonthlyReviewReportPage extends StatelessWidget {
  const MonthlyReviewReportPage({required this.review, super.key});

  final MonthlyFinancialReview review;

  @override
  Widget build(BuildContext context) {
    final spendingImproved = review.expenses <= review.previousExpenses;
    final cashFlowPositive = review.netCashFlow >= 0;

    return Scaffold(
      appBar: AppBar(
          title: Text(
              '${_monthName(review.month.month)} ${review.month.year} review',
              style: const TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _HeroCard(review: review),
          const SizedBox(height: 22),
          const _SectionTitle('Month-over-month'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ComparisonCard(
                  icon: Icons.payments_outlined,
                  label: 'Spending',
                  value: CurrencyFormatter.myr(review.expenses),
                  delta: _percentLabel(review.expenseChangePercent),
                  favorable: spendingImproved,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ComparisonCard(
                  icon: Icons.savings_outlined,
                  label: 'Savings rate',
                  value: '${review.savingsRate.toStringAsFixed(1)}%',
                  delta: _pointLabel(review.savingsRateChange),
                  favorable: review.savingsRateChange >= 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ComparisonCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Daily average',
                  value: CurrencyFormatter.myr(review.averageDailySpend),
                  delta: _moneyDelta(review.averageDailySpendChange),
                  favorable: review.averageDailySpendChange <= 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ComparisonCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Expenses logged',
                  value: '${review.expenseCount}',
                  delta:
                      '${_signedInt(review.expenseCount - review.previousExpenseCount)} vs last month',
                  favorable: true,
                  neutralDelta: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle('Highlights'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _HighlightTile(
                  icon: Icons.category_outlined,
                  title: 'Top spending category',
                  value: review.topCategory == null
                      ? 'No expense data'
                      : '${review.topCategory} · ${CurrencyFormatter.myr(review.topCategoryAmount)}',
                ),
                const Divider(height: 1, indent: 64),
                _HighlightTile(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Largest expense',
                  value: review.largestExpense == null
                      ? 'No expense data'
                      : '${review.largestExpense!.title} · ${CurrencyFormatter.myr(review.largestExpense!.amount)}',
                ),
                const Divider(height: 1, indent: 64),
                _HighlightTile(
                  icon: cashFlowPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  title: 'Net cash flow',
                  value:
                      CurrencyFormatter.myr(review.netCashFlow, showSign: true),
                  valueColor:
                      cashFlowPositive ? AppColors.success : AppColors.expense,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _InsightCard(review: review),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Want to take action?',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your planning tools now live in Insights, where '
                          'they are grouped by what you want to do next.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _monthName(int month) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][month - 1];

  static String _percentLabel(double? value) {
    if (value == null) return 'New vs last month';
    return '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}% vs last month';
  }

  static String _pointLabel(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)} pts';
  static String _moneyDelta(double value) =>
      '${value >= 0 ? '+' : '-'}${CurrencyFormatter.myr(value.abs())}';
  static String _signedInt(int value) => '${value >= 0 ? '+' : ''}$value';
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.review});
  final MonthlyFinancialReview review;

  @override
  Widget build(BuildContext context) {
    final positive = review.netCashFlow >= 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF826CEB), AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: .20),
              blurRadius: 24,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly net cash flow',
              style: TextStyle(color: Color(0xFFDCD6FF))),
          const SizedBox(height: 6),
          Text(CurrencyFormatter.myr(review.netCashFlow, showSign: true),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1)),
          const SizedBox(height: 8),
          Text(
            positive
                ? 'You kept more money than you spent this month.'
                : 'Expenses are currently ahead of income this month.',
            style: const TextStyle(color: Color(0xFFE8E4FF), height: 1.35),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _HeroMetric(
                      label: 'Income',
                      value: CurrencyFormatter.myr(review.income))),
              const SizedBox(width: 10),
              Expanded(
                  child: _HeroMetric(
                      label: 'Expenses',
                      value: CurrencyFormatter.myr(review.expenses))),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(17)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: Color(0xFFDCD6FF), fontSize: 12)),
          const SizedBox(height: 5),
          Text(value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.delta,
      required this.favorable,
      this.neutralDelta = false});
  final IconData icon;
  final String label;
  final String value;
  final String delta;
  final bool favorable;
  final bool neutralDelta;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppColors.primary, size: 20)),
            const SizedBox(height: 14),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(delta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: neutralDelta
                        ? AppColors.textSecondary
                        : (favorable ? AppColors.success : AppColors.expense))),
          ]),
        ),
      );
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile(
      {required this.icon,
      required this.title,
      required this.value,
      this.valueColor});
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: AppColors.primary, size: 21)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 3),
                Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: valueColor)),
              ])),
        ]),
      );
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.review});
  final MonthlyFinancialReview review;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = _insight(review);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(22)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.primary)),
        const SizedBox(width: 13),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          const SizedBox(height: 5),
          Text(message,
              style:
                  const TextStyle(color: AppColors.textPrimary, height: 1.4)),
        ])),
      ]),
    );
  }

  (IconData, String, String) _insight(MonthlyFinancialReview review) {
    if (review.expenses == 0 && review.income == 0) {
      return (
        Icons.auto_awesome_outlined,
        'Start your monthly review',
        'Add income and expense transactions to unlock a useful month-over-month summary.'
      );
    }
    if (review.savingsRateChange >= 5) {
      return (
        Icons.celebration_outlined,
        'Savings momentum improved',
        'Your savings rate is ${review.savingsRateChange.toStringAsFixed(1)} points higher than last month. Keep the habits that drove this improvement.'
      );
    }
    if (review.expenseChange > 0 && review.previousExpenses > 0) {
      return (
        Icons.manage_search_rounded,
        'Spending increased',
        'You spent ${CurrencyFormatter.myr(review.expenseChange)} more than last month. Review ${review.topCategory ?? 'your largest categories'} first for the clearest opportunity.'
      );
    }
    if (review.expenseChange < 0) {
      return (
        Icons.thumb_up_alt_outlined,
        'Spending is trending down',
        'Monthly expenses are ${CurrencyFormatter.myr(review.expenseChange.abs())} lower than last month while your current savings rate is ${review.savingsRate.toStringAsFixed(1)}%.'
      );
    }
    return (
      Icons.insights_outlined,
      'Month is tracking steadily',
      'Your spending is close to last month. Watch the daily average and net cash flow as the month progresses.'
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800));
}
