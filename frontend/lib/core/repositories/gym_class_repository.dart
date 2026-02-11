// GYM_CLASS_REPOSITORY.DART
// --------------------------
// Abstracción para operaciones de clases (GymClass).
//
// Métodos:
// - `getClasses(date)`: Obtiene clases para una fecha.
// - `bookClass(id)` / `cancelBooking(id)`: Reservar/Cancelar clase.
// - Admin: `createGymClass`, `updateGymClass`, `deleteGymClass`, `manualBook`.
//
import '../../models/gym_class.dart';
import 'package:dio/dio.dart';

abstract class GymClassRepository {
  Future<List<GymClass>> getClasses({DateTime? date});
  Future<GymClassDetail> getClassDetail(String classId);
  Future<void> bookClass(String classId);
  Future<void> cancelBooking(String classId);

  // Admin Methods
  Future<GymClass> createGymClass({
    required String name,
    required String instructor,
    required DateTime startTime,
    required int maxSlots,
    required int durationMinutes,
    bool recurrence = false,
  });

  Future<void> manualBook({
    required String classId,
    String? userId,
    String? dni,
    String? fullName,
    bool isTrial = false,
  });

  Future<GymClass> updateGymClass({
    required String classId,
    String? name,
    String? instructor,
    int? maxSlots,
    int? durationMinutes,
  });

  Future<void> adminCancelBooking(String bookingId);

  Future<void> deleteGymClass(String classId, {bool cancelSeries = false});
}

class MockGymClassRepository implements GymClassRepository {
  final Set<String> _bookedClassIds = {};

  @override
  Future<List<GymClass>> getClasses({DateTime? date}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final targetDate = date ?? DateTime.now();

    return [
      GymClass(
        id: 'class-1-${targetDate.day}',
        name: 'Pilates Reformer (Mañana)',
        instructor: 'Ana García',
        startTime:
            DateTime(targetDate.year, targetDate.month, targetDate.day, 9, 0),
        durationMinutes: 50,
        maxSlots: 8,
        confirmedCount: 6,
        isBookedByMe: _bookedClassIds.contains('class-1-${targetDate.day}'),
      ),
      GymClass(
        id: 'class-2-${targetDate.day}',
        name: 'Mat Pilates (Mediodía)',
        instructor: 'Carlos Perez',
        startTime:
            DateTime(targetDate.year, targetDate.month, targetDate.day, 14, 0),
        durationMinutes: 60,
        maxSlots: 10,
        confirmedCount: 0,
        isBookedByMe: _bookedClassIds.contains('class-2-${targetDate.day}'),
      ),
    ];
  }

  @override
  Future<void> bookClass(String classId) async {
    await Future.delayed(const Duration(seconds: 1));
    _bookedClassIds.add(classId);
  }

  @override
  Future<void> cancelBooking(String classId) async {
    await Future.delayed(const Duration(seconds: 1));
    _bookedClassIds.remove(classId);
  }

  @override
  Future<GymClassDetail> getClassDetail(String classId) async =>
      throw UnimplementedError();

  @override
  Future<GymClass> createGymClass(
          {required String name,
          required String instructor,
          required DateTime startTime,
          required int maxSlots,
          required int durationMinutes,
          bool recurrence = false}) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteGymClass(String classId,
          {bool cancelSeries = false}) async =>
      throw UnimplementedError();

  @override
  Future<void> manualBook(
          {required String classId,
          String? userId,
          String? dni,
          String? fullName,
          bool isTrial = false}) async =>
      throw UnimplementedError();

  @override
  Future<GymClass> updateGymClass({
    required String classId,
    String? name,
    String? instructor,
    int? maxSlots,
    int? durationMinutes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> adminCancelBooking(String bookingId) async =>
      throw UnimplementedError();
}

class HttpGymClassRepository implements GymClassRepository {
  final Dio _dio;

  HttpGymClassRepository(this._dio);

  @override
  Future<List<GymClass>> getClasses({DateTime? date}) async {
    try {
      final response = await _dio.get('/gym-classes', queryParameters: {
        if (date != null) 'date': date.toIso8601String().split('T').first,
      });
      return (response.data as List).map((e) => GymClass.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error fetching classes: $e');
    }
  }

  @override
  Future<GymClassDetail> getClassDetail(String classId) async {
    try {
      final response = await _dio.get('/gym-classes/$classId');
      return GymClassDetail.fromJson(response.data);
    } catch (e) {
      throw Exception('Error fetching class detail: $e');
    }
  }

  @override
  Future<void> bookClass(String classId) async {
    try {
      await _dio.post('/gym-classes/$classId/book');
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response!.data['detail'] != null) {
        throw e.response!.data['detail'];
      }
      throw 'Error al reservar: ${e.message}';
    } catch (e) {
      throw 'Error desconocido al reservar';
    }
  }

  @override
  Future<void> cancelBooking(String classId) async {
    throw UnimplementedError('Use BookingRepository for cancellations');
  }

  // Admin Implementations

  @override
  Future<GymClass> createGymClass(
      {required String name,
      required String instructor,
      required DateTime startTime,
      required int maxSlots,
      required int durationMinutes,
      bool recurrence = false}) async {
    try {
      // Backend returns List<GymClass> (usually the list created, or single).
      // endpoint: POST /gym-classes. Returns List<GymClass>.
      final response = await _dio.post('/gym-classes', data: {
        'gym_class': {
          // Body(..., embed=True) implies fields are at top level or embedded?
          // Backend: name: str = Body("Clase", embed=True).
          // This means {"name": "...", "instructor": "..."}.
          // NOT nested in "gym_class".
        },
        'name': name,
        'instructor': instructor,
        'start_time': startTime.toIso8601String(),
        'max_slots': maxSlots,
        'duration_minutes': durationMinutes,
        'recurrence': recurrence,
      });

      // Backend returns List. We return the first one as representative? Or last?
      // Interface says return GymClass.
      // We return the first one.
      return GymClass.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response!.data['detail'] != null) {
        throw e.response!.data['detail'];
      }
      throw 'Error creating class: ${e.message}';
    } catch (e) {
      throw 'Error creating class: $e';
    }
  }

  @override
  Future<void> manualBook(
      {required String classId,
      String? userId,
      String? dni,
      String? fullName,
      bool isTrial = false}) async {
    try {
      await _dio.post('/gym-classes/$classId/manual-book', data: {
        if (userId != null) 'user_id': userId,
        if (dni != null) 'dni': dni,
        if (fullName != null) 'full_name': fullName,
        'is_trial': isTrial,
      });
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response!.data['detail'] != null) {
        throw e.response!.data['detail'];
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteGymClass(String classId,
      {bool cancelSeries = false}) async {
    await _dio.delete('/gym-classes/$classId', queryParameters: {
      'cancel_series': cancelSeries,
    });
  }

  @override
  Future<GymClass> updateGymClass({
    required String classId,
    String? name,
    String? instructor,
    int? maxSlots,
    int? durationMinutes,
  }) async {
    try {
      final response = await _dio.patch('/gym-classes/$classId', data: {
        if (name != null) 'name': name,
        if (instructor != null) 'instructor': instructor,
        if (maxSlots != null) 'max_slots': maxSlots,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
      });
      return GymClass.fromJson(response.data);
    } catch (e) {
      throw Exception('Error updating class: $e');
    }
  }

  @override
  Future<void> adminCancelBooking(String bookingId) async {
    try {
      await _dio.delete('/bookings/$bookingId');
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response!.data['detail'] != null) {
        throw e.response!.data['detail'];
      }
      throw 'Error cancelling booking: ${e.message}';
    }
  }
}
