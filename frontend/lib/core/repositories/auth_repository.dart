// AUTH_REPOSITORY.DART
// --------------------
// Abstracción para autenticación.
//
// Define la interfaz `AuthRepository` para:
// - Obtener usuario actual.
// - Login con Google/Apple.
// - Logout y revocación de acceso.
//
// Implementaciones: `MockAuthRepository` (dev), `FirebaseAuthRepository` (prod).
//
// lib/core/repositories/auth_repository.dart
import '../../models/user.dart'; // Asegúrate de que apunte a lib/models/user.dart

// 1. LA INTERFAZ (IMPORTANTE: No borrar esto)
abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> signInWithGoogle();
  Future<void> signOut();
  Future<void> revokeAccess();
  Stream<User?> authStateChanges();
}

// 2. LA IMPLEMENTACIÓN MOCK
class MockAuthRepository implements AuthRepository {
  // Variable estática compartida (Base de datos en memoria para el Onboarding)
  static User? inMemoryUser;

  // --- DATOS MOCK ---
  final _mockNewUser = const User(
    id: 'mock-user-new',
    email: 'nuevo@pilates.com',
    fullName: null, // Sin nombre -> Dispara Onboarding
    dni: null,
    creditsAvailable: 5,
    isAdmin: false,
  );

  @override
  Future<User?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return inMemoryUser;
  }

  @override
  Future<User> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));

    // PARA PROBAR: _mockNewUser, _mockExistingUser o _mockAdminUser
    inMemoryUser = _mockNewUser;

    return inMemoryUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    inMemoryUser = null;
  }

  @override
  Future<void> revokeAccess() async {
    await Future.delayed(const Duration(milliseconds: 300));
    inMemoryUser = null;
  }

  @override
  Stream<User?> authStateChanges() {
    return Stream.value(inMemoryUser);
  }
}
