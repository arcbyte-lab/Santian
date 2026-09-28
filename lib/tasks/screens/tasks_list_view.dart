import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../cubits/tasks_list_state.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../task_order.dart';
import '../widgets/create_task_fab.dart';
import '../widgets/list_tab_bar.dart';
import '../widgets/month_grid.dart';
import '../widgets/task_row.dart';

/// The Tasks List screen as a pure function of [state]. Kept apart from the
/// Cubit wiring so it can be tested with hand-built states.
class TasksListView extends StatelessWidget {
  const TasksListView({
    super.key,
    required this.state,
    required this.onTabSelected,
    this.onToggleTask,
    this.onToggleStar,
    this.onOpenTask,
    this.onCreateTask,
    this.onAddList,
    this.onRenameList,
    this.onDeleteList,
    this.onDeleteCompletedTasks,
  });

  final TasksListState state;
  final ValueChanged<TasksTab> onTabSelected;

  /// Called when the tab bar's trailing `+` tab is tapped. Null hides it.
  final VoidCallback? onAddList;

  /// Called with a Task whose checkbox was tapped. Null leaves checkboxes inert.
  final ValueChanged<Task>? onToggleTask;

  /// Called with a Task whose star was tapped. Null leaves stars inert.
  final ValueChanged<Task>? onToggleStar;

  /// Called with a Task whose row was tapped outside the checkbox. Null
  /// leaves that area inert.
  final ValueChanged<Task>? onOpenTask;

  /// Called when the FAB is tapped. Null disables it.
  final VoidCallback? onCreateTask;

  /// The active List's menu items, each called with that List. The menu only
  /// shows while a List (not Star) is active.
  final ValueChanged<TaskList>? onRenameList;
  final ValueChanged<TaskList>? onDeleteList;
  final ValueChanged<TaskList>? onDeleteCompletedTasks;

  TaskList? get _activeList => switch (state.activeTab) {
    ListTab(:final listId) =>
      state.lists.where((l) => l.id == listId).firstOrNull,
    _ => null,
  };

  Widget _page(TasksTab tab) {
    final tasks = state.tasksFor(tab);
    final empty = tasks.isEmpty && !state.isLoading;
    Widget row(Task task) => TaskRow(
      task: task,
      onToggle: onToggleTask == null ? null : () => onToggleTask!(task),
      onToggleStar: onToggleStar == null ? null : () => onToggleStar!(task),
      onOpenDetail: onOpenTask == null ? null : () => onOpenTask!(task),
    );
    // Star stays one flat list; a List groups its completed Tasks below.
    if (tab is! ListTab) {
      if (empty) return const _EmptyTasks();
      return ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (_, i) => row(tasks[i]),
      );
    }
    final completed = tasks.where((t) => t.isCompleted).toList();
    final now = DateTime.now();
    final list = ListView(
      children: [
        for (final (label, group) in groupRuns(
          tasks.where((t) => !t.isCompleted),
          (t) => dayHeaderLabel(t.reminderAt, now),
        )) ...[
          _DayHeader(label: label),
          for (final t in group) row(t),
        ],
        // Always shown on a List, even at (0).
        _CompletedSection(
          // Keeps each List's collapsed/expanded choice across tab swipes.
          key: PageStorageKey('completed-${tab.listId}'),
          count: completed.length,
          children: [for (final t in completed) row(t)],
        ),
      ],
    );
    return empty ? Stack(children: [const _EmptyTasks(), list]) : list;
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
                      // Fixed, so the header doesn't change height when
                      // Star (no menu) is active.
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            const SizedBox(width: 48),
                            const Expanded(
                              child: Center(
                                child: _RootCardLabel(text: 'Tasks'),
                              ),
                            ),
                            SizedBox(
                              width: 48,
                              child: switch (_activeList) {
                                final list? => _ListMenu(
                                  // The last List can't go: the FAB always
                                  // needs a List to create into.
                                  onRename: _bind(onRenameList, list),
                                  onDelete: state.lists.length > 1
                                      ? _bind(onDeleteList, list)
                                      : null,
                                  onDeleteCompleted:
                                      state.tasks.any((t) => t.isCompleted)
                                      ? _bind(onDeleteCompletedTasks, list)
                                      : null,
                                ),
                                null => null,
                              },
                            ),
                          ],
                        ),
                      ),
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

VoidCallback? _bind(ValueChanged<TaskList>? f, TaskList list) =>
    f == null ? null : () => f(list);

/// The active List's `More` menu. A null callback disables its item.
class _ListMenu extends StatelessWidget {
  const _ListMenu({this.onRename, this.onDelete, this.onDeleteCompleted});

  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onDeleteCompleted;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).extension<AppColors>()!.mutedForeground;
    return PopupMenuButton<void>(
      icon: Icon(Icons.more_vert, color: muted),
      tooltip: 'List options',
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: onRename != null,
          onTap: onRename,
          child: const Text('Rename list'),
        ),
        PopupMenuItem<void>(
          enabled: onDelete != null,
          onTap: onDelete,
          child: const Text('Delete list'),
        ),
        PopupMenuItem<void>(
          enabled: onDeleteCompleted != null,
          onTap: onDeleteCompleted,
          child: const Text('Delete all completed tasks'),
        ),
      ],
    );
  }
}

class _RootCardLabel extends StatelessWidget {
  const _RootCardLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

const pastLabel = 'Past';

/// A day header's text: Past for anything before today, Today, Tomorrow,
/// else [formatShortDate]. Null [day] is the Tasks with no reminder: "No
/// date".
String dayHeaderLabel(DateTime? day, DateTime now) {
  if (day == null) return 'No date';
  final diff = calendarDaysFrom(now, day);
  if (diff < 0) return pastLabel;
  switch (diff) {
    case 0:
      return 'Today';
    case 1:
      return 'Tomorrow';
  }
  return formatShortDate(day, now);
}

/// Heads one run of open Tasks; [label] is from [dayHeaderLabel]. Past is
/// error-colored, like the overdue dates in its rows.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium!.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: label == pastLabel
              ? theme.colorScheme.error
              : theme.extension<AppColors>()!.mutedForeground,
        ),
      ),
    );
  }
}

/// A List's completed Tasks under a "Completed (N)" header, expanded until
/// the header is tapped.
class _CompletedSection extends StatelessWidget {
  const _CompletedSection({
    super.key,
    required this.count,
    required this.children,
  });

  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.extension<AppColors>()!.mutedForeground;
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: muted,
      collapsedIconColor: muted,
      title: Text(
        'Completed ($count)',
        style: theme.textTheme.bodyMedium!.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: muted,
        ),
      ),
      children: children,
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
