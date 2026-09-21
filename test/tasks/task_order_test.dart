import 'package:flutter_test/flutter_test.dart';
import 'package:santian/tasks/models/task.dart';
import 'package:santian/tasks/task_order.dart';

Task _task(int id, {DateTime? at, bool done = false}) => Task()
  ..id = id
  ..listId = 1
  ..title = 't$id'
  ..reminderAt = at
  ..isCompleted = done;

List<int> _ids(Iterable<Task> tasks) => tasks.map((t) => t.id).toList();

void main() {
  final morning = DateTime(2026, 9, 21, 7);
  final noon = DateTime(2026, 9, 21, 12);
  final evening = DateTime(2026, 9, 21, 19);

  test('incomplete tasks sort by reminder ascending', () {
    final sorted = sortTasksForDisplay([
      _task(1, at: evening),
      _task(2, at: morning),
      _task(3, at: noon),
    ]);

    expect(_ids(sorted), [2, 3, 1]);
  });

  test('tasks with no reminder come after those with one', () {
    final sorted = sortTasksForDisplay([
      _task(1),
      _task(2, at: evening),
      _task(3, at: morning),
    ]);

    expect(_ids(sorted), [3, 2, 1]);
  });

  test('ties, including several with no reminder, break by id', () {
    final sorted = sortTasksForDisplay([
      _task(5),
      _task(3, at: noon),
      _task(2),
      _task(1, at: noon),
    ]);

    expect(_ids(sorted), [1, 3, 2, 5]);
  });

  test('completed tasks come after every incomplete one', () {
    final sorted = sortTasksForDisplay([
      _task(1, at: morning, done: true),
      _task(2, at: evening),
      _task(3, done: true),
      _task(4),
    ]);

    expect(_ids(sorted), [2, 4, 1, 3]);
  });

  test('completed tasks use the same order among themselves', () {
    final sorted = sortTasksForDisplay([
      _task(1, at: evening, done: true),
      _task(2, at: morning, done: true),
      _task(3, done: true),
    ]);

    expect(_ids(sorted), [2, 1, 3]);
  });

  test('does not modify the list it is given', () {
    final input = [_task(2, at: evening), _task(1, at: morning)];

    sortTasksForDisplay(input);

    expect(_ids(input), [2, 1]);
  });

  test('an empty list stays empty', () {
    expect(sortTasksForDisplay(const []), isEmpty);
  });
}
