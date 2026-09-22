import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../cubits/create_list_cubit.dart';
import '../widgets/list_color.dart';
import '../widgets/list_icon.dart';

/// The contents of the Create List sheet as a function of [state]: name
/// (keyboard focused on open), an icon grid, and a color row. Mirrors
/// CreateTaskForm's shape - it owns only the name controller; everything
/// else comes from [state] and the callbacks.
class CreateListForm extends StatefulWidget {
  const CreateListForm({
    super.key,
    required this.state,
    required this.onNameChanged,
    required this.onIconChanged,
    required this.onColorChanged,
    required this.onSubmit,
  });

  final CreateListState state;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onIconChanged;
  final ValueChanged<int> onColorChanged;

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
    final state = widget.state;

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
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in listIconOptions)
              _IconChoice(
                iconKey: option.key,
                icon: option.icon,
                selected: option.key == state.icon,
                onTap: () => widget.onIconChanged(option.key),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final option in listColorOptions)
              _ColorChoice(
                option: option,
                selected: option.value == state.color,
                onTap: () => widget.onColorChanged(option.value),
              ),
          ],
        ),
      ],
    );
  }
}

/// One tile in the icon grid: a circular tap target, tinted like Create
/// Task's own action icons when active (primary fill at 10% plus a primary
/// icon), muted otherwise. [iconKey] (e.g. "book-open") is only for the
/// semantics label - a screen reader user has no other way to tell which
/// icon a plain glyph is.
class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.iconKey,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.extension<AppColors>()!.mutedForeground;

    return Semantics(
      button: true,
      selected: selected,
      label: '${iconKey.replaceAll('-', ' ')} icon',
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? scheme.primary.withValues(alpha: 0.1) : null,
          ),
          child: Icon(icon, size: 20, color: selected ? scheme.primary : muted),
        ),
      ),
    );
  }
}

/// One dot in the color row: the option's own fill, with a ring plus a
/// checkmark once selected - a plain fill alone wouldn't read as "selected"
/// against its own color the way the icon grid's tint does against neutral.
class _ColorChoice extends StatelessWidget {
  const _ColorChoice({required this.option, required this.selected, required this.onTap});

  final ListColorOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = Color(option.value);

    return Semantics(
      button: true,
      selected: selected,
      label: '${option.name} color',
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: selected ? Border.all(color: scheme.onSurface, width: 2) : null,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
            child: selected
                ? Icon(Icons.check, size: 16, color: fill.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}
