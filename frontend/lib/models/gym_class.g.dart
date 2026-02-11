// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GymClassImpl _$$GymClassImplFromJson(Map<String, dynamic> json) =>
    _$GymClassImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      instructor: json['instructor'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      maxSlots: (json['max_slots'] as num?)?.toInt() ?? 8,
      confirmedCount: (json['confirmed_count'] as num?)?.toInt() ?? 0,
      isBookedByMe: json['my_status'] as bool? ?? false,
      recurrence: json['recurrence'] as bool? ?? false,
      recurrenceGroup: json['recurrence_group'] as String?,
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
    );

Map<String, dynamic> _$$GymClassImplToJson(_$GymClassImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'instructor': instance.instructor,
      'start_time': instance.startTime.toIso8601String(),
      'duration_minutes': instance.durationMinutes,
      'max_slots': instance.maxSlots,
      'confirmed_count': instance.confirmedCount,
      'my_status': instance.isBookedByMe,
      'recurrence': instance.recurrence,
      'recurrence_group': instance.recurrenceGroup,
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
    };

_$GymClassDetailImpl _$$GymClassDetailImplFromJson(Map<String, dynamic> json) =>
    _$GymClassDetailImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      instructor: json['instructor'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      durationMinutes: (json['duration_minutes'] as num).toInt(),
      maxSlots: (json['max_slots'] as num).toInt(),
      confirmedCount: (json['confirmed_count'] as num?)?.toInt() ?? 0,
      bookings: (json['bookings'] as List<dynamic>)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$GymClassDetailImplToJson(
        _$GymClassDetailImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'instructor': instance.instructor,
      'start_time': instance.startTime.toIso8601String(),
      'duration_minutes': instance.durationMinutes,
      'max_slots': instance.maxSlots,
      'confirmed_count': instance.confirmedCount,
      'bookings': instance.bookings,
    };
