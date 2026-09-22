import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:santian/tasks/cubits/tasks_list_cubit.dart';
import 'package:santian/tasks/cubits/tasks_list_state.dart';
import 'package:santian/tasks/models/task.dart';
import 'package:santian/tasks/models/task_list.dart';
import 'package:santian/tasks/repository/list_repository.dart';
import 'package:santian/tasks/repository/task_repository.dart';

import '../../support/test_isar.dart';

/// Resolves with the first state (the current one, or a later one) that
/// satisfies [test]. Fails after a timeout instead of hanging.
Future<TasksListState> until(
  TasksListCubit cubit,
  bool Function(TasksListState) test,
) async {
  if (test(cubit.state)) return cubit.state;
  try {
    return await cubit.stream.firstWhere(test).timeout(const Duration(seconds: 5));
  } on TimeoutException {
    throw TestFailure('Timed out waiting for a state. Last state: ${describe(cubit.state)}');
  }
}

List<String> titles(TasksListState s) => s.tasks.map((t) => t.title).toList();

String describe(TasksListState s) {
  final tab = s.activeTab;
  final tabText = switch (tab) {
    null => 'none',
    StarredTab() => 'Star',
    ListTab(:final listId) => 'List $listId',
  };
  return 'lists=${s.lists.map((l) => l.id).toList()} tab=$tabText '
      'tasks=${titles(s)} loading=${s.isLoading}';
}

