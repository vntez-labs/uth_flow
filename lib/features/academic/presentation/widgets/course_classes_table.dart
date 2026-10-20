import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uth_flow/features/academic/domain/models/academic_models.dart';

class CourseClassesTable extends StatelessWidget {
  final List<AcademicCourse> courses;
  final List<Semester> semesters;
  final int? selectedSemesterId;
  final ValueChanged<int?> onSemesterChanged;

  const CourseClassesTable({
    super.key,
    required this.courses,
    required this.semesters,
    required this.selectedSemesterId,
    required this.onSemesterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentId = selectedSemesterId ?? (semesters.isNotEmpty ? semesters.first.id : null);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282724) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Tiêu đề "Lớp học phần"
          Padding(
            padding: const EdgeInsets.only(top: 18, left: 16, right: 16),
            child: Column(
              children: [
                Text(
                  'Lớp học phần',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF008689),
                  ),
                ),
                const SizedBox(height: 10),

                // Dropdown chọn học kỳ pill shaped
                if (semesters.isNotEmpty)
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF32302C) : const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: currentId,
                        isDense: true,
                        icon: const Icon(
                          SolarIconsOutline.altArrowDown,
                          size: 14,
                          color: Color(0xFF0284C7),
                        ),
                        dropdownColor: isDark ? const Color(0xFF282724) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0369A1),
                        ),
                        onChanged: onSemesterChanged,
                        items: semesters.map((sem) {
                          return DropdownMenuItem<int>(
                            value: sem.id,
                            child: Text(
                              sem.tenDot,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),

          // 2. Tiêu đề cột Table: "Môn học" | "Tín chỉ"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : const Color(0xFFFAFAF8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Môn học',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF333333),
                    ),
                  ),
                ),
                Text(
                  'Tín chỉ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.03),
          ),

          // 3. Danh sách hàng môn học
          if (courses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Không có lớp học phần nào trong học kỳ này',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12.5,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < courses.length; i++) ...[
                  _buildCourseRow(
                    context,
                    courses[i],
                    isDark,
                    isEven: i % 2 == 1,
                    isLast: i == courses.length - 1,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _openCourseLms(BuildContext context, AcademicCourse course) async {
    final uri = Uri.parse(course.courseLmsUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở trang courses: ${course.courseLmsUrl}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kết nối đến courses.ut.edu.vn'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildCourseRow(
    BuildContext context,
    AcademicCourse course,
    bool isDark, {
    required bool isEven,
    required bool isLast,
  }) {
    final rowBg = isEven
        ? (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8F8F6))
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openCourseLms(context, course),
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(20))
            : BorderRadius.zero,
        child: Container(
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(20))
                : BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Tên môn học + mã môn
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.tenMonHoc,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF191919),
                      ),
                    ),
                    if (course.maHocPhan.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            course.maHocPhan,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF008689)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Courses',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF008689),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  SolarIconsOutline.arrowRightUp,
                                  size: 10,
                                  color: Color(0xFF008689),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Tín chỉ (và điểm nếu có)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (course.hasGrade) ...[
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: course.gpaInfo.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${course.diemTongKet!.toStringAsFixed(1)} (${course.gpaInfo.letter})',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: course.gpaInfo.color,
                        ),
                      ),
                    ),
                  ],
                  Text(
                    '${course.soTinChi}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF191919),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
