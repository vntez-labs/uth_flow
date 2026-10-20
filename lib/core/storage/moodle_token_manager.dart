import 'package:flutter/foundation.dart';
import 'package:uth_flow/core/storage/secure_storage_service.dart';

/// Quản lý SSO JWT Token cho hệ thống Moodle LMS (courses.ut.edu.vn).
///
/// Token này được trả về trực tiếp trong link lịch học của sinh viên
/// từ API Portal UTH (GET /lichhoc/lichNgay?date=yyyy-MM-dd).
/// Token có thời hạn sử dụng lên đến 30 ngày và dùng để đăng nhập tự động
/// một chạm (SSO) vào Moodle mà không cần nhập lại mật khẩu.
class MoodleTokenManager {
  static String? _currentToken;
  static SecureStorageService? _storageService;

  static String? get currentToken => _currentToken;

  /// Khởi tạo và khôi phục token từ SecureStorage
  static Future<void> initialize(SecureStorageService storage) async {
    _storageService = storage;
    try {
      final savedToken = await storage.getMoodleToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        _currentToken = savedToken;
      }
    } catch (e) {
      debugPrint('[MoodleTokenManager] Init error: $e');
    }
  }

  /// Trích xuất và cập nhật SSO token từ URL (ví dụ link lịch học)
  static void updateFromUrl(String? url) {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        setToken(token);
      }
    } catch (_) {}
  }

  /// Lưu token vào bộ nhớ RAM và SecureStorage
  static void setToken(String token) {
    if (token.isEmpty || token == _currentToken) return;
    _currentToken = token;
    _storageService?.saveMoodleToken(token).catchError((_) {});
  }

  /// Tạo đường dẫn LMS đã gắn SSO token (nếu có)
  static String buildCourseUrl({
    required String? courseCode,
    String? subjectName,
    String? fallbackDirectUrl,
  }) {
    // 1. Nếu đã có link trực tiếp hợp lệ từ API
    if (fallbackDirectUrl != null && fallbackDirectUrl.trim().isNotEmpty) {
      return fallbackDirectUrl.trim();
    }

    // 2. Định dạng idnumber chuẩn của Moodle UTH: "77" + mã lớp học phần (ví dụ: 77012012500102)
    final code = courseCode?.trim();
    final token = _currentToken;
    if (code != null && code.isNotEmpty && code != 'UTH') {
      final tokenParam = (token != null && token.isNotEmpty) ? '&token=$token' : '';
      return 'https://courses.ut.edu.vn/course/view.php?idnumber=77$code$tokenParam';
    }

    // 3. Nếu có token SSO nhưng không có mã lớp: mở trang chính LMS kèm token
    if (token != null && token.isNotEmpty) {
      return 'https://courses.ut.edu.vn/?token=$token';
    }

    // 4. Fallback tìm kiếm theo tên môn
    final query = (subjectName != null && subjectName.trim().isNotEmpty)
        ? subjectName.trim()
        : 'UTH';
    return 'https://courses.ut.edu.vn/course/search.php?search=${Uri.encodeComponent(query)}';
  }

  /// Gắn token SSO vào bất kỳ URL nào của courses.ut.edu.vn nếu chưa có token
  static String appendTokenIfNeeded(String url) {
    final token = _currentToken;
    if (token == null || token.isEmpty) return url;

    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('courses.ut.edu.vn') &&
          !uri.queryParameters.containsKey('token')) {
        final newParams = Map<String, String>.from(uri.queryParameters);
        newParams['token'] = token;
        return uri.replace(queryParameters: newParams).toString();
      }
    } catch (_) {}

    return url;
  }
}
