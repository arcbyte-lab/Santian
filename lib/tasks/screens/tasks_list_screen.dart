import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/tasks_list_cubit.dart';
import '../cubits/tasks_list_state.dart';
import '../repository/list_repository.dart';
import '../repository/task_repository.dart';
import 'create_task_sheet.dart';
import 'tasks_list_view.dart';

/// Wires [TasksListView] to a [TasksListCubit]. Needs a [TaskRepository] and a
/// [ListRepository] above it in the tree.
class TasksListScreen extends StatelessWidget {
  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TasksListCubit(
        tasks: context.read<TaskRepository>(),
        lists: context.read<ListRepository>(),
      ),
      child: BlocBuilder<TasksListCubit, TasksListState>(
        builder: (context, state) {
          final listId = state.createListId;
          return TasksListView(
            state: state,
            onTabSelected: context.read<TasksListCubit>().selectTab,
            onToggleTask: context.read<TasksListCubit>().toggleCompleted,
            onCreateTask: listId == null
                ? null
                : () => showCreateTaskSheet(context, listId: listId),
          );
        },
      ),
    );
  }
}
