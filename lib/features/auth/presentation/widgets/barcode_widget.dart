import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BarcodeWidget extends StatelessWidget {
  final String code;
  final double height;
  final double? width;
  final bool showText;
  final Color barColor;
  final Color backgroundColor;

  const BarcodeWidget({
    super.key,
    required this.code,
    this.height = 70,
    this.width,
    this.showText = true,
    this.barColor = Colors.black,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final cleanCode = code.trim().isEmpty ? '074207005137' : code.trim();

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(width ?? double.infinity, height),
            painter: _BarcodePainter(
              code: cleanCode,
              color: barColor,
            ),
          ),
          if (showText) ...[
            const SizedBox(height: 6),
            Text(
              cleanCode,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: barColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final String code;
  final Color color;

  _BarcodePainter({
    required this.code,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Chuyển chuỗi mã thành mảng độ rộng vạch mô phỏng chuẩn Code 128
    final barPattern = _generatePattern(code);
    final totalUnits = barPattern.fold<int>(0, (prev, val) => prev + val);
    final unitWidth = size.width / totalUnits;

    double currentX = 0;
    bool isBar = true;

    for (final widthUnits in barPattern) {
      final barW = widthUnits * unitWidth;
      if (isBar) {
        canvas.drawRect(
          Rect.fromLTWH(currentX, 0, barW, size.height),
          paint,
        );
      }
      currentX += barW;
      isBar = !isBar;
    }
  }

  List<int> _generatePattern(String text) {
    // Start guard
    final pattern = <int>[2, 1, 1, 2];

    for (int i = 0; i < text.length; i++) {
      final charCode = text.codeUnitAt(i);
      // Mô phỏng 4 vạch & 4 khoảng trống dựa trên hash ký tự
      final b1 = (charCode % 3) + 1;
      final s1 = ((charCode ~/ 3) % 2) + 1;
      final b2 = ((charCode ~/ 2) % 3) + 1;
      final s2 = ((charCode ~/ 4) % 2) + 1;
      pattern.addAll([b1, s1, b2, s2]);
    }

    // Stop guard
    pattern.addAll([2, 1, 2, 2, 2]);
    return pattern;
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) {
    return oldDelegate.code != code || oldDelegate.color != color;
  }
}
