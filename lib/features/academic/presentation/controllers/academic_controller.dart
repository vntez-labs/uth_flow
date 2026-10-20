import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/features/academic/data/repositories/academic_repository.dart';
import 'package:uth_flow/features/academic/domain/models/academic_models.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';

export 'package:uth_flow/features/academic/data/repositories/academic_repository.dart'
    show academicRepositoryProvider;

/// Notifier quản lý học kỳ đang được chọn
class SelectedSemesterNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? id) => state = id;
}

/// Provider học kỳ đang được chọn
final selectedSemesterProvider =
    NotifierProvider<SelectedSemesterNotifier, int?>(
  SelectedSemesterNotifier.new,
);

/// Tiến độ học tập (canDat, hienTai)
final academicProgressProvider =
    FutureProvider.autoDispose<AcademicProgress>((ref) async {
  final token = ref.watch(authTokenProvider) ?? '';
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getAcademicProgress(token);
});

/// Danh sách tất cả học kỳ
final academicSemestersProvider =
    FutureProvider.autoDispose<List<Semester>>((ref) async {
  final token = ref.watch(authTokenProvider) ?? '';
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getSemesters(token);
});

/// Danh sách môn học và điểm số theo học kỳ được chọn
final academicCoursesProvider =
    FutureProvider.autoDispose<List<AcademicCourse>>((ref) async {
  final token = ref.watch(authTokenProvider) ?? '';
  final semesters = await ref.watch(academicSemestersProvider.future);
  if (semesters.isEmpty) {
    return AcademicRepositoryImpl.fallbackCourses;
  }

  final selectedId =
      ref.watch(selectedSemesterProvider) ?? semesters.first.id;

  final repository = ref.watch(academicRepositoryProvider);
  return repository.getCoursesBySemester(
    token: token,
    semesterId: selectedId,
  );
});

/// GPA học kỳ hiện tại (hệ 4.0 và hệ 10)
final semesterGpaProvider = Provider.autoDispose<
    ({double gpa4, double gpa10, int credits, String rank})>((ref) {
  final coursesAsync = ref.watch(academicCoursesProvider);
  final List<AcademicCourse> courses =
      coursesAsync.asData?.value ?? AcademicRepositoryImpl.fallbackCourses;

  final repository = ref.watch(academicRepositoryProvider);
  return repository.calculateSemesterGpa(courses);
});

/// GPA tích lũy tổng thể toàn khóa
final cumulativeGpaProvider = FutureProvider.autoDispose<
    ({double gpa4, double gpa10, int credits, String rank})>((ref) async {
  final token = ref.watch(authTokenProvider) ?? '';
  final repository = ref.watch(academicRepositoryProvider);
  return repository.getCumulativeGpa(token);
});
