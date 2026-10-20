import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/features/academic/domain/models/academic_models.dart';
import 'package:uth_flow/features/auth/data/repositories/auth_repository.dart';
import 'package:uth_flow/features/auth/data/services/uth_portal_service.dart';

typedef GpaSummary = ({double gpa4, double gpa10, int credits, String rank});

abstract class AcademicRepository {
  Future<AcademicProgress> getAcademicProgress(String token);
  Future<List<Semester>> getSemesters(String token);
  Future<List<AcademicCourse>> getCoursesBySemester({
    required String token,
    required int semesterId,
  });
  Future<GpaSummary> getCumulativeGpa(String token);
  GpaSummary calculateSemesterGpa(List<AcademicCourse> courses);
}

class AcademicRepositoryImpl implements AcademicRepository {
  final UthPortalService _portalService;
  final AuthRepository _authRepository;

  AcademicRepositoryImpl({
    required this._portalService,
    required this._authRepository,
  });

  static const fallbackSemesters = [
    Semester(id: 101, tenDot: 'Học kỳ 2 năm học 2025-2026'),
    Semester(id: 102, tenDot: 'Học kỳ 1 năm học 2026-2027'),
    Semester(id: 100, tenDot: 'Học kỳ 1 năm học 2025-2026'),
  ];

  static const fallbackCourses = [
    AcademicCourse(
      tenMonHoc: 'Hệ điều hành',
      maHocPhan: 'IT001',
      soTinChi: 3,
      diemTongKet: 4.4,
    ),
    AcademicCourse(
      tenMonHoc: 'Tư duy thiết kế và đổi mới sáng tạo',
      maHocPhan: 'GE002',
      soTinChi: 3,
      diemTongKet: 5.9,
    ),
    AcademicCourse(
      tenMonHoc: 'Quản trị dự án CNTT',
      maHocPhan: 'IT003',
      soTinChi: 3,
      diemTongKet: 6.7,
    ),
    AcademicCourse(
      tenMonHoc: 'Công nghệ phần mềm',
      maHocPhan: 'IT004',
      soTinChi: 3,
      diemTongKet: 7.9,
    ),
    AcademicCourse(
      tenMonHoc: 'Cấu trúc dữ liệu và giải thuật',
      maHocPhan: 'IT005',
      soTinChi: 3,
      diemTongKet: 4.5,
    ),
    AcademicCourse(
      tenMonHoc: 'Lập trình ứng dụng di động',
      maHocPhan: 'IT006',
      soTinChi: 3,
      diemTongKet: 7.3,
    ),
  ];

  static const fallbackCumulativeGpa = (
    gpa4: 2.80,
    gpa10: 7.16,
    credits: 32,
    rank: 'Khá',
  );

  Future<T> _executeWithRetry<T>({
    required String token,
    required Future<T> Function(String tk) action,
    required T fallback,
  }) async {
    try {
      return await action(token);
    } catch (e) {
      if (e.toString().contains('401')) {
        final freshToken = await _authRepository.refreshToken();
        if (freshToken != null && freshToken.isNotEmpty) {
          try {
            return await action(freshToken);
          } catch (_) {}
        }
      }
      return fallback;
    }
  }

  @override
  Future<AcademicProgress> getAcademicProgress(String token) async {
    if (token.isEmpty) return AcademicProgress.fallback;

    return _executeWithRetry(
      token: token,
      action: (tk) => _portalService.getAcademicProgress(tk),
      fallback: AcademicProgress.fallback,
    );
  }

  @override
  Future<List<Semester>> getSemesters(String token) async {
    if (token.isEmpty) return fallbackSemesters;

    return _executeWithRetry(
      token: token,
      action: (tk) async {
        final list = await _portalService.getSemesters(tk);
        return list.isNotEmpty ? list : fallbackSemesters;
      },
      fallback: fallbackSemesters,
    );
  }

  @override
  Future<List<AcademicCourse>> getCoursesBySemester({
    required String token,
    required int semesterId,
  }) async {
    if (token.isEmpty) return fallbackCourses;

    return _executeWithRetry(
      token: token,
      action: (tk) async {
        final results = await Future.wait([
          _portalService.getCoursesBySemester(tk, semesterId),
          _portalService.getGradesBySemester(tk, semesterId),
        ]);
        final subjects = results[0] as List<CourseSubject>;
        final grades = results[1] as List<CourseGrade>;
        if (subjects.isEmpty && grades.isEmpty) return fallbackCourses;

        return subjects.map((sub) {
          CourseGrade? matchedGrade;
          for (final g in grades) {
            if (g.lopHocPhan == sub.tenMonHoc ||
                g.lopHocPhan.contains(sub.tenMonHoc) ||
                sub.tenMonHoc.contains(g.lopHocPhan)) {
              matchedGrade = g;
              break;
            }
          }
          return AcademicCourse(
            tenMonHoc: sub.tenMonHoc,
            maHocPhan: sub.maHocPhan,
            soTinChi: sub.soTinChi,
            diemTongKet: matchedGrade?.diemTongKet,
          );
        }).toList();
      },
      fallback: fallbackCourses,
    );
  }

