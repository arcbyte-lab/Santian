import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';

part 'subtask.g.dart';

@embedded
class Subtask {
  /// Embedded objects have no Isar id, so delete and reorder target this.
  String id = const Uuid().v4();

  late String title;

  bool isCompleted = false;

  /// Manual order, not insertion order.
  late int order;
}
