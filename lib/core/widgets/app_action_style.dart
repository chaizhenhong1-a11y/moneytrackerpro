import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class AppActionStyle {
  static ButtonStyle primary() {
    return FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static ButtonStyle secondary() {
    return OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static ButtonStyle destructive() {
    return FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      backgroundColor: AppColors.expense,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static ButtonStyle compactPrimary() {
    return FilledButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
