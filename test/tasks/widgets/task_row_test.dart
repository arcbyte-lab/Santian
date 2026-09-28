import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santian/core/theme/app_colors.dart';
import 'package:santian/core/theme/app_theme.dart';
import 'package:santian/tasks/models/task.dart';
import 'package:santian/tasks/widgets/task_row.dart';

Future<void> _pump(WidgetTester tester, Task task) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: TaskRow(task: task)),
  ),
);

Task _task({DateTime? deadline, bool completed = false}) => Task()
  ..listId = 1
  ..title = 'Ship it'
  ..deadline = deadline
  ..isCompleted = completed;

void main() {
  testWidgets('no deadline line when deadline is unset', (tester) async {
    await _pump(tester, _task());

    expect(find.byIcon(Icons.calendar_today), findsNothing);
  });

  testWidgets('shows "Due <relative day>" with a calendar icon', (
    tester,
  ) async {
    final now = DateTime.now();
    await _pump(
      tester,
      _task(deadline: DateTime(now.year, now.month, now.day + 3)),
    );

    expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    expect(find.text('Due in 3 days'), findsOneWidget);
  });

  testWidgets('a deadline today reads "Due today"', (tester) async {
    await _pump(tester, _task(deadline: DateTime.now()));

    expect(find.text('Due today'), findsOneWidget);
  });

  testWidgets('the reminder reads "<relative day>, <time>"', (tester) async {
    final now = DateTime.now();
    await _pump(
      tester,
      _task()..reminderAt = DateTime(now.year, now.month, now.day - 1, 9),
    );

    expect(find.text('Yesterday, 9:00 AM'), findsOneWidget);
  });

  testWidgets("a future deadline's line is muted, not error-colored", (
    tester,
  ) async {
    final future = DateTime.now().add(const Duration(days: 30));
    await _pump(tester, _task(deadline: future));

    final muted = AppTheme.light.extension<AppColors>()!.mutedForeground;
    expect(tester.widget<Icon>(find.byIcon(Icons.calendar_today)).color, muted);
  });

  testWidgets("a past deadline's line turns colorScheme.error", (tester) async {
    final past = DateTime.now().subtract(const Duration(days: 1));
    await _pump(tester, _task(deadline: past));

    expect(
      tester.widget<Icon>(find.byIcon(Icons.calendar_today)).color,
      AppTheme.light.colorScheme.error,
    );
  });

  testWidgets(
    'a completed Task with a past deadline is not styled as overdue',
    (tester) async {
      final past = DateTime.now().subtract(const Duration(days: 1));
      await _pump(tester, _task(deadline: past, completed: true));

      final muted = AppTheme.light.extension<AppColors>()!.mutedForeground;
      expect(
        tester.widget<Icon>(find.byIcon(Icons.calendar_today)).color,
        muted,
      );
    },
  );

  testWidgets('a long title wraps, growing the row downward', (tester) async {
    await _pump(tester, _task());
    final oneLine = tester.getSize(find.text('Ship it')).height;
    final long = 'word ' * 40;
    await _pump(tester, _task()..title = long);

    expect(tester.getSize(find.text(long)).height, greaterThan(oneLine * 2));
    final circle = find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.maxWidth == 21,
    );
    expect(
      tester.getTopLeft(circle).dy,
      tester.getTopLeft(find.text(long)).dy,
      reason: 'the checkbox stays by the first line, not centered',
    );
  });

  testWidgets('the description shows, truncated at two lines', (tester) async {
    await _pump(tester, _task()..description = 'detail ' * 60);

    final text = tester.widget<Text>(find.text(('detail ' * 60).trim()));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('a blank description shows nothing', (tester) async {
    await _pump(tester, _task()..description = '   ');

    expect(find.byType(Text), findsOneWidget, reason: 'only the title');
  });

  testWidgets('the reminder time and deadline sit on one line', (tester) async {
    final now = DateTime.now();
    await _pump(
      tester,
      _task(deadline: now)..reminderAt = DateTime(now.year, now.month, now.day, 9),
    );

    final time = tester.getCenter(find.textContaining('9:00'));
    final date = tester.getCenter(find.text('Due today'));
    expect(time.dy, closeTo(date.dy, 1));
    expect(time.dx, lessThan(date.dx));
  });

  testWidgets('a reminder past from today is error-colored, today is muted', (
    tester,
  ) async {
    final now = DateTime.now();
    final error = AppTheme.light.colorScheme.error;
    final muted = AppTheme.light.extension<AppColors>()!.mutedForeground;

    await _pump(
      tester,
      _task()..reminderAt = DateTime(now.year, now.month, now.day - 1, 9),
    );
    expect(tester.widget<Text>(find.text('Yesterday, 9:00 AM')).style!.color, error);
    expect(tester.widget<Icon>(find.byIcon(Icons.schedule)).color, error);

    await _pump(
      tester,
      _task()..reminderAt = DateTime(now.year, now.month, now.day, 0, 1),
    );
    expect(tester.widget<Icon>(find.byIcon(Icons.schedule)).color, muted);
  });

  testWidgets("a completed task's past reminder stays muted", (tester) async {
    final now = DateTime.now();
    await _pump(
      tester,
      _task(completed: true)
        ..reminderAt = DateTime(now.year, now.month, now.day - 3, 9),
    );

    expect(
      tester.widget<Icon>(find.byIcon(Icons.schedule)).color,
      AppTheme.light.extension<AppColors>()!.mutedForeground,
    );
  });
}
