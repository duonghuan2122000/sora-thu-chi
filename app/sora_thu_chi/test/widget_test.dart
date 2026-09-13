import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/app_shell.dart';
import 'package:sora_thu_chi/core/widgets/app_bottom_nav_bar.dart';
import 'package:sora_thu_chi/core/widgets/screen_header.dart';
import 'package:sora_thu_chi/core/scan/scan_controller.dart';
import 'package:sora_thu_chi/core/scan/scan_settings.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_device_probe.dart';
import 'fakes/fake_scan_settings_store.dart';
import 'fakes/fake_wallet_repository.dart';

/// Shell giờ không còn là `home` mặc định (luồng boot bị PIN gate chiếm) —
/// nhóm shell pump `AppShell` trực tiếp, tách khỏi luồng boot. Tab Giao dịch
/// nạp dữ liệu khi chọn (FR-011) → đăng ký fake repo để không mở drift DB thật.
/// FAB mở bottom sheet (PBI 24) → đăng ký luôn [ScanController] fake.
Future<void> pumpShell(WidgetTester tester, {bool scanEnabled = false}) async {
  Get.reset();
  Get.put<WalletRepository>(FakeWalletRepository());
  final scan = ScanController(
    FakeScanSettingsStore(stored: ScanSettings(enabled: scanEnabled)),
    FakeDeviceProbe(),
  );
  scan.settings.value = ScanSettings(enabled: scanEnabled);
  Get.put(scan);
  addTearDown(Get.reset);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.themeData, home: const AppShell()),
  );
}

/// Màn ảo cao đủ hiện mọi dòng màn thêm giao dịch mà không cần cuộn.
void useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(720, 2000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('AppShell — điều hướng 4 vùng chính', () {
    testWidgets('Boot vào Tổng quan, đủ 4 tab + ô giữa', (tester) async {
      await pumpShell(tester);

      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.byType(ScreenHeader), findsOneWidget);
      // Header đang hiện + nhãn tab → 2 chỗ có chữ "Tổng quan".
      expect(find.text('Tổng quan'), findsNWidgets(2));
      // Các tab khác mới chỉ xuất hiện ở nhãn (header của chúng đang offstage).
      expect(find.text('Giao dịch'), findsOneWidget);
      expect(find.text('Báo cáo'), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
    });

    testWidgets('Tap từng tab → màn chính đổi tương ứng', (tester) async {
      await pumpShell(tester);

      Future<void> tapTab(String label) async {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      await tapTab('Giao dịch');
      expect(find.text('Giao dịch'), findsNWidgets(2)); // header + tab

      await tapTab('Báo cáo');
      expect(find.text('Báo cáo'), findsNWidgets(2));

      await tapTab('Cài đặt');
      expect(find.text('Cài đặt'), findsNWidgets(2));

      await tapTab('Tổng quan');
      expect(find.text('Tổng quan'), findsNWidgets(2));
    });

    testWidgets('FAB hiện cố định trên cả 4 màn chính', (tester) async {
      await pumpShell(tester);

      for (final label in ['Giao dịch', 'Báo cáo', 'Cài đặt', 'Tổng quan']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.add), findsOneWidget,
            reason: 'FAB phải hiện khi ở màn $label');
      }
    });

    testWidgets('Tap FAB → mở bottom sheet thêm giao dịch (FR-001)', (tester) async {
      useTallView(tester);
      await pumpShell(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Sheet 3 hàng (tính năng quét đang tắt).
      expect(find.text('Thêm giao dịch'), findsOneWidget);
      expect(find.text('Khoản Thu'), findsOneWidget);
      expect(find.text('Khoản Chi'), findsOneWidget);
      expect(find.text('Chuyển khoản'), findsOneWidget);
      expect(find.text('Quét hóa đơn (AI)'), findsNothing);
    });

    testWidgets('Sheet → "Khoản Chi" mở form thêm giao dịch (không no-op)',
        (tester) async {
      useTallView(tester);
      await pumpShell(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khoản Chi'));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNavBar), findsNothing);
      // App bar: icon đóng X (trái) + check (phải) — không còn BackButton stub.
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Chi'), findsOneWidget); // segmented mặc định Chi.
      expect(find.text('Lưu giao dịch'), findsOneWidget);
    });

    testWidgets('Bật tính năng quét → sheet có thêm hàng "Quét hóa đơn (AI)"',
        (tester) async {
      useTallView(tester);
      await pumpShell(tester, scanEnabled: true);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Quét hóa đơn (AI)'), findsOneWidget);
      expect(find.text('MỚI'), findsOneWidget);
    });

    testWidgets('Quay lại từ màn phụ → đúng tab cũ', (tester) async {
      useTallView(tester);
      await pumpShell(tester);

      // Sang tab Báo cáo rồi mở màn phụ.
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khoản Chi'));
      await tester.pumpAndSettle();

      // Đóng bằng icon X (màn sạch → pop thẳng, không dialog) → về đúng tab.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.text('Báo cáo'), findsNWidgets(2)); // header + tab còn chọn
    });

    testWidgets('FR-013/SC-006: lưu giao dịch qua FAB → shell làm mới danh sách ngay',
        (tester) async {
      useTallView(tester);
      await pumpShell(tester);

      // Sang Giao dịch rồi mở FAB (danh sách đang có 11 dòng seed).
      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khoản Chi'));
      await tester.pumpAndSettle();

      // Nhập khoản chi 90 đ danh mục "Nhà ở" (cha không con → chọn ngay).
      await tester.tap(find.text('9'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhà ở'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-transaction')));
      await tester.pumpAndSettle();

      // Đã quay lại shell; dòng mới hiện trong danh sách Giao dịch — không cần
      // thao tác làm mới thủ công.
      expect(find.text('Thêm giao dịch'), findsNothing);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
      expect(find.text('Nhà ở'), findsWidgets);
    });

    testWidgets('FR-004: rời tab rồi quay lại → vẫn ở đúng vùng', (tester) async {
      await pumpShell(tester);

      // Sang Giao dịch.
      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();
      expect(find.text('Giao dịch'), findsNWidgets(2));

      // Rời sang Báo cáo rồi quay lại Giao dịch.
      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Giao dịch'));
      await tester.pumpAndSettle();

      // Header Giao dịch vẫn hiển thị, đúng vùng đã chọn.
      expect(find.text('Giao dịch'), findsNWidgets(2));
      expect(find.text('Báo cáo'), findsOneWidget);
    });
  });
}
