import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:santian/tasks/cubits/create_task_cubit.dart';
import 'package:santian/tasks/models/task.dart';
import 'package:santian/tasks/repository/task_repository.dart';

import '../../support/test_isar.dart';

/// Fails its first save, then behaves normally.
class _FlakyRepository extends TaskRepository {
  _FlakyRepository(super.isar);

  var failNext = true;

  @override
  Future<int> create(Task task) async {
    if (failNext) {
      failNext = false;
      throw StateError('disk full');
    }
    return super.create(task);
  }
}

void main() {
  late TestIsar db;
  late Isar isar;

  setUp(() async {
    db = await TestIsar.open();
    isar = db.isar;
  });

  tearDown(() => db.close());

  CreateTaskCubit cubit({int listId = 7, TaskRepository? repo}) =>
      CreateTaskCubit(tasks: repo ?? TaskRepository(isar), listId: listId);

  Future<List<Task>> saved() => isar.tasks.where().findAll();

  group('submit', () {
    test('creates the Task in the given List with only the title set', () async {
      final c = cubit(listId: 7)..setTitle('  Buy milk  ');

      expect(await c.submit(), isTrue);

      final tasks = await saved();
      expect(tasks, hasLength(1));
      expect(tasks.single.title, 'Buy milk');
      expect(tasks.single.listId, 7);
      expect(tasks.single.description, isNull);
      expect(tasks.single.isStarred, isFalse);
      expect(tasks.single.isCompleted, isFalse);
      expect(tasks.single.reminderAt, isNull);
      expect(tasks.single.deadline, isNull);
      expect(tasks.single.repeat, isNull);
      expect(tasks.single.subtasks, isEmpty);
      await c.close();
    });

    test('an empty or whitespace-only title creates nothing', () async {
      final c = cubit();

      expect(await c.submit(), isFalse);
      c.setTitle('   ');
      expect(await c.submit(), isFalse);

      expect(await saved(), isEmpty);
      await c.close();
    });

    test('a Task with a reminder saves reminderAt', () async {
      final c = cubit()
        ..setTitle('With reminder')
        ..setReminder(DateTime(2026, 9, 21, 9));

      await c.submit();

      expect((await saved()).single.reminderAt, DateTime(2026, 9, 21, 9));
      await c.close();
    });

    test('no reminder set leaves reminderAt null', () async {
      final c = cubit()..setTitle('No reminder');

      await c.submit();

      expect((await saved()).single.reminderAt, isNull);
      await c.close();
    });

    test('a starred Task is saved as starred', () async {
      final c = cubit()
        ..setTitle('Important')
        ..toggleStar();

      await c.submit();

      expect((await saved()).single.isStarred, isTrue);
      await c.close();
    });

    test('toggling the star twice leaves it unstarred', () async {
      final c = cubit()
        ..setTitle('Meh')
        ..toggleStar()
        ..toggleStar();

      await c.submit();

      expect((await saved()).single.isStarred, isFalse);
      await c.close();
    });

    test('notes are saved as the description while their field is showing', () async {
      final c = cubit()
        ..setTitle('With notes')
        ..toggleNotes()
        ..setNotes('  some details  ');

      await c.submit();

      expect((await saved()).single.description, 'some details');
      await c.close();
    });

    test('blank notes leave the description null', () async {
      final c = cubit()
        ..setTitle('Blank notes')
        ..toggleNotes()
        ..setNotes('   ');

      await c.submit();

      expect((await saved()).single.description, isNull);
      await c.close();
    });

    test('notes typed and then hidden are discarded', () async {
      final c = cubit()
        ..setTitle('Hidden notes')
        ..toggleNotes()
        ..setNotes('should not be saved')
        ..toggleNotes();

      await c.submit();

      expect((await saved()).single.description, isNull);
      await c.close();
    });

    test('a second submit from the same sheet does not create a second Task', () async {
      final c = cubit()..setTitle('Once');

      final results = await Future.wait([c.submit(), c.submit()]);

      expect(results.where((r) => r), hasLength(1));
      expect(await saved(), hasLength(1));
      expect(await c.submit(), isFalse);
      await c.close();
    });

    test('a failed save can be retried', () async {
      final repo = _FlakyRepository(isar);
      final c = cubit(repo: repo)..setTitle('Retry me');

      await expectLater(c.submit(), throwsStateError);
      expect(await saved(), isEmpty);

      expect(await c.submit(), isTrue);
      expect(await saved(), hasLength(1));
      await c.close();
    });
  });

  group('state', () {
    test('starts empty', () {
      final c = cubit();

      expect(c.state.title, '');
      expect(c.state.notes, '');
      expect(c.state.notesVisible, isFalse);
      expect(c.state.isStarred, isFalse);
      expect(c.state.canSubmit, isFalse);
      c.close();
    });

    test('setReminder updates the state', () {
      final c = cubit();

      c.setReminder(DateTime(2026, 9, 21, 9));

      expect(c.state.reminderAt, DateTime(2026, 9, 21, 9));
      c.close();
    });

    test('canSubmit needs a non-blank title', () {
      final c = cubit();

      c.setTitle('  ');
      expect(c.state.canSubmit, isFalse);
      c.setTitle(' x ');
      expect(c.state.canSubmit, isTrue);
      c.close();
    });

    test('toggleNotes flips visibility', () {
      final c = cubit();

      c.toggleNotes();
      expect(c.state.notesVisible, isTrue);
      c.toggleNotes();
      expect(c.state.notesVisible, isFalse);
      c.close();
    });
  });
}
