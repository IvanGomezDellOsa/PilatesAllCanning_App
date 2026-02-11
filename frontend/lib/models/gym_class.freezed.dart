// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gym_class.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GymClass _$GymClassFromJson(Map<String, dynamic> json) {
  return _GymClass.fromJson(json);
}

/// @nodoc
mixin _$GymClass {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get instructor => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_time')
  DateTime get startTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_minutes')
  int get durationMinutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_slots')
  int get maxSlots =>
      throw _privateConstructorUsedError; // Campos opcionales o con default para compatibilidad con create response
  @JsonKey(name: 'confirmed_count')
  int get confirmedCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'my_status')
  bool get isBookedByMe =>
      throw _privateConstructorUsedError; // Campos nuevos del Backend
  bool get recurrence => throw _privateConstructorUsedError;
  @JsonKey(name: 'recurrence_group')
  String? get recurrenceGroup =>
      throw _privateConstructorUsedError; // Puede ser null
  @JsonKey(name: 'cancelled_at')
  DateTime? get cancelledAt => throw _privateConstructorUsedError;

  /// Serializes this GymClass to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GymClass
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GymClassCopyWith<GymClass> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GymClassCopyWith<$Res> {
  factory $GymClassCopyWith(GymClass value, $Res Function(GymClass) then) =
      _$GymClassCopyWithImpl<$Res, GymClass>;
  @useResult
  $Res call(
      {String id,
      String name,
      String instructor,
      @JsonKey(name: 'start_time') DateTime startTime,
      @JsonKey(name: 'duration_minutes') int durationMinutes,
      @JsonKey(name: 'max_slots') int maxSlots,
      @JsonKey(name: 'confirmed_count') int confirmedCount,
      @JsonKey(name: 'my_status') bool isBookedByMe,
      bool recurrence,
      @JsonKey(name: 'recurrence_group') String? recurrenceGroup,
      @JsonKey(name: 'cancelled_at') DateTime? cancelledAt});
}

/// @nodoc
class _$GymClassCopyWithImpl<$Res, $Val extends GymClass>
    implements $GymClassCopyWith<$Res> {
  _$GymClassCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GymClass
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? instructor = null,
    Object? startTime = null,
    Object? durationMinutes = null,
    Object? maxSlots = null,
    Object? confirmedCount = null,
    Object? isBookedByMe = null,
    Object? recurrence = null,
    Object? recurrenceGroup = freezed,
    Object? cancelledAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      instructor: null == instructor
          ? _value.instructor
          : instructor // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      maxSlots: null == maxSlots
          ? _value.maxSlots
          : maxSlots // ignore: cast_nullable_to_non_nullable
              as int,
      confirmedCount: null == confirmedCount
          ? _value.confirmedCount
          : confirmedCount // ignore: cast_nullable_to_non_nullable
              as int,
      isBookedByMe: null == isBookedByMe
          ? _value.isBookedByMe
          : isBookedByMe // ignore: cast_nullable_to_non_nullable
              as bool,
      recurrence: null == recurrence
          ? _value.recurrence
          : recurrence // ignore: cast_nullable_to_non_nullable
              as bool,
      recurrenceGroup: freezed == recurrenceGroup
          ? _value.recurrenceGroup
          : recurrenceGroup // ignore: cast_nullable_to_non_nullable
              as String?,
      cancelledAt: freezed == cancelledAt
          ? _value.cancelledAt
          : cancelledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GymClassImplCopyWith<$Res>
    implements $GymClassCopyWith<$Res> {
  factory _$$GymClassImplCopyWith(
          _$GymClassImpl value, $Res Function(_$GymClassImpl) then) =
      __$$GymClassImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String instructor,
      @JsonKey(name: 'start_time') DateTime startTime,
      @JsonKey(name: 'duration_minutes') int durationMinutes,
      @JsonKey(name: 'max_slots') int maxSlots,
      @JsonKey(name: 'confirmed_count') int confirmedCount,
      @JsonKey(name: 'my_status') bool isBookedByMe,
      bool recurrence,
      @JsonKey(name: 'recurrence_group') String? recurrenceGroup,
      @JsonKey(name: 'cancelled_at') DateTime? cancelledAt});
}

