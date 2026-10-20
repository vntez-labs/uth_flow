import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:uth_flow/features/tabs/domain/portal_menu_utils.dart';

class ShortcutItem {
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final Color color;

  const ShortcutItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.color,
  });
}

class QuickShortcutsSection extends StatelessWidget {
  const QuickShortcutsSection({super.key});

  static const List<ShortcutItem> shortcuts = [
    ShortcutItem(
      title: 'Đào tạo LMS',
      subtitle: 'courses.ut.edu.vn',
      route: 'https://courses.ut.edu.vn',
      icon: SolarIconsOutline.laptop2,
      color: Color(0xFF008689),
    ),
    ShortcutItem(
      title: 'Bảng điểm & KQHT',
      subtitle: 'portal/transcript',
      route: '/transcript',
      icon: SolarIconsOutline.diploma,
      color: Color(0xFF4F46E5),
    ),
    ShortcutItem(
      title: 'Đăng ký học phần',
      subtitle: 'portal/registration',
      route: '/coursesregistration',
      icon: SolarIconsOutline.pen2,
      color: Color(0xFF059669),
    ),
    ShortcutItem(
      title: 'Học phí & Công nợ',
      subtitle: 'portal/tuition',
      route: '/tuition',
      icon: SolarIconsOutline.card2,
      color: Color(0xFFD97706),
    ),
    ShortcutItem(
      title: 'Dịch vụ sinh viên',
      subtitle: 'Cấp giấy tờ online',
      route: '/studentpaper',
      icon: SolarIconsOutline.documentText,
      color: Color(0xFF0284C7),
    ),
    ShortcutItem(
      title: 'Hỗ trợ trực tuyến',
      subtitle: 'support.ut.edu.vn',
      route: 'https://support.ut.edu.vn',
      icon: SolarIconsOutline.headphonesSquare,
      color: Color(0xFFE11D48),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              SolarIconsOutline.bolt,
              size: 18,
              color: Color(0xFF008689),
            ),
            const SizedBox(width: 8),
            Text(
              'Truy cập nhanh',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF191919),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < shortcuts.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildShortcutCard(context, shortcuts[i], isDark),
              ),
              const SizedBox(width: 12),
              if (i + 1 < shortcuts.length)
                Expanded(
                  child: _buildShortcutCard(context, shortcuts[i + 1], isDark),
                )
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildShortcutCard(
    BuildContext context,
    ShortcutItem item,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => PortalMenuUtils.openRoute(context, item.route, item.title),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF282724) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: item.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF191919),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
