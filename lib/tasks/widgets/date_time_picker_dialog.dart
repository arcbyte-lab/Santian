import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import 'month_grid.dart';
import 'picker_button_row.dart';

/// The time a date-only `reminderAt` selection defaults to. Proposed in the
/// spec, not confirmed by the owner — kept as one named constant so the
/// default is easy to revisit.
const TimeOfDay defaultReminderTime = TimeOfDay(hour: 9, minute: 0);

/// Opens the reminder picker: a month grid plus a "Set time" row that opens
/// the platform's native time picker. Cancel returns null, discarding
/// everything; Done returns the combined `DateTime` — a date-only pick
/// defaults its time to [defaultReminderTime]. The Repeat row is omitted
/// until #11.
Future<DateTime?> showDateTimePickerDialog(
  BuildContext context, {
  DateTime? initial,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => DateTimePickerDialog(initial: initial),
  );
}

class DateTimePickerDialog extends StatefulWidget {
  const DateTimePickerDialog({super.key, this.initial});

  final DateTime? initial;

  @override
  State<DateTimePickerDialog> createState() => _DateTimePickerDialogState();
}

class _DateTimePickerDialogState extends State<DateTimePickerDialog> {
  late DateTime _date;
  TimeOfDay? _time;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final base = initial ?? DateTime.now();
    _date = DateTime(base.year, base.month, base.day);
    _time = initial == null ? null : TimeOfDay.fromDateTime(initial);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? defaultReminderTime,
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  void _done() {
    final time = _time ?? defaultReminderTime;
    Navigator.of(context).pop(
      DateTime(_date.year, _date.month, _date.day, time.hour, time.minute),
    );
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
          PickerButtonRow(
            onCancel: () => Navigator.of(context).pop(),
            onDone: _done,
          ),
        ],
      ),
    );
  }
}
