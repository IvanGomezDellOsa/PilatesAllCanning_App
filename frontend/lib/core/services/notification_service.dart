import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_repository.dart';
import '../../core/providers/providers.dart';

/// Servicio encargado de manejar Push Notifications (FCM).
/// Se encarga de pedir permisos, obtener el token y escuchar mensajes.
class NotificationService {
  final UserRepository _userRepository;
  final Ref _ref;

  NotificationService(this._userRepository, this._ref);

  /// Inicializa el servicio. Debe llamarse al inicio de la app (ej: main o provider init).
  Future<void> init() async {
    if (kIsWeb) return; // No implementado para Web

    try {
      // 1. Pedir Permisos
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Intentar sync inicial (puede fallar si no hay user logueado, se reintenta en login)
        syncToken();

        // 3. Escuchar refrescos de Token
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          debugPrint('[FCM] Token Refreshed: $newToken');
          _saveTokenToBackend(newToken);
        });

        // 4. Configurar Handlers de Mensajes
        _setupMessageHandlers();
      }
    } catch (e) {
      debugPrint('[FCM] Error initializing: $e');
    }
  }

  /// Público: Fuerza la sincronización del token (ej: al loguearse)
  Future<void> syncToken() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('[FCM] Syncing Token: $token');
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('[FCM] Error syncing token: $e');
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      await _userRepository.updateFcmToken(token);
    } catch (e) {
      // Es normal que falle 401 si no está logueado al inicio
      debugPrint('[FCM] Error saving token to backend (Auth?): $e');
    }
  }

  /// Limpia el token (Logout)
  Future<void> deleteToken() async {
    if (kIsWeb) return;
    try {
      // 1. Avisar al backend que borre el token de este user
      await _userRepository.updateFcmToken(null);
      // 2. Borrar localmente
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('[FCM] Error deleting token: $e');
    }
  }

  void _setupMessageHandlers() {
    // FOREGROUND: La app está abierta
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground Message: ${message.notification?.title}');

      // Opcional: Mostrar un snackbar o dialog custom si se desea
      // Por defecto no muestra notificación de sistema en foreground en Android.
      // Si queremos mostrar algo visual, podemos usar un StateNotifier o Stream.

      if (message.notification != null) {
        // Refresh announcements list to update badge count
        debugPrint(
            '[FCM] Refreshing announcements due to foreground message...');
        _ref.invalidate(announcementsProvider);
      }
    });

    // BACKGROUND / TERMINATED (On Open): Al tocar la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Message Opened App: ${message.data}');
      _handleNavigation(message);
    });

    // Check if app was opened from terminated state by a notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('[FCM] Initial Message: ${message.data}');
        _handleNavigation(message);
      }
    });
  }

  void _handleNavigation(RemoteMessage message) {
    // Logic to handle tapping on notification.
    // Currently relying on default behavior (opening app).
    // Future: Use a global navigator key or router to redirect to specific screens.
    final data = message.data;
    if (data['type'] == 'announcement') {
      debugPrint('[FCM] Announcement notification tapped.');
    }
  }
}
