import 'package:flutter_test/flutter_test.dart';
import 'package:santian/tasks/models/repeat.dart';
import 'package:santian/tasks/repeat_advance.dart';

Repeat _freq(RepeatFrequency frequency, {List<int> weekdays = const []}) => Repeat()
  ..frequency = frequency
  ..weekdays = weekdays;

Repeat _custom(RepeatUnit unit, int interval, {List<int> weekdays = const []}) => Repeat()
  ..frequency = RepeatFrequency.custom
  ..interval = interval
  ..unit = unit
  ..weekdays = weekdays;

void main() {
  group('daily', () {
    test('advances by one day', () {
      expect(
        nextOccurrence(DateTime(2026, 9, 21, 9), _freq(RepeatFrequency.daily)),
        DateTime(2026, 9, 22, 9),
      );
    });

    test('custom, unit days, interval 3', () {
      expect(
        nextOccurrence(DateTime(2026, 9, 21, 9), _custom(RepeatUnit.days, 3)),
        DateTime(2026, 9, 24, 9),
      );
    });

    test('crosses a month boundary', () {
      expect(
        nextOccurrence(DateTime(2026, 9, 30, 9), _freq(RepeatFrequency.daily)),
        DateTime(2026, 10, 1, 9),
      );
    });

    test('preserves time of day', () {
      expect(
        nextOccurrence(DateTime(2026, 9, 21, 14, 37), _freq(RepeatFrequency.daily)),
        DateTime(2026, 9, 22, 14, 37),
      );
    });
  });

  group('weekly, no weekdays selected', () {
    test('advances by 7 days', () {
      expect(
        nextOccurrence(DateTime(2026, 9, 21, 9), _freq(RepeatFrequency.weekly)),
        DateTime(2026, 9, 28, 9),
      );
    });

    test('custom, unit weeks, interval 2, no weekdays', () {
      expect(
        nextOccurrence(DateTime(2026, 9, 21, 9), _custom(RepeatUnit.weeks, 2)),
        DateTime(2026, 10, 5, 9),
      );
    });
  });

  group('weekly with selected weekdays', () {
    // 2026-09-21 is a Monday.
    test('finds the next matching weekday later in the same week', () {
      final repeat = _freq(RepeatFrequency.weekly, weekdays: [1, 4]); // Mon, Thu
      expect(
        nextOccurrence(DateTime(2026, 9, 21, 9), repeat), // Mon -> Thu
        DateTime(2026, 9, 24, 9),
      );
    });

    test('wraps to the matching weekday in the following week', () {
      final repeat = _freq(RepeatFrequency.weekly, weekdays: [1, 4]); // Mon, Thu
      expect(
        nextOccurrence(DateTime(2026, 9, 24, 9), repeat), // Thu -> next Mon
        DateTime(2026, 9, 28, 9),
      );
    });

    test('a single selected weekday advances by exactly one week', () {
      final repeat = _freq(RepeatFrequency.weekly, weekdays: [1]); // Mon only
      expect(
        nextOccurrence(DateTime(2026, 9, 21, 9), repeat),
        DateTime(2026, 9, 28, 9),
      );
    });

    group('interval > 1', () {
      test('a match later in the current (active) week ignores the interval', () {
        // Completing Monday with Mon+Thu selected still finds Thursday in
        // the same week, regardless of how many weeks apart active weeks are.
        final repeat = _custom(RepeatUnit.weeks, 2, weekdays: [1, 4]);
        expect(
          nextOccurrence(DateTime(2026, 9, 21, 9), repeat), // Mon -> Thu, same week
          DateTime(2026, 9, 24, 9),
        );
      });

      test('past the last match in the active week, skips interval-1 extra weeks', () {
        // Mon+Thu selected, interval 2: completing Thursday (the last match
        // in the active week) jumps to Monday two weeks later, not next week.
        final repeat = _custom(RepeatUnit.weeks, 2, weekdays: [1, 4]);
        expect(
          nextOccurrence(DateTime(2026, 9, 24, 9), repeat), // Thu -> Mon, +2 weeks
          DateTime(2026, 10, 5, 9),
        );
      });

      test('interval 3 skips two extra weeks', () {
        final repeat = _custom(RepeatUnit.weeks, 3, weekdays: [1]);
        expect(
          nextOccurrence(DateTime(2026, 9, 21, 9), repeat), // Mon -> Mon, +3 weeks
          DateTime(2026, 10, 12, 9),
        );
      });
    });
  });

  group('monthly', () {
    test('same day next month', () {
      expect(
        nextOccurrence(DateTime(2026, 9, 15, 9), _freq(RepeatFrequency.monthly)),
        DateTime(2026, 10, 15, 9),
      );
    });

    test('clamps Jan 31 to Feb 28 in a non-leap year', () {
      expect(
        nextOccurrence(DateTime(2027, 1, 31, 9), _freq(RepeatFrequency.monthly)),
        DateTime(2027, 2, 28, 9),
      );
    });

    test('clamps Jan 31 to Feb 29 in a leap year', () {
      expect(
        nextOccurrence(DateTime(2028, 1, 31, 9), _freq(RepeatFrequency.monthly)),
        DateTime(2028, 2, 29, 9),
      );
    });

    test('crosses a year boundary', () {
      expect(
        nextOccurrence(DateTime(2026, 12, 15, 9), _freq(RepeatFrequency.monthly)),
        DateTime(2027, 1, 15, 9),
      );
    });

    test('custom, unit months, interval 3, clamps at the far month', () {
      expect(
        nextOccurrence(DateTime(2026, 11, 30, 9), _custom(RepeatUnit.months, 3)),
        DateTime(2027, 2, 28, 9),
      );
    });
  });

  group('yearly', () {
    test('same day next year', () {
      expect(
        nextOccurrence(DateTime(2026, 9, 21, 9), _freq(RepeatFrequency.yearly)),
        DateTime(2027, 9, 21, 9),
      );
    });

    test('clamps Feb 29 to Feb 28 in the next (non-leap) year', () {
      expect(
        nextOccurrence(DateTime(2028, 2, 29, 9), _freq(RepeatFrequency.yearly)),
        DateTime(2029, 2, 28, 9),
      );
    });

    test('custom, unit years, interval 4, lands back on a leap day', () {
      expect(
        nextOccurrence(DateTime(2028, 2, 29, 9), _custom(RepeatUnit.years, 4)),
        DateTime(2032, 2, 29, 9),
      );
    });
  });

  test('no catch-up: advances exactly one occurrence regardless of how late', () {
    // A daily Task last done 2026-09-18, completed 3 days late on
    // 2026-09-21: nextOccurrence only knows the stored `current`, not "now",
    // so it always advances by exactly one day from where it was.
    expect(
      nextOccurrence(DateTime(2026, 9, 18, 9), _freq(RepeatFrequency.daily)),
      DateTime(2026, 9, 19, 9),
    );
  });
}
