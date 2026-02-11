// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  String get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'full_name')
  String? get fullName => throw _privateConstructorUsedError;
  String? get dni => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'credits_available')
  int get creditsAvailable => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_admin')
  bool get isAdmin => throw _privateConstructorUsedError;
  bool get disabled => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_trial')
  bool get isTrial => throw _privateConstructorUsedError;
  @JsonKey(name: 'medical_certificate_url')
  String? get medicalCertificateUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_given_feedback')
  bool get hasGivenFeedback => throw _privateConstructorUsedError;
  @JsonKey(name: 'feedback_sentiment')
  String? get feedbackSentiment => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_instructor')
  bool get isInstructor => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'full_name') String? fullName,
      String? dni,
      String? phone,
      @JsonKey(name: 'credits_available') int creditsAvailable,
      @JsonKey(name: 'is_admin') bool isAdmin,
      bool disabled,
      @JsonKey(name: 'is_trial') bool isTrial,
      @JsonKey(name: 'medical_certificate_url') String? medicalCertificateUrl,
      @JsonKey(name: 'has_given_feedback') bool hasGivenFeedback,
      @JsonKey(name: 'feedback_sentiment') String? feedbackSentiment,
      @JsonKey(name: 'is_instructor') bool isInstructor});
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = freezed,
    Object? dni = freezed,
    Object? phone = freezed,
    Object? creditsAvailable = null,
    Object? isAdmin = null,
    Object? disabled = null,
    Object? isTrial = null,
    Object? medicalCertificateUrl = freezed,
    Object? hasGivenFeedback = null,
    Object? feedbackSentiment = freezed,
    Object? isInstructor = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      dni: freezed == dni
          ? _value.dni
          : dni // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      creditsAvailable: null == creditsAvailable
          ? _value.creditsAvailable
          : creditsAvailable // ignore: cast_nullable_to_non_nullable
              as int,
      isAdmin: null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      disabled: null == disabled
          ? _value.disabled
          : disabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isTrial: null == isTrial
          ? _value.isTrial
          : isTrial // ignore: cast_nullable_to_non_nullable
              as bool,
      medicalCertificateUrl: freezed == medicalCertificateUrl
          ? _value.medicalCertificateUrl
          : medicalCertificateUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hasGivenFeedback: null == hasGivenFeedback
          ? _value.hasGivenFeedback
          : hasGivenFeedback // ignore: cast_nullable_to_non_nullable
              as bool,
      feedbackSentiment: freezed == feedbackSentiment
          ? _value.feedbackSentiment
          : feedbackSentiment // ignore: cast_nullable_to_non_nullable
              as String?,
      isInstructor: null == isInstructor
          ? _value.isInstructor
          : isInstructor // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
          _$UserImpl value, $Res Function(_$UserImpl) then) =
      __$$UserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'full_name') String? fullName,
      String? dni,
      String? phone,
      @JsonKey(name: 'credits_available') int creditsAvailable,
      @JsonKey(name: 'is_admin') bool isAdmin,
      bool disabled,
      @JsonKey(name: 'is_trial') bool isTrial,
      @JsonKey(name: 'medical_certificate_url') String? medicalCertificateUrl,
      @JsonKey(name: 'has_given_feedback') bool hasGivenFeedback,
      @JsonKey(name: 'feedback_sentiment') String? feedbackSentiment,
      @JsonKey(name: 'is_instructor') bool isInstructor});
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
      : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? fullName = freezed,
    Object? dni = freezed,
    Object? phone = freezed,
    Object? creditsAvailable = null,
    Object? isAdmin = null,
    Object? disabled = null,
    Object? isTrial = null,
    Object? medicalCertificateUrl = freezed,
    Object? hasGivenFeedback = null,
    Object? feedbackSentiment = freezed,
    Object? isInstructor = null,
  }) {
    return _then(_$UserImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      dni: freezed == dni
          ? _value.dni
          : dni // ignore: cast_nullable_to_non_nullable
              as String?,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      creditsAvailable: null == creditsAvailable
          ? _value.creditsAvailable
          : creditsAvailable // ignore: cast_nullable_to_non_nullable
              as int,
      isAdmin: null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      disabled: null == disabled
          ? _value.disabled
          : disabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isTrial: null == isTrial
          ? _value.isTrial
          : isTrial // ignore: cast_nullable_to_non_nullable
              as bool,
      medicalCertificateUrl: freezed == medicalCertificateUrl
          ? _value.medicalCertificateUrl
          : medicalCertificateUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hasGivenFeedback: null == hasGivenFeedback
          ? _value.hasGivenFeedback
          : hasGivenFeedback // ignore: cast_nullable_to_non_nullable
              as bool,
      feedbackSentiment: freezed == feedbackSentiment
          ? _value.feedbackSentiment
          : feedbackSentiment // ignore: cast_nullable_to_non_nullable
              as String?,
      isInstructor: null == isInstructor
          ? _value.isInstructor
          : isInstructor // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl(
      {required this.id,
      required this.email,
      @JsonKey(name: 'full_name') this.fullName,
      this.dni,
      this.phone,
      @JsonKey(name: 'credits_available') this.creditsAvailable = 0,
      @JsonKey(name: 'is_admin') this.isAdmin = false,
      this.disabled = false,
      @JsonKey(name: 'is_trial') this.isTrial = false,
      @JsonKey(name: 'medical_certificate_url') this.medicalCertificateUrl,
      @JsonKey(name: 'has_given_feedback') this.hasGivenFeedback = false,
      @JsonKey(name: 'feedback_sentiment') this.feedbackSentiment,
      @JsonKey(name: 'is_instructor') this.isInstructor = false});

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

  @override
  final String id;
  @override
  final String email;
  @override
  @JsonKey(name: 'full_name')
  final String? fullName;
  @override
  final String? dni;
  @override
  final String? phone;
  @override
  @JsonKey(name: 'credits_available')
  final int creditsAvailable;
  @override
  @JsonKey(name: 'is_admin')
  final bool isAdmin;
  @override
  @JsonKey()
  final bool disabled;
  @override
  @JsonKey(name: 'is_trial')
  final bool isTrial;
  @override
  @JsonKey(name: 'medical_certificate_url')
  final String? medicalCertificateUrl;
  @override
  @JsonKey(name: 'has_given_feedback')
  final bool hasGivenFeedback;
  @override
  @JsonKey(name: 'feedback_sentiment')
  final String? feedbackSentiment;
  @override
  @JsonKey(name: 'is_instructor')
  final bool isInstructor;

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, dni: $dni, phone: $phone, creditsAvailable: $creditsAvailable, isAdmin: $isAdmin, disabled: $disabled, isTrial: $isTrial, medicalCertificateUrl: $medicalCertificateUrl, hasGivenFeedback: $hasGivenFeedback, feedbackSentiment: $feedbackSentiment, isInstructor: $isInstructor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.dni, dni) || other.dni == dni) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.creditsAvailable, creditsAvailable) ||
                other.creditsAvailable == creditsAvailable) &&
            (identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin) &&
            (identical(other.disabled, disabled) ||
                other.disabled == disabled) &&
            (identical(other.isTrial, isTrial) || other.isTrial == isTrial) &&
            (identical(other.medicalCertificateUrl, medicalCertificateUrl) ||
                other.medicalCertificateUrl == medicalCertificateUrl) &&
            (identical(other.hasGivenFeedback, hasGivenFeedback) ||
                other.hasGivenFeedback == hasGivenFeedback) &&
            (identical(other.feedbackSentiment, feedbackSentiment) ||
                other.feedbackSentiment == feedbackSentiment) &&
            (identical(other.isInstructor, isInstructor) ||
                other.isInstructor == isInstructor));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      email,
      fullName,
      dni,
      phone,
      creditsAvailable,
      isAdmin,
      disabled,
      isTrial,
      medicalCertificateUrl,
      hasGivenFeedback,
      feedbackSentiment,
      isInstructor);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(
      this,
    );
  }
}

