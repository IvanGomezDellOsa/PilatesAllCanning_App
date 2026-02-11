import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

enum BookingStatus { confirmed, cancelled, none }

@freezed
class Booking with _$Booking {
  const factory Booking({
    required String bookingId,
    required String classId,
    required String name,
    required String instructor,
    String? userName, // Added for Admin Class Detail (Student Name)
    required DateTime startTime,
    required BookingStatus status,
    DateTime? createdAt,
    DateTime? cancelledAt,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
}

extension BookingStatusX on Booking {
  bool get canCancel => status == BookingStatus.confirmed;
}
