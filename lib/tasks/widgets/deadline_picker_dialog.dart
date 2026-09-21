import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import 'month_grid.dart';
import 'picker_button_row.dart';

/// Opens the deadline picker: a calendar-only variant of the reminder
/// picker — month grid plus Cancel/Done, no Set Time, no Repeat. `deadline`
/// is a target date, not a time-of-day commitment the way `reminderAt` is,
/// so it stores a date only. `repeat` is also already set once from the
/// reminder picker; a second Repeat entry point here would let it be set
/// twice from two places for one Task.
Future<DateTime?> showDeadlinePickerDialog(
  BuildContext context, {
  DateTime? initial,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => DeadlinePickerDialog(initial: initial),
  );
}

class DeadlinePickerDialog extends StatefulWidget {
  const DeadlinePickerDialog({super.key, this.initial});

  final DateTime? initial;

  @override
  State<DeadlinePickerDialog> createState() => _DeadlinePickerDialogState();
}

class _DeadlinePickerDialogState extends State<DeadlinePickerDialog> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final base = widget.initial ?? DateTime.now();
    _date = DateTime(base.year, base.month, base.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
          PickerButtonRow(
            onCancel: () => Navigator.of(context).pop(),
            onDone: () => Navigator.of(context).pop(_date),
          ),
        ],
      ),
    );
  }
}
