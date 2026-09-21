import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

class SantianApp extends StatelessWidget {
  const SantianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Santian',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const Scaffold(),
    );
  }
}
