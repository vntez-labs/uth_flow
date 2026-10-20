import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uth_flow/features/notification/domain/notification_model.dart';
import 'package:uth_flow/features/notification/presentation/controllers/notification_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _openPortalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showDetailModal(
    BuildContext context,
    NotificationModel item,
    bool isDark,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildDetailModal(ctx, item, isDark, primaryColor),
    );
  }

  Widget _buildDetailModal(
    BuildContext context,
    NotificationModel item,
    bool isDark,
    Color primaryColor,
  ) {
    final bgColor = isDark ? const Color(0xFF262522) : Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  SolarIconsBold.clockCircle,
                  size: 13,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 5),
                Text(
                  'Tính năng đang được phát triển',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF191919),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1B19) : const Color(0xFFF8F7F3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Text(
              item.content != null && item.content!.isNotEmpty
                  ? item.content!
                  : 'Nội dung chi tiết của thông báo đang được phát triển. Bạn vui lòng xem trực tiếp trên cổng Portal UTH bạn nhé!',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.5,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Đóng',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openPortalUrl('https://portal.ut.edu.vn/notedetail');
                  },
                  icon: const Icon(SolarIconsOutline.linkCircle, size: 16),
                  label: Text(
                    'Mở Portal UTH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final cardBgColor = isDark ? const Color(0xFF282724) : Colors.white;

    final notificationsAsync = ref.watch(notificationsProvider);
    final notifications = notificationsAsync.asData?.value ?? [];
    final isLoading = notificationsAsync.isLoading;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  SolarIconsOutline.arrowLeft,
                  color: isDark ? Colors.white : const Color(0xFF191919),
                ),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(
          'Thông báo',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF191919),
          ),
        ),
        centerTitle: true,
        actions: [
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primaryColor,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                SolarIconsOutline.restart,
                size: 20,
                color: primaryColor,
              ),
              tooltip: 'Làm mới',
              onPressed: () => ref.refresh(notificationsProvider),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          await ref.read(notificationsProvider.future);
        },
        color: primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
          children: [
            // ----------------- BANNER NỔI BẬT: TÍNH NĂNG ĐANG ĐƯỢC PHÁT TRIỂN -----------------
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              SolarIconsBold.clockCircle,
                              size: 13,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Tính năng đang được phát triển',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Portal UTH',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kênh thông báo Portal UTH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF191919),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tính năng hiển thị chi tiết thông báo đang được phát triển và hoàn thiện. Bạn có thể kiểm tra trực tiếp thông báo học tập trên cổng Portal UTH nhé!',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openPortalUrl(
                        'https://portal.ut.edu.vn/notedetail',
                      ),
                      icon: const Icon(SolarIconsOutline.linkCircle, size: 16),
                      label: Text(
                        'Mở trang Thông báo trên Portal UTH',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ----------------- DANH SÁCH THÔNG BÁO HOẶC TRẠNG THÁI RỖNG -----------------
            if (notifications.isEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        SolarIconsOutline.bell,
                        size: 26,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Chưa có thông báo mới',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF191919),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hiện tại không có thông báo nào từ API portal.ut.edu.vn. Khi có thông báo mới, số lượng sẽ hiển thị trên badge chuông ở Trang chủ.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'Danh sách thông báo (${notifications.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF191919),
                      ),
                    ),
                  ),
                  ...notifications.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showDetailModal(
                            context,
                            item,
                            isDark,
                            primaryColor,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    SolarIconsBold.bell,
                                    size: 17,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF191919),
                                        ),
                                      ),
                                      if (item.content != null &&
                                          item.content!.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          item.content!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            SolarIconsOutline.calendar,
                                            size: 12,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.black38,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.createdAt != null
                                                ? '${item.createdAt!.day.toString().padLeft(2, '0')}/${item.createdAt!.month.toString().padLeft(2, '0')}/${item.createdAt!.year}'
                                                : 'Gần đây',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white38
                                                  : Colors.black38,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  SolarIconsOutline.altArrowRight,
                                  size: 16,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
