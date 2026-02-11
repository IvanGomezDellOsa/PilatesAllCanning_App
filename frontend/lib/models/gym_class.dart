// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'booking.dart'; // Asegúrate de que BookingStatus esté aquí

part 'gym_class.freezed.dart';
part 'gym_class.g.dart';

@freezed
class GymClass with _$GymClass {
  // 1. Constructor privado: OBLIGATORIO para métodos personalizados en Freezed
  const GymClass._();

  const factory GymClass({
    required String id,
    required String name,
    required String instructor,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'duration_minutes') @Default(60) int durationMinutes,
    @JsonKey(name: 'max_slots') @Default(8) int maxSlots,

    // Campos opcionales o con default para compatibilidad con create response
    @JsonKey(name: 'confirmed_count') @Default(0) int confirmedCount,
    @JsonKey(name: 'my_status') @Default(false) bool isBookedByMe,

    // Campos nuevos del Backend
    @Default(false) bool recurrence,
    @JsonKey(name: 'recurrence_group')
    String? recurrenceGroup, // Puede ser null
    @JsonKey(name: 'cancelled_at') DateTime? cancelledAt, // Puede ser null
  }) = _GymClass;

  factory GymClass.fromJson(Map<String, dynamic> json) =>
      _$GymClassFromJson(json);

  // --- LÓGICA DE NEGOCIO (Getters) ---

  // Esto arregla el error: undefined_getter 'availableSlots'
  int get availableSlots => maxSlots - confirmedCount;

  // Esto arregla el error: undefined_getter 'myStatus'
  BookingStatus get myStatus {
    if (isBookedByMe) return BookingStatus.confirmed;
    return BookingStatus.none;
  }
}

@freezed
class GymClassDetail with _$GymClassDetail {
  const factory GymClassDetail({
    required String id,
    required String name,
    required String instructor,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'duration_minutes') required int durationMinutes,
    @JsonKey(name: 'max_slots') required int maxSlots,
    @JsonKey(name: 'confirmed_count') @Default(0) int confirmedCount,
    required List<Booking> bookings,
  }) = _GymClassDetail;

  factory GymClassDetail.fromJson(Map<String, dynamic> json) =>
      _$GymClassDetailFromJson(json);
}
