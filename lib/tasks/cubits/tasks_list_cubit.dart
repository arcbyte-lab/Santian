import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task.dart';
import '../models/task_list.dart';
import '../repository/list_repository.dart';
import '../repository/task_repository.dart';
import 'tasks_list_state.dart';

class TasksListCubit extends Cubit<TasksListState> {
  TasksListCubit({
    required TaskRepository tasks,
    required ListRepository lists,
  })  : _tasks = tasks,
        _lists = lists,
        super(const TasksListState()) {
    _listsSub = lists.watchAll().listen(_onLists);
    _tasksSub = tasks.watchAll().listen(_onTasks);
  }

  final TaskRepository _tasks;
  final ListRepository _lists;
  StreamSubscription<List<TaskList>>? _listsSub;
  StreamSubscription<List<Task>>? _tasksSub;

  /// Set the moment a first-launch default List is requested, so a second
  /// empty emission arriving before Isar's own write notification comes back
  /// (the two are both async) can't fire a second one.
  bool _creatingDefaultList = false;

  void selectTab(TasksTab tab) {
    if (tab == state.activeTab) return;
    _activate(tab, lists: state.lists);
  }

  /// Flips [task]'s completion. The tasks stream delivers the change, so
  /// there is nothing to emit here.
  Future<void> toggleCompleted(Task task) => _tasks.toggleCompleted(task);

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
        lastListId: state.lastListId,
        allTasks: state.allTasks,
        isLoading: state.isLoading,
      ));
      return;
    }

    // Opened fresh (or the active List vanished): the first List, if any.
    if (lists.isEmpty) {
      if (!_creatingDefaultList) {
        _creatingDefaultList = true;
        _lists.createDefault();
      }
      emit(TasksListState(
        lists: lists,
        allTasks: state.allTasks,
        isLoading: state.isLoading,
      ));
    } else {
      _creatingDefaultList = false;
      _activate(ListTab(lists.first.id), lists: lists);
    }
  }

  void _activate(TasksTab tab, {required List<TaskList> lists}) {
    emit(TasksListState(
      lists: lists,
      activeTab: tab,
      lastListId: tab is ListTab ? tab.listId : state.lastListId,
      allTasks: state.allTasks,
      isLoading: state.isLoading,
    ));
  }

  void _onTasks(List<Task> tasks) {
    emit(TasksListState(
      lists: state.lists,
      activeTab: state.activeTab,
      lastListId: state.lastListId,
      allTasks: tasks,
      isLoading: false,
    ));
  }

  @override
  Future<void> close() async {
    await _listsSub?.cancel();
    await _tasksSub?.cancel();
    return super.close();
  }
}
