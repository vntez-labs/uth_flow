import 'package:uth_flow/features/auth/domain/models/user_model.dart';

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      user != null && token != null && token!.trim().isNotEmpty;

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearAuth = false,
  }) {
    return AuthState(
      user: clearAuth ? null : (user ?? this.user),
      token: clearAuth ? null : (token ?? this.token),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
