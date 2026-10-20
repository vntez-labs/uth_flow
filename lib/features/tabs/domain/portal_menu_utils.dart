import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uth_flow/core/storage/moodle_token_manager.dart';
import 'package:uth_flow/features/tabs/domain/portal_menu_model.dart';

class PortalMenuUtils {
  static Future<void> openRoute(
    BuildContext context,
    String? route,
    String name,
  ) async {
    if (route == null || route.trim().isEmpty) {
      final nameLower = name.toLowerCase();
      if (nameLower.contains('lịch học') || nameLower.contains('thời khóa biểu')) {
        GoRouter.of(context).go('/schedule');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tính năng "$name" đang được cập nhật'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final trimmed = route.trim();
    final lowerRoute = trimmed.toLowerCase() + name.toLowerCase();
    if (lowerRoute.contains('schedule') ||
        lowerRoute.contains('thời khóa biểu') ||
        lowerRoute.contains('lichhoc')) {
      GoRouter.of(context).go('/schedule');
      return;
    }
    final String resolvedUrl;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      resolvedUrl = trimmed;
    } else {
      final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
      resolvedUrl = 'https://portal.ut.edu.vn$path';
    }

    final fullUrl = MoodleTokenManager.appendTokenIfNeeded(resolvedUrl);

    final uri = Uri.tryParse(fullUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đường dẫn không hợp lệ: $fullUrl'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở liên kết: $fullUrl'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi mở trang: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static IconData getItemIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('đào tạo trực tuyến') ||
        lower.contains('moodle') ||
        lower.contains('lms')) {
      return SolarIconsOutline.laptop2;
    }
    if (lower.contains('kết quả') ||
        lower.contains('điểm') ||
        lower.contains('transcript')) {
      return SolarIconsOutline.diploma;
    }
    if (lower.contains('đăng ký học phần') ||
        lower.contains('coursesregistration') ||
        lower.contains('đăng ký')) {
      return SolarIconsOutline.pen2;
    }
    if (lower.contains('khung') || lower.contains('chương trình')) {
      return SolarIconsOutline.diagramUp;
    }
    if (lower.contains('điều kiện')) {
      return SolarIconsOutline.checkCircle;
    }
    if (lower.contains('khảo sát') || lower.contains('survey')) {
      return SolarIconsOutline.chatSquareCheck;
    }
    if (lower.contains('tin học') || lower.contains('ngôn ngữ')) {
      return SolarIconsOutline.global;
    }
    if (lower.contains('công nợ') ||
        lower.contains('học phí') ||
        lower.contains('tuition')) {
      return SolarIconsOutline.wallet2;
    }
    if (lower.contains('thanh toán') || lower.contains('payment')) {
      return SolarIconsOutline.card2;
    }
    if (lower.contains('hỗ trợ') || lower.contains('support')) {
      return SolarIconsOutline.headphonesSquare;
    }
    if (lower.contains('dịch vụ') ||
        lower.contains('giấy') ||
        lower.contains('paper')) {
      return SolarIconsOutline.documentText;
    }
    if (lower.contains('chi tiết') ||
        lower.contains('hồ sơ') ||
        lower.contains('profile')) {
      return SolarIconsOutline.userId;
    }
    if (lower.contains('cập nhật') || lower.contains('edit')) {
      return SolarIconsOutline.penNewSquare;
    }
    if (lower.contains('tin tức') || lower.contains('news')) {
      return SolarIconsOutline.documentText;
    }
    return SolarIconsOutline.linkSquare;
  }

  static Color getCategoryColor(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('học tập') || lower.contains('đào tạo')) {
      return const Color(0xFF008689);
    }
    if (lower.contains('công nợ') || lower.contains('học phí')) {
      return const Color(0xFFD97706);
    }
    if (lower.contains('hỗ trợ')) {
      return const Color(0xFF0284C7);
    }
    if (lower.contains('thông tin')) {
      return const Color(0xFF6366F1);
    }
    return const Color(0xFF008689);
  }

  static IconData getCategoryIcon(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('học tập') || lower.contains('đào tạo')) {
      return SolarIconsOutline.squareAcademicCap;
    }
    if (lower.contains('công nợ') || lower.contains('học phí')) {
      return SolarIconsOutline.wallet2;
    }
    if (lower.contains('hỗ trợ')) {
      return SolarIconsOutline.headphonesSquare;
    }
    if (lower.contains('thông tin')) {
      return SolarIconsOutline.infoSquare;
    }
    return SolarIconsOutline.widget;
  }

  static List<PortalMenuItem> getFallbackSideMenu() {
    return const [
      PortalMenuItem(
        id: 520,
        name: 'Học tập & Đào tạo',
        children: [
          PortalMenuItem(
            id: 5201,
            name: 'Đào tạo trực tuyến (LMS)',
            route: 'https://courses.ut.edu.vn',
          ),
          PortalMenuItem(
            id: 5202,
            name: 'Kết quả học tập & Bảng điểm',
            route: '/transcript',
          ),
          PortalMenuItem(
            id: 5203,
            name: 'Đăng ký học phần',
            route: '/coursesregistration',
          ),
          PortalMenuItem(
            id: 5204,
            name: 'Chương trình khung đào tạo',
            route: '/educationprogram',
          ),
          PortalMenuItem(
            id: 5205,
            name: 'Đăng ký môn học điều kiện',
            route: '/conditional',
          ),
          PortalMenuItem(
            id: 5206,
            name: 'Khảo sát sinh viên',
            route: '/studentsurvey',
          ),
          PortalMenuItem(
            id: 5207,
            name: 'Đào tạo tin học - ngôn ngữ',
            route: 'https://thnn.ut.edu.vn',
          ),
        ],
      ),
      PortalMenuItem(
        id: 530,
        name: 'Tài chính & Công nợ',
        children: [
          PortalMenuItem(
            id: 5301,
            name: 'Tra cứu công nợ & Học phí',
            route: '/tuition',
          ),
          PortalMenuItem(
            id: 5302,
            name: 'Cổng thanh toán trực tuyến',
            route: 'https://payment.ut.edu.vn',
          ),
        ],
      ),
      PortalMenuItem(
        id: 540,
        name: 'Dịch vụ & Hỗ trợ sinh viên',
        children: [
          PortalMenuItem(
            id: 5401,
            name: 'Hỗ trợ trực tuyến sinh viên',
            route: 'https://support.ut.edu.vn',
          ),
          PortalMenuItem(
            id: 5402,
            name: 'Dịch vụ sinh viên (Cấp giấy xác nhận)',
            route: '/studentpaper',
          ),
        ],
      ),
      PortalMenuItem(
        id: 510,
        name: 'Thông tin chung',
        children: [
          PortalMenuItem(
            id: 5101,
            name: 'Thông tin chi tiết sinh viên',
            route: '/infordetail',
          ),
          PortalMenuItem(
            id: 5102,
            name: 'Cập nhật thông tin hồ sơ',
            route: '/editprofile',
          ),
          PortalMenuItem(
            id: 5103,
            name: 'Tin tức & Thông báo UTH',
            route: '/newfeeds/368',
          ),
        ],
      ),
    ];
  }
}
