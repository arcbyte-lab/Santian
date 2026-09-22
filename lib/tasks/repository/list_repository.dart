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

  /// Saves a new List and returns its id.
  Future<int> create(TaskList list) =>
      _isar.writeTxn(() => _isar.taskLists.put(list));

  /// The List a fresh install gets before the user has created any of their
  /// own, so the FAB always has somewhere to create into rather than a
  /// first-launch empty state. Confirmed by the product owner directly
  /// (2026-09-22) in lieu of an Arcbyte decision doc - see the add-list
  /// ticket's PR for the exchange; still worth back-filling into Arcbyte
  /// once that repo is reachable from wherever this runs next.
  Future<int> createDefault() => create(
        TaskList()
          ..name = 'My Tasks'
          ..icon = 'footprints'
          ..color = 0xFF0284C7,
      );
}
