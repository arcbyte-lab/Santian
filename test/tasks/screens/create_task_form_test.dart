import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:santian/core/theme/app_colors.dart';
import 'package:santian/core/theme/app_theme.dart';
import 'package:santian/tasks/cubits/create_task_cubit.dart';
import 'package:santian/tasks/screens/create_task_form.dart';

class _Calls {
  final titles = <String>[];
  final notes = <String>[];
  var toggleNotes = 0;
  var toggleStar = 0;
  var submits = 0;
}

Future<_Calls> _pump(
  WidgetTester tester, {
  CreateTaskState state = const CreateTaskState(),
  ThemeData? theme,
}) async {
  final calls = _Calls();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(
        body: CreateTaskForm(
          state: state,
          onTitleChanged: calls.titles.add,
          onNotesChanged: calls.notes.add,
          onToggleNotes: () => calls.toggleNotes++,
          onToggleStar: () => calls.toggleStar++,
          onSubmit: () => calls.submits++,
        ),
      ),
    ),
  );
  return calls;
}

Finder _circle() => find.byWidgetPredicate((w) =>
    w is Container &&
    w.decoration is BoxDecoration &&
    (w.decoration as BoxDecoration).shape == BoxShape.circle);

void main() {
  testWidgets('shows the compose placeholder, the actions, and no notes field', (tester) async {
    await _pump(tester);

    expect(find.text('What needs to be done?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Add details'), findsNothing);
    expect(find.bySemanticsLabel('Add details'), findsOneWidget); // the toggle
    expect(find.bySemanticsLabel('Set date and time'), findsOneWidget);
    expect(find.bySemanticsLabel('Star'), findsOneWidget);
  });

  testWidgets('has no subtask entry point', (tester) async {
    await _pump(tester);

    expect(find.textContaining('ubtask'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('ubtask')), findsNothing);
  });

  testWidgets('the title field takes focus as soon as the sheet opens', (tester) async {
    await _pump(tester);
    await tester.pump();

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
  });

  testWidgets('typing reports the title', (tester) async {
    final calls = await _pump(tester);

    await tester.enterText(find.byType(TextField), 'Buy milk');

    expect(calls.titles.last, 'Buy milk');
  });

  testWidgets('the keyboard Done action submits', (tester) async {
    final calls = await _pump(tester);
    await tester.showKeyboard(find.byType(TextField));

    await tester.testTextInput.receiveAction(TextInputAction.done);

    expect(calls.submits, 1);
  });

  testWidgets('Done on an empty title keeps the keyboard open', (tester) async {
    await _pump(tester);
    await tester.showKeyboard(find.byType(TextField));

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isTrue);
  });

  testWidgets('the notes field appears when the state says so, and reports typing', (tester) async {
    final calls = await _pump(tester, state: const CreateTaskState(notesVisible: true));

    expect(find.text('Add details'), findsOneWidget); // the placeholder
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.enterText(find.byType(TextField).last, 'some details');

    expect(calls.notes.last, 'some details');
  });

  testWidgets('revealing the notes field moves focus into it', (tester) async {
    await _pump(tester);
    await tester.pump();
    List<EditableText> fields() =>
        tester.widgetList<EditableText>(find.byType(EditableText)).toList();
    expect(fields().single.focusNode.hasFocus, isTrue, reason: 'the title starts focused');

    await _pump(tester, state: const CreateTaskState(notesVisible: true));
    await tester.pump();

    final [title, notes] = fields();
    expect(notes.focusNode.hasFocus, isTrue);
    expect(title.focusNode.hasFocus, isFalse);
  });

  testWidgets('text typed after revealing notes goes to the notes, not the title', (tester) async {
    final before = await _pump(tester);
    await tester.pump();
    tester.testTextInput.enterText('Buy milk');
    expect(before.titles.last, 'Buy milk', reason: 'the title has focus at first');

    // The state now shows the notes field; each _pump installs fresh callbacks.
    final after = await _pump(
      tester,
      state: const CreateTaskState(title: 'Buy milk', notesVisible: true),
    );
    await tester.pump();

    // Typed into whichever field has focus, as a person at the keyboard would.
    tester.testTextInput.enterText('oat milk if they have it');

    expect(after.notes.last, 'oat milk if they have it');
    expect(after.titles, isEmpty, reason: 'nothing more may reach the title');
  });

  testWidgets('tapping the notes and star icons calls their toggles', (tester) async {
    final calls = await _pump(tester);

    await tester.tap(find.bySemanticsLabel('Add details'));
    await tester.tap(find.bySemanticsLabel('Star'));
    await tester.tap(find.bySemanticsLabel('Star'));

    expect(calls.toggleNotes, 1);
    expect(calls.toggleStar, 2);
  });

  testWidgets('the star shows filled only when starred', (tester) async {
    await _pump(tester);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);

    await _pump(tester, state: const CreateTaskState(isStarred: true));
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNothing);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.star)).color,
      AppTheme.light.colorScheme.primary,
    );
  });

  testWidgets('the notes icon is tinted only while notes are showing', (tester) async {
    final primary = AppTheme.light.colorScheme.primary;
    final muted = AppTheme.light.extension<AppColors>()!.mutedForeground;

    await _pump(tester);
    expect(tester.widget<Icon>(find.byIcon(Icons.notes)).color, muted);

    await _pump(tester, state: const CreateTaskState(notesVisible: true));
    expect(tester.widget<Icon>(find.byIcon(Icons.notes)).color, primary);
  });

  testWidgets('the date and time icon is disabled until its ticket', (tester) async {
    final calls = await _pump(tester);
    final muted = AppTheme.light.extension<AppColors>()!.mutedForeground;

    await tester.tap(find.byIcon(Icons.schedule));

    expect(tester.takeException(), isNull);
    expect(calls.toggleNotes + calls.toggleStar + calls.submits, 0);
    expect(tester.widget<Icon>(find.byIcon(Icons.schedule)).color, muted.withValues(alpha: 0.5));
  });

  testWidgets('the compose circle is outlined in primary once there is a title', (tester) async {
    await _pump(tester);
    var box = tester.widget<Container>(_circle()).decoration as BoxDecoration;
    expect((box.border as Border).top.color, AppTheme.light.colorScheme.outline);

    await _pump(tester, state: const CreateTaskState(title: 'x'));
    box = tester.widget<Container>(_circle()).decoration as BoxDecoration;
    expect((box.border as Border).top.color, AppTheme.light.colorScheme.primary);
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('renders without errors in ${brightness.name} mode', (tester) async {
      await _pump(
        tester,
        state: const CreateTaskState(title: 'x', notesVisible: true, isStarred: true),
        theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      );

      expect(tester.takeException(), isNull);
    });
  }
}
