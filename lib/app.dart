import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

class SantianApp extends StatelessWidget {
  const SantianApp({super.key, required this.home, this.navigatorKey});

  final Widget home;

  /// Lets a notification tap - which has no BuildContext of its own to work
  /// with, since it can land while any screen is showing - reach a context
  /// inside this app's tree (and everything above `home` in it, including
  /// the repositories) to open Task Detail. Null when nothing needs it, e.g.
  /// most tests.
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Santian',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: home,
    );
  }
}
