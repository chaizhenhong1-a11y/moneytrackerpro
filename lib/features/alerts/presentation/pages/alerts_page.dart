import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/entities/financial_alert.dart';
import '../../domain/services/financial_alert_service.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({
    required this.dashboardController,
    required this.settingsController,
    super.key,
  });

  final DashboardController dashboardController;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([dashboardController, settingsController]),
      builder: (context, _) {
        final alerts = FinancialAlertService.generate(
          transactions: dashboardController.transactions,
          settings: settingsController.settings,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Financial alerts', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          body: RefreshIndicator(
            onRefresh: dashboardController.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                _AlertSummary(count: alerts.length),
                const SizedBox(height: 20),
                if (alerts.isEmpty)
                  const _AllClearCard()
                else
                  ...alerts.map((alert) => _AlertCard(alert: alert)),
                const SizedBox(height: 10),
                const Text(
                  'Alerts are generated privately from data stored on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF826CEB), AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_active_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count active ${count == 1 ? 'alert' : 'alerts'}', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Updated from your latest activity', style: TextStyle(color: Color(0xFFDCD6FF), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final FinancialAlert alert;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(alert.severity);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: style.color.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)),
              child: Icon(_iconFor(alert.type), color: style.color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: style.color.withValues(alpha: .1), borderRadius: BorderRadius.circular(10)),
                        child: Text(style.label, style: TextStyle(color: style.color, fontSize: 9, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(alert.message, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _AlertStyle _styleFor(FinancialAlertSeverity severity) => switch (severity) {
        FinancialAlertSeverity.info => const _AlertStyle(AppColors.primary, 'INFO'),
        FinancialAlertSeverity.success => const _AlertStyle(AppColors.success, 'GOOD'),
        FinancialAlertSeverity.warning => const _AlertStyle(Color(0xFFF59E0B), 'CHECK'),
        FinancialAlertSeverity.critical => const _AlertStyle(AppColors.expense, 'URGENT'),
      };

  IconData _iconFor(FinancialAlertType type) => switch (type) {
        FinancialAlertType.budgetWarning => Icons.speed_rounded,
        FinancialAlertType.budgetExceeded => Icons.warning_amber_rounded,
        FinancialAlertType.largeExpense => Icons.payments_outlined,
        FinancialAlertType.positiveSavings => Icons.savings_outlined,
        FinancialAlertType.noActivity => Icons.add_chart_rounded,
      };
}

class _AllClearCard extends StatelessWidget {
  const _AllClearCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(34),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 44),
            SizedBox(height: 12),
            Text('Everything looks good', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 5),
            Text('There are no financial alerts right now.', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _AlertStyle {
  const _AlertStyle(this.color, this.label);
  final Color color;
  final String label;
}
