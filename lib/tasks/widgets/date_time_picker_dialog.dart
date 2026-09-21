import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../models/repeat.dart';
import 'month_grid.dart';
import 'picker_button_row.dart';
import 'repeat_dialog.dart';

/// The time a date-only `reminderAt` selection defaults to. Proposed in the
/// spec, not confirmed by the owner — kept as one named constant so the
/// default is easy to revisit.
const TimeOfDay defaultReminderTime = TimeOfDay(hour: 9, minute: 0);

/// Opens the reminder picker: a month grid, a "Set time" row that opens the
/// platform's native time picker, and a Repeat row that opens
/// [showRepeatDialog]. Cancel returns null, discarding everything; Done
/// returns the combined date, time (a date-only pick defaults its time to
/// [defaultReminderTime]), and whatever repeat was configured, if any.
Future<({DateTime dateTime, Repeat? repeat})?> showDateTimePickerDialog(
  BuildContext context, {
  DateTime? initial,
  Repeat? initialRepeat,
}) {
  return showDialog(
    context: context,
    builder: (_) => DateTimePickerDialog(initial: initial, initialRepeat: initialRepeat),
  );
}

class DateTimePickerDialog extends StatefulWidget {
  const DateTimePickerDialog({super.key, this.initial, this.initialRepeat});

  final DateTime? initial;
  final Repeat? initialRepeat;

  @override
  State<DateTimePickerDialog> createState() => _DateTimePickerDialogState();
}

class _DateTimePickerDialogState extends State<DateTimePickerDialog> {
  late DateTime _date;
  TimeOfDay? _time;
  Repeat? _repeat;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final base = initial ?? DateTime.now();
    _date = DateTime(base.year, base.month, base.day);
    _time = initial == null ? null : TimeOfDay.fromDateTime(initial);
    _repeat = widget.initialRepeat;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? defaultReminderTime,
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _pickRepeat() async {
    final picked = await showRepeatDialog(context, initial: _repeat);
    if (picked != null && mounted) setState(() => _repeat = picked);
  }

  void _done() {
    final time = _time ?? defaultReminderTime;
    Navigator.of(context).pop((
      dateTime: DateTime(_date.year, _date.month, _date.day, time.hour, time.minute),
      repeat: _repeat,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.extension<AppColors>()!.mutedForeground;
    final time = _time;

    return Dialog(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MonthGrid(
            selectedDate: _date,
            onDateSelected: (date) => setState(() => _date = date),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          InkWell(
            onTap: _pickTime,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 20, color: muted),
                  const SizedBox(width: 16),
                  Text(
                    time == null ? 'Set time' : time.format(context),
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 15,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickRepeat,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.repeat, size: 20, color: muted),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _repeat == null ? 'Repeat' : summarizeRepeat(_repeat!),
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontSize: 15,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_repeat != null)
                  Semantics(
                    button: true,
                    label: 'Remove repeat',
                    excludeSemantics: true,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _repeat = null),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 16, color: muted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          PickerButtonRow(
            onCancel: () => Navigator.of(context).pop(),
            onDone: _done,
          ),
        ],
      ),
    );
  }
}
