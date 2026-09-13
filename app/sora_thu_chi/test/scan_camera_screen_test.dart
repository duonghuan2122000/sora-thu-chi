import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/screens/scan/scan_camera_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_camera_gateway.dart';

/// Hứng kết quả pop của màn chụp (đường dẫn ảnh hoặc null).
class Host {
  String? result;
}

/// Pump host có nút đẩy màn chụp rồi mở màn đó.
Future<dynamic> pushCamera(
  WidgetTester tester,
  FakeCameraGateway gateway, {
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final host = Host();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      darkTheme: AppTheme.darkThemeData,
      themeMode: themeMode,
      home: Builder(
        builder: (context) => ElevatedButton(
          key: const ValueKey('open-camera'),
          onPressed: () async {
            host.result = await Navigator.of(context).push<String>(
              MaterialPageRoute(
                builder: (_) => ScanCameraScreen(gateway: gateway),
              ),
            );
          },
          child: const Text('mở'),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-camera')));
  await tester.pumpAndSettle();
  return host;
}

void main() {
  testWidgets('Đủ khung ngắm + 3 nút + dòng gợi ý, KHÔNG có "Quét nhiều"',
      (tester) async {
    final gateway = FakeCameraGateway();
    await pushCamera(tester, gateway);

    expect(find.byKey(const ValueKey('scan-guide-overlay')), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.byKey(const ValueKey('scan-flash')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-library')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-shutter')), findsOneWidget);
    expect(find.text('Đặt hóa đơn vừa khung, tránh bóng đổ'), findsOneWidget);
    expect(find.text('Quét hóa đơn'), findsOneWidget);
    // Quét hàng loạt thuộc GĐ2 — mockup có nút này nhưng đợt này không hiện.
    expect(find.text('Quét nhiều'), findsNothing);
    expect(gateway.initCount, 1);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('Nền tối cố định ở theme $mode', (tester) async {
      await pushCamera(tester, FakeCameraGateway(), themeMode: mode);

      final scaffold = tester.widget<Scaffold>(
        find.byKey(const ValueKey('scan-camera-screen')),
      );
      expect(scaffold.backgroundColor, Colors.black);
    });
  }

  testWidgets('Không mở được camera → thông báo, vẫn còn nút Thư viện',
      (tester) async {
    await pushCamera(tester, FakeCameraGateway());

    expect(
      find.text('Không mở được camera. Bạn vẫn có thể chọn ảnh từ thư viện.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('scan-library')), findsOneWidget);
  });

  testWidgets('Chọn từ thư viện → pop trả đường dẫn ảnh', (tester) async {
    final gateway = FakeCameraGateway(libraryPath: '/tmp/hoa-don.jpg');
    final host = await pushCamera(tester, gateway);

    await tester.tap(find.byKey(const ValueKey('scan-library')));
    await tester.pumpAndSettle();

    expect(host.result, '/tmp/hoa-don.jpg');
    expect(gateway.libraryCount, 1);
    expect(find.byKey(const ValueKey('scan-camera-screen')), findsNothing);
  });
}
