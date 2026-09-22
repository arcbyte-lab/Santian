import 'package:flutter_test/flutter_test.dart';
import 'package:santian/core/notifications/task_notifications.dart';
import 'package:santian/tasks/models/task.dart';

import '../../support/fake_notification_service.dart';

Task _task(
  int id, {
  String title = 't',
  DateTime? reminderAt,
  DateTime? deadline,
  bool done = false,
}) =>
    Task()
      ..id = id
      ..listId = 1
      ..title = title
      ..reminderAt = reminderAt
      ..deadline = deadline
      ..isCompleted = done;

void main() {
  test('reminder and deadline ids never collide, for any Task id', () {
    for (var id = 1; id < 50; id++) {
      expect(reminderNotificationId(id).isEven, isTrue);
      expect(deadlineNotificationId(id).isOdd, isTrue);
      expect(reminderNotificationId(id), isNot(deadlineNotificationId(id)));
    }
  });

  group('syncTaskNotifications', () {
    test('schedules the reminder, titled with the Task, no body', () async {
      final notifications = FakeNotificationService();
      final at = DateTime(2026, 9, 22, 9);

      await syncTaskNotifications(notifications, _task(5, title: 'Standup', reminderAt: at));

      final call = notifications.scheduled.single;
      expect(call.id, reminderNotificationId(5));
      expect(call.at, at);
      expect(call.title, 'Standup');
      expect(call.body, isNull);
    });

    test('schedules the deadline at 9am on its date, body "Due today"', () async {
      final notifications = FakeNotificationService();

      await syncTaskNotifications(
        notifications,
        _task(5, title: 'Ship it', deadline: DateTime(2026, 9, 25)),
      );

      final call = notifications.scheduled.single;
      expect(call.id, deadlineNotificationId(5));
      expect(call.at, DateTime(2026, 9, 25, deadlineNotificationHour));
      expect(call.title, 'Ship it');
      expect(call.body, 'Due today');
    });

    test('schedules both when both are set', () async {
      final notifications = FakeNotificationService();

      await syncTaskNotifications(
        notifications,
        _task(5, reminderAt: DateTime(2026, 9, 22, 9), deadline: DateTime(2026, 9, 25)),
      );

      expect(notifications.scheduled.map((c) => c.id).toSet(), {
        reminderNotificationId(5),
        deadlineNotificationId(5),
      });
    });

    test('cancels the reminder id when reminderAt is null', () async {
      final notifications = FakeNotificationService();

      await syncTaskNotifications(notifications, _task(5));

      expect(notifications.cancelled, contains(reminderNotificationId(5)));
      expect(notifications.scheduled, isEmpty);
    });

    test('cancels the deadline id when deadline is null', () async {
      final notifications = FakeNotificationService();

      await syncTaskNotifications(notifications, _task(5, reminderAt: DateTime(2026, 9, 22, 9)));

      expect(notifications.cancelled, contains(deadlineNotificationId(5)));
    });

    test('a completed Task has both ids cancelled, even with both fields set', () async {
      final notifications = FakeNotificationService();

      await syncTaskNotifications(
        notifications,
        _task(
          5,
          reminderAt: DateTime(2026, 9, 22, 9),
          deadline: DateTime(2026, 9, 25),
          done: true,
        ),
      );

      expect(notifications.cancelled.toSet(), {reminderNotificationId(5), deadlineNotificationId(5)});
      expect(notifications.scheduled, isEmpty);
    });
  });

  group('cancelTaskNotifications', () {
    test('cancels both ids', () async {
      final notifications = FakeNotificationService();

      await cancelTaskNotifications(notifications, 7);

      expect(notifications.cancelled.toSet(), {reminderNotificationId(7), deadlineNotificationId(7)});
    });
  });
}
