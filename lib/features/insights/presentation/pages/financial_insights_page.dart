import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../monthly_review/domain/models/monthly_financial_review.dart';
import '../../../monthly_review/domain/services/financial_action_plan_service.dart';
import '../../../monthly_review/domain/services/monthly_financial_review_service.dart';
import '../../../monthly_review/domain/services/safe_to_spend_service.dart';
import '../../../monthly_review/domain/services/spending_pace_forecast_service.dart';
import '../../../monthly_review/presentation/pages/budget_stress_test_page.dart';
import '../../../monthly_review/presentation/pages/emergency_fund_planner_page.dart';
import '../../../monthly_review/presentation/pages/financial_action_plan_page.dart';
import '../../../monthly_review/presentation/pages/income_stability_planner_page.dart';
import '../../../monthly_review/presentation/pages/monthly_financial_review_page.dart';
import '../../../monthly_review/presentation/pages/safe_to_spend_page.dart';
import '../../../monthly_review/presentation/pages/savings_target_planner_page.dart';
import '../../../monthly_review/presentation/pages/spending_guard_page.dart';
import '../../../monthly_review/presentation/pages/spending_pace_page.dart';
import '../../../monthly_review/presentation/pages/surplus_allocation_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';

class FinancialInsightsPage extends StatelessWidget {
  const FinancialInsightsPage({required this.controller, super.key});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final now = DateTime.now();
        final review = MonthlyFinancialReviewService.build(
          transactions: controller.transactions,
          month: DateTime(now.year, now.month),
        );
        final safeToSpend = SafeToSpendService.build(review);
        final recommendation = _recommendation(review);

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Insights',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              children: [
                _OverviewCard(
                  review: review,
                  safeToSpend: safeToSpend.safeToSpend,
                ),
                const SizedBox(height: 22),
                const _SectionHeader(
                  title: 'Recommended for you',
                  subtitle: 'One useful next step based on this month',
                ),
                const SizedBox(height: 10),
                _RecommendedCard(
                  icon: recommendation.icon,
                  title: recommendation.title,
                  message: recommendation.message,
                  actionLabel: recommendation.actionLabel,
                  onTap: () => recommendation.open(context, review),
                ),
                const SizedBox(height: 22),
                const _SectionHeader(
                  title: 'Quick tools',
                  subtitle: 'The three places you will use most often',
                ),
                const SizedBox(height: 10),
                _ToolGroup(
                  children: [
                    _ToolTile(
                      icon: Icons.auto_graph_rounded,
                      title: 'Monthly review',
                      subtitle: 'See how this month is going',
                      onTap: () => _push(
                        context,
                        MonthlyFinancialReviewPage(review: review),
                      ),
                    ),
                    _ToolTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Safe to spend',
                      subtitle: 'Know what you can comfortably spend',
                      onTap: () => _push(
                        context,
                        SafeToSpendPage(plan: safeToSpend),
                      ),
                    ),
                    _ToolTile(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'Statistics',
                      subtitle: 'Explore trends and category breakdowns',
                      onTap: () => _push(
                        context,
                        StatisticsPage(controller: controller),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _MoreToolsCard(review: review),
              ],
            ),
          ),
        );
      },
    );
  }

  _Recommendation _recommendation(MonthlyFinancialReview review) {
    if (review.income <= 0) {
      return _Recommendation(
        icon: Icons.trending_up_rounded,
        title: 'Start with income stability',
        message: 'There is no income recorded this month. Build a conservative '
            'baseline before setting spending targets.',
        actionLabel: 'Check income',
        open: (context, review) => _push(
          context,
          IncomeStabilityPlannerPage(review: review),
        ),
      );
    }

    if (review.netCashFlow < 0 || review.savingsRate < 0) {
      return _Recommendation(
        icon: Icons.science_outlined,
        title: 'Pressure-test this month',
        message: 'Expenses are ahead of income. Test a few scenarios before '
            'making another spending commitment.',
        actionLabel: 'Run stress test',
        open: (context, review) => _push(
          context,
          BudgetStressTestPage(review: review),
        ),
      );
    }

    if (review.expenseChange > 0 && review.previousExpenses > 0) {
      return _Recommendation(
        icon: Icons.shield_outlined,
        title: 'Spending is rising',
        message:
            'Your spending is above last month. Use Spending Guard for the '
            'next non-essential purchase.',
        actionLabel: 'Check a purchase',
        open: (context, review) => _push(
          context,
          SpendingGuardPage(review: review),
        ),
      );
    }

    return _Recommendation(
      icon: Icons.call_split_rounded,
      title: 'Put your surplus to work',
      message: 'You have positive cash flow this month. Give the extra money a '
          'job instead of leaving it unplanned.',
      actionLabel: 'Allocate surplus',
      open: (context, review) => _push(
        context,
        SurplusAllocationPage(review: review),
      ),
    );
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.review,
    required this.safeToSpend,
  });

  final MonthlyFinancialReview review;
  final double safeToSpend;

  @override
  Widget build(BuildContext context) {
    final positive = review.netCashFlow >= 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF826CEB), AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This month at a glance',
            style: TextStyle(color: Color(0xFFDCD6FF)),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.myr(review.netCashFlow, showSign: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            positive
                ? 'Net cash flow is positive.'
                : 'Spending is currently ahead of income.',
            style: const TextStyle(color: Color(0xFFE8E4FF)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Savings rate',
                  value: '${review.savingsRate.toStringAsFixed(1)}%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroMetric(
                  label: 'Safe to spend',
                  value: CurrencyFormatter.myr(safeToSpend),
                ),
              ),
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFDCD6FF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onTap,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreToolsCard extends StatefulWidget {
  const _MoreToolsCard({required this.review});

  final MonthlyFinancialReview review;

  @override
  State<_MoreToolsCard> createState() => _MoreToolsCardState();
}

