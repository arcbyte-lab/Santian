import 'package:isar_community/isar.dart';

import '../../tasks/models/task.dart';
import '../../tasks/models/task_list.dart';

/// Debug builds only (guarded in `main.dart`): fills an empty database with the
/// mockup's three Lists and a few Tasks, so the Tasks List has something to
/// show before Create Task and Add List exist. Does nothing if any List exists.
Future<void> seedDebugData(Isar isar) async {
  if (await isar.taskLists.count() > 0) return;

  final now = DateTime.now();
  DateTime today(int hour, [int minute = 0]) =>
      DateTime(now.year, now.month, now.day, hour, minute);

  await isar.writeTxn(() async {
    final personal = await isar.taskLists.put(TaskList()
      ..name = 'Personal Interest'
      ..icon = 'rocket'
      ..color = 0xFF0284C7);
    final myTasks = await isar.taskLists.put(TaskList()
      ..name = 'My Tasks'
      ..icon = 'footprints'
      ..color = 0xFFF97316);
    final building = await isar.taskLists.put(TaskList()
      ..name = 'Building'
      ..icon = 'hammer'
      ..color = 0xFF57534E);

    await isar.tasks.putAll([
      Task()
        ..listId = personal
        ..title = 'Morning workout'
        ..reminderAt = today(7),
      Task()
        ..listId = personal
        ..title = 'Review pull requests'
        ..reminderAt = today(9)
        ..isStarred = true,
      Task()
        ..listId = personal
        ..title = 'Team standup'
        ..reminderAt = today(10),
      Task()
        ..listId = personal
        ..title = 'Read a chapter'
        ..isCompleted = true
        ..reminderAt = today(6, 30),
      Task()
        ..listId = personal
        ..title = 'Plan the week',
      Task()
        ..listId = myTasks
        ..title = 'Call the dentist'
        ..reminderAt = today(14),
      Task()
        ..listId = building
        ..title = 'Deep work: API migration'
        ..reminderAt = today(11)
        ..isStarred = true,
    ]);
  });
}
