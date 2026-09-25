import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../cubits/create_task_cubit.dart';
import '../models/repeat.dart';
import '../widgets/date_time_picker_dialog.dart';

/// The contents of the Create Task sheet as a function of [state]: a compose
/// row, an optional notes field, and the actions row. It owns only the text
/// controllers; everything else comes from [state] and the callbacks.
class CreateTaskForm extends StatefulWidget {
  const CreateTaskForm({
    super.key,
    required this.state,
    required this.onTitleChanged,
    required this.onNotesChanged,
    required this.onToggleNotes,
    required this.onToggleStar,
    required this.onReminderChanged,
    required this.onSubmit,
  });

  final CreateTaskState state;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onToggleNotes;
  final VoidCallback onToggleStar;
  final void Function(DateTime dateTime, Repeat? repeat) onReminderChanged;

  /// Keyboard Enter or Done in the title field.
  final VoidCallback onSubmit;

  @override
  State<CreateTaskForm> createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends State<CreateTaskForm> {
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _notesFocus = FocusNode();

  Future<void> _pickReminder(BuildContext context) async {
    final picked = await showDateTimePickerDialog(
      context,
      initial: widget.state.reminderAt,
      initialRepeat: widget.state.repeat,
    );
    if (picked != null)
      widget.onReminderChanged(picked.dateTime, picked.repeat);
  }

  @override
  void didUpdateWidget(CreateTaskForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Revealing the notes field moves the cursor into it. `autofocus` cannot do
    // this: it is ignored while another field, here the title, has focus.
    if (!oldWidget.state.notesVisible && widget.state.notesVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notesFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.extension<AppColors>()!.mutedForeground;
    final hint = muted.withValues(alpha: 0.5);
    final state = widget.state;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: hint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _title,
                autofocus: true,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                onChanged: widget.onTitleChanged,
                // Providing this keeps the keyboard open when the title is
                // empty; Done on a blank title is a no-op, not a dismissal.
                onEditingComplete: widget.onSubmit,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 16,
                  color: scheme.onSurface,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: 'What needs to be done?',
                  hintStyle: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: 16,
                    color: hint,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (state.notesVisible) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            focusNode: _notesFocus,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            onChanged: widget.onNotesChanged,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontSize: 14,
              color: scheme.onSurface,
            ),
            decoration: InputDecoration.collapsed(
              hintText: 'Add details',
              hintStyle: theme.textTheme.bodyMedium!.copyWith(
                fontSize: 14,
                color: hint,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            _ActionIcon(
              icon: Icons.notes,
              size: 24,
              label: 'Add details',
              active: state.notesVisible,
              onTap: widget.onToggleNotes,
            ),
            const SizedBox(width: 16),
            _ActionIcon(
              icon: Icons.schedule,
              size: 24,
              label: 'Set date and time',
              active: state.reminderAt != null,
              onTap: () => _pickReminder(context),
            ),
            const SizedBox(width: 16),
            _ActionIcon(
              icon: state.isStarred ? Icons.star : Icons.star_border,
              size: 24,
              label: 'Star',
              active: state.isStarred,
              onTap: widget.onToggleStar,
            ),
          ],
        ),
      ],
    );
  }
}

/// An icon in the actions row. The drawn pill (8 x 6 padding, 14 radius) is
/// what gets the active tint; the tappable area around it is larger so the
/// icon is not a thin target. Null [onTap] renders it disabled.
class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.size,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final double size;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppColors>()!.mutedForeground;
    final primary = theme.colorScheme.primary;
    final color = active
        ? primary
        : onTap == null
        ? muted.withValues(alpha: 0.5)
        : muted;

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}
