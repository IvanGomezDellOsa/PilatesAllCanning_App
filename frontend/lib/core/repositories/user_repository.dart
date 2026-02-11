// USER_REPOSITORY.DART
// --------------------
// Abstracción para operaciones de usuarios.
//
// Proporciona:
// - Consulta de perfiles (propio y de otros).
// - Búsqueda paginada de usuarios (Admin).
// - Actualización de datos (perfil, créditos, certificado médico).
// - Toggle de estados (disabled, trial, admin).
//
import 'package:file_picker/file_picker.dart';
import '../../models/user.dart';
import 'auth_repository.dart';

abstract class UserRepository {
  Future<UserProfile> getProfile();
  Future<List<User>> searchUsers({String? query, int skip = 0, int limit = 20});
  Future<UserProfile> getUserDetail(String userId);
  Future<void> updateProfile(String fullName, String? dni, String? phone);
  Future<void> updateUserDetails(String userId,
      {String? email, String? fullName, String? dni, String? phone});
  Future<void> toggleDisabled(String userId);
  Future<void> toggleInstructor(String userId);
  Future<void> toggleAdmin(String userId);
  Future<void> toggleTrial(String userId);
  Future<void> addCredits(String userId, int amount, DateTime? expiresAt);
  Future<String> uploadMedicalCertificate(
      PlatformFile file); // Nuevo: Apto Físico
  Future<void> deleteAccount();
  Future<void> updateFcmToken(String? token);
  Future<void> sendFeedback(String sentiment, String? message);
}

class MockUserRepository implements UserRepository {
  // 1. HACEMOS LA LISTA ESTÁTICA Y MUTABLE (Para que guarde los cambios en memoria)
  static final List<User> _mockUsers = [
    const User(
      id: 'u1',
      email: 'maria.g@gmail.com',
      fullName: 'María González',
      dni: '30123456',
      creditsAvailable: 2,
      isAdmin: false,
      disabled: false,
      medicalCertificateUrl:
          'https://via.placeholder.com/600x800.png?text=Apto+Fisico+Demo',
    ),
    const User(
      id: 'u2',
      email: 'juan.perez@live.com',
      fullName: 'Juan Pérez',
      dni: '20987654',
      creditsAvailable: 0,
      isAdmin: false,
      disabled: true,
    ),
    const User(
      id: 'u3',
      email: 'laura.instructor@pilates.com',
      fullName: 'Laura Fernández',
      dni: '25456789',
      creditsAvailable: 999,
      isAdmin: false,
      disabled: false,
    ),
    const User(
      id: 'u4',
      email: 'cliente.nuevo@test.com',
      fullName: 'Sofía Gonzalez',
      dni: '40111222',
      creditsAvailable: 8,
      isAdmin: false,
      disabled: false,
    ),
  ];

  @override
  Future<UserProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final current = MockAuthRepository.inMemoryUser;

    if (current == null) throw Exception("No user logged in");

    return UserProfile(
      email: current.email,
      fullName: current.fullName,
      dni: current.dni,
      creditsAvailable: current.creditsAvailable,
      isAdmin: current.isAdmin,
    );
  }

  @override
  Future<List<User>> searchUsers(
      {String? query, int skip = 0, int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    var results = _mockUsers;

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results
          .where((u) =>
              (u.fullName?.toLowerCase().contains(q) ?? false) ||
              (u.dni?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    final start = skip;
    if (start >= results.length) return [];

    final end =
        (start + limit < results.length) ? start + limit : results.length;
    return results.sublist(start, end);
  }

  @override
  Future<UserProfile> getUserDetail(String userId) async =>
      throw UnimplementedError();

  @override
  Future<void> updateProfile(
      String fullName, String? dni, String? phone) async {
    await Future.delayed(const Duration(seconds: 1));
    final current = MockAuthRepository.inMemoryUser;

    if (current != null) {
      MockAuthRepository.inMemoryUser = current.copyWith(
        fullName: fullName,
        dni: dni,
        phone: phone,
      );
    }
  }

  @override
  Future<void> toggleDisabled(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Lógica para actualizar el mock
    final index = _mockUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _mockUsers[index];
      _mockUsers[index] = user.copyWith(disabled: !user.disabled);
    }
  }

  @override
  Future<void> toggleInstructor(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Aquí podrías agregar lógica si tu modelo User tuviera un campo isInstructor
  }

  @override
  Future<void> updateUserDetails(String userId,
      {String? email, String? fullName, String? dni, String? phone}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      var user = _mockUsers[index];
      _mockUsers[index] = user.copyWith(
        email: email ?? user.email,
        fullName: fullName ?? user.fullName,
        dni: dni ?? user.dni,
        phone: phone ?? user.phone,
      );
    }
  }

  @override
  Future<void> toggleAdmin(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> toggleTrial(String userId) async {}

  // 2. LÓGICA REAL PARA SUMAR CRÉDITOS EN EL MOCK
  @override
  Future<void> addCredits(
      String userId, int amount, DateTime? expiresAt) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Buscamos al usuario en la lista estática
    final index = _mockUsers.indexWhere((u) => u.id == userId);

    if (index != -1) {
      final oldUser = _mockUsers[index];
      // Actualizamos sus créditos
      final newCredits = oldUser.creditsAvailable + amount;

      // Guardamos el usuario actualizado en la lista
      _mockUsers[index] = oldUser.copyWith(
        creditsAvailable: newCredits < 0 ? 0 : newCredits, // Evitamos negativos
      );
    }
  }

  @override
  @override
  Future<String> uploadMedicalCertificate(PlatformFile file) async {
    await Future.delayed(const Duration(seconds: 2)); // Simula carga

    // 1. URL Fake simulada (en backend real sería: http://.../static/uploads/x.jpg)
    const fakeUrl =
        'https://via.placeholder.com/600x800.png?text=Certificado+Medico';

    // 2. Actualizar usuario en memoria
    final current = MockAuthRepository.inMemoryUser;
    if (current != null) {
      MockAuthRepository.inMemoryUser = current.copyWith(
        medicalCertificateUrl: fakeUrl,
      );
    }

    return fakeUrl;
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(const Duration(seconds: 1));
    MockAuthRepository.inMemoryUser = null;
  }

  @override
  Future<void> updateFcmToken(String? token) async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> sendFeedback(String sentiment, String? message) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock feedback submission
  }
}
