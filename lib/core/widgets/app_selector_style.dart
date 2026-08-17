import 'package:flutter/material.dart';

abstract final class AppSelectorStyle {
  static ButtonStyle segmentedButtonStyle() {
    return ButtonStyle(
      visualDensity: VisualDensity.standard,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  static Widget datePickerBuilder(
    BuildContext context,
    Widget? child,
  ) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        datePickerTheme: DatePickerThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
