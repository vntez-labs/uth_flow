import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_flow/features/tabs/presentation/screens/learning_screen.dart';
import 'package:uth_flow/features/tabs/presentation/screens/settings_screen.dart';
import 'package:uth_flow/features/tabs/presentation/screens/utilities_screen.dart';

void main() {
  testWidgets('Renders LearningScreen without errors', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LearningScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Học tập'), findsOneWidget);
    expect(find.text('Tổng quan GPA'), findsOneWidget);
    expect(find.text('Tiến độ học tập'), findsOneWidget);
    expect(find.text('Kết quả học tập'), findsOneWidget);
    expect(find.text('Lớp học phần'), findsOneWidget);
  });

  testWidgets('Renders UtilitiesScreen without errors', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: UtilitiesScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Tiện ích'), findsOneWidget);
    expect(find.text('Truy cập nhanh'), findsOneWidget);
    expect(find.text('Đào tạo LMS'), findsOneWidget);
  });

  testWidgets('Renders SettingsScreen without errors', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Hồ sơ sinh viên'), findsOneWidget);
    expect(find.text('Tổng quan GPA'), findsOneWidget);
    expect(find.text('Tiến độ học tập'), findsOneWidget);
    expect(find.text('Kết quả học tập'), findsOneWidget);
    expect(find.text('Lớp học phần'), findsOneWidget);
    expect(find.text('Thông tin đào tạo'), findsOneWidget);
    expect(find.text('Thông tin cá nhân'), findsOneWidget);
    expect(find.text('Đăng xuất khỏi thiết bị'), findsOneWidget);
  });
}
