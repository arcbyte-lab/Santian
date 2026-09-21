import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/tasks_screen_harness.dart';

// `tester.pumpAndSettle()` alone is not safe here: opening Task Detail and
// deleting a Task both round-trip through real Isar I/O, which the fake test
// clock cannot resolve on its own — the same reason `TasksScreenHarness.settle`
// exists. Every interaction below settles through `h.settle()` instead.
extension on TasksScreenHarness {
  Future<void> openDetail(String title) async {
    await tester.tap(find.text(title));
    await settle();
  }
}

void main() {
  testWidgets('tapping a row outside the checkbox opens Task Detail', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');

    await h.openDetail('alpha');

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Mark completed'), findsOneWidget);
  });

  testWidgets('editing the title on blur persists and shows on the list row', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');

    await h.openDetail('alpha');
    await tester.enterText(find.byType(TextField).first, 'alpha edited');
    FocusManager.instance.primaryFocus?.unfocus();
    await h.settle();

    expect((await h.saved()).single.title, 'alpha edited');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await h.settle();

    expect(find.text('alpha edited'), findsOneWidget);
  });

  testWidgets('editing the description on blur persists', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');

    await h.openDetail('alpha');
    await tester.enterText(find.byType(TextField).last, 'some notes');
    FocusManager.instance.primaryFocus?.unfocus();
    await h.settle();

    expect((await h.saved()).single.description, 'some notes');
  });

  semanticsTest('the star icon toggles isStarred', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');

    await h.openDetail('alpha');
    await tester.tap(find.bySemanticsLabel('Star'));
    await h.settle();

    expect((await h.saved()).single.isStarred, isTrue);
  });

  testWidgets('Mark completed toggles completion and its own label', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');

    await h.openDetail('alpha');
    await tester.tap(find.text('Mark completed'));
    await h.settle();

    expect(find.text('Mark incomplete'), findsOneWidget);
    expect((await h.saved()).single.isCompleted, isTrue);

    await tester.tap(find.text('Mark incomplete'));
    await h.settle();

    expect(find.text('Mark completed'), findsOneWidget);
    expect((await h.saved()).single.isCompleted, isFalse);
  });

  testWidgets('setting a reminder shows a removable chip and persists it', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');

    await h.openDetail('alpha');
    expect(find.text('Add reminder'), findsOneWidget);

    await tester.tap(find.text('Add reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await h.settle();

    expect(find.text('Add reminder'), findsNothing);
    expect((await h.saved()).single.reminderAt, isNotNull);
  });

  semanticsTest('the X on the reminder chip clears reminderAt without reopening the picker', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');

    await h.openDetail('alpha');
    await tester.tap(find.text('Add reminder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await h.settle();
    expect((await h.saved()).single.reminderAt, isNotNull);

    await tester.tap(find.bySemanticsLabel('Remove reminder'));
    await h.settle();

    expect(find.text('Done'), findsNothing, reason: 'the picker did not reopen');
    expect(find.text('Add reminder'), findsOneWidget);
    expect((await h.saved()).single.reminderAt, isNull);
  });

  testWidgets('More, Delete removes the Task and closes the sheet with no confirm dialog', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');

    await h.openDetail('alpha');
    await tester.tap(find.byIcon(Icons.more_vert));
    await h.settle();
    await tester.tap(find.text('Delete'));
    await h.settle();

    expect(find.text('Mark completed'), findsNothing, reason: 'the sheet has closed');
    expect(await h.saved(), isEmpty);
    expect(find.text('Task deleted'), findsOneWidget);
  });

  testWidgets('Undo on the delete toast restores the Task with the same id', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');
    final originalId = (await h.saved()).single.id;

    await h.openDetail('alpha');
    await tester.tap(find.byIcon(Icons.more_vert));
    await h.settle();
    await tester.tap(find.text('Delete'));
    await h.settle();

    await tester.tap(find.text('Undo'));
    await h.settle();

    final restored = await h.saved();
    expect(restored, hasLength(1));
    expect(restored.single.id, originalId);
    expect(restored.single.title, 'alpha');
    expect(find.text('alpha'), findsOneWidget);
  });

  testWidgets('not tapping Undo leaves the delete in place', (tester) async {
    // The delete itself is immediate, not deferred until the toast expires
    // (see the More/Delete test); this only checks that doing nothing with
    // the toast does not undo it.
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');

    await h.openDetail('alpha');
    await tester.tap(find.byIcon(Icons.more_vert));
    await h.settle();
    await tester.tap(find.text('Delete'));
    await h.settle();

    expect(await h.saved(), isEmpty);
  });
}
