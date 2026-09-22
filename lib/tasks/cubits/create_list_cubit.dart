import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task_list.dart';
import '../repository/list_repository.dart';
import '../widgets/list_color.dart';
import '../widgets/list_icon.dart';

class CreateListState {
  const CreateListState({
    this.name = '',
    this.icon = _defaultIcon,
    this.color = _defaultColorValue,
  });

  final String name;

  /// A key from [listIconOptions] - always one of them, never free text.
  final String icon;

  /// An ARGB int from [listColorOptions] - `TaskList.color`'s own storage type.
  final int color;

  bool get canSubmit => name.trim().isNotEmpty;

  CreateListState copyWith({String? name, String? icon, int? color}) => CreateListState(
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
      );
}

// Redeclared as literals, matching listIconOptions[0].key/listColorOptions[0]
// .value: `.first` on those consts isn't itself a const expression, so the
// default can't just reference them directly. See list_icon.dart/
// list_color.dart for what these mean.
const _defaultIcon = 'rocket';
const _defaultColorValue = 0xFF0284C7;

/// State for one open Create List sheet: name, icon, color. Mirrors
/// CreateTaskCubit's shape (title-only state, one `submit`, guarded against
/// a second List from the same sheet).
class CreateListCubit extends Cubit<CreateListState> {
  CreateListCubit({required ListRepository lists})
      : _lists = lists,
        super(const CreateListState());

  final ListRepository _lists;
  var _submitted = false;

  void setName(String name) => emit(state.copyWith(name: name));

  void setIcon(String icon) => emit(state.copyWith(icon: icon));

  void setColor(int color) => emit(state.copyWith(color: color));

  /// Creates the List and returns its id. Returns null, doing nothing, when
  /// the name is blank (the sheet stays open, with no error) or when a List
  /// was already created from this sheet.
  Future<int?> submit() async {
    if (!state.canSubmit || _submitted) return null;
    _submitted = true;
    try {
      return await _lists.create(TaskList()
        ..name = state.name.trim()
        ..icon = state.icon
        ..color = state.color);
    } catch (_) {
      _submitted = false; // a failed save must not lock the sheet
      rethrow;
    }
  }
}
