import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_flow/core/widgets/schedule_widget_sheet.dart';

void main() {
  testWidgets('ScheduleWidgetSheet renders correctly and shows instructions',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScheduleWidgetSheet(),
        ),
      ),
    );

    expect(find.text('Tiện ích màn hình chính'), findsOneWidget);
    expect(find.text('Thử ghim tự động (Dành cho máy hỗ trợ)'), findsOneWidget);
    expect(find.text('Lịch học hôm nay'), findsOneWidget);
    expect(find.text('Cách thêm tiện ích (100% thành công)'), findsOneWidget);
  });
}
