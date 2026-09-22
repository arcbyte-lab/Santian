import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../cubits/tasks_list_state.dart';
import '../models/task.dart';
import '../widgets/create_task_fab.dart';
import '../widgets/list_tab_bar.dart';
import '../widgets/task_row.dart';

/// The Tasks List screen as a pure function of [state]. Kept apart from the
/// Cubit wiring so it can be tested with hand-built states.
class TasksListView extends StatelessWidget {
  const TasksListView({
    super.key,
    required this.state,
    required this.onTabSelected,
    this.onToggleTask,
    this.onOpenTask,
    this.onCreateTask,
    this.onAddList,
  });

  final TasksListState state;
  final ValueChanged<TasksTab> onTabSelected;

  /// Called when the tab bar's trailing `+` tab is tapped. Null hides it.
  final VoidCallback? onAddList;

  /// Called with a Task whose checkbox was tapped. Null leaves checkboxes inert.
  final ValueChanged<Task>? onToggleTask;

  /// Called with a Task whose row was tapped outside the checkbox. Null
  /// leaves that area inert.
  final ValueChanged<Task>? onOpenTask;

  /// Called when the FAB is tapped. Null disables it.
  final VoidCallback? onCreateTask;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Stack(
                children: [
                  Column(
                    children: [
                      ListTabBar(
                        lists: state.lists,
                        activeTab: state.activeTab,
                        onSelected: onTabSelected,
                        onAddList: onAddList,
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.tasks.length,
                          itemBuilder: (_, i) {
                            final task = state.tasks[i];
                            return TaskRow(
                              task: task,
                              onToggle: onToggleTask == null
                                  ? null
                                  : () => onToggleTask!(task),
                              onOpenDetail: onOpenTask == null
                                  ? null
                                  : () => onOpenTask!(task),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 21,
                    bottom: 23,
                    child: CreateTaskFab(onPressed: onCreateTask),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
