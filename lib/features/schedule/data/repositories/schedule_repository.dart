import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/features/auth/data/services/uth_portal_service.dart';
import 'package:uth_flow/features/schedule/domain/schedule_model.dart';

class DailyScheduleData {
  final List<ScheduleModel> todayClasses;
  final List<ScheduleModel> tomorrowClasses;
  final bool isTodayFinished;

  const DailyScheduleData({
    this.todayClasses = const [],
    this.tomorrowClasses = const [],
    this.isTodayFinished = false,
  });

  /// Danh sách tất cả các ca học (gộp hôm nay + ngày mai)
  /// Đã sắp xếp theo thứ tự thời gian: môn học trước hiển thị trước
  List<ScheduleModel> get upcomingSchedule {
    final all = <ScheduleModel>[...todayClasses, ...tomorrowClasses];
    all.sort((a, b) => a.classDateTime.compareTo(b.classDateTime));
    return all;
  }
}

abstract class ScheduleRepository {
  Future<DailyScheduleData> getDailySchedule(String token);
  Future<List<ScheduleModel>> getScheduleByDate(String token, DateTime date);
  Future<List<ScheduleModel>> getWeeklySchedule(String token, {DateTime? date});
  Future<List<MonthScheduleDay>> getMonthlySchedule(String token, {DateTime? date});
  void clearCache();
}

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(hours: 1);
}

class ScheduleRepositoryImpl implements ScheduleRepository {
  final UthPortalService _portalService;

  // Cache lịch học tạm thời trong 1 giờ (static để giữ cache xuyên suốt phiên làm việc)
  static final Map<String, _CacheEntry<List<ScheduleModel>>> _dailyCache = {};
  static final Map<String, _CacheEntry<List<ScheduleModel>>> _weeklyCache = {};
  static final Map<String, _CacheEntry<List<MonthScheduleDay>>> _monthlyCache = {};

  ScheduleRepositoryImpl({required this._portalService});

  @override
  void clearCache() {
    _dailyCache.clear();
    _weeklyCache.clear();
    _monthlyCache.clear();
  }

  /// Lấy ngày Thứ Hai của tuần chứa [date]
  static DateTime getMondayOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static String getDayCacheKey(DateTime date) {
    final yyyy = date.year.toString();
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return 'day_${yyyy}_${mm}_$dd';
  }

  static String getWeekCacheKey(DateTime date) {
    final monday = getMondayOfWeek(date);
    final yyyy = monday.year.toString();
    final mm = monday.month.toString().padLeft(2, '0');
    final dd = monday.day.toString().padLeft(2, '0');
    return 'week_${yyyy}_${mm}_$dd';
  }

  static String getMonthCacheKey(DateTime date) {
    final yyyy = date.year.toString();
    final mm = date.month.toString().padLeft(2, '0');
    return 'month_${yyyy}_$mm';
  }

  @override
  Future<List<ScheduleModel>> getWeeklySchedule(
    String token, {
    DateTime? date,
  }) async {
    if (token.isEmpty) return [];

    final targetDate = date ?? DateTime.now();
    final cacheKey = getWeekCacheKey(targetDate);

    // 1. Kiểm tra cache có còn hiệu lực trong 1 giờ không
    final cached = _weeklyCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    // 2. Fetch từ API lịch tuần của UTH Portal
    try {
      final monday = getMondayOfWeek(targetDate);
      final classes =
          await _portalService.getWeeklySchedule(token, date: monday);
      _weeklyCache[cacheKey] = _CacheEntry(classes);
      return classes;
    } catch (_) {
      if (cached != null) return cached.data;
      return [];
    }
  }

  @override
  Future<List<MonthScheduleDay>> getMonthlySchedule(
    String token, {
    DateTime? date,
  }) async {
    if (token.isEmpty) return [];

    final targetDate = date ?? DateTime.now();
    final cacheKey = getMonthCacheKey(targetDate);

    // 1. Kiểm tra cache 1 giờ
    final cached = _monthlyCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    // 2. Fetch từ API lịch tháng
    try {
      final firstDay = DateTime(targetDate.year, targetDate.month, 1);
      final days =
          await _portalService.getMonthlySchedule(token, date: firstDay);
      _monthlyCache[cacheKey] = _CacheEntry(days);
      return days;
    } catch (_) {
      if (cached != null) return cached.data;
      return [];
    }
  }

