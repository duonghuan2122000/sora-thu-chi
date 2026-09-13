import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/core/scan/scan_controller.dart';
import 'package:sora_thu_chi/core/scan/scan_settings.dart';
import 'package:sora_thu_chi/screens/scan/add_transaction_sheet.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_device_probe.dart';
import 'fakes/fake_scan_settings_store.dart';

/// Đăng ký [ScanController] với trạng thái công tắc cho trước.
void registerScan({bool enabled = true}) {
  Get.reset();
  final controller = ScanController(
    FakeScanSettingsStore(stored: ScanSettings(enabled: enabled)),
    FakeDeviceProbe(),
  );
  controller.settings.value = ScanSettings(enabled: enabled);
  Get.put(controller);
  addTearDown(Get.reset);
}

Future<void> pumpHost(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: const Scaffold(body: SizedBox.expand()),
    ),
  );
}

/// Mở sheet, trả Future kết quả **chưa await** (future chỉ hoàn tất khi sheet
/// đóng) — test tự `pumpAndSettle` rồi chạm hàng, sau đó await future.
Future<AddSheetChoice?> openSheet(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold));
  return showAddTransactionSheet(context);
}

Future<void> showSheet(WidgetTester tester) async {
  openSheet(tester);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Bật tính năng → đủ 4 hàng + nhãn MỚI + mô tả', (tester) async {
    registerScan(enabled: true);
    await pumpHost(tester);

    await showSheet(tester);

    expect(find.text('Thêm giao dịch'), findsOneWidget);
    expect(find.text('Khoản Thu'), findsOneWidget);
    expect(find.text('Khoản Chi'), findsOneWidget);
    expect(find.text('Chuyển khoản'), findsOneWidget);
    expect(find.text('Quét hóa đơn (AI)'), findsOneWidget);
    expect(find.text('MỚI'), findsOneWidget);
    expect(find.text('Tự động đọc số tiền, ngày, cửa hàng'), findsOneWidget);
  });

  testWidgets('Tắt tính năng → hàng quét biến mất, 3 hàng còn lại nguyên',
      (tester) async {
    registerScan(enabled: false);
    await pumpHost(tester);

    await showSheet(tester);

    expect(find.text('Quét hóa đơn (AI)'), findsNothing);
    expect(find.text('MỚI'), findsNothing);
    expect(find.text('Khoản Thu'), findsOneWidget);
    expect(find.text('Khoản Chi'), findsOneWidget);
    expect(find.text('Chuyển khoản'), findsOneWidget);
  });

  testWidgets('Chạm từng hàng trả đúng AddSheetChoice', (tester) async {
    registerScan(enabled: true);
    await pumpHost(tester);

    for (final entry in {
      'add-sheet-income': AddSheetChoice.income,
      'add-sheet-expense': AddSheetChoice.expense,
      'add-sheet-transfer': AddSheetChoice.transfer,
      'add-sheet-scan': AddSheetChoice.scan,
    }.entries) {
      final result = openSheet(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey(entry.key)));
      await tester.pumpAndSettle();
      expect(await result, entry.value, reason: 'hàng ${entry.key}');
    }
  });

  testWidgets('Locale en → nhãn sheet bằng tiếng Anh', (tester) async {
    registerScan(enabled: true);
    // Pump `MaterialApp` thường nên phải tự đăng ký bản đồ dịch rồi đặt
    // `Get.locale`; `Get.locale` là biến toàn cục → khôi phục trong teardown.
    Get.addTranslations(SoraTranslations().keys);
    Get.locale = const Locale('en');
    addTearDown(() => Get.locale = null);
    await pumpHost(tester);

    await showSheet(tester);

    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
    expect(find.text('Scan receipt (AI)'), findsOneWidget);
    expect(find.text('Khoản Thu'), findsNothing);
  });
}
