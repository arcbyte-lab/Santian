import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_radius.dart';
import '../cubits/task_detail_cubit.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../repository/list_repository.dart';
import '../repository/task_repository.dart';
import 'task_detail_view.dart';

/// Opens Task Detail as a modal sheet for [task]. Needs a [TaskRepository]
/// and a [ListRepository] above [context]. If the Task is deleted while the
/// sheet is open, shows an undo toast once the sheet closes.
Future<void> showTaskDetailSheet(BuildContext context, {required Task task}) async {
  final tasks = context.read<TaskRepository>();
  final lists = context.read<ListRepository>();
  final messenger = ScaffoldMessenger.of(context);

  final deleted = await showModalBottomSheet<Task>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    // #00000080, per the spec: darker than Create Task's dim, since Task
    // Detail is a full modal, not a compose sheet.
    barrierColor: const Color(0x80000000),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (_) => MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: tasks),
        RepositoryProvider.value(value: lists),
      ],
      child: BlocProvider(
        create: (_) => TaskDetailCubit(tasks: tasks, task: task),
        child: const TaskDetailSheet(),
      ),
    ),
  );

  // No confirm dialog for delete; this toast is the one accident-guard, and
  // letting it expire (or dismissing it) makes the delete final.
  if (deleted != null) {
    messenger.showSnackBar(SnackBar(
      content: const Text('Task deleted'),
      action: SnackBarAction(label: 'Undo', onPressed: () => tasks.update(deleted)),
    ));
  }
}

/// Wires [TaskDetailView] to the [TaskDetailCubit] above it. Pops the sheet,
/// with the deleted Task as the result, once [TaskDetailState.isDeleted].
class TaskDetailSheet extends StatelessWidget {
  const TaskDetailSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TaskList>>(
      stream: context.read<ListRepository>().watchAll(),
      builder: (context, snapshot) {
        final lists = snapshot.data ?? const <TaskList>[];
        return BlocConsumer<TaskDetailCubit, TaskDetailState>(
          listenWhen: (previous, current) =>
              !previous.isDeleted && current.isDeleted,
          listener: (context, state) => Navigator.of(context).pop(state.task),
          builder: (context, state) {
            final cubit = context.read<TaskDetailCubit>();
            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
              child: TaskDetailView(
                state: state,
                lists: lists,
                onBack: () => Navigator.of(context).pop(),
                onToggleStar: cubit.toggleStar,
                onSelectList: (list) => cubit.setListId(list.id),
                onTitleChanged: cubit.setTitle,
                onDescriptionChanged: cubit.setDescription,
                onDeadlineChanged: cubit.setDeadline,
                onReminderChanged: cubit.setReminder,
                onAddSubtask: cubit.addSubtask,
                onSubtaskTitleChanged: cubit.setSubtaskTitle,
                onToggleSubtask: cubit.toggleSubtask,
                onDeleteSubtask: cubit.deleteSubtask,
                onReorderSubtasks: cubit.reorderSubtasks,
                onToggleCompleted: cubit.toggleCompleted,
                onDelete: cubit.delete,
              ),
            );
          },
        );
      },
    );
  }
}
