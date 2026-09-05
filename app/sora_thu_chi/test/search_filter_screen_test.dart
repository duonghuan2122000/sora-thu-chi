import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/transaction/transaction_filter.dart';
import 'package:sora_thu_chi/screens/search_filter_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

/// Anchor 10/09 — seed 11 mẫu đều trong tháng 9. Mặc định màn lọc "Tháng này":
/// 10 kết quả (gộp transfer), Tổng = 15.000.000 − 2.455.000 = 12.545.000 đ.
final _now = DateTime(2026, 9, 10, 9, 30);

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  double textScale = 1.0,
  EdgeInsets safe = EdgeInsets.zero,
  Size? size,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(
          size: size ?? MediaQueryData.fromView(tester.view).size,
          padding: safe,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: home,
    ),
  );
}

Future<FakeWalletRepository> _pumpScreen(
  WidgetTester tester, {
  double textScale = 1.0,
  EdgeInsets safe = EdgeInsets.zero,
  Size? size,
}) async {
  final repo = FakeWalletRepository(null, _now);
  await _pump(
    tester,
    Scaffold(
      body: SearchFilterScreen(repository: repo, now: _now),
    ),
    textScale: textScale,
    safe: safe,
    size: size,
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  group('SearchFilterScreen — màn lọc giao dịch', () {
    testWidgets('(a) bố cục mockup 05: app bar back + ô tìm pill, 4 chip, '
        'BỘ LỌC NÂNG CAO, 5 dòng, tóm tắt, Đặt lại/Áp dụng', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpScreen(tester);

      // App bar: ô tìm pill (màn là home ở test → không có nút back; back khi
      // mở qua route — kiểm chứng ở case (i) qua pageBack).
      expect(find.text('Tìm kiếm giao dịch...'), findsOneWidget);

      // Chip loại 4 nút.
      for (final label in ['Tất cả', 'Thu', 'Chi', 'Chuyển khoản']) {
        expect(find.text(label), findsOneWidget);
      }

      expect(find.text('BỘ LỌC NÂNG CAO'), findsOneWidget);
      expect(find.text('Khoảng thời gian'), findsOneWidget);
      expect(find.text('Danh mục'), findsOneWidget);
      expect(find.text('Ví'), findsOneWidget);
      expect(find.text('Khoảng số tiền'), findsOneWidget);
      expect(find.text('Sắp xếp theo'), findsOneWidget);

      // Giá trị mặc định FR-005/007/009.
      expect(find.text('01/09/2026 - 30/09/2026'), findsOneWidget);
      expect(find.text('Tất cả các ví'), findsOneWidget);
      expect(find.text('Ngày mới nhất'), findsOneWidget);

      // Dòng tóm tắt + 2 nút chân.
      expect(find.text('10 kết quả · Tổng: 12.545.000 đ'), findsOneWidget);
      expect(find.text('Đặt lại'), findsOneWidget);
      expect(find.text('Áp dụng'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(b) gõ từ khóa → summary live sau debounce ~250ms, bỏ dấu '
        '"an uong" ↔ "Ăn uống"', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpScreen(tester);

      await tester.enterText(find.byKey(const ValueKey('search-field')), 'an uong');
      await tester.pump(const Duration(milliseconds: 300)); // vượt debounce.
      await tester.pump();

      // 3 chi Ăn uống (id 1/6/10): −85k −450k −350k.
      expect(find.text('3 kết quả · Tổng: -885.000 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(c) chip Chi/Thu/Chuyển khoản → summary đổi + nguồn danh mục '
        'theo loại; Chuyển khoản vô hiệu dòng Danh mục', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpScreen(tester);

      // Chi → 6 dòng chi, tổng −2.455.000.
      await tester.tap(find.text('Chi'));
      await tester.pumpAndSettle();
      expect(find.text('6 kết quả · Tổng: -2.455.000 đ'), findsOneWidget);

      // Sheet danh mục chỉ chi — không thấy danh mục thu (Lương).
      await tester.tap(find.byKey(const ValueKey('filter-category')));
      await tester.pumpAndSettle();
      expect(find.text('Chọn danh mục'), findsWidgets); // tiêu đề sheet.
      expect(find.text('Ăn uống (gồm con)'), findsOneWidget); // cha có con.
      expect(find.text('Lương'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('category-done')));
      await tester.pumpAndSettle();

      // Thu → 3 dòng thu, tổng +15.000.000.
      await tester.tap(find.text('Thu'));
      await tester.pumpAndSettle();
      expect(find.text('3 kết quả · Tổng: 15.000.000 đ'), findsOneWidget);

      // Chuyển khoản → 1 dòng transfer gộp, không vào Tổng; dòng Danh mục vô hiệu.
      // (Cuộn hàng chip ngang để lộ chip Chuyển khoản nằm ngoài viewport.)
      await tester.drag(
        find.byKey(const ValueKey('type-chips')),
        const Offset(-250, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chuyển khoản'));
      await tester.pumpAndSettle();
      expect(find.text('1 kết quả · Tổng: 0 đ'), findsOneWidget);
      expect(find.text('Không áp dụng cho Chuyển khoản'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(d) chọn danh mục nhiều: chọn cha Ăn uống → chip hiện; '
        'mở lại bỏ chọn → trở về trống', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpScreen(tester);

      await tester.tap(find.text('Chi'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('filter-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category-option-Ăn uống')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('category-done')));
      await tester.pumpAndSettle();

      // Chip danh mục + nút "+ Thêm".
      expect(find.byKey(const ValueKey('category-chip-Ăn uống')), findsOneWidget);
      expect(find.byKey(const ValueKey('category-add-more')), findsOneWidget);
      expect(find.text('3 kết quả · Tổng: -885.000 đ'), findsOneWidget);

      // Mở lại sheet (tap nhãn — tránh InputChip đang che vùng row) → bỏ chọn.
      await tester.tap(find.text('Danh mục'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category-option-Ăn uống')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('category-done')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('category-chip-Ăn uống')), findsNothing);
      expect(find.text('Chọn danh mục'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(e) sheet ví: chọn Momo → value; về Tất cả các ví', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('filter-wallet')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Momo'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('filter-wallet-value')), findsOneWidget);
      expect(find.text('Momo'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('filter-wallet')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tất cả các ví'));
      await tester.pumpAndSettle();
      expect(find.text('Momo'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(f) khoảng tiền: trống một đầu giữ giới hạn kia; min>max → '
        'báo đỏ + vô hiệu Áp dụng; Xóa giới hạn phục hồi', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpScreen(tester);

      // Từ = 50.000.
      await tester.tap(find.byKey(const ValueKey('amount-min')));
      await tester.pumpAndSettle();
      for (final d in ['5', '0', '0', '0', '0']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('amount-done')));
      await tester.pumpAndSettle();
      // Đến = 30.000 → min > max → báo đỏ + Áp dụng vô hiệu.
      await tester.tap(find.byKey(const ValueKey('amount-max')));
      await tester.pumpAndSettle();
      for (final d in ['3', '0', '0', '0', '0']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('amount-done')));
      await tester.pumpAndSettle();

      expect(
        find.text('Số tiền tối thiểu không được lớn hơn tối đa'),
        findsOneWidget,
      );
      final apply = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('apply-filter')),
      );
      expect(apply.onPressed, isNull);

      // Xóa giới hạn Đến → hết lỗi, Áp dụng bật lại, chỉ còn ràng buộc Từ.
      await tester.tap(find.byKey(const ValueKey('amount-max')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('amount-clear')));
      await tester.pumpAndSettle();
      expect(
        find.text('Số tiền tối thiểu không được lớn hơn tối đa'),
        findsNothing,
      );
      final apply2 = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('apply-filter')),
      );
      expect(apply2.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(g) preset thời gian: Hôm nay → hẹp; Toàn bộ → rộng', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('filter-period')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hôm nay'));
      await tester.pumpAndSettle();
      expect(find.text('10/09/2026 - 10/09/2026'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('filter-period')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Toàn bộ'));
      await tester.pumpAndSettle();
      expect(find.text('Toàn bộ'), findsOneWidget); // value của dòng.
      expect(find.text('10 kết quả · Tổng: 12.545.000 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(h) Đặt lại → về mặc định (chip Tất cả, Tháng này, mọi điều kiện)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpScreen(tester);

      // Đổi sang Chi + từ khóa.
      await tester.tap(find.text('Chi'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('search-field')), 'ăn');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('Chi'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('reset-filter')));
      await tester.pumpAndSettle();

      // Về mặc định: Tháng này + mọi điều kiện rỗng + summary toàn bộ.
      expect(find.text('01/09/2026 - 30/09/2026'), findsOneWidget);
      expect(find.text('Tất cả các ví'), findsOneWidget);
      expect(find.text('Ngày mới nhất'), findsOneWidget);
      expect(find.text('10 kết quả · Tổng: 12.545.000 đ'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('search-field')),
      );
      expect(field.controller!.text, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(i) Áp dụng → pop(filter) đúng điều kiện; back → pop(null) giữ '
        'tập cũ (FR-015)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeWalletRepository(null, _now);
      TxnSearchFilter? applied;
      TxnSearchFilter? secondResult;
      await _pump(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push<TxnSearchFilter>(
                        MaterialPageRoute(
                          builder: (_) =>
                              SearchFilterScreen(repository: repo, now: _now),
                        ),
                      );
                  // Lần mở đầu → applied; lần sau (test back) → secondResult.
                  if (applied == null) {
                    applied = result;
                  } else {
                    secondResult = result;
                  }
                },
                child: const Text('open-filter'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mở, đổi chip Chi + ví Momo, Áp dụng → nhận filter.
      await tester.tap(find.text('open-filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chi'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter-wallet')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Momo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-filter')));
      await tester.pumpAndSettle();

      expect(applied, isNotNull);
      expect(applied!.type, TxnTypeFilter.expense);
      expect(applied!.walletId, isNotNull);

      // Mở lại, đổi chip Thu rồi back → pop null: secondResult null, applied giữ.
      await tester.tap(find.text('open-filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thu'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(secondResult, isNull);
      expect(applied!.type, TxnTypeFilter.expense);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(j) cỡ chữ lớn + safe area → cuộn hết, nút chân không cắt, '
        'không overflow (SC-011)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(
        tester,
        textScale: 2.0,
        safe: const EdgeInsets.only(bottom: 34),
      );

      final bodyList = find.byKey(const ValueKey('filter-body-list'));
      for (var i = 0; i < 8; i++) {
        await tester.drag(bodyList, const Offset(0, -400));
        await tester.pump();
      }
      // Nút chân vẫn hiện (bottomNavigationBar cố định).
      expect(find.text('Áp dụng'), findsOneWidget);
      expect(find.text('Đặt lại'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
