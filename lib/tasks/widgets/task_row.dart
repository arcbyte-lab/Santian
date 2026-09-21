import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../deadline_status.dart';
import '../models/task.dart';
import '../widgets/month_grid.dart';

/// One Task on the Tasks List: a circular checkbox, the title, the reminder
/// time when there is one, and a second muted line — calendar icon plus a
/// short date — when there is a deadline. That line turns
/// `colorScheme.error` when the deadline is overdue. The checkbox calls
/// [onToggle]; tapping anywhere else on the row calls [onOpenDetail].
class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task, this.onToggle, this.onOpenDetail});

  final Task task;

  /// Called when the checkbox is tapped. Null leaves it inert.
  final VoidCallback? onToggle;

  /// Called when the row is tapped outside the checkbox zone. Null leaves
  /// that area inert.
  final VoidCallback? onOpenDetail;

  /// The checkbox's tap target: the row's left edge up to the title, over the
  /// row's full height. The drawn circle is only 21 wide.
  static const double _checkboxZone = 24 + 21 + 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppColors>()!.mutedForeground;
    final done = task.isCompleted;
    final reminder = task.reminderAt;
    final deadline = task.deadline;
    final overdue = isOverdue(deadline: deadline, isCompleted: done);
    final deadlineColor = overdue ? theme.colorScheme.error : muted;

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpenDetail,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                _CheckCircle(completed: done),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                        child: Text(
                          task.title,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            fontSize: 15,
                            color: done ? muted : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (reminder != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          TimeOfDay.fromDateTime(reminder).format(context),
                          style: theme.textTheme.bodySmall!.copyWith(
                            fontSize: 12,
                            color: muted,
                          ),
                        ),
                      ],
                      if (deadline != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: deadlineColor),
                            const SizedBox(width: 4),
                            Text(
                              '${monthNames[deadline.month - 1].substring(0, 3)} ${deadline.day}',
                              style: theme.textTheme.bodySmall!.copyWith(
                                fontSize: 12,
                                color: deadlineColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: _checkboxZone,
          // The checkbox is the row's one labelled control, so screen readers
          // say "<title>, checkbox, checked"; the title text is excluded below
          // rather than read a second time.
          child: Semantics(
            container: true,
            checked: done,
            label: task.title,
            excludeSemantics: true,
            onTap: onToggle,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
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
    );
  }
}