  @override
  Future<List<ScheduleModel>> getScheduleByDate(
    String token,
    DateTime date,
  ) async {
    if (token.isEmpty) return [];

    final dayKey = getDayCacheKey(date);

    // 1. Đã có trong cache ngày và chưa hết hạn -> trả về ngay lập tức không gọi API
    final cachedDay = _dailyCache[dayKey];
    if (cachedDay != null && !cachedDay.isExpired) {
      return cachedDay.data;
    }

    // 2. Kiểm tra dữ liệu lịch tháng (nếu đã có trong cache tháng)
    // Nếu tháng này đã load và ngày này không có môn học hoặc total == 0 -> trả về rỗng ngay không fetch!
    final monthKey = getMonthCacheKey(date);
    final cachedMonth = _monthlyCache[monthKey];
    if (cachedMonth != null && !cachedMonth.isExpired) {
      final match =
          cachedMonth.data.where((d) => d.matchesDate(date)).firstOrNull;
      if (match == null || match.total == 0) {
        _dailyCache[dayKey] = _CacheEntry([]);
        return [];
      }
    }

    final yyyy = date.year.toString();
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final dateStr = '$yyyy-$mm-$dd';

    // 3. Kiểm tra xem tuần này đã được tải và có môn nào cho ngày này chưa
    final weekKey = getWeekCacheKey(date);
    final cachedWeek = _weeklyCache[weekKey];
    if (cachedWeek != null && !cachedWeek.isExpired) {
      final weekClasses = cachedWeek.data
          .where((c) => c.matchesDate(date))
          .map((c) => c.copyWith(ngayHoc: c.ngayHoc ?? dateStr))
          .toList();
      if (weekClasses.isNotEmpty) {
        _dailyCache[dayKey] = _CacheEntry(weekClasses);
        return weekClasses;
      }
    }

    // 4. Nếu chưa có: gọi API lịch ngày (/lichhoc/lichNgay) để lấy chi tiết kèm link LMS trực tiếp
    try {
      final dayDirectClasses =
          await _portalService.getTodaySchedule(token, date: date);
      if (dayDirectClasses.isNotEmpty) {
        final normalized = dayDirectClasses
            .map((c) => c.copyWith(ngayHoc: c.ngayHoc ?? dateStr))
            .toList();
        _dailyCache[dayKey] = _CacheEntry(normalized);
        return normalized;
      }
    } catch (_) {}

    // 5. Nếu API lịch ngày rỗng hoặc lỗi, thử tra cứu từ lịch tuần (có cache 1h)
    try {
      final weekClasses = await getWeeklySchedule(token, date: date);
      final dayClasses = weekClasses
          .where((c) => c.matchesDate(date))
          .map((c) => c.copyWith(ngayHoc: c.ngayHoc ?? dateStr))
          .toList();

      if (dayClasses.isNotEmpty) {
        _dailyCache[dayKey] = _CacheEntry(dayClasses);
        return dayClasses;
      }
    } catch (_) {}

    // Lưu vào cache kết quả rỗng để không bị spam gọi lại
    _dailyCache[dayKey] = _CacheEntry([]);
    return [];
  }

  @override
  Future<DailyScheduleData> getDailySchedule(String token) async {
    if (token.isEmpty) {
      return const DailyScheduleData();
    }

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    // Gọi đồng thời:
    // 1. API Lịch ngày hôm nay (/lichhoc/lichNgay): có sẵn link LMS SSO trực tiếp
    // 2. API Lịch ngày mai (/lichhoc/lichNgay): có sẵn link LMS SSO trực tiếp
    // 3. API Lịch tuần: chuẩn bị sẵn cache tuần để chuyển tab Lịch học mượt mà
    final results = await Future.wait([
      _portalService
          .getTodaySchedule(token, date: now)
          .catchError((_) => <ScheduleModel>[]),
      _portalService
          .getTodaySchedule(token, date: tomorrow)
          .catchError((_) => <ScheduleModel>[]),
      getWeeklySchedule(token, date: now)
          .catchError((_) => <ScheduleModel>[]),
    ]);

    var todayClasses = results[0];
    var tomorrowClasses = results[1];
    final weekClasses = results[2];

    // Fallback lịch tuần nếu API lịch ngày chưa có dữ liệu hoặc gặp sự cố
    if (todayClasses.isEmpty && weekClasses.isNotEmpty) {
      todayClasses = weekClasses.where((c) => c.matchesDate(now)).toList();
    }
    if (tomorrowClasses.isEmpty && weekClasses.isNotEmpty) {
      tomorrowClasses =
          weekClasses.where((c) => c.matchesDate(tomorrow)).toList();
    }

    // Trường hợp hôm nay là Chủ Nhật và ngày mai sang Thứ 2 tuần sau:
    // nếu chưa có trong tuần hiện tại thì tải tuần của ngày mai (tự động cache 1h)
    if (tomorrowClasses.isEmpty && tomorrow.weekday == DateTime.monday) {
      final nextWeekClasses =
          await getWeeklySchedule(token, date: tomorrow);
      tomorrowClasses =
          nextWeekClasses.where((c) => c.matchesDate(tomorrow)).toList();
    }

    // Fallback nâng cao: Tra cứu qua getScheduleByDate (hỗ trợ cả lịch tháng nếu API ngày/tuần chưa có)
    if (todayClasses.isEmpty) {
      todayClasses = await getScheduleByDate(token, now);
    }
    if (tomorrowClasses.isEmpty) {
      tomorrowClasses = await getScheduleByDate(token, tomorrow);
    }

    // Cache ngay kết quả hôm nay và ngày mai vào static dailyCache
    _dailyCache[getDayCacheKey(now)] = _CacheEntry(todayClasses);
    _dailyCache[getDayCacheKey(tomorrow)] = _CacheEntry(tomorrowClasses);

    final todayActive =
        todayClasses.where((item) => !item.isFinished).toList();
    final isTodayFinished = todayClasses.isNotEmpty && todayActive.isEmpty;

    return DailyScheduleData(
      todayClasses: todayClasses,
      tomorrowClasses: tomorrowClasses,
      isTodayFinished: isTodayFinished,
    );
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final portalService = ref.watch(uthPortalServiceProvider);
  return ScheduleRepositoryImpl(portalService: portalService);
});
