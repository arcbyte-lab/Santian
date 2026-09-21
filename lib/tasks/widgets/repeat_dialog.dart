import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../models/repeat.dart';

const List<String> _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const List<String> _weekdayFullNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

/// "Every 2 weeks" — the label shown on the reminder picker's Repeat row
/// once a repeat is configured. Omits the weekday selection for brevity.
String summarizeRepeat(Repeat repeat) {
  final unit = repeat.unit ??
      switch (repeat.frequency) {
        RepeatFrequency.daily => RepeatUnit.days,
        RepeatFrequency.weekly => RepeatUnit.weeks,
        RepeatFrequency.monthly => RepeatUnit.months,
        RepeatFrequency.yearly => RepeatUnit.years,
        RepeatFrequency.custom => RepeatUnit.days, // unreachable: unit is set
      };
  final n = repeat.interval;
  final unitLabel = switch (unit) {
    RepeatUnit.days => n == 1 ? 'day' : 'days',
    RepeatUnit.weeks => n == 1 ? 'week' : 'weeks',
    RepeatUnit.months => n == 1 ? 'month' : 'months',
    RepeatUnit.years => n == 1 ? 'year' : 'years',
  };
  return 'Every $n $unitLabel';
}

/// Opens the Repeat dialog, reached from the reminder picker's own Repeat
/// row. Back discards this dialog session's edits and returns null — the
/// caller keeps whatever repeat was already configured. Done always returns
/// a configured [Repeat]; there is no "off" state inside this dialog itself
/// — the caller's chip-style X on the Repeat row handles clearing, the same
/// vocabulary already taught by the reminder and deadline chips.
Future<Repeat?> showRepeatDialog(BuildContext context, {Repeat? initial}) {
  return showDialog<Repeat>(
    context: context,
    builder: (_) => RepeatDialog(initial: initial),
  );
}

class RepeatDialog extends StatefulWidget {
  const RepeatDialog({super.key, this.initial});

  final Repeat? initial;

  @override
  State<RepeatDialog> createState() => _RepeatDialogState();
}

class _RepeatDialogState extends State<RepeatDialog> {
  late int _interval;
  late RepeatUnit _unit;
  late Set<int> _weekdays;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) {
      _interval = 1;
      _unit = RepeatUnit.days;
      _weekdays = {};
      return;
    }
    if (initial.frequency == RepeatFrequency.custom) {
      _interval = initial.interval;
      _unit = initial.unit!;
    } else {
      _interval = 1;
      _unit = switch (initial.frequency) {
        RepeatFrequency.daily => RepeatUnit.days,
        RepeatFrequency.weekly => RepeatUnit.weeks,
        RepeatFrequency.monthly => RepeatUnit.months,
        RepeatFrequency.yearly => RepeatUnit.years,
        RepeatFrequency.custom => RepeatUnit.days, // unreachable
      };
    }
    _weekdays = initial.weekdays.toSet();
  }

  String _unitLabel(RepeatUnit unit) => switch (unit) {
        RepeatUnit.days => _interval == 1 ? 'day' : 'days',
        RepeatUnit.weeks => _interval == 1 ? 'week' : 'weeks',
        RepeatUnit.months => _interval == 1 ? 'month' : 'months',
        RepeatUnit.years => _interval == 1 ? 'year' : 'years',
      };

  void _done() {
    final repeat = Repeat();
    if (_interval == 1) {
      // N = 1: the matching plain frequency; interval/unit stay unset,
      // implied by frequency (per the data model, 1 otherwise).
      repeat.frequency = switch (_unit) {
        RepeatUnit.days => RepeatFrequency.daily,
        RepeatUnit.weeks => RepeatFrequency.weekly,
        RepeatUnit.months => RepeatFrequency.monthly,
        RepeatUnit.years => RepeatFrequency.yearly,
      };
      repeat.interval = 1;
      repeat.unit = null;
    } else {
      repeat.frequency = RepeatFrequency.custom;
      repeat.interval = _interval;
      repeat.unit = _unit;
    }
    // weekdays only ever applies to a weekly-shaped repeat.
    repeat.weekdays = _unit == RepeatUnit.weeks ? (_weekdays.toList()..sort()) : [];
    Navigator.of(context).pop(repeat);
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Back',
                  excludeSemantics: true,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back, size: 20, color: scheme.onSurface),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Repeat',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _done,
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
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Every',
                  style: theme.textTheme.bodyMedium!.copyWith(fontSize: 15, color: scheme.onSurface),
                ),
                const SizedBox(width: 12),
                _Stepper(value: _interval, onChanged: (v) => setState(() => _interval = v)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<RepeatUnit>(
                    isExpanded: true,
                    value: _unit,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final unit in RepeatUnit.values)
                        DropdownMenuItem(value: unit, child: Text(_unitLabel(unit))),
                    ],
                    onChanged: (unit) {
                      if (unit != null) setState(() => _unit = unit);
                    },
                  ),
                ),
              ],
            ),
            // Shown only when unit is week — `weekdays` doesn't apply to
            // day/month/year repeats.
            if (_unit == RepeatUnit.weeks) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var weekday = 1; weekday <= 7; weekday++)
                    _WeekdayChip(
                      letter: _weekdayLetters[weekday - 1],
                      fullName: _weekdayFullNames[weekday - 1],
                      selected: _weekdays.contains(weekday),
                      onTap: () => setState(() {
                        if (!_weekdays.add(weekday)) _weekdays.remove(weekday);
                      }),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.extension<AppColors>()!.mutedForeground;
    final canDecrease = value > 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          enabled: canDecrease,
          label: 'Decrease',
          excludeSemantics: true,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: canDecrease ? () => onChanged(value - 1) : null,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.remove,
                size: 18,
                color: canDecrease ? scheme.onSurface : muted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(fontSize: 15, color: scheme.onSurface),
          ),
        ),
        Semantics(
          button: true,
          label: 'Increase',
          excludeSemantics: true,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onChanged(value + 1),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.add, size: 18, color: scheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.letter,
    required this.fullName,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String fullName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).extension<AppColors>()!.mutedForeground;

    return Semantics(
      button: true,
      selected: selected,
      label: fullName,
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? scheme.primary : null,
            border: selected ? null : Border.all(color: scheme.outline, width: 1.5),
          ),
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? scheme.onPrimary : muted,
            ),
          ),
        ),
      ),
    );
  }
}
