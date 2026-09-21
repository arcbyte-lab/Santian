import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_radius.dart';
import '../cubits/create_task_cubit.dart';
import '../repository/task_repository.dart';
import 'create_task_form.dart';

/// Opens the Create Task sheet already risen, with the keyboard on the title.
/// The new Task goes into [listId]. Needs a [TaskRepository] above [context].
Future<void> showCreateTaskSheet(
  BuildContext context, {
  required int listId,
}) {
  final tasks = context.read<TaskRepository>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: const Color(0x40000000),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (_) => BlocProvider(
      create: (_) => CreateTaskCubit(tasks: tasks, listId: listId),
      child: const CreateTaskSheet(),
    ),
  );
}

/// Wires [CreateTaskForm] to the [CreateTaskCubit] above it, and closes the
/// sheet once a Task has been created.
class CreateTaskSheet extends StatelessWidget {
  const CreateTaskSheet({super.key});

  Future<void> _submit(BuildContext context) async {
    final created = await context.read<CreateTaskCubit>().submit();
    if (created && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateTaskCubit, CreateTaskState>(
      builder: (context, state) {
        final cubit = context.read<CreateTaskCubit>();
        return Padding(
          // Lift the sheet above the keyboard.
          padding: EdgeInsets.fromLTRB(
            28,
            16,
            28,
            28 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: CreateTaskForm(
            state: state,
            onTitleChanged: cubit.setTitle,
            onNotesChanged: cubit.setNotes,
            onToggleNotes: cubit.toggleNotes,
            onToggleStar: cubit.toggleStar,
            onSubmit: () => _submit(context),
          ),
        );
      },
    );
  }
}
