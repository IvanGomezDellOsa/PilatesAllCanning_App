import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

// Configuración global de la app (GET /settings público)
@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('Studio de Pilates') String studioName,
    @Default('Dirección no configurada') String address,
    String? whatsapp,
    String? instagram,
    @Default('Lun-Vie: 8-20hs') String schedule,
    String? mapUrl,
    @Default(10) int cancelMinutesBefore,
    @Default(false) bool pauseReservations,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);

  // Helper para parsear el dict plano que viene del backend
  factory AppSettings.fromDict(Map<String, String> dict) {
    return AppSettings(
      studioName: dict['studio_name'] ?? 'Studio de Pilates',
      address: dict['address'] ?? 'Dirección no configurada',
      whatsapp: dict['whatsapp'],
      instagram: dict['instagram'],
      schedule: dict['schedule'] ?? 'Lun-Vie: 8-20hs',
      mapUrl: dict['map_url'],
      cancelMinutesBefore:
          int.tryParse(dict['cancel_minutes_before'] ?? '10') ?? 10,
      pauseReservations: dict['pause_reservations']?.toLowerCase() == 'true',
    );
  }
}
