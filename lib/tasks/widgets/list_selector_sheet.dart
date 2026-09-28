import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../models/task_list.dart';

/// Opens the List Selector's own dedicated bottom sheet, listing every List
/// so a Task's `listId` can be reassigned. Not a reuse of the List Tab Bar's
/// row — a new sheet instance of the pattern, per the spec.
Future<TaskList?> showListSelectorSheet(
  BuildContext context, {
  required List<TaskList> lists,
  required int? currentListId,
}) {
  return showModalBottomSheet<TaskList>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: const Color(0x40000000),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (_) =>
        ListSelectorSheet(lists: lists, currentListId: currentListId),
  );
}

class ListSelectorSheet extends StatelessWidget {
  const ListSelectorSheet({
    super.key,
    required this.lists,
    required this.currentListId,
  });

  final List<TaskList> lists;
  final int? currentListId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final list in lists)
              ListTile(
                title: Text(list.name),
                selected: list.id == currentListId,
                onTap: () => Navigator.of(context).pop(list),
              ),
          ],
        ),
      ),
    );
  }
}
