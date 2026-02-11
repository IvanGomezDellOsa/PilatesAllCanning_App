import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:file_picker/file_picker.dart'; // PlatformFile
import 'package:dio/dio.dart';
import '../../models/user.dart';
import 'user_repository.dart';

class HttpUserRepository implements UserRepository {
  final Dio _dio;

  HttpUserRepository(this._dio);

  @override
  Future<UserProfile> getProfile() async {
    try {
      final response = await _dio.get('/me');
      return UserProfile.fromJson(response.data);
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  @override
  Future<List<User>> searchUsers(
      {String? query, int skip = 0, int limit = 20}) async {
    try {
      final response = await _dio.get('/users', queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        'skip': skip,
        'limit': limit,
      });
      return (response.data as List).map((e) => User.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  @override
  Future<UserProfile> getUserDetail(String userId) async {
    try {
      final _ = await _dio.get('/users/$userId');
      // final data = response.data; // Unused for now
      // Map nested response to UserProfile format if possible, or throw
      // Actually UserProfile is for /me.
      // We might need to return a User object or similar.
      // But the interface says Future<UserProfile>.
      // Let's coerce it for now or assume /me structure compatibility?
      // Backend /users/{id} returns {user: {...}, credits...}
      // This doesn't match UserProfile exactly.
      throw UnimplementedError('Detail view extraction not fully mapped yet');
    } catch (e) {
      throw Exception('Error fetching user detail: $e');
    }
  }

  @override
  Future<void> updateProfile(
      String fullName, String? dni, String? phone) async {
    try {
      await _dio.patch('/me', data: {
        'full_name': fullName,
        'dni': dni,
        'phone': phone,
      });
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data['detail'] != null) return Future.error(data['detail']);
          if (data['message'] != null) return Future.error(data['message']);
        }
        if (data is String) {
          return Future.error(data);
        }
      }
      throw 'Error al actualizar perfil: ${e.message}';
    } catch (e) {
      throw 'Error inesperado: $e';
    }
  }

  @override
  Future<void> toggleDisabled(String userId) async {
    await _dio.patch('/users/$userId/toggle-disabled');
  }

  @override
  Future<void> updateUserDetails(String userId,
      {String? email, String? fullName, String? dni, String? phone}) async {
    try {
      final payload = <String, dynamic>{};
      if (email != null) payload['email'] = email;
      if (fullName != null) payload['full_name'] = fullName;
      if (dni != null) payload['dni'] = dni;
      if (phone != null) payload['phone'] = phone;

      if (payload.isEmpty) return;

      await _dio.patch('/users/$userId/details', data: payload);
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data['detail'] != null) {
          throw Exception(data['detail']);
        }
      }
      throw Exception('Error updating user details: $e');
    }
  }

  @override
  Future<void> toggleAdmin(String userId) async {
    await _dio.patch('/users/$userId/toggle-admin');
  }

  @override
  Future<void> toggleTrial(String userId) async {
    await _dio.patch('/users/$userId/toggle-trial');
  }

  @override
  Future<void> toggleInstructor(String userId) async {
    await _dio.patch('/users/$userId/toggle-instructor');
  }

  @override
  Future<void> addCredits(
      String userId, int amount, DateTime? expiresAt) async {
    await _dio.post('/users/$userId/credits', data: {
      'amount': amount,
      'expires_at': expiresAt?.toIso8601String(),
    });
  }

  @override
  @override
  Future<String> uploadMedicalCertificate(PlatformFile file) async {
    MultipartFile multipartFile;

    if (kIsWeb) {
      if (file.bytes == null) {
        throw Exception("No file bytes available on web");
      }
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: file.name,
      );
    } else {
      if (file.path == null) {
        throw Exception("No file path available on device");
      }
      multipartFile = await MultipartFile.fromFile(file.path!);
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
    });
    final response = await _dio.post('/me/medical-certificate', data: formData);
    return response.data['url'];
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/me');
    } catch (e) {
      throw Exception('Error deleting account: $e');
    }
  }

  @override
  Future<void> updateFcmToken(String? token) async {
    try {
      await _dio.patch('/auth/me/fcm-token', data: {'token': token});
    } catch (e) {
      // Fail silently for token updates usually, or log debug
      debugPrint('Error updating FCM Token: $e');
    }
  }

  @override
  Future<void> sendFeedback(String sentiment, String? message) async {
    try {
      await _dio.post('/feedback', data: {
        'sentiment': sentiment,
        if (message != null) 'message': message,
      });
    } catch (e) {
      throw Exception('Error sending feedback: $e');
    }
  }
}
