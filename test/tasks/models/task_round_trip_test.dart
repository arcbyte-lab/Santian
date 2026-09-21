import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:santian/tasks/models/repeat.dart';
import 'package:santian/tasks/models/subtask.dart';
import 'package:santian/tasks/models/task.dart';
import 'package:santian/tasks/models/task_list.dart';

void main() {
  late Directory dir;
  late Isar isar;

  setUpAll(() async {
    // Locally, fetch the native library on first run. In CI it is pre-placed
    // and hash-verified (see ci.yml), so never download an unchecked copy.
    await Isar.initializeIsarCore(
      download: Platform.environment['CI'] != 'true',
    );
  });

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('santian_isar_test_');
    isar = await Isar.open(
      [TaskSchema, TaskListSchema],
      directory: dir.path,
      name: 'test',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  test('a Task round-trips with an embedded Repeat and Subtasks', () async {
    final reminder = DateTime(2026, 9, 21, 9);
    final task = Task()
      ..listId = 1
      ..title = 'Morning workout'
      ..description = 'Legs'
      ..reminderAt = reminder
      ..deadline = DateTime(2026, 9, 30)
      ..isStarred = true
      ..repeat = (Repeat()
        ..frequency = RepeatFrequency.custom
        ..interval = 2
        ..unit = RepeatUnit.weeks
        ..weekdays = [1, 4])
      ..subtasks = [
        Subtask()
          ..title = 'Warm up'
          ..order = 0,
        Subtask()
          ..title = 'Stretch'
          ..isCompleted = true
          ..order = 1,
      ];

    final id = await isar.writeTxn(() => isar.tasks.put(task));
    final read = await isar.tasks.get(id);

    expect(read, isNotNull);
    expect(read!.title, 'Morning workout');
    expect(read.listId, 1);
    expect(read.description, 'Legs');
    expect(read.reminderAt, reminder);
    expect(read.deadline, DateTime(2026, 9, 30));
    expect(read.isStarred, isTrue);
    expect(read.isCompleted, isFalse);
    expect(read.repeat!.frequency, RepeatFrequency.custom);
    expect(read.repeat!.interval, 2);
    expect(read.repeat!.unit, RepeatUnit.weeks);
    expect(read.repeat!.weekdays, [1, 4]);
    expect(read.subtasks.map((s) => s.title), ['Warm up', 'Stretch']);
    expect(read.subtasks.map((s) => s.isCompleted), [false, true]);
    expect(read.subtasks.map((s) => s.order), [0, 1]);
    expect(read.subtasks.first.id, isNotEmpty);
    expect(read.subtasks.first.id, isNot(read.subtasks.last.id));
  });

  test('a Task with no repeat and a null RepeatUnit round-trips', () async {
    final task = Task()
      ..listId = 1
      ..title = 'Plain'
      ..repeat = (Repeat()..frequency = RepeatFrequency.daily);

    final id = await isar.writeTxn(() => isar.tasks.put(task));
    final read = (await isar.tasks.get(id))!;

    expect(read.repeat!.frequency, RepeatFrequency.daily);
    expect(read.repeat!.unit, isNull);
    expect(read.repeat!.interval, 1);
  });

  test('a TaskList round-trips', () async {
    final list = TaskList()
      ..name = 'My Tasks'
      ..icon = 'footprints'
      ..color = 0xFF0284C7;

    final id = await isar.writeTxn(() => isar.taskLists.put(list));
    final read = (await isar.taskLists.get(id))!;

    expect(read.name, 'My Tasks');
    expect(read.icon, 'footprints');
    expect(read.color, 0xFF0284C7);
  });
}
