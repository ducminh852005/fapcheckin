import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fapcheckin/views/auth/layouts/login_mobile_layout.dart';
import 'package:fapcheckin/views/auth/widgets/login_google_button.dart';

void main() {
  for (final size in [
    const Size(360, 800),
    const Size(412, 950),
    const Size(640, 360),
  ]) {
    testWidgets('Login fits and scrolls at $size with enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.2),
              ),
              child: LoginMobileLayout(
                isLoading: false,
                onGoogleSignIn: () => taps++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(OutlinedButton));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Loading disables duplicate sign-in and shows feedback', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoginGoogleButton(isLoading: true, onPressed: () => taps++),
        ),
      ),
    );
    expect(find.text('Đang đăng nhập…'), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(OutlinedButton));
    expect(taps, 0);
  });
}
