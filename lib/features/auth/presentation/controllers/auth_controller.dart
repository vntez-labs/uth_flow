import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uth_flow/features/auth/data/repositories/auth_repository.dart';
import 'package:uth_flow/features/auth/domain/models/auth_state.dart';
import 'package:uth_flow/features/auth/domain/models/saved_account_model.dart';
import 'package:uth_flow/features/auth/domain/models/user_model.dart';

export 'package:uth_flow/features/auth/data/repositories/auth_repository.dart'
    show sharedPreferencesProvider;

final savedAccountsProvider =
    FutureProvider.autoDispose<List<SavedAccount>>((ref) async {
  ref.watch(authProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getSavedAccounts();
});

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    return _repository.getInitialAuthState();
  }

  Future<bool> login(String input, String password) async {
    final cleanInput = input.trim();
    final cleanPassword = password.trim();

    if (cleanInput.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập MSSV hoặc Email');
      return false;
    }

    if (cleanPassword.isEmpty) {
      state = state.copyWith(errorMessage: 'Vui lòng nhập mật khẩu');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.login(
        username: cleanInput,
        password: cleanPassword,
      );

      state = AuthState(
        user: result.user,
        token: result.token,
        isLoading: false,
      );
      return true;
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
      return false;
    }
  }

  /// Chuyển đổi sang tài khoản khác chỉ với 1 chạm
  Future<bool> switchAccount(SavedAccount account) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.switchAccount(account);
      state = AuthState(
        user: result.user,
        token: result.token,
        isLoading: false,
      );
      return true;
    } catch (_) {
      state = AuthState(
        user: account.user,
        token: account.token,
        isLoading: false,
      );
      return true;
    }
  }

  /// Xóa tài khoản khỏi danh sách lưu trữ
  Future<void> removeAccount(String mssv) async {
    await _repository.removeAccount(mssv);
    if (state.user?.mssv == mssv) {
      final remaining = await _repository.getSavedAccounts();
      if (remaining.isNotEmpty) {
        await switchAccount(remaining.first);
      } else {
        await logout();
      }
    }
  }

  /// Làm mới token Portal khi token bị hết hạn (401)
  Future<String?> refreshToken() async {
    final freshToken = await _repository.refreshToken();
    if (freshToken != null) {
      state = state.copyWith(token: freshToken);
    }
    return freshToken;
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).token;
});
