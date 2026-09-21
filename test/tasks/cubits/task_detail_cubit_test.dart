import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:santian/tasks/cubits/task_detail_cubit.dart';
import 'package:santian/tasks/models/repeat.dart';
import 'package:santian/tasks/models/task.dart';
import 'package:santian/tasks/repository/task_repository.dart';

import '../../support/test_isar.dart';

void main() {
  late TestIsar db;
  late Isar isar;
  late TaskRepository tasks;

  setUp(() async {
    db = await TestIsar.open();
    isar = db.isar;
    tasks = TaskRepository(isar);
  });

  tearDown(() => db.close());

  Future<Task> seed({
    int listId = 1,
    String title = 'Original',
    bool starred = false,
  }) async {
    final task = Task()
      ..listId = listId
      ..title = title
      ..isStarred = starred;
    task.id = await tasks.create(task);
    return task;
  }

  TaskDetailCubit cubit(Task task) => TaskDetailCubit(tasks: tasks, task: task);

  group('setTitle', () {
    test('persists the trimmed title and shows it in state', () async {
      final task = await seed();
      final c = cubit(task);

      await c.setTitle('  New title  ');

      expect(c.state.task.title, 'New title');
      expect((await isar.tasks.get(task.id))!.title, 'New title');
      await c.close();
    });

    test('a blank title is dropped, leaving the stored title unchanged', () async {
      final task = await seed(title: 'Keep me');
      final c = cubit(task);

      await c.setTitle('   ');

      expect(c.state.task.title, 'Keep me');
      expect((await isar.tasks.get(task.id))!.title, 'Keep me');
      await c.close();
    });
  });

  group('setDescription', () {
    test('persists a non-blank description', () async {
      final task = await seed();
      final c = cubit(task);

      await c.setDescription('  details  ');

      expect(c.state.task.description, 'details');
      expect((await isar.tasks.get(task.id))!.description, 'details');
      await c.close();
    });

    test('a blank description clears it to null', () async {
      final task = await seed();
      await tasks.update(task..description = 'was set');
      final c = cubit(task);

      await c.setDescription('   ');

      expect(c.state.task.description, isNull);
      expect((await isar.tasks.get(task.id))!.description, isNull);
      await c.close();
    });
  });

  test('toggleStar flips isStarred and persists it', () async {
    final task = await seed(starred: false);
    final c = cubit(task);

    await c.toggleStar();
    expect(c.state.task.isStarred, isTrue);
    expect((await isar.tasks.get(task.id))!.isStarred, isTrue);

    await c.toggleStar();
    expect(c.state.task.isStarred, isFalse);
    expect((await isar.tasks.get(task.id))!.isStarred, isFalse);
    await c.close();
  });

  test('setListId reassigns the Task to another List and persists it', () async {
    final task = await seed(listId: 1);
    final c = cubit(task);

    await c.setListId(2);

    expect(c.state.task.listId, 2);
    expect((await isar.tasks.get(task.id))!.listId, 2);
    await c.close();
  });

  group('setReminder', () {
    test('sets and persists reminderAt', () async {
      final task = await seed();
      final c = cubit(task);

      await c.setReminder(DateTime(2026, 9, 21, 9));

      expect(c.state.task.reminderAt, DateTime(2026, 9, 21, 9));
      expect((await isar.tasks.get(task.id))!.reminderAt, DateTime(2026, 9, 21, 9));
      await c.close();
    });

    test('null clears it', () async {
      final task = await seed();
      await tasks.update(task..reminderAt = DateTime(2026, 9, 21, 9));
      final c = cubit(task);

      await c.setReminder(null);

      expect(c.state.task.reminderAt, isNull);
      expect((await isar.tasks.get(task.id))!.reminderAt, isNull);
      await c.close();
    });

    test('sets and persists a repeat alongside the reminder', () async {
      final task = await seed();
      final c = cubit(task);
      final repeat = Repeat()..frequency = RepeatFrequency.weekly;

      await c.setReminder(DateTime(2026, 9, 21, 9), repeat: repeat);

      expect(c.state.task.repeat?.frequency, RepeatFrequency.weekly);
      expect((await isar.tasks.get(task.id))!.repeat?.frequency, RepeatFrequency.weekly);
      await c.close();
    });

    test('null also clears a previously-set repeat', () async {
      final task = await seed();
      await tasks.update(task
        ..reminderAt = DateTime(2026, 9, 21, 9)
        ..repeat = (Repeat()..frequency = RepeatFrequency.daily));
      final c = cubit(task);

      await c.setReminder(null);

      expect(c.state.task.repeat, isNull);
      expect((await isar.tasks.get(task.id))!.repeat, isNull);
      await c.close();
    });
  });

  group('setDeadline', () {
    test('sets and persists deadline', () async {
      final task = await seed();
      final c = cubit(task);

      await c.setDeadline(DateTime(2026, 9, 21));

      expect(c.state.task.deadline, DateTime(2026, 9, 21));
      expect((await isar.tasks.get(task.id))!.deadline, DateTime(2026, 9, 21));
      await c.close();
    });

    test('null clears it', () async {
      final task = await seed();
      await tasks.update(task..deadline = DateTime(2026, 9, 21));
      final c = cubit(task);

      await c.setDeadline(null);

      expect(c.state.task.deadline, isNull);
      expect((await isar.tasks.get(task.id))!.deadline, isNull);
      await c.close();
    });
  });

  group('toggleCompleted', () {
    test('completes an incomplete Task', () async {
      final task = await seed();
      final c = cubit(task);

      await c.toggleCompleted();

      expect(c.state.task.isCompleted, isTrue);
      expect((await isar.tasks.get(task.id))!.isCompleted, isTrue);
      await c.close();
    });

    test('a second toggle restores it', () async {
      final task = await seed();
      final c = cubit(task);

      await c.toggleCompleted();
      await c.toggleCompleted();

      expect(c.state.task.isCompleted, isFalse);
      expect((await isar.tasks.get(task.id))!.isCompleted, isFalse);
      await c.close();
    });
  });

  group('delete', () {
    test('removes the Task and marks the state deleted, keeping its id', () async {
      final task = await seed(title: 'Doomed');
      final c = cubit(task);

      await c.delete();

      expect(c.state.isDeleted, isTrue);
      expect(c.state.task.id, task.id);
      expect(c.state.task.title, 'Doomed');
      expect(await isar.tasks.get(task.id), isNull);
      await c.close();
    });

    test('the deleted Task can be restored exactly via update, same id', () async {
      final task = await seed(title: 'Doomed', starred: true);
      final c = cubit(task);

      await c.delete();
      final deleted = c.state.task;
      await tasks.update(deleted);

      final restored = await isar.tasks.get(task.id);
      expect(restored, isNotNull);
      expect(restored!.id, task.id);
      expect(restored.title, 'Doomed');
      expect(restored.isStarred, isTrue);
      await c.close();
    });
  });
}
