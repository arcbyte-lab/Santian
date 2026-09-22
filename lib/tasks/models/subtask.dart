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

  /// A copy with the given fields replaced, [id] always preserved (the
  /// constructor's default assigns a *new* random one, which a copy must
  /// override back rather than accidentally mint a second identity for the
  /// same Subtask).
  Subtask copyWith({String? title, bool? isCompleted, int? order}) => Subtask()
    ..id = id
    ..title = title ?? this.title
    ..isCompleted = isCompleted ?? this.isCompleted
    ..order = order ?? this.order;
}
