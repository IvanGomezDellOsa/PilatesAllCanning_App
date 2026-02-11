// SETTINGS_REPOSITORY.DART
// -------------------------
// Abstracción para configuración global de la app.
//
// Métodos:
// - `getSettings()`: Obtiene configuración (pausa, tiempo de cancelación, etc).
// - `updateSetting(key, value)`: Actualiza un valor.
//
import 'package:dio/dio.dart';
import '../../models/settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateSetting(String key, String value);
}

// Mock Implementation (Optional but redundant now)
class MockSettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> getSettings() async => const AppSettings();
  @override
  Future<void> updateSetting(String key, String value) async {}
}

class HttpSettingsRepository implements SettingsRepository {
  final Dio _dio;
  HttpSettingsRepository(this._dio);

  @override
  Future<AppSettings> getSettings() async {
    final response = await _dio.get('/settings');
    // Ensure response.data is Map<String, dynamic> and values are Strings (publicEP returns Dict[str, str])
    // But Dio might parse json numbers as int/double.
    // AppSettings.fromDict expects Map<String, String>.
    // So we need to convert values to String safely.
    final data = response.data as Map<String, dynamic>;
    final stringMap = data.map((key, value) => MapEntry(key, value.toString()));
    return AppSettings.fromDict(stringMap);
  }

  @override
  Future<void> updateSetting(String key, String value) async {
    await _dio.patch('/settings/$key', data: {'value': value});
  }
}
