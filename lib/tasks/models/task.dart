import 'package:isar_community/isar.dart';

import 'repeat.dart';
import 'subtask.dart';

part 'task.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;

  /// `TaskList.id`. A plain indexed field, not an `IsarLink`.
  @Index()
  late int listId;

  late String title;

  String? description;

  /// Notification trigger. A date-only entry still stores a full DateTime.
  DateTime? reminderAt;

  /// Date only, no time component. Has its own notification and overdue style.
  DateTime? deadline;

  /// Null means no repeat.
  Repeat? repeat;

  @Index()
  bool isStarred = false;

  bool isCompleted = false;

  List<Subtask> subtasks = [];
}
