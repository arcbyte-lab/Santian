import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:santian/core/theme/app_colors.dart';
import 'package:santian/core/theme/app_theme.dart';
import 'package:santian/tasks/cubits/tasks_list_state.dart';
import 'package:santian/tasks/models/task.dart';
import 'package:santian/tasks/models/task_list.dart';
import 'package:santian/tasks/screens/tasks_list_view.dart';
import 'package:santian/tasks/widgets/create_task_fab.dart';
import 'package:santian/tasks/widgets/task_row.dart';

import '../../support/tasks_screen_harness.dart' show semanticsTest;

TaskList _list(int id, String name, String icon) => TaskList()
  ..id = id
  ..name = name
  ..icon = icon
  ..color = 0xFF0284C7;

Task _task(int id, String title, {DateTime? at, bool done = false}) => Task()
  ..id = id
  ..listId = 1
  ..title = title
  ..reminderAt = at
  ..isCompleted = done;

final _lists = [
  _list(1, 'Personal Interest', 'rocket'),
  _list(2, 'My Tasks', 'footprints'),
  _list(3, 'Building', 'hammer'),
];

Future<void> _pump(
  WidgetTester tester,
  TasksListState state, {
  ValueChanged<TasksTab>? onTabSelected,
  VoidCallback? onCreateTask,
  VoidCallback? onAddList,
  ThemeData? theme,
  ThemeData? darkTheme,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      darkTheme: darkTheme ?? AppTheme.dark,
      themeMode: themeMode,
      home: TasksListView(
        state: state,
        onTabSelected: onTabSelected ?? (_) {},
        onCreateTask: onCreateTask,
        onAddList: onAddList,
      ),
    ),
  );
}

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  group('tab bar', () {
    testWidgets('shows Star first, then every List', (tester) async {
      await _pump(tester, TasksListState(lists: _lists, activeTab: const ListTab(2), isLoading: false));

      expect(find.byIcon(Icons.star_border), findsOneWidget);
      for (final name in ['Personal Interest', 'My Tasks', 'Building']) {
        expect(find.text(name), findsOneWidget);
      }
      final star = tester.getTopLeft(find.byIcon(Icons.star_border)).dx;
      final first = tester.getTopLeft(find.text('Personal Interest')).dx;
      final second = tester.getTopLeft(find.text('My Tasks')).dx;
      expect(star, lessThan(first));
      expect(first, lessThan(second));
    });

    testWidgets('the active List is bold and primary-tinted, the rest are not', (tester) async {
      await _pump(tester, TasksListState(lists: _lists, activeTab: const ListTab(2), isLoading: false));
      final scheme = AppTheme.light.colorScheme;
      final muted = AppTheme.light.extension<AppColors>()!.mutedForeground;

      expect(_styleOf(tester, 'My Tasks').fontWeight, FontWeight.w600);
      expect(_styleOf(tester, 'My Tasks').color, scheme.onSurface);
      expect(_styleOf(tester, 'Building').fontWeight, FontWeight.w400);
      expect(_styleOf(tester, 'Building').color, muted);

      expect(tester.widget<Icon>(find.byIcon(LucideIcons.footprints)).color, scheme.primary);
      expect(tester.widget<Icon>(find.byIcon(LucideIcons.hammer)).color, muted);
    });

    testWidgets('Star is the active tab when it is selected', (tester) async {
      await _pump(tester, TasksListState(lists: _lists, activeTab: const StarredTab(), isLoading: false));
      final scheme = AppTheme.light.colorScheme;

      expect(tester.widget<Icon>(find.byIcon(Icons.star_border)).color, scheme.primary);
      expect(_styleOf(tester, 'My Tasks').fontWeight, FontWeight.w400);
    });

    testWidgets('tapping a tab reports which one', (tester) async {
      final selected = <TasksTab>[];
      await _pump(
        tester,
        TasksListState(lists: _lists, activeTab: const ListTab(1), isLoading: false),
        onTabSelected: selected.add,
      );

      await tester.tap(find.text('Building'));
      await tester.tap(find.byIcon(Icons.star_border));
      await tester.tap(find.text('My Tasks'));

      expect(selected, [const ListTab(3), const StarredTab(), const ListTab(2)]);
    });

    semanticsTest('with no onAddList there is no + tab', (tester) async {
      await _pump(tester, TasksListState(lists: _lists, activeTab: const ListTab(1), isLoading: false));

      expect(find.bySemanticsLabel('Add list'), findsNothing);
    });

    semanticsTest('the + tab is last, after every List, and reports a tap', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        TasksListState(lists: _lists, activeTab: const ListTab(1), isLoading: false),
        onAddList: () => taps++,
      );

      final addList = find.bySemanticsLabel('Add list');
      expect(addList, findsOneWidget);
      final last = tester.getTopLeft(find.text('Building')).dx;
      expect(tester.getTopLeft(addList).dx, greaterThan(last));

      await tester.tap(addList);
      expect(taps, 1);
    });

    testWidgets('a long bar scrolls instead of overflowing', (tester) async {
      final many = [for (var i = 1; i <= 12; i++) _list(i, 'List number $i', 'rocket')];
      await _pump(tester, TasksListState(lists: many, activeTab: const ListTab(1), isLoading: false));

      expect(tester.takeException(), isNull);
      final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(tester.getTopLeft(find.text('List number 12')).dx, greaterThan(screenWidth));

      await tester.drag(find.byType(SingleChildScrollView), const Offset(-4000, 0));
      await tester.pump();

      expect(tester.getTopLeft(find.text('List number 12')).dx, lessThan(screenWidth));
    });
  });

  group('rows', () {
    testWidgets('show the title and the reminder time', (tester) async {
      await _pump(
        tester,
        TasksListState(
          lists: _lists,
          activeTab: const ListTab(1),
          isLoading: false,
          tasks: [_task(1, 'Morning workout', at: DateTime(2026, 9, 21, 7))],
        ),
      );

      expect(find.text('Morning workout'), findsOneWidget);
      expect(find.text('7:00 AM'), findsOneWidget);
    });

    testWidgets('a task with no reminder shows no time line', (tester) async {
      await _pump(
        tester,
        TasksListState(
          lists: _lists,
          activeTab: const ListTab(1),
          isLoading: false,
          tasks: [_task(1, 'Plan the week')],
        ),
      );

      expect(find.text('Plan the week'), findsOneWidget);
      expect(find.textContaining('AM'), findsNothing);
      expect(find.textContaining('PM'), findsNothing);
    });

    testWidgets('rows appear in the order the state gives them', (tester) async {
      await _pump(
        tester,
        TasksListState(
          lists: _lists,
          activeTab: const ListTab(1),
          isLoading: false,
          tasks: [_task(1, 'first'), _task(2, 'second'), _task(3, 'third')],
        ),
      );

      final ys = ['first', 'second', 'third']
          .map((t) => tester.getTopLeft(find.text(t)).dy)
          .toList();
      expect(ys, orderedEquals([...ys]..sort()));
    });

    testWidgets('a completed task is dimmed with a filled, checked circle', (tester) async {
      await _pump(
        tester,
        TasksListState(
          lists: _lists,
          activeTab: const ListTab(1),
          isLoading: false,
          tasks: [_task(1, 'open'), _task(2, 'finished', done: true)],
        ),
      );
      final scheme = AppTheme.light.colorScheme;
      final muted = AppTheme.light.extension<AppColors>()!.mutedForeground;

      expect(_styleOf(tester, 'open').color, scheme.onSurface);
      expect(_styleOf(tester, 'finished').color, muted);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('checkbox', () {
    semanticsTest('tapping it calls onToggleTask with that task', (tester) async {
      final toggled = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TasksListView(
            state: TasksListState(
              lists: _lists,
              activeTab: const ListTab(1),
              isLoading: false,
              tasks: [_task(1, 'one'), _task(2, 'two')],
            ),
            onTabSelected: (_) {},
            onToggleTask: (t) => toggled.add(t.id),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('two'));

      expect(toggled, [2]);
    });

    semanticsTest('its tap target reaches the row edge and the row height, not just the circle', (tester) async {
      final toggled = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TasksListView(
            state: TasksListState(
              lists: _lists,
              activeTab: const ListTab(1),
              isLoading: false,
              tasks: [_task(1, 'one', at: DateTime(2026, 9, 21, 9))],
            ),
            onTabSelected: (_) {},
            onToggleTask: (t) => toggled.add(t.id),
          ),
        ),
      );
      final row = tester.getRect(find.byType(TaskRow));

      await tester.tapAt(row.topLeft + const Offset(4, 4));
      await tester.tapAt(row.bottomLeft + const Offset(4, -4));

      expect(toggled, [1, 1]);
    });

    semanticsTest('tapping the title or the reminder time does not toggle', (tester) async {
      final toggled = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TasksListView(
            state: TasksListState(
              lists: _lists,
              activeTab: const ListTab(1),
              isLoading: false,
              tasks: [_task(1, 'one', at: DateTime(2026, 9, 21, 9))],
            ),
            onTabSelected: (_) {},
            onToggleTask: (t) => toggled.add(t.id),
          ),
        ),
      );

      await tester.tap(find.text('one'));
      await tester.tap(find.textContaining('9:00'));

      expect(toggled, isEmpty);
    });

    semanticsTest('is one control per row, named by the task and carrying its checked state', (tester) async {
      await _pump(
        tester,
        TasksListState(
          lists: _lists,
          activeTab: const ListTab(1),
          isLoading: false,
          tasks: [_task(1, 'open'), _task(2, 'finished', done: true)],
        ),
      );

      // One node per title: the checkbox, not the checkbox plus the text.
      final open = tester.getSemantics(find.bySemanticsLabel('open'));
      final finished = tester.getSemantics(find.bySemanticsLabel('finished'));
      expect(open.flagsCollection.isChecked, CheckedState.isFalse);
      expect(finished.flagsCollection.isChecked, CheckedState.isTrue);
    });

    semanticsTest('does nothing when there is no callback', (tester) async {
      await _pump(
        tester,
        TasksListState(
          lists: _lists,
          activeTab: const ListTab(1),
          isLoading: false,
          tasks: [_task(1, 'open')],
        ),
      );

      await tester.tap(find.bySemanticsLabel('open'));

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('shows the create-task button', (tester) async {
    await _pump(tester, TasksListState(lists: _lists, activeTab: const ListTab(1), isLoading: false));

    expect(find.bySemanticsLabel('Create task'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('tapping the create-task button calls onCreateTask', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      TasksListState(lists: _lists, activeTab: const ListTab(1), isLoading: false),
      onCreateTask: () => taps++,
    );

    await tester.tap(find.byIcon(Icons.add));

    expect(taps, 1);
  });

  testWidgets('with no onCreateTask the button does nothing', (tester) async {
    await _pump(tester, const TasksListState(isLoading: false));

    await tester.tap(find.byIcon(Icons.add));

    expect(tester.takeException(), isNull);
    final inkWell = tester.widget<InkWell>(
      find.descendant(of: find.byType(CreateTaskFab), matching: find.byType(InkWell)),
    );
    expect(inkWell.onTap, isNull);
  });

  testWidgets('renders with no Lists and no tasks', (tester) async {
    await _pump(tester, const TasksListState(isLoading: false));

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('renders without errors in ${mode.name} mode', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue =
          mode == ThemeMode.dark ? Brightness.dark : Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await _pump(
        tester,
        TasksListState(
          lists: _lists,
          activeTab: const ListTab(1),
          isLoading: false,
          tasks: [
            _task(1, 'Morning workout', at: DateTime(2026, 9, 21, 7)),
            _task(2, 'finished', done: true),
          ],
        ),
        themeMode: ThemeMode.system,
      );

      expect(tester.takeException(), isNull);
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.brightness, mode == ThemeMode.dark ? Brightness.dark : Brightness.light);
    });
  }
}
