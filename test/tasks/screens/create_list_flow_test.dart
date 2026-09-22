import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:santian/tasks/models/task_list.dart';
import 'package:santian/tasks/screens/create_list_form.dart';

import '../../support/tasks_screen_harness.dart';

extension on TasksScreenHarness {
  Future<void> openAddListSheet() async {
    await tester.tap(find.bySemanticsLabel('Add list'));
    await tester.pumpAndSettle();
  }
}

void main() {
  semanticsTest('+, type a name, Done: the sheet closes and the new tab is '
      'inserted before + and selected', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await h.openAddListSheet();
    expect(find.byType(CreateListForm), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Errands');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    expect(find.byType(CreateListForm), findsNothing);
    expect(find.text('Errands'), findsOneWidget);
    final errandsX = tester.getTopLeft(find.text('Errands')).dx;
    final addListX = tester.getTopLeft(find.bySemanticsLabel('Add list')).dx;
    expect(errandsX, lessThan(addListX), reason: 'the new tab sits before +');

    final lists = await tester.runAsync(() => h.isar.taskLists.where().findAll());
    final created = lists!.singleWhere((l) => l.name == 'Errands');
    expect(created.icon, isNotEmpty);
    expect(created.color, isNot(0));
  });

  semanticsTest('the new List survives a restart', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await h.openAddListSheet();
    await tester.enterText(find.byType(TextField), 'Errands');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    final lists = await tester.runAsync(() => h.isar.taskLists.where().findAll());
    expect(lists!.map((l) => l.name), containsAll(['Personal Interest', 'Errands']));
  });

  semanticsTest('Done on an empty name keeps the sheet open and creates nothing',
      (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await h.openAddListSheet();
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    expect(find.byType(CreateListForm), findsOneWidget);
    final lists = await tester.runAsync(() => h.isar.taskLists.where().findAll());
    expect(lists, hasLength(1), reason: 'only the List the harness seeded');
  });

  semanticsTest('picking an icon and a color persists them', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await h.openAddListSheet();
    await tester.enterText(find.byType(TextField), 'Fitness');
    await tester.tap(find.bySemanticsLabel('dumbbell icon'));
    await tester.tap(find.bySemanticsLabel('Green color'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    final lists = await tester.runAsync(() => h.isar.taskLists.where().findAll());
    final created = lists!.singleWhere((l) => l.name == 'Fitness');
    expect(created.icon, 'dumbbell');
    expect(created.color, 0xFF16A34A);
  });

  semanticsTest('a default icon and color are already selected on open',
      (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await h.openAddListSheet();
    await tester.enterText(find.byType(TextField), 'No picks made');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    final lists = await tester.runAsync(() => h.isar.taskLists.where().findAll());
    final created = lists!.singleWhere((l) => l.name == 'No picks made');
    expect(created.icon, isNotEmpty);
    expect(created.color, isNot(0));
  });

  semanticsTest('a Task can be created in the new List right after making it',
      (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await h.openAddListSheet();
    await tester.enterText(find.byType(TextField), 'Errands');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    await tester.tap(find.bySemanticsLabel('Create task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pick up dry cleaning');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await h.settle();

    final lists = await tester.runAsync(() => h.isar.taskLists.where().findAll());
    final errands = lists!.singleWhere((l) => l.name == 'Errands');
    final tasks = await h.saved();
    expect(tasks.single.listId, errands.id);
    expect(find.text('Pick up dry cleaning'), findsOneWidget);
  });

  testWidgets('dismissing the sheet creates nothing', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);

    await tester.tap(find.bySemanticsLabel('Add list'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Never saved');
    await tester.tapAt(const Offset(20, 40)); // the dimmed area above the sheet
    await tester.pumpAndSettle();

    expect(find.byType(CreateListForm), findsNothing);
    final lists = await tester.runAsync(() => h.isar.taskLists.where().findAll());
    expect(lists, hasLength(1));
  });
}
