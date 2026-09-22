import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:santian/tasks/models/task_list.dart';
import 'package:santian/tasks/screens/create_task_form.dart';

import '../../support/tasks_screen_harness.dart';

extension on TasksScreenHarness {
  Future<void> openSheet() async {
    // Not `find.byIcon(Icons.add)`: the tab bar's own "+" (add-list) tab uses
    // the same icon and would make that finder ambiguous.
    await tester.tap(find.bySemanticsLabel('Create task'));
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('FAB, type a title, Done: the sheet closes and the Task appears', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await h.openSheet();
    expect(find.byType(CreateTaskForm), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Buy milk');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    expect(find.byType(CreateTaskForm), findsNothing);
    expect(find.text('Buy milk'), findsOneWidget);
    final tasks = await h.saved();
    expect(tasks.map((t) => t.title), ['Buy milk']);
    expect(tasks.single.listId, (await h.tester.runAsync(() => h.isar.taskLists.where().findFirst()))!.id);
  });

  testWidgets('Done on an empty title keeps the sheet open and creates nothing', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await h.openSheet();
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    expect(find.byType(CreateTaskForm), findsOneWidget);
    expect(await h.saved(), isEmpty);
  });

  testWidgets('notes and star are saved with the Task', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await h.openSheet();
    await tester.enterText(find.byType(TextField), 'Plan trip');
    await tester.tap(find.bySemanticsLabel('Star'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Add details').first);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));
    // Typed into whichever field has focus: revealing notes must move it there.
    await tester.pump();
    tester.testTextInput.enterText('book flights');

    // Enter in the notes field is a newline, so submit from the title field.
    await tester.showKeyboard(find.byType(TextField).first);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    final task = (await h.saved()).single;
    expect(task.title, 'Plan trip');
    expect(task.description, 'book flights');
    expect(task.isStarred, isTrue);
  });

  testWidgets('the clock icon sets a reminder that is saved with the Task', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await h.openSheet();
    await tester.enterText(find.byType(TextField), 'Morning workout');
    await tester.tap(find.bySemanticsLabel('Set date and time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    final task = (await h.saved()).single;
    expect(task.title, 'Morning workout');
    expect(task.reminderAt, isNotNull);
    expect(TimeOfDay.fromDateTime(task.reminderAt!), const TimeOfDay(hour: 9, minute: 0));
  });

  testWidgets('a Task is created in whichever List tab is active', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest', 'My Tasks']);
    final second = (await tester.runAsync(() => h.isar.taskLists.where().findAll()))!.last;

    await tester.tap(find.text('My Tasks'));
    await h.settle();
    await h.openSheet();
    await tester.enterText(find.byType(TextField), 'In the second list');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    final task = (await h.saved()).single;
    expect(task.listId, second.id);
    expect(find.text('In the second list'), findsOneWidget);
  });

  testWidgets('from the Star tab a Task goes into the last List, not into Star itself', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest', 'My Tasks']);
    final second = (await tester.runAsync(() => h.isar.taskLists.where().findAll()))!.last;

    await tester.tap(find.text('My Tasks'));
    await h.settle();
    await tester.tap(find.bySemanticsLabel('Starred'));
    await h.settle();
    await h.openSheet();
    await tester.enterText(find.byType(TextField), 'Made on Star');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    final task = (await h.saved()).single;
    expect(task.listId, second.id);
    expect(task.isStarred, isFalse, reason: 'Star is a filter, not a List; nothing is starred unless the user stars it');
  });

  testWidgets('dismissing the sheet creates nothing', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await h.openSheet();
    await tester.enterText(find.byType(TextField), 'Never saved');
    await tester.tapAt(const Offset(20, 40)); // the dimmed area above the sheet
    await tester.pumpAndSettle();

    expect(find.byType(CreateTaskForm), findsNothing);
    expect(await h.saved(), isEmpty);
  });

  testWidgets('starting with no Lists auto-creates a default one, and the '
      'button creates a Task into it', (tester) async {
    final h = await TasksScreenHarness.start(tester, []);
    // The default List's creation and its becoming active are two separate
    // reactive round trips through Isar's watch (empty -> [list] ->
    // activated); `start`'s own single `settle()` isn't reliably enough
    // margin for both, so the FAB can still be disabled right after it
    // returns. One more settle gives the second round trip room to land.
    await h.settle();

    await h.openSheet();
    await tester.enterText(find.byType(TextField), 'First ever task');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    final task = (await h.saved()).single;
    expect(task.title, 'First ever task');
    final defaultList = (await tester.runAsync(() => h.isar.taskLists.where().findFirst()))!;
    expect(defaultList.name, 'My Tasks');
    expect(task.listId, defaultList.id);
  });
}
