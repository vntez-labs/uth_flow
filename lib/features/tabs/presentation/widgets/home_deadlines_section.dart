import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uth_flow/core/widgets/bouncing_tap.dart';
import 'package:uth_flow/features/moodle/presentation/controllers/moodle_controller.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/sync_moodle_password_sheet.dart';

class HomeDeadlinesSection extends ConsumerStatefulWidget {
  const HomeDeadlinesSection({super.key});

  @override
  ConsumerState<HomeDeadlinesSection> createState() =>
      _HomeDeadlinesSectionState();
}

class _HomeDeadlinesSectionState extends ConsumerState<HomeDeadlinesSection> {
  String _deadlineFilter = '30d'; // '1d', '7d', '30d', 'all'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final cardBgColor = isDark ? const Color(0xFF282724) : Colors.white;
    final deadlinesAsync = ref.watch(moodleDeadlinesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon cuốn sách + Cụm Badge Filter (Tránh overflow trên màn hình nhỏ)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Deadlines',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (deadlinesAsync.isLoading) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
              _buildDeadlineFilterChips(isDark, primaryColor),
            ],
          ),

          const SizedBox(height: 14),

          deadlinesAsync.when(
            loading: () => Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) {
              final isMissingPassword = err.toString().contains(
                'CHUA_CO_MAT_KHAU',
              );
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isMissingPassword
                                ? SolarIconsBold.lockPassword
                                : SolarIconsBold.dangerCircle,
                            size: 20,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMissingPassword
                                    ? 'Cần mật khẩu đồng bộ Moodle'
                                    : 'Chưa thể đồng bộ Moodle',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF191919),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isMissingPassword
                                    ? 'Nhập mật khẩu một lần để tải các hạn chót bài tập LMS.'
                                    : _formatMoodleErrorMessage(err),
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            SyncMoodlePasswordSheet.show(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                        ),
                        child: Text(
                          isMissingPassword
                              ? 'Đồng bộ Moodle ngay'
                              : 'Thử nhập lại mật khẩu',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            data: (events) {
              final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
              final filteredEvents = events.where((e) {
                if (_deadlineFilter == 'all') {
                  return true;
                }
                final days =
                    int.tryParse(_deadlineFilter.replaceAll('d', '')) ?? 30;
                final maxSec = nowSeconds + (days * 86400);
                return e.timesort >= nowSeconds - 86400 && e.timesort <= maxSec;
              }).toList();

              filteredEvents.sort((a, b) => a.timesort.compareTo(b.timesort));

              if (filteredEvents.isEmpty) {
                String emptyMessage;
                if (_deadlineFilter == '1d') {
                  emptyMessage = 'Không có deadline trong 1 ngày tới 🎉';
                } else if (_deadlineFilter == '7d') {
                  emptyMessage = 'Không có deadline trong 7 ngày tới 🎉';
                } else if (_deadlineFilter == '30d') {
                  emptyMessage = 'Không có deadline trong 30 ngày tới 🎉';
                } else {
                  emptyMessage = 'Không có deadline nào trong thời gian tới 🎉';
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        SolarIconsBold.smileCircle,
                        size: 22,
                        color: Color(0xFF2ED573),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF191919),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
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
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.22 : 0.04,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Column(
                  children: List.generate(filteredEvents.length, (idx) {
                    final item = filteredEvents[idx];
                    return _buildDeadlineItem(
                      isDark: isDark,
                      title: item.name,
                      subject: item.courseName,
                      countdownText: item.countdownText,
                      suffixText: item.suffixText,
                      dueTime: item.formattedDueTime,
                      isUrgent: item.isUrgent,
                      url: item.url,
                      isLast: idx == filteredEvents.length - 1,
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineFilterChips(bool isDark, Color primaryColor) {
    final filters = [
      {'key': '1d', 'label': '1 ngày'},
      {'key': '7d', 'label': '7 ngày'},
      {'key': '30d', 'label': '30 ngày'},
      {'key': 'all', 'label': 'Tất cả'},
    ];

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: filters.map((item) {
          final isSelected = _deadlineFilter == item['key'];
          return BouncingTap(
            scaleFactor: 0.92,
            onTap: () {
              setState(() {
                _deadlineFilter = item['key']!;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF282724) : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.25 : 0.08,
                          ),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                item['label']!,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.white60 : const Color(0xFF666666)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeadlineItem({
    required bool isDark,
    required String title,
    required String subject,
    required String countdownText,
    required String suffixText,
    required String dueTime,
    required bool isUrgent,
    required String url,
    required bool isLast,
  }) {
    final urgentColor = const Color(0xFFFF4757);

    return BouncingTap(
      onTap: url.isNotEmpty
          ? () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
      scaleFactor: 0.98,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFE5E5E5)
                        : const Color(0xFF191919),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? urgentColor.withValues(alpha: isDark ? 0.22 : 0.1)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  suffixText.isNotEmpty
                      ? '$countdownText $suffixText'
                      : countdownText,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isUrgent
                        ? urgentColor
                        : (isDark ? Colors.white70 : const Color(0xFF555555)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Môn: $subject',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white60 : const Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Hạn chót: $dueTime',
            style: GoogleFonts.beVietnamPro(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: isUrgent
                  ? (isDark ? const Color(0xFFFF8598) : const Color(0xFFD63031))
                  : (isDark ? Colors.white38 : const Color(0xFF888888)),
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 14),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  String _formatMoodleErrorMessage(Object err) {
    final str = err.toString();
    if (str.contains('Đăng nhập không hợp lệ')) {
      return 'Tài khoản hoặc mật khẩu Moodle không chính xác. Vui lòng bấm bên dưới để cập nhật lại.';
    }
    if (str.contains('SocketException') || str.contains('kết nối')) {
      return 'Không thể kết nối đến máy chủ Moodle UTH. Vui lòng kiểm tra lại kết nối mạng.';
    }
    return str
        .replaceFirst('Exception: ', '')
        .replaceFirst('PlatformException(MOODLE_ERROR, ', '')
        .replaceAll(', null, null)', '');
  }
}
