import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../cubits/task_detail_cubit.dart';
import '../deadline_status.dart';
import '../models/task_list.dart';
import '../widgets/date_time_picker_dialog.dart';
import '../widgets/deadline_picker_dialog.dart';
import '../widgets/list_selector_sheet.dart';
import '../widgets/month_grid.dart';

TaskList? _listById(List<TaskList> lists, int listId) {
  for (final list in lists) {
    if (list.id == listId) return list;
  }
  return null;
}

const List<String> _weekdayNames = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

String _formatReminderChip(BuildContext context, DateTime dt) {
  final weekday = _weekdayNames[dt.weekday - 1];
  final month = monthNames[dt.month - 1].substring(0, 3);
  final time = TimeOfDay.fromDateTime(dt).format(context);
  return '$weekday, $month ${dt.day} · $time';
}

/// "Sep 20" — no year (a deadline this far out is rare enough not to need
/// one), no time (`deadline` is date-only).
String _formatDeadlineChip(DateTime dt) =>
    '${monthNames[dt.month - 1].substring(0, 3)} ${dt.day}';

/// Task Detail's content as a function of [state]: Top Bar (Back, Star,
/// More), List Selector, Title, Description, the Deadline and Reminder
/// fields, and the Mark Completed pill. Repeat and subtask rows are not
/// built here — each later ticket adds its own row between Reminder and
/// Mark Completed.
class TaskDetailView extends StatefulWidget {
  const TaskDetailView({
    super.key,
    required this.state,
    required this.lists,
    required this.onBack,
    required this.onToggleStar,
    required this.onSelectList,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onDeadlineChanged,
    required this.onReminderChanged,
    required this.onToggleCompleted,
    required this.onDelete,
  });

  final TaskDetailState state;
  final List<TaskList> lists;
  final VoidCallback onBack;
  final VoidCallback onToggleStar;
  final ValueChanged<TaskList> onSelectList;

  /// Called on blur, once editing stops — not on every keystroke.
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onDescriptionChanged;

  /// Null clears the deadline, removing the chip.
  final ValueChanged<DateTime?> onDeadlineChanged;

  /// Null clears the reminder, removing the chip.
  final ValueChanged<DateTime?> onReminderChanged;

