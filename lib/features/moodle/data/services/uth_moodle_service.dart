import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uth_flow/features/moodle/domain/moodle_event_model.dart';

class UthMoodleService {
  static const String moodleBaseUrl = 'https://courses.ut.edu.vn';
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const MethodChannel _moodleChannel =
      MethodChannel('com.example.uth_flow/moodle');

  http.Client _createClient() => http.Client();

  /// Lấy danh sách hạn chót bài tập trên Moodle
  Future<List<MoodleEventModel>> getDeadlines({
    required String username,
    required String password,
  }) async {
    // Trên Android: Sử dụng OkHttp native qua MethodChannel để vượt qua Cloudflare TLS check
    if (Platform.isAndroid) {
      return _getDeadlinesViaAndroid(
        username: username,
        password: password,
      );
    }

    // Trên nền tảng Desktop (Linux/macOS), dùng curl engine trực tiếp để xử lý Cloudflare challenge như uth-sync
    if (Platform.isLinux || Platform.isMacOS) {
      return _getDeadlinesViaCurl(username: username, password: password);
    }

    return _getDeadlinesViaHttpClient(username: username, password: password);
  }

  /// Lấy deadline qua OkHttp Native trên Android
  Future<List<MoodleEventModel>> _getDeadlinesViaAndroid({
    required String username,
    required String password,
  }) async {
    final String? resJson = await _moodleChannel.invokeMethod<String>(
      'getMoodleDeadlines',
      {
        'username': username,
        'password': password,
      },
    );

    if (resJson != null && resJson.isNotEmpty) {
      final dynamic data = jsonDecode(resJson);
      if (data is List && data.isNotEmpty) {
        if (data[0]['error'] == true) {
          final msg = data[0]['exception']?['message'] as String? ??
              'Lỗi kết nối Moodle';
          throw Exception(msg);
        }
        if (data[0]['data']?['events'] is List) {
          final events = data[0]['data']['events'] as List;
          return events
              .map((e) => MoodleEventModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    }
    return [];
  }

  /// Phương thức sử dụng curl process (hoạt động tối ưu trên môi trường desktop mô phỏng Chrome TLS)
  Future<List<MoodleEventModel>> _getDeadlinesViaCurl({
    required String username,
    required String password,
  }) async {
    final tempDir = Directory.systemTemp;
    final cookieFile =
        '${tempDir.path}/moodle_cookies_${username.replaceAll(RegExp(r'\W+'), '_')}.txt';

    // 1. Tải trang đăng nhập để bóc logintoken
    final step1 = await Process.run('curl', [
      '-s',
      '-c', cookieFile,
      '-b', cookieFile,
      '-A', userAgent,
      '$moodleBaseUrl/login/index.php',
    ]);

    final html1 = step1.stdout as String;
    final tokenMatch =
        RegExp(r'name="logintoken"\s+value="([^"]+)"').firstMatch(html1);

    final logintoken = tokenMatch?.group(1);
    if (logintoken == null && !html1.contains('courses.php')) {
      throw Exception('Không tìm thấy logintoken Moodle');
    }

    // 2. Submit thông tin đăng nhập
    if (logintoken != null) {
      await Process.run('curl', [
        '-s',
        '-c', cookieFile,
        '-b', cookieFile,
        '-A', userAgent,
        '-H', 'Origin: $moodleBaseUrl',
        '-H', 'Referer: $moodleBaseUrl/login/index.php',
        '-d',
        'anchor=&logintoken=$logintoken&username=${Uri.encodeQueryComponent(username)}&password=${Uri.encodeQueryComponent(password)}',
        '$moodleBaseUrl/login/index.php',
      ]);
    }

    // 3. Tải trang courses để lấy sesskey
    final step3 = await Process.run('curl', [
      '-s',
      '-c', cookieFile,
      '-b', cookieFile,
      '-A', userAgent,
      '$moodleBaseUrl/my/courses.php',
    ]);

    final html3 = step3.stdout as String;
    final sesskeyMatch = RegExp(r'"sesskey":"([^"]+)"').firstMatch(html3) ??
        RegExp(r'name="sesskey"\s+value="([^"]+)"').firstMatch(html3);

    final sesskey = sesskeyMatch?.group(1);
    if (sesskey == null || sesskey.isEmpty) {
      throw Exception('Đăng nhập Moodle không thành công (thiếu sesskey)');
    }

    // 4. Gọi API core_calendar_get_action_events_by_timesort
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final startTs = nowSeconds - (365 * 24 * 60 * 60);
    final endTs = nowSeconds + (365 * 24 * 60 * 60);

    final payload = jsonEncode([
      {
        'index': 0,
        'methodname': 'core_calendar_get_action_events_by_timesort',
        'args': {
          'timesortfrom': startTs,
          'timesortto': endTs,
          'limitnum': 50,
        },
      },
      {
        'index': 1,
        'methodname':
            'core_course_get_enrolled_courses_by_timeline_classification',
        'args': {
          'offset': 0,
          'limit': 100,
          'classification': 'all',
          'sort': 'ul.timeaccess desc',
          'customfieldname': '',
          'customfieldvalue': '',
        },
      }
    ]);

    final step4 = await Process.run('curl', [
      '-s',
      '-c', cookieFile,
      '-b', cookieFile,
      '-A', userAgent,
      '-H', 'Content-Type: application/json',
      '-H', 'Accept: application/json, text/plain, */*',
      '-d', payload,
      '$moodleBaseUrl/lib/ajax/service.php?sesskey=$sesskey&info=core_calendar_get_action_events_by_timesort,core_course_get_enrolled_courses_by_timeline_classification',
    ]);

    final resJson = step4.stdout as String;
    final dynamic data = jsonDecode(resJson);

    if (data is List && data.isNotEmpty && data[0]['data']?['events'] is List) {
      final events = data[0]['data']['events'] as List;
      return events
          .map((e) => MoodleEventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Phương thức sử dụng HTTP Client (chạy với Cronet trên Android)
  Future<List<MoodleEventModel>> _getDeadlinesViaHttpClient({
    required String username,
    required String password,
  }) async {
    final client = _createClient();
    final Map<String, String> cookies = {};

    void updateCookies(http.Response res) {
      final raw = res.headers['set-cookie'];
      if (raw != null) {
        for (final item in raw.split(',')) {
          final cookiePart = item.split(';').first.trim();
          final eqIdx = cookiePart.indexOf('=');
          if (eqIdx > 0) {
            cookies[cookiePart.substring(0, eqIdx)] =
                cookiePart.substring(eqIdx + 1);
          }
        }
      }
    }

    String buildCookieHeader() {
      return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }

    try {
      // 1. Tải trang login moodle
      final loginPageRes = await client.get(
        Uri.parse('$moodleBaseUrl/login/index.php'),
        headers: {
          'User-Agent': userAgent,
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        },
      );
      updateCookies(loginPageRes);

      final loginHtml = utf8.decode(loginPageRes.bodyBytes);
      final logintokenMatch =
          RegExp(r'name="logintoken"\s+value="([^"]+)"').firstMatch(loginHtml);
      final logintoken = logintokenMatch?.group(1);

      if (logintoken != null) {
        // 2. Submit login
        final loginSubmitRes = await client.post(
          Uri.parse('$moodleBaseUrl/login/index.php'),
          headers: {
            'User-Agent': userAgent,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Origin': moodleBaseUrl,
            'Referer': '$moodleBaseUrl/login/index.php',
            'Cookie': buildCookieHeader(),
          },
          body: {
            'anchor': '',
            'logintoken': logintoken,
            'username': username,
            'password': password,
          },
        );
        updateCookies(loginSubmitRes);
      }

      // 3. Tải courses.php lấy sesskey
      final coursesRes = await client.get(
        Uri.parse('$moodleBaseUrl/my/courses.php'),
        headers: {
          'User-Agent': userAgent,
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Cookie': buildCookieHeader(),
        },
      );
      updateCookies(coursesRes);

      final coursesHtml = utf8.decode(coursesRes.bodyBytes);
      final sesskeyMatch =
          RegExp(r'"sesskey":"([^"]+)"').firstMatch(coursesHtml) ??
              RegExp(r'name="sesskey"\s+value="([^"]+)"')
                  .firstMatch(coursesHtml);
      final sesskey = sesskeyMatch?.group(1);

      if (sesskey == null || sesskey.isEmpty) {
        throw Exception('Không tìm thấy sesskey Moodle');
      }

      // 4. Lấy lịch
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final startTs = nowSeconds - (365 * 24 * 60 * 60);
      final endTs = nowSeconds + (365 * 24 * 60 * 60);

      final eventsRes = await client.post(
        Uri.parse(
          '$moodleBaseUrl/lib/ajax/service.php?sesskey=$sesskey&info=core_calendar_get_action_events_by_timesort,core_course_get_enrolled_courses_by_timeline_classification',
        ),
        headers: {
          'User-Agent': userAgent,
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/plain, */*',
          'Cookie': buildCookieHeader(),
        },
        body: jsonEncode([
          {
            'index': 0,
            'methodname': 'core_calendar_get_action_events_by_timesort',
            'args': {
              'timesortfrom': startTs,
              'timesortto': endTs,
              'limitnum': 50,
            },
          },
          {
            'index': 1,
            'methodname':
                'core_course_get_enrolled_courses_by_timeline_classification',
            'args': {
              'offset': 0,
              'limit': 100,
              'classification': 'all',
              'sort': 'ul.timeaccess desc',
              'customfieldname': '',
              'customfieldvalue': '',
            },
          }
        ]),
      );

      final dynamic data = jsonDecode(utf8.decode(eventsRes.bodyBytes));
      if (data is List &&
          data.isNotEmpty &&
          data[0]['data']?['events'] is List) {
        final events = data[0]['data']['events'] as List;
        return events
            .map((e) => MoodleEventModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    } finally {
      client.close();
    }
  }
}

final uthMoodleServiceProvider = Provider<UthMoodleService>((ref) {
  return UthMoodleService();
});
