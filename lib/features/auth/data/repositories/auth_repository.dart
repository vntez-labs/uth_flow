import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uth_flow/core/storage/secure_storage_service.dart';
import 'package:uth_flow/features/auth/data/services/uth_portal_service.dart';
import 'package:uth_flow/features/auth/domain/models/auth_state.dart';
import 'package:uth_flow/features/auth/domain/models/saved_account_model.dart';
import 'package:uth_flow/features/auth/domain/models/user_model.dart';

abstract class AuthRepository {
  AuthState getInitialAuthState();
  Future<({UserModel user, String token})> login({
    required String username,
    required String password,
  });
  Future<({UserModel user, String token})> switchAccount(SavedAccount account);
  Future<void> removeAccount(String mssv);
  Future<String?> refreshToken();
  Future<void> logout();
  Future<List<SavedAccount>> getSavedAccounts();
  Future<UserModel?> syncAvatar(String token, UserModel currentUser);
}

class AuthRepositoryImpl implements AuthRepository {
  static const String tokenKey = 'uth_auth_token';
  static const String userKey = 'uth_auth_user';

  final UthPortalService _portalService;
  final SecureStorageService _secureStorage;
  final SharedPreferences? _prefs;

  AuthRepositoryImpl({
    required this._portalService,
    required this._secureStorage,
    this._prefs,
  });

  @override
  AuthState getInitialAuthState() {
    final token = _prefs?.getString(tokenKey);
    final userJson = _prefs?.getString(userKey);

    if (token != null && token.isNotEmpty && userJson != null) {
      try {
        final Map<String, dynamic> map =
            jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(map);

        if (user.avatarBase64 == null || user.avatarBase64!.isEmpty) {
          syncAvatar(token, user);
        }

        _ensureUserSavedInAccounts(token, user);
        _verifyOrRefreshTokenInBackground(user, token);

        return AuthState(user: user, token: token);
      } catch (_) {
        // Dữ liệu cache không hợp lệ
      }
    }

    return const AuthState();
  }

  void _verifyOrRefreshTokenInBackground(UserModel user, String currentToken) {
    Future.microtask(() async {
      try {
        final creds = await _secureStorage.getCredentials();
        final username = creds.username ?? user.mssv;
        final password = creds.password;
        if (username.isNotEmpty && password != null && password.isNotEmpty) {
          try {
            await _portalService.getSummaryProfile(currentToken);
          } catch (_) {
            debugPrint('>>> Token expired, auto refreshing token for $username...');
            await refreshToken();
          }
        }
      } catch (_) {}
    });
  }

  void _ensureUserSavedInAccounts(String token, UserModel user) {
    Future.microtask(() async {
      try {
        final accounts = await _secureStorage.getSavedAccounts();
        final exists = accounts.any((a) => a.mssv == user.mssv);
        if (!exists) {
          final creds = await _secureStorage.getCredentials();
          final savedAcc = SavedAccount(
            mssv: user.mssv,
            fullName: user.fullName,
            avatarBase64: user.avatarBase64,
            token: token,
            password: creds.password ?? '',
            lastUsed: DateTime.now(),
            user: user,
          );
          await _secureStorage.saveOrUpdateAccount(savedAcc);
        }
      } catch (_) {}
    });
  }

  @override
  Future<UserModel?> syncAvatar(String token, UserModel currentUser) async {
    try {
      final avatar = await _portalService.getAvatarBase64(token);
      if (avatar != null && avatar.isNotEmpty) {
        final updatedUser = currentUser.copyWith(avatarBase64: avatar);
        await _prefs?.setString(userKey, jsonEncode(updatedUser.toJson()));
        await _secureStorage.saveUser(updatedUser);

        final existingAcc = await _secureStorage.getAccount(updatedUser.mssv);
        if (existingAcc != null) {
          await _secureStorage.saveOrUpdateAccount(
            existingAcc.copyWith(
              avatarBase64: avatar,
              user: updatedUser,
            ),
          );
        }
        return updatedUser;
      }
    } catch (_) {
      // Bỏ qua lỗi kết nối
    }
    return null;
  }

