// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookingImpl _$$BookingImplFromJson(Map<String, dynamic> json) =>
    _$BookingImpl(
      bookingId: json['bookingId'] as String,
      classId: json['classId'] as String,
      name: json['name'] as String,
      instructor: json['instructor'] as String,
      userName: json['userName'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      status: $enumDecode(_$BookingStatusEnumMap, json['status']),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
    );

Map<String, dynamic> _$$BookingImplToJson(_$BookingImpl instance) =>
    <String, dynamic>{
      'bookingId': instance.bookingId,
      'classId': instance.classId,
      'name': instance.name,
      'instructor': instance.instructor,
      'userName': instance.userName,
      'startTime': instance.startTime.toIso8601String(),
      'status': _$BookingStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt?.toIso8601String(),
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
    };

const _$BookingStatusEnumMap = {
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.none: 'none',
};
