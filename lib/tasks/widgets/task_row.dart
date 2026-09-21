import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/task.dart';

/// One Task on the Tasks List: a circular checkbox, the title, and the
/// reminder time when there is one. Read-only for now; the checkbox and the row
/// do nothing until the tickets that make them interactive.
class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppColors>()!.mutedForeground;
    final done = task.isCompleted;
    final reminder = task.reminderAt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          _CheckCircle(completed: done),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: 15,
                    color: done ? muted : theme.colorScheme.onSurface,
                  ),
                ),
                if (reminder != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    TimeOfDay.fromDateTime(reminder).format(context),
                    style: theme.textTheme.bodySmall!
                        .copyWith(fontSize: 12, color: muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      checked: completed,
      child: Container(
        width: 21,
        height: 21,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: completed ? scheme.primary : null,
          border: completed
              ? null
              : Border.all(color: scheme.outline, width: 1.5),
        ),
        child: completed
            ? Icon(Icons.check, size: 14, color: scheme.onPrimary)
            : null,
      ),
    );
  }
}
