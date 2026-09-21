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

  testWidgets('shows a short date with a calendar icon when deadline is set', (tester) async {
    await _pump(tester, _task(deadline: DateTime(2026, 9, 20)));

    expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    expect(find.text('Sep 20'), findsOneWidget);
  });

  testWidgets("a future deadline's line is muted, not error-colored", (tester) async {
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

  testWidgets('a completed Task with a past deadline is not styled as overdue', (tester) async {
    final past = DateTime.now().subtract(const Duration(days: 1));
    await _pump(tester, _task(deadline: past, completed: true));

    final muted = AppTheme.light.extension<AppColors>()!.mutedForeground;
    expect(tester.widget<Icon>(find.byIcon(Icons.calendar_today)).color, muted);
  });
}
