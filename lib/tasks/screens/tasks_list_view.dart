import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../cubits/tasks_list_state.dart';
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
    this.onCreateTask,
  });

  final TasksListState state;
  final ValueChanged<TasksTab> onTabSelected;

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
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.tasks.length,
                          itemBuilder: (_, i) => TaskRow(task: state.tasks[i]),
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
