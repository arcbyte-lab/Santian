/// Whether a Task with [deadline] is overdue: not completed, has a
/// [deadline], and that deadline's calendar date is before [now]'s calendar
/// date.
///
/// The spec says overdue is `now > deadline`, but `deadline` is date-only —
/// taken literally, a task due today would already read overdue at 00:00.
/// Comparing calendar dates instead means a deadline of today is not
/// overdue, only yesterday's (and earlier) is. This interpretation is not
/// confirmed by the owner; it lives in this one pure function so the rule is
/// easy to find and change if the owner rules otherwise.
///
/// Nothing about "was overdue" is stored anywhere — this is a computed
/// style, not a field, so it reverts the moment [isCompleted] flips to true
/// or [deadline] is cleared.
bool isOverdue({
  required DateTime? deadline,
  required bool isCompleted,
  DateTime? now,
}) {
  if (isCompleted || deadline == null) return false;
  final today = _dateOnly(now ?? DateTime.now());
  return _dateOnly(deadline).isBefore(today);
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
