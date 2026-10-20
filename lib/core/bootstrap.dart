import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uth_flow/core/app.dart';
import 'package:uth_flow/core/storage/moodle_token_manager.dart';
import 'package:uth_flow/core/storage/secure_storage_service.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Moodle SSO Token Manager
  await MoodleTokenManager.initialize(SecureStorageService());

  // Bật chế độ tràn viền (edge-to-edge) và thanh trạng thái trong suốt
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Khởi tạo SharedPreferences trước khi khởi chạy ứng dụng để sẵn sàng nạp phiên đăng nhập
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}
