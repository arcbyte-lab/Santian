import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service.dart';

const _channelId = 'santian_tasks';
const _channelName = 'Tasks';
const _androidDetails = AndroidNotificationDetails(
  _channelId,
  _channelName,
  importance: Importance.defaultImportance,
);
const _notificationDetails = NotificationDetails(android: _androidDetails);

/// The real [NotificationService], backed by `flutter_local_notifications`.
/// Permissions - `POST_NOTIFICATIONS` and the exact-alarm rules - are
/// requested lazily, the first time [schedule] is actually called, not at
/// [initialize]: the spec asks for this explicitly, so a fresh install's
/// first launch never shows a permission prompt before the user has set
/// anything that needs one.
class FlutterLocalNotificationsService implements NotificationService {
  FlutterLocalNotificationsService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  var _permissionsRequested = false;

  /// The `taskId` payload of a notification tapped while the app is already
  /// running (a warm start). A cold start - the app launched *by* the tap -
  /// is [launchDetails] instead; main.dart checks both.
  Stream<int> get onTap => _onTap.stream;
  final _onTap = StreamController<int>.broadcast();

  /// Sets up the plugin, the timezone database, and the tap callback. Call
  /// once, at app startup, before the first [schedule] - this does not
  /// request any permission itself, see the class doc.
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
    );
  }

  /// The `taskId` payload of the notification that launched this run of the
  /// app from a killed state, or null if it wasn't launched that way. Call
  /// once, after [initialize], at startup - not lazily, since the launch
  /// details are only available for this one run.
  Future<int?> launchDetails() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return _taskIdFrom(details?.notificationResponse);
  }

  void _handleResponse(NotificationResponse response) {
    final taskId = _taskIdFrom(response);
    if (taskId != null) _onTap.add(taskId);
  }

  static int? _taskIdFrom(NotificationResponse? response) =>
      int.tryParse(response?.payload ?? '');

  Future<void> _ensurePermissions() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> schedule(int id, {required DateTime at, required String title, String? body}) async {
    await _ensurePermissions();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: _notificationDetails,
      // Alarm-precision even in Doze - a reminder or deadline that fires
      // "eventually" defeats the point of setting one.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Task.id is the payload, not the notification id: both the reminder
      // and deadline ids for the same Task decode back to one taskId, so a
      // tap opens Task Detail regardless of which of the two was tapped.
      payload: '${id ~/ 2}',
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