class _MoreToolsCardState extends State<_MoreToolsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 5,
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: AppColors.primary,
                size: 21,
              ),
            ),
            title: const Text(
              'More tools',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: const Text(
              'Planning, protection and deeper analysis',
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const Divider(height: 1, indent: 66),
            _ToolTile(
              icon: Icons.speed_rounded,
              title: 'Spending pace',
              subtitle: 'Project spending through month end',
              onTap: () => FinancialInsightsPage._push(
                context,
                SpendingPacePage(
                  forecast: SpendingPaceForecastService.build(widget.review),
                ),
              ),
            ),
            const Divider(height: 1, indent: 66),
            _ToolTile(
              icon: Icons.shield_outlined,
              title: 'Spending Guard',
              subtitle: 'Check a purchase before committing',
              onTap: () => FinancialInsightsPage._push(
                context,
                SpendingGuardPage(review: widget.review),
              ),
            ),
            const Divider(height: 1, indent: 66),
            _ToolTile(
              icon: Icons.science_outlined,
              title: 'Budget stress test',
              subtitle: 'Simulate lower income or surprise expenses',
              onTap: () => FinancialInsightsPage._push(
                context,
                BudgetStressTestPage(review: widget.review),
              ),
            ),
            const Divider(height: 1, indent: 66),
            _ToolTile(
              icon: Icons.task_alt_rounded,
              title: 'Action plan',
              subtitle: 'Prioritized steps for this month',
              onTap: () => FinancialInsightsPage._push(
                context,
                FinancialActionPlanPage(
                  plan: FinancialActionPlanService.build(widget.review),
                ),
              ),
            ),
            const Divider(height: 1, indent: 66),
            _ToolTile(
              icon: Icons.health_and_safety_outlined,
              title: 'Emergency fund',
              subtitle: 'Build a 3–12 month safety reserve',
              onTap: () => FinancialInsightsPage._push(
                context,
                EmergencyFundPlannerPage(review: widget.review),
              ),
            ),
            const Divider(height: 1, indent: 66),
            _ToolTile(
              icon: Icons.savings_outlined,
              title: 'Savings target',
              subtitle: 'Set a savings rate and spending ceiling',
              onTap: () => FinancialInsightsPage._push(
                context,
                SavingsTargetPlannerPage(review: widget.review),
              ),
            ),
            const Divider(height: 1, indent: 66),
            _ToolTile(
              icon: Icons.call_split_rounded,
              title: 'Allocate surplus',
              subtitle: 'Split extra cash across your priorities',
              onTap: () => FinancialInsightsPage._push(
                context,
                SurplusAllocationPage(review: widget.review),
              ),
            ),
            const Divider(height: 1, indent: 66),
            _ToolTile(
              icon: Icons.trending_up_rounded,
              title: 'Income stability',
              subtitle: 'Plan around variable monthly income',
              onTap: () => FinancialInsightsPage._push(
                context,
                IncomeStabilityPlannerPage(review: widget.review),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToolGroup extends StatelessWidget {
  const _ToolGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const Divider(height: 1, indent: 66),
          ],
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: AppColors.primary, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _Recommendation {
  const _Recommendation({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.open,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final void Function(
    BuildContext context,
    MonthlyFinancialReview review,
  ) open;
}
