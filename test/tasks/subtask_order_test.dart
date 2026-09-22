import 'package:flutter_test/flutter_test.dart';
import 'package:santian/tasks/models/subtask.dart';
import 'package:santian/tasks/subtask_order.dart';

Subtask _subtask(String id, int order, {String title = 't'}) =>
    Subtask()
      ..id = id
      ..title = title
      ..order = order;

List<String> _ids(Iterable<Subtask> subtasks) => subtasks.map((s) => s.id).toList();

void main() {
  group('sortSubtasksForDisplay', () {
    test('sorts by order ascending', () {
      final sorted = sortSubtasksForDisplay([
        _subtask('c', 2),
        _subtask('a', 0),
        _subtask('b', 1),
      ]);

      expect(_ids(sorted), ['a', 'b', 'c']);
    });

    test('ties break by id', () {
      final sorted = sortSubtasksForDisplay([
        _subtask('b', 0),
        _subtask('a', 0),
      ]);

      expect(_ids(sorted), ['a', 'b']);
    });

    test('does not modify the list it is given', () {
      final input = [_subtask('b', 1), _subtask('a', 0)];

      sortSubtasksForDisplay(input);

      expect(_ids(input), ['b', 'a']);
    });
  });

  group('applySubtaskReorder', () {
    test('moving the first item down lands it at newIndex, per '
        "ReorderableListView's own before-removal convention", () {
      final result = applySubtaskReorder(
        [_subtask('a', 0), _subtask('b', 1), _subtask('c', 2)],
        0,
        2,
      );

      expect(_ids(result), ['b', 'a', 'c']);
    });

    test('moving the last item up', () {
      final result = applySubtaskReorder(
        [_subtask('a', 0), _subtask('b', 1), _subtask('c', 2)],
        2,
        0,
      );

      expect(_ids(result), ['c', 'a', 'b']);
    });

    test('order values are rewritten densely from 0, regardless of the '
        'input orders', () {
      final result = applySubtaskReorder(
        [_subtask('a', 10), _subtask('b', 25), _subtask('c', 99)],
        0,
        2,
      );

      expect(result.map((s) => s.order).toList(), [0, 1, 2]);
    });

    test('a no-op reorder (same position) leaves order untouched in value, '
        'still densely 0-based', () {
      final result = applySubtaskReorder(
        [_subtask('a', 0), _subtask('b', 1)],
        0,
        0,
      );

      expect(_ids(result), ['a', 'b']);
      expect(result.map((s) => s.order).toList(), [0, 1]);
    });

    test('preserves every other field (title, isCompleted, id)', () {
      final b = _subtask('b', 1, title: 'buy milk')..isCompleted = true;
      final result = applySubtaskReorder([_subtask('a', 0), b], 1, 0);

      final moved = result.firstWhere((s) => s.id == 'b');
      expect(moved.title, 'buy milk');
      expect(moved.isCompleted, isTrue);
    });
  });
}
