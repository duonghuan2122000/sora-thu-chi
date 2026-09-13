import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_controller.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/dashboard_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_notification_history_store.dart';
import 'fakes/fake_wallet_repository.dart';

/// Mốc cố định 10/09 — khớp seed 11 dòng mẫu như `transaction_screen_test.dart`
/// (card Thu 15.000.000 / Chi 2.455.000, ví hoạt động tổng 19.450.000).
final _now = DateTime(2026, 9, 10, 9, 30);

Future<int> _pumpDashboard(
  WidgetTester tester, {
  FakeWalletRepository? repo,
  ValueChanged<int>? onSelectTab,
}) async {
  Get.reset();
  final repository = repo ?? FakeWalletRepository(null, _now);
  Get.put<WalletRepository>(repository);
  final controller = TransactionController(repository);
  Get.put(controller);
  await controller.load(now: _now);
  addTearDown(Get.reset);
  var selectedTab = -1;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Scaffold(
        body: DashboardScreen(
          store: FakeNotificationHistoryStore(),
          onSelectTab: onSelectTab ?? (i) => selectedTab = i,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return selectedTab;
}

void main() {
  group('DashboardScreen — nội dung màn Tổng quan (PBI 33)', () {
    testWidgets('(a) số dư = tổng ví đang hoạt động (19.450.000 đ)', (
      tester,
    ) async {
      await _pumpDashboard(tester);

      expect(find.text('19.450.000 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(b) 2 thẻ Thu/Chi tháng này đúng số (FR-002)', (
      tester,
    ) async {
      await _pumpDashboard(tester);

      expect(find.text('Thu tháng này'), findsOneWidget);
      expect(find.text('Chi tháng này'), findsOneWidget);
      expect(find.text('15.000.000 đ'), findsOneWidget);
      expect(find.text('2.455.000 đ'), findsOneWidget);
    });

    testWidgets(
      '(c) đúng 5 dòng gần nhất, mới nhất trước (FR-003/004)',
      (tester) async {
        await _pumpDashboard(tester);

        expect(find.text('Giao dịch gần đây'), findsOneWidget);
        // 5 dòng mới nhất theo seed (hôm nay: -85.000/-450.000/-350.000,
        // hôm qua: -120.000/+12.000.000) — "Bán đồ cũ" (5 ngày trước) bị loại.
        for (final amount in ['-85.000 đ', '-450.000 đ', '-350.000 đ', '-120.000 đ', '+12.000.000 đ']) {
          expect(find.text(amount), findsOneWidget);
        }
        expect(find.text('Bán đồ cũ'), findsNothing);

        final firstY = tester.getTopLeft(find.text('-85.000 đ')).dy;
        final lastY = tester.getTopLeft(find.text('+12.000.000 đ')).dy;
        expect(firstY, lessThan(lastY));
      },
    );

    testWidgets('(d) chạm 1 dòng → mở đúng màn chi tiết (FR-005)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await _pumpDashboard(tester);

      await tester.tap(find.text('+12.000.000 đ'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết giao dịch'), findsOneWidget);
      expect(find.text('+12.000.000 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(e) chạm "Xem tất cả" → gọi onSelectTab(1) (FR-004)', (
      tester,
    ) async {
      int? selected;
      await _pumpDashboard(tester, onSelectTab: (i) => selected = i);

      await tester.tap(find.text('Xem tất cả'));
      await tester.pump();

      expect(selected, 1);
    });

    testWidgets(
      '(f) chưa có giao dịch → empty state, số dư = tổng initial_balance, '
      '2 thẻ 0 đ (FR-006)',
      (tester) async {
        final wallets = [
          const Wallet(
            id: 1,
            name: 'Tiền mặt',
            type: WalletType.cash,
            balance: 500000,
            sortOrder: 1,
          ),
          const Wallet(
            id: 2,
            name: 'Vietcombank',
            type: WalletType.bank,
            balance: 1000000,
            sortOrder: 2,
          ),
        ];
        await _pumpDashboard(
          tester,
          repo: FakeWalletRepository(wallets, _now, const []),
        );

        expect(find.text('1.500.000 đ'), findsOneWidget); // tổng initial_balance.
        expect(find.text('0 đ'), findsNWidgets(2)); // 2 thẻ thu/chi.
        expect(find.text('Chưa có giao dịch nào.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('(g) tất cả ví ẩn → số dư hiển thị 0 đ', (tester) async {
      final wallets = [
        const Wallet(
          id: 1,
          name: 'Tiền mặt',
          type: WalletType.cash,
          balance: 500000,
          isHidden: true,
          sortOrder: 1,
        ),
      ];
      await _pumpDashboard(
        tester,
        repo: FakeWalletRepository(wallets, _now, const []),
      );

      expect(find.text('0 đ'), findsNWidgets(3)); // số dư + 2 thẻ.
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '(h) có dòng chuyển khoản trong 5 dòng gần đây → màu trung tính, '
      'không dấu +/-',
      (tester) async {
        final wallets = [
          const Wallet(
            id: 1,
            name: 'Tiền mặt',
            type: WalletType.cash,
            balance: 0,
            sortOrder: 1,
          ),
          const Wallet(
            id: 2,
            name: 'Vietcombank',
            type: WalletType.bank,
            balance: 0,
            sortOrder: 2,
          ),
        ];
        final transactions = [
          Transaction(
            id: 1,
            walletId: 1,
            type: TxnType.transfer,
            note: 'Chuyển sang Vietcombank',
            amount: -300000,
            date: _now,
            transferGroupId: 1,
          ),
          Transaction(
            id: 2,
            walletId: 2,
            type: TxnType.transfer,
            note: 'Chuyển sang Vietcombank',
            amount: 300000,
            date: _now,
            transferGroupId: 1,
          ),
        ];
        await _pumpDashboard(
          tester,
          repo: FakeWalletRepository(wallets, _now, transactions),
        );

        expect(find.text('Chuyển khoản'), findsOneWidget);
        expect(find.text('300.000 đ'), findsOneWidget);
        expect(find.text('+300.000 đ'), findsNothing);
        expect(find.text('-300.000 đ'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
