// APP_ROUTER.DART
// ----------------
// Configuración de rutas y navegación usando GoRouter.
//
// Lógica de Redirección:
// - Sin usuario: -> /login
// - Sin DNI/Nombre: -> /onboarding
// - Admin: -> /admin
// - Cliente: -> /client
//
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../providers/providers.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/client/presentation/client_home_screen.dart';
import '../../features/client/presentation/client_my_classes_screen.dart';
import '../../features/client/presentation/client_profile_screen.dart';
import '../../features/client/presentation/client_info_screen.dart';
import '../../features/client/presentation/client_announcements_screen.dart';

import '../../features/admin/presentation/admin_home_screen.dart';
import '../../features/admin/presentation/admin_users_screen.dart';
import '../../features/shared/presentation/delete_account_info_screen.dart';
import '../../features/admin/presentation/admin_settings_screen.dart';
import '../../features/admin/presentation/admin_announcements_screen.dart';
import '../../features/admin/presentation/admin_user_bookings_screen.dart'; // Nuevo

final goRouterProvider = Provider<GoRouter>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);

  // Create a notifier to trigger router refreshes
  final listenable = ValueNotifier<bool>(true);

  // Update listenable when auth state changes
  ref.listen(authStateChangesProvider, (_, __) {
    debugPrint("AppRouter: Auth state changed, notifying router...");
    listenable.value = !listenable.value;
  });

  // Also listen to current user provider to handle profile loading changes
  ref.listen(currentUserProvider, (_, __) {
    debugPrint("AppRouter: Current user data changed, notifying router...");
    listenable.value = !listenable.value;
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: listenable, // Router refreshes when this changes
    redirect: (context, state) {
      if (currentUserAsync.isLoading) {
        debugPrint("AppRouter: User loading...");
        return null;
      }

      final user = currentUserAsync.value;

      final isOnLogin = state.matchedLocation == '/login';
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      final isDeletionRequest =
          state.matchedLocation == '/delete-account-request';

      if (isDeletionRequest) return null;

      if (user == null) {
        return isOnLogin ? null : '/login';
      }

      if (user.fullName == null || user.dni == null) {
        debugPrint("AppRouter: Missing DNI/Name -> /onboarding");
        return isOnOnboarding ? null : '/onboarding';
      }

      if (user.isAdmin && state.matchedLocation.startsWith('/admin')) {
        return null;
      }

      if (user.isAdmin && isOnLogin) {
        return '/admin';
      }

      if (!user.isAdmin && state.matchedLocation.startsWith('/client')) {
        return null;
      }

      // Client attempting to access Admin area
      if (!user.isAdmin && state.matchedLocation.startsWith('/admin')) {
        return '/client';
      }

      if (!user.isAdmin && (isOnLogin || isOnOnboarding)) {
        return '/client';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/delete-account-request',
        builder: (context, state) => const DeleteAccountInfoScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ===== RUTAS CLIENTE =====
      GoRoute(
        path: '/client',
        name: 'client-home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/client/my-classes',
        name: 'my-classes',
        builder: (context, state) => const MyClassesScreen(),
      ),
      GoRoute(
        path: '/client/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/client/info',
        name: 'client-info',
        builder: (context, state) => const InfoScreen(),
      ),
      GoRoute(
        path: '/client/announcements',
        name: 'client-announcements',
        builder: (context, state) => const ClientAnnouncementsScreen(),
      ),

      // ===== RUTAS ADMIN =====
      GoRoute(
        path: '/admin',
        name: 'admin-home',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        name: 'admin-users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'admin-settings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/announcements',
        name: 'admin-announcements',
        builder: (context, state) => const AdminAnnouncementsScreen(),
      ),
      GoRoute(
        path: '/admin/users/:userId/bookings',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final userName = state.extra as String? ?? 'Usuario';
          return AdminUserBookingsScreen(userId: userId, userName: userName);
        },
      ),
    ],
  );
});
