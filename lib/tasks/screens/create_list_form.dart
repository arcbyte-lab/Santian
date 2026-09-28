import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The contents of the Create List sheet: just the name (keyboard focused on
/// open).
class CreateListForm extends StatefulWidget {
  const CreateListForm({
    super.key,
    required this.onNameChanged,
    required this.onSubmit,
  });

  final ValueChanged<String> onNameChanged;

  /// Keyboard Enter or Done in the name field.
  final VoidCallback onSubmit;

  @override
  State<CreateListForm> createState() => _CreateListFormState();
}

class _CreateListFormState extends State<CreateListForm> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.extension<AppColors>()!.mutedForeground;
    final hint = muted.withValues(alpha: 0.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: hint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        TextField(
          controller: _name,
          autofocus: true,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          onChanged: widget.onNameChanged,
          // Providing this keeps the keyboard open when the name is empty;
          // Done on a blank name is a no-op, not a dismissal - same rule as
          // Create Task's own title field.
          onEditingComplete: widget.onSubmit,
          style: theme.textTheme.bodyMedium!.copyWith(
            fontFamily: 'DMSans',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: scheme.onSurface,
          ),
          decoration: InputDecoration.collapsed(
            hintText: 'List name',
            hintStyle: theme.textTheme.bodyMedium!.copyWith(
              fontFamily: 'DMSans',
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: hint,
            ),
          ),
        ),
      ],
    );
  }
}
