import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/profile/device_profile.dart';
import 'package:sora_thu_chi/screens/settings_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

Future<void> pumpSettings(
  WidgetTester tester, {
  DeviceProfile profile = DeviceProfile.initial,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Scaffold(body: SettingsScreen(profile: profile)),
    ),
  );
}

void main() {
  group('SettingsScreen — hiển thị màn Cài đặt', () {
    testWidgets('Profile mặc định → đủ khối hồ sơ + 2 nhóm/4 hàng đúng', (tester) async {
      await pumpSettings(tester);

      // Header + khối hồ sơ.
      expect(find.text('Cài đặt'), findsOneWidget);
      expect(find.text('ND'), findsOneWidget); // avatar chữ viết tắt
      expect(find.text('Người dùng'), findsOneWidget);
      expect(find.text('Chạm để đổi ảnh đại diện'), findsOneWidget);

      // 2 nhóm + 4 hàng.
      expect(find.text('TÀI KHOẢN'), findsOneWidget);
      expect(find.text('Tiền tệ mặc định'), findsOneWidget);
      expect(find.text('Đổi mã PIN'), findsOneWidget);
      expect(find.text('Mở khóa sinh trắc học'), findsOneWidget);
      expect(find.text('KHÁC'), findsOneWidget);
      expect(find.text('Quản lý ví'), findsOneWidget);

      // Giá trị tiền tệ + công tắc tắt.
      expect(find.text('VND'), findsOneWidget);
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);
    });

    testWidgets('Hàng đúng thứ tự từ trên xuống', (tester) async {
      await pumpSettings(tester);

      final ordered = ['Tiền tệ mặc định', 'Đổi mã PIN', 'Mở khóa sinh trắc học', 'Quản lý ví'];
      double prev = -1;
      for (final label in ordered) {
        final y = tester.getTopLeft(find.text(label)).dy;
        expect(y, greaterThan(prev), reason: '$label phải nằm dưới hàng trước');
        prev = y;
      }
      // Nhóm KHÁC nằm sau 3 hàng nhóm TÀI KHOẢN (trước hàng Quản lý ví).
      final biometricY = tester.getTopLeft(find.text('Mở khóa sinh trắc học')).dy;
      final manageY = tester.getTopLeft(find.text('Quản lý ví')).dy;
      final otherY = tester.getTopLeft(find.text('KHÁC')).dy;
      expect(otherY, greaterThan(biometricY));
      expect(otherY, lessThan(manageY));
    });

    testWidgets('Profile tên dài + cỡ chữ lớn → không overflow, tên cắt ellipsis', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const profile = DeviceProfile(
        displayName: 'Một cái tên cực kỳ dài để kiểm tra chống tràn layout của khối hồ sơ',
      );
      await pumpSettings(tester, profile: profile);

      // Quét toàn bộ nội dung xuống đáy — mọi hàng được build, không overflow.
      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
      }
      expect(tester.takeException(), isNull,
          reason: 'Không được có FlutterError (RenderFlex overflow) khi cỡ chữ lớn');
      expect(find.text('Cài đặt'), findsOneWidget);
    });

    testWidgets('Tap hàng chưa kích hoạt & Switch → không mở màn, Switch giữ tắt', (tester) async {
      await pumpSettings(tester);

      for (final label in ['Tiền tệ mặc định', 'Đổi mã PIN', 'Quản lý ví']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      // Switch: chạm nhiều lần (kể cả nhanh) không bật.
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(Switch));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Không có route/màn mới: màn Cài đặt còn nguyên (không bị đẩy xuống offstage),
      // không có nút back, không lỗi.
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
