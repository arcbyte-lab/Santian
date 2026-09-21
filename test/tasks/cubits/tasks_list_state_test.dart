import 'package:flutter_test/flutter_test.dart';
import 'package:santian/tasks/cubits/tasks_list_state.dart';
import 'package:santian/tasks/models/task_list.dart';

TaskList _list(int id) => TaskList()
  ..id = id
  ..name = 'List $id'
  ..icon = 'rocket'
  ..color = 1;

void main() {
  group('createListId', () {
    test('is the active List', () {
      final state = TasksListState(
        lists: [_list(1), _list(2)],
        activeTab: const ListTab(2),
      );

      expect(state.createListId, 2);
    });

    test('on Star is the remembered List', () {
      final state = TasksListState(
        lists: [_list(1), _list(2)],
        activeTab: const StarredTab(),
        lastListId: 2,
      );

      expect(state.createListId, 2);
    });

    test('on Star with nothing remembered is the first List', () {
      final state = TasksListState(
        lists: [_list(4), _list(5)],
        activeTab: const StarredTab(),
      );

      expect(state.createListId, 4);
    });

    test('on Star with a remembered List that no longer exists is the first List', () {
      final state = TasksListState(
        lists: [_list(4), _list(5)],
        activeTab: const StarredTab(),
        lastListId: 99,
      );

      expect(state.createListId, 4);
    });

    test('with no active tab is the first List, if any', () {
      expect(TasksListState(lists: [_list(3)]).createListId, 3);
      expect(const TasksListState().createListId, isNull);
    });
  });

  group('tab equality', () {
    test('the same List is the same tab', () {
      expect(const ListTab(1), const ListTab(1));
      expect(const ListTab(1), isNot(const ListTab(2)));
      expect(const ListTab(1).hashCode, const ListTab(1).hashCode);
    });

    test('Star is one tab and is not a List', () {
      expect(const StarredTab(), const StarredTab());
      expect(const StarredTab(), isNot(const ListTab(1)));
    });
  });
}
