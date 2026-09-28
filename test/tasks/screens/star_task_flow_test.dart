import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/tasks_screen_harness.dart';

void main() {
  semanticsTest('tapping a row\'s star stars it, and again unstars it', (
    tester,
  ) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');

    await tester.tap(find.bySemanticsLabel('Star alpha'));
    await h.settle();

    expect((await h.saved()).single.isStarred, isTrue);
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.text('Mark completed'), findsNothing, reason: 'no Task Detail');

    await tester.tap(find.bySemanticsLabel('Star alpha'));
    await h.settle();

    expect((await h.saved()).single.isStarred, isFalse);
  });
}
