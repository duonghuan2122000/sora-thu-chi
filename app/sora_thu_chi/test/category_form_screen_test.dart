import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_presets.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/category_form_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

const _errEmpty = 'Tên danh mục không được để trống';
const _errTrung = 'Tên danh mục đã tồn tại trong nhóm này';
const _noParentLabel = 'Không có — là danh mục gốc';

Category _cat(
  int id,
  String name, {
  CategoryType type = CategoryType.expense,
  int? parentId,
  int sortOrder = 0,
  bool isHidden = false,
  bool isSystem = false,
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
    isSystem: isSystem,
  );
}

class _Result {
  Category? saved;
}

final _nameField = find.byKey(const ValueKey('field-name'));
final _savePrimary = find.byKey(const ValueKey('save-primary'));
final _parentField = find.byKey(const ValueKey('parent-field'));
final _hiddenSwitch = find.byKey(const ValueKey('switch-hidden'));

Future<void> _launch(
  WidgetTester tester,
  WalletRepository repository, {
  CategoryType? initialType,
  int? initialParentId,
  Category? category,
  _Result? result,
}) async {
  final r = result ?? _Result();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute<Object?>(
                        builder: (_) => CategoryFormScreen(
                          initialType: initialType,
                          initialParentId: initialParentId,
                          category: category,
                          repository: repository,
                        ),
                      ),
                    )
                    .then((value) {
                      if (value is Category) r.saved = value;
                    });
              },
              child: const Text('mở form'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở form'));
  await tester.pumpAndSettle();
}

/// Kéo ListView thân màn cho tới khi [finder] được dựng rồi cuộn tới nó.
/// Các mục thấp (màu/cha/switch) có thể chưa được dựng (ListView lười).
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 8 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -240));
    await tester.pump();
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Category _seed(FakeWalletRepository repo, String name) =>
    repo.categoriesStored.firstWhere((c) => c.name == name);

