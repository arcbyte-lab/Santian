import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:santian/tasks/models/task.dart';
import 'package:santian/tasks/models/task_list.dart';

/// Loads Isar's native library once. Locally it is fetched on first run. In CI
/// it is pre-placed and hash-verified (see ci.yml), so never download an
/// unchecked copy there.
Future<void> initIsarCoreForTests() => Isar.initializeIsarCore(
      download: Platform.environment['CI'] != 'true',
    );

/// An Isar in a throwaway directory, deleted by [close].
class TestIsar {
  TestIsar._(this.isar, this._dir);

  final Isar isar;
  final Directory _dir;

  static var _counter = 0;

  static Future<TestIsar> open() async {
    await initIsarCoreForTests();
    final dir = await Directory.systemTemp.createTemp('santian_isar_test_');
    final isar = await Isar.open(
      [TaskSchema, TaskListSchema],
      directory: dir.path,
      name: 'test_${_counter++}',
    );
    return TestIsar._(isar, dir);
  }

  Future<void> close() async {
    await isar.close(deleteFromDisk: true);
    await _dir.delete(recursive: true);
  }
}