/// @nodoc
class __$$GymClassImplCopyWithImpl<$Res>
    extends _$GymClassCopyWithImpl<$Res, _$GymClassImpl>
    implements _$$GymClassImplCopyWith<$Res> {
  __$$GymClassImplCopyWithImpl(
      _$GymClassImpl _value, $Res Function(_$GymClassImpl) _then)
      : super(_value, _then);

  /// Create a copy of GymClass
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? instructor = null,
    Object? startTime = null,
    Object? durationMinutes = null,
    Object? maxSlots = null,
    Object? confirmedCount = null,
    Object? isBookedByMe = null,
    Object? recurrence = null,
    Object? recurrenceGroup = freezed,
    Object? cancelledAt = freezed,
  }) {
    return _then(_$GymClassImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      instructor: null == instructor
          ? _value.instructor
          : instructor // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      maxSlots: null == maxSlots
          ? _value.maxSlots
          : maxSlots // ignore: cast_nullable_to_non_nullable
              as int,
      confirmedCount: null == confirmedCount
          ? _value.confirmedCount
          : confirmedCount // ignore: cast_nullable_to_non_nullable
              as int,
      isBookedByMe: null == isBookedByMe
          ? _value.isBookedByMe
          : isBookedByMe // ignore: cast_nullable_to_non_nullable
              as bool,
      recurrence: null == recurrence
          ? _value.recurrence
          : recurrence // ignore: cast_nullable_to_non_nullable
              as bool,
      recurrenceGroup: freezed == recurrenceGroup
          ? _value.recurrenceGroup
          : recurrenceGroup // ignore: cast_nullable_to_non_nullable
              as String?,
      cancelledAt: freezed == cancelledAt
          ? _value.cancelledAt
          : cancelledAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GymClassImpl extends _GymClass {
  const _$GymClassImpl(
      {required this.id,
      required this.name,
      required this.instructor,
      @JsonKey(name: 'start_time') required this.startTime,
      @JsonKey(name: 'duration_minutes') this.durationMinutes = 60,
      @JsonKey(name: 'max_slots') this.maxSlots = 8,
      @JsonKey(name: 'confirmed_count') this.confirmedCount = 0,
      @JsonKey(name: 'my_status') this.isBookedByMe = false,
      this.recurrence = false,
      @JsonKey(name: 'recurrence_group') this.recurrenceGroup,
      @JsonKey(name: 'cancelled_at') this.cancelledAt})
      : super._();

  factory _$GymClassImpl.fromJson(Map<String, dynamic> json) =>
      _$$GymClassImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String instructor;
  @override
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  @override
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @override
  @JsonKey(name: 'max_slots')
  final int maxSlots;
// Campos opcionales o con default para compatibilidad con create response
  @override
  @JsonKey(name: 'confirmed_count')
  final int confirmedCount;
  @override
  @JsonKey(name: 'my_status')
  final bool isBookedByMe;
// Campos nuevos del Backend
  @override
  @JsonKey()
  final bool recurrence;
  @override
  @JsonKey(name: 'recurrence_group')
  final String? recurrenceGroup;
// Puede ser null
  @override
  @JsonKey(name: 'cancelled_at')
  final DateTime? cancelledAt;

  @override
  String toString() {
    return 'GymClass(id: $id, name: $name, instructor: $instructor, startTime: $startTime, durationMinutes: $durationMinutes, maxSlots: $maxSlots, confirmedCount: $confirmedCount, isBookedByMe: $isBookedByMe, recurrence: $recurrence, recurrenceGroup: $recurrenceGroup, cancelledAt: $cancelledAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GymClassImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.instructor, instructor) ||
                other.instructor == instructor) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.maxSlots, maxSlots) ||
                other.maxSlots == maxSlots) &&
            (identical(other.confirmedCount, confirmedCount) ||
                other.confirmedCount == confirmedCount) &&
            (identical(other.isBookedByMe, isBookedByMe) ||
                other.isBookedByMe == isBookedByMe) &&
            (identical(other.recurrence, recurrence) ||
                other.recurrence == recurrence) &&
            (identical(other.recurrenceGroup, recurrenceGroup) ||
                other.recurrenceGroup == recurrenceGroup) &&
            (identical(other.cancelledAt, cancelledAt) ||
                other.cancelledAt == cancelledAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      instructor,
      startTime,
      durationMinutes,
      maxSlots,
      confirmedCount,
      isBookedByMe,
      recurrence,
      recurrenceGroup,
      cancelledAt);

  /// Create a copy of GymClass
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GymClassImplCopyWith<_$GymClassImpl> get copyWith =>
      __$$GymClassImplCopyWithImpl<_$GymClassImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GymClassImplToJson(
      this,
    );
  }
}

