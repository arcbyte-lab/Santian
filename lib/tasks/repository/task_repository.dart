import 'dart:async';

import 'package:isar_community/isar.dart';

import '../models/task.dart';
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

  /// Flips `isCompleted` on the stored Task with [task]'s id, for a
  /// non-repeating Task. Works on the stored record, not on [task], so a row
  /// that has gone stale cannot overwrite other edits. Does nothing if the
  /// Task has been deleted.
  ///
  /// A repeating Task will instead advance to its next occurrence (the repeat
  /// ticket), and each branch will re-sync notifications (the notifications
  /// ticket); both hook in here, in the same transaction.
  Future<void> toggleCompleted(Task task) => _isar.writeTxn(() async {
        final stored = await _isar.tasks.get(task.id);
        if (stored == null) return;
        stored.isCompleted = !stored.isCompleted;
        await _isar.tasks.put(stored);
      });
}
