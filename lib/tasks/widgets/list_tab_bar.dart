import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../cubits/tasks_list_state.dart';
import '../models/task_list.dart';
import 'list_icon.dart';

/// The horizontally scrolling row of tabs above the Tasks List: Star first,
/// then one tab per List. Exactly one tab is active.
///
/// A single underline marks the active tab. Given [position] - the pages'
/// scroll position, where 1.4 is 40% of the way from tab 1 to tab 2 - it
/// slides and resizes between tabs as the pages are dragged, and the tabs'
/// tint follows it.
class ListTabBar extends StatefulWidget {
  const ListTabBar({
    super.key,
    required this.lists,
    required this.activeTab,
    required this.onSelected,
    this.position,
    this.onAddList,
  });

  final List<TaskList> lists;
  final TasksTab? activeTab;
  final ValueChanged<TasksTab> onSelected;

  /// Null pins the underline to [activeTab].
  final ValueListenable<double>? position;

  /// Called when the trailing `+` tab is tapped. Null hides it - there is no
  /// List Repository to create into yet (shouldn't happen outside a test
  /// harness missing one, since [ListRepository.createDefault] means a real
  /// app is never without at least one List).
  final VoidCallback? onAddList;

  @override
  State<ListTabBar> createState() => _ListTabBarState();
}

class _ListTabBarState extends State<ListTabBar> {
  final _stackKey = GlobalKey();

  /// One per page tab (Star, then each List), on the part the underline spans.
  List<GlobalKey> _tabKeys = [];

  /// Where each page tab sits in the row, measured after layout. Empty until
  /// the first frame is laid out, and the underline waits for it.
  List<Rect> _tabRects = [];

  int get _activeIndex {
    final active = widget.activeTab;
    if (active is ListTab) {
      final i = widget.lists.indexWhere((l) => l.id == active.listId);
      if (i >= 0) return i + 1;
    }
    return 0;
  }

  @override
  void didUpdateWidget(ListTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeTab != oldWidget.activeTab) {
      // Keep the newly active tab on screen when there are more tabs than fit.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _keyFor(_activeIndex).currentContext;
        if (context != null && context.mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  GlobalKey _keyFor(int index) {
    while (_tabKeys.length <= index) {
      _tabKeys = [..._tabKeys, GlobalKey()];
    }
    return _tabKeys[index];
  }

  /// Re-measures the tabs after every layout, since a List rename, a new List,
  /// or the active label turning bold all move them. Rebuilds only on change.
  void _measure(Duration _) {
    if (!mounted) return;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || !stack.hasSize) return;
    final rects = <Rect>[];
    for (var i = 0; i <= widget.lists.length; i++) {
      final box = _keyFor(i).currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      rects.add(box.localToGlobal(Offset.zero, ancestor: stack) & box.size);
    }
    if (!listEquals(rects, _tabRects)) setState(() => _tabRects = rects);
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.position;
    if (position == null) return _bar(_activeIndex.toDouble());
    return ValueListenableBuilder<double>(
      valueListenable: position,
      builder: (_, value, _) => _bar(value),
    );
  }

  Widget _bar(double position) {
    WidgetsBinding.instance.addPostFrameCallback(_measure);
    final lists = widget.lists;
    final activeTab = widget.activeTab;
    final onAddList = widget.onAddList;
    final p = position.clamp(0.0, lists.length.toDouble());

    // 1 on the tab the position is at, fading to 0 one tab away.
    double highlight(int index) => (1 - (p - index).abs()).clamp(0.0, 1.0);

    // The underline, between the two tabs either side of the position.
    Rect? underline;
    if (_tabRects.length == lists.length + 1) {
      final from = p.floor();
      final to = p.ceil().clamp(0, lists.length);
      underline = Rect.lerp(_tabRects[from], _tabRects[to], p - from);
    }

    // The parent Column centers its children; a short tab row would be
    // centered too, so pin it to the left edge.
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Stack(
          key: _stackKey,
          children: [
            Row(
              children: [
                _Tab(
                  measureKey: _keyFor(0),
                  semanticLabel: 'Starred',
                  icon: Icons.star_border,
                  active: activeTab is StarredTab,
                  highlight: highlight(0),
                  onTap: () => widget.onSelected(const StarredTab()),
                ),
                for (final (i, list) in lists.indexed) ...[
                  const SizedBox(width: 24),
                  _Tab(
                    measureKey: _keyFor(i + 1),
                    semanticLabel: list.name,
                    icon: iconForList(list.icon),
                    label: list.name,
                    active: activeTab == ListTab(list.id),
                    highlight: highlight(i + 1),
                    onTap: () => widget.onSelected(ListTab(list.id)),
                  ),
                ],
                if (onAddList != null) ...[
                  const SizedBox(width: 24),
                  _Tab(
                    semanticLabel: 'Add list',
                    icon: Icons.add,
                    // Never the active tab itself - it opens a sheet, not a view.
                    active: false,
                    highlight: 0,
                    onTap: onAddList,
                  ),
                ],
              ],
            ),
            if (underline != null)
              Positioned.fromRect(
                rect: Rect.fromLTRB(
                  underline.left,
                  underline.bottom - _underlineHeight,
                  underline.right,
                  underline.bottom,
                ),
                child: ColoredBox(color: Theme.of(context).colorScheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}

const double _underlineHeight = 2;

class _Tab extends StatelessWidget {
  const _Tab({
    required this.semanticLabel,
    required this.icon,
    required this.active,
    required this.highlight,
    required this.onTap,
    this.label,
    this.measureKey,
  });

  final String semanticLabel;
  final IconData icon;
  final String? label;

  /// The settled active tab, for accessibility.
  final bool active;

  /// How far along the tint is, 0 (muted) to 1 (primary). Follows a drag, so
  /// it can sit anywhere in between.
  final double highlight;

  final VoidCallback onTap;

  /// On the part the shared underline spans, so the bar can measure it.
  final GlobalKey? measureKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).extension<AppColors>()!.mutedForeground;
    final body = Theme.of(context).textTheme.bodyMedium!;
    final color = Color.lerp(muted, scheme.primary, highlight)!;

    return Semantics(
      button: true,
      selected: active,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        // The drawn bar has 24 above and 16 below the tabs; that space is part
        // of the hit area so the tab is not a thin target.
        child: Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          child: Container(
            key: measureKey,
            // Room for the bar's shared underline, drawn across this padding.
            padding: const EdgeInsets.only(bottom: 10 + _underlineHeight),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: body.copyWith(
                      fontSize: 14,
                      fontWeight: highlight > 0.5 ? FontWeight.w600 : FontWeight.w400,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