  @override
  Future<({UserModel user, String token})> login({
    required String username,
    required String password,
  }) async {
    final cleanPassword = password.trim();
    var cleanUsername = username.trim();

    if (cleanUsername.contains('@')) {
      cleanUsername = cleanUsername.split('@').first.trim();
    }

    // 1. Đăng nhập qua Portal API UTH
    final authResult = await _portalService.login(
      username: cleanUsername,
      password: cleanPassword,
    );

    final token = authResult.token;
    final user = authResult.user;

    // 2. Lưu vào SharedPreferences & Secure Storage
    await _prefs?.setString(tokenKey, token);
    await _prefs?.setString(userKey, jsonEncode(user.toJson()));

    final finalMssv = user.mssv.isNotEmpty ? user.mssv : cleanUsername;

    await _secureStorage.saveCredentials(
      username: finalMssv,
      password: cleanPassword,
    );
    await _secureStorage.saveToken(token);
    await _secureStorage.saveUser(user);

    // 3. Cập nhật Multi-account
    final savedAcc = SavedAccount(
      mssv: finalMssv,
      fullName: user.fullName,
      avatarBase64: user.avatarBase64,
      token: token,
      password: cleanPassword,
      lastUsed: DateTime.now(),
      user: user,
    );
    await _secureStorage.saveOrUpdateAccount(savedAcc);

    return (user: user, token: token);
  }

  @override
  Future<({UserModel user, String token})> switchAccount(SavedAccount account) async {
    final updatedAcc = account.copyWith(lastUsed: DateTime.now());
    await _secureStorage.saveOrUpdateAccount(updatedAcc);

    await _secureStorage.saveCredentials(
      username: account.mssv,
      password: account.password,
    );
    await _secureStorage.saveToken(account.token);
    await _secureStorage.saveUser(account.user);

    await _prefs?.setString(tokenKey, account.token);
    await _prefs?.setString(userKey, jsonEncode(account.user.toJson()));

    if (account.password.isNotEmpty) {
      try {
        final authResult = await _portalService.login(
          username: account.mssv,
          password: account.password,
        );
        final freshToken = authResult.token;
        final freshUser = authResult.user.copyWith(
          avatarBase64: account.avatarBase64 ?? authResult.user.avatarBase64,
        );

        await _prefs?.setString(tokenKey, freshToken);
        await _prefs?.setString(userKey, jsonEncode(freshUser.toJson()));
        await _secureStorage.saveToken(freshToken);
        await _secureStorage.saveUser(freshUser);

        final refreshedAcc = updatedAcc.copyWith(
          token: freshToken,
          user: freshUser,
          lastUsed: DateTime.now(),
        );
        await _secureStorage.saveOrUpdateAccount(refreshedAcc);

        return (user: freshUser, token: freshToken);
      } catch (_) {
        // Lỗi mạng: vẫn giữ phiên hiện có để dùng offline
      }
    }

    return (user: account.user, token: account.token);
  }

  @override
  Future<void> removeAccount(String mssv) async {
    await _secureStorage.removeAccount(mssv);
  }

  @override
  Future<String?> refreshToken() async {
    try {
      final creds = await _secureStorage.getCredentials();
      final username = creds.username ?? '';
      final password = creds.password;
      if (username.isNotEmpty && password != null && password.isNotEmpty) {
        final authResult = await _portalService.login(
          username: username,
          password: password,
        );
        final freshToken = authResult.token;
        await _prefs?.setString(tokenKey, freshToken);
        await _secureStorage.saveToken(freshToken);
        return freshToken;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> logout() async {
    await _prefs?.remove(tokenKey);
    await _prefs?.remove(userKey);
    await _secureStorage.clearAll();
  }

  @override
  Future<List<SavedAccount>> getSavedAccounts() async {
    return _secureStorage.getSavedAccounts();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final portalService = ref.watch(uthPortalServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    // Trường hợp widget test không override sharedPreferencesProvider
  }

  return AuthRepositoryImpl(
    portalService: portalService,
    secureStorage: secureStorage,
    prefs: prefs,
  );
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider phải được ghi đè (override) trong ProviderScope',
  );
});
