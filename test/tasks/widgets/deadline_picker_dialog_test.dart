import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santian/core/theme/app_theme.dart';
import 'package:santian/tasks/widgets/deadline_picker_dialog.dart';

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
              onOpen(await showDeadlinePickerDialog(context, initial: initial));
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('has no Set Time or Repeat row — calendar and Cancel/Done only', (tester) async {
    await tester.pumpWidget(_Host(initial: DateTime(2026, 9, 21), onOpen: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('September 2026'), findsOneWidget);
    expect(find.text('Set time'), findsNothing);
    expect(find.text('Repeat'), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('Cancel discards everything and returns null', (tester) async {
    DateTime? result = DateTime(1999);
    await tester.pumpWidget(_Host(initial: DateTime(2026, 9, 21), onOpen: (d) => result = d));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('Done commits the selected date only, no time', (tester) async {
    DateTime? result;
    await tester.pumpWidget(_Host(initial: DateTime(2026, 9, 21), onOpen: (d) => result = d));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result, DateTime(2026, 9, 21));
  });

  testWidgets('tapping a day changes which date Done commits', (tester) async {
    DateTime? result;
    await tester.pumpWidget(_Host(initial: DateTime(2026, 9, 21), onOpen: (d) => result = d));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('15'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(result, DateTime(2026, 9, 15));
  });
}
