import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/debug/debug_seed.dart';
import 'core/notifications/flutter_local_notifications_service.dart';
import 'tasks/models/task.dart';
import 'tasks/models/task_list.dart';
import 'tasks/repository/list_repository.dart';
import 'tasks/repository/task_repository.dart';
import 'tasks/screens/task_detail_sheet.dart';
import 'tasks/screens/tasks_list_screen.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [TaskSchema, TaskListSchema],
    directory: dir.path,
  );
  if (kDebugMode) await seedDebugData(isar);

  final notifications = FlutterLocalNotificationsService();
  await notifications.initialize();
  final tasks = TaskRepository(isar, notifications: notifications);

  // A tap delivered while already running: opens as soon as it arrives.
  notifications.onTap.listen((taskId) => _openTaskDetail(tasks, taskId));

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: tasks),
        RepositoryProvider(create: (_) => ListRepository(isar)),
      ],
      child: SantianApp(navigatorKey: _navigatorKey, home: const TasksListScreen()),
    ),
  );

  // A tap that launched this run from a killed app: the launch details are
  // only available for one run, and the first frame needs to be up before
  // there's a context to open a sheet from - hence after `runApp`, not
  // instead of the warm-start path above.
  final coldStartTaskId = await notifications.launchDetails();
  if (coldStartTaskId != null) await _openTaskDetail(tasks, coldStartTaskId);
}

Future<void> _openTaskDetail(TaskRepository tasks, int taskId) async {
  final task = await tasks.get(taskId);
  final context = _navigatorKey.currentContext;
  if (task != null && context != null && context.mounted) {
    await showTaskDetailSheet(context, task: task);
  }
}
