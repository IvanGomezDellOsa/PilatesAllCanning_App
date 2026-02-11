// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsImpl _$$AppSettingsImplFromJson(Map<String, dynamic> json) =>
    _$AppSettingsImpl(
      studioName: json['studioName'] as String? ?? 'Studio de Pilates',
      address: json['address'] as String? ?? 'Dirección no configurada',
      whatsapp: json['whatsapp'] as String?,
      instagram: json['instagram'] as String?,
      schedule: json['schedule'] as String? ?? 'Lun-Vie: 8-20hs',
      mapUrl: json['mapUrl'] as String?,
      cancelMinutesBefore: (json['cancelMinutesBefore'] as num?)?.toInt() ?? 10,
      pauseReservations: json['pauseReservations'] as bool? ?? false,
    );

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'studioName': instance.studioName,
      'address': instance.address,
      'whatsapp': instance.whatsapp,
      'instagram': instance.instagram,
      'schedule': instance.schedule,
      'mapUrl': instance.mapUrl,
      'cancelMinutesBefore': instance.cancelMinutesBefore,
      'pauseReservations': instance.pauseReservations,
    };
