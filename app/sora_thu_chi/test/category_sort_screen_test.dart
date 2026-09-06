import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/category_sort_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

/// Danh mục cha/con helper cho seed (R10 — không sqlite).
Category _cat(
  int id,
  String name, {
  CategoryType type = CategoryType.expense,
  int? parentId,
  int sortOrder = 0,
  bool isHidden = false,
}) {
  return Category(
    id: id,
    name: name,
    type: type,
    icon: 'category',
    color: 0xFF0F6E56,
    parentId: parentId,
    sortOrder: sortOrder,
    isHidden: isHidden,
  );
}

/// 4 cha chi tiêu theo thứ tự seed (Ăn uống có 2 con) + 1 cha thu nhập lạ.
List<Category> _seedExpenseAndIncome() => [
  _cat(1, 'Ăn uống', sortOrder: 0),
  _cat(11, 'Cà phê', parentId: 1, sortOrder: 0),
  _cat(12, 'Ăn ngoài', parentId: 1, sortOrder: 1),
  _cat(2, 'Di chuyển', sortOrder: 1),
  _cat(3, 'Nhà ở', sortOrder: 2),
  _cat(4, 'Hóa đơn', sortOrder: 3),
  _cat(10, 'Lương', type: CategoryType.income, sortOrder: 0),
];

/// Push [CategorySortScreen] từ route trung gian — có back + pop trả về.
Future<void> _openSort(
  WidgetTester tester,
  CategoryType type,
  WalletRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CategorySortScreen(
                    initialType: type,
                    repository: repository,
                  ),
                ),
              ),
              child: const Text('mở sắp xếp'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở sắp xếp'));
  await tester.pumpAndSettle();
}

void main() {
  group('CategorySortScreen — bố cục mockup 04 (acceptance 1/FR-002)', () {
    testWidgets('app bar back + tiêu đề + "Xong"; không tab/nav/số tiền; đúng cha seed', (
      tester,
    ) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: _seedExpenseAndIncome(),
      );
      await _openSort(tester, CategoryType.expense, repo);

      expect(find.text('Sắp xếp danh mục'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Xong'), findsOneWidget);

      // Không tab riêng / bottom nav / số tiền / chevron.
      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.byIcon(Icons.sort), findsNothing);

      // 4 cha chi tiêu đúng thứ tự seed; không lẫn con / loại kia (FR-003/004).
      double prev = -1;
      for (final name in ['Ăn uống', 'Di chuyển', 'Nhà ở', 'Hóa đơn']) {
        expect(find.text(name), findsOneWidget);
        final y = tester.getTopLeft(find.text(name)).dy;
        expect(y, greaterThan(prev), reason: '$name phải dưới hàng trước');
        prev = y;
      }
      expect(find.text('Cà phê'), findsNothing);
      expect(find.text('Ăn ngoài'), findsNothing);
      expect(find.text('Lương'), findsNothing);

      // Mỗi dòng có tay cầm kéo–thả (R2/FR-004).
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('vào từ loại Thu nhập → chỉ cha thu nhập (acceptance 3)', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: _seedExpenseAndIncome(),
      );
      await _openSort(tester, CategoryType.income, repo);

      expect(find.text('Lương'), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
      for (final name in ['Ăn uống', 'Di chuyển', 'Nhà ở', 'Hóa đơn']) {
        expect(find.text(name), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('CategorySortScreen — danh mục ẩn (acceptance 4/FR-004/SC-005)', () {
    testWidgets('ẩn vẫn hiện đúng vị trí + "Đã ẩn"; kéo được như dòng khác', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [
          _cat(1, 'Ăn uống', sortOrder: 0),
          _cat(2, 'Di chuyển', sortOrder: 1, isHidden: true),
          _cat(3, 'Nhà ở', sortOrder: 2),
        ],
      );
      await _openSort(tester, CategoryType.expense, repo);

      expect(find.text('Di chuyển'), findsOneWidget);
      expect(find.text('Đã ẩn'), findsOneWidget);
      // Đúng thứ tự: Ăn uống → Di chuyển → Nhà ở.
      final anUongY = tester.getTopLeft(find.text('Ăn uống')).dy;
      final diChuyenY = tester.getTopLeft(find.text('Di chuyển')).dy;
      final nhaOY = tester.getTopLeft(find.text('Nhà ở')).dy;
      expect(anUongY, lessThan(diChuyenY));
      expect(diChuyenY, lessThan(nhaOY));
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });

  group('CategorySortScreen — kéo tay cầm ghi ngay (acceptance 2/FR-005/006)', () {
    testWidgets('kéo dòng đầu xuống → reorderCategories ghi + UI đổi thứ tự', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [
          _cat(1, 'Ăn uống', sortOrder: 0),
          _cat(2, 'Di chuyển', sortOrder: 1),
          _cat(3, 'Nhà ở', sortOrder: 2),
        ],
      );
      await _openSort(tester, CategoryType.expense, repo);

      final handle = find.descendant(
        of: find.byKey(const ValueKey('sort-row-1')),
        matching: find.byIcon(Icons.drag_handle),
      );
      // Kéo tay cầm dòng "Ăn uống" (id 1) xuống 1 dòng.
      await tester.timedDrag(handle, const Offset(0, 90), const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Ghi ngay: store đánh sortOrder = 0..n theo thứ tự mới (R2/R7) — dòng
      // kéo xuống phải nằm DƯỚI Di chuyển (vốn ở vị trí 2 lúc đầu).
      Category byId(int id) => repo.categoriesStored.firstWhere((c) => c.id == id);
      expect(byId(2).sortOrder, 0, reason: 'Di chuyển thành dòng đầu');
      expect(byId(1).sortOrder, greaterThan(byId(2).sortOrder),
          reason: 'Ăn uống bị kéo xuống dưới Di chuyển');

      // UI đổi thứ tự: Di chuyển trên Ăn uống.
      final diChuyenY = tester.getTopLeft(find.text('Di chuyển')).dy;
      final anUongY = tester.getTopLeft(find.text('Ăn uống')).dy;
      expect(diChuyenY, lessThan(anUongY));
      expect(tester.takeException(), isNull);
    });
  });

  group('CategorySortScreen — rời màn & empty phòng thủ (FR-008)', () {
    testWidgets('chạm "Xong" → pop về màn trước (acceptance 7)', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: _seedExpenseAndIncome(),
      );
      await _openSort(tester, CategoryType.expense, repo);

      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();

      expect(find.byType(CategorySortScreen), findsNothing);
      expect(find.text('mở sắp xếp'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loại không có cha nào → empty phòng thủ, không lỗi (spec Giả định)', (
      tester,
    ) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [_cat(1, 'Ăn uống')], // chỉ chi tiêu, không thu nhập.
      );
      await _openSort(tester, CategoryType.income, repo);

      expect(find.textContaining('Không có danh mục thu nhập'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategorySortScreen — khả năng tiếp cận (FR-009/SC-007)', () {
    testWidgets('cỡ chữ lớn + màn nhỏ → cuộn tới cuối không overflow/cắt', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeWalletRepository(); // seed mặc định: 8 cha chi tiêu.
      await _openSort(tester, CategoryType.expense, repo);

      final list = find.byType(ReorderableListView);
      for (var i = 0; i < 6; i++) {
        await tester.drag(list, const Offset(0, -400));
        await tester.pump();
      }
      expect(find.text('Giáo dục'), findsOneWidget);
      expect(find.text('Xong'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
