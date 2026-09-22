/// The one platform boundary for scheduling and cancelling local
/// notifications. [TaskRepository] depends on this abstraction, never on
/// `flutter_local_notifications` directly, so the repository's own tests can
/// inject a fake instead of touching platform channels - see
/// [notification-scheduling.md]'s acceptance criteria: "repository tests
/// against a fake NotificationService."
///
/// Tapping a delivered notification is the other half of this boundary, but
/// it has no method here: it isn't something a caller invokes, it's an event
/// the concrete implementation raises for whoever wires navigation - a fake
/// never needs to simulate a tap, only record what was scheduled.
abstract class NotificationService {
  /// Schedules a one-time notification with [id], firing at [at], titled
  /// [title] with an optional [body]. Replaces any existing notification
  /// already scheduled with the same [id].
  Future<void> schedule(int id, {required DateTime at, required String title, String? body});

  /// Cancels the notification with [id], if one is scheduled. Does nothing
  /// if there isn't one.
  Future<void> cancel(int id);
}
