import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uth_flow/features/schedule/domain/schedule_model.dart';
import 'package:uth_flow/features/schedule/presentation/controllers/schedule_controller.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  void _selectDay(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
  }

  void _changeMonth(int deltaMonths) {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + deltaMonths,
        1,
      );
      _selectedDate = DateTime(
        _currentMonth.year,
        _currentMonth.month,
        1,
      );
    });
  }

  void _resetToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _currentMonth = DateTime(now.year, now.month, 1);
    });
  }

  Future<void> _openLms(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final cardBgColor = isDark ? const Color(0xFF282724) : Colors.white;

    // Lấy toàn bộ lịch tháng từ Portal UTH (đã cache 1h)
    final monthlyScheduleAsync =
        ref.watch(monthlyScheduleProvider(_currentMonth));
    final monthDays = monthlyScheduleAsync.asData?.value ?? [];

    // Lấy lịch học theo ngày (ưu tiên API lịch ngày trực tiếp, fallback sang dữ liệu ngày)
    final scheduleForDateAsync =
        ref.watch(scheduleForDateProvider(_selectedDate));
    final classesForDate = scheduleForDateAsync.asData?.value ?? [];

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
          'Lịch học & Thời khóa biểu',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF191919),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _resetToToday,
            icon: Icon(
              SolarIconsBold.calendar,
              size: 16,
              color: primaryColor,
            ),
            label: Text(
              'Hôm nay',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. LƯỚI LỊCH THÁNG (QUICK VIEW)
            _buildMonthCalendarCard(
              isDark: isDark,
              primaryColor: primaryColor,
              monthDays: monthDays,
              isLoading: monthlyScheduleAsync.isLoading,
            ),

            const SizedBox(height: 10),

            // 2. TIÊU ĐỀ LỊCH HỌC TRONG NGÀY ĐANG CHỌN (1 HÀNG GỌN GÀNG)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateShort(_selectedDate),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF191919),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: classesForDate.isEmpty
                          ? (isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05))
                          : primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      classesForDate.isEmpty
                          ? (scheduleForDateAsync.isLoading
                              ? 'Đang tải...'
                              : 'Không có tiết học')
                          : '${classesForDate.length} môn học',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: classesForDate.isEmpty
                            ? Colors.grey
                            : primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 3. DANH SÁCH MÔN HỌC HOẶC TRẠNG THÁI NGHỈ (HIỂN THỊ TRỰC TIẾP DƯỚI LỊCH)
            if (scheduleForDateAsync.isLoading && classesForDate.isEmpty)
              Container(
                height: 140,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              )
            else if (classesForDate.isEmpty)
              _buildEmptyDayPreview(isDark, primaryColor)
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: classesForDate.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 0.8,
                      indent: 16,
                      endIndent: 16,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    itemBuilder: (context, index) {
                      final item = classesForDate[index];
                      return _buildClassSectionItem(
                        item,
                        isDark,
                        primaryColor,
                        selectedDate: _selectedDate,
                      );
                    },
                  ),
                ),
              ),

            // Đệm đáy tránh bị che bởi thanh điều hướng nổi
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCalendarCard({
    required bool isDark,
    required Color primaryColor,
    required List<MonthScheduleDay> monthDays,
    required bool isLoading,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final leadingBlanks = firstDayOfMonth.weekday - 1;
    final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    final totalMonthClasses =
        monthDays.fold<int>(0, (sum, item) => sum + item.total);

    final daysWithClasses = <int>{};
    for (int day = 1; day <= daysInMonth; day++) {
      final d = DateTime(_currentMonth.year, _currentMonth.month, day);
      if (monthDays.any((c) => c.matchesDate(d) && c.total > 0)) {
        daysWithClasses.add(day);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262522) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Header: Chuyển tháng + Tiêu đề tháng + Tóm tắt ca học (1 hàng siêu gọn)
          Row(
            children: [
              IconButton(
                icon: const Icon(SolarIconsOutline.altArrowLeft, size: 18),
                onPressed: () => _changeMonth(-1),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              const SizedBox(width: 4),
              Icon(
                SolarIconsBold.calendar,
                size: 15,
                color: primaryColor,
              ),
              const SizedBox(width: 5),
              Text(
                'Tháng ${_currentMonth.month}, ${_currentMonth.year}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF191919),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(width: 6),
                const SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(strokeWidth: 1.6),
                ),
              ],
              const Spacer(),
              if (totalMonthClasses > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        primaryColor.withValues(alpha: isDark ? 0.15 : 0.09),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${daysWithClasses.length} ngày • $totalMonthClasses ca',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFF2DD4BF)
                          : const Color(0xFF008689),
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(SolarIconsOutline.altArrowRight, size: 18),
                onPressed: () => _changeMonth(1),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 2. Tiêu đề 7 thứ trong tuần: T2 -> CN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((label) {
              final isWeekend = label == 'CN';
              return Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isWeekend
                          ? const Color(0xFFEF4444)
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 4),

          // 3. Lưới các ô ngày trong tháng theo từng tuần (Row) - Tuyệt đối không bị thừa chiều cao / dãn trắng
          ...List.generate(totalCells ~/ 7, (weekIndex) {
            final isLastWeek = weekIndex == (totalCells ~/ 7) - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLastWeek ? 0.0 : 3.0),
              child: Row(
                children: List.generate(7, (colIndex) {
                  final cellIndex = weekIndex * 7 + colIndex;
                  final isLastCol = colIndex == 6;

                  if (cellIndex < leadingBlanks ||
                      cellIndex >= leadingBlanks + daysInMonth) {
                    return Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.only(right: isLastCol ? 0.0 : 3.0),
                        child: const AspectRatio(
                          aspectRatio: 1.15,
                          child: SizedBox.shrink(),
                        ),
                      ),
                    );
                  }

                  final dayNumber = cellIndex - leadingBlanks + 1;
                  final cellDate = DateTime(
                    _currentMonth.year,
                    _currentMonth.month,
                    dayNumber,
                  );
                  final isDayToday = cellDate.year == today.year &&
                      cellDate.month == today.month &&
                      cellDate.day == today.day;
                  final isSelected = cellDate.year == _selectedDate.year &&
                      cellDate.month == _selectedDate.month &&
                      cellDate.day == _selectedDate.day;

                  final dayEntry = monthDays
                      .where((d) => d.matchesDate(cellDate))
                      .firstOrNull;
                  final classCount = dayEntry?.total ?? 0;

                  return Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: isLastCol ? 0.0 : 3.0),
                      child: AspectRatio(
                        aspectRatio: 1.15,
                        child: _buildCalendarDayCell(
                          cellDate: cellDate,
                          isSelected: isSelected,
                          isDayToday: isDayToday,
                          classCount: classCount,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCalendarDayCell({
    required DateTime cellDate,
    required bool isSelected,
    required bool isDayToday,
    required int classCount,
    required bool isDark,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () => _selectDay(cellDate),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDayToday
                  ? primaryColor.withValues(alpha: 0.12)
                  : (classCount > 0
                      ? (isDark
                          ? const Color(0xFF008689).withValues(alpha: 0.16)
                          : const Color(0xFFE6F5F5))
                      : Colors.transparent)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDayToday
                    ? primaryColor.withValues(alpha: 0.55)
                    : (classCount > 0
                        ? const Color(0xFF008689)
                            .withValues(alpha: isDark ? 0.45 : 0.35)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04)))),
            width:
                isDayToday || isSelected ? 1.4 : (classCount > 0 ? 0.9 : 0.5),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                '${cellDate.day}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: isSelected || isDayToday || classCount > 0
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDayToday
                          ? primaryColor
                          : (classCount > 0
                              ? (isDark
                                  ? const Color(0xFF2DD4BF)
                                  : const Color(0xFF008689))
                              : (isDark
                                  ? Colors.white
                                  : const Color(0xFF191919)))),
                ),
              ),
            ),
            if (classCount > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$classCount',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? const Color(0xFFEF4444)
                            : Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDayPreview(bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282724) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              SolarIconsOutline.calendarMinimalistic,
              size: 22,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Không có môn học',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF191919),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ngày này bạn không có môn học nào. Bạn có thể tự do nghỉ ngơi hoặc ôn bài nhé!',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSectionItem(
    ScheduleModel item,
    bool isDark,
    Color primaryColor, {
    required DateTime selectedDate,
  }) {
    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    final viewDateOnly =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    Color statusColor;
    String statusText;

    if (item.isTamNgung) {
      statusColor = const Color(0xFFEF4444);
      statusText = 'Tạm ngưng học';
    } else if (item.isArranging) {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Đang sắp xếp';
    } else if (viewDateOnly.isAfter(todayDateOnly)) {
      // Ngày tương lai -> Luôn là "Sắp tới" bất kể giờ học trong ngày
      statusColor = const Color(0xFF008689);
      statusText = 'Sắp tới';
    } else if (viewDateOnly.isBefore(todayDateOnly)) {
      // Ngày trong quá khứ -> "Đã kết thúc"
      statusColor = Colors.grey;
      statusText = 'Đã kết thúc';
    } else {
      // Hôm nay -> Kiểm tra giờ học thực tế
      if (item.isLive) {
        statusColor = const Color(0xFF10B981);
        statusText = 'Đang diễn ra';
      } else if (item.isFinished) {
        statusColor = Colors.grey;
        statusText = 'Đã kết thúc';
      } else {
        statusColor = const Color(0xFF008689);
        statusText = 'Sắp tới';
      }
    }

    // Thời gian hiển thị (chỉ hiển thị giờ, KHÔNG hiển thị Tiết 1 - 3 theo yêu cầu của user)
    final timeDisplay = (item.timeToDisplay != null &&
            item.timeToDisplay!.isNotEmpty &&
            item.timeToDisplay != 'Chưa rõ ca học')
        ? item.timeToDisplay!
        : 'Đang sắp xếp';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // Chạm trực tiếp vào section của môn học để chuyển thẳng đến LMS Courses
        onTap: () => _openLms(item.courseLmsUrl),
        onLongPress: () =>
            _showClassDetailModal(context, item, isDark, primaryColor),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Trạng thái & Giờ học (Không kèm tiết học) & Biểu tượng chuyển LMS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          statusText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeDisplay,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          SolarIconsOutline.arrowRightUp,
                          size: 13,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Tên môn học
              Text(
                item.displayName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF191919),
                ),
              ),

              if (item.courseCode != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Mã lớp: ${item.courseCode}${item.maMonHoc != null ? " • Mã môn: ${item.maMonHoc}" : ""}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Phòng học & Cơ sở
              Row(
                children: [
                  Icon(
                    item.isElearning
                        ? SolarIconsOutline.laptop
                        : SolarIconsOutline.mapPoint,
                    size: 15,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.isElearning ? 'E-Learning (Online)' : item.roomWithCampus,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : const Color(0xFF444444),
                      ),
                    ),
                  ),
                ],
              ),

              if (item.giangVien != null && item.giangVien!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      SolarIconsOutline.user,
                      size: 15,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'GV: ${item.giangVien}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF444444),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (item.outLineDescription != null &&
                  item.outLineDescription!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.025),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Text(
                    item.outLineDescription!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : const Color(0xFF555555),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showClassDetailModal(
    BuildContext context,
    ScheduleModel item,
    bool isDark,
    Color primaryColor,
  ) {
    final now = DateTime.now();
    final todayDateOnly = DateTime(now.year, now.month, now.day);
    final pDate = item.parsedDate ?? _selectedDate;
    final itemDateOnly = DateTime(pDate.year, pDate.month, pDate.day);

    Color modalStatusColor;
    String modalStatusText;
    IconData modalStatusIcon;

    if (item.isTamNgung) {
      modalStatusColor = const Color(0xFFEF4444);
      modalStatusText = 'Tạm ngưng học';
      modalStatusIcon = SolarIconsBold.dangerCircle;
    } else if (itemDateOnly.isAfter(todayDateOnly)) {
      modalStatusColor = const Color(0xFF008689);
      modalStatusText = 'Sắp tới';
      modalStatusIcon = SolarIconsBold.clockCircle;
    } else if (itemDateOnly.isBefore(todayDateOnly)) {
      modalStatusColor = Colors.grey;
      modalStatusText = 'Đã kết thúc';
      modalStatusIcon = SolarIconsBold.checkCircle;
    } else {
      if (item.isLive) {
        modalStatusColor = const Color(0xFF10B981);
        modalStatusText = 'Đang diễn ra';
        modalStatusIcon = SolarIconsBold.playCircle;
      } else if (item.isFinished) {
        modalStatusColor = Colors.grey;
        modalStatusText = 'Đã kết thúc';
        modalStatusIcon = SolarIconsBold.checkCircle;
      } else {
        modalStatusColor = const Color(0xFF008689);
        modalStatusText = 'Sắp tới';
        modalStatusIcon = SolarIconsBold.clockCircle;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242320) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh kéo
                Center(
                  child: Container(
                    width: 40,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tiêu đề & nút đóng
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF191919),
                            ),
                          ),
                          if (item.courseCode != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Mã lớp HP: ${item.courseCode}${item.maMonHoc != null ? " • Mã môn: ${item.maMonHoc}" : ""}',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Badge trạng thái
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(
                      label: modalStatusText,
                      color: modalStatusColor,
                      icon: modalStatusIcon,
                    ),
                    if (item.isElearning)
                      _buildChip(
                        label: 'Học trực tuyến (E-learning)',
                        color: const Color(0xFF8B5CF6),
                        icon: SolarIconsBold.laptop,
                      ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Danh sách chi tiết thông tin
                _buildDetailRow(
                  icon: SolarIconsOutline.calendar,
                  title: 'Ngày học',
                  value: item.parsedDate != null
                      ? _formatDateShort(item.parsedDate!)
                      : (item.ngayHoc ?? _formatDateShort(_selectedDate)),
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: SolarIconsOutline.clockCircle,
                  title: 'Thời gian & Tiết học',
                  value: item.periodDisplay,
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: SolarIconsOutline.mapPoint,
                  title: 'Phòng học & Cơ sở',
                  value: item.roomWithCampus,
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: SolarIconsOutline.user,
                  title: 'Giảng viên',
                  value: item.giangVien ?? 'Đang cập nhật',
                  isDark: isDark,
                  primaryColor: primaryColor,
                ),
                if (item.ghiChu != null && item.ghiChu!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    icon: SolarIconsOutline.notes,
                    title: 'Ghi chú',
                    value: item.ghiChu!.trim(),
                    isDark: isDark,
                    primaryColor: primaryColor,
                  ),
                ],

                // Đề cương môn học
                if (item.outLineDescription != null &&
                    item.outLineDescription!.trim().isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Đề cương & Giới thiệu môn học',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF191919),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF7FAFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      item.outLineDescription!.trim(),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        height: 1.5,
                        color: isDark ? Colors.white70 : const Color(0xFF444444),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                // Nút vào LMS
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openLms(item.courseLmsUrl);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(SolarIconsOutline.laptop2, size: 18),
                    label: Text(
                      'Vào học trên LMS Courses',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            title,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF666666),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF191919),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateShort(DateTime d) {
    final weekdayStr = switch (d.weekday) {
      DateTime.monday => 'Thứ Hai',
      DateTime.tuesday => 'Thứ Ba',
      DateTime.wednesday => 'Thứ Tư',
      DateTime.thursday => 'Thứ Năm',
      DateTime.friday => 'Thứ Sáu',
      DateTime.saturday => 'Thứ Bảy',
      DateTime.sunday => 'Chủ Nhật',
      _ => '',
    };
    return '$weekdayStr, ${d.day}/${d.month}/${d.year}';
  }
}
