import 'models/task.dart';

/// The display order for a Tasks List: by `reminderAt` ascending with tasks
/// that have no reminder last, ties broken by `id`. Completion doesn't
/// matter - a List tab splits completed Tasks into their own section itself.
///
/// This departs from `isar-schema.md`'s recommendation (completed last), so
/// it lives in one place.
List<Task> sortTasksForDisplay(Iterable<Task> tasks) {
  final sorted = tasks.toList()..sort(_compare);
  return sorted;
}

int _compare(Task a, Task b) {
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

/// Splits [tasks] into runs of consecutive Tasks sharing a [key], each
/// paired with that key. Given [sortTasksForDisplay] order and a key derived
/// from `reminderAt`, each run is one header's worth of Tasks.
List<(K, List<Task>)> groupRuns<K>(
  Iterable<Task> tasks,
  K Function(Task) key,
) {
  final groups = <(K, List<Task>)>[];
  for (final task in tasks) {
    final k = key(task);
    if (groups.isNotEmpty && groups.last.$1 == k) {
      groups.last.$2.add(task);
    } else {
      groups.add((k, [task]));
    }
  }
  return groups;
}
