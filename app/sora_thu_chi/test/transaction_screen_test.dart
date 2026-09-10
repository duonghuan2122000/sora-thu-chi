import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/app_shell.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_controller.dart';
import 'package:sora_thu_chi/core/transaction/transaction_filter.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_source.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/transaction_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/sora_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

/// Mốc thời gian cố định 10/09 — mọi dòng seed 11 mẫu nằm trong tháng 9 nên
/// số card tròn 15.000.000 / 2.455.000 (không phụ thuộc ngày chạy thật).
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

/// Đăng ký controller + fake repo, nạp trước rồi mới pump [TransactionScreen]
/// (load do AppShell gọi khi chọn tab — standalone tự nạp cho deterministic).
Future<TransactionController> _pumpScreen(
  WidgetTester tester, {
  FakeWalletRepository? repo,
  double textScale = 1.0,
  EdgeInsets safe = EdgeInsets.zero,
  Size? size,
}) async {
  Get.reset();
  final repository = repo ?? FakeWalletRepository(null, _now);
  // Đăng ký cả WalletRepository để màn chi tiết (PBI 10) đọc qua
  // ensureWalletRepository() dùng chung fake — không tạo drift (R10).
  Get.put<WalletRepository>(repository);
  final controller = TransactionController(repository);
  Get.put(controller);
  await controller.load(now: _now);
  addTearDown(Get.reset);
  await _pump(
    tester,
    // Trong app thật màn nằm trong Scaffold của AppShell (Material ancestor).
    Scaffold(body: const TransactionScreen()),
    textScale: textScale,
    safe: safe,
    size: size,
  );
  return controller;
}

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('TransactionScreen — màn danh sách giao dịch', () {
    testWidgets(
      '(a) render seed 11 dòng: header, card Thu/Chi, nhóm ngày đúng',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _pumpScreen(tester);

        // Header: tiêu đề giữa + icon lọc bên phải.
        expect(find.text('Giao dịch'), findsOneWidget);
        expect(find.byIcon(Icons.filter_list), findsOneWidget);

        // Card thống kê đúng tổng seed (FR-002/003).
        expect(find.text('Thu tháng này'), findsOneWidget);
        expect(find.text('Chi tháng này'), findsOneWidget);
        expect(find.text('15.000.000 đ'), findsOneWidget);
        expect(find.text('2.455.000 đ'), findsOneWidget);

        // Nhóm ngày mới nhất trên: HÔM NAY rồi HÔM QUA rồi dd/MM/yyyy.
        expect(find.text('HÔM NAY - 10/09/2026'), findsOneWidget);
        expect(find.text('HÔM QUA - 09/09/2026'), findsOneWidget);
        expect(find.text('05/09/2026'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('(b) thu teal +, chi coral − (màu + dấu đúng)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(tester);

      expect(find.text('+12.000.000 đ'), findsOneWidget); // Lương (thu).
      expect(_textColor(tester, '+12.000.000 đ'), AppColors.teal);
      expect(find.text('-85.000 đ'), findsOneWidget); // Ăn trưa (chi).
      expect(_textColor(tester, '-85.000 đ'), AppColors.coral);
      expect(find.text('+2.500.000 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '(c) chuyển khoản 1 dòng trung tính, phụ đề nguồn → đích, không dấu',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await _pumpScreen(tester);

        // Đúng 1 dòng "Chuyển khoản", không tách 2 vế (FR-007, acceptance 4).
        expect(find.text('Chuyển khoản'), findsOneWidget);
        expect(find.text('Vietcombank → Momo'), findsOneWidget);
        expect(find.text('700.000 đ'), findsOneWidget);
        expect(_textColor(tester, '700.000 đ'), SoraColors.light.listLabel);
        expect(find.text('-700.000 đ'), findsNothing);
        expect(find.text('+700.000 đ'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '(d) shell: tab Giao dịch tự nạp; chạm lọc/dòng/FAB không lỗi (FR-014)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(420, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Chỉ đăng ký fake repo — controller do AppShell tạo khi cần (no drift).
        // Seed & load dùng giờ thật (như app) → assert dòng tương đối (HÔM NAY/
        // cách nay 3 ngày) luôn hiện, không phụ thuộc ngày chạy trong tháng.
        Get.reset();
        Get.put<WalletRepository>(FakeWalletRepository(null));
        addTearDown(Get.reset);

        await _pump(tester, const AppShell());

        // Chọn tab Giao dịch → tự nạp dữ liệu (R6/FR-011).
        await tester.tap(find.text('Giao dịch'));
        await tester.pumpAndSettle();
        expect(find.text('Giao dịch'), findsNWidgets(2)); // header + tab.
        expect(find.text('Thu tháng này'), findsOneWidget);
        expect(find.text('-85.000 đ'), findsOneWidget); // chi hôm nay.
        expect(find.text('Chuyển khoản'), findsOneWidget); // gộp 1 dòng.

        // Chạm icon lọc → mở màn "Tìm kiếm & Lọc" thật (PBI 12, không còn no-op).
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        expect(find.text('Tìm kiếm giao dịch...'), findsOneWidget);
        expect(find.text('BỘ LỌC NÂNG CAO'), findsOneWidget);
        expect(find.text('Áp dụng'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        // Chạm một dòng → mở màn chi tiết giao dịch (PBI 10), không no-op.
        await tester.tap(find.text('Lương'));
        await tester.pumpAndSettle();
        expect(find.text('Chi tiết giao dịch'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Giao dịch'), findsNWidgets(2)); // header + tab.

        // FAB (shell) mở màn ghi giao dịch tạm, không lỗi.
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();
        expect(find.text('Thêm giao dịch'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('(e) chưa có giao dịch → card 0 đ + empty state, không lỗi', (
      tester,
    ) async {
      await _pumpScreen(tester, repo: FakeWalletRepository([], null, const []));

      expect(find.text('0 đ'), findsNWidgets(2));
      expect(find.text('Chưa có giao dịch nào.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(f) ví ẩn: giao dịch vẫn hiện, tên ví đủ (giữ lịch sử)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Ẩn Vietcombank (id 2) — mọi giao dịch của nó vẫn phải hiện (giữ lịch sử).
      final wallets = [
        for (final w in WalletSource.all())
          if (w.id == 2)
            Wallet(
              id: w.id,
              name: w.name,
              type: w.type,
              balance: w.balance,
              isHidden: true,
              sortOrder: w.sortOrder,
            )
          else
            w,
      ];
      final repo = FakeWalletRepository(wallets, _now);

      await _pumpScreen(tester, repo: repo);

      expect(find.text('+12.000.000 đ'), findsOneWidget); // Lương VCB vẫn hiện.
      expect(find.text('Vietcombank · Lương tháng 8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(g) cỡ chữ lớn + vùng an toàn → cuộn hết, không overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(
        tester,
        textScale: 2.0,
        safe: const EdgeInsets.only(bottom: 34),
      );

      for (var i = 0; i < 6; i++) {
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -500),
        );
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('(h) số tiền rất lớn → hiển thị đủ, không tràn/cắt (FR-009)', (
      tester,
    ) async {
      final cash = const Wallet(
        id: 1,
        name: 'Tiền mặt',
        type: WalletType.cash,
        balance: 0,
        sortOrder: 1,
      );
      final repo = FakeWalletRepository(
        [cash],
        null,
        [
          Transaction(
            id: 1,
            walletId: 1,
            type: TxnType.income,
            category: 'Thu nhập khác',
            amount: 1234567890123,
            date: _now,
          ),
        ],
      );

      await _pumpScreen(tester, repo: repo);

      expect(find.text('+1.234.567.890.123 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TransactionScreen — chạm dòng mở màn chi tiết (PBI 10, R2)', () {
    double listOffset(WidgetTester tester) {
      final scrollable = find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      );
      return tester.state<ScrollableState>(scrollable).position.pixels;
    }

    testWidgets('chạm dòng thu → mở detail đúng dữ liệu; back giữ vị trí cuộn '
        '(acceptance 6/7, FR-010/013)', (tester) async {
      // Màn hình nhỏ để danh sách phải cuộn — mới đo được giữ vị trí.
      await tester.binding.setSurfaceSize(const Size(420, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(tester);

      // Cuộn tới dòng cuối (Bán đồ cũ) để xác minh giữ vị trí sau khi back.
      while (find.text('Bán đồ cũ').evaluate().isEmpty) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await tester.pump();
      }
      await tester.ensureVisible(find.text('Bán đồ cũ'));
      await tester.pumpAndSettle();
      final before = listOffset(tester);
      expect(before, greaterThan(0)); // đã cuộn khỏi đầu.

      await tester.tap(find.text('Bán đồ cũ'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết giao dịch'), findsOneWidget);
      expect(find.text('+2.500.000 đ'), findsOneWidget);
      expect(_textColor(tester, '+2.500.000 đ'), AppColors.teal);
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết giao dịch'), findsNothing);
      expect(listOffset(tester), before); // vị trí cuộn giữ nguyên (SC-008).
      expect(tester.takeException(), isNull);
    });

    testWidgets('chạm dòng transfer đã gộp → 1 màn chi tiết trung tính, 2 hàng '
        'Ví nguồn/đích (FR-006/SC-005)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpScreen(tester);

      await tester.tap(find.text('Chuyển khoản'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết giao dịch'), findsOneWidget);
      // Khối tóm tắt trung tính: không dấu +/-, màu trung tính.
      expect(find.text('700.000 đ'), findsOneWidget);
      expect(_textColor(tester, '700.000 đ'), SoraColors.light.textPrimary);
      expect(find.text('+700.000 đ'), findsNothing);
      // Vùng chi tiết: đúng chiều nguồn → đích.
      expect(find.text('Ví nguồn'), findsOneWidget);
      expect(find.text('Ví đích'), findsOneWidget);
      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('Momo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TransactionScreen — nhánh đã lọc (PBI 12, R4/R5)', () {
    /// Chi + danh mục Ăn uống, preset `all` — 3 dòng seed (id 1/6/10),
    /// Tổng −885.000. Cố định [sort].
    TxnSearchFilter eatFilter({SortOption sort = SortOption.dateNewest}) =>
        TxnSearchFilter.defaults(now: _now)
            .withDateRange(DatePreset.all)
            .copyWith(type: TxnTypeFilter.expense, categoryIds: {1}, sort: sort);

    testWidgets('Áp dụng → thanh N kết quả · Tổng thay card tháng; list chỉ tập '
        'khớp; chạm dòng mở chi tiết (FR-012/013)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = await _pumpScreen(tester);
      controller.setFilter(eatFilter());
      await tester.pump();

      // Card "Thu/Chi tháng này" ẩn; thay bằng thanh chỉ báo.
      expect(find.text('Thu tháng này'), findsNothing);
      expect(find.text('3 kết quả · Tổng: -885.000 đ'), findsOneWidget);
      expect(find.text('Bỏ lọc'), findsOneWidget);
      // Chỉ 3 chi Ăn uống — không còn thu/các chi khác.
      expect(find.text('+12.000.000 đ'), findsNothing);
      expect(find.text('-120.000 đ'), findsNothing);
      expect(find.text('Ăn uống'), findsNWidgets(3));

      // Chạm dòng vẫn mở chi tiết (FR-012).
      await tester.tap(find.text('-450.000 đ'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết giao dịch'), findsOneWidget);
      expect(find.text('-450.000 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sort Số tiền giảm dần → list phẳng không header ngày, khoản '
        'lớn trước (R4)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = await _pumpScreen(tester);
      controller.setFilter(eatFilter(sort: SortOption.amountDesc));
      await tester.pump();

      // Phẳng: không có header ngày.
      expect(find.textContaining('HÔM'), findsNothing);
      expect(find.text('3 kết quả · Tổng: -885.000 đ'), findsOneWidget);
      // Khoản 450.000 hiển thị trên 350.000 và 85.000.
      final top450 = tester.getTopLeft(find.text('-450.000 đ'));
      final top85 = tester.getTopLeft(find.text('-85.000 đ'));
      expect(top450.dy, lessThan(top85.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sort Ngày cũ nhất → nhóm ngày cũ nhất lên đầu (R4)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Lọc toàn tập (preset all), sort cũ nhất — nhóm 05/09 (cũ nhất) lên đầu.
      final controller = await _pumpScreen(tester);
      final all = TxnSearchFilter.defaults(now: _now)
          .withDateRange(DatePreset.all)
          .copyWith(sort: SortOption.dateOldest);
      controller.setFilter(all);
      await tester.pump();

      expect(find.text('HÔM NAY - 10/09/2026'), findsOneWidget);
      expect(find.text('05/09/2026'), findsOneWidget);
      final oldestY = tester.getTopLeft(find.text('05/09/2026')).dy;
      final todayY = tester.getTopLeft(find.text('HÔM NAY - 10/09/2026')).dy;
      expect(oldestY, lessThan(todayY));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Bỏ lọc → về toàn bộ + card tháng hiện lại (FR-013)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = await _pumpScreen(tester);
      controller.setFilter(eatFilter());
      await tester.pump();
      expect(find.text('Thu tháng này'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('clear-filter')));
      await tester.pumpAndSettle();

      expect(find.text('Thu tháng này'), findsOneWidget);
      expect(find.text('3 kết quả · Tổng: -885.000 đ'), findsNothing);
      expect(find.text('+12.000.000 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('0 kết quả → thanh 0 + empty khớp có gợi ý, không lỗi (FR-016)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final controller = await _pumpScreen(tester);
      final none = eatFilter().copyWith(keyword: 'xyz không có');
      controller.setFilter(none);
      await tester.pump();

      expect(find.text('0 kết quả · Tổng: 0 đ'), findsOneWidget);
      expect(find.text('Không có giao dịch khớp bộ lọc.'), findsOneWidget);
      expect(find.text('Bỏ lọc để xem toàn bộ.'), findsOneWidget);
      expect(find.text('Chưa có giao dịch nào.'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
