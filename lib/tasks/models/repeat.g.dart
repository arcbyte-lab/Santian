// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repeat.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const RepeatSchema = Schema(
  name: r'Repeat',
  id: -6476019677630450765,
  properties: {
    r'frequency': PropertySchema(
      id: 0,
      name: r'frequency',
      type: IsarType.byte,
      enumMap: _RepeatfrequencyEnumValueMap,
    ),
    r'interval': PropertySchema(id: 1, name: r'interval', type: IsarType.long),
    r'unit': PropertySchema(
      id: 2,
      name: r'unit',
      type: IsarType.int,
      enumMap: _RepeatunitEnumValueMap,
    ),
    r'weekdays': PropertySchema(
      id: 3,
      name: r'weekdays',
      type: IsarType.longList,
    ),
  },

  estimateSize: _repeatEstimateSize,
  serialize: _repeatSerialize,
  deserialize: _repeatDeserialize,
  deserializeProp: _repeatDeserializeProp,
);

int _repeatEstimateSize(
  Repeat object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.weekdays.length * 8;
  return bytesCount;
}

void _repeatSerialize(
  Repeat object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeByte(offsets[0], object.frequency.index);
  writer.writeLong(offsets[1], object.interval);
  writer.writeInt(offsets[2], object.unit?.index);
  writer.writeLongList(offsets[3], object.weekdays);
}

Repeat _repeatDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Repeat();
  object.frequency =
      _RepeatfrequencyValueEnumMap[reader.readByteOrNull(offsets[0])] ??
      RepeatFrequency.daily;
  object.interval = reader.readLong(offsets[1]);
  object.unit = _RepeatunitValueEnumMap[reader.readIntOrNull(offsets[2])];
  object.weekdays = reader.readLongList(offsets[3]) ?? [];
  return object;
}

P _repeatDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_RepeatfrequencyValueEnumMap[reader.readByteOrNull(offset)] ??
              RepeatFrequency.daily)
          as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (_RepeatunitValueEnumMap[reader.readIntOrNull(offset)]) as P;
    case 3:
      return (reader.readLongList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RepeatfrequencyEnumValueMap = {
  'daily': 0,
  'weekly': 1,
  'monthly': 2,
  'yearly': 3,
  'custom': 4,
};
const _RepeatfrequencyValueEnumMap = {
  0: RepeatFrequency.daily,
  1: RepeatFrequency.weekly,
  2: RepeatFrequency.monthly,
  3: RepeatFrequency.yearly,
  4: RepeatFrequency.custom,
};
const _RepeatunitEnumValueMap = {
  'days': 0,
  'weeks': 1,
  'months': 2,
  'years': 3,
};
const _RepeatunitValueEnumMap = {
  0: RepeatUnit.days,
  1: RepeatUnit.weeks,
  2: RepeatUnit.months,
  3: RepeatUnit.years,
};

extension RepeatQueryFilter on QueryBuilder<Repeat, Repeat, QFilterCondition> {
  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> frequencyEqualTo(
    RepeatFrequency value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'frequency', value: value),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> frequencyGreaterThan(
    RepeatFrequency value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'frequency',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> frequencyLessThan(
    RepeatFrequency value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'frequency',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> frequencyBetween(
    RepeatFrequency lower,
    RepeatFrequency upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'frequency',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> intervalEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'interval', value: value),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> intervalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'interval',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> intervalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'interval',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> intervalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'interval',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> unitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'unit'),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> unitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'unit'),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> unitEqualTo(
    RepeatUnit? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'unit', value: value),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> unitGreaterThan(
    RepeatUnit? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'unit',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> unitLessThan(
    RepeatUnit? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'unit',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> unitBetween(
    RepeatUnit? lower,
    RepeatUnit? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'unit',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> weekdaysElementEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'weekdays', value: value),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition>
  weekdaysElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'weekdays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> weekdaysElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'weekdays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> weekdaysElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'weekdays',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> weekdaysLengthEqualTo(
    int length,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'weekdays', length, true, length, true);
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> weekdaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'weekdays', 0, true, 0, true);
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> weekdaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'weekdays', 0, false, 999999, true);
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> weekdaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'weekdays', 0, true, length, include);
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> weekdaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'weekdays', length, include, 999999, true);
    });
  }

  QueryBuilder<Repeat, Repeat, QAfterFilterCondition> weekdaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weekdays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension RepeatQueryObject on QueryBuilder<Repeat, Repeat, QFilterCondition> {}
