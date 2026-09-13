import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/scan/scan_controller.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/screens/scan/device_check_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_device_probe.dart';
import 'fakes/fake_scan_model_manager.dart';
import 'fakes/fake_scan_settings_store.dart';

void useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class Host {
  bool? result;
}

/// Pump màn kiểm tra cấu hình với controller bơm sẵn (store + probe fake).
Future<Host> pumpDeviceCheck(
  WidgetTester tester, {
  required FakeDeviceProbe probe,
  FakeScanSettingsStore? store,
  FakeScanModelManager? modelManager,
}) async {
  useTallView(tester);
  Get.reset();
  final controller = ScanController(
    store ?? FakeScanSettingsStore(),
    probe,
  );
  Get.put(controller);
  addTearDown(Get.reset);

  final host = Host();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Builder(
        builder: (context) => ElevatedButton(
          key: const ValueKey('start'),
          onPressed: () async {
            host.result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => DeviceCheckScreen(
                  controller: controller,
                  modelManager: modelManager,
                ),
              ),
            );
          },
          child: const Text('mở'),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('start')));
  await tester.pumpAndSettle();
  return host;
}

void main() {
  testWidgets('Tier A → kích hoạt được Gemini Nano (Tier A không cần tải)',
      (tester) async {
    final store = FakeScanSettingsStore();
    final probe = FakeDeviceProbe(FakeDeviceProbe.tierA());
    final host = await pumpDeviceCheck(tester, probe: probe, store: store);

    expect(find.text('Kiểm tra cấu hình máy'), findsOneWidget);
    expect(find.byKey(const ValueKey('device-check-tier-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('device-check-tier-b')), findsNothing);
    expect(find.byKey(const ValueKey('device-check-tier-c')), findsNothing);
    expect(find.text('Đủ điều kiện — Tier A'), findsOneWidget);
    expect(find.text('Dùng ngay Gemini Nano'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('device-check-activate-a')));
    await tester.pumpAndSettle();

    expect(host.result, isTrue);
    expect(store.storedSettings.mode, ScanEngine.geminiNano);
  });

  testWidgets('Tier B → tải model xong mới bật Gemma 3n', (tester) async {
    final store = FakeScanSettingsStore();
    final manager = FakeScanModelManager();
    final host = await pumpDeviceCheck(
      tester,
      probe: FakeDeviceProbe(FakeDeviceProbe.tierB()),
      store: store,
      modelManager: manager,
    );

    expect(find.byKey(const ValueKey('device-check-tier-b')), findsOneWidget);
    expect(find.text('Đủ điều kiện dùng Gemma 3n E2B'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('device-check-download-b')));
    await tester.pumpAndSettle();

    expect(manager.downloadCount, 1);
    expect(host.result, isTrue);
    expect(store.storedSettings.mode, ScanEngine.gemma3nE2b);
    expect(store.storedSettings.modelBytes, greaterThan(0));
  });

  testWidgets('Tier B → tải thất bại: báo lỗi, KHÔNG bật AI (FR-012)',
      (tester) async {
    final store = FakeScanSettingsStore();
    final manager = FakeScanModelManager(downloadSucceeds: false);
    final host = await pumpDeviceCheck(
      tester,
      probe: FakeDeviceProbe(FakeDeviceProbe.tierB()),
      store: store,
      modelManager: manager,
    );

    await tester.tap(find.byKey(const ValueKey('device-check-download-b')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('device-check-download-failed')),
      findsOneWidget,
    );
    expect(host.result, isNull); // chưa pop — người dùng còn chọn lại
    expect(store.storedSettings.mode, ScanEngine.ruleBased);
    expect(store.storedSettings.modelBytes, 0);
  });

  testWidgets('Tier B → chọn "Dùng chế độ cơ bản": huỷ tải + về Chế độ cơ bản',
      (tester) async {
    final store = FakeScanSettingsStore();
    final manager = FakeScanModelManager(downloadSucceeds: false);
    final host = await pumpDeviceCheck(
      tester,
      probe: FakeDeviceProbe(FakeDeviceProbe.tierB()),
      store: store,
      modelManager: manager,
    );

    await tester.tap(find.byKey(const ValueKey('device-check-download-b')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('device-check-use-basic')));
    await tester.pumpAndSettle();

    expect(host.result, isTrue);
    expect(store.storedSettings.mode, ScanEngine.ruleBased);
    expect(store.storedSettings.modelBytes, 0);
  });

  testWidgets('Tier C → nêu tiêu chí chưa đạt + nút dùng chế độ cơ bản chạy được',
      (tester) async {
    final store = FakeScanSettingsStore();
    final host = await pumpDeviceCheck(
      tester,
      probe: FakeDeviceProbe(FakeDeviceProbe.tierC()),
      store: store,
    );

    expect(find.byKey(const ValueKey('device-check-tier-c')), findsOneWidget);
    expect(find.text('Chưa đủ điều kiện dùng AI nâng cao'), findsOneWidget);
    expect(find.text('Bạn vẫn dùng được ở Chế độ cơ bản'), findsOneWidget);
    // Tiêu chí chưa đạt (RAM 3GB, không AICore, dung lượng 1.2GB).
    expect(find.textContaining('RAM 3 GB'), findsOneWidget);
    expect(find.textContaining('Hỗ trợ AI trên máy — Không'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('device-check-use-basic')));
    await tester.pumpAndSettle();

    expect(host.result, isTrue);
    // Kết quả đo đã lưu lại để lần sau không phải chạy lại (FR-008).
    expect(store.storedSettings.deviceCheck, isNotNull);
    expect(store.storedSettings.mode, ScanEngine.ruleBased);
  });

  testWidgets('4 mục đo có giá trị + Đạt/Không đạt', (tester) async {
    final probe = FakeDeviceProbe(FakeDeviceProbe.tierA());
    await pumpDeviceCheck(tester, probe: probe);

    expect(find.byKey(const ValueKey('device-check-row-ram')), findsOneWidget);
    expect(find.byKey(const ValueKey('device-check-row-storage')), findsOneWidget);
    expect(find.byKey(const ValueKey('device-check-row-ai')), findsOneWidget);
    expect(find.byKey(const ValueKey('device-check-row-os')), findsOneWidget);
    expect(find.text('Bộ nhớ RAM'), findsOneWidget);
    expect(find.text('Dung lượng trống'), findsOneWidget);
    expect(find.text('Hỗ trợ AI trên máy (AICore)'), findsOneWidget);
    expect(find.text('Phiên bản hệ điều hành'), findsOneWidget);
    expect(find.textContaining('8 GB — Đạt'), findsOneWidget);
    expect(find.textContaining('Android 15'), findsOneWidget);
    expect(probe.measureCount, 1);
  });

  testWidgets('Bấm "Kiểm tra lại" → đo lại và cập nhật số lần gọi probe',
      (tester) async {
    final probe = FakeDeviceProbe(FakeDeviceProbe.tierC());
    await pumpDeviceCheck(tester, probe: probe);
    expect(probe.measureCount, 1);

    await tester.tap(find.byKey(const ValueKey('device-check-retry')));
    await tester.pumpAndSettle();
    expect(probe.measureCount, 2);
  });
}
