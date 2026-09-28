import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:santian/tasks/models/task.dart';
import 'package:santian/tasks/models/task_list.dart';

import '../../support/tasks_screen_harness.dart';

extension on TasksScreenHarness {
  Future<void> pickOption(String item) async {
    await tester.tap(find.byTooltip('List options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  Future<void> putTask(String title, {bool done = false}) async {
    await tester.runAsync(() async {
      final list = (await isar.taskLists.where().findFirst())!;
      await isar.writeTxn(
        () => isar.tasks.put(
          Task()
            ..listId = list.id
            ..title = title
            ..isCompleted = done,
        ),
      );
    });
    await settle();
  }

  Future<List<TaskList>> lists() async =>
      (await tester.runAsync(() => isar.taskLists.where().findAll()))!;
}

void main() {
  testWidgets('Rename list saves the new name to the tab', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Errands']);

    await h.pickOption('Rename list');
    await tester.enterText(find.byType(TextField), 'Chores');
    await tester.tap(find.text('Save'));
    await h.settle();

    expect(find.text('Chores'), findsOneWidget);
    expect((await h.lists()).single.name, 'Chores');
  });

  testWidgets(
    'Delete list removes it and its Tasks, and moves to another List',
    (tester) async {
      final h = await TasksScreenHarness.start(tester, ['Errands', 'Work']);
      await h.putTask('Buy milk');

      await h.pickOption('Delete list');
      await tester.tap(find.text('Delete'));
      await h.settle();

      expect((await h.lists()).map((l) => l.name), ['Work']);
      expect(await h.saved(), isEmpty);
      await h.settle();
      debugPrint(
        tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join('|'),
      );
      expect(find.text('Errands'), findsNothing);
    },
  );

  testWidgets('Delete list is disabled on the only List', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Errands']);

    await h.pickOption('Delete list');

    expect(find.text('Delete'), findsNothing, reason: 'no confirm dialog');
    expect(await h.lists(), hasLength(1));
  });

  testWidgets('Delete all completed tasks keeps the open ones', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Errands']);
    await h.putTask('Open');
    await h.putTask('Done', done: true);

    await h.pickOption('Delete all completed tasks');
    await tester.tap(find.text('Delete'));
    await h.settle();

    expect((await h.saved()).map((t) => t.title), ['Open']);
  });
}
