import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uth_flow/core/app.dart';
import 'package:uth_flow/core/storage/moodle_token_manager.dart';
import 'package:uth_flow/core/storage/secure_storage_service.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';

Future<void> bootstrap() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Bắt các lỗi kết xuất Widget để không bị trắng màn hình (White Screen of Death)
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('[FlutterError] ${details.exceptionAsString()}');
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('[PlatformDispatcher Error] $error\n$stack');
        return true;
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFFFAF9F5),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFF008689),
                        size: 54,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Đã có sự cố khi tải giao diện',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF191919),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details.exceptionAsString(),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Khởi động lại ứng dụng
                          runApp(
                            const ProviderScope(
                              child: App(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008689),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      };

      // Bật chế độ tràn viền (edge-to-edge) và thanh trạng thái trong suốt
      try {
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
      } catch (_) {}

      // Khởi tạo SharedPreferences an toàn với cơ chế timeout (tránh treo vô hạn trên một số máy)
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 3),
        );
      } catch (e) {
        debugPrint('[SharedPreferences Init Warning] $e');
      }

      // Khởi tạo Moodle SSO Token Manager ở chế độ chạy nền không chặn render khung hình đầu tiên
      unawaited(
        MoodleTokenManager.initialize(SecureStorageService()).catchError((_) {}),
      );

      runApp(
        ProviderScope(
          overrides: [
            if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const App(),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('[Root Zone Error] $error\n$stackTrace');
    },
  );
}
