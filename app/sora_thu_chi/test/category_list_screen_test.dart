import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/category_list_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

/// Category helper cho seed riêng (case ẩn / con lạ — R11, không sqlite).
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

/// Đẩy màn [CategoryListScreen] từ một route trung gian để có nút back.
Future<void> _openScreen(
  WidgetTester tester,
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
                  builder: (_) => CategoryListScreen(repository: repository),
                ),
              ),
              child: const Text('mở danh mục'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở danh mục'));
  await tester.pumpAndSettle();
}

const _expenseParents = [
  'Ăn uống', 'Di chuyển', 'Nhà ở', 'Hóa đơn',
  'Mua sắm', 'Giải trí', 'Sức khỏe', 'Giáo dục',
];

const _incomeParents = ['Lương', 'Thưởng', 'Đầu tư', 'Khác'];

void main() {
  group('CategoryListScreen — bố cục mockup 01 (acceptance 1)', () {
    testWidgets('App bar Danh mục + back + icon sắp xếp; tab Chi tiêu chọn; FAB; không bottom nav', (
      tester,
    ) async {
      await _openScreen(tester, FakeWalletRepository());

      expect(find.text('Danh mục'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byIcon(Icons.sort), findsOneWidget);
      expect(find.byTooltip('Sắp xếp'), findsOneWidget);

      // Tab Chi tiêu đang chọn (teal) — Thu nhập mờ.
      expect(
        tester.widget<Text>(find.text('Chi tiêu')).style!.color,
        AppColors.teal,
      );
      expect(
        tester.widget<Text>(find.text('Thu nhập')).style!.color,
        AppColors.tabInactive,
      );

      // FAB "+" teal phải dưới.
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      expect(find.byIcon(Icons.add), findsWidgets); // FAB trong màn này.
      final fabWidget = tester.widget<FloatingActionButton>(fab);
      expect(fabWidget.backgroundColor, AppColors.teal);

      // Không có bottom nav.
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Mặc định tab Chi tiêu: 8 cha đúng thứ tự + "3 danh mục con" của Ăn uống', (
      tester,
    ) async {
      await _openScreen(tester, FakeWalletRepository());

      for (final name in _expenseParents) {
        expect(find.text(name), findsOneWidget);
      }
      // Con không nằm trong danh sách cấp 1.
      expect(find.text('Cà phê'), findsNothing);

      // Chỉ "Ăn uống" có con → đúng 1 dòng phụ "3 danh mục con".
      expect(find.text('3 danh mục con'), findsOneWidget);
      expect(find.textContaining('danh mục con'), findsOneWidget);
      // Dòng phụ nằm dưới tên cha của nó.
      final anUongY = tester.getTopLeft(find.text('Ăn uống')).dy;
      final subY = tester.getTopLeft(find.text('3 danh mục con')).dy;
      expect(subY, greaterThan(anUongY));

      // Thứ tự cha từ trên xuống đúng sortOrder seed.
      double prev = -1;
      for (final name in _expenseParents) {
        final y = tester.getTopLeft(find.text(name)).dy;
        expect(y, greaterThan(prev), reason: '$name phải nằm dưới hàng trước');
        prev = y;
      }

      // Mỗi dòng có chevron phải.
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(8));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Chuyển tab Thu nhập ↔ Chi tiêu — không lẫn loại, giữ danh sách (acceptance 3)', (
      tester,
    ) async {
      await _openScreen(tester, FakeWalletRepository());

      await tester.tap(find.text('Thu nhập'));
      await tester.pumpAndSettle();

      for (final name in _incomeParents) {
        expect(find.text(name), findsOneWidget);
      }
      for (final name in _expenseParents) {
        expect(find.text(name), findsNothing);
      }
      expect(find.textContaining('danh mục con'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));

      await tester.tap(find.text('Chi tiêu'));
      await tester.pumpAndSettle();

      for (final name in _expenseParents) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('3 danh mục con'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(8));
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryListScreen — danh mục ẩn & con ẩn (acceptance 4)', () {
    testWidgets('Ẩn hiện đúng vị trí + nhãn "Đã ẩn"; con ẩn vẫn đếm', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [
          _cat(1, 'Ăn uống', sortOrder: 0),
          _cat(2, 'Cà phê', parentId: 1, sortOrder: 0, isHidden: true),
          _cat(3, 'Giải trí', sortOrder: 1, isHidden: true),
          _cat(4, 'Di chuyển', sortOrder: 2),
        ],
      );
      await _openScreen(tester, repo);

      // Cả cha ẩn lẫn cha hoạt động đều hiện đúng vị trí.
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Giải trí'), findsOneWidget);
      expect(find.text('Di chuyển'), findsOneWidget);

      // Cha ẩn có nhãn "Đã ẩn"; cha hoạt động thì không.
      expect(find.text('Đã ẩn'), findsOneWidget);

      // Thứ tự: Ăn uống → Giải trí → Di chuyển.
      final anUongY = tester.getTopLeft(find.text('Ăn uống')).dy;
      final giaiTriY = tester.getTopLeft(find.text('Giải trí')).dy;
      final diChuyenY = tester.getTopLeft(find.text('Di chuyển')).dy;
      expect(anUongY, lessThan(giaiTriY));
      expect(giaiTriY, lessThan(diChuyenY));

      // Con ẩn vẫn tính vào "N danh mục con" của cha (FR-005 edge).
      expect(find.text('1 danh mục con'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Mọi cấp 1 đều ẩn → vẫn hiện đủ dòng, không empty giả (SC-004)', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [
          _cat(1, 'A ẩn', isHidden: true),
          _cat(2, 'B ẩn', isHidden: true),
        ],
      );
      await _openScreen(tester, repo);

      expect(find.text('A ẩn'), findsOneWidget);
      expect(find.text('B ẩn'), findsOneWidget);
      expect(find.text('Đã ẩn'), findsNWidgets(2));
      expect(find.textContaining('Chưa có danh mục'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryListScreen — tab rỗng thật & điểm vào no-op', () {
    testWidgets('Tab không còn cấp 1 nào → empty hướng dẫn, không lỗi (FR-009)', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [_cat(1, 'Ăn uống')],
      );
      await _openScreen(tester, repo);

      await tester.tap(find.text('Thu nhập'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Chưa có danh mục thu nhập'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Chạm dòng / FAB / icon sắp xếp → không crash, không rời màn (SC-008)', (
      tester,
    ) async {
      await _openScreen(tester, FakeWalletRepository());

      await tester.tap(find.text('Ăn uống'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sắp xếp'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryListScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cỡ chữ lớn + màn nhỏ → cuộn tới cuối, không overflow, FAB/chevron không cắt', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _openScreen(tester, FakeWalletRepository());

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Giáo dục'), findsOneWidget);
    });
  });
}
