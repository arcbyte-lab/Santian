import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santian/core/theme/app_colors.dart';
import 'package:santian/core/theme/app_theme.dart';

import '../../support/tasks_screen_harness.dart';

double _y(WidgetTester tester, String title) =>
    tester.getTopLeft(find.text(title)).dy;

Color? _titleColor(WidgetTester tester, String title) =>
    tester.widget<Text>(find.text(title)).style?.color;

void main() {
  semanticsTest('tapping the checkbox dims the row and moves it below the incomplete tasks; tapping again restores it', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');
    await h.addTask('beta');
    final muted = AppTheme.light.extension<AppColors>()!.mutedForeground;
    expect(_y(tester, 'alpha'), lessThan(_y(tester, 'beta')));
    expect(_titleColor(tester, 'alpha'), isNot(muted));

    await tester.tap(find.bySemanticsLabel('alpha'));
    await h.settle();

    expect(_y(tester, 'beta'), lessThan(_y(tester, 'alpha')));
    expect(_titleColor(tester, 'alpha'), muted);
    expect(_titleColor(tester, 'beta'), isNot(muted));
    expect((await h.saved()).singleWhere((t) => t.title == 'alpha').isCompleted, isTrue);

    await tester.tap(find.bySemanticsLabel('alpha'));
    await h.settle();

    expect(_y(tester, 'alpha'), lessThan(_y(tester, 'beta')));
    expect(_titleColor(tester, 'alpha'), isNot(muted));
    expect((await h.saved()).every((t) => !t.isCompleted), isTrue);
  });

  semanticsTest('tapping the title does not complete the Task', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha');

    await tester.tap(find.text('alpha'));
    await h.settle();

    expect((await h.saved()).single.isCompleted, isFalse);
  });

  semanticsTest('a completed starred Task stays under the Star tab, below the incomplete ones', (tester) async {
    final h = await TasksScreenHarness.start(tester, ['Personal Interest']);
    await h.addTask('alpha', starred: true);
    await h.addTask('beta', starred: true);
    await tester.tap(find.bySemanticsLabel('Starred'));
    await h.settle();

    await tester.tap(find.bySemanticsLabel('alpha'));
    await h.settle();

    expect(find.text('alpha'), findsOneWidget);
    expect(_y(tester, 'beta'), lessThan(_y(tester, 'alpha')));
  });
}
