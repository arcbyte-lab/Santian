import '../../tasks/models/task.dart';
import 'notification_service.dart';

/// The reminder notification's id for [taskId] - even, so it never collides
/// with a deadline id (odd).
int reminderNotificationId(int taskId) => taskId * 2;

/// The deadline notification's id for [taskId].
int deadlineNotificationId(int taskId) => taskId * 2 + 1;

/// What time of day a date-only deadline's notification fires. `deadline`
/// itself has no time component and the spec gave none; confirmed by the
/// product owner directly (2026-09-22) in lieu of an Arcbyte decision doc -
/// worth back-filling there once that repo is reachable.
const deadlineNotificationHour = 9;

/// Schedules or cancels [task]'s reminder and deadline notifications to
/// match its current fields - the one place every trigger in the
/// notification-scheduling spec (create, edit, complete, delete-undo) routes
/// through, via [TaskRepository].
///
/// A completed Task's notifications are always cancelled, even if
/// `reminderAt`/`deadline` are still set: a repeating Task's completion path
/// (see `TaskRepository.toggleCompleted`) briefly sets `isCompleted = true`
/// before flipping it back to `false` in the same write, and this rule holds
/// either way, rather than depending on that implementation detail.
Future<void> syncTaskNotifications(NotificationService notifications, Task task) async {
  if (task.isCompleted) {
    await cancelTaskNotifications(notifications, task.id);
    return;
  }

  final reminderAt = task.reminderAt;
  if (reminderAt == null) {
    await notifications.cancel(reminderNotificationId(task.id));
  } else {
    await notifications.schedule(
      reminderNotificationId(task.id),
      at: reminderAt,
      title: task.title,
    );
  }

  final deadline = task.deadline;
  if (deadline == null) {
    await notifications.cancel(deadlineNotificationId(task.id));
  } else {
    await notifications.schedule(
      deadlineNotificationId(task.id),
      at: DateTime(deadline.year, deadline.month, deadline.day, deadlineNotificationHour),
      title: task.title,
      body: 'Due today',
    );
  }
}

/// Cancels both of [taskId]'s notifications - used on delete.
Future<void> cancelTaskNotifications(NotificationService notifications, int taskId) async {
  await notifications.cancel(reminderNotificationId(taskId));
  await notifications.cancel(deadlineNotificationId(taskId));
}
