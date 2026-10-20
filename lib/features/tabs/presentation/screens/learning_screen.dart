import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:uth_flow/features/academic/domain/models/academic_models.dart';
import 'package:uth_flow/features/academic/presentation/controllers/academic_controller.dart';
import 'package:uth_flow/features/academic/presentation/widgets/course_classes_table.dart';
import 'package:uth_flow/features/academic/presentation/widgets/gpa_overview_card.dart';
import 'package:uth_flow/features/academic/presentation/widgets/grades_bar_chart.dart';
import 'package:uth_flow/features/academic/presentation/widgets/progress_donut_chart.dart';

class LearningScreen extends ConsumerWidget {
  const LearningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progressAsync = ref.watch(academicProgressProvider);
    final semestersAsync = ref.watch(academicSemestersProvider);
    final coursesAsync = ref.watch(academicCoursesProvider);
    final selectedSemesterId = ref.watch(selectedSemesterProvider);

    final semGpa = ref.watch(semesterGpaProvider);
    final cumGpaAsync = ref.watch(cumulativeGpaProvider);
    final cumGpa = cumGpaAsync.asData?.value ??
        const (
          gpa4: 2.80,
          gpa10: 7.16,
          credits: 32,
          rank: 'Khá',
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Học tập',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Nút làm mới dữ liệu
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(SolarIconsOutline.refresh, size: 22),
            onPressed: () {
              ref.invalidate(academicProgressProvider);
              ref.invalidate(academicSemestersProvider);
              ref.invalidate(academicCoursesProvider);
              ref.invalidate(cumulativeGpaProvider);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(academicProgressProvider);
          ref.invalidate(academicSemestersProvider);
          ref.invalidate(academicCoursesProvider);
          ref.invalidate(cumulativeGpaProvider);
          await ref.read(academicProgressProvider.future);
          await ref.read(academicCoursesProvider.future);
          await ref.read(cumulativeGpaProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CARD TỔNG QUAN GPA (TÍCH LŨY & HỌC KỲ)
              GpaOverviewCard(
                isDark: isDark,
                cumGpa: cumGpa,
                semGpa: semGpa,
              ),

              const SizedBox(height: 18),

              // 3. TIẾN ĐỘ HỌC TẬP (DONUT CHART NHƯ ẢNH UTH PORTAL)
              progressAsync.when(
                data: (progress) => ProgressDonutChart(progress: progress),
                loading: () => const ProgressDonutChart(
                  progress: AcademicProgress.fallback,
                ),
                error: (err, stack) => const ProgressDonutChart(
                  progress: AcademicProgress.fallback,
                ),
              ),

              const SizedBox(height: 18),

              // 4. KẾT QUẢ HỌC TẬP (BAR CHART THANG 0-10 NHƯ ẢNH UTH PORTAL)
              _buildGradesSection(
                ref,
                semestersAsync.asData?.value ?? const [
                  Semester(id: 101, tenDot: 'Học kỳ 2 năm học 2025-2026'),
                  Semester(id: 102, tenDot: 'Học kỳ 1 năm học 2026-2027'),
                ],
                coursesAsync,
                selectedSemesterId,
                semGpa,
              ),

              const SizedBox(height: 18),

              // 5. LỚP HỌC PHẦN (TABLE NHƯ ẢNH UTH PORTAL)
              _buildClassesSection(
                ref,
                semestersAsync.asData?.value ?? const [
                  Semester(id: 101, tenDot: 'Học kỳ 2 năm học 2025-2026'),
                  Semester(id: 102, tenDot: 'Học kỳ 1 năm học 2026-2027'),
                ],
                coursesAsync,
                selectedSemesterId,
              ),

              // Đệm đáy tránh bị che bởi thanh điều hướng nổi
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradesSection(
    WidgetRef ref,
    List<Semester> semesters,
    AsyncValue<List<AcademicCourse>> coursesAsync,
    int? selectedSemesterId,
    ({double gpa4, double gpa10, int credits, String rank}) semGpa,
  ) {
    final courses = coursesAsync.asData?.value ?? const [
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

    return GradesBarChart(
      courses: courses,
      semesters: semesters,
      selectedSemesterId: selectedSemesterId,
      onSemesterChanged: (val) {
        ref.read(selectedSemesterProvider.notifier).select(val);
      },
      semesterGpa: semGpa,
    );
  }

  Widget _buildClassesSection(
    WidgetRef ref,
    List<Semester> semesters,
    AsyncValue<List<AcademicCourse>> coursesAsync,
    int? selectedSemesterId,
  ) {
    final courses = coursesAsync.asData?.value ?? const [
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

    return CourseClassesTable(
      courses: courses,
      semesters: semesters,
      selectedSemesterId: selectedSemesterId,
      onSemesterChanged: (val) {
        ref.read(selectedSemesterProvider.notifier).select(val);
      },
    );
  }
}
