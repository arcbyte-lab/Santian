import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/repeat.dart';
import '../models/subtask.dart';
import '../models/task.dart';
import '../repository/task_repository.dart';
import '../subtask_order.dart';

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
  // Deep-copied, not just the same List reference: every other field here is
  // a value type, but `subtasks` is a mutable embedded list, so sharing it
  // between clones would let mutating one Subtask (add/edit/toggle/delete/
  // reorder) silently leak back into whatever earlier state still holds this
  // "clone".
  ..subtasks = task.subtasks.map((s) => s.copyWith()).toList();

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

  /// Null clears the reminder, removing the chip. Clearing also clears
  /// `repeat` — a spec gap: `toggleCompleted`'s repeating branch reads
  /// `reminderAt!`, so a repeat left dangling with no reminder would crash
  /// on completion. Flagged back to Arcbyte to confirm, not a ruling.
  Future<void> setReminder(DateTime? reminderAt, {Repeat? repeat}) => _edit((t) {
        t.reminderAt = reminderAt;
        t.repeat = reminderAt == null ? null : repeat;
      });

  /// Null clears the deadline, removing the chip.
  Future<void> setDeadline(DateTime? deadline) =>
      _edit((t) => t.deadline = deadline);

  /// Appends a new Subtask after every existing one (by `order`). A blank
  /// title is dropped rather than saved, same rule as [setTitle].
  Future<void> addSubtask(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return _edit((t) {
      final sorted = sortSubtasksForDisplay(t.subtasks);
      final nextOrder = sorted.isEmpty ? 0 : sorted.last.order + 1;
      t.subtasks = [...t.subtasks, Subtask()..title = trimmed..order = nextOrder];
    });
  }

  /// Saved on blur, like [setTitle] - and, like [setTitle], a blank result is
  /// dropped rather than saved (a Subtask's title cannot go blank either).
  Future<void> setSubtaskTitle(String id, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return _edit((t) {
      t.subtasks = [
        for (final s in t.subtasks) s.id == id ? s.copyWith(title: trimmed) : s,
      ];
    });
  }

  /// Independent of the parent Task's own completion in both directions -
  /// this never touches `t.isCompleted`, and [toggleCompleted] never touches
  /// any Subtask.
  Future<void> toggleSubtask(String id) => _edit((t) {
        t.subtasks = [
          for (final s in t.subtasks)
            s.id == id ? s.copyWith(isCompleted: !s.isCompleted) : s,
        ];
      });

  /// No undo - the spec doesn't ask for one here, unlike deleting the Task
  /// itself.
  Future<void> deleteSubtask(String id) =>
      _edit((t) => t.subtasks = t.subtasks.where((s) => s.id != id).toList());

  /// Applies a `ReorderableListView.onReorder` drag to the Subtasks and
  /// rewrites every `order` to match - see [applySubtaskReorder] for the
  /// index convention.
  Future<void> reorderSubtasks(int oldIndex, int newIndex) => _edit(
        (t) => t.subtasks = applySubtaskReorder(t.subtasks, oldIndex, newIndex),
      );

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
