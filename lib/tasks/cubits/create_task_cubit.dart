import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task.dart';
import '../repository/task_repository.dart';

class CreateTaskState {
  const CreateTaskState({
    this.title = '',
    this.notes = '',
    this.notesVisible = false,
    this.isStarred = false,
    this.reminderAt,
  });

  final String title;
  final String notes;
  final bool notesVisible;
  final bool isStarred;
  final DateTime? reminderAt;

  /// A Task needs a title that is not blank; nothing else is required.
  bool get canSubmit => title.trim().isNotEmpty;

  CreateTaskState copyWith({
    String? title,
    String? notes,
    bool? notesVisible,
    bool? isStarred,
    DateTime? reminderAt,
  }) =>
      CreateTaskState(
        title: title ?? this.title,
        notes: notes ?? this.notes,
        notesVisible: notesVisible ?? this.notesVisible,
        isStarred: isStarred ?? this.isStarred,
        reminderAt: reminderAt ?? this.reminderAt,
      );
}

/// State for one open Create Task sheet. Everything but the title starts empty
/// and is set later from Task Detail; only notes and star can be set here.
class CreateTaskCubit extends Cubit<CreateTaskState> {
  CreateTaskCubit({required TaskRepository tasks, required int listId})
      : _tasks = tasks,
        _listId = listId,
        super(const CreateTaskState());

  final TaskRepository _tasks;
  final int _listId;
  var _submitted = false;

  void setTitle(String title) => emit(state.copyWith(title: title));

  void setNotes(String notes) => emit(state.copyWith(notes: notes));

  void toggleNotes() =>
      emit(state.copyWith(notesVisible: !state.notesVisible));

  void toggleStar() => emit(state.copyWith(isStarred: !state.isStarred));

  void setReminder(DateTime reminderAt) =>
      emit(state.copyWith(reminderAt: reminderAt));

  /// Creates the Task and returns true. Returns false, doing nothing, when the
  /// title is blank (the sheet stays open, with no error) or when a Task was
  /// already created from this sheet.
  Future<bool> submit() async {
    if (!state.canSubmit || _submitted) return false;
    _submitted = true;

    // Notes count only while their field is showing: hiding it discards them
    // rather than saving text the user can no longer see.
    final notes = state.notesVisible ? state.notes.trim() : '';
    try {
      await _tasks.create(Task()
        ..listId = _listId
        ..title = state.title.trim()
        ..description = notes.isEmpty ? null : notes
        ..isStarred = state.isStarred
        ..reminderAt = state.reminderAt);
    } catch (_) {
      _submitted = false; // a failed save must not lock the sheet
      rethrow;
    }
    return true;
  }
}
