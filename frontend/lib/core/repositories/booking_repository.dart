// BOOKING_REPOSITORY.DART
// ------------------------
// Abstracción para operaciones de reservas del usuario.
//
// Métodos:
// - `getMyBookings()`: Historial de reservas.
// - `cancelBooking(id)`: Cancela reserva y devuelve info de reembolso.
//
import 'package:dio/dio.dart';
import '../../models/booking.dart';
import '../../models/cancel_response.dart';

abstract class BookingRepository {
  Future<List<Booking>> getMyBookings();
  Future<CancelResponse> cancelBooking(String bookingId);
}

class MockBookingRepository implements BookingRepository {
  final List<Booking> _mockDb = [
    Booking(
      bookingId: 'b1',
      classId: 'c1',
      name: 'Pilates Reformer (Mañana)',
      instructor: 'Ana García',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      status: BookingStatus.confirmed,
    ),
    Booking(
      bookingId: 'b2',
      classId: 'c2',
      name: 'Mat Pilates (Mediodía)',
      instructor: 'Carlos Perez',
      startTime: DateTime.now().add(const Duration(days: 2, hours: 4)),
      status: BookingStatus.confirmed,
    ),
    Booking(
      bookingId: 'b3',
      classId: 'c3',
      name: 'Stretching (Pasada)',
      instructor: 'Luis',
      startTime: DateTime.now().subtract(const Duration(days: 2)),
      status: BookingStatus.confirmed,
    ),
  ];

  @override
  Future<List<Booking>> getMyBookings() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [..._mockDb];
  }

  @override
  Future<CancelResponse> cancelBooking(String bookingId) async {
    await Future.delayed(const Duration(seconds: 1));

    final index = _mockDb.indexWhere((b) => b.bookingId == bookingId);

    if (index != -1) {
      final original = _mockDb[index];
      _mockDb[index] = original.copyWith(status: BookingStatus.cancelled);

      return CancelResponse(
          refunded: true,
          message:
              "Reserva cancelada exitosamente. Se te ha devuelto 1 crédito.");
    } else {
      throw Exception("Reserva no encontrada");
    }
  }
}

class HttpBookingRepository implements BookingRepository {
  final Dio _dio;
  HttpBookingRepository(this._dio);

  @override
  Future<List<Booking>> getMyBookings() async {
    try {
      final response = await _dio.get('/my-bookings');
      final list = response.data as List;
      return list.map((e) {
        return Booking(
          bookingId: e['booking_id'].toString(),
          classId: e['id'].toString(),
          name: e['name'],
          instructor: e['instructor'],
          startTime: DateTime.parse(e['start_time']),
          status: BookingStatus.values.firstWhere(
            (s) => s.name == e['status'],
            orElse: () => BookingStatus.none,
          ),
          cancelledAt: e['cancelled_at'] != null
              ? DateTime.parse(e['cancelled_at'])
              : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  @override
  Future<CancelResponse> cancelBooking(String bookingId) async {
    try {
      final response = await _dio.post('/bookings/$bookingId/cancel');
      return CancelResponse(
          refunded: response.data['refunded'],
          message: response.data['message']);
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response!.data['detail'] != null) {
        throw e.response!.data['detail'];
      }
      throw 'Error al cancelar: ${e.message}';
    } catch (e) {
      throw 'Error inesperado al cancelar';
    }
  }
}
