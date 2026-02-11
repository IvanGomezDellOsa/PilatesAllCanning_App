// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      dni: json['dni'] as String?,
      phone: json['phone'] as String?,
      creditsAvailable: (json['credits_available'] as num?)?.toInt() ?? 0,
      isAdmin: json['is_admin'] as bool? ?? false,
      disabled: json['disabled'] as bool? ?? false,
      isTrial: json['is_trial'] as bool? ?? false,
      medicalCertificateUrl: json['medical_certificate_url'] as String?,
      hasGivenFeedback: json['has_given_feedback'] as bool? ?? false,
      feedbackSentiment: json['feedback_sentiment'] as String?,
      isInstructor: json['is_instructor'] as bool? ?? false,
    );

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'dni': instance.dni,
      'phone': instance.phone,
      'credits_available': instance.creditsAvailable,
      'is_admin': instance.isAdmin,
      'disabled': instance.disabled,
      'is_trial': instance.isTrial,
      'medical_certificate_url': instance.medicalCertificateUrl,
      'has_given_feedback': instance.hasGivenFeedback,
      'feedback_sentiment': instance.feedbackSentiment,
      'is_instructor': instance.isInstructor,
    };

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      fullName: json['full_name'] as String?,
      dni: json['dni'] as String?,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
      isTrial: json['is_trial'] as bool? ?? false,
      medicalCertificateUrl: json['medical_certificate_url'] as String?,
      hasGivenFeedback: json['has_given_feedback'] as bool? ?? false,
      feedbackSentiment: json['feedback_sentiment'] as String?,
      creditsAvailable: (json['credits_available'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'full_name': instance.fullName,
      'dni': instance.dni,
      'email': instance.email,
      'phone': instance.phone,
      'is_admin': instance.isAdmin,
      'is_trial': instance.isTrial,
      'medical_certificate_url': instance.medicalCertificateUrl,
      'has_given_feedback': instance.hasGivenFeedback,
      'feedback_sentiment': instance.feedbackSentiment,
      'credits_available': instance.creditsAvailable,
    };
