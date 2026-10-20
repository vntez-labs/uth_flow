import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_flow/features/schedule/domain/schedule_model.dart';
import 'package:uth_flow/features/schedule/presentation/controllers/schedule_controller.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/home_header_widget.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/home_schedule_section.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/quick_shortcuts_section.dart';

void main() {
  testWidgets('HomeHeaderWidget renders user greeting and quick actions',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HomeHeaderWidget(),
          ),
        ),
      ),
    );

    expect(find.textContaining('Chào'), findsOneWidget);
    expect(find.text('Quét QR'), findsOneWidget);
    expect(find.text('Thẻ SV'), findsOneWidget);
    expect(find.text('Dịch vụ SV'), findsOneWidget);
    expect(find.text('Hỗ trợ TT'), findsOneWidget);
  });

  testWidgets('HomeScheduleSection renders title and empty or timeline card',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HomeScheduleSection(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Lịch học'), findsOneWidget);
    expect(find.text('Xem tất cả'), findsOneWidget);
  });

  testWidgets(
      'HomeScheduleSection renders tomorrow schedule when today is free without "Lịch ngày mai" badge or "Vào LMS Courses" button',
      (tester) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final mockTomorrowItem = ScheduleModel(
      tenMonHoc: 'Lập trình ứng dụng di động',
      maHocPhan: 'CNTT01',
      tenPhong: 'B102',
      ngayHoc: '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}',
      tietBatDau: 1,
      soTiet: 3,
      tuGio: '07:00',
      denGio: '09:15',
      rawJson: const {'lmsUrl': 'https://courses.ut.edu.vn/course/view.php?id=123'},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyScheduleProvider.overrideWith(
            (ref) async => DailyScheduleData(
              todayClasses: [],
              tomorrowClasses: [mockTomorrowItem],
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeScheduleSection(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifies today is marked free
    expect(find.text('Hôm nay không có lịch học 🎉'), findsOneWidget);

    // Verifies "Lịch ngày mai" badge is removed
    expect(find.text('Lịch ngày mai'), findsNothing);

    // Verifies "Vào LMS Courses" button is removed
    expect(find.text('Vào LMS Courses'), findsNothing);

    // Verifies tomorrow's class is displayed
    expect(find.textContaining('Lập trình ứng dụng di động'), findsOneWidget);

    // Tapping the card should work cleanly
    await tester.tap(find.textContaining('Lập trình ứng dụng di động'));
    await tester.pump();
  });

  testWidgets('QuickShortcutsSection renders shortcut cards', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QuickShortcutsSection(),
        ),
      ),
    );

    expect(find.text('Truy cập nhanh'), findsOneWidget);
    expect(find.text('Đào tạo LMS'), findsOneWidget);
    expect(find.text('Bảng điểm & KQHT'), findsOneWidget);
    expect(find.text('Đăng ký học phần'), findsOneWidget);
  });
}