void main() {
  late TestIsar db;
  late Isar isar;
  late TasksListCubit cubit;

  Future<int> addList(String name) => isar.writeTxn(() => isar.taskLists.put(
        TaskList()
          ..name = name
          ..icon = 'rocket'
          ..color = 0xFF0284C7,
      ));

  Future<int> addTask(
    int listId,
    String title, {
    DateTime? at,
    bool starred = false,
    bool done = false,
  }) =>
      isar.writeTxn(() => isar.tasks.put(
            Task()
              ..listId = listId
              ..title = title
              ..reminderAt = at
              ..isStarred = starred
              ..isCompleted = done,
          ));

  TasksListCubit newCubit() =>
      TasksListCubit(tasks: TaskRepository(isar), lists: ListRepository(isar));

  setUp(() async {
    db = await TestIsar.open();
    isar = db.isar;
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  final nine = DateTime(2026, 9, 21, 9);
  final ten = DateTime(2026, 9, 21, 10);

  test('with no Lists, a default one is created and made active', () async {
    cubit = newCubit();

    final state = await until(cubit, (s) => !s.isLoading && s.activeTab != null);

    expect(state.lists.map((l) => l.name), ['My Tasks']);
    expect(state.activeTab, ListTab(state.lists.single.id));
    expect(state.tasks, isEmpty);
  });

  test('opens on the first List, tasks in display order', () async {
    final first = await addList('Personal Interest');
    await addList('My Tasks');
    await addTask(first, 'no reminder');
    await addTask(first, 'done', at: nine, done: true);
    await addTask(first, 'later', at: ten);
    await addTask(first, 'earlier', at: nine);

    cubit = newCubit();
    final state = await until(
      cubit,
      (s) => s.activeTab == ListTab(first) && !s.isLoading,
    );

    expect(state.lists.map((l) => l.name), ['Personal Interest', 'My Tasks']);
    expect(titles(state), ['earlier', 'later', 'no reminder', 'done']);
  });

  test('selecting another List shows only that List\'s tasks', () async {
    final first = await addList('Personal Interest');
    final second = await addList('My Tasks');
    await addTask(first, 'in first');
    await addTask(second, 'in second');

    cubit = newCubit();
    await until(cubit, (s) => s.activeTab == ListTab(first) && !s.isLoading);

    cubit.selectTab(ListTab(second));
    final state = await until(
      cubit,
      (s) => s.activeTab == ListTab(second) && !s.isLoading,
    );

    expect(titles(state), ['in second']);
  });

  test('Star shows starred tasks across every List', () async {
    final first = await addList('Personal Interest');
    final second = await addList('My Tasks');
    await addTask(first, 'starred one', starred: true, at: ten);
    await addTask(first, 'plain');
    await addTask(second, 'starred two', starred: true, at: nine);

    cubit = newCubit();
    await until(cubit, (s) => s.activeTab == ListTab(first) && !s.isLoading);

    cubit.selectTab(const StarredTab());
    final state = await until(
      cubit,
      (s) => s.activeTab == const StarredTab() && !s.isLoading,
    );

    expect(titles(state), ['starred two', 'starred one']);
  });

  test('a write to Isar reaches the state with no manual refresh', () async {
    final list = await addList('Personal Interest');
    await addTask(list, 'existing', at: ten);
    cubit = newCubit();
    await until(cubit, (s) => titles(s).length == 1);

    await addTask(list, 'added later', at: nine);
    final afterAdd = await until(cubit, (s) => titles(s).length == 2);
    expect(titles(afterAdd), ['added later', 'existing']);

    final existing = (await isar.tasks.filter().titleEqualTo('existing').findFirst())!;
    existing.isCompleted = true;
    await isar.writeTxn(() => isar.tasks.put(existing));
    final afterComplete = await until(
      cubit,
      (s) => s.tasks.any((t) => t.isCompleted),
    );
    expect(titles(afterComplete), ['added later', 'existing']);
    expect(afterComplete.tasks.last.isCompleted, isTrue);
  });

  test('deleting the active List falls back to the first remaining one', () async {
    final first = await addList('Personal Interest');
    final second = await addList('My Tasks');
    await addTask(first, 'in first');
    cubit = newCubit();
    await until(cubit, (s) => s.activeTab == ListTab(first) && !s.isLoading);
    cubit.selectTab(ListTab(second));
    await until(cubit, (s) => s.activeTab == ListTab(second));

    await isar.writeTxn(() => isar.taskLists.delete(second));

    final state = await until(
      cubit,
      (s) => s.activeTab == ListTab(first) && titles(s).isNotEmpty,
    );
    expect(state.lists.map((l) => l.id), [first]);
  });

  test('selecting the tab that is already active does nothing', () async {
    final list = await addList('Personal Interest');
    cubit = newCubit();
    final settled = await until(
      cubit,
      (s) => s.activeTab == ListTab(list) && !s.isLoading,
    );

    cubit.selectTab(ListTab(list));

    expect(identical(cubit.state, settled), isTrue);
  });

  group('toggleCompleted', () {
    test('a completed Task drops below the incomplete ones, and toggling again restores it', () async {
      final list = await addList('Personal Interest');
      await addTask(list, 'first', at: nine);
      await addTask(list, 'second', at: ten);
      await addTask(list, 'third');
      cubit = newCubit();
      final opened = await until(cubit, (s) => s.tasks.length == 3);
      expect(titles(opened), ['first', 'second', 'third']);

      cubit.toggleCompleted(opened.tasks.first);
      final completed = await until(cubit, (s) => s.tasks.any((t) => t.isCompleted));

      expect(titles(completed), ['second', 'third', 'first']);
      expect(completed.tasks.last.isCompleted, isTrue);

      cubit.toggleCompleted(completed.tasks.last);
      final restored = await until(cubit, (s) => s.tasks.every((t) => !t.isCompleted));

      expect(titles(restored), ['first', 'second', 'third']);
    });

    test('a completed starred Task stays under Star, in the completed position', () async {
      final list = await addList('Personal Interest');
      await addTask(list, 'plain starred', at: ten, starred: true);
      await addTask(list, 'to complete', at: nine, starred: true);
      cubit = newCubit();
      await until(cubit, (s) => s.activeTab is ListTab && !s.isLoading);
      cubit.selectTab(const StarredTab());
      final onStar = await until(cubit, (s) => s.activeTab == const StarredTab() && s.tasks.length == 2);
      expect(titles(onStar), ['to complete', 'plain starred']);

      cubit.toggleCompleted(onStar.tasks.first);
      final after = await until(cubit, (s) => s.tasks.any((t) => t.isCompleted));

      expect(titles(after), ['plain starred', 'to complete']);
    });
  });

  group('the List a new Task goes into', () {
    test('is the active List', () async {
      final first = await addList('Personal Interest');
      final second = await addList('My Tasks');
      cubit = newCubit();
      final opened = await until(cubit, (s) => s.activeTab == ListTab(first));
      expect(opened.createListId, first);

      cubit.selectTab(ListTab(second));
      final switched = await until(cubit, (s) => s.activeTab == ListTab(second));

      expect(switched.createListId, second);
    });

    test('on Star is the last List that was active before it', () async {
      await addList('Personal Interest');
      final second = await addList('My Tasks');
      cubit = newCubit();
      await until(cubit, (s) => s.activeTab is ListTab && !s.isLoading);
      cubit.selectTab(ListTab(second));
      await until(cubit, (s) => s.activeTab == ListTab(second));

      cubit.selectTab(const StarredTab());
      final onStar = await until(cubit, (s) => s.activeTab == const StarredTab());

      expect(onStar.createListId, second);
    });

    test('on Star right after opening is the first List', () async {
      final first = await addList('Personal Interest');
      await addList('My Tasks');
      cubit = newCubit();
      await until(cubit, (s) => s.activeTab == ListTab(first));

      cubit.selectTab(const StarredTab());
      final onStar = await until(cubit, (s) => s.activeTab == const StarredTab());

      expect(onStar.createListId, first);
    });

    test('is null in the initial synchronous state, before any List - real '
        'or the auto-created default - has loaded', () {
      cubit = newCubit();

      expect(cubit.state.createListId, isNull);
    });
  });
}
