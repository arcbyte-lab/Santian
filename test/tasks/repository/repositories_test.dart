import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:santian/tasks/models/task.dart';
import 'package:santian/tasks/models/task_list.dart';
import 'package:santian/tasks/repository/list_repository.dart';
import 'package:santian/tasks/repository/task_repository.dart';

import '../../support/test_isar.dart';

void main() {
  late TestIsar db;
  late Isar isar;
  late TaskRepository tasks;
  late ListRepository lists;

  Future<int> put(Task task) => isar.writeTxn(() => isar.tasks.put(task));

  Task task(int listId, String title, {bool starred = false}) => Task()
    ..listId = listId
    ..title = title
    ..isStarred = starred;

  Future<List<String>> next(Stream<List<Task>> stream, bool Function(List<Task>) test) async {
    final found = await stream.firstWhere(test).timeout(const Duration(seconds: 5));
    return found.map((t) => t.title).toList()..sort();
  }

  setUp(() async {
    db = await TestIsar.open();
    isar = db.isar;
    tasks = TaskRepository(isar);
    lists = ListRepository(isar);
  });

  tearDown(() => db.close());

  group('TaskRepository', () {
    test('watchByList emits only that List\'s tasks, and updates live', () async {
      await put(task(1, 'a'));
      await put(task(2, 'other list'));
      final stream = tasks.watchByList(1).asBroadcastStream();

      expect(await next(stream, (t) => t.isNotEmpty), ['a']);

      await put(task(1, 'b'));
      expect(await next(stream, (t) => t.length == 2), ['a', 'b']);
    });

    test('watchStarred spans every List and ignores unstarred tasks', () async {
      await put(task(1, 'starred one', starred: true));
      await put(task(2, 'starred two', starred: true));
      await put(task(1, 'plain'));

      expect(
        await next(tasks.watchStarred(), (t) => t.length == 2),
        ['starred one', 'starred two'],
      );
    });

    test('a watch started while a write is in flight still sees that write', () async {
      // Isar's own query.watch() misses a write that is already running when
      // it is registered (38 of 40 tries). watchQuery must not.
      for (var i = 1; i <= 25; i++) {
        final write = put(task(i, 'in flight $i'));
        final stream = tasks.watchByList(i);

        expect(
          await next(stream, (t) => t.isNotEmpty),
          ['in flight $i'],
          reason: 'iteration $i',
        );
        await write;
      }
    });

    test('a second watch still works after the first was cancelled', () async {
      final first = tasks.watchByList(1).listen((_) {});
      await pumpEventQueue();
      await first.cancel();

      await put(task(1, 'after cancel'));

      expect(await next(tasks.watchByList(1), (t) => t.isNotEmpty), ['after cancel']);
    });
  });

  group('ListRepository', () {
    test('watchAll emits Lists in creation order and updates live', () async {
      final stream = lists.watchAll().asBroadcastStream();
      Future<int> add(String name) => isar.writeTxn(() => isar.taskLists.put(TaskList()
        ..name = name
        ..icon = 'rocket'
        ..color = 1));

      await add('first');
      await add('second');
      final both = await stream
          .firstWhere((l) => l.length == 2)
          .timeout(const Duration(seconds: 5));
      expect(both.map((l) => l.name), ['first', 'second']);

      await add('third');
      final three = await stream
          .firstWhere((l) => l.length == 3)
          .timeout(const Duration(seconds: 5));
      expect(three.map((l) => l.name), ['first', 'second', 'third']);
    });
  });
}
