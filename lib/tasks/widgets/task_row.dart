import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../deadline_status.dart';
import '../models/task.dart';
import '../widgets/month_grid.dart';

/// One Task on the Tasks List: a circular checkbox, the title (wrapping onto
/// as many lines as it needs), up to two lines of description, the reminder
/// ("Yesterday, 9:00 AM") and the deadline ("Due in 2 days") side by side on
/// one muted line when either is set (each turns `colorScheme.error` once its
/// date is past), and a star on the right.
/// The checkbox calls [onToggle], the star [onToggleStar]; tapping anywhere
/// else on the row calls [onOpenDetail].
class TaskRow extends StatelessWidget {
  const TaskRow({
    super.key,
    required this.task,
    this.onToggle,
    this.onToggleStar,
    this.onOpenDetail,
  });

  final Task task;

  /// Called when the checkbox is tapped. Null leaves it inert.
  final VoidCallback? onToggle;

  /// Called when the star is tapped. Null leaves it inert.
  final VoidCallback? onToggleStar;

  /// Called when the row is tapped outside the checkbox zone. Null leaves
  /// that area inert.
  final VoidCallback? onOpenDetail;

  /// The checkbox's tap target: the row's left edge up to the title, over the
  /// row's full height. The drawn circle is only 21 wide.
  static const double _checkboxZone = 24 + 21 + 14;

  /// The star's tap target, mirroring the checkbox's: from the title's end
  /// to the row's right edge, over the row's full height.
  static const double _starZone = 14 + 20 + 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppColors>()!.mutedForeground;
    final done = task.isCompleted;
    final description = switch (task.description?.trim()) {
      final d? when d.isNotEmpty => d,
      _ => null,
    };
    final now = DateTime.now();
    final reminder = task.reminderAt;
    final deadline = task.deadline;
    // Past from today (and not completed): error-colored, reminder and
    // deadline alike - the same date rule, so it's isOverdue for both.
    Color dateColor(DateTime? at) =>
        isOverdue(deadline: at, isCompleted: done) ? theme.colorScheme.error : muted;
    final reminderColor = dateColor(reminder);
    final deadlineColor = dateColor(deadline);

    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpenDetail,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              // A wrapped title grows the row downward; the checkbox stays
              // beside its first line.
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (description != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall!.copyWith(
                            fontSize: 12,
                            color: muted,
                          ),
                        ),
                      ],
                      if (reminder != null || deadline != null) ...[
                        const SizedBox(height: 3),
                        // One line; wraps only if a narrow row can't fit both.
                        Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (reminder != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: reminderColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${relativeDayLabel(reminder, now)}, '
                                    '${TimeOfDay.fromDateTime(reminder).format(context)}',
                                    style: theme.textTheme.bodySmall!.copyWith(
                                      fontSize: 12,
                                      color: reminderColor,
                                    ),
                                  ),
                                ],
                              ),
                            if (deadline != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: deadlineColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due ${_lowerFirst(relativeDayLabel(deadline, now))}',
                                    style: theme.textTheme.bodySmall!.copyWith(
                                      fontSize: 12,
                                      color: deadlineColor,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  task.isStarred ? Icons.star : Icons.star_border,
                  size: 20,
                  color: task.isStarred ? theme.colorScheme.primary : muted,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: _starZone,
          child: Semantics(
            container: true,
            button: true,
            toggled: task.isStarred,
            label: 'Star ${task.title}',
            excludeSemantics: true,
            onTap: onToggleStar,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleStar,
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

/// "Today" -> "today", for "Due today"; "in 2 days" is unchanged.
String _lowerFirst(String s) => s[0].toLowerCase() + s.substring(1);

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
