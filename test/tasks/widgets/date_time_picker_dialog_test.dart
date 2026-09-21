import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santian/core/theme/app_theme.dart';
import 'package:santian/tasks/widgets/date_time_picker_dialog.dart';

class _Host extends StatelessWidget {
  const _Host({required this.onOpen, this.initial});

  final ValueChanged<DateTime?> onOpen;
  final DateTime? initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              onOpen(await showDateTimePickerDialog(context, initial: initial));
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Cancel discards everything and returns null', (tester) async {
    DateTime? result = DateTime(1999);
    await tester.pumpWidget(_Host(
      initial: DateTime(2026, 9, 21),
      onOpen: (d) => result = d,
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  // A fresh Create Task open has no initial value at all: `reminderAt` starts
  // null, so the dialog defaults `_date` to today and leaves `_time` unset.
  // `DateTime(2026, 9, 21)` (implicit midnight) is not a real production
  // input for this dialog — a stored `reminderAt` is never genuinely
  // midnight, since Done always fills in a time — so these tests open fresh
  // instead of feeding it a fake date-only `initial`.
  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  testWidgets('Done with no date or time picked defaults to today at 9:00 AM', (tester) async {
    DateTime? result;
    await tester.pumpWidget(_Host(onOpen: (d) => result = d));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final expected = today();
    expect(result, DateTime(expected.year, expected.month, expected.day, 9, 0));
  });

  testWidgets('tapping a day changes which date Done commits', (tester) async {
    DateTime? result;
    await tester.pumpWidget(_Host(onOpen: (d) => result = d));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('10'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    final expected = today();
    expect(result, DateTime(expected.year, expected.month, 10, 9, 0));
  });

  testWidgets('Set time opens the native time picker and updates the row label', (tester) async {
    DateTime? result;
    await tester.pumpWidget(_Host(onOpen: (d) => result = d));
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

    final expected = today();
    expect(result, DateTime(expected.year, expected.month, expected.day, 9, 0));
  });
}
