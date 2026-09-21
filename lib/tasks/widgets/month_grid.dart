import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

const List<String> monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// A month-grid date picker: month navigation, a weekday header, and a grid
/// of days with at most one selected — the pattern committed in decision
/// 0004. Single-date selection only, no range. Reused by the reminder
/// picker's date step and, in #10, the deadline picker's calendar-only
/// dialog.
class MonthGrid extends StatefulWidget {
  const MonthGrid({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  /// Null shows no day highlighted; the grid still opens on the current month.
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<MonthGrid> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final base = widget.selectedDate ?? DateTime.now();
    _visibleMonth = DateTime(base.year, base.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.extension<AppColors>()!.mutedForeground;
    final selected = widget.selectedDate;

    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // `DateTime.weekday` is 1 (Monday) .. 7 (Sunday); the grid is Monday-first.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final rowCount = ((leadingBlanks + daysInMonth) / 7).ceil();

    Widget dayCell(int row, int col) {
      final day = row * 7 + col - leadingBlanks + 1;
      if (day < 1 || day > daysInMonth) {
        return const Expanded(child: SizedBox(height: 42));
      }
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      return Expanded(
        child: _DayCell(
          day: day,
          selected: selected != null && _isSameDate(selected, date),
          onTap: () => widget.onDateSelected(date),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                icon: Icons.chevron_left,
                label: 'Previous month',
                onTap: () => _changeMonth(-1),
              ),
              Text(
                '${monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: scheme.onSurface,
                ),
              ),
              _NavButton(
                icon: Icons.chevron_right,
                label: 'Next month',
                onTap: () => _changeMonth(1),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: Center(
                      child: Text(
                        label,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: muted.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          child: Column(
            children: [
              for (var row = 0; row < rowCount; row++)
                Row(
                  children: [for (var col = 0; col < 7; col++) dayCell(row, col)],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.selected, required this.onTap});

  final int day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$day',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 42,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scheme.primary : null,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).extension<AppColors>()!.mutedForeground;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 20, color: muted),
        ),
      ),
    );
  }
}
