import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/utilities/utilities_store.dart';
import 'package:sora_thu_chi/screens/utilities_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_utilities_store.dart';

/// Đẩy [UtilitiesScreen] qua route để có nút back; màn luôn nhận [store] bơm
/// (fake) → không chạm drift/GetX (R7).
Future<void> pumpUtilities(WidgetTester tester, {UtilitiesStore? store}) async {
  await tester.binding.setSurfaceSize(const Size(390, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => UtilitiesScreen(store: store),
                ),
              ),
              child: const Text('mở'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở'));
  await tester.pumpAndSettle();
}

void main() {
  const groupOrder = <String, List<String>>{
    'HIỂN THỊ': ['Giao diện', 'Ngôn ngữ', 'Định dạng & Tiền tệ'],
    'TRẢI NGHIỆM': [
      'Widget màn hình chính',
      'Ẩn số dư (Privacy mode)',
      'Máy tính khi nhập số tiền',
    ],
    'DỮ LIỆU & TÌM KIẾM': ['Tìm kiếm toàn cục', 'Quản lý Tag'],
  };

  List<Switch> switches(WidgetTester tester) =>
      tester.widgetList<Switch>(find.byType(Switch)).toList();

  testWidgets('Bố cục mockup: back + tiêu đề, 3 nhóm/8 hàng đúng thứ tự, icon', (tester) async {
    await pumpUtilities(tester, store: FakeUtilitiesStore());

    // App bar: back + tiêu đề; không bottom nav.
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Tiện ích & Cá nhân hóa'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);

    // 3 nhóm viết hoa + 8 hàng đúng tên.
    for (final group in groupOrder.keys) {
      expect(find.text(group), findsOneWidget);
    }
    final allRows = groupOrder.values.expand((r) => r).toList();
    for (final name in allRows) {
      expect(find.text(name), findsOneWidget, reason: 'thiếu hàng "$name"');
    }

    // Thứ tự: hàng theo đúng nhóm từ trên xuống.
    double prev = -1;
    for (final name in allRows) {
      final y = tester.getTopLeft(find.text(name)).dy;
      expect(y, greaterThan(prev), reason: '$name phải nằm dưới hàng trước');
      prev = y;
    }

    // Icon teal của từng mục xuất hiện trong hàng.
    for (final icon in [
      Icons.wb_sunny_outlined,
      Icons.language,
      Icons.tune,
      Icons.widgets_outlined,
      Icons.visibility_off_outlined,
      Icons.calculate_outlined,
      Icons.search,
      Icons.sell_outlined,
    ]) {
      expect(find.byIcon(icon), findsOneWidget, reason: 'thiếu icon $icon');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Trailing mặc định: "Hệ thống"/"Tiếng Việt" + chevron 5 hàng nav', (tester) async {
    await pumpUtilities(tester, store: FakeUtilitiesStore());

    expect(find.text('Hệ thống'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    // 5 hàng điều hướng có chevron sang phải.
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
  });

  testWidgets('Giá trị switch từ store: Widget bật, Ẩn số dư tắt, Máy tính bật', (tester) async {
    await pumpUtilities(tester, store: FakeUtilitiesStore());

    final values = switches(tester).map((s) => s.value).toList();
    expect(values, [true, false, true]); // Widget / Ẩn số dư / Máy tính
  });

  testWidgets('Toggle ghi-through store + đảo UI + bật/tắt nhanh đúng lần cuối', (tester) async {
    final fake = FakeUtilitiesStore();
    await pumpUtilities(tester, store: fake);

    final hideSwitch = find.byType(Switch).at(1); // Ẩn số dư
    final calcSwitch = find.byType(Switch).at(2); // Máy tính

    // Bật Ẩn số dư → UI đảo + store ghi.
    await tester.tap(hideSwitch);
    await tester.pumpAndSettle();
    expect(switches(tester)[1].value, isTrue);
    expect(fake.storedPrefs.hideBalance, isTrue);

    // Tắt Máy tính → store ghi false.
    await tester.tap(calcSwitch);
    await tester.pumpAndSettle();
    expect(switches(tester)[2].value, isFalse);
    expect(fake.storedPrefs.amountCalculatorEnabled, isFalse);

    // Bật/tắt nhanh liên tục cùng công tắc → trạng thái cuối đúng lần chạm cuối.
    await tester.tap(hideSwitch); // true → false
    await tester.pump();
    await tester.tap(hideSwitch); // false → true
    await tester.pump();
    await tester.tap(hideSwitch); // true → false
    await tester.pump();
    await tester.pumpAndSettle();
    expect(switches(tester)[1].value, isFalse);
    expect(fake.storedPrefs.hideBalance, isFalse);
  });

  testWidgets('Mở lại màn với store mới (có state đã lưu) → switch giữ trạng thái', (tester) async {
    final fake1 = FakeUtilitiesStore();
    await pumpUtilities(tester, store: fake1);
    await tester.tap(find.byType(Switch).at(1)); // bật Ẩn số dư
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).at(2)); // tắt Máy tính
    await tester.pumpAndSettle();

    // Mở lại màn bằng store fake mới mang state đã lưu (mô phỏng mở lại app).
    // MaterialApp key UniqueKey → dựng lại state mới đọc store mới (không tái
    // dùng initState cũ của lần pump trước).
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: AppTheme.themeData,
        home: UtilitiesScreen(
          store: FakeUtilitiesStore(storedPrefs: fake1.storedPrefs),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final values = switches(tester).map((s) => s.value).toList();
    expect(values, [true, true, false]); // Widget / Ẩn số dư / Máy tính
  });

  testWidgets('Hàng Widget: chạm toàn hàng mở dialog hướng dẫn, switch không đảo', (tester) async {
    await pumpUtilities(tester, store: FakeUtilitiesStore());

    // Chạm đúng vùng switch (hàng bọc InkWell toàn bộ — R5) → dialog hiện.
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text('Hướng dẫn ghim widget'), findsOneWidget);
    expect(switches(tester)[0].value, isTrue); // switch giữ "bật", không đảo.

    // Đóng dialog → switch vẫn bật.
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(switches(tester)[0].value, isTrue);
    expect(find.text('Hướng dẫn ghim widget'), findsNothing);
  });

  testWidgets('5 hàng điều hướng no-op: chạm không mở màn/dialog, không lỗi', (tester) async {
    await pumpUtilities(tester, store: FakeUtilitiesStore());

    for (final label in [
      'Giao diện',
      'Ngôn ngữ',
      'Định dạng & Tiền tệ',
      'Tìm kiếm toàn cục',
      'Quản lý Tag',
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    // Không route mới (chỉ 1 back duy nhất, không dialog), app không lỗi,
    // giá trị "Hệ thống"/"Tiếng Việt" không đổi.
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Hướng dẫn ghim widget'), findsNothing);
    expect(find.text('Hệ thống'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.byType(UtilitiesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quản lý Tag không hiện số tag giả / nhãn # (FR-009/SC-008)', (tester) async {
    await pumpUtilities(tester, store: FakeUtilitiesStore());

    expect(find.textContaining('12 tag'), findsNothing);
    expect(find.textContaining('#'), findsNothing);
    expect(find.text('Gắn nhãn cho giao dịch'), findsOneWidget);
  });

  testWidgets('Cỡ chữ lớn + màn nhỏ: cuộn tới hàng cuối, không overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeData,
        home: UtilitiesScreen(store: FakeUtilitiesStore()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Quản lý Tag'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quản lý Tag'), findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'Không được có FlutterError (RenderFlex overflow) khi cỡ chữ lớn');
  });
}
