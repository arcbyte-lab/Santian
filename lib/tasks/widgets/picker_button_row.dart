import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The Cancel/Done row shared by the reminder and deadline picker dialogs.
class PickerButtonRow extends StatelessWidget {
  const PickerButtonRow({super.key, required this.onCancel, required this.onDone});

  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.extension<AppColors>()!.mutedForeground;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Cancel',
              style: theme.textTheme.labelLarge!.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: muted,
              ),
            ),
          ),
          TextButton(
            onPressed: onDone,
            child: Text(
              'Done',
              style: theme.textTheme.labelLarge!.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
