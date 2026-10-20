import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:uth_flow/features/schedule/domain/schedule_model.dart';
import 'package:uth_flow/features/schedule/presentation/controllers/schedule_controller.dart';
import 'package:uth_flow/features/schedule/presentation/screens/schedule_screen.dart';

class MockScheduleRepository implements ScheduleRepository {
  final List<ScheduleModel> mockClasses;

  MockScheduleRepository({this.mockClasses = const []});

  @override
  void clearCache() {}

  @override
  Future<DailyScheduleData> getDailySchedule(String token) async {
    return DailyScheduleData(todayClasses: mockClasses);
  }

  @override
  Future<List<ScheduleModel>> getScheduleByDate(
      String token, DateTime date) async {
    return mockClasses;
  }

  @override
  Future<List<ScheduleModel>> getWeeklySchedule(String token,
      {DateTime? date}) async {
    return mockClasses;
  }

  @override
  Future<List<MonthScheduleDay>> getMonthlySchedule(String token,
      {DateTime? date}) async {
    if (mockClasses.isEmpty) return [];
    return [
      MonthScheduleDay(
        date: mockClasses.first.ngayHoc ?? '20/10/2026',
        total: mockClasses.length,
        subjects: mockClasses
            .map((c) => MonthScheduleSubject(
                  name: c.tenMonHoc,
                  nameToDisplay: c.tenMonHoc,
                ))
            .toList(),
      ),
    ];
  }
}

void main() {
  testWidgets(
      'ScheduleScreen renders monthly calendar grid, dots, and class schedule list',
      (tester) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final testClasses = [
      ScheduleModel(
        tenMonHoc: 'Lập trình ứng dụng di động UTH',
        maHocPhan: '010100085401',
        tenPhong: 'A.302',
        timeToDisplay: '07:00 - 09:15',
        ngayHoc: todayStr,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(
            MockScheduleRepository(mockClasses: testClasses),
          ),
        ],
        child: const MaterialApp(
          home: ScheduleScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify AppBar
    expect(find.text('Lịch học & Thời khóa biểu'), findsOneWidget);
    expect(find.text('Hôm nay'), findsWidgets);

    // Verify days of the week headers are displayed
    expect(find.text('T2'), findsOneWidget);
    expect(find.text('T3'), findsOneWidget);
    expect(find.text('T4'), findsOneWidget);
    expect(find.text('T5'), findsOneWidget);
    expect(find.text('T6'), findsOneWidget);
    expect(find.text('T7'), findsOneWidget);
    expect(find.text('CN'), findsOneWidget);

    // Check for class content and time directly below calendar
    expect(find.text('Lập trình ứng dụng di động UTH'), findsOneWidget);
    expect(find.text('07:00 - 09:15'), findsOneWidget);
  });

  testWidgets(
      'ScheduleScreen updates class schedule list directly below calendar when day is tapped',
      (tester) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final testClasses = [
      ScheduleModel(
        tenMonHoc: 'Lập trình ứng dụng di động UTH',
        maHocPhan: '010100085401',
        tenPhong: 'A.302',
        timeToDisplay: '07:00 - 09:15',
        ngayHoc: todayStr,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(
            MockScheduleRepository(mockClasses: testClasses),
          ),
        ],
        child: const MaterialApp(
          home: ScheduleScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap on the day number
    final todayDayFinder = find.text('${now.day}');
    expect(todayDayFinder, findsWidgets);
    await tester.ensureVisible(todayDayFinder.first);
    await tester.tap(todayDayFinder.first);
    await tester.pumpAndSettle();

    // Verify class card is displayed directly below calendar (no bottom sheet)
    expect(find.text('Lập trình ứng dụng di động UTH'), findsOneWidget);
    expect(find.text('07:00 - 09:15'), findsOneWidget);
  });

  testWidgets('ScheduleScreen renders empty state when there are no classes',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(
            MockScheduleRepository(mockClasses: const []),
          ),
        ],
        child: const MaterialApp(
          home: ScheduleScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Check for empty state
    expect(find.text('Không có môn học'), findsOneWidget);
    expect(find.text('Hôm nay'), findsWidgets);
  });

  testWidgets('ScheduleScreen navigates between months cleanly',
      (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scheduleRepositoryProvider.overrideWithValue(
            MockScheduleRepository(mockClasses: const []),
          ),
        ],
        child: const MaterialApp(
          home: ScheduleScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify current month header appears
    expect(find.textContaining('Tháng ${now.month}'), findsOneWidget);

    // Tap right arrow to go to next month
    await tester.tap(find.byIcon(SolarIconsOutline.altArrowRight).first);
    await tester.pumpAndSettle();

    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    expect(find.textContaining('Tháng $nextMonth'), findsOneWidget);

    // Tap 'Hôm nay' to reset to current month
    await tester.tap(find.text('Hôm nay').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Tháng ${now.month}'), findsOneWidget);
  });
}
