import 'package:santian/core/notifications/notification_service.dart';

/// Records every call instead of touching a platform channel, so
/// [TaskRepository]'s own tests can assert on exactly which ids were
/// scheduled or cancelled - see the notification-scheduling ticket's
/// acceptance criteria.
class FakeNotificationService implements NotificationService {
  final List<ScheduledCall> scheduled = [];
  final List<int> cancelled = [];

  @override
  Future<void> schedule(int id, {required DateTime at, required String title, String? body}) async {
    scheduled.add(ScheduledCall(id: id, at: at, title: title, body: body));
  }

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }
}

class ScheduledCall {
  const ScheduledCall({required this.id, required this.at, required this.title, this.body});

  final int id;
  final DateTime at;
  final String title;
  final String? body;
}
