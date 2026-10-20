import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uth_flow/features/auth/domain/models/saved_account_model.dart';
import 'package:uth_flow/features/auth/domain/models/user_model.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const _kUsername = 'uth_username';
  static const _kPassword = 'uth_password';
  static const _kToken = 'uth_token';
  static const _kUser = 'uth_user_profile';
  static const _kMoodleToken = 'uth_moodle_sso_token';
  static const _kSavedAccounts = 'uth_saved_accounts_list';

  SecureStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
            );

  static bool get _isTesting =>
      Platform.environment.containsKey('FLUTTER_TEST');

  Future<String?> _safeRead(String key) async {
    try {
      if (_isTesting) {
        return await _storage.read(key: key);
      }
      return await _storage.read(key: key).timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
    } catch (_) {
      try {
        await _storage.delete(key: key);
      } catch (_) {}
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      if (_isTesting) {
        await _storage.write(key: key, value: value);
        return;
      }
      await _storage
          .write(key: key, value: value)
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await _safeWrite(_kUsername, username);
    await _safeWrite(_kPassword, password);
  }

  Future<({String? username, String? password})> getCredentials() async {
    final username = await _safeRead(_kUsername);
    final password = await _safeRead(_kPassword);
    return (username: username, password: password);
  }

  Future<void> saveToken(String token) async {
    await _safeWrite(_kToken, token);
  }

  Future<String?> getToken() async {
    return _safeRead(_kToken);
  }

  Future<void> saveMoodleToken(String token) async {
    await _safeWrite(_kMoodleToken, token);
  }

  Future<String?> getMoodleToken() async {
    return _safeRead(_kMoodleToken);
  }

  Future<void> saveUser(UserModel user) async {
    await _safeWrite(_kUser, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final raw = await _safeRead(_kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _kPassword);
      await _storage.delete(key: _kToken);
      await _storage.delete(key: _kMoodleToken);
      await _storage.delete(key: _kUser);
    } catch (_) {}
  }

  Future<void> clearFull() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  // ==================== QUẢN LÝ NHIỀU PROFILE / TÀI KHOẢN ====================

  Future<List<SavedAccount>> getSavedAccounts() async {
    final raw = await _safeRead(_kSavedAccounts);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      final accounts = list
          .map((e) => SavedAccount.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      accounts.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
      return accounts;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOrUpdateAccount(SavedAccount account) async {
    try {
      final current = await getSavedAccounts();
      final index = current.indexWhere((a) => a.mssv == account.mssv);
      if (index >= 0) {
        current[index] = account;
      } else {
        current.insert(0, account);
      }
      await _safeWrite(
        _kSavedAccounts,
        jsonEncode(current.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> removeAccount(String mssv) async {
    try {
      final current = await getSavedAccounts();
      current.removeWhere((a) => a.mssv == mssv);
      await _safeWrite(
        _kSavedAccounts,
        jsonEncode(current.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<SavedAccount?> getAccount(String mssv) async {
    try {
      final current = await getSavedAccounts();
      final matches = current.where((a) => a.mssv == mssv);
      return matches.isNotEmpty ? matches.first : null;
    } catch (_) {
      return null;
    }
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
