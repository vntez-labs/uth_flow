import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:uth_flow/features/auth/domain/models/user_model.dart';
import 'package:uth_flow/features/auth/presentation/widgets/account_switcher_sheet.dart';

class UserProfileCard extends StatelessWidget {
  final UserModel? user;
  final bool isDark;
  final Color primaryColor;

  const UserProfileCard({
    super.key,
    required this.user,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282724) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildUserAvatar(user),
          const SizedBox(height: 14),
          Text(
            user?.fullName ?? 'Sinh viên UTH',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF191919),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '${user?.mssv ?? ''}@ut.edu.vn',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'MSSV: ${user?.mssv ?? '074207005137'}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => AccountSwitcherSheet.show(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        SolarIconsBold.usersGroupRounded,
                        size: 13,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Đổi tài khoản',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        SolarIconsOutline.altArrowRight,
                        size: 11,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(UserModel? user) {
    final avatarBase64 = user?.avatarBase64;
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(avatarBase64);
        return CircleAvatar(
          radius: 40,
          backgroundColor: primaryColor.withValues(alpha: 0.15),
          child: ClipOval(
            child: Image.memory(
              bytes,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackAvatar(user),
            ),
          ),
        );
      } catch (_) {}
    }
    return _buildFallbackAvatar(user);
  }

  Widget _buildFallbackAvatar(UserModel? user) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: primaryColor.withValues(alpha: 0.15),
      child: Text(
        user?.initials ?? 'HN',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
      ),
    );
  }
}
