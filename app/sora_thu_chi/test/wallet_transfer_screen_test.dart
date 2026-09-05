import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_controller.dart';
import 'package:sora_thu_chi/screens/wallet_transfer_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

const _vcb = Wallet(
  id: 2,
  name: 'Vietcombank',
  type: WalletType.bank,
  icon: '🏦',
  initialBalance: 1200000,
  balance: 14800000,
  sortOrder: 2,
);
const _momo = Wallet(
  id: 4,
  name: 'Momo',
  type: WalletType.eWallet,
  icon: '📱',
  balance: 1450000,
  sortOrder: 4,
);
const _cashLow = Wallet(
  id: 1,
  name: 'Tiền mặt',
  type: WalletType.cash,
  icon: '💵',
  initialBalance: 500000,
  balance: 500000,
  sortOrder: 1,
);
const _creditVib = Wallet(
  id: 3,
  name: 'Thẻ tín dụng VIB',
  type: WalletType.credit,
  icon: '💳',
  balance: 0,
  sortOrder: 3,
  creditLimit: 20000000,
  creditUsed: 6500000,
);
const _savingsHidden = Wallet(
  id: 5,
  name: 'Sổ tiết kiệm',
  type: WalletType.savings,
  icon: '🏷️',
  balance: 9000000,
  isHidden: true,
  sortOrder: 5,
);

/// Fake repo đếm số lần `performTransfer` — kiểm chống double-tap (SC-006).
class _CountingRepo extends FakeWalletRepository {
  _CountingRepo(super.seed);

  int transferCalls = 0;

  @override
  Future<void> performTransfer({
    required int fromWalletId,
    required int toWalletId,
    required int amount,
    required DateTime date,
    String note = '',
  }) async {
    transferCalls++;
    await super.performTransfer(
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      date: date,
      note: note,
    );
  }
}

/// Đăng ký controller + fake repo (seed 5 ví mẫu trừ khi truyền [seed]).
Future<WalletController> _register({List<Wallet>? seed}) async {
  Get.reset();
  final controller = WalletController(FakeWalletRepository(seed));
  Get.put(controller);
  await controller.init();
  addTearDown(Get.reset);
  return controller;
}

/// Đăng ký controller với fake repo đếm lần transfer → trả (controller, repo).
Future<(WalletController, _CountingRepo)> _registerCounting() async {
  Get.reset();
  final repo = _CountingRepo(
    const [_cashLow, _vcb, _creditVib, _momo, _savingsHidden],
  );
  final controller = WalletController(repo);
  Get.put(controller);
  await controller.init();
  addTearDown(Get.reset);
  return (controller, repo);
}