abstract class _GymClass extends GymClass {
  const factory _GymClass(
          {required final String id,
          required final String name,
          required final String instructor,
          @JsonKey(name: 'start_time') required final DateTime startTime,
          @JsonKey(name: 'duration_minutes') final int durationMinutes,
          @JsonKey(name: 'max_slots') final int maxSlots,
          @JsonKey(name: 'confirmed_count') final int confirmedCount,
          @JsonKey(name: 'my_status') final bool isBookedByMe,
          final bool recurrence,
          @JsonKey(name: 'recurrence_group') final String? recurrenceGroup,
          @JsonKey(name: 'cancelled_at') final DateTime? cancelledAt}) =
      _$GymClassImpl;
  const _GymClass._() : super._();

  factory _GymClass.fromJson(Map<String, dynamic> json) =
      _$GymClassImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get instructor;
  @override
  @JsonKey(name: 'start_time')
  DateTime get startTime;
  @override
  @JsonKey(name: 'duration_minutes')
  int get durationMinutes;
  @override
  @JsonKey(name: 'max_slots')
  int get maxSlots; // Campos opcionales o con default para compatibilidad con create response
  @override
  @JsonKey(name: 'confirmed_count')
  int get confirmedCount;
  @override
  @JsonKey(name: 'my_status')
  bool get isBookedByMe; // Campos nuevos del Backend
  @override
  bool get recurrence;
  @override
  @JsonKey(name: 'recurrence_group')
  String? get recurrenceGroup; // Puede ser null
  @override
  @JsonKey(name: 'cancelled_at')
  DateTime? get cancelledAt;

  /// Create a copy of GymClass
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GymClassImplCopyWith<_$GymClassImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GymClassDetail _$GymClassDetailFromJson(Map<String, dynamic> json) {
  return _GymClassDetail.fromJson(json);
}

/// @nodoc
mixin _$GymClassDetail {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get instructor => throw _privateConstructorUsedError;
  @JsonKey(name: 'start_time')
  DateTime get startTime => throw _privateConstructorUsedError;
  @JsonKey(name: 'duration_minutes')
  int get durationMinutes => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_slots')
  int get maxSlots => throw _privateConstructorUsedError;
  @JsonKey(name: 'confirmed_count')
  int get confirmedCount => throw _privateConstructorUsedError;
  List<Booking> get bookings => throw _privateConstructorUsedError;

  /// Serializes this GymClassDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GymClassDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GymClassDetailCopyWith<GymClassDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GymClassDetailCopyWith<$Res> {
  factory $GymClassDetailCopyWith(
          GymClassDetail value, $Res Function(GymClassDetail) then) =
      _$GymClassDetailCopyWithImpl<$Res, GymClassDetail>;
  @useResult
  $Res call(
      {String id,
      String name,
      String instructor,
      @JsonKey(name: 'start_time') DateTime startTime,
      @JsonKey(name: 'duration_minutes') int durationMinutes,
      @JsonKey(name: 'max_slots') int maxSlots,
      @JsonKey(name: 'confirmed_count') int confirmedCount,
      List<Booking> bookings});
}

/// @nodoc
class _$GymClassDetailCopyWithImpl<$Res, $Val extends GymClassDetail>
    implements $GymClassDetailCopyWith<$Res> {
  _$GymClassDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GymClassDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? instructor = null,
    Object? startTime = null,
    Object? durationMinutes = null,
    Object? maxSlots = null,
    Object? confirmedCount = null,
    Object? bookings = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      instructor: null == instructor
          ? _value.instructor
          : instructor // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      maxSlots: null == maxSlots
          ? _value.maxSlots
          : maxSlots // ignore: cast_nullable_to_non_nullable
              as int,
      confirmedCount: null == confirmedCount
          ? _value.confirmedCount
          : confirmedCount // ignore: cast_nullable_to_non_nullable
              as int,
      bookings: null == bookings
          ? _value.bookings
          : bookings // ignore: cast_nullable_to_non_nullable
              as List<Booking>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GymClassDetailImplCopyWith<$Res>
    implements $GymClassDetailCopyWith<$Res> {
  factory _$$GymClassDetailImplCopyWith(_$GymClassDetailImpl value,
          $Res Function(_$GymClassDetailImpl) then) =
      __$$GymClassDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String instructor,
      @JsonKey(name: 'start_time') DateTime startTime,
      @JsonKey(name: 'duration_minutes') int durationMinutes,
      @JsonKey(name: 'max_slots') int maxSlots,
      @JsonKey(name: 'confirmed_count') int confirmedCount,
      List<Booking> bookings});
}

