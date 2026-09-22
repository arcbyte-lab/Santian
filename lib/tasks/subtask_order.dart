import 'models/subtask.dart';

/// Subtasks in their display order: by `order` ascending, ties (which
/// shouldn't occur once [applySubtaskReorder] is the only writer, but a
/// freshly-added Subtask racing a stale read could still collide) broken by
/// `id` for a stable, deterministic order either way.
List<Subtask> sortSubtasksForDisplay(Iterable<Subtask> subtasks) {
  final sorted = subtasks.toList()
    ..sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
  return sorted;
}

/// Applies one drag-and-drop move to [subtasks] and returns the result with
/// every `order` rewritten to its new position (0, 1, 2, ...) - dense and
/// gap-free regardless of what the input's `order` values were.
///
/// [oldIndex]/[newIndex] are display-sorted-list indices in
/// `ReorderableListView.onReorder`'s own convention: when moving an item
/// *down* the list, [newIndex] is the index it would land at **before** the
/// dragged item is removed, so it lands one slot earlier than that number
/// once the removal happens. This function does that adjustment; callers
/// pass `onReorder`'s two ints straight through.
List<Subtask> applySubtaskReorder(
  Iterable<Subtask> subtasks,
  int oldIndex,
  int newIndex,
) {
  final sorted = sortSubtasksForDisplay(subtasks);
  final moved = sorted.removeAt(oldIndex);
  final insertAt = oldIndex < newIndex ? newIndex - 1 : newIndex;
  sorted.insert(insertAt, moved);
  return [
    for (var i = 0; i < sorted.length; i++) sorted[i].copyWith(order: i),
  ];
}
