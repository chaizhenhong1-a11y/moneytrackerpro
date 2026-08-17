import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class AppFeedback {
  static void success(
    BuildContext context, {
    required String message,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: AppColors.success,
    );
  }

  static void error(
    BuildContext context, {
    required String message,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: AppColors.expense,
    );
  }

  static void info(
    BuildContext context, {
    required String message,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppColors.primary,
    );
  }

  static void undo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.undo_rounded,
      backgroundColor: AppColors.textPrimary,
      action: SnackBarAction(
        label: 'UNDO',
        textColor: Colors.white,
        onPressed: onUndo,
      ),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          duration: action == null
              ? const Duration(seconds: 3)
              : const Duration(seconds: 5),
          action: action,
          content: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 21,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
