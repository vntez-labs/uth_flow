import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uth_flow/core/widgets/bouncing_tap.dart';

void main() {
  testWidgets('BouncingTap triggers onTap callback and animates scale', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BouncingTap(
              onTap: () => tapped = true,
              scaleFactor: 0.95,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Tap Me'), findsOneWidget);

    // Tap Down
    final gesture = await tester.startGesture(tester.getCenter(find.text('Tap Me')));
    await tester.pump(const Duration(milliseconds: 50));

    // Tap Up
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('BouncingTap triggers onLongPress callback', (tester) async {
    bool longPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BouncingTap(
              onLongPress: () => longPressed = true,
              child: const Text('Long Press Me'),
            ),
          ),
        ),
      ),
    );

    await tester.longPress(find.text('Long Press Me'));
    await tester.pumpAndSettle();

    expect(longPressed, isTrue);
  });
}
