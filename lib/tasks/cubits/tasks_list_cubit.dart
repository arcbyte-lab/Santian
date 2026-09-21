import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task.dart';
import '../models/task_list.dart';
import '../repository/list_repository.dart';
import '../repository/task_repository.dart';
import '../task_order.dart';
import 'tasks_list_state.dart';

class TasksListCubit extends Cubit<TasksListState> {
  TasksListCubit({
    required TaskRepository tasks,
    required ListRepository lists,
  })  : _tasks = tasks,
        super(const TasksListState()) {
    _listsSub = lists.watchAll().listen(_onLists);
  }

  final TaskRepository _tasks;
  StreamSubscription<List<TaskList>>? _listsSub;
  StreamSubscription<List<Task>>? _tasksSub;

  void selectTab(TasksTab tab) {
    if (tab == state.activeTab) return;
    _activate(tab, lists: state.lists);
  }

  void _onLists(List<TaskList> lists) {
    final active = state.activeTab;
    final stillValid = switch (active) {
      StarredTab() => true,
      ListTab(:final listId) => lists.any((l) => l.id == listId),
      null => false,
    };

    if (stillValid) {
      emit(TasksListState(
        lists: lists,
        activeTab: active,
        tasks: state.tasks,
        isLoading: state.isLoading,
      ));
      return;
    }

    // Opened fresh (or the active List vanished): the first List, if any.
    if (lists.isEmpty) {
      _tasksSub?.cancel();
      _tasksSub = null;
      emit(TasksListState(lists: lists, isLoading: false));
    } else {
      _activate(ListTab(lists.first.id), lists: lists);
    }
  }

  void _activate(TasksTab tab, {required List<TaskList> lists}) {
    _tasksSub?.cancel();
    emit(TasksListState(lists: lists, activeTab: tab));

    final stream = switch (tab) {
      StarredTab() => _tasks.watchStarred(),
      ListTab(:final listId) => _tasks.watchByList(listId),
    };
    _tasksSub = stream.listen((tasks) {
      emit(TasksListState(
        lists: state.lists,
        activeTab: tab,
        tasks: sortTasksForDisplay(tasks),
        isLoading: false,
      ));
    });
  }

  @override
  Future<void> close() async {
    await _listsSub?.cancel();
    await _tasksSub?.cancel();
    return super.close();
  }
}
