import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:uth_flow/core/widgets/bouncing_tap.dart';
import 'package:uth_flow/features/auth/domain/models/user_model.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:uth_flow/features/notification/presentation/controllers/notification_controller.dart';
import 'package:uth_flow/features/tabs/domain/portal_menu_utils.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/qr_scanner_sheet.dart';

class HomeHeaderWidget extends ConsumerWidget {
  const HomeHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final notifCount = ref.watch(notificationCountProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            const Color(0xFF007578),
            const Color(0xFF005E60),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: topPadding + 14,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Row: Avatar + Họ tên + MSSV + Chuông thông báo
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildHeaderAvatar(user),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Chào, ${user?.fullName ?? 'Nguyễn Hoàng Nam'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'MSSV: ${user?.mssv ?? '074207005137'} (${user?.studentType ?? 'Đại học - chính quy'})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Nút Chuông thông báo
                  _buildHeaderIconButton(
                    icon: SolarIconsBold.bell,
                    badgeCount: notifCount,
                    onTap: () => context.push('/notifications'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. Capsule Quick Action Bar: Quét QR | Thẻ SV | Dịch vụ SV | Hỗ trợ TT
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildHeaderActionItem(
                        icon: SolarIconsBold.scanner_2,
                        label: 'Quét QR',
                        onTap: () => QrScannerSheet.handleQrAction(context),
                      ),
                    ),
                    _buildHeaderActionDivider(),
                    Expanded(
                      child: _buildHeaderActionItem(
                        icon: SolarIconsBold.shieldUser,
                        label: 'Thẻ SV',
                        onTap: () => context.push('/student-card'),
                      ),
                    ),
                    _buildHeaderActionDivider(),
                    Expanded(
                      child: _buildHeaderActionItem(
                        icon: SolarIconsBold.calendarAdd,
                        label: 'Dịch vụ SV',
                        onTap: () => PortalMenuUtils.openRoute(
                          context,
                          '/studentpaper',
                          'Dịch vụ sinh viên',
                        ),
                      ),
                    ),
                    _buildHeaderActionDivider(),
                    Expanded(
                      child: _buildHeaderActionItem(
                        icon: SolarIconsBold.chatDots,
                        label: 'Hỗ trợ TT',
                        onTap: () => PortalMenuUtils.openRoute(
                          context,
                          'https://support.ut.edu.vn',
                          'Hỗ trợ trực tuyến sinh viên',
                        ),
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

  Widget _buildHeaderAvatar(UserModel? user) {
    final avatarBase64 = user?.avatarBase64;
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(avatarBase64);
        return CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white.withValues(alpha: 0.22),
          child: ClipOval(
            child: Image.memory(
              bytes,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallbackInitials(user),
            ),
          ),
        );
      } catch (_) {}
    }
    return _buildFallbackInitials(user);
  }

  Widget _buildFallbackInitials(UserModel? user) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white.withValues(alpha: 0.22),
      child: Text(
        user?.initials ?? 'HN',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHeaderActionDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.28),
    );
  }

  Widget _buildHeaderActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return BouncingTap(
      onTap: onTap,
      scaleFactor: 0.90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    int badgeCount = 0,
    bool hasBadge = false,
    required VoidCallback onTap,
  }) {
    final showBadge = hasBadge || badgeCount > 0;
    return BouncingTap(
      onTap: onTap,
      scaleFactor: 0.88,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            if (showBadge)
              Positioned(
                top: badgeCount > 0 ? -2 : 8,
                right: badgeCount > 0 ? -2 : 8,
                child: badgeCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.5,
                          vertical: 1.5,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4757),
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