  @override
  GpaSummary calculateSemesterGpa(List<AcademicCourse> courses) {
    final gradedCourses = courses
        .where((c) => c.diemTongKet != null && c.soTinChi > 0)
        .toList();
    if (gradedCourses.isEmpty) {
      return (gpa4: 0.0, gpa10: 0.0, credits: 0, rank: 'Chưa có');
    }

    int totalCredits = 0;
    double sumScore10 = 0.0;
    double sumScore4 = 0.0;

    for (final c in gradedCourses) {
      totalCredits += c.soTinChi;
      sumScore10 += (c.diemTongKet ?? 0.0) * c.soTinChi;
      sumScore4 += c.gpaInfo.gpa4 * c.soTinChi;
    }

    final gpa10 = totalCredits > 0 ? (sumScore10 / totalCredits) : 0.0;
    final gpa4 = totalCredits > 0 ? (sumScore4 / totalCredits) : 0.0;

    String rank = 'Trung bình';
    if (gpa4 >= 3.6) {
      rank = 'Xuất sắc';
    } else if (gpa4 >= 3.2) {
      rank = 'Giỏi';
    } else if (gpa4 >= 2.5) {
      rank = 'Khá';
    } else if (gpa4 >= 2.0) {
      rank = 'Trung bình';
    } else {
      rank = 'Yếu';
    }

    return (
      gpa4: double.parse(gpa4.toStringAsFixed(2)),
      gpa10: double.parse(gpa10.toStringAsFixed(2)),
      credits: totalCredits,
      rank: rank,
    );
  }

  @override
  Future<GpaSummary> getCumulativeGpa(String token) async {
    if (token.isEmpty) return fallbackCumulativeGpa;

    return _executeWithRetry(
      token: token,
      action: (tk) async {
        final transcript = await _portalService.getFullTranscript(tk);
        if (transcript.isEmpty) return fallbackCumulativeGpa;
        return _calculateCumulativeGpaFromTranscript(transcript);
      },
      fallback: fallbackCumulativeGpa,
    );
  }

  GpaSummary _calculateCumulativeGpaFromTranscript(
    List<Map<String, dynamic>> transcript,
  ) {
    if (transcript.isEmpty) return fallbackCumulativeGpa;

    int totalCredits = 0;
    double totalPts4 = 0.0;
    double totalPts10 = 0.0;

    for (final sem in transcript) {
      final diems = sem['diems'];
      if (diems is! List) continue;

      for (final rawD in diems) {
        if (rawD is! Map) continue;
        final isDat = rawD['isDat'] == true;
        if (!isDat) continue;

        final tc = (rawD['soTinChi'] as num?)?.toInt() ?? 0;
        if (tc <= 0) continue;

        final name = (rawD['tenMonHoc'] as String? ?? '').toLowerCase();
        // Loại trừ GDTC và GDQP-AN theo quy định đào tạo đại học
        const excludedKeywords = [
          'thể dục',
          'fitness',
          'quân sự',
          'quốc phòng',
          'an ninh',
          'chiến thuật',
        ];
        final isExcluded = excludedKeywords.any((kw) => name.contains(kw));
        if (isExcluded) continue;

        final d4 = (rawD['diemTinChi'] as num?)?.toDouble() ?? 0.0;
        final d10 = (rawD['diemTongKet'] as num?)?.toDouble() ?? 0.0;

        totalCredits += tc;
        totalPts4 += d4 * tc;
        totalPts10 += d10 * tc;
      }
    }

    if (totalCredits == 0) return fallbackCumulativeGpa;

    final gpa4 = totalPts4 / totalCredits;
    final gpa10 = totalPts10 / totalCredits;

    String rank = 'Trung bình';
    if (gpa4 >= 3.6) {
      rank = 'Xuất sắc';
    } else if (gpa4 >= 3.2) {
      rank = 'Giỏi';
    } else if (gpa4 >= 2.5) {
      rank = 'Khá';
    } else if (gpa4 >= 2.0) {
      rank = 'Trung bình';
    } else {
      rank = 'Yếu';
    }

    return (
      gpa4: double.parse(gpa4.toStringAsFixed(2)),
      gpa10: double.parse(gpa10.toStringAsFixed(2)),
      credits: totalCredits,
      rank: rank,
    );
  }
}

final academicRepositoryProvider = Provider<AcademicRepository>((ref) {
  final portalService = ref.watch(uthPortalServiceProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return AcademicRepositoryImpl(
    portalService: portalService,
    authRepository: authRepository,
  );
});
