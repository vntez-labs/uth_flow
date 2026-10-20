import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:uth_flow/features/academic/domain/models/academic_models.dart';

class GradesBarChart extends StatelessWidget {
  final List<AcademicCourse> courses;
  final List<Semester> semesters;
  final int? selectedSemesterId;
  final ValueChanged<int?> onSemesterChanged;
  final ({double gpa4, double gpa10, int credits, String rank})? semesterGpa;

  const GradesBarChart({
    super.key,
    required this.courses,
    required this.semesters,
    required this.selectedSemesterId,
    required this.onSemesterChanged,
    this.semesterGpa,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradedCourses = courses.where((c) => c.diemTongKet != null).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Tiêu đề + Dropdown Học kỳ (đảm bảo Expanded chống overflow)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Kết quả học tập',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF008689),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildSemesterDropdown(context, isDark),
            ],
          ),

          if (semesterGpa != null && semesterGpa!.credits > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    SolarIconsOutline.diploma,
                    size: 14,
                    color: Color(0xFF4F46E5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GPA Học kỳ: ${semesterGpa!.gpa4.toStringAsFixed(2)} / 4.0 (${semesterGpa!.rank})',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 2. Bar Chart vẽ chuẩn trục 0 - 10 không bị cắt chữ số
          if (gradedCourses.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Text(
                'Chưa có dữ liệu điểm cho học kỳ này',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            )
          else
            _buildChartArea(context, gradedCourses, isDark),

          const SizedBox(height: 12),

          // 3. Chú thích Legend: "Điểm tổng kết môn của bạn"
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6E4A),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Điểm tổng kết môn của bạn',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterDropdown(BuildContext context, bool isDark) {
    if (semesters.isEmpty) return const SizedBox.shrink();

    final currentId = selectedSemesterId ?? semesters.first.id;

    return Container(
      height: 32,
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF32302C) : const Color(0xFFF6F5F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: currentId,
          isDense: true,
          isExpanded: true,
          icon: Icon(
            SolarIconsOutline.altArrowDown,
            size: 13,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          dropdownColor: isDark ? const Color(0xFF282724) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.beVietnamPro(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF191919),
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
    );
  }

  Widget _buildChartArea(
    BuildContext context,
    List<AcademicCourse> courses,
    bool isDark,
  ) {
    const double plotHeight = 135.0; // Chiều cao đồ thị từ baseline 0 tới đỉnh 10
    const double labelHeight = 26.0; // Chiều cao nhãn tên môn phía dưới
    const ySteps = [10, 8, 6, 4, 2, 0];

    return SizedBox(
      height: plotHeight + labelHeight + 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trục Y (10, 8, 6, 4, 2, 0)
          SizedBox(
            width: 20,
            height: plotHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final step in ySteps)
                  Text(
                    '$step',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Vùng vẽ đồ thị: Lưới ngang + Các cột điểm + Nhãn tên bên dưới
          Expanded(
            child: Column(
              children: [
                // 1. Plot area (chứa đường lưới ngang và các cột)
                SizedBox(
                  height: plotHeight,
                  child: Stack(
                    children: [
                      // Các đường lưới ngang (Grid lines)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (int i = 0; i < ySteps.length; i++) ...[
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ],
                        ],
                      ),

                      // Các cột điểm
                      Positioned.fill(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: courses.map((c) {
                            final score = c.diemTongKet ?? 0.0;
                            // Chiều cao cột tối đa 105px để luôn chừa 30px phía trên cho số điểm
                            const maxBarHeight = plotHeight - 32.0;
                            final barHeight = (score / 10.0).clamp(0.0, 1.0) * maxBarHeight;

                            return Tooltip(
                              message: '${c.tenMonHoc}\nĐiểm: $score',
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Điểm số phía trên đỉnh cột
                                  Text(
                                    score.toStringAsFixed(1),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFF5252),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Thân cột màu coral
                                  Container(
                                    width: 24,
                                    height: barHeight,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF6E4A),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 2. Nhãn tên viết tắt bên dưới đường đáy 0
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: courses.map((c) {
                    final shortName = _getCourseShortName(c.tenMonHoc);
                    return SizedBox(
                      width: 36,
                      child: Text(
                        shortName,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCourseShortName(String fullName) {
    final words = fullName.trim().split(RegExp(r'\s+'));
    if (words.length <= 2) return fullName;
    final initials = words.map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join('');
    if (initials.length > 5) return initials.substring(0, 5);
    return initials;
  }
}
