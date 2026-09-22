import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:santian/tasks/models/repeat.dart';
import 'package:santian/tasks/models/subtask.dart';
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
    test('create saves the Task and returns its id', () async {
      final id = await tasks.create(task(3, 'made'));

      expect(id, isNot(Isar.autoIncrement));
      final saved = (await isar.tasks.get(id))!;
      expect(saved.title, 'made');
      expect(saved.listId, 3);
    });

    group('toggleCompleted', () {
      test('completes an incomplete Task', () async {
        final id = await put(task(1, 'a'));

        await tasks.toggleCompleted((await isar.tasks.get(id))!);

        expect((await isar.tasks.get(id))!.isCompleted, isTrue);
      });

      test('restores a completed Task', () async {
        final id = await put(task(1, 'a')..isCompleted = true);

        await tasks.toggleCompleted((await isar.tasks.get(id))!);

        expect((await isar.tasks.get(id))!.isCompleted, isFalse);
      });

      test('flips what is stored, so a second toggle undoes the first', () async {
        final stale = task(1, 'a');
        stale.id = await put(stale);

        await tasks.toggleCompleted(stale);
        await tasks.toggleCompleted(stale);

        expect((await isar.tasks.get(stale.id))!.isCompleted, isFalse);
      });

      test('changes nothing but completion', () async {
        final id = await put(task(1, 'a', starred: true)
          ..description = 'notes'
          ..reminderAt = DateTime(2026, 9, 21, 9)
          ..deadline = DateTime(2026, 9, 22)
          ..subtasks = [Subtask()..title = 'sub'..order = 0]);

        await tasks.toggleCompleted((await isar.tasks.get(id))!);

        final saved = (await isar.tasks.get(id))!;
        expect(saved.title, 'a');
        expect(saved.listId, 1);
        expect(saved.isStarred, isTrue);
        expect(saved.description, 'notes');
        expect(saved.reminderAt, DateTime(2026, 9, 21, 9));
        expect(saved.deadline, DateTime(2026, 9, 22));
        expect(saved.subtasks.single.title, 'sub');
        expect(saved.subtasks.single.isCompleted, isFalse);
      });

      test('a Task that no longer exists is ignored', () async {
        final gone = task(1, 'gone')..id = 999;

        await tasks.toggleCompleted(gone);

        expect(await isar.tasks.count(), 0);
      });

      test('reaches a live watch of its List', () async {
        final id = await put(task(1, 'a'));
        final stream = tasks.watchByList(1).asBroadcastStream();
        await stream.firstWhere((t) => t.length == 1).timeout(const Duration(seconds: 5));

        await tasks.toggleCompleted((await isar.tasks.get(id))!);

        final done = await stream
            .firstWhere((t) => t.single.isCompleted)
            .timeout(const Duration(seconds: 5));
        expect(done.single.title, 'a');
      });

      group('a repeating Task', () {
        test('advances reminderAt instead of completing, and stays unchecked', () async {
          final id = await put(task(1, 'daily')
            ..reminderAt = DateTime(2026, 9, 21, 9)
            ..repeat = (Repeat()..frequency = RepeatFrequency.daily));

          await tasks.toggleCompleted((await isar.tasks.get(id))!);

          final saved = (await isar.tasks.get(id))!;
          expect(saved.isCompleted, isFalse);
          expect(saved.reminderAt, DateTime(2026, 9, 22, 9));
        });

        test('advances deadline independently, when set', () async {
          final id = await put(task(1, 'daily')
            ..reminderAt = DateTime(2026, 9, 21, 9)
            ..deadline = DateTime(2026, 9, 25)
            ..repeat = (Repeat()..frequency = RepeatFrequency.daily));

          await tasks.toggleCompleted((await isar.tasks.get(id))!);

          final saved = (await isar.tasks.get(id))!;
          expect(saved.reminderAt, DateTime(2026, 9, 22, 9));
          expect(saved.deadline, DateTime(2026, 9, 26));
        });

        test('with no deadline, leaves it null', () async {
          final id = await put(task(1, 'daily')
            ..reminderAt = DateTime(2026, 9, 21, 9)
            ..repeat = (Repeat()..frequency = RepeatFrequency.daily));

          await tasks.toggleCompleted((await isar.tasks.get(id))!);

          expect((await isar.tasks.get(id))!.deadline, isNull);
        });

        test('no catch-up: completing three days late still advances by exactly one day', () async {
          final id = await put(task(1, 'daily')
            ..reminderAt = DateTime(2026, 9, 18, 9)
            ..repeat = (Repeat()..frequency = RepeatFrequency.daily));

          await tasks.toggleCompleted((await isar.tasks.get(id))!);

          expect((await isar.tasks.get(id))!.reminderAt, DateTime(2026, 9, 19, 9));
        });

        test('completing repeatedly advances one occurrence each time', () async {
          final id = await put(task(1, 'daily')
            ..reminderAt = DateTime(2026, 9, 21, 9)
            ..repeat = (Repeat()..frequency = RepeatFrequency.daily));

          await tasks.toggleCompleted((await isar.tasks.get(id))!);
          await tasks.toggleCompleted((await isar.tasks.get(id))!);
          await tasks.toggleCompleted((await isar.tasks.get(id))!);

          expect((await isar.tasks.get(id))!.reminderAt, DateTime(2026, 9, 24, 9));
        });

        test('a weekly repeat with selected weekdays advances via nextOccurrence', () async {
          // 2026-09-21 is a Monday; Mon+Thu selected, so completing Monday
          // advances to Thursday of the same week.
          final id = await put(task(1, 'weekly')
            ..reminderAt = DateTime(2026, 9, 21, 9)
            ..repeat = (Repeat()
              ..frequency = RepeatFrequency.weekly
              ..weekdays = [1, 4]));

          await tasks.toggleCompleted((await isar.tasks.get(id))!);

          expect((await isar.tasks.get(id))!.reminderAt, DateTime(2026, 9, 24, 9));
        });
      });
    });

    test('a created Task reaches a live watch of its List', () async {
      final stream = tasks.watchByList(1).asBroadcastStream();
      await next(stream, (t) => t.isEmpty);

      await tasks.create(task(1, 'live'));

      expect(await next(stream, (t) => t.isNotEmpty), ['live']);
    });

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

    group('update', () {
      test('persists every field of the given Task onto its stored record', () async {
        final id = await put(task(1, 'a'));

        await tasks.update(task(2, 'b', starred: true)
          ..id = id
          ..description = 'notes'
          ..isCompleted = true);

        final saved = (await isar.tasks.get(id))!;
        expect(saved.listId, 2);
        expect(saved.title, 'b');
        expect(saved.isStarred, isTrue);
        expect(saved.description, 'notes');
        expect(saved.isCompleted, isTrue);
      });

      test('reaches a live watch of its List', () async {
        final id = await put(task(1, 'a'));
        final stream = tasks.watchByList(2).asBroadcastStream();
        await next(stream, (t) => t.isEmpty);

        await tasks.update(task(2, 'moved')..id = id);

        expect(await next(stream, (t) => t.isNotEmpty), ['moved']);
      });
    });

    group('delete', () {
      test('removes the Task', () async {
        final id = await put(task(1, 'gone'));

        await tasks.delete(id);

        expect(await isar.tasks.get(id), isNull);
      });

      test('a Task restored afterwards with update keeps the same id', () async {
        final original = task(1, 'restore me');
        original.id = await put(original);

        await tasks.delete(original.id);
        expect(await isar.tasks.get(original.id), isNull);

        await tasks.update(original);

        final restored = await isar.tasks.get(original.id);
        expect(restored, isNotNull);
        expect(restored!.title, 'restore me');
      });

      test('a Task that no longer exists is ignored', () async {
        await tasks.delete(999);

        expect(await isar.tasks.count(), 0);
      });

      test('reaches a live watch of its List', () async {
        final id = await put(task(1, 'a'));
        final stream = tasks.watchByList(1).asBroadcastStream();
        await next(stream, (t) => t.isNotEmpty);

        await tasks.delete(id);

        expect(await next(stream, (t) => t.isEmpty), isEmpty);
      });
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

    test('create saves the List and returns its id', () async {
      final id = await lists.create(TaskList()
        ..name = 'Errands'
        ..icon = 'rocket'
        ..color = 0xFF0284C7);

      expect(id, isNot(Isar.autoIncrement));
      final saved = (await isar.taskLists.get(id))!;
      expect(saved.name, 'Errands');
      expect(saved.icon, 'rocket');
      expect(saved.color, 0xFF0284C7);
    });

    test('create reaches a live watch of every List', () async {
      final stream = lists.watchAll().asBroadcastStream();
      await stream.firstWhere((l) => l.isEmpty).timeout(const Duration(seconds: 5));

      await lists.create(TaskList()
        ..name = 'live'
        ..icon = 'rocket'
        ..color = 1);

      final after = await stream
          .firstWhere((l) => l.isNotEmpty)
          .timeout(const Duration(seconds: 5));
      expect(after.single.name, 'live');
    });

    test('createDefault names it "My Tasks"', () async {
      final id = await lists.createDefault();

      expect((await isar.taskLists.get(id))!.name, 'My Tasks');
    });
  });
}
