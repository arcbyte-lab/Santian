import 'package:isar_community/isar.dart';

part 'repeat.g.dart';

@embedded
class Repeat {
  @enumerated
  late RepeatFrequency frequency;

  /// Custom only; 1 otherwise.
  int interval = 1;

  /// Custom only, null otherwise. Nullable enums need `ordinal32`; the
  /// default byte storage cannot represent null.
  @Enumerated(EnumType.ordinal32)
  RepeatUnit? unit;

  /// ISO 8601 weekday numbers (1 = Monday ... 7 = Sunday). Used only when
  /// frequency is weekly, or custom with unit weeks.
  List<int> weekdays = [];
}

// Both enums are stored by ordinal position. Only append new members at the
// end; inserting or reordering silently changes what existing data means.
enum RepeatFrequency { daily, weekly, monthly, yearly, custom }

enum RepeatUnit { days, weeks, months, years }
