import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/tasks_list_cubit.dart';
import '../cubits/tasks_list_state.dart';
import '../repository/list_repository.dart';
import '../repository/task_repository.dart';
import 'create_list_sheet.dart';
import 'create_task_sheet.dart';
import 'task_detail_sheet.dart';
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
          final cubit = context.read<TasksListCubit>();
          final listId = state.createListId;
          return TasksListView(
            state: state,
            onTabSelected: cubit.selectTab,
            onToggleTask: cubit.toggleCompleted,
            onToggleStar: cubit.toggleStarred,
            onOpenTask: (task) => showTaskDetailSheet(context, task: task),
            onCreateTask: listId == null
                ? null
                : () => showCreateTaskSheet(context, listId: listId),
            onAddList: () async {
              final id = await showCreateListSheet(context);
              // The new tab is inserted before `+` and selected.
              if (id != null && context.mounted) {
                cubit.selectTab(ListTab(id));
              }
            },
            onRenameList: (list) async {
              final name = await showDialog<String>(
                context: context,
                builder: (_) => _RenameListDialog(name: list.name),
              );
              if (name != null) await cubit.renameList(list.id, name);
            },
            onDeleteList: (list) async {
              if (await _confirm(
                context,
                title: 'Delete "${list.name}"?',
                body: 'All tasks in this list will be deleted.',
              )) {
                await cubit.deleteList(list.id);
              }
            },
            onDeleteCompletedTasks: (list) async {
              if (await _confirm(
                context,
                title: 'Delete all completed tasks?',
                body: 'Completed tasks in "${list.name}" will be deleted.',
              )) {
                await cubit.deleteCompletedTasks(list.id);
              }
            },
          );
        },
      ),
    );
  }
}

/// A Delete/Cancel dialog; true only when Delete is tapped. Unlike a single
/// Task's delete, these remove many Tasks at once and have no undo.
Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;

/// Pops with the new name, or nothing if cancelled. Save is disabled while
/// the name is blank, same rule as Create List.
class _RenameListDialog extends StatefulWidget {
  const _RenameListDialog({required this.name});

  final String name;

  @override
  State<_RenameListDialog> createState() => _RenameListDialogState();
}

class _RenameListDialogState extends State<_RenameListDialog> {
  late final _name = TextEditingController(text: widget.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isNotEmpty) Navigator.pop(context, _name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename list'),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _name.text.trim().isEmpty ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
