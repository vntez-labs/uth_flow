import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_flow/features/notification/domain/notification_model.dart';
import 'package:uth_flow/features/notification/presentation/controllers/notification_controller.dart';
import 'package:uth_flow/features/tabs/presentation/screens/notifications_screen.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/home_header_widget.dart';

void main() {
  group('NotificationModel tests', () {
    test('NotificationModel.fromJson parses fields correctly', () {
      final json = {
        'id': 101,
        'title': 'Lịch thi học kỳ 1 năm học 2026-2027',
        'content': 'Sinh viên kiểm tra phòng thi và thời gian thi chi tiết.',
        'createdAt': '2026-10-20T10:00:00Z',
        'isRead': false,
      };

      final model = NotificationModel.fromJson(json);
      expect(model.id, '101');
      expect(model.title, 'Lịch thi học kỳ 1 năm học 2026-2027');
      expect(model.content, contains('phòng thi'));
      expect(model.isRead, isFalse);
      expect(model.createdAt, isNotNull);
    });

    test('NotificationModel.fromJson handles empty map gracefully', () {
      final model = NotificationModel.fromJson({});
      expect(model.title, 'Thông báo UTH');
      expect(model.isRead, isFalse);
    });
  });

  group('NotificationsScreen widget tests', () {
    testWidgets('Renders empty state when notification list is empty',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Thông báo'), findsOneWidget);
      expect(find.text('Tính năng đang được phát triển'), findsOneWidget);
      expect(find.text('Chưa có thông báo mới'), findsOneWidget);
      expect(find.text('Mở trang Thông báo trên Portal UTH'), findsOneWidget);
    });

    testWidgets(
        'Renders notification list and tapping item opens "Tính năng đang được phát triển" modal',
        (tester) async {
      final mockItems = [
        const NotificationModel(
          id: '1',
          title: 'Thông báo đóng học phí đợt 2',
          content: 'Hạn cuối đóng học phí đến hết ngày 30/10/2026.',
        ),
        const NotificationModel(
          id: '2',
          title: 'Lịch học bổ sung môn Kỹ thuật lập trình',
          content: 'Lớp học vào thứ 7 tuần này tại phòng A302.',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationsProvider.overrideWith((ref) => Future.value(mockItems)),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Thông báo đóng học phí đợt 2'), findsOneWidget);
      expect(find.text('Lịch học bổ sung môn Kỹ thuật lập trình'), findsOneWidget);

      // Tap first item
      await tester.tap(find.text('Thông báo đóng học phí đợt 2'));
      await tester.pumpAndSettle();

      // Modal bottom sheet appears
      expect(find.text('Tính năng đang được phát triển'), findsNWidgets(2));
      expect(find.text('Mở Portal UTH'), findsOneWidget);
      expect(find.text('Đóng'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();

      expect(find.text('Mở Portal UTH'), findsNothing);
      expect(find.text('Tính năng đang được phát triển'), findsOneWidget);
    });
  });

  group('HomeHeaderWidget notification badge tests', () {
    testWidgets('Renders badge count on bell icon when count > 0',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationCountProvider.overrideWithValue(5),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomeHeaderWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('No badge number rendered when count is 0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationCountProvider.overrideWithValue(0),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomeHeaderWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('0'), findsNothing);
    });
  });
}
