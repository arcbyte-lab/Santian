import '../models/task.dart';
import '../models/task_list.dart';

/// Which tab of the List Tab Bar is active. Star is a filter over
/// `Task.isStarred`, not a List, so it is its own case.
sealed class TasksTab {
  const TasksTab();
}

final class StarredTab extends TasksTab {
  const StarredTab();

  @override
  bool operator ==(Object other) => other is StarredTab;

  @override
  int get hashCode => (StarredTab).hashCode;
}

final class ListTab extends TasksTab {
  const ListTab(this.listId);

  final int listId;

  @override
  bool operator ==(Object other) => other is ListTab && other.listId == listId;

  @override
  int get hashCode => Object.hash(ListTab, listId);
}

class TasksListState {
  const TasksListState({
    this.lists = const [],
    this.activeTab,
    this.lastListId,
    this.tasks = const [],
    this.isLoading = true,
  });

  final List<TaskList> lists;

  /// Null only while there are no Lists at all.
  final TasksTab? activeTab;

  /// The last List that was active, so Star can still say where a new Task
  /// goes. Null until a List has been active.
  final int? lastListId;

  /// The active tab's tasks, already in display order.
  final List<Task> tasks;

  final bool isLoading;

  /// The List a new Task is created in: the active List; on Star, the last
  /// List that was active before it; failing that, the first List. Null only
  /// when there are no Lists at all.
  int? get createListId {
    final first = lists.isEmpty ? null : lists.first.id;
    return switch (activeTab) {
      ListTab(:final listId) => listId,
      StarredTab() =>
        lists.any((l) => l.id == lastListId) ? lastListId : first,
      null => first,
    };
  }
}
