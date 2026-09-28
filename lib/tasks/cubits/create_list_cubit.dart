import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/task_list.dart';
import '../repository/list_repository.dart';

class CreateListState {
  const CreateListState({this.name = ''});

  final String name;

  bool get canSubmit => name.trim().isNotEmpty;
}

/// State for one open Create List sheet: its name. Mirrors
/// CreateTaskCubit's shape (title-only state, one `submit`, guarded against
/// a second List from the same sheet).
class CreateListCubit extends Cubit<CreateListState> {
  CreateListCubit({required ListRepository lists})
    : _lists = lists,
      super(const CreateListState());

  final ListRepository _lists;
  var _submitted = false;

  void setName(String name) => emit(CreateListState(name: name));

  /// Creates the List and returns its id. Returns null, doing nothing, when
  /// the name is blank (the sheet stays open, with no error) or when a List
  /// was already created from this sheet.
  Future<int?> submit() async {
    if (!state.canSubmit || _submitted) return null;
    _submitted = true;
    try {
      return await _lists.create(TaskList()..name = state.name.trim());
    } catch (_) {
      _submitted = false; // a failed save must not lock the sheet
      rethrow;
    }
  }
}
