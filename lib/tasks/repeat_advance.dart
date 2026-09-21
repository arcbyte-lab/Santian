import 'models/repeat.dart';

/// The next occurrence of a repeating field (`reminderAt` or `deadline`)
/// after [current], per [repeat]. Called independently on each field — not a
/// shared delta between them — so each keeps its own day-of-month identity.
///
/// No catch-up logic: this only ever advances by exactly one occurrence from
/// [current], never from "now." Completing a daily Task three days late
/// still only advances it by one day. Uses calendar arithmetic (the
/// `DateTime` constructor's day-overflow normalization), not `Duration`, so
/// the wall-clock time of day survives across DST and month/year rollovers.
DateTime nextOccurrence(DateTime current, Repeat repeat) {
  final n = repeat.interval;

  switch (repeat.frequency) {
    case RepeatFrequency.daily:
      return _addDays(current, n);

    case RepeatFrequency.weekly:
      return repeat.weekdays.isEmpty
          ? _addDays(current, 7 * n)
          : _nextWeekday(current, repeat.weekdays, n);

    case RepeatFrequency.monthly:
      return _addMonthsClamped(current, n);

    case RepeatFrequency.yearly:
      return _addMonthsClamped(current, n * 12);

    case RepeatFrequency.custom:
      switch (repeat.unit!) {
        case RepeatUnit.days:
          return _addDays(current, n);
        case RepeatUnit.weeks:
          return repeat.weekdays.isEmpty
              ? _addDays(current, 7 * n)
              : _nextWeekday(current, repeat.weekdays, n);
        case RepeatUnit.months:
          return _addMonthsClamped(current, n);
        case RepeatUnit.years:
          return _addMonthsClamped(current, n * 12);
      }
  }
}

/// The next date after [current] whose weekday is in [weekdays] (ISO
/// numbers, 1 = Monday .. 7 = Sunday).
///
/// [current]'s own week is the "active" week: any later match still in that
/// week wins regardless of [intervalWeeks], since interval only spaces
/// *active weeks* apart, not the days within one. Only once no match remains
/// in the active week does the next active week become `intervalWeeks`
/// weeks after [current]'s week (not simply the following week) — e.g. with
/// weekdays Mon+Thu and interval 2, completing Thursday (the last match in
/// the active week) jumps to the Monday two weeks later, not next week.
DateTime _nextWeekday(DateTime current, List<int> weekdays, int intervalWeeks) {
  final sorted = weekdays.toList()..sort();
  final currentWeekday = current.weekday;

  for (final weekday in sorted) {
    if (weekday > currentWeekday) {
      return _addDays(current, weekday - currentWeekday);
    }
  }

  final mondayOfCurrentWeek = _addDays(current, -(currentWeekday - 1));
  final targetMonday = _addDays(mondayOfCurrentWeek, 7 * intervalWeeks);
  return _addDays(targetMonday, sorted.first - 1);
}

/// [dt] plus [months], clamped to the last valid day of the target month —
/// Jan 31 + 1 month is Feb 28 (or 29), not an overflow into March.
/// Recommended in the spec, not confirmed by the owner.
DateTime _addMonthsClamped(DateTime dt, int months) {
  final totalMonths = dt.month - 1 + months;
  final year = dt.year + totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
  final day = dt.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : dt.day;
  return DateTime(year, month, day, dt.hour, dt.minute, dt.second, dt.millisecond, dt.microsecond);
}

DateTime _addDays(DateTime dt, int days) => DateTime(
      dt.year,
      dt.month,
      dt.day + days,
      dt.hour,
      dt.minute,
      dt.second,
      dt.millisecond,
      dt.microsecond,
    );
