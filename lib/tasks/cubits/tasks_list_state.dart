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
    this.tasks = const [],
    this.isLoading = true,
  });

  final List<TaskList> lists;

  /// Null only while there are no Lists at all.
  final TasksTab? activeTab;

  /// The active tab's tasks, already in display order.
  final List<Task> tasks;

  final bool isLoading;
}
