import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_flow/features/academic/domain/models/academic_models.dart';
import 'package:uth_flow/features/academic/presentation/widgets/course_classes_table.dart';
import 'package:uth_flow/features/academic/presentation/widgets/grades_bar_chart.dart';
import 'package:uth_flow/features/academic/presentation/widgets/progress_donut_chart.dart';

void main() {
  testWidgets('Renders ProgressDonutChart accurately', (tester) async {
    const progress = AcademicProgress(canDat: 120, hienTai: 32);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProgressDonutChart(progress: progress),
        ),
      ),
    );

    expect(find.text('Tiến độ học tập'), findsOneWidget);
    expect(find.text('Đã đạt: 32/120'), findsOneWidget);
    expect(find.text('Tín chỉ'), findsOneWidget);
  });

  testWidgets('Renders GradesBarChart accurately', (tester) async {
    const courses = [
      AcademicCourse(
        tenMonHoc: 'Hệ điều hành',
        maHocPhan: 'IT001',
        soTinChi: 3,
        diemTongKet: 4.4,
      ),
      AcademicCourse(
        tenMonHoc: 'Công nghệ phần mềm',
        maHocPhan: 'IT004',
        soTinChi: 3,
        diemTongKet: 7.9,
      ),
    ];

    const semesters = [
      Semester(id: 1, tenDot: 'Học kỳ 2 năm học 2025-2026'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradesBarChart(
            courses: courses,
            semesters: semesters,
            selectedSemesterId: 1,
            onSemesterChanged: (_) {},
            semesterGpa: (gpa4: 3.2, gpa10: 7.8, credits: 6, rank: 'Giỏi'),
          ),
        ),
      ),
    );

    expect(find.text('Kết quả học tập'), findsOneWidget);
    expect(find.text('Điểm tổng kết môn của bạn'), findsOneWidget);
    expect(find.text('4.4'), findsOneWidget);
    expect(find.text('7.9'), findsOneWidget);
  });

  testWidgets('Renders CourseClassesTable accurately', (tester) async {
    const courses = [
      AcademicCourse(
        tenMonHoc: 'Hệ điều hành',
        maHocPhan: 'IT001',
        soTinChi: 3,
        diemTongKet: 4.4,
      ),
      AcademicCourse(
        tenMonHoc: 'Công nghệ phần mềm',
        maHocPhan: 'IT004',
        soTinChi: 3,
        diemTongKet: 7.9,
      ),
    ];

    const semesters = [
      Semester(id: 1, tenDot: 'Học kỳ 1 năm học 2026-2027'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourseClassesTable(
            courses: courses,
            semesters: semesters,
            selectedSemesterId: 1,
            onSemesterChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Lớp học phần'), findsOneWidget);
    expect(find.text('Môn học'), findsOneWidget);
    expect(find.text('Tín chỉ'), findsWidgets);
    expect(find.text('Hệ điều hành'), findsOneWidget);
    expect(find.text('Công nghệ phần mềm'), findsOneWidget);
  });
}
