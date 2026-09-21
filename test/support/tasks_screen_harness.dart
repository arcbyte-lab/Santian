import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:santian/app.dart';
import 'package:santian/tasks/models/task.dart';
import 'package:santian/tasks/models/task_list.dart';
import 'package:santian/tasks/repository/list_repository.dart';
import 'package:santian/tasks/repository/task_repository.dart';
import 'package:santian/tasks/screens/tasks_list_screen.dart';

import 'test_isar.dart';

/// The Tasks List screen wired to a real Isar: Cubit, repositories, the live
/// list. Isar does real I/O, so waits run outside the fake clock.
class TasksScreenHarness {
  TasksScreenHarness(this.tester, this.db);

  final WidgetTester tester;
  final TestIsar db;
  Isar get isar => db.isar;

  static Future<TasksScreenHarness> start(
    WidgetTester tester,
    List<String> lists,
  ) async {
    final db = (await tester.runAsync(TestIsar.open))!;
    // Runs even when the test fails part-way, so a failure cannot leave Isar
    // open and hang the run.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(db.close);
    });
    final h = TasksScreenHarness(tester, db);
    await tester.runAsync(
      () => db.isar.writeTxn(() async {
        for (final name in lists) {
          await db.isar.taskLists.put(
            TaskList()
              ..name = name
              ..icon = 'rocket'
              ..color = 1,
          );
        }
      }),
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (_) => TaskRepository(db.isar)),
          RepositoryProvider(create: (_) => ListRepository(db.isar)),
        ],
        child: const SantianApp(home: TasksListScreen()),
      ),
    );
    await h.settle();
    return h;
  }

  /// Lets the Isar round trips finish. The Cubit needs several in a row (the
  /// Lists, then the tasks of the active tab), each completing in real time,
  /// so alternate real waits with pumps.
  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pumpAndSettle();
  }

  Future<List<Task>> saved() async =>
      (await tester.runAsync(() => isar.tasks.where().findAll()))!;

  /// Puts a Task in the first List and waits for the screen to show it.
  Future<void> addTask(String title, {bool starred = false}) async {
    await tester.runAsync(() async {
      final list = (await isar.taskLists.where().findFirst())!;
      await isar.writeTxn(
        () => isar.tasks.put(
          Task()
            ..listId = list.id
            ..title = title
            ..isStarred = starred,
        ),
      );
    });
    await settle();
  }
}

/// A widget test with semantics on. The handle must be released before the
/// test ends, which `addTearDown` is too late for.
void semanticsTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await body(tester);
    } finally {
      handle.dispose();
    }
  });
}