void main() {
  group('ADD — bố cục & mặc định (acceptance 1/2, FR-001/005/007)', () {
    testWidgets('Mở Thêm (mặc định Chi tiêu) đúng mockup: không bottom nav, trường rỗng', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      await _launch(tester, repo);

      expect(find.text('Thêm danh mục'), findsOneWidget);
      expect(find.text('Lưu'), findsOneWidget);
      expect(find.text('Lưu danh mục'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);

      // Pill loại — Chi tiêu chọn sẵn (trắng trên teal), Thu nhập mờ.
      expect(
        tester.widget<Text>(find.text('Chi tiêu')).style!.color,
        AppColors.white,
      );
      expect(
        tester.widget<Text>(find.text('Thu nhập')).style!.color,
        AppColors.tabInactive,
      );
      expect(find.text('Chi tiêu'), findsOneWidget);

      // Tên rỗng; icon mặc định (receipt) đang chọn; cha & switch mặc định.
      expect(
        tester.widget<TextFormField>(_nameField).controller!.text,
        isEmpty,
      );
      final iconChip = find.descendant(
        of: find.byKey(const ValueKey('icon-opt-receipt')),
        matching: find.byType(Container),
      );
      final box = tester.widget<Container>(iconChip.first).decoration!
          as BoxDecoration;
      expect((box.border as Border).top.color, AppColors.teal);

      await _reveal(tester, _parentField);
      expect(find.text(_noParentLabel), findsOneWidget);
      await _reveal(tester, _hiddenSwitch);
      expect(
        tester.widget<SwitchListTile>(_hiddenSwitch).value,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('initialType = Thu nhập → loại Thu nhập chọn sẵn (acceptance 2)', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      await _launch(tester, repo, initialType: CategoryType.income);

      expect(find.text('Thêm danh mục'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Thu nhập')).style!.color,
        AppColors.white,
      );
      expect(
        tester.widget<Text>(find.text('Chi tiêu')).style!.color,
        AppColors.tabInactive,
      );
    });
  });

  group('ADD — tên lỗi trống/trùng chặn lưu (acceptance 4/12)', () {
    testWidgets('Tên rỗng → lỗi trống dưới ô, không ghi, không rời màn', (tester) async {
      final repo = FakeWalletRepository();
      final result = _Result();
      await _launch(tester, repo, result: result);

      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      expect(find.text(_errEmpty), findsOneWidget);
      expect(repo.categoriesStored.length, 15);
      expect(find.byType(CategoryFormScreen), findsOneWidget);
      expect(result.saved, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Trùng "Ăn uống" (cùng nhóm chi-gốc) → lỗi chặn, không ghi', (tester) async {
      final repo = FakeWalletRepository();
      final result = _Result();
      await _launch(tester, repo, result: result);

      await tester.enterText(_nameField, 'Ăn uống');
      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      expect(find.text(_errTrung), findsOneWidget);
      expect(repo.categoriesStored.length, 15);
      expect(find.byType(CategoryFormScreen), findsOneWidget);
      expect(result.saved, isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('ADD — chọn cha & đổi loại lọc danh sách cha (acceptance 5, FR-006)', () {
    testWidgets('Chọn cha chi → đổi Thu nhập → cha về "Không có", sheet chỉ cha thu', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      await _launch(tester, repo, initialType: CategoryType.expense);

      await _reveal(tester, _parentField);
      await tester.tap(_parentField);
      await tester.pumpAndSettle();
      expect(find.text('Chọn danh mục cha'), findsOneWidget);
      expect(find.text('Ăn uống'), findsWidgets); // cha chi xuất hiện.

      await tester.tap(find.byKey(const ValueKey('parent-1')));
      await tester.pumpAndSettle();
      expect(find.text('Ăn uống'), findsOneWidget); // field hiển thị cha.

      // Đổi sang Thu nhập → cha về "Không có" (cuộn lại đầu màn để thấy pill).
      await tester.drag(find.byType(ListView).first, const Offset(0, 600));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('type-pill-income')));
      await tester.pumpAndSettle();
      await _reveal(tester, _parentField);
      expect(find.text(_noParentLabel), findsOneWidget);

      // Sheet cha chỉ liệt kê cha thu.
      await tester.tap(_parentField);
      await tester.pumpAndSettle();
      expect(find.text('Chọn danh mục cha'), findsOneWidget);
      expect(find.byKey(const ValueKey('parent-9')), findsOneWidget); // Lương.
      expect(find.byKey(const ValueKey('parent-1')), findsNothing); // Ăn uống.
      await tester.tap(find.byKey(const ValueKey('parent-none')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('ADD — lưu hợp lệ (acceptance 3, FR-009/011, SC-007)', () {
    testWidgets('Lưu → ghi cuối nhóm với icon/màu/ẩn đã chọn, pop(saved)', (tester) async {
      final repo = FakeWalletRepository();
      final result = _Result();
      await _launch(tester, repo, result: result);

      await tester.enterText(_nameField, 'Ăn vặt');
      // Đổi icon + màu từ mặc định.
      await _reveal(tester, find.byKey(const ValueKey('icon-opt-home')));
      await tester.tap(find.byKey(const ValueKey('icon-opt-home')));
      await tester.pump();
      await _reveal(tester, find.byKey(const ValueKey('color-opt-1')));
      await tester.tap(find.byKey(const ValueKey('color-opt-1')));
      await tester.pump();

      await _reveal(tester, _savePrimary);
      await tester.ensureVisible(_savePrimary);
      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      expect(find.byType(CategoryFormScreen), findsNothing);
      expect(result.saved, isNotNull);
      final saved = result.saved!;
      expect(saved.name, 'Ăn vặt');
      expect(saved.type, CategoryType.expense);
      expect(saved.icon, 'home');
      expect(saved.color, categoryPresetColors[1]);
      expect(saved.parentId, isNull);
      expect(saved.isHidden, isFalse);
      expect(saved.isSystem, isFalse);
      // Cuối nhóm chi-gốc: max sortOrder seed 7 → 8.
      expect(saved.sortOrder, 8);

      // Store thật đã ghi (assert qua store, không sqlite).
      final stored = _seed(repo, 'Ăn vặt');
      expect(stored.id, saved.id);
      expect(stored.icon, 'home');
      expect(stored.color, categoryPresetColors[1]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Lưu mặc định (không đụng icon/màu/ẩn) → icon/color default per type', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      final result = _Result();
      await _launch(tester, repo, result: result);

      await tester.enterText(_nameField, 'Tiền lẻ');
      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      final saved = result.saved!;
      expect(saved.icon, defaultIconFor(CategoryType.expense));
      expect(saved.color, defaultColorFor(CategoryType.expense));
      expect(saved.isHidden, isFalse);
    });

    testWidgets('Chạm "Lưu" 2 lần nhanh → chỉ ghi 1 lần (FR-011/SC-007)', (tester) async {
      final repo = FakeWalletRepository();
      final result = _Result();
      await _launch(tester, repo, result: result);

      await tester.enterText(_nameField, 'Ăn vặt');
      await tester.tap(_savePrimary);
      await tester.pump(); // _saving = true → nút chính bị disabled (FR-011).
      await tester.tap(_savePrimary, warnIfMissed: false);
      await tester.pumpAndSettle();

      final added = repo.categoriesStored
          .where((c) => c.name == 'Ăn vặt')
          .toList();
      expect(added.length, 1);
      expect(find.byType(CategoryFormScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Back trước khi lưu → không insert (SC-007)', (tester) async {
      final repo = FakeWalletRepository();
      final result = _Result();
      await _launch(tester, repo, result: result);

      await tester.enterText(_nameField, 'Ăn vặt');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(CategoryFormScreen), findsNothing);
      expect(repo.categoriesStored.length, 15);
      expect(result.saved, isNull);
    });
  });

  group('EDIT — prefill & sửa (acceptance 6/9/14, SC-002/006)', () {
    testWidgets('Sửa danh mục con "Cà phê": prefill 100% + loại khóa readonly', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      final caPhe = _seed(repo, 'Cà phê');
      await _launch(tester, repo, category: caPhe);

      expect(find.text('Sửa danh mục'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(_nameField).controller!.text,
        'Cà phê',
      );
      // Con → loại khóa: không có pill, readonly box hiện loại hiện tại.
      expect(find.byKey(const ValueKey('type-pill-expense')), findsNothing);
      expect(find.byKey(const ValueKey('type-pill-income')), findsNothing);
      expect(find.text('Chi tiêu'), findsOneWidget);

      // Cha prefill "Ăn uống", công tắc ẩn tắt.
      await _reveal(tester, _parentField);
      expect(find.text('Ăn uống'), findsOneWidget);
      await _reveal(tester, _hiddenSwitch);
      expect(tester.widget<SwitchListTile>(_hiddenSwitch).value, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sửa danh mục ẩn → công tắc bật sẵn (edge, FR-007)', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [_cat(1, 'Di chuyển', isHidden: true)],
        transactions: const [],
      );
      await _launch(tester, repo, category: _cat(1, 'Di chuyển', isHidden: true));
      await _reveal(tester, _hiddenSwitch);
      expect(tester.widget<SwitchListTile>(_hiddenSwitch).value, isTrue);
    });

    testWidgets('Bật Ẩn → lưu → store isHidden=true (acceptance 9)', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [_cat(1, 'Di chuyển')],
        transactions: const [],
      );
      final result = _Result();
      await _launch(tester, repo, category: _cat(1, 'Di chuyển'), result: result);

      await _reveal(tester, _hiddenSwitch);
      await tester.tap(_hiddenSwitch);
      await tester.pumpAndSettle();
      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      expect(result.saved, isNotNull);
      expect(result.saved!.isHidden, isTrue);
      expect(repo.categoriesStored.firstWhere((c) => c.id == 1).isHidden, isTrue);
    });

    testWidgets('Sửa giữ nguyên tên → lưu không báo trùng (edge)', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [_cat(1, 'Di chuyển')],
        transactions: const [],
      );
      final result = _Result();
      await _launch(tester, repo, category: _cat(1, 'Di chuyển'), result: result);

      await tester.enterText(_nameField, 'Di chuyển');
      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      expect(find.byType(CategoryFormScreen), findsNothing);
      expect(result.saved, isNotNull);
      expect(find.text(_errTrung), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Back trước khi lưu → update không xảy ra (SC-007)', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [_cat(1, 'Di chuyển')],
        transactions: const [],
      );
      final result = _Result();
      await _launch(tester, repo, category: _cat(1, 'Di chuyển'), result: result);

      await tester.enterText(_nameField, 'Di chuyển mới');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(result.saved, isNull);
      expect(repo.categoriesStored.firstWhere((c) => c.id == 1).name, 'Di chuyển');
      expect(find.text(_errTrung), findsNothing);
    });
  });

  group('EDIT — khóa đổi loại (acceptance 8, SC-005)', () {
    testWidgets('Đã gắn giao dịch → ô loại readonly; tên/icon/màu vẫn sửa', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [_cat(1, 'Mua sắm')],
        transactions: [
          Transaction(
            id: 1,
            walletId: 1,
            type: TxnType.expense,
            category: 'Mua sắm',
            amount: -100000,
            date: DateTime(2026, 1, 1),
            categoryId: 1,
          ),
        ],
      );
      final result = _Result();
      await _launch(tester, repo, category: _cat(1, 'Mua sắm'), result: result);

      // Loại khóa readonly, không có pill.
      expect(find.byKey(const ValueKey('type-pill-expense')), findsNothing);
      expect(find.text('Chi tiêu'), findsOneWidget);

      // Tên vẫn sửa được.
      await tester.enterText(_nameField, 'Mua đồ');
      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      expect(result.saved, isNotNull);
      expect(result.saved!.type, CategoryType.expense);
      expect(repo.categoriesStored.firstWhere((c) => c.id == 1).name, 'Mua đồ');
      expect(tester.takeException(), isNull);
    });
  });

  group('EDIT — gốc sạch đổi loại (acceptance 7)', () {
    testWidgets('Gốc chưa gd, không con → đổi chi→thu, lưu về cuối nhóm thu', (
      tester,
    ) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [
          _cat(1, 'Giải trí', sortOrder: 0),
          _cat(2, 'Lương', type: CategoryType.income, sortOrder: 0),
        ],
        transactions: const [],
      );
      final result = _Result();
      await _launch(tester, repo, category: _cat(1, 'Giải trí'), result: result);

      // Gốc sạch → pill hiển thị (đổi được).
      expect(find.byKey(const ValueKey('type-pill-expense')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('type-pill-income')));
      await tester.pumpAndSettle();
      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      final saved = result.saved!;
      expect(saved.type, CategoryType.income);
      expect(saved.parentId, isNull);
      // Cuối nhóm thu-gốc: Lương sortOrder 0 → 1.
      expect(saved.sortOrder, 1);
      final stored = repo.categoriesStored.firstWhere((c) => c.id == 1);
      expect(stored.type, CategoryType.income);
      expect(tester.takeException(), isNull);
    });
  });

  group('EDIT — danh mục con & danh mục có con (acceptance 10/11, FR-008)', () {
    testWidgets('Sửa danh mục con → đổi cha (bỏ cha) lưu đúng nhóm gốc đích', (
      tester,
    ) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [
          _cat(1, 'Ăn uống', sortOrder: 0),
          _cat(13, 'Cà phê', parentId: 1, sortOrder: 0),
        ],
        transactions: const [],
      );
      final result = _Result();
      await _launch(
        tester,
        repo,
        category: _cat(13, 'Cà phê', parentId: 1),
        result: result,
      );

      await _reveal(tester, _parentField);
      await tester.tap(_parentField);
      await tester.pumpAndSettle();
      // Sheet cho phép bỏ cha (con vẫn đổi cha được).
      expect(find.byKey(const ValueKey('parent-none')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('parent-none')));
      await tester.pumpAndSettle();

      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      final saved = result.saved!;
      expect(saved.parentId, isNull);
      // Về gốc chi: Ăn uống sortOrder 0 → 1.
      expect(saved.sortOrder, 1);
      final stored = repo.categoriesStored.firstWhere((c) => c.id == 13);
      expect(stored.parentId, isNull);
      expect(stored.type, CategoryType.expense);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sửa danh mục có con → loại khóa + ô cha không mở sheet (acceptance 11)', (
      tester,
    ) async {
      final repo = FakeWalletRepository.withCategories(
        categoriesSeed: [
          _cat(1, 'Ăn uống', sortOrder: 0),
          _cat(2, 'Cà phê', parentId: 1, sortOrder: 0),
        ],
        transactions: const [],
      );
      await _launch(tester, repo, category: _cat(1, 'Ăn uống'));

      // Loại khóa.
      expect(find.byKey(const ValueKey('type-pill-expense')), findsNothing);
      expect(find.text('Chi tiêu'), findsOneWidget);

      // Chạm ô cha → không mở sheet.
      await _reveal(tester, _parentField);
      await tester.tap(_parentField);
      await tester.pumpAndSettle();
      expect(find.text('Chọn danh mục cha'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('ADD — Thêm với initialParentId preset cha (PBI 15, acceptance 6/7)', () {
    testWidgets('Ô cha hiện tên cha preset; lưu về cuối nhóm con của cha đó', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      final result = _Result();
      await _launch(
        tester,
        repo,
        initialType: CategoryType.expense,
        initialParentId: 1,
        result: result,
      );

      // Nhập tên trước khi cuộn (ô tên ở đầu form — ListView lười).
      await tester.enterText(_nameField, 'Cà phê sữa');
      await _reveal(tester, _parentField);
      // Ô "Danh mục cha (tùy chọn)" hiển thị sẵn tên cha preset — không chọn lại.
      expect(find.text('Ăn uống'), findsOneWidget);

      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      final saved = result.saved!;
      expect(saved.type, CategoryType.expense);
      expect(saved.parentId, 1);
      // Cuối nhóm con của "Ăn uống": con seed sortOrder 0..2 → 3.
      expect(saved.sortOrder, 3);
      final stored = repo.categoriesStored.firstWhere((c) => c.name == 'Cà phê sữa');
      expect(stored.parentId, 1);
      expect(stored.type, CategoryType.expense);
      expect(tester.takeException(), isNull);
    });

    testWidgets('So trùng tên theo nhóm con của cha preset — trùng "Cà phê" bị chặn', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      final result = _Result();
      await _launch(
        tester,
        repo,
        initialType: CategoryType.expense,
        initialParentId: 1,
        result: result,
      );

      await tester.enterText(_nameField, 'Cà phê');
      await tester.tap(_savePrimary);
      await tester.pumpAndSettle();

      expect(find.text(_errTrung), findsOneWidget);
      expect(repo.categoriesStored.length, 15);
      expect(find.byType(CategoryFormScreen), findsOneWidget);
      expect(result.saved, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sửa (category) vẫn thắng initialParentId — prefill cha thật của con', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      final caPhe = _seed(repo, 'Cà phê'); // con của "Ăn uống" (id 1).
      await _launch(
        tester,
        repo,
        initialType: CategoryType.expense,
        initialParentId: 3, // "Nhà ở" — cố tình khác cha thật.
        category: caPhe,
      );

      await _reveal(tester, _parentField);
      expect(find.text('Ăn uống'), findsOneWidget); // cha thật của con.
      expect(find.text('Nhà ở'), findsNothing); // preset không thắng.
      expect(tester.takeException(), isNull);
    });

    testWidgets('Không truyền initialParentId → mặc định "danh mục gốc" (không hồi quy PBI 14)', (
      tester,
    ) async {
      final repo = FakeWalletRepository();
      await _launch(tester, repo, initialType: CategoryType.expense);

      await _reveal(tester, _parentField);
      expect(find.text(_noParentLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
