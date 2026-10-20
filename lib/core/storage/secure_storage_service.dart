import 'dart:convert';
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

  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _kUsername, value: username);
    await _storage.write(key: _kPassword, value: password);
  }

  Future<({String? username, String? password})> getCredentials() async {
    final username = await _storage.read(key: _kUsername);
    final password = await _storage.read(key: _kPassword);
    return (username: username, password: password);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _kToken, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _kToken);
  }

  Future<void> saveMoodleToken(String token) async {
    await _storage.write(key: _kMoodleToken, value: token);
  }

  Future<String?> getMoodleToken() async {
    return _storage.read(key: _kMoodleToken);
  }

  Future<void> saveUser(UserModel user) async {
    await _storage.write(key: _kUser, value: jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await _storage.delete(key: _kPassword);
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kMoodleToken);
    await _storage.delete(key: _kUser);
    // Giữ lại username và savedAccounts để tiện chuyển tài khoản
  }

  Future<void> clearFull() async {
    await _storage.deleteAll();
  }

  // ==================== QUẢN LÝ NHIỀU PROFILE / TÀI KHOẢN ====================

  Future<List<SavedAccount>> getSavedAccounts() async {
    final raw = await _storage.read(key: _kSavedAccounts);
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
    final current = await getSavedAccounts();
    final index = current.indexWhere((a) => a.mssv == account.mssv);
    if (index >= 0) {
      current[index] = account;
    } else {
      current.insert(0, account);
    }
    await _storage.write(
      key: _kSavedAccounts,
      value: jsonEncode(current.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> removeAccount(String mssv) async {
    final current = await getSavedAccounts();
    current.removeWhere((a) => a.mssv == mssv);
    await _storage.write(
      key: _kSavedAccounts,
      value: jsonEncode(current.map((e) => e.toJson()).toList()),
    );
  }

  Future<SavedAccount?> getAccount(String mssv) async {
    final current = await getSavedAccounts();
    final matches = current.where((a) => a.mssv == mssv);
    return matches.isNotEmpty ? matches.first : null;
  }
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
