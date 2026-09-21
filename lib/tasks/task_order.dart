import 'models/task.dart';

/// The display order for a Tasks List: incomplete tasks first, then completed
/// ones. Within each group, by `reminderAt` ascending with tasks that have no
/// reminder last, ties broken by `id`.
///
/// This is a recommendation in `isar-schema.md`, not a ruling, so it lives in
/// one place. The recommended order among completed tasks is "most recently
/// completed first", which needs a `completedAt` field that `Task` does not
/// have; until the data model adds one, completed tasks use the same order.
List<Task> sortTasksForDisplay(Iterable<Task> tasks) {
  final sorted = tasks.toList()..sort(_compare);
  return sorted;
}

int _compare(Task a, Task b) {
  if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;

  final aAt = a.reminderAt;
  final bAt = b.reminderAt;
  if (aAt != null && bAt != null) {
    final byTime = aAt.compareTo(bAt);
    if (byTime != 0) return byTime;
  } else if (aAt != null) {
    return -1;
  } else if (bAt != null) {
    return 1;
  }
  return a.id.compareTo(b.id);
}
