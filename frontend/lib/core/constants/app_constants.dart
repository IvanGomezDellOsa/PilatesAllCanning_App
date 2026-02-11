// APP_CONSTANTS.DART
// -------------------
// Constantes globales de la aplicación.
//
// Incluye:
// - URL del backend (configurable por plataforma: Web vs Android).
// - Lista de feriados (para lógica de clases recurrentes).
//
import 'package:flutter/foundation.dart';

class AppConstants {
  static String get apiBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    // Para Android Emulator
    // return 'http://10.0.2.2:8000';
    // Para Dispositivo Físico (sin tunnel)
    return 'http://127.0.0.1:8000'; // Requiere 'adb reverse tcp:8000 tcp:8000'
  }

  static const Set<String> holidays2026 = {
    '2026-01-01',
    '2026-02-16',
    '2026-02-17',
    '2026-03-24',
    '2026-04-02',
    '2026-04-03',
    '2026-05-01',
    '2026-05-25',
    '2026-06-20',
    '2026-07-09',
    '2026-12-08',
    '2026-12-25',
  };
}
