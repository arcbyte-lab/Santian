import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santian/tasks/models/subtask.dart';
import 'package:santian/tasks/subtask_order.dart';

import '../../support/tasks_screen_harness.dart';

const _inputKey = Key('subtask-input');

// Mirrors task_detail_flow_test.dart's own extension: real Isar I/O needs
// `h.settle()`, not just `pumpAndSettle()`.
extension on TasksScreenHarness {
  Future<void> openDetail(String title) async {
    await tester.tap(find.text(title));
    await settle();
  }

  Future<List<Subtask>> subtasksOf(String title) async {
    final task = (await saved()).singleWhere((t) => t.title == title);
    return sortSubtasksForDisplay(task.subtasks);
  }

  /// Types into the persistent Subtask input (found by key, not its hint
  /// text - the hint switches from "Add subtasks" to "Add subtask" the
  /// moment the first one exists) and presses Enter.
  Future<void> addSubtask(String title) async {
    await tester.enterText(find.byKey(_inputKey), title);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle();
  }
}

void main() {
  testWidgets('the input reads "Add subtasks" empty, "Add subtask" once one exists',
      (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');
    await h.openDetail('alpha');

    expect(find.text('Add subtasks'), findsOneWidget);

    await h.addSubtask('wash dishes');

    expect(find.text('Add subtasks'), findsNothing);
    expect(find.text('Add subtask'), findsOneWidget);
  });

  testWidgets('typing a title and pressing Enter creates and persists a Subtask, '
      'clearing the input', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');
    await h.openDetail('alpha');

    await h.addSubtask('wash dishes');

    expect(find.text('wash dishes'), findsOneWidget);
    final subtasks = await h.subtasksOf('alpha');
    expect(subtasks.map((s) => s.title), ['wash dishes']);
    expect(subtasks.single.order, 0);
    expect(
      tester.widget<TextField>(find.byKey(_inputKey)).controller!.text,
      isEmpty,
      reason: 'the input clears itself for the next entry',
    );
  });

  testWidgets('a second Subtask is appended after the first, by order', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');
    await h.openDetail('alpha');

    await h.addSubtask('wash dishes');
    await h.addSubtask('buy milk');

    final subtasks = await h.subtasksOf('alpha');
    expect(subtasks.map((s) => s.title), ['wash dishes', 'buy milk']);
    expect(subtasks.map((s) => s.order), [0, 1]);
  });

  testWidgets('editing a Subtask title on blur persists it', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');
    await h.openDetail('alpha');
    await h.addSubtask('wash dishes');

    await tester.enterText(find.widgetWithText(TextField, 'wash dishes'), 'wash the dishes');
    FocusManager.instance.primaryFocus?.unfocus();
    await h.settle();

    final subtasks = await h.subtasksOf('alpha');
    expect(subtasks.single.title, 'wash the dishes');
  });

  testWidgets('blurring a Subtask title left blank keeps the old title', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');
    await h.openDetail('alpha');
    await h.addSubtask('wash dishes');

    await tester.enterText(find.widgetWithText(TextField, 'wash dishes'), '   ');
    FocusManager.instance.primaryFocus?.unfocus();
    await h.settle();

    final subtasks = await h.subtasksOf('alpha');
    expect(subtasks.single.title, 'wash dishes');
  });

  semanticsTest('completing every Subtask does not complete the parent Task',
      (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');
    await h.openDetail('alpha');
    await h.addSubtask('wash dishes');
    await h.addSubtask('buy milk');

    final checkboxes = find.bySemanticsLabel('Subtask');
    expect(checkboxes, findsNWidgets(2));
    await tester.tap(checkboxes.at(0));
    await h.settle();
    await tester.tap(checkboxes.at(1));
    await h.settle();

    final subtasks = await h.subtasksOf('alpha');
    expect(subtasks.every((s) => s.isCompleted), isTrue);
    final task = (await h.saved()).single;
    expect(task.isCompleted, isFalse);
  });

  testWidgets('completing the parent Task does not complete its Subtasks', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');
    await h.openDetail('alpha');
    await h.addSubtask('wash dishes');

    await tester.tap(find.text('Mark completed'));
    await h.settle();

    final task = (await h.saved()).single;
    expect(task.isCompleted, isTrue);
    expect(task.subtasks.single.isCompleted, isFalse);
  });

  semanticsTest('deleting a Subtask removes it, with no undo offered', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');
    await h.openDetail('alpha');
    await h.addSubtask('wash dishes');
    await h.addSubtask('buy milk');

    await tester.tap(find.bySemanticsLabel('Delete subtask').first);
    await h.settle();

    final subtasks = await h.subtasksOf('alpha');
    expect(subtasks.map((s) => s.title), ['buy milk']);
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('dragging the first Subtask below the second persists the new order',
      (tester) async {
    // Drives the drop via the real ReorderableListView's own onReorder, the
    // same call a completed drag makes, rather than simulating the drag
    // gesture pixel-by-pixel: `SliverReorderableList`'s drop point is an
    // internal item-extent computation Flutter doesn't expose to tests, so a
    // simulated drag is exactly as fragile as it sounds and was, in fact,
    // tried here first and abandoned as unreliable. What's actually under
    // test - the cubit call, the persisted `order` values, the re-render -
    // is unaffected by which of the two triggers it.
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');
    await h.openDetail('alpha');
    await h.addSubtask('wash dishes');
    await h.addSubtask('buy milk');
    expect((await h.subtasksOf('alpha')).map((s) => s.title), ['wash dishes', 'buy milk']);

    tester.widget<ReorderableListView>(find.byType(ReorderableListView)).onReorder(0, 2);
    await h.settle();

    final subtasks = await h.subtasksOf('alpha');
    expect(subtasks.map((s) => s.title), ['buy milk', 'wash dishes']);
    expect(subtasks.map((s) => s.order), [0, 1]);
  });
}