  final VoidCallback onToggleCompleted;
  final VoidCallback onDelete;

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  late final _title = TextEditingController(text: widget.state.task.title);
  late final _description =
      TextEditingController(text: widget.state.task.description ?? '');
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleFocus.addListener(_onTitleFocusChange);
    _descriptionFocus.addListener(_onDescriptionFocusChange);
  }

  void _onTitleFocusChange() {
    if (!_titleFocus.hasFocus) widget.onTitleChanged(_title.text);
  }

  void _onDescriptionFocusChange() {
    if (!_descriptionFocus.hasFocus) {
      widget.onDescriptionChanged(_description.text);
    }
  }

  @override
  void dispose() {
    _titleFocus.removeListener(_onTitleFocusChange);
    _descriptionFocus.removeListener(_onDescriptionFocusChange);
    _title.dispose();
    _description.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  Future<void> _openListSelector(BuildContext context) async {
    final selected = await showListSelectorSheet(
      context,
      lists: widget.lists,
      currentListId: widget.state.task.listId,
    );
    if (selected != null) widget.onSelectList(selected);
  }

  Future<void> _pickReminder(BuildContext context) async {
    final picked = await showDateTimePickerDialog(
      context,
      initial: widget.state.task.reminderAt,
    );
    if (picked != null) widget.onReminderChanged(picked);
  }

  Future<void> _pickDeadline(BuildContext context) async {
    final picked = await showDeadlinePickerDialog(
      context,
      initial: widget.state.task.deadline,
    );
    if (picked != null) widget.onDeadlineChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.extension<AppColors>()!.mutedForeground;
    final task = widget.state.task;
    final list = _listById(widget.lists, task.listId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              color: muted.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconAction(
                icon: Icons.arrow_back,
                label: 'Back',
                color: scheme.onSurface,
                onTap: widget.onBack,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconAction(
                    icon: task.isStarred ? Icons.star : Icons.star_border,
                    label: 'Star',
                    color: task.isStarred ? scheme.primary : muted,
                    onTap: widget.onToggleStar,
                  ),
                  PopupMenuButton<void>(
                    icon: Icon(Icons.more_vert, color: muted),
                    tooltip: 'More',
                    itemBuilder: (context) => [
                      PopupMenuItem<void>(
                        onTap: widget.onDelete,
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 4),
          child: InkWell(
            onTap: list == null ? null : () => _openListSelector(context),
            child: Semantics(
              button: true,
              label: 'List: ${list?.name ?? ''}',
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: list == null ? muted : Color(list.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    list?.name ?? '',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 14, color: scheme.primary),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
          child: TextField(
            controller: _title,
            focusNode: _titleFocus,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: scheme.onSurface,
            ),
            decoration: const InputDecoration.collapsed(hintText: ''),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.menu, size: 20, color: muted),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _description,
                  focusNode: _descriptionFocus,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: theme.textTheme.bodyMedium!
                      .copyWith(fontSize: 15, color: scheme.onSurface),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Add description',
                    hintStyle: theme.textTheme.bodyMedium!
                        .copyWith(fontSize: 15, color: muted),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
          child: _DeadlineField(
            deadline: task.deadline,
            overdue: isOverdue(deadline: task.deadline, isCompleted: task.isCompleted),
            onTap: () => _pickDeadline(context),
            onClear: () => widget.onDeadlineChanged(null),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
          child: _ReminderField(
            reminderAt: task.reminderAt,
            onTap: () => _pickReminder(context),
            onClear: () => widget.onReminderChanged(null),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: _MarkCompletedPill(
            completed: task.isCompleted,
            onTap: widget.onToggleCompleted,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// One of the Top Bar's icons (Back, Star). A plain `IconButton`'s tooltip
/// does not reliably surface as a semantics label in tests, so this wraps the
/// icon in its own `Semantics`, matching the pattern used elsewhere (the
/// Tasks List checkbox, the Create Task action icons).
class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

/// The reminder row: "Add reminder" until set, then a removable chip showing
/// the picked date and time. Tapping the chip's label reopens the picker to
/// change it; the X clears `reminderAt` on its own, without reopening it.
class _ReminderField extends StatelessWidget {
  const _ReminderField({
    required this.reminderAt,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? reminderAt;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.extension<AppColors>()!.mutedForeground;
    final reminderAt = this.reminderAt;

    if (reminderAt == null) {
      return InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.schedule, size: 20, color: muted),
            const SizedBox(width: 16),
            Text(
              'Add reminder',
              style: theme.textTheme.bodyMedium!.copyWith(fontSize: 15, color: muted),
            ),
          ],
        ),
      );
    }

    final radius = BorderRadius.circular(AppRadius.chip);
    return Row(
      children: [
        Icon(Icons.schedule, size: 20, color: muted),
        const SizedBox(width: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.1),
            borderRadius: radius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                label: 'Change reminder',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      _formatReminderChip(context, reminderAt),
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontSize: 13,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Remove reminder',
                excludeSemantics: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 12, 6),
                    child: Icon(Icons.close, size: 14, color: muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The deadline row: "Add deadline" until set, then a removable chip shaped
/// like the reminder's — same radius, padding, removable-X pattern — but on
/// a neutral `muted` background rather than the reminder's accent tint, so
/// the two don't read as the same kind of chip at a glance. [overdue] turns
/// the icon, chip text, and (via the caller) the list row's line to
/// `colorScheme.error`; it reverts the moment the Task is completed or the
/// deadline is cleared — [overdue] is a computed style, not stored state.
class _DeadlineField extends StatelessWidget {
  const _DeadlineField({
    required this.deadline,
    required this.overdue,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? deadline;
  final bool overdue;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final appColors = theme.extension<AppColors>()!;
    final muted = appColors.mutedForeground;
    final deadline = this.deadline;
    final iconColor = overdue ? scheme.error : muted;

    if (deadline == null) {
      return InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: muted),
            const SizedBox(width: 16),
            Text(
              'Add deadline',
              style: theme.textTheme.bodyMedium!.copyWith(fontSize: 15, color: muted),
            ),
          ],
        ),
      );
    }

    final radius = BorderRadius.circular(AppRadius.chip);
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 20, color: iconColor),
        const SizedBox(width: 16),
        DecoratedBox(
          decoration: BoxDecoration(color: appColors.muted, borderRadius: radius),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                label: 'Change deadline',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: radius,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      _formatDeadlineChip(deadline),
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontSize: 13,
                        color: overdue ? scheme.error : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Remove deadline',
                excludeSemantics: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 12, 6),
                    child: Icon(Icons.close, size: 14, color: muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Task Detail's only completion control. Accent-filled "Mark completed" when
/// incomplete; once completed, a muted "Mark incomplete", still tappable to
/// undo. Recommended in the spec, not confirmed by the owner.
class _MarkCompletedPill extends StatelessWidget {
  const _MarkCompletedPill({required this.completed, required this.onTap});

  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.extension<AppColors>()!.muted;
    final mutedForeground = theme.extension<AppColors>()!.mutedForeground;
    final radius = BorderRadius.circular(AppRadius.pill);

    return Material(
      color: completed ? muted : scheme.primary,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          width: 180,
          height: 48,
          alignment: Alignment.center,
          child: Text(
            completed ? 'Mark incomplete' : 'Mark completed',
            style: theme.textTheme.labelLarge!.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: completed ? mutedForeground : scheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
