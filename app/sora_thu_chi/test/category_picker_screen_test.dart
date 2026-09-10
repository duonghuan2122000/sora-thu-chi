import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/screens/category_picker_screen.dart';

import 'fakes/fake_wallet_repository.dart';

/// Bật chế độ tiếng Anh cho test — pump `MaterialApp` thường nên phải tự đăng
/// ký bản đồ dịch rồi đặt `Get.locale` (khôi phục trong teardown).
void useEnglish() {
  Get.addTranslations(SoraTranslations().keys);
  Get.locale = const Locale('en');
  addTearDown(() {
    Get.locale = null;
    Get.reset();
  });
}

Category _cat(int id, String name) => Category(
  id: id,
  name: name,
  type: CategoryType.expense,
  icon: 'category',
  color: 0xFF0F6E56,
);

/// Repo trả rỗng — kiểm tra empty state (loại không có danh mục).
class _NoCategoriesRepo extends FakeWalletRepository {
  @override
  Future<List<Category>> categories({required CategoryType type}) async => [];
}

/// Pump màn picker; chạm trả về ghi tên danh mục đã chọn qua [onPicked].
Future<void> pumpPicker(
  WidgetTester tester, {
  required CategoryType type,
  FakeWalletRepository? repository,
  required void Function(String? name) onPicked,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final picked = await Navigator.of(context).push<Category>(
                  MaterialPageRoute(
                    builder: (_) => CategoryPickerScreen(
                      type: type,
                      repository: repository ?? FakeWalletRepository(),
                    ),
                  ),
                );
                onPicked(picked?.name);
              },
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
  group('CategoryPickerScreen — màn chọn danh mục (mockup 03, R5)', () {
    testWidgets('(a) đúng loại: Chi → danh mục chi, không thấy thu; Thu ngược lại',
        (tester) async {
      await pumpPicker(tester, type: CategoryType.expense, onPicked: (_) {});

      // Chỉ danh mục chi (8 cha) + Thêm mới; danh mục thu không xuất hiện.
      expect(find.text('Chọn danh mục'), findsOneWidget);
      for (final name in ['Ăn uống', 'Di chuyển', 'Nhà ở', 'Hóa đơn', 'Mua sắm', 'Giáo dục']) {
        expect(find.text(name), findsOneWidget, reason: 'thiếu danh mục chi $name');
      }
      expect(find.text('Lương'), findsNothing);
      expect(find.text('Thưởng'), findsNothing);
      expect(find.text('Khác'), findsNothing);
      expect(find.text('Thêm mới'), findsOneWidget);

      // Quay về rồi mở lại với Thu.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await pumpPicker(tester, type: CategoryType.income, onPicked: (_) {});
      expect(find.text('Lương'), findsOneWidget);
      expect(find.text('Thưởng'), findsOneWidget);
      expect(find.text('Đầu tư'), findsOneWidget);
      expect(find.text('Khác'), findsOneWidget);
      expect(find.text('Ăn uống'), findsNothing);
    });

    testWidgets('(b) cha có con: chạm Ăn uống → vùng DANH MỤC CON, chọn con → trả về',
        (tester) async {
      String? picked;
      await pumpPicker(tester, type: CategoryType.expense, onPicked: (v) => picked = v);

      await tester.tap(find.text('Ăn uống'));
      await tester.pumpAndSettle();

      expect(find.text('DANH MỤC CON: ĂN UỐNG'), findsOneWidget);
      for (final child in ['Cà phê', 'Ăn ngoài', 'Đi chợ']) {
        expect(find.text(child), findsOneWidget);
      }

      await tester.tap(find.text('Ăn ngoài'));
      await tester.pumpAndSettle();
      expect(picked, 'Ăn ngoài');
      // Đã quay về màn host (picker đóng).
      expect(find.text('Chọn danh mục'), findsNothing);
    });

    testWidgets('(c) cha không con: chọn ngay (Nhà ở) → trả về', (tester) async {
      String? picked;
      await pumpPicker(tester, type: CategoryType.expense, onPicked: (v) => picked = v);

      await tester.tap(find.text('Nhà ở'));
      await tester.pumpAndSettle();
      expect(picked, 'Nhà ở');
      expect(find.text('Chọn danh mục'), findsNothing);
    });

    testWidgets('(d) ô "Thêm mới" no-op: không crash/không rời màn', (tester) async {
      await pumpPicker(
        tester,
        type: CategoryType.expense,
        onPicked: (_) {},
      );

      await tester.tap(find.text('Thêm mới'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn danh mục'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(e) loại không có danh mục → empty state, không lỗi', (tester) async {
      await pumpPicker(
        tester,
        type: CategoryType.expense,
        repository: _NoCategoriesRepo(),
        onPicked: (_) {},
      );

      expect(find.text('Chưa có danh mục cho loại này.\n'
              'Bạn có thể thêm mới từ màn danh mục.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(f) cỡ chữ lớn + safe area: cuộn tới ô cuối không overflow', (tester) async {
      tester.view.physicalSize = const Size(720, 1400); // logical 360x700 @2x.
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await pumpPicker(tester, type: CategoryType.expense, onPicked: (_) {});
      expect(tester.takeException(), isNull);

      // Cuộn xuống đáy cho tới khi thấy ô cuối (Thêm mới) — không overflow.
      await tester.scrollUntilVisible(find.text('Thêm mới'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Thêm mới'), findsWidgets);
    });

    testWidgets('(g) locale en: tên mặc định trên lưới dịch, tên tự tạo giữ nguyên (FR-009/FR-010)',
        (tester) async {
      useEnglish();
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [_cat(1, 'Ăn uống'), _cat(2, 'Trà sữa')],
      );

      await pumpPicker(
        tester,
        type: CategoryType.expense,
        repository: repo,
        onPicked: (_) {},
      );

      expect(find.text('Food & Drink'), findsOneWidget);
      expect(find.text('Ăn uống'), findsNothing);
      expect(find.text('Trà sữa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
