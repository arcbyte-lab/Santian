import 'package:flutter_test/flutter_test.dart';
import 'package:santian/tasks/deadline_status.dart';

void main() {
  group('isOverdue', () {
    test('a deadline of today is not overdue', () {
      expect(
        isOverdue(
          deadline: DateTime(2026, 9, 21),
          isCompleted: false,
          now: DateTime(2026, 9, 21, 23, 59),
        ),
        isFalse,
      );
    });

    test("yesterday's deadline is overdue", () {
      expect(
        isOverdue(
          deadline: DateTime(2026, 9, 20),
          isCompleted: false,
          now: DateTime(2026, 9, 21, 0, 0),
        ),
        isTrue,
      );
    });

    test('a deadline of today is not overdue even one minute before midnight', () {
      // The literal `now > deadline` reading would call this overdue at
      // 00:00:01 on the due date; comparing calendar dates instead keeps a
      // same-day deadline on-time all day.
      expect(
        isOverdue(
          deadline: DateTime(2026, 9, 21),
          isCompleted: false,
          now: DateTime(2026, 9, 21, 0, 1),
        ),
        isFalse,
      );
    });

    test("yesterday's deadline is overdue one minute after midnight", () {
      expect(
        isOverdue(
          deadline: DateTime(2026, 9, 20),
          isCompleted: false,
          now: DateTime(2026, 9, 21, 0, 1),
        ),
        isTrue,
      );
    });

    test('a future deadline is not overdue', () {
      expect(
        isOverdue(
          deadline: DateTime(2026, 9, 22),
          isCompleted: false,
          now: DateTime(2026, 9, 21),
        ),
        isFalse,
      );
    });

    test('a completed Task is never overdue, even with a past deadline', () {
      expect(
        isOverdue(
          deadline: DateTime(2020, 1, 1),
          isCompleted: true,
          now: DateTime(2026, 9, 21),
        ),
        isFalse,
      );
    });

    test('no deadline is never overdue', () {
      expect(
        isOverdue(deadline: null, isCompleted: false, now: DateTime(2026, 9, 21)),
        isFalse,
      );
    });

    test('a deadline that carries a time component still compares by calendar date', () {
      // `deadline` is meant to be date-only, but the function itself should
      // not assume that — it truncates to the calendar date either way.
      expect(
        isOverdue(
          deadline: DateTime(2026, 9, 21, 18, 30),
          isCompleted: false,
          now: DateTime(2026, 9, 21, 8),
        ),
        isFalse,
      );
    });
  });
}
