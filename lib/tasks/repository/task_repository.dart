import 'dart:async';

import 'package:isar_community/isar.dart';

import '../models/task.dart';
import '../repeat_advance.dart';
import 'watch_query.dart';

/// The one place that reads and mutates Tasks. Notification coordination
/// arrives with the notifications ticket.
class TaskRepository {
  TaskRepository(this._isar)
      // Registered now, and kept for the repository's life; see watchQuery.
      : _changes = _isar.tasks.watchLazy().asBroadcastStream(onCancel: (_) {});

  final Isar _isar;
  final Stream<void> _changes;

  Stream<List<Task>> watchByList(int listId) => watchQuery(
        _changes,
        () => _isar.tasks.filter().listIdEqualTo(listId).findAll(),
      );

  Stream<List<Task>> watchStarred() => watchQuery(
        _changes,
        () => _isar.tasks.filter().isStarredEqualTo(true).findAll(),
      );

  /// Saves a new Task and returns its id.
  Future<int> create(Task task) =>
      _isar.writeTxn(() => _isar.tasks.put(task));

  /// Persists every field of [task] onto the stored record with the same id.
  /// Used for Task Detail's edits (title, description, star, list), and to
  /// restore a deleted Task exactly, including its id, on undo.
  Future<void> update(Task task) =>
      _isar.writeTxn(() => _isar.tasks.put(task));

  /// Removes the Task with [id]. Its Subtasks go with it: they are embedded,
  /// so they have nowhere to exist once their parent Task is gone.
  Future<void> delete(int id) => _isar.writeTxn(() => _isar.tasks.delete(id));

  /// Flips `isCompleted` on the stored Task with [task]'s id. Works on the
  /// stored record, not on [task], so a row that has gone stale cannot
  /// overwrite other edits. Does nothing if the Task has been deleted.
  ///
  /// Completing a **repeating** Task advances `reminderAt`, and `deadline`
  /// if set, to their next occurrence instead, each independently via
  /// [nextOccurrence], and leaves `isCompleted` false — the checkbox never
  /// stays checked on a repeating Task. No catch-up: this advances exactly
  /// one occurrence, even if completed days late. Un-completing (the
  /// non-repeating direction, or a repeating Task somehow left completed)
  /// just flips the flag back, same as always.
  ///
  /// This is the one place completion is decided for any Cubit's "complete
  /// this Task" action, so notification rescheduling (the notifications
  /// ticket) only needs to hook in here once.
  Future<void> toggleCompleted(Task task) => _isar.writeTxn(() async {
        final stored = await _isar.tasks.get(task.id);
        if (stored == null) return;

        final completing = !stored.isCompleted;
        final repeat = stored.repeat;
        if (completing && repeat != null) {
          stored.reminderAt = nextOccurrence(stored.reminderAt!, repeat);
          final deadline = stored.deadline;
          if (deadline != null) stored.deadline = nextOccurrence(deadline, repeat);
          stored.isCompleted = false;
        } else {
          stored.isCompleted = completing;
        }
        await _isar.tasks.put(stored);
      });
}
