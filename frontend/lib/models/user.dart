import 'package:freezed_annotation/freezed_annotation.dart';

// ignore_for_file: invalid_annotation_target

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    @JsonKey(name: 'full_name') String? fullName,
    String? dni,
    String? phone,
    @JsonKey(name: 'credits_available') @Default(0) int creditsAvailable,
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
    @Default(false) bool disabled,
    @JsonKey(name: 'is_trial') @Default(false) bool isTrial,
    @JsonKey(name: 'medical_certificate_url') String? medicalCertificateUrl,
    @JsonKey(name: 'has_given_feedback') @Default(false) bool hasGivenFeedback,
    @JsonKey(name: 'feedback_sentiment') String? feedbackSentiment,
    @JsonKey(name: 'is_instructor') @Default(false) bool isInstructor,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// Profile Read Schema (para GET /me)
@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    @JsonKey(name: 'full_name') String? fullName,
    String? dni,
    required String email,
    String? phone,
    @JsonKey(name: 'is_admin') @Default(false) bool isAdmin,
    @JsonKey(name: 'is_trial') @Default(false) bool isTrial,
    @JsonKey(name: 'medical_certificate_url') String? medicalCertificateUrl,
    @JsonKey(name: 'has_given_feedback') @Default(false) bool hasGivenFeedback,
    @JsonKey(name: 'feedback_sentiment') String? feedbackSentiment,
    @JsonKey(name: 'credits_available') @Default(0) int creditsAvailable,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

// Enum para días de la semana (mapeo al backend)
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Lunes';
      case DayOfWeek.tuesday:
        return 'Martes';
      case DayOfWeek.wednesday:
        return 'Miércoles';
      case DayOfWeek.thursday:
        return 'Jueves';
      case DayOfWeek.friday:
        return 'Viernes';
      case DayOfWeek.saturday:
        return 'Sábado';
      case DayOfWeek.sunday:
        return 'Domingo';
    }
  }
}
