import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uth_flow/core/network/api_endpoints.dart';
import 'package:uth_flow/features/academic/domain/models/academic_models.dart';
import 'package:uth_flow/features/auth/domain/models/user_model.dart';
import 'package:uth_flow/features/schedule/domain/schedule_model.dart';
import 'package:uth_flow/features/tabs/domain/portal_menu_model.dart';

class PortalApiClient {
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  final http.Client _client;

  PortalApiClient([http.Client? client]) : _client = client ?? http.Client();

  Map<String, String> _buildHeaders([String? token]) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Đăng nhập tài khoản sinh viên vào cổng thông tin đào tạo UTH
  Future<({String token, UserModel user})> login({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    final cleanPassword = password.trim();

    final response = await _client.post(
      Uri.parse(ApiEndpoints.userLogin),
      headers: _buildHeaders(),
      body: jsonEncode({
        'username': cleanUsername,
        'password': cleanPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Máy chủ phản hồi mã lỗi ${response.statusCode}');
    }

    final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final isSuccess = data['success'] as bool? ?? false;
    final token = (data['token'] as String?) ??
        (data['body'] is Map ? data['body']['token'] as String? : null);

    if (!isSuccess || token == null || token.isEmpty) {
      final msg = data['message'] as String? ??
          'Sai thông tin đăng nhập hoặc tài khoản không tồn tại';
      throw Exception(msg);
    }

    // Tải profile người dùng ngay sau khi có token
    try {
      final user = await getSummaryProfile(token, fallbackMssv: cleanUsername);
      return (token: token, user: user);
    } catch (_) {
      // Fallback nếu api getSummaryProfile gặp sự cố tạm thời
      final avatar = await getAvatarBase64(token);
      final fallbackUser = UserModel(
        mssv: cleanUsername,
        ten: cleanUsername,
        heDaoTao: 'Đại học',
        loaiHinhDt: 'chính quy',
        avatarBase64: avatar,
      );
      return (token: token, user: fallbackUser);
    }
  }

  /// Lấy thông tin tóm tắt hồ sơ sinh viên kèm avatar
  Future<UserModel> getSummaryProfile(
    String token, {
    String? fallbackMssv,
  }) async {
    final response = await _client.get(
      Uri.parse(ApiEndpoints.userSummaryProfile),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể tải hồ sơ sinh viên (${response.statusCode})');
    }

    final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final raw = data['body'] is Map
        ? data['body'] as Map<String, dynamic>
        : (data['data'] is Map ? data['data'] as Map<String, dynamic> : data);

    var user = UserModel.fromJson(raw);
    if (user.mssv.isEmpty && fallbackMssv != null) {
      user = user.copyWith(mssv: fallbackMssv);
    }

    // Tải ảnh avatar đại diện
    try {
      final avatar = await getAvatarBase64(token);
      if (avatar != null && avatar.isNotEmpty) {
        user = user.copyWith(avatarBase64: avatar);
      }
    } catch (_) {
      // Bỏ qua lỗi tải avatar, giữ profile nguyên vẹn
    }

    return user;
  }

  /// Tải ảnh đại diện sinh viên dạng chuỗi Base64
  Future<String?> getAvatarBase64(String token) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiEndpoints.userImageBinary),
        headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': userAgent,
        },
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return base64Encode(response.bodyBytes);
      }
    } catch (_) {
      // Lỗi mạng hoặc server không có avatar
    }
    return null;
  }

  List<ScheduleModel> _parseScheduleResponse(dynamic decoded, [String? fallbackDate]) {
    dynamic raw = decoded;
    if (raw is Map) {
      if (raw['body'] != null) {
        raw = raw['body'];
      } else if (raw['data'] != null) {
        raw = raw['data'];
      } else if (raw['result'] != null) {
        raw = raw['result'];
      } else if (raw['items'] != null) {
        raw = raw['items'];
      }
    }
    if (raw is Map) {
      if (raw['body'] != null) {
        raw = raw['body'];
      } else if (raw['data'] != null) {
        raw = raw['data'];
      } else if (raw['result'] != null) {
        raw = raw['result'];
      }
    }

    if (raw is List) {
      return raw.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        if (fallbackDate != null) {
          map['ngayHoc'] ??= fallbackDate;
        }
        return ScheduleModel.fromJson(map);
      }).toList();
    }

    if (raw is Map) {
      final List<ScheduleModel> list = [];
      raw.forEach((key, val) {
        if (val is List) {
          for (final item in val) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              map['ngayHoc'] ??= key.toString();
              list.add(ScheduleModel.fromJson(map));
            }
          }
        } else if (val is Map) {
          final map = Map<String, dynamic>.from(val);
          map['ngayHoc'] ??= key.toString();
          list.add(ScheduleModel.fromJson(map));
        }
      });
      return list;
    }

    return [];
  }

  /// Lấy lịch học trong ngày (Lịch hôm nay: GET /lichhoc/lichNgay?date=yyyy-MM-dd)
  Future<List<ScheduleModel>> getTodaySchedule(
    String token, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final yyyy = targetDate.year.toString();
    final mm = targetDate.month.toString().padLeft(2, '0');
    final dd = targetDate.day.toString().padLeft(2, '0');
    final dateStr = '$yyyy-$mm-$dd';

    final response = await _client.get(
      Uri.parse('${ApiEndpoints.scheduleDaily}?date=$dateStr'),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi tải lịch học (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return _parseScheduleResponse(decoded, dateStr);
  }

  /// Lấy lịch học theo tuần (GET /lichhoc/tuan?date=yyyy-MM-dd)
  Future<List<ScheduleModel>> getWeeklySchedule(
    String token, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final yyyy = targetDate.year.toString();
    final mm = targetDate.month.toString().padLeft(2, '0');
    final dd = targetDate.day.toString().padLeft(2, '0');
    final dateStr = '$yyyy-$mm-$dd';

    final response = await _client.get(
      Uri.parse('${ApiEndpoints.scheduleWeekly}?date=$dateStr'),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi tải lịch học tuần (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return _parseScheduleResponse(decoded);
  }

  /// Lấy lịch học theo tháng (GET /lichhoc/thang?date=yyyy-MM-01)
  Future<List<MonthScheduleDay>> getMonthlySchedule(
    String token, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final yyyy = targetDate.year.toString();
    final mm = targetDate.month.toString().padLeft(2, '0');
    final dateStr = '$yyyy-$mm-01';

    final response = await _client.get(
      Uri.parse('${ApiEndpoints.scheduleMonthly}?date=$dateStr'),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Lỗi tải lịch học tháng (${response.statusCode})');
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    dynamic raw = decoded;
    if (raw is Map) {
      if (raw['body'] != null) {
        raw = raw['body'];
      } else if (raw['data'] != null) {
        raw = raw['data'];
      }
    }

    if (raw is List) {
      return raw
          .map((item) =>
              MonthScheduleDay.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    return [];
  }

  /// Lấy danh sách menu tiện ích hệ thống (sideMenu) từ Portal UTH
  Future<List<PortalMenuItem>> getSideMenu(String token) async {
    final response = await _client.get(
      Uri.parse(ApiEndpoints.menuSide),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể tải menu hệ thống (${response.statusCode})');
    }

    final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final rawList = data['body'] ?? data['data'] ?? data;
    if (rawList is List) {
      return rawList
          .map((item) =>
              PortalMenuItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  /// Lấy danh sách menu truy cập nhanh (mainMenu) từ Portal UTH
  Future<List<PortalMenuItem>> getMainMenu(String token) async {
    final response = await _client.get(
      Uri.parse(ApiEndpoints.menuMain),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể tải menu chính (${response.statusCode})');
    }

    final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final rawList = data['body'] ?? data['data'] ?? data;
    if (rawList is List) {
      return rawList
          .map((item) =>
              PortalMenuItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  /// Lấy tiến độ học tập (canDat, hienTai)
  Future<AcademicProgress> getAcademicProgress(String token) async {
    final response = await _client.get(
      Uri.parse(ApiEndpoints.academicProgress),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể tải tiến độ học tập (${response.statusCode})');
    }

    final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final raw = data['body'] is Map
        ? data['body'] as Map<String, dynamic>
        : (data['data'] is Map ? data['data'] as Map<String, dynamic> : data);

    return AcademicProgress.fromJson(raw);
  }

  /// Lấy danh sách các học kỳ
  Future<List<Semester>> getSemesters(String token) async {
    final response = await _client.get(
      Uri.parse(ApiEndpoints.academicSemesters),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể tải danh sách học kỳ (${response.statusCode})');
    }

    final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final rawList = data['body'] ?? data['data'] ?? data;
    if (rawList is List) {
      return rawList
          .map((item) =>
              Semester.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  /// Lấy danh sách môn học theo học kỳ
  Future<List<CourseSubject>> getCoursesBySemester(
    String token,
    int semesterId,
  ) async {
    final response = await _client.get(
      Uri.parse('${ApiEndpoints.academicCoursesBySemester}/$semesterId'),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải danh sách môn học ($semesterId): ${response.statusCode}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final rawList = data['body'] ?? data['data'] ?? data;
    if (rawList is List) {
      return rawList
          .map((item) =>
              CourseSubject.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  /// Lấy điểm tổng kết các môn theo học kỳ
  Future<List<CourseGrade>> getGradesBySemester(
    String token,
    int semesterId,
  ) async {
    final response = await _client.get(
      Uri.parse('${ApiEndpoints.academicGradesBySemester}/$semesterId'),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể tải kết quả điểm ($semesterId): ${response.statusCode}',
      );
    }

    final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final rawList = data['body'] ?? data['data'] ?? data;
    if (rawList is List) {
      return rawList
          .map((item) =>
              CourseGrade.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  /// Lấy toàn bộ bảng điểm học tập (hoctap/bangdiem)
  Future<List<Map<String, dynamic>>> getFullTranscript(String token) async {
    final response = await _client.get(
      Uri.parse(ApiEndpoints.academicTranscript),
      headers: _buildHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Không thể tải bảng điểm (${response.statusCode})');
    }

    final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final rawList = data['body'] ?? data['data'];
    if (rawList is List) {
      return rawList
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    return [];
  }

  /// Lấy danh sách thông báo sinh viên từ cổng Portal (/notification/getNote)
  Future<List<Map<String, dynamic>>> getNotifications(String token) async {
    try {
      final response = await _client
          .get(
            Uri.parse(ApiEndpoints.notifications),
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode != 200) {
        return [];
      }

      final Map<String, dynamic> data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      final rawList = data['body'] ?? data['data'];
      if (rawList is List) {
        return rawList
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return [];
    } catch (_) {
      // Timeout hoặc lỗi kết nối -> trả về rỗng ngay lập tức, không để màn hình treo
      return [];
    }
  }
}

final portalApiClientProvider = Provider<PortalApiClient>((ref) {
  return PortalApiClient();
});

// Alias for backward compatibility
typedef UthPortalService = PortalApiClient;
final uthPortalServiceProvider = portalApiClientProvider;
