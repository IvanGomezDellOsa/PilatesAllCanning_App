// lib/features/auth/providers/auth_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/providers/providers.dart';
import '../../../models/user.dart';

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final Ref _ref;

  AuthController(this._authRepo, this._userRepo, this._ref)
      : super(const AsyncValue.data(null));

  Future<User> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepo.signInWithGoogle();
      _ref.invalidate(currentUserProvider);
      state = const AsyncValue.data(null);
      return user;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> completeOnboarding({
    required String fullName,
    required String dni,
  }) async {
    state = const AsyncValue.loading();
    try {
      // ✅ CORRECTO: Argumentos posicionales (Nombre, DNI, Null para teléfono)
      await _userRepo.updateProfile(fullName, dni, null);

      _ref.invalidate(currentUserProvider);
      _ref.invalidate(userProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepo.signOut();
      _ref.invalidate(currentUserProvider);
      _ref.invalidate(userProfileProvider);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userRepo = ref.watch(userRepositoryProvider);
  return AuthController(authRepo, userRepo, ref);
});
