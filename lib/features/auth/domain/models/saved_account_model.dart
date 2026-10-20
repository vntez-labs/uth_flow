import 'package:uth_flow/features/auth/domain/models/user_model.dart';

class SavedAccount {
  final String mssv;
  final String fullName;
  final String? avatarBase64;
  final String token;
  final String password;
  final DateTime lastUsed;
  final UserModel user;

  const SavedAccount({
    required this.mssv,
    required this.fullName,
    this.avatarBase64,
    required this.token,
    required this.password,
    required this.lastUsed,
    required this.user,
  });

  SavedAccount copyWith({
    String? mssv,
    String? fullName,
    String? avatarBase64,
    String? token,
    String? password,
    DateTime? lastUsed,
    UserModel? user,
  }) {
    return SavedAccount(
      mssv: mssv ?? this.mssv,
      fullName: fullName ?? this.fullName,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      token: token ?? this.token,
      password: password ?? this.password,
      lastUsed: lastUsed ?? this.lastUsed,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() => {
        'mssv': mssv,
        'fullName': fullName,
        'avatarBase64': avatarBase64,
        'token': token,
        'password': password,
        'lastUsed': lastUsed.toIso8601String(),
        'user': user.toJson(),
      };

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      mssv: json['mssv'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      avatarBase64: json['avatarBase64'] as String?,
      token: json['token'] as String? ?? '',
      password: json['password'] as String? ?? '',
      lastUsed: json['lastUsed'] != null
          ? DateTime.tryParse(json['lastUsed'] as String) ?? DateTime.now()
          : DateTime.now(),
      user: UserModel.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? {}),
      ),
    );
  }
}
