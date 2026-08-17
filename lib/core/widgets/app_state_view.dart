import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppStateViewType {
  loading,
  empty,
  error,
}

class AppStateView extends StatelessWidget {
  const AppStateView.loading({
    this.title = 'Loading',
    this.message = 'Getting everything ready…',
    super.key,
  })  : type = AppStateViewType.loading,
        icon = Icons.hourglass_top_rounded,
        actionLabel = null,
        onAction = null;

  const AppStateView.empty({
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  }) : type = AppStateViewType.empty;

  const AppStateView.error({
    this.title = 'Something went wrong',
    this.message = 'We could not load this right now.',
    this.icon = Icons.error_outline_rounded,
    this.actionLabel = 'Try again',
    this.onAction,
    super.key,
  }) : type = AppStateViewType.error;

  final AppStateViewType type;
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 44,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type == AppStateViewType.loading)
                const SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 29,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(
                    type == AppStateViewType.error
                        ? Icons.refresh_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