/// Mở màn chuyển tiền (route đẩy — để back/pop hoạt động).
Future<void> _open(
  WidgetTester tester,
  WalletController controller,
  Wallet source, {
  Size? size,
  double textScale = 1.0,
  EdgeInsets safe = EdgeInsets.zero,
}) async {
  if (size != null) {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      builder: (context, child) => MediaQuery(
        data: MediaQueryData(
          padding: safe,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (_) => WalletTransferScreen(
                    sourceWallet: source,
                    controller: controller,
                  ),
                ),
              ),
              child: const Text('MỞ CHUYỂN'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('MỞ CHUYỂN'));
  await tester.pumpAndSettle();
}

/// Chọn ví đích [name] qua bottom sheet.
Future<void> _pickDest(WidgetTester tester, String name) async {
  await tester.tap(find.text('Chọn ví'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

/// Nhập số tiền [value] vào trường Số tiền chuyển.
Future<void> _enterAmount(WidgetTester tester, String value) async {
  await tester.enterText(find.byKey(const ValueKey('amount-field')), value);
  await tester.pumpAndSettle();
}

ElevatedButton _confirmButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Xác nhận chuyển tiền'),
    );

void main() {
  group('WalletTransferScreen — màn chuyển tiền giữa ví', () {
    testWidgets('(a) mở từ Vietcombank: đủ bố cục mockup, không bottom nav', (
      tester,
    ) async {
      final c = await _register();
      await _open(tester, c, _vcb, size: const Size(800, 2000));

      expect(find.text('Chuyển tiền giữa ví'), findsOneWidget); // app bar
      expect(find.text('Từ ví'), findsOneWidget);
      expect(find.text('Đến ví'), findsOneWidget);
      // Ô "Từ ví" nạp sẵn Vietcombank + số dư.
      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('Số dư: 14.800.000 đ'), findsOneWidget);
      // Ô "Đến ví" trống.
      expect(find.text('Chọn ví'), findsOneWidget);
      // Đủ trường + dòng preview + nút Xác nhận.
      expect(find.text('Số tiền chuyển'), findsOneWidget);
      expect(find.text('Ngày giờ'), findsOneWidget);
      expect(find.text('Ghi chú'), findsOneWidget);
      expect(find.text('Số dư sau chuyển'), findsOneWidget);
      expect(find.text('— / —'), findsOneWidget);
      expect(find.text('Xác nhận chuyển tiền'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '(b) danh sách đích: ví active cùng VND, không chứa nguồn/thẻ tín dụng/ví ẩn',
      (tester) async {
        final c = await _register();
        await _open(tester, c, _vcb, size: const Size(800, 2000));

        await tester.tap(find.text('Chọn ví'));
        await tester.pumpAndSettle();

        // Sheet chỉ liệt kê ví đích hợp lệ.
        expect(find.text('Chọn ví đến'), findsOneWidget);
        // 'Tiền mặt' vừa là tên ví vừa là nhãn loại của chính nó → findsWidgets.
        expect(find.text('Tiền mặt'), findsWidgets);
        expect(find.text('Momo'), findsOneWidget);
        // Không chứa ví nguồn (chỉ 1 chỗ — card nguồn phía sau), không thẻ tín
        // dụng VIB, không ví ẩn.
        expect(find.text('Vietcombank'), findsOneWidget);
        expect(find.text('Thẻ tín dụng VIB'), findsNothing);
        expect(find.text('Sổ tiết kiệm'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('(c) chọn Momo → ô hiển thị; hoán đổi → nguồn/đích đổi chỗ', (
      tester,
    ) async {
      final c = await _register();
      await _open(tester, c, _vcb, size: const Size(800, 2000));

      await _pickDest(tester, 'Momo');
      expect(find.text('Momo'), findsOneWidget);
      expect(find.text('Số dư: 1.450.000 đ'), findsOneWidget);

      // Hoán đổi → nguồn Momo, đích Vietcombank, số dư đổi theo.
      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
      expect(find.text('Momo'), findsOneWidget); // giờ là nguồn
      expect(find.text('Vietcombank'), findsOneWidget); // giờ là đích
      expect(find.text('Số dư: 14.800.000 đ'), findsOneWidget);
      expect(find.text('Số dư: 1.450.000 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '(d) nhập 2.000.000 → phân tách nghìn + preview đúng (acceptance 4, SC-002)',
      (tester) async {
        final c = await _register();
        await _open(tester, c, _vcb, size: const Size(800, 2000));

        await _pickDest(tester, 'Momo');
        await _enterAmount(tester, '2000000');

        // Số tiền nhập hiển thị dạng phân tách nghìn (FR-005) + preview đúng.
        expect(find.text('2.000.000'), findsOneWidget);
        expect(find.text('12.800.000 đ / 3.450.000 đ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('(e) Xác nhận khi tiền trống/0 → chặn + lỗi tại trường, không gọi transfer', (
      tester,
    ) async {
      final (c, repo) = await _registerCounting();
      await _open(tester, c, _vcb, size: const Size(800, 2000));
      await _pickDest(tester, 'Momo');

      // Tiền trống → chạm Xác nhận → lỗi tại trường, không ghi.
      await tester.tap(find.text('Xác nhận chuyển tiền'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập số tiền lớn hơn 0'), findsOneWidget);
      expect(repo.transferCalls, 0);

      // Tiền = 0 vẫn chặn.
      await _enterAmount(tester, '0');
      await tester.tap(find.text('Xác nhận chuyển tiền'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập số tiền lớn hơn 0'), findsOneWidget);
      expect(repo.transferCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(f) chuyển vượt số dư nguồn → preview âm + cảnh báo mềm, vẫn bấm', (
      tester,
    ) async {
      final c = await _register(
        seed: const [_cashLow, _vcb, _creditVib, _momo, _savingsHidden],
      );
      await _open(tester, c, _cashLow, size: const Size(800, 2000));

      expect(find.text('Số dư: 500.000 đ'), findsOneWidget);
      await _pickDest(tester, 'Momo');
      await _enterAmount(tester, '1000000');

      // Nguồn 500.000 − 1.000.000 = −500.000 → cảnh báo mềm, không chặn.
      expect(find.text('-500.000 đ / 2.450.000 đ'), findsOneWidget);
      expect(find.text('Số dư sau chuyển sẽ âm'), findsOneWidget);
      expect(_confirmButton(tester).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(g) chạm Xác nhận 2 lần nhanh → đúng 1 lần gọi transfer (SC-006)', (
      tester,
    ) async {
      final (c, repo) = await _registerCounting();
      await _open(tester, c, _vcb, size: const Size(800, 2000));
      await _pickDest(tester, 'Momo');
      await _enterAmount(tester, '2000000');

      await tester.tap(find.text('Xác nhận chuyển tiền'));
      await tester.tap(find.text('Xác nhận chuyển tiền'));
      await tester.pumpAndSettle();

      expect(repo.transferCalls, 1);
      expect(find.byType(WalletTransferScreen), findsNothing); // đã pop
      expect(tester.takeException(), isNull);
    });

    testWidgets('(h) back chưa xác nhận → pop, không tạo khoản chuyển', (
      tester,
    ) async {
      final (c, repo) = await _registerCounting();
      await _open(tester, c, _vcb, size: const Size(800, 2000));
      await _pickDest(tester, 'Momo');
      await _enterAmount(tester, '2000000');
      await tester.enterText(
        find.byKey(const ValueKey('note-field')),
        'Nạp tiền ví điện tử',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(WalletTransferScreen), findsNothing);
      expect(repo.transferCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(i) cỡ chữ 2.0 + vùng an toàn → cuộn tới nút, không overflow', (
      tester,
    ) async {
      final c = await _register();
      await _open(
        tester,
        c,
        _vcb,
        size: const Size(360, 640),
        textScale: 2.0,
        safe: const EdgeInsets.only(bottom: 34),
      );
      expect(tester.takeException(), isNull);

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
      }
      expect(find.text('Xác nhận chuyển tiền'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
