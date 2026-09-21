import 'package:isar_community/isar.dart';

part 'task_list.g.dart';

/// The domain term is **List**; `List` is a reserved built-in type in Dart,
/// so the collection is named `TaskList`. Docs and conversation still say List.
@collection
class TaskList {
  Id id = Isar.autoIncrement;

  late String name;

  /// Lucide icon identifier, e.g. "rocket", matched to a widget client-side.
  late String icon;

  /// ARGB int, built with `Color(value)`.
  late int color;
}
