import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../models/user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Dio _dio;

  FirebaseAuthRepository(this._dio);

  // Helper: Transforma un User de Firebase a nuestro modelo User (Solo visual/fallback)
  User? _mapFirebaseUser(firebase.User? firebaseUser) {
    if (firebaseUser == null) return null;
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      fullName: firebaseUser.displayName,
      creditsAvailable: 0,
      isAdmin: false,
    );
  }

  Future<User?> _fetchBackendUser(firebase.User firebaseUser) async {
    try {
      final idToken = await firebaseUser.getIdToken();
      final response =
          await _dio.post('/auth/login', data: {'id_token': idToken});
      return User.fromJson(response.data);
    } catch (e) {
      debugPrint(
          "AUTH_DEBUG: Error deserializing/fetching user from backend: $e");
      try {
        final idToken = await firebaseUser.getIdToken();
        final response =
            await _dio.post('/auth/login', data: {'id_token': idToken});
        debugPrint("AUTH_DEBUG: RAW JSON RESPONSE: ${response.data}");
      } catch (e2) {
        debugPrint("AUTH_DEBUG: Could not re-fetch for debug logging: $e2");
      }
      return null;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      debugPrint("AUTH_DEBUG: No Firebase user found.");
      return null;
    }
    debugPrint(
        "AUTH_DEBUG: Firebase user found: ${firebaseUser.email}. Fetching backend profile...");

    // Intentar obtener el usuario completo del backend
    final backendUser = await _fetchBackendUser(firebaseUser);
    if (backendUser != null) {
      debugPrint(
          "AUTH_DEBUG: Backend user loaded: ${backendUser.email}, DNI: ${backendUser.dni}");
      return backendUser;
    }

    debugPrint(
        "AUTH_DEBUG: Backend fetch failed or null. Using fallback Firebase user (No DNI).");
    return _mapFirebaseUser(firebaseUser);
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      // 1. Iniciar flujo Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Inicio de sesión cancelado');
      }

      // 2. Auth Tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final firebase.OAuthCredential credential =
          firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Login Firebase
      final firebase.UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Error en Firebase Auth');
      }

      // 4. Login Backend (Obtener perfil real)
      final backendUser = await _fetchBackendUser(firebaseUser);
      if (backendUser == null) {
        throw Exception(
            'No se pudo conectar con el servidor para obtener el perfil.');
      }

      return backendUser;
    } catch (e) {
      // debugPrint(e);
      throw Exception('Error en Login: $e');
    }
  }

  @override
  Future<void> signOut() async {
    // Limpiar FCM Token
    try {
      await _dio.patch('/auth/me/fcm-token', data: {'token': null});
    } catch (e) {
      debugPrint("[AUTH] Error clearing FCM token: $e");
    }

    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> revokeAccess() async {
    try {
      await _dio.patch('/auth/me/fcm-token', data: {'token': null});
    } catch (e) {
      debugPrint("[AUTH] Error clearing FCM token: $e");
    }

    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        await _googleSignIn.disconnect();
      }
    } catch (e) {
      debugPrint("AUTH_DEBUG: Error disconnecting Google: $e");
    }
    await _auth.signOut();
  }

  @override
  Stream<User?> authStateChanges() {
    // Nota: Este stream sigue emitiendo el usuario básico de Firebase inmediato.
    // Para datos actualizados, la UI recarga al entrar.
    return _auth.authStateChanges().map(_mapFirebaseUser);
  }
}
