import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/gym_class_repository.dart';
import '../../../core/repositories/booking_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/providers/providers.dart';
import '../../../models/cancel_response.dart'; // ✅ IMPORTANTE: Este import faltaba

// ========== BOOK CLASS CONTROLLER ==========

class BookClassController extends StateNotifier<AsyncValue<void>> {
  final GymClassRepository _gymClassRepo;

  BookClassController(this._gymClassRepo) : super(const AsyncValue.data(null));

  Future<void> bookClass(String classId) async {
    state = const AsyncValue.loading();

    try {
      await _gymClassRepo.bookClass(classId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final bookClassControllerProvider =
    StateNotifierProvider<BookClassController, AsyncValue<void>>((ref) {
  final gymClassRepo = ref.watch(gymClassRepositoryProvider);
  return BookClassController(gymClassRepo);
});

// ========== CANCEL BOOKING CONTROLLER ==========

class CancelBookingController
    extends StateNotifier<AsyncValue<CancelResponse?>> {
  final BookingRepository _bookingRepo;

  CancelBookingController(this._bookingRepo)
      : super(const AsyncValue.data(null));

  Future<CancelResponse> cancelBooking(String bookingId) async {
    state = const AsyncValue.loading();

    try {
      // Ahora coincide con el repositorio que devuelve Future<CancelResponse>
      final response = await _bookingRepo.cancelBooking(bookingId);
      state = AsyncValue.data(response);
      return response;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final cancelBookingControllerProvider =
    StateNotifierProvider<CancelBookingController, AsyncValue<CancelResponse?>>(
        (ref) {
  final bookingRepo = ref.watch(bookingRepositoryProvider);
  return CancelBookingController(bookingRepo);
});

// ========== UPDATE PROFILE CONTROLLER ==========

class UpdateProfileController extends StateNotifier<AsyncValue<void>> {
  final UserRepository _userRepo;

  UpdateProfileController(this._userRepo) : super(const AsyncValue.data(null));

  Future<void> updateProfile({
    String? fullName,
    String? dni,
    String? phone, // Lo recibimos pero no lo enviamos si el repo no lo soporta
  }) async {
    state = const AsyncValue.loading();

    try {
      await _userRepo.updateProfile(fullName ?? '', dni ?? '', null);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final updateProfileControllerProvider =
    StateNotifierProvider<UpdateProfileController, AsyncValue<void>>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  return UpdateProfileController(userRepo);
});
