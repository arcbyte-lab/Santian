import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';

/// The floating create-task button in its drawn position and style. Inert until
/// the Create Task sheet exists.
class CreateTaskFab extends StatelessWidget {
  const CreateTaskFab({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Create task',
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.fab),
          boxShadow: const [fabShadow],
        ),
        child: Icon(Icons.add, color: scheme.onPrimary),
      ),
    );
  }
}
