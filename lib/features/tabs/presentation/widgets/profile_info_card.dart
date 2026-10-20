import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileRowItem {
  final IconData icon;
  final String label;
  final String value;

  const ProfileRowItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class ProfileInfoCard extends StatelessWidget {
  final String title;
  final List<ProfileRowItem> items;
  final bool isDark;

  const ProfileInfoCard({
    super.key,
    required this.title,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF555555),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF282724) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: [
              for (int idx = 0; idx < items.length; idx++) ...[
                if (idx > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      color: isDark
                          ? Colors.white12
                          : Colors.black.withValues(alpha: 0.06),
                      height: 1,
                    ),
                  ),
                _buildRow(items[idx]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(ProfileRowItem item) {
    return Row(
      children: [
        Icon(
          item.icon,
          size: 18,
          color: isDark ? Colors.white60 : const Color(0xFF666666),
        ),
        const SizedBox(width: 10),
        Text(
          item.label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: isDark ? Colors.white60 : const Color(0xFF666666),
          ),
        ),
        const Spacer(),
        Text(
          item.value,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF191919),
          ),
        ),
      ],
    );
  }
}
