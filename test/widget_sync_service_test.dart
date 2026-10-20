import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uth_flow/core/services/widget_sync_service.dart';
import 'package:uth_flow/features/schedule/data/repositories/schedule_repository.dart';
import 'package:uth_flow/features/schedule/domain/schedule_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('WidgetSyncService syncSchedule saves formatted json to SharedPreferences', () async {
    const class1 = ScheduleModel(
      tenMonHoc: 'Lập trình di động',
      timeToDisplay: '07:00 - 09:15',
      tenPhong: 'B201',
      coSo: 'Cơ sở 1',
    );
    const class2 = ScheduleModel(
      tenMonHoc: 'Toán ứng dụng',
      timeToDisplay: '09:30 - 11:45',
      tenPhong: 'A102',
    );

    const dailyData = DailyScheduleData(
      todayClasses: [class1],
      tomorrowClasses: [class2],
      isTodayFinished: false,
    );

    await WidgetSyncService.syncSchedule(dailyData);

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('widget_schedule_data');
    expect(jsonStr, isNotNull);
    expect(jsonStr, contains('Lập trình di động'));
    expect(jsonStr, contains('Toán ứng dụng'));
    expect(jsonStr, contains('hasTodayClasses'));
    expect(jsonStr, contains('hasTomorrowClasses'));
  });

  test('WidgetSyncService clearWidget removes data from SharedPreferences', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('widget_schedule_data', '{"test": 123}');

    await WidgetSyncService.clearWidget();

    expect(prefs.getString('widget_schedule_data'), isNull);
  });
}
