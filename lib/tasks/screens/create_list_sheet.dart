import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_radius.dart';
import '../cubits/create_list_cubit.dart';
import '../repository/list_repository.dart';
import 'create_list_form.dart';

/// Opens the Create List sheet, already risen, with the keyboard on the
/// name. Returns the new List's id, so the caller can select its tab - "the
/// new tab is inserted before + and selected" - or null if the sheet was
/// dismissed without creating one. Needs a [ListRepository] above [context].
Future<int?> showCreateListSheet(BuildContext context) {
  final lists = context.read<ListRepository>();
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: const Color(0x40000000),
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (_) => BlocProvider(
      create: (_) => CreateListCubit(lists: lists),
      child: const CreateListSheet(),
    ),
  );
}

/// Wires [CreateListForm] to the [CreateListCubit] above it, and closes the
/// sheet - with the new List's id as the result - once one has been created.
class CreateListSheet extends StatelessWidget {
  const CreateListSheet({super.key});

  Future<void> _submit(BuildContext context) async {
    final id = await context.read<CreateListCubit>().submit();
    if (id != null && context.mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateListCubit, CreateListState>(
      builder: (context, state) {
        final cubit = context.read<CreateListCubit>();
        return Padding(
          // Lift the sheet above the keyboard.
          padding: EdgeInsets.fromLTRB(
            28,
            16,
            28,
            28 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: CreateListForm(
            state: state,
            onNameChanged: cubit.setName,
            onIconChanged: cubit.setIcon,
            onColorChanged: cubit.setColor,
            onSubmit: () => _submit(context),
          ),
        );
      },
    );
  }
}
