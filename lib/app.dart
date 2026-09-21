import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

class SantianApp extends StatelessWidget {
  const SantianApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Santian',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: home,
    );
  }
}
