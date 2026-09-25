import '../models/task.dart';
import '../models/task_list.dart';
import '../task_order.dart';

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
    this.allTasks = const [],
    this.isLoading = true,
  });

  final List<TaskList> lists;

  /// Null only while there are no Lists at all.
  final TasksTab? activeTab;

  /// The last List that was active, so Star can still say where a new Task
  /// goes. Null until a List has been active.
  final int? lastListId;

  /// Every Task in every List, in no particular order. Each tab's tasks are
  /// derived from it by [tasksFor].
  final List<Task> allTasks;

  /// The tabs in tab-bar order: Star, then each List.
  List<TasksTab> get tabs =>
      [const StarredTab(), for (final l in lists) ListTab(l.id)];

  /// [tab]'s tasks, in display order.
  // ponytail: filters and sorts on every call; cache per tab if Lists grow
  // large enough for page builds to show up in a profile.
  List<Task> tasksFor(TasksTab tab) => sortTasksForDisplay(allTasks.where(
        (t) => switch (tab) {
          StarredTab() => t.isStarred,
          ListTab(:final listId) => t.listId == listId,
        },
      ));

  /// The active tab's tasks, in display order.
  List<Task> get tasks => switch (activeTab) {
        final tab? => tasksFor(tab),
        null => const [],
      };

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
