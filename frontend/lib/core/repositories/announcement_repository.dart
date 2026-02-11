// ANNOUNCEMENT_REPOSITORY.DART
// -----------------------------
// Abstracción para operaciones de novedades/anuncios.
//
// Métodos:
// - `getAnnouncements()`: Lista de novedades activas.
// - `createAnnouncement(...)`: Crear con imagen y push opcional.
// - `deleteAnnouncement(id)`: Eliminar por ID.
//
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart'; // Necesario para PlatformFile
import 'package:http_parser/http_parser.dart'; // Para MediaType
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/announcement.dart';

// 1. EL CONTRATO (Abstract Class)
abstract class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncements();

  Future<Announcement> createAnnouncement({
    String? title, // Opcional
    String? content, // Opcional
    PlatformFile? imageFile,
    DateTime? expiresAt,
    bool sendPush = false,
  });

  Future<void> deleteAnnouncement(String id);
}

// 2. LA IMPLEMENTACIÓN (Http con Dio)
class HttpAnnouncementRepository implements AnnouncementRepository {
  final Dio _dio;

  HttpAnnouncementRepository(this._dio);

  @override
  Future<List<Announcement>> getAnnouncements() async {
    try {
      // Admin always gets ALL announcements (including expired/deleted)
      final response = await _dio.get(
        '/announcements',
        queryParameters: {
          'include_expired': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch, // Cache busting
        },
      );
      final List data = response.data;
      return data.map((json) => Announcement.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar novedades: $e');
    }
  }

  @override
  Future<Announcement> createAnnouncement({
    String? title,
    String? content,
    PlatformFile? imageFile,
    DateTime? expiresAt,
    bool sendPush = false,
  }) async {
    try {
      MultipartFile? multipartImage;

      if (imageFile != null) {
        // PROCESAR IMAGEN SEGÚN PLATAFORMA
        if (kIsWeb) {
          // En Web usamos bytes
          if (imageFile.bytes != null) {
            multipartImage = MultipartFile.fromBytes(
              imageFile.bytes!,
              filename: imageFile.name,
              contentType: MediaType('image', _getSubType(imageFile.name)),
            );
          }
        } else {
          // En Móvil/Desktop usamos path
          if (imageFile.path != null) {
            multipartImage = await MultipartFile.fromFile(
              imageFile.path!,
              filename: imageFile.name,
              contentType: MediaType('image', _getSubType(imageFile.path!)),
            );
          }
        }
      }

      final formData = FormData.fromMap({
        if (title != null && title.isNotEmpty) 'title': title,
        if (content != null && content.isNotEmpty) 'content': content,
        'send_push': sendPush,
        if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
        if (multipartImage != null) 'image_file': multipartImage,
      });

      final response = await _dio.post('/announcements', data: formData);
      return Announcement.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al crear novedad: $e');
    }
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    try {
      await _dio.delete('/announcements/$id');
    } catch (e) {
      throw Exception('Error al eliminar novedad: $e');
    }
  }

  String _getSubType(String pathOrName) {
    final lower = pathOrName.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpeg'; // default to jpeg for jpg/jpeg
  }
}
