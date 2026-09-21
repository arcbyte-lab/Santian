import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task.dart';
import '../repository/task_repository.dart';

class TaskDetailState {
  const TaskDetailState({required this.task, this.isDeleted = false});

  final Task task;

  /// True once [TaskDetailCubit.delete] has removed the Task. The sheet
  /// listens for this and closes itself, handing [task] back to the caller
  /// so it can offer undo.
  final bool isDeleted;
}

Task _clone(Task task) => Task()
  ..id = task.id
  ..listId = task.listId
  ..title = task.title
  ..description = task.description
  ..reminderAt = task.reminderAt
  ..deadline = task.deadline
  ..repeat = task.repeat
  ..isStarred = task.isStarred
  ..isCompleted = task.isCompleted
  ..subtasks = task.subtasks;

/// State and actions for one open Task Detail sheet: star, list, title,
/// description, completion, and delete. Every edit persists immediately via
/// [TaskRepository.update] — there is no separate save step, matching Title
/// and Description's tap-to-edit/save-on-blur behavior.
class TaskDetailCubit extends Cubit<TaskDetailState> {
  TaskDetailCubit({required TaskRepository tasks, required Task task})
      : _tasks = tasks,
        super(TaskDetailState(task: _clone(task)));

  final TaskRepository _tasks;

  Future<void> setTitle(String title) {
    final trimmed = title.trim();
    // A Task's title cannot be blank; an edit that would leave it blank is
    // dropped rather than saved.
    return trimmed.isEmpty ? Future<void>.value() : _edit((t) => t.title = trimmed);
  }

  Future<void> setDescription(String description) {
    final trimmed = description.trim();
    return _edit((t) => t.description = trimmed.isEmpty ? null : trimmed);
  }

  Future<void> toggleStar() => _edit((t) => t.isStarred = !t.isStarred);

  Future<void> setListId(int listId) => _edit((t) => t.listId = listId);

  /// Null clears the reminder, removing the chip.
  Future<void> setReminder(DateTime? reminderAt) =>
      _edit((t) => t.reminderAt = reminderAt);

  /// Null clears the deadline, removing the chip.
  Future<void> setDeadline(DateTime? deadline) =>
      _edit((t) => t.deadline = deadline);

  Future<void> _edit(void Function(Task) mutate) {
    final next = _clone(state.task);
    mutate(next);
    emit(TaskDetailState(task: next));
    return _tasks.update(next);
  }

  /// Same action as the Tasks List checkbox.
  Future<void> toggleCompleted() async {
    await _tasks.toggleCompleted(state.task);
    emit(TaskDetailState(
      task: _clone(state.task)..isCompleted = !state.task.isCompleted,
    ));
  }

  /// Deletes the Task immediately — no confirm dialog. The resulting state's
  /// [TaskDetailState.task] is the deleted copy, including its id, so the
  /// sheet can hand it back to the caller for the undo toast.
  Future<void> delete() async {
    await _tasks.delete(state.task.id);
    emit(TaskDetailState(task: state.task, isDeleted: true));
  }
}
