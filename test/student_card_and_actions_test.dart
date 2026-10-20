import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:uth_flow/features/auth/presentation/screens/student_card_screen.dart';
import 'package:uth_flow/features/auth/presentation/widgets/barcode_widget.dart';
import 'package:uth_flow/features/tabs/presentation/widgets/qr_scanner_sheet.dart';

class MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  bool canLaunchResult = false;
  bool launchResult = false;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async =>
      launchResult;
}

void main() {
  testWidgets('BarcodeWidget renders custom barcode cleanly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BarcodeWidget(code: '074207005137'),
        ),
      ),
    );

    expect(find.byType(BarcodeWidget), findsOneWidget);
    expect(find.text('074207005137'), findsOneWidget);
  });

  testWidgets('StudentCardScreen renders electronic student card matching UTH spec',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StudentCardScreen(),
        ),
      ),
    );

    expect(find.text('Thẻ sinh viên điện tử'), findsOneWidget);
    expect(find.text('TRƯỜNG ĐẠI HỌC'), findsOneWidget);
    expect(find.text('GIAO THÔNG VẬN TẢI TP. HỒ CHÍ MINH'), findsOneWidget);
    expect(find.text('Thông tin số hóa'), findsOneWidget);
    expect(find.text('Mã vạch'), findsOneWidget);
    expect(find.text('Thông tin thêm'), findsOneWidget);
    expect(find.text('Không có thông tin'), findsOneWidget);

    // Verify top card is pinned and does NOT scroll when bottom section is dragged
    final initialCardPos = tester.getTopLeft(find.text('TRƯỜNG ĐẠI HỌC'));
    await tester.drag(find.text('Mã vạch'), const Offset(0, -60));
    await tester.pump();
    final afterCardPos = tester.getTopLeft(find.text('TRƯỜNG ĐẠI HỌC'));
    expect(afterCardPos.dy, equals(initialCardPos.dy));
  });

  testWidgets('QrScannerSheet renders viewfinder and scanner actions',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QrScannerSheet(),
        ),
      ),
    );

    expect(find.text('Quét mã QR UTH'), findsOneWidget);
    expect(find.text('Bật đèn'), findsOneWidget);
    expect(find.text('Nhập mã'), findsOneWidget);

    // Tap 'Nhập mã' button
    await tester.ensureVisible(find.text('Nhập mã'));
    await tester.tap(find.text('Nhập mã'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nhập mã điểm danh thủ công'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'UTH-1234');
    await tester.tap(find.text('Xác nhận'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nhập mã điểm danh thủ công'), findsNothing);
  });

  testWidgets(
      'QrScannerSheet.handleQrAction shows developing dialog when app is not installed',
      (tester) async {
    final mockPlatform = MockUrlLauncherPlatform();
    mockPlatform.canLaunchResult = false;
    UrlLauncherPlatform.instance = mockPlatform;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => QrScannerSheet.handleQrAction(context),
                child: const Text('Quét QR'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Quét QR'));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Tính năng này đang được phát triển, vui lòng dùng app UTH bạn nhé!'),
      findsOneWidget,
    );
    expect(find.text('Tải app UTH'), findsOneWidget);
    expect(find.text('Đóng'), findsOneWidget);

    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Tính năng này đang được phát triển, vui lòng dùng app UTH bạn nhé!'),
      findsNothing,
    );
  });
}
