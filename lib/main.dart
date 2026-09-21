import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/debug/debug_seed.dart';
import 'tasks/models/task.dart';
import 'tasks/models/task_list.dart';
import 'tasks/repository/list_repository.dart';
import 'tasks/repository/task_repository.dart';
import 'tasks/screens/tasks_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [TaskSchema, TaskListSchema],
    directory: dir.path,
  );
  if (kDebugMode) await seedDebugData(isar);

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => TaskRepository(isar)),
        RepositoryProvider(create: (_) => ListRepository(isar)),
      ],
      child: const SantianApp(home: TasksListScreen()),
    ),
  );
}
