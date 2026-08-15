import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'home_shell.dart';

class MoneyTrackerApp extends StatelessWidget {
  const MoneyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoneyTracker Pro',
      theme: AppTheme.light,
      home: const HomeShell(),
    );
  }
}
