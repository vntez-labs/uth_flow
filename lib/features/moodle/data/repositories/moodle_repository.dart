import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uth_flow/core/storage/secure_storage_service.dart';
import 'package:uth_flow/features/auth/domain/models/user_model.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:uth_flow/features/moodle/data/services/uth_moodle_service.dart';
import 'package:uth_flow/features/moodle/domain/moodle_event_model.dart';

abstract class MoodleRepository {
  Future<List<MoodleEventModel>> getDeadlines({
    required UserModel? user,
    bool forceRefresh = false,
  });
}

class MoodleRepositoryImpl implements MoodleRepository {
  final UthMoodleService _moodleService;
  final SecureStorageService _secureStorage;
  final SharedPreferences? prefs;

  static const Duration cacheTtl = Duration(days: 1);

  MoodleRepositoryImpl({
    required this._moodleService,
    required this._secureStorage,
    this.prefs,
  });

  Future<SharedPreferences> _getPrefs() async {
    return prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<List<MoodleEventModel>> getDeadlines({
    required UserModel? user,
    bool forceRefresh = false,
  }) async {
    final creds = await _secureStorage.getCredentials();

    final mssv = user?.mssv.trim();
    final username = (mssv != null && mssv.isNotEmpty)
        ? mssv
        : (creds.username?.trim() ?? '');

    final cacheKey = 'moodle_deadlines_cache_$username';
    final cacheTimeKey = 'moodle_deadlines_time_$username';

    // 1. Kiểm tra cache 1 ngày nếu không bắt buộc làm mới (forceRefresh = false)
    if (!forceRefresh && username.isNotEmpty) {
      try {
        final prefs = await _getPrefs();
        final cachedJson = prefs.getString(cacheKey);
        final cachedTimeMs = prefs.getInt(cacheTimeKey);

        if (cachedJson != null && cachedTimeMs != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedTimeMs);
          final isFresh = DateTime.now().difference(cacheTime) < cacheTtl;
          if (isFresh) {
            final list = jsonDecode(cachedJson) as List;
            return list
                .map((e) =>
                    MoodleEventModel.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          }
        }
      } catch (_) {}
    }

    var password = creds.password?.trim();

    // 2. Nếu creds chưa có mật khẩu, kiểm tra trong SavedAccount của user hiện tại
    if ((password == null || password.isEmpty) &&
        user != null &&
        user.mssv.isNotEmpty) {
      final currentAcc = await _secureStorage.getAccount(user.mssv);
      if (currentAcc != null && currentAcc.password.isNotEmpty) {
        password = currentAcc.password.trim();
      }
    }

    // 3. Tính mật khẩu mặc định theo ngày sinh của sinh viên UTH (ddMMyyyy)
    String? dobPassword;
    if (user?.ngaySinh != null) {
      final cleanDob = user!.ngaySinh!.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanDob.length == 8) {
        dobPassword = cleanDob;
      }
    }

    final candidatePassword = (password != null && password.isNotEmpty)
        ? password
        : dobPassword;

    if (username.isEmpty ||
        candidatePassword == null ||
        candidatePassword.isEmpty) {
      // Nếu không có mật khẩu nhưng có cache cũ, trả về cache cũ thay vì báo lỗi
      final fallbackList = await _getCachedFallback(cacheKey);
      if (fallbackList != null && fallbackList.isNotEmpty) {
        return fallbackList;
      }
      throw Exception('CHUA_CO_MAT_KHAU');
    }

    try {
      final events = await _moodleService.getDeadlines(
        username: username,
        password: candidatePassword,
      );

      // Lưu lại mật khẩu hoạt động tốt vào credentials & SavedAccount
      if (candidatePassword != creds.password) {
        await _secureStorage.saveCredentials(
          username: username,
          password: candidatePassword,
        );
        if (user != null && user.mssv.isNotEmpty) {
          final currentAcc = await _secureStorage.getAccount(user.mssv);
          if (currentAcc != null) {
            await _secureStorage.saveOrUpdateAccount(
              currentAcc.copyWith(password: candidatePassword),
            );
          }
        }
      }

      // 4. Lưu kết quả mới vào Cache 1 ngày
      await _saveToCache(cacheKey, cacheTimeKey, events);

      return events;
    } catch (err) {
      // Nếu mật khẩu nhập tay/portal bị từ chối và có ngày sinh khác, tự động thử fallback sang ngày sinh
      final errStr = err.toString();
      if (dobPassword != null &&
          dobPassword != candidatePassword &&
          (errStr.contains('Đăng nhập không hợp lệ') ||
              errStr.contains('không thành công'))) {
        try {
          final fallbackEvents = await _moodleService.getDeadlines(
            username: username,
            password: dobPassword,
          );

          // Fallback thành công! Lưu lại mật khẩu chuẩn xác
          await _secureStorage.saveCredentials(
            username: username,
            password: dobPassword,
          );
          if (user != null && user.mssv.isNotEmpty) {
            final currentAcc = await _secureStorage.getAccount(user.mssv);
            if (currentAcc != null) {
              await _secureStorage.saveOrUpdateAccount(
                currentAcc.copyWith(password: dobPassword),
              );
            }
          }

          // Lưu cache 1 ngày
          await _saveToCache(cacheKey, cacheTimeKey, fallbackEvents);

          return fallbackEvents;
        } catch (_) {
          // Fallback ngày sinh cũng không thành công
        }
      }

      // Nếu mạng lỗi nhưng có cache cũ bất kỳ, trả về cache cũ để không làm gián đoạn trải nghiệm
      final fallbackList = await _getCachedFallback(cacheKey);
      if (fallbackList != null && fallbackList.isNotEmpty) {
        return fallbackList;
      }

      rethrow;
    }
  }

  Future<void> _saveToCache(
    String cacheKey,
    String cacheTimeKey,
    List<MoodleEventModel> events,
  ) async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = jsonEncode(events.map((e) => e.toJson()).toList());
      await prefs.setString(cacheKey, jsonStr);
      await prefs.setInt(cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<List<MoodleEventModel>?> _getCachedFallback(String cacheKey) async {
    try {
      final prefs = await _getPrefs();
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final list = jsonDecode(cachedJson) as List;
        return list
            .map((e) =>
                MoodleEventModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
    return null;
  }
}

final moodleRepositoryProvider = Provider<MoodleRepository>((ref) {
  final moodleService = ref.watch(uthMoodleServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {}

  return MoodleRepositoryImpl(
    moodleService: moodleService,
    secureStorage: secureStorage,
    prefs: prefs,
  );
});
