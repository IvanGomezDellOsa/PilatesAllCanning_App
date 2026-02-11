// INSTRUCTOR_REPOSITORY.DART
// ---------------------------
// Abstracción para gestión de instructores.
//
// Métodos:
// - `getAllInstructors()`: Listado completo.
// - `createInstructor(name)`: Alta de instructor.
// - `deleteInstructor(id)`: Baja permanente.
//
import 'package:dio/dio.dart';
import '../../models/instructor.dart';

// Interface
abstract class InstructorRepository {
  Future<List<Instructor>> getAllInstructors();

  // Admin endpoints
  Future<Instructor> createInstructor(String name);
  Future<void> deleteInstructor(String instructorId);
  Future<void> toggleInstructorStatus(
      String
          instructorId); // Deprecated in UI but kept for now or removed if unused
}

// Mock Implementation
class MockInstructorRepository implements InstructorRepository {
  final List<Instructor> _mockInstructors = [
    const Instructor(
      id: 'instructor-1',
      name: 'Laura Fernández',
      isActive: true,
    ),
    const Instructor(
      id: 'instructor-2',
      name: 'Carolina Smith',
      isActive: true,
    ),
    const Instructor(
      id: 'instructor-3',
      name: 'Martín Gómez',
      isActive: true,
    ),
    const Instructor(
      id: 'instructor-4',
      name: 'Sofía Rodríguez',
      isActive: false,
    ),
  ];

  @override
  Future<List<Instructor>> getAllInstructors() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockInstructors;
  }

  @override
  Future<Instructor> createInstructor(String name) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final newInstructor = Instructor(
      id: 'instructor-new-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isActive: true,
    );

    _mockInstructors.add(newInstructor);
    return newInstructor;
  }

  @override
  Future<void> deleteInstructor(String instructorId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockInstructors.removeWhere((i) => i.id == instructorId);
  }

  @override
  Future<void> toggleInstructorStatus(String instructorId) async {
    // Deprecated
  }
}

class HttpInstructorRepository implements InstructorRepository {
  final Dio _dio;
  HttpInstructorRepository(this._dio);

  @override
  Future<List<Instructor>> getAllInstructors() async {
    final response = await _dio.get('/instructors');
    return (response.data as List).map((e) => Instructor.fromJson(e)).toList();
  }

  @override
  Future<Instructor> createInstructor(String name) async {
    final response = await _dio.post('/instructors', data: {'name': name});
    return Instructor.fromJson(response.data);
  }

  @override
  Future<void> deleteInstructor(String instructorId) async {
    await _dio.delete('/instructors/$instructorId');
  }

  @override
  Future<void> toggleInstructorStatus(String instructorId) async {
    // Endpoint removed in backend, this method is effectively dead
  }
}
