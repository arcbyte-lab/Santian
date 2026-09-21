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
}
