import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../cubits/tasks_list_state.dart';
import '../models/task.dart';
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
    this.onToggleTask,
    this.onOpenTask,
    this.onCreateTask,
    this.onAddList,
  });

  final TasksListState state;
  final ValueChanged<TasksTab> onTabSelected;

  /// Called when the tab bar's trailing `+` tab is tapped. Null hides it.
  final VoidCallback? onAddList;

  /// Called with a Task whose checkbox was tapped. Null leaves checkboxes inert.
  final ValueChanged<Task>? onToggleTask;

  /// Called with a Task whose row was tapped outside the checkbox. Null
  /// leaves that area inert.
  final ValueChanged<Task>? onOpenTask;

  /// Called when the FAB is tapped. Null disables it.
  final VoidCallback? onCreateTask;

  Widget _page(TasksTab tab) {
    final tasks = state.tasksFor(tab);
    if (tasks.isEmpty && !state.isLoading) return const _EmptyTasks();
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (_, i) {
        final task = tasks[i];
        return TaskRow(
          task: task,
          onToggle: onToggleTask == null ? null : () => onToggleTask!(task),
          onOpenDetail: onOpenTask == null ? null : () => onOpenTask!(task),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The sheets pad themselves for the keyboard; resizing this screen under
      // them only makes the empty-state text and FAB jump upward.
      resizeToAvoidBottomInset: false,
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
                      RootCardLabel(text: "Tasks"),
                      Expanded(
                        child: _TabPages(
                          tabs: state.tabs,
                          activeTab: state.activeTab,
                          onPageChanged: onTabSelected,
                          tabBar: (position) => ListTabBar(
                            lists: state.lists,
                            activeTab: state.activeTab,
                            position: position,
                            onSelected: onTabSelected,
                            onAddList: onAddList,
                          ),
                          pageBuilder: _page,
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

class RootCardLabel extends StatelessWidget {
  const RootCardLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Shown in place of the Task list when the active tab has no Tasks.
class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'No tasks for today',
        style: theme.textTheme.bodySmall!.copyWith(
          fontSize: 12,
          color: theme.extension<AppColors>()!.mutedForeground,
        ),
      ),
    );
  }
}

/// One page per tab, in tab-bar order, so a horizontal drag pulls the
/// neighbouring tab into view under the finger. Settling on a page reports it
/// through [onPageChanged]; a tab chosen elsewhere (a tap on the tab bar)
/// animates the pages to it. Builds [tabBar] above the pages, handing it the
/// live scroll position so its underline can follow the drag.
class _TabPages extends StatefulWidget {
  const _TabPages({
    required this.tabs,
    required this.activeTab,
    required this.onPageChanged,
    required this.tabBar,
    required this.pageBuilder,
  });

  final List<TasksTab> tabs;
  final TasksTab? activeTab;
  final ValueChanged<TasksTab> onPageChanged;
  final Widget Function(ValueListenable<double> position) tabBar;
  final Widget Function(TasksTab tab) pageBuilder;

  @override
  State<_TabPages> createState() => _TabPagesState();
}

class _TabPagesState extends State<_TabPages> {
  late final PageController _controller = PageController(
    initialPage: _activeIndex,
  )..addListener(_reportPosition);

  /// The pages' scroll position in pages, e.g. 1.4 between tabs 1 and 2.
  late final _position = ValueNotifier<double>(_activeIndex.toDouble());

  void _reportPosition() {
    final page = _controller.page;
    if (page != null) _position.value = page;
  }

  /// True while the pages animate to a tab chosen elsewhere. The pages they
  /// pass on the way must not be reported as chosen.
  bool _animating = false;

  int get _activeIndex {
    final i = widget.tabs.indexOf(widget.activeTab ?? const StarredTab());
    return i < 0 ? 0 : i;
  }

  @override
  void didUpdateWidget(_TabPages oldWidget) {
    super.didUpdateWidget(oldWidget);
    _followActiveTab();
  }

  /// On a different page than the active tab (a tap, or a List inserted
  /// before this one): move there without re-reporting the pages passed.
  /// Re-checks when done, in case the active tab changed again meanwhile.
  void _followActiveTab() {
    if (_animating || !_controller.hasClients) return;
    final target = _activeIndex;
    if (_controller.page?.round() == target) return;
    _animating = true;
    _controller
        .animateToPage(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
      _animating = false;
      if (mounted) _followActiveTab();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.tabBar(_position),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.tabs.length,
            onPageChanged: (i) {
              if (!_animating) widget.onPageChanged(widget.tabs[i]);
            },
            itemBuilder: (_, i) => widget.pageBuilder(widget.tabs[i]),
          ),
        ),
      ],
    );
  }
}
