import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uth_flow/features/schedule/data/repositories/schedule_repository.dart';
import 'package:uth_flow/features/schedule/domain/schedule_model.dart';

class WidgetSyncService {
  static const _channel = MethodChannel('com.example.uth_flow/widget');
  static const _kPrefKey = 'widget_schedule_data';

  static String _formatDateShort(DateTime date) {
    final weekdayStr = switch (date.weekday) {
      DateTime.monday => 'T2',
      DateTime.tuesday => 'T3',
      DateTime.wednesday => 'T4',
      DateTime.thursday => 'T5',
      DateTime.friday => 'T6',
      DateTime.saturday => 'T7',
      DateTime.sunday => 'CN',
      _ => '',
    };
    return '$weekdayStr, ${date.day}/${date.month}';
  }

  static Map<String, dynamic> _formatClassItem(ScheduleModel c) {
    return {
      'name': c.displayName,
      'time': c.periodDisplay,
      'room': c.roomWithCampus,
      'isLive': c.isLive,
      'isFinished': c.isFinished,
    };
  }

  /// Đồng bộ lịch học hôm nay và ngày mai ra Home Screen Widget Android
  static Future<void> syncSchedule(DailyScheduleData data) async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final payload = {
        'updatedAt': now.toIso8601String(),
        'todayDate': _formatDateShort(now),
        'hasTodayClasses': data.todayClasses.isNotEmpty,
        'isTodayFinished': data.isTodayFinished,
        'hasTomorrowClasses': data.tomorrowClasses.isNotEmpty,
        'tomorrowDate': _formatDateShort(tomorrow),
        'todayClasses': data.todayClasses.map(_formatClassItem).toList(),
        'tomorrowClasses': data.tomorrowClasses.map(_formatClassItem).toList(),
      };

      final jsonStr = jsonEncode(payload);

      // 1. Lưu vào SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kPrefKey, jsonStr);
      } catch (_) {}

      // 2. Gọi native cập nhật widget tức thì qua MethodChannel
      try {
        await _channel.invokeMethod('updateScheduleWidget', jsonStr);
      } catch (_) {}
    } catch (e) {
      debugPrint('[WidgetSyncService] Sync error: $e');
    }
  }

  /// Xóa dữ liệu lịch học trên Widget khi người dùng đăng xuất
  static Future<void> clearWidget() async {
    try {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kPrefKey);
      } catch (_) {}

      try {
        await _channel.invokeMethod('updateScheduleWidget', '');
      } catch (_) {}
    } catch (_) {}
  }

  /// Yêu cầu hệ điều hành Android ghim widget Lịch học ra màn hình chính (Android 8.0+)
  static Future<bool> requestPinWidget() async {
    try {
      final res = await _channel.invokeMethod<bool>('pinScheduleWidget');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Kiểm tra xem thiết bị có phải là Xiaomi / Redmi / POCO không (MIUI / HyperOS)
  static Future<bool> isXiaomiDevice() async {
    try {
      final res = await _channel.invokeMethod<bool>('isXiaomiDevice');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mở màn hình cài đặt ứng dụng để người dùng cấp quyền nếu cần
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (_) {}
  }
}
