import 'dart:async';

import 'package:isar_community/isar.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/notifications/task_notifications.dart';
import '../models/task.dart';
import '../repeat_advance.dart';
import 'watch_query.dart';

/// The one place that reads and mutates Tasks. Every write that changes
/// what should notify (create, update, delete, toggleCompleted) re-syncs
/// [notifications] afterward, via [syncTaskNotifications]/
/// [cancelTaskNotifications] - see notification-scheduling.md's own trigger
/// list, which maps onto these four methods exactly.
class TaskRepository {
  TaskRepository(this._isar, {required NotificationService notifications})
      : _notifications = notifications,
        // Registered now, and kept for the repository's life; see watchQuery.
        _changes = _isar.tasks.watchLazy().asBroadcastStream(onCancel: (_) {});

  final Isar _isar;
  final NotificationService _notifications;
  final Stream<void> _changes;

  Stream<List<Task>> watchByList(int listId) => watchQuery(
        _changes,
        () => _isar.tasks.filter().listIdEqualTo(listId).findAll(),
      );

  Stream<List<Task>> watchStarred() => watchQuery(
        _changes,
        () => _isar.tasks.filter().isStarredEqualTo(true).findAll(),
      );

  /// Fetches the Task with [id], or null if it doesn't exist - e.g. deleted
  /// since a still-pending notification was scheduled against it. Used to
  /// open Task Detail for a notification tap's payload.
  Future<Task?> get(int id) => _isar.tasks.get(id);

  /// Saves a new Task and returns its id.
  Future<int> create(Task task) async {
    final id = await _isar.writeTxn(() => _isar.tasks.put(task));
    task.id = id;
    await syncTaskNotifications(_notifications, task);
    return id;
  }

  /// Persists every field of [task] onto the stored record with the same id.
  /// Used for Task Detail's edits (title, description, star, list), and to
  /// restore a deleted Task exactly, including its id, on undo - which is
  /// also why this re-syncs notifications: undoing a delete must reschedule
  /// them.
  Future<void> update(Task task) async {
    await _isar.writeTxn(() => _isar.tasks.put(task));
    await syncTaskNotifications(_notifications, task);
  }

  /// Removes the Task with [id]. Its Subtasks go with it: they are embedded,
  /// so they have nowhere to exist once their parent Task is gone.
  Future<void> delete(int id) async {
    await _isar.writeTxn(() => _isar.tasks.delete(id));
    await cancelTaskNotifications(_notifications, id);
  }

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
  /// Either way, notifications are re-synced against the task's final state
  /// afterward: a plain completion cancels both (isCompleted), a repeating
  /// completion reschedules both to the advanced occurrence, and
  /// un-completing resumes whatever was already set.
  Future<void> toggleCompleted(Task task) async {
    final stored = await _isar.writeTxn(() async {
      final stored = await _isar.tasks.get(task.id);
      if (stored == null) return null;

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
      return stored;
    });
    if (stored != null) await syncTaskNotifications(_notifications, stored);
  }
}
