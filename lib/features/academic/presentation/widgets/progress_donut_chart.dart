import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uth_flow/features/academic/domain/models/academic_models.dart';

class ProgressDonutChart extends StatelessWidget {
  final AcademicProgress progress;

  const ProgressDonutChart({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          // Header tiêu đề "Tiến độ học tập"
          Text(
            'Tiến độ học tập',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF008689),
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 22),

          // Donut chart
          SizedBox(
            width: 175,
            height: 175,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(175, 175),
                  painter: _DonutChartPainter(
                    ratio: progress.canDat > 0
                        ? (progress.hienTai / progress.canDat).clamp(0.0, 1.0)
                        : 0.0,
                    isDark: isDark,
                  ),
                ),
                // Text chính giữa: "Đã đạt: 32/120"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đã đạt: ${progress.hienTai}/${progress.canDat}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF191919),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tín chỉ',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Footer thông số tỷ lệ hoàn thành
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF008689).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: Color(0xFF008689),
                ),
                const SizedBox(width: 6),
                Text(
                  'Hoàn thành ${progress.percentage.toStringAsFixed(1)}% chương trình',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF4DD0E1) : const Color(0xFF007376),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double ratio;
  final bool isDark;

  _DonutChartPainter({
    required this.ratio,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.width / 2) - 6;
    const outerStrokeWidth = 10.0;

    // 1. Vòng ngoài (Sky Blue ring)
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerStrokeWidth
      ..color = const Color(0xFF38B6FF);

    canvas.drawCircle(center, outerRadius, outerPaint);

    // 2. Vòng trong: Track nền xám
    final innerRadius = outerRadius - 13.0;
    const innerStrokeWidth = 11.0;

    final innerBgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerStrokeWidth
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : const Color(0xFFE2E4E8);

    canvas.drawCircle(center, innerRadius, innerBgPaint);

    // 3. Vòng trong: Phần tiến độ màu xanh lá cây (#2ECC71 / #10B981)
    if (ratio > 0.0) {
      final innerProgressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerStrokeWidth
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF2ECC71);

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * ratio;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepAngle,
        false,
        innerProgressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.isDark != isDark;
  }
}
