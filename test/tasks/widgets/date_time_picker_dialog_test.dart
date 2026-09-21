import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santian/core/theme/app_theme.dart';
import 'package:santian/tasks/models/repeat.dart';
import 'package:santian/tasks/widgets/date_time_picker_dialog.dart';
import 'package:santian/tasks/widgets/repeat_dialog.dart';

/// The outer picker's own Done is also on screen once the Repeat dialog is
/// open (showDialog stacks routes; it doesn't remove the one underneath),
/// so `find.text('Done')` alone is ambiguous while the Repeat dialog shows.
Finder _repeatDialogDone() =>
    find.descendant(of: find.byType(RepeatDialog), matching: find.text('Done'));

typedef _Result = ({DateTime dateTime, Repeat? repeat});

class _Host extends StatelessWidget {
  const _Host({required this.onOpen, this.initial, this.initialRepeat});

  final ValueChanged<_Result?> onOpen;
  final DateTime? initial;
  final Repeat? initialRepeat;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              onOpen(await showDateTimePickerDialog(
                context,
                initial: initial,
                initialRepeat: initialRepeat,
              ));
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

// A fresh Create Task open has no initial value at all: `reminderAt` starts
// null, so the dialog defaults `_date` to today and leaves `_time` unset.
// `DateTime(2026, 9, 21)` (implicit midnight) is not a real production
// input for this dialog — a stored `reminderAt` is never genuinely
// midnight, since Done always fills in a time — so most tests open fresh
// instead of feeding it a fake date-only `initial`.
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  testWidgets('Cancel discards everything and returns null', (tester) async {
    _Result? result = (dateTime: DateTime(1999), repeat: null);
    await tester.pumpWidget(_Host(
      initial: DateTime(2026, 9, 21),
      onOpen: (r) => result = r,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('Done with no date or time picked defaults to today at 9:00 AM', (tester) async {
    _Result? result;
    await tester.pumpWidget(_Host(onOpen: (r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final expected = _today();
    expect(result?.dateTime, DateTime(expected.year, expected.month, expected.day, 9, 0));
    expect(result?.repeat, isNull);
  });

  testWidgets('tapping a day changes which date Done commits', (tester) async {
    _Result? result;
    await tester.pumpWidget(_Host(onOpen: (r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final expected = _today();
    expect(result?.dateTime, DateTime(expected.year, expected.month, 10, 9, 0));
  });

  testWidgets('Set time opens the native time picker and updates the row label', (tester) async {
    _Result? result;
    await tester.pumpWidget(_Host(onOpen: (r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Set time'), findsOneWidget);
    await tester.tap(find.text('Set time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Set time'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final expected = _today();
    expect(result?.dateTime, DateTime(expected.year, expected.month, expected.day, 9, 0));
  });

  group('Repeat row', () {
    testWidgets('configuring a repeat updates the row label and carries through Done', (tester) async {
      _Result? result;
      await tester.pumpWidget(_Host(onOpen: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Repeat'), findsOneWidget);
      await tester.tap(find.text('Repeat'));
      await tester.pumpAndSettle();
      // Every 1 day, the dialog's default: tap Done inside the Repeat dialog.
      await tester.tap(_repeatDialogDone());
      await tester.pumpAndSettle();

      expect(find.text('Every 1 day'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(result?.repeat?.frequency, RepeatFrequency.daily);
    });

    testWidgets('the X on a configured repeat clears it without reopening the dialog', (tester) async {
      // The handle must be released before the test ends, which addTearDown
      // is too late for (see TasksScreenHarness.semanticsTest).
      final handle = tester.ensureSemantics();
      try {
        final repeat = Repeat()..frequency = RepeatFrequency.weekly;
        _Result? result;
        await tester.pumpWidget(_Host(initialRepeat: repeat, onOpen: (r) => result = r));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Every 1 week'), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('Remove repeat'));
        await tester.pumpAndSettle();

        expect(find.text('Repeat'), findsOneWidget);
        expect(find.text('Every 1 week'), findsNothing);

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        expect(result?.repeat, isNull);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Back in the Repeat dialog discards edits, keeping what was already configured', (tester) async {
      final repeat = Repeat()..frequency = RepeatFrequency.weekly;
      _Result? result;
      await tester.pumpWidget(_Host(initialRepeat: repeat, onOpen: (r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Every 1 week'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add)); // bump the stepper, then abandon it
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Every 1 week'), findsOneWidget, reason: 'Back must not commit the bumped interval');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(result?.repeat?.frequency, RepeatFrequency.weekly);
      expect(result?.repeat?.interval, 1);
    });
  });
}
