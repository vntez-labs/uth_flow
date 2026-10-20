import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/core/storage/secure_storage_service.dart';
import 'package:uth_flow/features/auth/domain/models/user_model.dart';
import 'package:uth_flow/features/moodle/data/services/uth_moodle_service.dart';
import 'package:uth_flow/features/moodle/domain/moodle_event_model.dart';

abstract class MoodleRepository {
  Future<List<MoodleEventModel>> getDeadlines({
    required UserModel? user,
  });
}

class MoodleRepositoryImpl implements MoodleRepository {
  final UthMoodleService _moodleService;
  final SecureStorageService _secureStorage;

  MoodleRepositoryImpl({
    required this._moodleService,
    required this._secureStorage,
  });

  @override
  Future<List<MoodleEventModel>> getDeadlines({
    required UserModel? user,
  }) async {
    final creds = await _secureStorage.getCredentials();

    final mssv = user?.mssv.trim();
    final username = (mssv != null && mssv.isNotEmpty)
        ? mssv
        : (creds.username?.trim() ?? '');

    var password = creds.password?.trim();

    // 1. Nếu creds chưa có mật khẩu, kiểm tra trong SavedAccount của user hiện tại
    if ((password == null || password.isEmpty) &&
        user != null &&
        user.mssv.isNotEmpty) {
      final currentAcc = await _secureStorage.getAccount(user.mssv);
      if (currentAcc != null && currentAcc.password.isNotEmpty) {
        password = currentAcc.password.trim();
      }
    }

    // 2. Tính mật khẩu mặc định theo ngày sinh của sinh viên UTH (ddMMyyyy)
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

          return fallbackEvents;
        } catch (_) {
          // Fallback ngày sinh cũng không thành công, ném lại lỗi ban đầu
        }
      }
      rethrow;
    }
  }
}

final moodleRepositoryProvider = Provider<MoodleRepository>((ref) {
  final moodleService = ref.watch(uthMoodleServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return MoodleRepositoryImpl(
    moodleService: moodleService,
    secureStorage: secureStorage,
  );
});