abstract class _User implements User {
  const factory _User(
      {required final String id,
      required final String email,
      @JsonKey(name: 'full_name') final String? fullName,
      final String? dni,
      final String? phone,
      @JsonKey(name: 'credits_available') final int creditsAvailable,
      @JsonKey(name: 'is_admin') final bool isAdmin,
      final bool disabled,
      @JsonKey(name: 'is_trial') final bool isTrial,
      @JsonKey(name: 'medical_certificate_url')
      final String? medicalCertificateUrl,
      @JsonKey(name: 'has_given_feedback') final bool hasGivenFeedback,
      @JsonKey(name: 'feedback_sentiment') final String? feedbackSentiment,
      @JsonKey(name: 'is_instructor') final bool isInstructor}) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

  @override
  String get id;
  @override
  String get email;
  @override
  @JsonKey(name: 'full_name')
  String? get fullName;
  @override
  String? get dni;
  @override
  String? get phone;
  @override
  @JsonKey(name: 'credits_available')
  int get creditsAvailable;
  @override
  @JsonKey(name: 'is_admin')
  bool get isAdmin;
  @override
  bool get disabled;
  @override
  @JsonKey(name: 'is_trial')
  bool get isTrial;
  @override
  @JsonKey(name: 'medical_certificate_url')
  String? get medicalCertificateUrl;
  @override
  @JsonKey(name: 'has_given_feedback')
  bool get hasGivenFeedback;
  @override
  @JsonKey(name: 'feedback_sentiment')
  String? get feedbackSentiment;
  @override
  @JsonKey(name: 'is_instructor')
  bool get isInstructor;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  @JsonKey(name: 'full_name')
  String? get fullName => throw _privateConstructorUsedError;
  String? get dni => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String? get phone => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_admin')
  bool get isAdmin => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_trial')
  bool get isTrial => throw _privateConstructorUsedError;
  @JsonKey(name: 'medical_certificate_url')
  String? get medicalCertificateUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_given_feedback')
  bool get hasGivenFeedback => throw _privateConstructorUsedError;
  @JsonKey(name: 'feedback_sentiment')
  String? get feedbackSentiment => throw _privateConstructorUsedError;
  @JsonKey(name: 'credits_available')
  int get creditsAvailable => throw _privateConstructorUsedError;

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {@JsonKey(name: 'full_name') String? fullName,
      String? dni,
      String email,
      String? phone,
      @JsonKey(name: 'is_admin') bool isAdmin,
      @JsonKey(name: 'is_trial') bool isTrial,
      @JsonKey(name: 'medical_certificate_url') String? medicalCertificateUrl,
      @JsonKey(name: 'has_given_feedback') bool hasGivenFeedback,
      @JsonKey(name: 'feedback_sentiment') String? feedbackSentiment,
      @JsonKey(name: 'credits_available') int creditsAvailable});
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fullName = freezed,
    Object? dni = freezed,
    Object? email = null,
    Object? phone = freezed,
    Object? isAdmin = null,
    Object? isTrial = null,
    Object? medicalCertificateUrl = freezed,
    Object? hasGivenFeedback = null,
    Object? feedbackSentiment = freezed,
    Object? creditsAvailable = null,
  }) {
    return _then(_value.copyWith(
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      dni: freezed == dni
          ? _value.dni
          : dni // ignore: cast_nullable_to_non_nullable
              as String?,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      isAdmin: null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      isTrial: null == isTrial
          ? _value.isTrial
          : isTrial // ignore: cast_nullable_to_non_nullable
              as bool,
      medicalCertificateUrl: freezed == medicalCertificateUrl
          ? _value.medicalCertificateUrl
          : medicalCertificateUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hasGivenFeedback: null == hasGivenFeedback
          ? _value.hasGivenFeedback
          : hasGivenFeedback // ignore: cast_nullable_to_non_nullable
              as bool,
      feedbackSentiment: freezed == feedbackSentiment
          ? _value.feedbackSentiment
          : feedbackSentiment // ignore: cast_nullable_to_non_nullable
              as String?,
      creditsAvailable: null == creditsAvailable
          ? _value.creditsAvailable
          : creditsAvailable // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'full_name') String? fullName,
      String? dni,
      String email,
      String? phone,
      @JsonKey(name: 'is_admin') bool isAdmin,
      @JsonKey(name: 'is_trial') bool isTrial,
      @JsonKey(name: 'medical_certificate_url') String? medicalCertificateUrl,
      @JsonKey(name: 'has_given_feedback') bool hasGivenFeedback,
      @JsonKey(name: 'feedback_sentiment') String? feedbackSentiment,
      @JsonKey(name: 'credits_available') int creditsAvailable});
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fullName = freezed,
    Object? dni = freezed,
    Object? email = null,
    Object? phone = freezed,
    Object? isAdmin = null,
    Object? isTrial = null,
    Object? medicalCertificateUrl = freezed,
    Object? hasGivenFeedback = null,
    Object? feedbackSentiment = freezed,
    Object? creditsAvailable = null,
  }) {
    return _then(_$UserProfileImpl(
      fullName: freezed == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String?,
      dni: freezed == dni
          ? _value.dni
          : dni // ignore: cast_nullable_to_non_nullable
              as String?,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: freezed == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      isAdmin: null == isAdmin
          ? _value.isAdmin
          : isAdmin // ignore: cast_nullable_to_non_nullable
              as bool,
      isTrial: null == isTrial
          ? _value.isTrial
          : isTrial // ignore: cast_nullable_to_non_nullable
              as bool,
      medicalCertificateUrl: freezed == medicalCertificateUrl
          ? _value.medicalCertificateUrl
          : medicalCertificateUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hasGivenFeedback: null == hasGivenFeedback
          ? _value.hasGivenFeedback
          : hasGivenFeedback // ignore: cast_nullable_to_non_nullable
              as bool,
      feedbackSentiment: freezed == feedbackSentiment
          ? _value.feedbackSentiment
          : feedbackSentiment // ignore: cast_nullable_to_non_nullable
              as String?,
      creditsAvailable: null == creditsAvailable
          ? _value.creditsAvailable
          : creditsAvailable // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl(
      {@JsonKey(name: 'full_name') this.fullName,
      this.dni,
      required this.email,
      this.phone,
      @JsonKey(name: 'is_admin') this.isAdmin = false,
      @JsonKey(name: 'is_trial') this.isTrial = false,
      @JsonKey(name: 'medical_certificate_url') this.medicalCertificateUrl,
      @JsonKey(name: 'has_given_feedback') this.hasGivenFeedback = false,
      @JsonKey(name: 'feedback_sentiment') this.feedbackSentiment,
      @JsonKey(name: 'credits_available') this.creditsAvailable = 0});

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  @JsonKey(name: 'full_name')
  final String? fullName;
  @override
  final String? dni;
  @override
  final String email;
  @override
  final String? phone;
  @override
  @JsonKey(name: 'is_admin')
  final bool isAdmin;
  @override
  @JsonKey(name: 'is_trial')
  final bool isTrial;
  @override
  @JsonKey(name: 'medical_certificate_url')
  final String? medicalCertificateUrl;
  @override
  @JsonKey(name: 'has_given_feedback')
  final bool hasGivenFeedback;
  @override
  @JsonKey(name: 'feedback_sentiment')
  final String? feedbackSentiment;
  @override
  @JsonKey(name: 'credits_available')
  final int creditsAvailable;

  @override
  String toString() {
    return 'UserProfile(fullName: $fullName, dni: $dni, email: $email, phone: $phone, isAdmin: $isAdmin, isTrial: $isTrial, medicalCertificateUrl: $medicalCertificateUrl, hasGivenFeedback: $hasGivenFeedback, feedbackSentiment: $feedbackSentiment, creditsAvailable: $creditsAvailable)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.dni, dni) || other.dni == dni) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin) &&
            (identical(other.isTrial, isTrial) || other.isTrial == isTrial) &&
            (identical(other.medicalCertificateUrl, medicalCertificateUrl) ||
                other.medicalCertificateUrl == medicalCertificateUrl) &&
            (identical(other.hasGivenFeedback, hasGivenFeedback) ||
                other.hasGivenFeedback == hasGivenFeedback) &&
            (identical(other.feedbackSentiment, feedbackSentiment) ||
                other.feedbackSentiment == feedbackSentiment) &&
            (identical(other.creditsAvailable, creditsAvailable) ||
                other.creditsAvailable == creditsAvailable));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      fullName,
      dni,
      email,
      phone,
      isAdmin,
      isTrial,
      medicalCertificateUrl,
      hasGivenFeedback,
      feedbackSentiment,
      creditsAvailable);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(
      this,
    );
  }
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile(
          {@JsonKey(name: 'full_name') final String? fullName,
          final String? dni,
          required final String email,
          final String? phone,
          @JsonKey(name: 'is_admin') final bool isAdmin,
          @JsonKey(name: 'is_trial') final bool isTrial,
          @JsonKey(name: 'medical_certificate_url')
          final String? medicalCertificateUrl,
          @JsonKey(name: 'has_given_feedback') final bool hasGivenFeedback,
          @JsonKey(name: 'feedback_sentiment') final String? feedbackSentiment,
          @JsonKey(name: 'credits_available') final int creditsAvailable}) =
      _$UserProfileImpl;

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  @JsonKey(name: 'full_name')
  String? get fullName;
  @override
  String? get dni;
  @override
  String get email;
  @override
  String? get phone;
  @override
  @JsonKey(name: 'is_admin')
  bool get isAdmin;
  @override
  @JsonKey(name: 'is_trial')
  bool get isTrial;
  @override
  @JsonKey(name: 'medical_certificate_url')
  String? get medicalCertificateUrl;
  @override
  @JsonKey(name: 'has_given_feedback')
  bool get hasGivenFeedback;
  @override
  @JsonKey(name: 'feedback_sentiment')
  String? get feedbackSentiment;
  @override
  @JsonKey(name: 'credits_available')
  int get creditsAvailable;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
