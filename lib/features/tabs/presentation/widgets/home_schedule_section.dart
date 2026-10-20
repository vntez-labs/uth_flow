import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uth_flow/core/widgets/bouncing_tap.dart';
import 'package:uth_flow/features/schedule/presentation/controllers/schedule_controller.dart';

class HomeScheduleSection extends ConsumerWidget {
  const HomeScheduleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final cardBgColor = isDark ? const Color(0xFF282724) : Colors.white;
    final scheduleAsync = ref.watch(dailyScheduleProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: scheduleAsync.when(
        loading: () => Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Chưa thể tải lịch học: $err',
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
        data: (dailyData) {
          final todayClasses = dailyData.todayClasses;
          final tomorrowClasses = dailyData.tomorrowClasses;
          final todayActive = todayClasses.where((c) => !c.isFinished).toList();
          final isTodayFree = todayClasses.isEmpty || todayActive.isEmpty;
          final hasTomorrowClasses = tomorrowClasses.isNotEmpty;
          final upcomingClasses = dailyData.upcomingSchedule;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------- TIÊU ĐỀ "LỊCH HỌC" -----------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Lịch học',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? const Color(0xFFE5E5E5)
                          : const Color(0xFF191919),
                      letterSpacing: -0.3,
                    ),
                  ),
                  BouncingTap(
                    onTap: () => context.go('/schedule'),
                    scaleFactor: 0.94,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem tất cả',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          SolarIconsOutline.altArrowRight,
                          size: 14,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Nếu hôm nay không có lịch học nhưng ngày mai có lịch học -> hiển thị thông báo hôm nay được nghỉ
              if (isTodayFree && hasTomorrowClasses) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          SolarIconsBold.calendarMinimalistic,
                          size: 16,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          todayClasses.isEmpty
                              ? 'Hôm nay không có lịch học 🎉'
                              : 'Đã hoàn thành các ca học hôm nay 🎉',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF191919),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (upcomingClasses.isEmpty)
                // Cả hôm nay và ngày mai đều không có lịch học
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        SolarIconsOutline.calendarMinimalistic,
                        size: 26,
                        color: primaryColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hôm nay và ngày mai không có lịch học 🎉',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF191919),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Danh sách ca học sắp tới theo timeline
                Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.22 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: List.generate(upcomingClasses.length, (idx) {
                      final item = upcomingClasses[idx];
                      final isTomorrowOrLater = !item.isToday;
                      final dateLabel = isTomorrowOrLater && item.dateLabelShort.isNotEmpty
                          ? item.dateLabelShort
                          : null;
                      return _buildTimelineClassItem(
                        isDark: isDark,
                        primaryColor: primaryColor,
                        subject: item.displayName,
                        courseCode: item.courseCode ?? '',
                        time: item.startTime,
                        room: item.roomDisplay,
                        period: item.periodDisplay,
                        note: item.ghiChu,
                        dateLabel: dateLabel,
                        lmsUrl: item.courseLmsUrl,
                        isArranging: item.isArranging,
                        isLive: item.isLive,
                        isFinished: item.isFinished,
                        isLast: idx == upcomingClasses.length - 1,
                      );
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimelineClassItem({
    required bool isDark,
    required Color primaryColor,
    required String subject,
    required String courseCode,
    required String time,
    required String room,
    required String period,
    required String lmsUrl,
    String? note,
    String? dateLabel,
    bool isArranging = false,
    required bool isLive,
    required bool isFinished,
    required bool isLast,
  }) {
    final bool canLaunch = lmsUrl.isNotEmpty;
    void openLms() async {
      if (!canLaunch) return;
      try {
        await launchUrl(
          Uri.parse(lmsUrl),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }

    return BouncingTap(
      onTap: canLaunch ? openLms : null,
      scaleFactor: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline Node & Vertical connecting line
                Column(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isLive
                            ? primaryColor
                            : (isFinished
                                ? (isDark ? Colors.white10 : const Color(0xFFE8E8E8))
                                : (isDark ? const Color(0xFF282724) : Colors.white)),
                        border: isLive
                            ? null
                            : Border.all(
                                color: isFinished
                                    ? (isDark
                                        ? Colors.white24
                                        : const Color(0xFFCCCCCC))
                                    : (isDark
                                        ? Colors.white38
                                        : const Color(0xFFB0B0B0)),
                                width: 2,
                              ),
                        boxShadow: isLive
                            ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isFinished
                              ? (isDark ? Colors.white12 : const Color(0xFFE0E0E0))
                              : primaryColor.withValues(alpha: 0.35),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 14),

                // Nội dung ca học
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isLast ? 0 : (isFinished ? 14 : 20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dateLabel != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  SolarIconsBold.calendar,
                                  size: 11,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ngày mai • $dateLabel',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      courseCode.isNotEmpty
                                          ? '$subject - $courseCode'
                                          : subject,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.5,
                                        fontWeight: isFinished
                                            ? FontWeight.w500
                                            : (isLive ? FontWeight.w800 : FontWeight.w700),
                                        color: isFinished
                                            ? (isDark
                                                ? Colors.white38
                                                : const Color(0xFF8E8D88))
                                            : (isDark
                                                ? const Color(0xFFE5E5E5)
                                                : const Color(0xFF191919)),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  if (canLaunch) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      SolarIconsOutline.arrowRightUp,
                                      size: 13,
                                      color: isLive
                                          ? primaryColor
                                          : (isDark
                                              ? Colors.white38
                                              : const Color(0xFF8E8D88)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              time,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 14,
                                fontWeight: isLive
                                    ? FontWeight.w800
                                    : (isFinished ? FontWeight.w500 : FontWeight.w600),
                                color: isFinished
                                    ? (isDark
                                        ? Colors.white24
                                        : const Color(0xFFA09F9A))
                                    : (isLive
                                        ? primaryColor
                                        : (isDark
                                            ? Colors.white70
                                            : const Color(0xFF444444))),
                              ),
                            ),
                          ],
                        ),
                        if (!isFinished) ...[
                          const SizedBox(height: 5),
                          Text(
                            'Phòng: $room',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color:
                                  isDark ? Colors.white60 : const Color(0xFF555555),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Thời gian: $period',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color:
                                  isDark ? Colors.white60 : const Color(0xFF555555),
                            ),
                          ),
                          if (note != null && note.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Ghi chú: $note',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w400,
                                color: isLive
                                    ? primaryColor
                                    : (isDark
                                        ? Colors.white38
                                        : const Color(0xFF888888)),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
