// PROVIDERS.DART
// ---------------
// Capa de estado global usando Riverpod.
//
// Contenido:
// 1. Configuración HTTP (Dio + Interceptor de Auth Firebase).
// 2. Repositorios (inyección de dependencias).
// 3. Providers de datos (usuarios, clases, reservas).
// 4. Controllers (acciones: reservar, crear novedades, etc).
//
import 'package:file_picker/file_picker.dart'; // Add import
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../repositories/auth_repository.dart';
import '../repositories/firebase_auth_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/http_user_repository.dart';
import '../repositories/gym_class_repository.dart';
import '../repositories/booking_repository.dart';
import '../repositories/announcement_repository.dart';
import '../../models/user.dart';
import '../../models/gym_class.dart';
import '../../models/booking.dart';
import '../../models/announcement.dart';
import '../repositories/instructor_repository.dart';
import '../repositories/settings_repository.dart';
import '../../models/instructor.dart';
import '../../models/settings.dart';

import 'package:flutter/foundation.dart'; // Import kIsWeb
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../services/notification_service.dart';

import '../../core/constants/app_constants.dart';

/// Configuración del cliente HTTP.
final dioProvider = Provider<Dio>((ref) {
  final baseUrl = AppConstants.apiBaseUrl;
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // Interceptor para añadir el token de Firebase a cada petición
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final token = await user.getIdToken();
            options.headers['Authorization'] = 'Bearer $token';
          } catch (e) {
            // Si falla obtener el token, continuar sin él
            debugPrint('AUTH_INTERCEPTOR: Error getting token: $e');
          }
        }
        return handler.next(options);
      },
    ),
  );

  return dio;
});

// =============================================================================
// REPOSITORIOS
// =============================================================================

// Implementaciones de Repositorios (HTTP / Firebase)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return FirebaseAuthRepository(dio);
});
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HttpUserRepository(dio);
});
final gymClassRepositoryProvider = Provider<GymClassRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HttpGymClassRepository(dio);
});
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HttpBookingRepository(dio);
});

// Implementación Real para Novedades (con subida de imágenes)
final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HttpAnnouncementRepository(dio);
});

// SERVICE: Push Notifications
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final service = NotificationService(userRepo, ref);

  // Escuchar cambios de Auth para sincronizar token al loguearse
  ref.listen<AsyncValue<User?>>(authStateChangesProvider, (prev, next) {
    next.whenData((user) {
      if (user != null) {
        service.syncToken();
      }
    });
  });

  return service;
});

// =============================================================================
// DATA PROVIDERS (LECTURA)
// =============================================================================

/// Usuario autenticado actual.
final currentUserProvider = FutureProvider<User?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getCurrentUser();
});

/// Stream de estado de autenticación (para router)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// Perfil completo del usuario (créditos, flags).
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.getProfile();
});

/// Grilla de clases.
final gymClassesProvider = FutureProvider.family<List<GymClass>, String>((
  ref,
  dateStr,
) async {
  final repo = ref.watch(gymClassRepositoryProvider);
  final date = DateTime.tryParse(dateStr) ?? DateTime.now();
  return repo.getClasses(date: date);
});

/// Mis reservas.
final myBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getMyBookings();
});

/// Buscador de usuarios con PAGINACIÓN
class UserSearchState {
  final List<User> users;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String query;

  const UserSearchState({
    required this.users,
    this.isLoading = false,
    this.hasMore = true,
    this.page = 0,
    this.query = '',
  });

  UserSearchState copyWith({
    List<User>? users,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? query,
  }) {
    return UserSearchState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      query: query ?? this.query,
    );
  }
}

final usersSearchProvider =
    StateNotifierProvider.autoDispose<UserSearchController, UserSearchState>((
  ref,
) {
  return UserSearchController(ref);
});

class UserSearchController extends StateNotifier<UserSearchState> {
  final Ref _ref;
  final int _limit = 20;
  Timer? _debounceTimer;

  UserSearchController(this._ref) : super(const UserSearchState(users: [])) {
    // Initial load immediately
    _performSearch('');
  }

  void onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> search(String query, {bool isRefresh = false}) async {
    await _performSearch(query, isRefresh: isRefresh);
  }

