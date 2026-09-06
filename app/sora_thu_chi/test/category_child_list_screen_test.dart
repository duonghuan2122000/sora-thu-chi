import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/category_child_list_screen.dart';
import 'package:sora_thu_chi/screens/category_form_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

/// Category helper cho seed riêng (case ẩn/con lạ/cha khác — R11, không sqlite).
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

final _childScreen = find.byType(CategoryChildListScreen);
final _formScreen = find.byType(CategoryFormScreen);
final _nameField = find.byKey(const ValueKey('field-name'));
final _savePrimary = find.byKey(const ValueKey('save-primary'));
final _parentField = find.byKey(const ValueKey('parent-field'));

/// Text trong màn con — màn `01` (nếu có, khi mở từ list) đè dưới giữ state.
Finder _child(String text) =>
    find.descendant(of: _childScreen, matching: find.text(text));

/// Text trong [CategoryFormScreen] — form đè trên màn con nên cùng tồn tại.
Finder _form(String text) =>
    find.descendant(of: _formScreen, matching: find.text(text));

Finder _childBack() => find.descendant(
  of: _childScreen,
  matching: find.byType(BackButton),
);

Finder _formBack() => find.descendant(
  of: _formScreen,
  matching: find.byType(BackButton),
);

/// Nút "+" trên app bar màn con (hàng "Thêm" dưới list cũng có icon add).
Finder _appbarAdd() => find.descendant(
  of: find.descendant(of: _childScreen, matching: find.byType(AppBar)),
  matching: find.byIcon(Icons.add),
);

/// Đẩy [CategoryChildListScreen] từ route trung gian (có back) để chạm sâu.
Future<void> _openChild(
  WidgetTester tester,
  WalletRepository repository,
  Category parent,
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
                  builder: (_) => CategoryChildListScreen(
                    parent: parent,
                    repository: repository,
                  ),
                ),
              ),
              child: const Text('mở con'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở con'));
  await tester.pumpAndSettle();
}

