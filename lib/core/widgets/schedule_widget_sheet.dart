import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:uth_flow/core/services/widget_sync_service.dart';
import 'package:uth_flow/core/widgets/bouncing_tap.dart';

class ScheduleWidgetSheet extends StatelessWidget {
  const ScheduleWidgetSheet({super.key});

  static Future<void> show(BuildContext context) {
    AppHaptics.medium();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ScheduleWidgetSheet(),
    );
  }

  Future<void> _handlePin(BuildContext context) async {
    AppHaptics.light();
    final isXiaomi = await WidgetSyncService.isXiaomiDevice();
    final success = await WidgetSyncService.requestPinWidget();
    if (!context.mounted) return;

    if (isXiaomi) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(SolarIconsBold.infoSquare, color: Color(0xFF008689), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lưu ý trên máy Xiaomi',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hệ điều hành Xiaomi / HyperOS / MIUI mặc định chặn tính năng ứng dụng tự động ghim tiện ích ra màn hình.',
                style: GoogleFonts.beVietnamPro(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              Text(
                '👉 Cách chuẩn và đơn giản nhất:\nBạn chỉ cần ra Màn hình chính > Nhấn giữ khoảng trống > Chọn "Tiện ích" (Widgets) > Kéo "Lịch học UTH" ra ngoài.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: const Color(0xFF008689),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                WidgetSyncService.openAppSettings();
              },
              child: Text(
                'Mở Cài đặt quyền',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF666666),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008689),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Đã hiểu',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đang gửi yêu cầu ghim tiện ích ra màn hình chính...',
            style: GoogleFonts.beVietnamPro(),
          ),
          backgroundColor: const Color(0xFF008689),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Trình khởi chạy của máy chưa hỗ trợ ghim tự động. Bạn hãy thêm thủ công theo 3 bước bên dưới nhé!',
            style: GoogleFonts.beVietnamPro(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFD97706),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1D1B) : Colors.white;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  SolarIconsBold.widget_5,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiện ích màn hình chính',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF191919),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Theo dõi lịch học nhanh mà không cần mở app',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        color: isDark ? Colors.white60 : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Widget Preview card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1E293B),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 18,
                        height: 18,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.school_rounded,
                          size: 18,
                          color: Color(0xFF2DD4BF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lịch học hôm nay',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2DD4BF),
                        ),
                      ),
                    ),
                    Text(
                      'T2, 20/10',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 1,
                  color: const Color(0xFF1E293B),
                ),
                const SizedBox(height: 10),
                Text(
                  'Lập trình ứng dụng di động',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      '07:00 - 09:15',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2DD4BF),
                      ),
                    ),
                    const Text(
                      '  •  ',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                    Text(
                      'B201 (Cơ sở 1)',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Hướng dẫn thêm thủ công (Khuyên dùng)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      SolarIconsBold.checklistMinimalistic,
                      size: 16,
                      color: Color(0xFF008689),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cách thêm tiện ích (100% thành công)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF191919),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildGuideStep('1', 'Ra màn hình chính của điện thoại, nhấn giữ vào khoảng trống bất kỳ (hoặc chụm 2 ngón tay lại).'),
                const SizedBox(height: 6),
                _buildGuideStep('2', 'Bấm vào mục "Tiện ích" (Widgets) trong menu hiện ra.'),
                const SizedBox(height: 6),
                _buildGuideStep('3', 'Tìm "UTH Flow" > Chọn "Lịch học UTH" và kéo ra vị trí bạn muốn.'),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Nút thử ghim tự động
          BouncingTap(
            onTap: () => _handlePin(context),
            scaleFactor: 0.96,
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _handlePin(context),
                icon: const Icon(SolarIconsBold.widgetAdd, size: 18),
                label: Text(
                  'Thử ghim tự động (Dành cho máy hỗ trợ)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.4), width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF008689),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: const Color(0xFF666666),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