  Future<void> _performSearch(String query, {bool isRefresh = true}) async {
    if (isRefresh) {
      state = state.copyWith(
        query: query,
        users: [],
        page: 0,
        hasMore: true,
        isLoading: true,
      );
    } else {
      if (!state.hasMore || state.isLoading) return;
      state = state.copyWith(isLoading: true);
    }

    try {
      final repo = _ref.read(userRepositoryProvider);
      final newUsers = await repo.searchUsers(
        query: query,
        skip: state.page * _limit,
        limit: _limit,
      );

      state = state.copyWith(
        users: isRefresh ? newUsers : [...state.users, ...newUsers],
        page: state.page + 1,
        hasMore: newUsers.length == _limit,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    await _performSearch(state.query, isRefresh: false);
  }

  void refresh() {
    _performSearch(state.query, isRefresh: true);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// =============================================================================
// LOGIC CONTROLLERS (ACCIONES)
// =============================================================================

/// 1. NOVEDADES (CRUD)
final announcementsProvider = StateNotifierProvider<AnnouncementController,
    AsyncValue<List<Announcement>>>((ref) {
  final repo = ref.watch(announcementRepositoryProvider);
  return AnnouncementController(repo);
});

class AnnouncementController
    extends StateNotifier<AsyncValue<List<Announcement>>> {
  final AnnouncementRepository _repository;

  AnnouncementController(this._repository) : super(const AsyncValue.loading()) {
    loadAnnouncements();
  }

  Future<void> loadAnnouncements() async {
    try {
      if (state.value == null) state = const AsyncValue.loading();
      final announcements = await _repository.getAnnouncements();
      state = AsyncValue.data(announcements);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createAnnouncement({
    String? title, // Opcional
    String? content, // Opcional
    PlatformFile? imageFile,
    DateTime? expiresAt,
    bool sendPush = false,
  }) async {
    try {
      await _repository.createAnnouncement(
        title: title,
        content: content,
        imageFile: imageFile,
        expiresAt: expiresAt,
        sendPush: sendPush,
      );
      await loadAnnouncements();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _repository.deleteAnnouncement(id);
      // Reload from server to ensure consistency instead of just filtering locally
      await loadAnnouncements();
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider para el conteo de novedades no leídas (Badge)

final unreadAnnouncementsProvider =
    StateNotifierProvider<UnreadController, int>((ref) {
  final announcementsAsync = ref.watch(
    announcementsProvider,
  ); // Escuchar cambios en novedades
  return UnreadController(announcementsAsync);
});

class UnreadController extends StateNotifier<int> {
  final AsyncValue<List<Announcement>> _announcements;
  static const _keyLastChecked = 'last_checked_announcements';

  UnreadController(this._announcements) : super(0) {
    _calculateUnread();
  }

  Future<void> _calculateUnread() async {
    final list = _announcements.valueOrNull;
    if (list == null || list.isEmpty) {
      state = 0;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastCheckedStr = prefs.getString(_keyLastChecked);
    final lastChecked =
        lastCheckedStr != null ? DateTime.tryParse(lastCheckedStr) : null;

    if (lastChecked == null) {
      // Si nunca entró, todas son nuevas
      state = list.length;
      debugPrint(
          'BadgeController: LastChecked is null. Count = ${list.length}');
    } else {
      // Contar cuantas tienen created_at > lastChecked
      int count = 0;
      for (var a in list) {
        final isNew = a.createdAt.isAfter(lastChecked);
        if (isNew) {
          count++;
          // debugPrint('BadgeController: New item found');
        }
      }
      state = count;
      debugPrint(
          'BadgeController: Unread count: $count. LastChecked: $lastChecked');
    }
  }

  Future<void> markWithList(List<Announcement> list) async {
    final prefs = await SharedPreferences.getInstance();
    DateTime markerTime;

    if (list.isNotEmpty) {
      // Find max date in the provided list
      var maxDate = list.first.createdAt;
      for (var a in list) {
        if (a.createdAt.isAfter(maxDate)) {
          maxDate = a.createdAt;
        }
      }
      markerTime = maxDate;
    } else {
      markerTime = DateTime.now();
    }

    await prefs.setString(_keyLastChecked, markerTime.toIso8601String());
    debugPrint(
        'BadgeController: Saved LastChecked: ${markerTime.toIso8601String()}');

    // Force recalculate immediately just in case
    // But since we are likely calling this from UI which already has the latest list
    // Updates will propagate via the watch(announcementsProvider) eventually?
    // Actually UnreadController holds a stale list from constructor usually.
    // So we should manually update state to 0.
    state = 0;
  }

  Future<void> markAllAsRead() async {
    // Legacy/Fallback method.
    // Try to use internal list if available.
    final list = _announcements.valueOrNull ?? [];
    await markWithList(list);
  }
}

/// 2. RESERVA MANUAL (ADMIN - AGENDA)
final manualBookProvider =
    StateNotifierProvider<ManualBookController, AsyncValue<void>>((ref) {
  return ManualBookController(ref);
});

/// Controller para realizar reservas manuales (Admin).
class ManualBookController extends StateNotifier<AsyncValue<void>> {
  ManualBookController(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> bookWithUserId(String classId, String userId) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/gym-classes/$classId/manual-book',
        data: {'user_id': userId},
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> bookWithNewUser(
    String classId,
    String dni,
    String fullName,
    bool isTrial,
  ) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/gym-classes/$classId/manual-book',
        data: {'dni': dni, 'full_name': fullName, 'is_trial': isTrial},
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// 3. TURNOS FIJOS (ADMIN - USUARIOS) - NUEVO
final fixedScheduleProvider =
    StateNotifierProvider<FixedScheduleController, AsyncValue<void>>((ref) {
  return FixedScheduleController(ref);
});

/// Controller para gestionar turnos fijos (Admin).
class FixedScheduleController extends StateNotifier<AsyncValue<void>> {
  FixedScheduleController(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  Future<void> addFixedSchedule({
    required String userId,
    required String dayOfWeek, // "monday", "tuesday"...
    required String startTime, // "HH:mm:ss"
  }) async {
    state = const AsyncValue.loading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/fixed-schedules',
        data: {
          'user_id': userId,
          'day_of_week': dayOfWeek,
          'start_time': startTime,
        },
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// =============================================================================
// AJUSTES Y CONFIGURACIÓN GLOBAL
// =============================================================================

final instructorRepositoryProvider = Provider<InstructorRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HttpInstructorRepository(dio);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HttpSettingsRepository(dio);
});

final allInstructorsProvider = FutureProvider<List<Instructor>>((ref) async {
  return ref.watch(instructorRepositoryProvider).getAllInstructors();
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<AppSettings>>((ref) {
  return SettingsController(ref.watch(settingsRepositoryProvider));
});

class SettingsController extends StateNotifier<AsyncValue<AppSettings>> {
  SettingsController(this._repo) : super(const AsyncValue.loading()) {
    load();
  }
  final SettingsRepository _repo;

  Future<void> load() async {
    state = await AsyncValue.guard(() => _repo.getSettings());
  }

  Future<void> update(String key, String value) async {
    await _repo.updateSetting(key, value);
    await load();
  }
}
