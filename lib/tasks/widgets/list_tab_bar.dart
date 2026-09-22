import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../cubits/tasks_list_state.dart';
import '../models/task_list.dart';
import 'list_icon.dart';

/// The horizontally scrolling row of tabs above the Tasks List: Star first,
/// then one tab per List. Exactly one tab is active.
class ListTabBar extends StatelessWidget {
  const ListTabBar({
    super.key,
    required this.lists,
    required this.activeTab,
    required this.onSelected,
    this.onAddList,
  });

  final List<TaskList> lists;
  final TasksTab? activeTab;
  final ValueChanged<TasksTab> onSelected;

  /// Called when the trailing `+` tab is tapped. Null hides it - there is no
  /// List Repository to create into yet (shouldn't happen outside a test
  /// harness missing one, since [ListRepository.createDefault] means a real
  /// app is never without at least one List).
  final VoidCallback? onAddList;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          _Tab(
            semanticLabel: 'Starred',
            icon: Icons.star_border,
            active: activeTab is StarredTab,
            onTap: () => onSelected(const StarredTab()),
          ),
          for (final list in lists) ...[
            const SizedBox(width: 24),
            _Tab(
              semanticLabel: list.name,
              icon: iconForList(list.icon),
              label: list.name,
              active: activeTab == ListTab(list.id),
              onTap: () => onSelected(ListTab(list.id)),
            ),
          ],
          if (onAddList != null) ...[
            const SizedBox(width: 24),
            _Tab(
              semanticLabel: 'Add list',
              icon: Icons.add,
              // Never the active tab itself - it opens a sheet, not a view.
              active: false,
              onTap: onAddList!,
            ),
          ],
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.semanticLabel,
    required this.icon,
    required this.active,
    required this.onTap,
    this.label,
  });

  final String semanticLabel;
  final IconData icon;
  final String? label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).extension<AppColors>()!.mutedForeground;
    final body = Theme.of(context).textTheme.bodyMedium!;

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
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? scheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: active ? scheme.primary : muted),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: body.copyWith(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? scheme.onSurface : muted,
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