/// Kéo ListView **trong form** (màn con bên dưới cũng có ListView — phải scope).
Future<void> _revealForm(WidgetTester tester, Finder finder) async {
  final list = find.descendant(of: _formScreen, matching: find.byType(ListView));
  for (var i = 0; i < 8 && finder.evaluate().isEmpty; i++) {
    await tester.drag(list, const Offset(0, -240));
    await tester.pump();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

List<double> _nameYs(WidgetTester tester, List<String> names) =>
    [for (final n in names) tester.getTopLeft(_child(n)).dy];

void main() {
  group('CategoryChildListScreen — bố cục mockup 03 (acceptance 1, SC-002)', () {
    testWidgets('App bar back + tiêu đề tên cha/"Danh mục con" + "+"; list 3 con; không bottom nav/số tiền', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      final parent = repo.categoriesStored.firstWhere((c) => c.id == 1);
      await _openChild(tester, repo, parent);

      // App bar: back + tiêu đề 2 dòng + nút "+".
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(_childBack(), findsOneWidget);
      expect(_child('Ăn uống'), findsOneWidget);
      expect(_child('Danh mục con'), findsOneWidget);
      expect(_appbarAdd(), findsOneWidget);
      expect(find.byTooltip('Thêm danh mục con'), findsOneWidget);

      // Danh sách đúng 3 con của "Ăn uống" theo thứ tự seed, không dòng phụ đếm.
      for (final n in ['Cà phê', 'Ăn ngoài', 'Đi chợ']) {
        expect(_child(n), findsOneWidget);
      }
      expect(find.text('3 danh mục con'), findsNothing);
      // 3 dòng con → đúng 3 chevron (con cấp 2 không có con đi tiếp).
      expect(
        find.descendant(of: _childScreen, matching: find.byIcon(Icons.chevron_right)),
        findsNWidgets(3),
      );
      final ys = _nameYs(tester, ['Cà phê', 'Ăn ngoài', 'Đi chợ']);
      expect(ys[0], lessThan(ys[1]));
      expect(ys[1], lessThan(ys[2]));

      // Hàng cuối "Thêm danh mục con".
      expect(_child('Thêm danh mục con'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryChildListScreen — chỉ con của cha đang xem (acceptance 2/SC-003)', () {
    testWidgets('Không lẫn con của cha khác / danh mục loại khác', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [
          _cat(1, 'Ăn uống', sortOrder: 0),
          _cat(13, 'Cà phê', parentId: 1, sortOrder: 0),
          _cat(14, 'Ăn ngoài', parentId: 1, sortOrder: 1),
          _cat(3, 'Nhà ở', sortOrder: 1),
          _cat(16, 'Điện nước', parentId: 3, sortOrder: 0),
          _cat(9, 'Lương', type: CategoryType.income, sortOrder: 0),
          _cat(17, 'Thưởng', type: CategoryType.income, parentId: 9, sortOrder: 0),
        ],
      );
      final parent = repo.categoriesStored.firstWhere((c) => c.id == 1);
      await _openChild(tester, repo, parent);

      expect(_child('Cà phê'), findsOneWidget);
      expect(_child('Ăn ngoài'), findsOneWidget);
      // Con của cha khác + danh mục thu nhập không lẫn vào.
      expect(find.text('Điện nước'), findsNothing);
      expect(find.text('Nhà ở'), findsNothing);
      expect(find.text('Lương'), findsNothing);
      expect(find.text('Thưởng'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Con ẩn hiện đúng vị trí + nhãn "Đã ẩn" + mờ, không loại (acceptance 4)', (
      tester,
    ) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [
          _cat(1, 'Ăn uống', sortOrder: 0),
          _cat(13, 'Cà phê', parentId: 1, sortOrder: 0),
          _cat(14, 'Đi chợ', parentId: 1, sortOrder: 1, isHidden: true),
          _cat(15, 'Ăn ngoài', parentId: 1, sortOrder: 2),
        ],
      );
      final parent = repo.categoriesStored.firstWhere((c) => c.id == 1);
      await _openChild(tester, repo, parent);

      expect(_child('Đi chợ'), findsOneWidget);
      expect(_child('Đã ẩn'), findsOneWidget);
      // Ẩn → vẫn giữ đúng thứ tự giữa Cà phê và Ăn ngoài.
      final ys = _nameYs(tester, ['Cà phê', 'Đi chợ', 'Ăn ngoài']);
      expect(ys[0], lessThan(ys[1]));
      expect(ys[1], lessThan(ys[2]));
      // Dòng ẩn mờ (tên màu tabInactive) khác con hoạt động.
      final txt = tester.widget<Text>(_child('Đi chợ'));
      expect(txt.style!.color, AppColors.tabInactive);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryChildListScreen — thứ tự ổn định giữa các lần xem (acceptance 3)', () {
    testWidgets('Mở lại → thứ tự con giữ nguyên', (tester) async {
      final repo = FakeWalletRepository();
      final parent = repo.categoriesStored.firstWhere((c) => c.id == 1);
      await _openChild(tester, repo, parent);
      final before = _nameYs(tester, ['Cà phê', 'Ăn ngoài', 'Đi chợ']);

      // Rời màn (back) rồi mở lại từ launcher — thứ tự không đổi.
      await tester.tap(_childBack());
      await tester.pumpAndSettle();
      await tester.tap(find.text('mở con'));
      await tester.pumpAndSettle();
      final after = _nameYs(tester, ['Cà phê', 'Ăn ngoài', 'Đi chợ']);
      expect(after, before);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryChildListScreen — chạm con → Sửa (acceptance 5, FR-007)', () {
    testWidgets('Prefill 100% + loại khóa readonly (con cùng loại cha)', (tester) async {
      final repo = FakeWalletRepository();
      final parent = repo.categoriesStored.firstWhere((c) => c.id == 1);
      await _openChild(tester, repo, parent);

      await tester.tap(_child('Cà phê'));
      await tester.pumpAndSettle();

      expect(find.text('Sửa danh mục'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(_nameField).controller!.text,
        'Cà phê',
      );
      // Loại khóa: không pill, readonly box hiện loại hiện tại.
      expect(find.byKey(const ValueKey('type-pill-expense')), findsNothing);
      expect(find.byKey(const ValueKey('type-pill-income')), findsNothing);
      expect(_form('Chi tiêu'), findsOneWidget);

      // Back không lưu → về màn con, không ghi gì.
      await tester.tap(_formBack());
      await tester.pumpAndSettle();
      expect(_childScreen, findsOneWidget);
      expect(_child('Cà phê'), findsOneWidget);
      expect(repo.categoriesStored.length, 15);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryChildListScreen — thêm con preset cha (acceptance 6/7, FR-008/009)', () {
    testWidgets('"+" app bar → Thêm preset cha; lưu con về cuối nhóm, không refresh tay', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      final parent = repo.categoriesStored.firstWhere((c) => c.id == 1);
      await _openChild(tester, repo, parent);

      await tester.tap(_appbarAdd());
      await tester.pumpAndSettle();

      // Thêm với cha preset "Ăn uống" + loại Chi tiêu.
      expect(find.text('Thêm danh mục'), findsOneWidget);
      expect(
        tester.widget<Text>(_form('Chi tiêu')).style!.color,
        AppColors.white,
      );
      await tester.enterText(_nameField, 'Cà phê sữa');
      await _revealForm(tester, _parentField);
      expect(_form('Ăn uống'), findsOneWidget);

      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      // Về màn con: dòng mới xuất hiện cuối nhóm, không refresh tay.
      expect(_formScreen, findsNothing);
      final ys = _nameYs(tester, ['Cà phê', 'Ăn ngoài', 'Đi chợ', 'Cà phê sữa']);
      expect(ys[3], greaterThan(ys[2]));
      // Store đã ghi con đúng cha + cuối nhóm con của cha đó (sortOrder 3).
      final stored = repo.categoriesStored.last;
      expect(stored.name, 'Cà phê sữa');
      expect(stored.parentId, 1);
      expect(stored.sortOrder, 3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Hàng "Thêm danh mục con" → cũng mở Thêm preset cha (acceptance 6)', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      final parent = repo.categoriesStored.firstWhere((c) => c.id == 1);
      await _openChild(tester, repo, parent);

      await tester.tap(_child('Thêm danh mục con'));
      await tester.pumpAndSettle();

      expect(find.text('Thêm danh mục'), findsOneWidget);
      expect(
        tester.widget<Text>(_form('Chi tiêu')).style!.color,
        AppColors.white,
      );
      await _revealForm(tester, _parentField);
      expect(_form('Ăn uống'), findsOneWidget);

      // Back không lưu → không ghi, quay lại màn con.
      await tester.tap(_formBack());
      await tester.pumpAndSettle();
      expect(_childScreen, findsOneWidget);
      expect(repo.categoriesStored.length, 15);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryChildListScreen — con đổi cha rời nhóm cũ (acceptance 7, FR-010)', () {
    testWidgets('Sửa con chuyển cha → không còn trong danh sách cha cũ', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [
          _cat(1, 'Ăn uống', sortOrder: 0),
          _cat(13, 'Cà phê', parentId: 1, sortOrder: 0),
          _cat(14, 'Ăn ngoài', parentId: 1, sortOrder: 1),
          _cat(3, 'Nhà ở', sortOrder: 1),
        ],
      );
      final parent = repo.categoriesStored.firstWhere((c) => c.id == 1);
      await _openChild(tester, repo, parent);

      await tester.tap(_child('Cà phê'));
      await tester.pumpAndSettle();
      await _revealForm(tester, _parentField);
      await tester.tap(_parentField);
      await tester.pumpAndSettle();
      // Con vẫn đổi cha được → chọn "Nhà ở" (id 3).
      expect(find.byKey(const ValueKey('parent-3')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('parent-3')));
      await tester.pumpAndSettle();
      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      // Về màn con: con đã chuyển cha → rời nhóm cũ, con kia giữ nguyên.
      expect(_child('Cà phê'), findsNothing);
      expect(_child('Ăn ngoài'), findsOneWidget);
      final stored = repo.categoriesStored.firstWhere((c) => c.id == 13);
      expect(stored.parentId, 3);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryChildListScreen — vùng tiêu đề sửa cha (acceptance 9/10, FR-003/009)', () {
    testWidgets('Đổi tên cha → tiêu đề mới; loại khóa + không mở sheet cha; con giữ nguyên', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      final parent = repo.categoriesStored.firstWhere((c) => c.id == 1);
      await _openChild(tester, repo, parent);

      await tester.tap(_child('Ăn uống'));
      await tester.pumpAndSettle();

      // Sửa cha: prefill + loại khóa (có con).
      expect(find.text('Sửa danh mục'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(_nameField).controller!.text,
        'Ăn uống',
      );
      expect(find.byKey(const ValueKey('type-pill-expense')), findsNothing);
      expect(_form('Chi tiêu'), findsOneWidget);

      // Chạm ô cha → không mở sheet (cha có con — giữ cây 2 cấp).
      await _revealForm(tester, _parentField);
      await tester.tap(_parentField);
      await tester.pumpAndSettle();
      expect(find.text('Chọn danh mục cha'), findsNothing);

      // Đổi tên cha → lưu → tiêu đề màn con phản ánh tên mới, con giữ nguyên.
      await tester.enterText(_nameField, 'Ăn uống (đổi tên)');
      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      expect(_child('Ăn uống (đổi tên)'), findsOneWidget);
      expect(_child('Cà phê'), findsOneWidget);
      expect(_child('Ăn ngoài'), findsOneWidget);
      expect(_child('Đi chợ'), findsOneWidget);
      final stored = repo.categoriesStored.firstWhere((c) => c.id == 1);
      expect(stored.name, 'Ăn uống (đổi tên)');
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryChildListScreen — empty phòng thủ (edge R9/FR-010)', () {
    testWidgets('Cha hết con → hướng dẫn + vẫn còn "+" và hàng Thêm, không lỗi', (
      tester,
    ) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [_cat(1, 'Ăn uống')],
      );
      final parent = repo.categoriesStored.firstWhere((c) => c.id == 1);
      await _openChild(tester, repo, parent);

      expect(find.textContaining('Chưa có danh mục con'), findsOneWidget);
      expect(_child('Thêm danh mục con'), findsOneWidget);
      expect(_appbarAdd(), findsOneWidget);

      // Vẫn thêm được: hàng Thêm mở form preset cha.
      await tester.tap(_child('Thêm danh mục con'));
      await tester.pumpAndSettle();
      expect(find.text('Thêm danh mục'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryChildListScreen — cỡ chữ lớn không vỡ (FR-012/SC-008)', () {
    testWidgets('textScale 2 + màn nhỏ → cuộn tới cuối, không overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.binding.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeWalletRepository();
      final parent = repo.categoriesStored.firstWhere((c) => c.id == 1);
      await _openChild(tester, repo, parent);

      for (var i = 0; i < 4; i++) {
        await tester.drag(
          find.descendant(of: _childScreen, matching: find.byType(ListView)),
          const Offset(0, -400),
        );
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(_child('Thêm danh mục con'), findsOneWidget);
    });
  });
}
