import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';

/// The floating create-task button in its drawn position and style. Does
/// nothing when [onPressed] is null (there is no List to create a Task in).
class CreateTaskFab extends StatelessWidget {
  const CreateTaskFab({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.fab);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: 'Create task',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: radius,
          boxShadow: const [fabShadow],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.add, color: scheme.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