/// @nodoc
class __$$GymClassDetailImplCopyWithImpl<$Res>
    extends _$GymClassDetailCopyWithImpl<$Res, _$GymClassDetailImpl>
    implements _$$GymClassDetailImplCopyWith<$Res> {
  __$$GymClassDetailImplCopyWithImpl(
      _$GymClassDetailImpl _value, $Res Function(_$GymClassDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of GymClassDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? instructor = null,
    Object? startTime = null,
    Object? durationMinutes = null,
    Object? maxSlots = null,
    Object? confirmedCount = null,
    Object? bookings = null,
  }) {
    return _then(_$GymClassDetailImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      instructor: null == instructor
          ? _value.instructor
          : instructor // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      maxSlots: null == maxSlots
          ? _value.maxSlots
          : maxSlots // ignore: cast_nullable_to_non_nullable
              as int,
      confirmedCount: null == confirmedCount
          ? _value.confirmedCount
          : confirmedCount // ignore: cast_nullable_to_non_nullable
              as int,
      bookings: null == bookings
          ? _value._bookings
          : bookings // ignore: cast_nullable_to_non_nullable
              as List<Booking>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GymClassDetailImpl implements _GymClassDetail {
  const _$GymClassDetailImpl(
      {required this.id,
      required this.name,
      required this.instructor,
      @JsonKey(name: 'start_time') required this.startTime,
      @JsonKey(name: 'duration_minutes') required this.durationMinutes,
      @JsonKey(name: 'max_slots') required this.maxSlots,
      @JsonKey(name: 'confirmed_count') this.confirmedCount = 0,
      required final List<Booking> bookings})
      : _bookings = bookings;

  factory _$GymClassDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$GymClassDetailImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String instructor;
  @override
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  @override
  @JsonKey(name: 'duration_minutes')
  final int durationMinutes;
  @override
  @JsonKey(name: 'max_slots')
  final int maxSlots;
  @override
  @JsonKey(name: 'confirmed_count')
  final int confirmedCount;
  final List<Booking> _bookings;
  @override
  List<Booking> get bookings {
    if (_bookings is EqualUnmodifiableListView) return _bookings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookings);
  }

  @override
  String toString() {
    return 'GymClassDetail(id: $id, name: $name, instructor: $instructor, startTime: $startTime, durationMinutes: $durationMinutes, maxSlots: $maxSlots, confirmedCount: $confirmedCount, bookings: $bookings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GymClassDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.instructor, instructor) ||
                other.instructor == instructor) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.maxSlots, maxSlots) ||
                other.maxSlots == maxSlots) &&
            (identical(other.confirmedCount, confirmedCount) ||
                other.confirmedCount == confirmedCount) &&
            const DeepCollectionEquality().equals(other._bookings, _bookings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      instructor,
      startTime,
      durationMinutes,
      maxSlots,
      confirmedCount,
      const DeepCollectionEquality().hash(_bookings));

  /// Create a copy of GymClassDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GymClassDetailImplCopyWith<_$GymClassDetailImpl> get copyWith =>
      __$$GymClassDetailImplCopyWithImpl<_$GymClassDetailImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GymClassDetailImplToJson(
      this,
    );
  }
}

abstract class _GymClassDetail implements GymClassDetail {
  const factory _GymClassDetail(
      {required final String id,
      required final String name,
      required final String instructor,
      @JsonKey(name: 'start_time') required final DateTime startTime,
      @JsonKey(name: 'duration_minutes') required final int durationMinutes,
      @JsonKey(name: 'max_slots') required final int maxSlots,
      @JsonKey(name: 'confirmed_count') final int confirmedCount,
      required final List<Booking> bookings}) = _$GymClassDetailImpl;

  factory _GymClassDetail.fromJson(Map<String, dynamic> json) =
      _$GymClassDetailImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get instructor;
  @override
  @JsonKey(name: 'start_time')
  DateTime get startTime;
  @override
  @JsonKey(name: 'duration_minutes')
  int get durationMinutes;
  @override
  @JsonKey(name: 'max_slots')
  int get maxSlots;
  @override
  @JsonKey(name: 'confirmed_count')
  int get confirmedCount;
  @override
  List<Booking> get bookings;

  /// Create a copy of GymClassDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GymClassDetailImplCopyWith<_$GymClassDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
