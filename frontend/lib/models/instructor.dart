import 'package:freezed_annotation/freezed_annotation.dart';

part 'instructor.freezed.dart';
part 'instructor.g.dart';

@freezed
class Instructor with _$Instructor {
  const factory Instructor({
    required String id,
    required String name,
    @Default(true) bool isActive,
  }) = _Instructor;

  factory Instructor.fromJson(Map<String, dynamic> json) =>
      _$InstructorFromJson(json);
}
