import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uth_flow/core/widgets/scaffold_with_nav_bar.dart';
import 'package:uth_flow/features/auth/domain/models/auth_state.dart';
import 'package:uth_flow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:uth_flow/features/auth/presentation/screens/auth_screen.dart';
import 'package:uth_flow/features/auth/presentation/screens/student_card_screen.dart';
import 'package:uth_flow/features/schedule/presentation/screens/schedule_screen.dart';
import 'package:uth_flow/features/tabs/presentation/screens/index.dart';

// Key điều hướng cấp Root và từng Branch để giữ độc lập State
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'homeNav');
final _scheduleNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'scheduleNav',
);
final _utilitiesNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'utilitiesNav',
);
final _settingsNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'settingsNav',
);

/// Lớp lắng nghe thay đổi AuthState để kích hoạt GoRouter làm mới điều hướng (refreshListenable)
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, current) => notifyListeners(),
    );
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // 1. Chưa đăng nhập: Mọi trang đều bắt buộc phải đăng nhập
      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // 2. Đã đăng nhập nhưng đang ở trang /login -> chuyển về trang chủ /home
      if (isLoggingIn) {
        return '/home';
      }

      // 3. Đã đăng nhập và đang ở các trang hợp lệ -> cho phép tiếp tục
      return null;
    },
    routes: [
      // ----------------- TRANG XÁC THỰC / ĐĂNG NHẬP -----------------
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const AuthScreen(),
      ),

      // ----------------- TRANG THÔNG BÁO (TỪ HEADER CHUÔNG) -----------------
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionDuration: const Duration(milliseconds: 160),
          reverseTransitionDuration: const Duration(milliseconds: 130),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeOut).animate(animation),
              child: child,
            );
          },
        ),
      ),

      // ----------------- THẺ SINH VIÊN ĐIỆN TỬ -----------------
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/student-card',
        name: 'studentCard',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const StudentCardScreen(),
          transitionDuration: const Duration(milliseconds: 160),
          reverseTransitionDuration: const Duration(milliseconds: 130),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeOut).animate(animation),
              child: child,
            );
          },
        ),
      ),

      // ----------------- CỤM TAB CHÍNH CỦA ỨNG DỤNG (4 TAB) -----------------
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return navigationShell;
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return ScaffoldWithNavBar(
            navigationShell: navigationShell,
            children: children,
          );
        },
        branches: [
          // ----------------- TAB 0: TRANG CHỦ (LỊCH & DEADLINE) -----------------
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // ----------------- TAB 1: LỊCH HỌC & THỜI KHÓA BIỂU (THÁNG) -----------------
          StatefulShellBranch(
            navigatorKey: _scheduleNavigatorKey,
            routes: [
              GoRoute(
                path: '/schedule',
                name: 'schedule',
                builder: (context, state) => const ScheduleScreen(),
              ),
              GoRoute(
                path: '/academics',
                redirect: (context, state) => '/profile',
              ),
            ],
          ),

          // ----------------- TAB 2: TIỆN ÍCH (DỊCH VỤ & LỐI TẮT UTH) -----------------
          StatefulShellBranch(
            navigatorKey: _utilitiesNavigatorKey,
            routes: [
              GoRoute(
                path: '/utilities',
                name: 'utilities',
                builder: (context, state) => const UtilitiesScreen(),
              ),
            ],
          ),

          // ----------------- TAB 3: HỒ SƠ SINH VIÊN -----------------
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: '/settings',
                name: 'settings',
                redirect: (context, state) => '/profile',
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
