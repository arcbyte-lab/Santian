import 'dart:async';

import 'package:isar_community/isar.dart';

import '../models/task_list.dart';
import 'watch_query.dart';

/// TaskList access. Smaller than [TaskRepository]: no notification
/// coordination is needed.
class ListRepository {
  ListRepository(this._isar)
      // Registered now, and kept for the repository's life; see watchQuery.
      : _changes =
            _isar.taskLists.watchLazy().asBroadcastStream(onCancel: (_) {});

  final Isar _isar;
  final Stream<void> _changes;

  /// Every List, in creation order.
  Stream<List<TaskList>> watchAll() =>
      watchQuery(_changes, () => _isar.taskLists.where().findAll());
}
