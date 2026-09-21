import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santian/core/theme/app_theme.dart';
import 'package:santian/tasks/widgets/month_grid.dart';

Future<DateTime?> _pump(
  WidgetTester tester, {
  DateTime? selectedDate,
}) async {
  DateTime? picked;
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: MonthGrid(
        selectedDate: selectedDate,
        onDateSelected: (d) => picked = d,
      ),
    ),
  ));
  return picked;
}

void main() {
  testWidgets('opens on the selected date\'s month', (tester) async {
    await _pump(tester, selectedDate: DateTime(2026, 9, 21));

    expect(find.text('September 2026'), findsOneWidget);
  });

  testWidgets('with no selected date, opens on the current month', (tester) async {
    await _pump(tester);

    final now = DateTime.now();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    expect(find.text('${monthNames[now.month - 1]} ${now.year}'), findsOneWidget);
  });

  testWidgets('the chevrons navigate months', (tester) async {
    await _pump(tester, selectedDate: DateTime(2026, 9, 21));

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(find.text('October 2026'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();
    expect(find.text('August 2026'), findsOneWidget);
  });

  testWidgets('tapping a day reports that date in the visible month', (tester) async {
    late DateTime picked;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: MonthGrid(
          selectedDate: DateTime(2026, 9, 21),
          onDateSelected: (d) => picked = d,
        ),
      ),
    ));

    await tester.tap(find.text('15'));

    expect(picked, DateTime(2026, 9, 15));
  });

  testWidgets('navigating months keeps reporting dates in the newly visible month', (tester) async {
    late DateTime picked;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: MonthGrid(
          selectedDate: DateTime(2026, 9, 21),
          onDateSelected: (d) => picked = d,
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    await tester.tap(find.text('15'));

    expect(picked, DateTime(2026, 10, 15));
  });
}
