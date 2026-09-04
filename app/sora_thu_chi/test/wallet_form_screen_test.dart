import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_controller.dart';
import 'package:sora_thu_chi/screens/wallet_form_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

const _cashDefault = Wallet(
  id: 1,
  name: 'Tiền mặt',
  type: WalletType.cash,
  icon: '💵',
  initialBalance: 3200000,
  balance: 3200000,
  isDefault: true,
  sortOrder: 1,
);
const _newCash = Wallet(
  id: 6,
  name: 'Tiền mặt mới',
  type: WalletType.cash,
  icon: '💵',
  initialBalance: 1000000,
  balance: 1000000,
  sortOrder: 2,
);
const _credit = Wallet(
  id: 3,
  name: 'Thẻ tín dụng VIB',
  type: WalletType.credit,
  icon: '💳',
  initialBalance: 0,
  balance: 0,
  sortOrder: 3,
  creditLimit: 20000000,
  creditUsed: 6500000,
);

/// Đăng ký controller + fake repo (seed mặc định hoặc [wallets]); trả controller.
Future<WalletController> _register({List<Wallet>? wallets}) async {
  Get.reset();
  final c = WalletController(FakeWalletRepository(wallets));
  Get.put(c);
  await c.init();
  addTearDown(Get.reset);
  return c;
}

/// Mở form (thêm hoặc sửa) qua route đẩy — để `pop` hoạt động được.
Future<void> _open(
  WidgetTester tester,
  WalletController controller, {
  Wallet? wallet,
  bool hasTransactions = false,
  Size? size,
  double textScale = 1.0,
}) async {
  if (size != null) {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  if (textScale != 1.0) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WalletFormScreen(
                    wallet: wallet,
                    hasTransactions: hasTransactions,
                    controller: controller,
                  ),
                ),
              ),
              child: const Text('MỞ FORM'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('MỞ FORM'));
  await tester.pumpAndSettle();
}

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Lấy ví trong cache controller theo tên.
Wallet _byName(WalletController c, String name) =>
    c.wallets.firstWhere((w) => w.name == name);

void main() {
  group('WalletFormScreen — chế độ THÊM', () {
    testWidgets('(a) title "Thêm ví mới", đủ khối, nút Lưu, không bottom nav', (
      tester,
    ) async {
      final c = await _register();
      await _open(tester, c, size: const Size(800, 2400));

      expect(find.text('Thêm ví mới'), findsWidgets); // app bar
      for (final chip in [
        'Tiền mặt',
        'Ngân hàng',
        'Thẻ tín dụng',
        'Ví điện tử',
        'Sổ tiết kiệm',
      ]) {
        expect(find.text(chip), findsOneWidget);
      }
      expect(find.text('Tên ví'), findsOneWidget);
      expect(find.text('Số dư ban đầu'), findsOneWidget);
      expect(find.text('Tiền tệ: VND'), findsOneWidget);
      expect(find.text('Biểu tượng & màu sắc'), findsOneWidget);
      expect(find.text('Đặt làm ví mặc định'), findsOneWidget);
      expect(find.text('Lưu ví'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(b) 5 loại → trường riêng đúng loại (FR-003)', (tester) async {
      final c = await _register();
      await _open(tester, c, size: const Size(800, 2400));

      // Cash mặc định: không trường riêng.
      expect(find.text('Hạn mức tín dụng'), findsNothing);
      expect(find.text('Kỳ hạn (tháng, tùy chọn)'), findsNothing);
      expect(find.text('Ngân hàng (tùy chọn)'), findsNothing);

      await _tapChip(tester, 'Thẻ tín dụng');
      expect(find.text('Hạn mức tín dụng'), findsOneWidget);
      expect(find.text('Ngày sao kê (tùy chọn)'), findsOneWidget);
      expect(find.text('Ngày đến hạn (tùy chọn)'), findsOneWidget);

      await _tapChip(tester, 'Sổ tiết kiệm');
      expect(find.text('Kỳ hạn (tháng, tùy chọn)'), findsOneWidget);
      expect(find.text('Ngày đáo hạn (tùy chọn)'), findsOneWidget);
      expect(find.text('Hạn mức tín dụng'), findsNothing);

      await _tapChip(tester, 'Ngân hàng');
      expect(find.text('Ngân hàng (tùy chọn)'), findsOneWidget);
      expect(find.text('Số cuối tài khoản (tùy chọn)'), findsOneWidget);

      await _tapChip(tester, 'Ví điện tử');
      expect(find.text('Tổ chức (tùy chọn)'), findsOneWidget);
      expect(find.text('Số cuối tài khoản (tùy chọn)'), findsOneWidget);

      await _tapChip(tester, 'Tiền mặt');
      expect(find.text('Hạn mức tín dụng'), findsNothing);
      expect(find.text('Kỳ hạn (tháng, tùy chọn)'), findsNothing);
      expect(find.text('Tổ chức (tùy chọn)'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(c) đổi chip giữa lúc nhập → trường loại cũ mất, không lưu giá trị cũ', (
      tester,
    ) async {
      final c = await _register();
      await _open(tester, c, size: const Size(800, 2400));

      await tester.enterText(find.byKey(const ValueKey('field-name')), 'Thẻ mới');
      await tester.enterText(find.byKey(const ValueKey('field-balance')), '500000');
      await _tapChip(tester, 'Thẻ tín dụng');
      await tester.enterText(
        find.byKey(const ValueKey('field-credit-limit')),
        '20000000',
      );

      // Đổi sang cash → hạn mức biến mất, lưu được ví cash không kèm creditLimit.
      await _tapChip(tester, 'Tiền mặt');
      expect(find.text('Hạn mức tín dụng'), findsNothing);

      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();
      expect(find.byType(WalletFormScreen), findsNothing); // đã pop

      final saved = _byName(c, 'Thẻ mới');
      expect(saved.type, WalletType.cash);
      expect(saved.creditLimit, isNull);
      expect(saved.balance, 500000);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(d) lưu thiếu tên/khoảng trắng/thiếu số dư → chặn, lỗi đúng trường', (
      tester,
    ) async {
      final c = await _register();
      await _open(tester, c, size: const Size(800, 2400));

      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập tên ví'), findsOneWidget);
      expect(find.text('Vui lòng nhập số dư ban đầu'), findsOneWidget);
      expect(find.byType(WalletFormScreen), findsOneWidget);
      expect(c.wallets.length, 5); // chưa tạo gì

      // Tên chỉ khoảng trắng vẫn chặn.
      await tester.enterText(find.byKey(const ValueKey('field-name')), '   ');
      await tester.enterText(find.byKey(const ValueKey('field-balance')), '1000');
      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập tên ví'), findsOneWidget);
      expect(c.wallets.length, 5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(e) số dư 0 hợp lệ → lưu được (acceptance edge)', (tester) async {
      final c = await _register();
      await _open(tester, c, size: const Size(800, 2400));

      await tester.enterText(find.byKey(const ValueKey('field-name')), 'Ví rỗng');
      await tester.enterText(find.byKey(const ValueKey('field-balance')), '0');
      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();

      expect(find.byType(WalletFormScreen), findsNothing);
      final saved = _byName(c, 'Ví rỗng');
      expect(saved.balance, 0);
      expect(saved.initialBalanceValue, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(f) hạn mức thẻ trống/0 → chặn tại trường; nhập 20000000 → lưu được', (
      tester,
    ) async {
      final c = await _register();
      await _open(tester, c, size: const Size(800, 2400));

      await tester.enterText(find.byKey(const ValueKey('field-name')), 'Thẻ mới');
      await tester.enterText(find.byKey(const ValueKey('field-balance')), '0');
      await _tapChip(tester, 'Thẻ tín dụng');

      // Hạn mức trống → chặn.
      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();
      expect(find.text('Hạn mức phải lớn hơn 0'), findsOneWidget);
      expect(c.wallets.length, 5);

      // Hạn mức 0 → chặn.
      await tester.enterText(
        find.byKey(const ValueKey('field-credit-limit')),
        '0',
      );
      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();
      expect(find.text('Hạn mức phải lớn hơn 0'), findsOneWidget);
      expect(c.wallets.length, 5);

      // Hạn mức hợp lệ → lưu được.
      await tester.enterText(
        find.byKey(const ValueKey('field-credit-limit')),
        '20000000',
      );
      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();
      expect(find.byType(WalletFormScreen), findsNothing);

      final saved = _byName(c, 'Thẻ mới');
      expect(saved.type, WalletType.credit);
      expect(saved.creditLimit, 20000000);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(g) back chưa lưu → pop, không tạo gì (acceptance 9)', (tester) async {
      final c = await _register();
      await _open(tester, c, size: const Size(800, 2400));

      await tester.enterText(find.byKey(const ValueKey('field-name')), 'Sẽ bỏ');
      await tester.enterText(find.byKey(const ValueKey('field-balance')), '1000');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(WalletFormScreen), findsNothing);
      expect(c.wallets.length, 5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(h) nhập đủ + Lưu → create qua controller + pop (acceptance 2)', (
      tester,
    ) async {
      final c = await _register();
      await _open(tester, c, size: const Size(800, 2400));

      await tester.enterText(
        find.byKey(const ValueKey('field-name')),
        'Quỹ chi tiêu hàng ngày',
      );
      await tester.enterText(find.byKey(const ValueKey('field-balance')), '3200000');
      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();

      expect(find.byType(WalletFormScreen), findsNothing);
      final saved = _byName(c, 'Quỹ chi tiêu hàng ngày');
      expect(saved.type, WalletType.cash);
      expect(saved.balance, 3200000);
      expect(saved.isHidden, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(i) cỡ chữ 2.0 + vùng an toàn → cuộn hết, không overflow, nút Lưu với tới', (
      tester,
    ) async {
      final c = await _register();
      await _open(
        tester,
        c,
        size: const Size(360, 640),
        textScale: 2.0,
      );

      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Lưu ví'), findsOneWidget);
    });
  });

  group('WalletFormScreen — chế độ SỬA', () {
    testWidgets('(a) title "Sửa ví" + mọi trường nạp đúng giá trị ví (acceptance 5)', (
      tester,
    ) async {
      final c = await _register();
      await _open(tester, c, wallet: _cashDefault, size: const Size(800, 2400));

      expect(find.text('Sửa ví'), findsWidgets); // app bar
      expect(
        tester.widget<TextFormField>(
          find.byKey(const ValueKey('field-name')),
        ).controller!.text,
        'Tiền mặt',
      );
      expect(find.text('Đặt làm ví mặc định'), findsOneWidget);
      // Switch thể hiện default của ví.
      expect(
        tester.widget<Switch>(find.byType(Switch)).value,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('(b) hasTransactions: Số dư/Tiền tệ/Loại khóa + ghi chú; sửa tên được', (
      tester,
    ) async {
      final c = await _register();
      await _open(
        tester,
        c,
        wallet: _cashDefault,
        hasTransactions: true,
        size: const Size(800, 2400),
      );

      // Khóa: không còn chip loại (thay bằng read-only) / ô nhập số dư; ghi chú.
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.textContaining('Ví đã có giao dịch nên không đổi được loại ví'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('field-balance')), findsNothing);
      expect(find.text('3.200.000 đ'), findsOneWidget); // số dư ban đầu read-only
      expect(find.text('Tiền tệ: VND'), findsOneWidget);

      // Vẫn sửa được tên/icon/màu.
      await tester.enterText(find.byKey(const ValueKey('field-name')), 'Tiền mặt 2');
      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();
      expect(find.byType(WalletFormScreen), findsNothing);
      expect(_byName(c, 'Tiền mặt 2').balance, 3200000); // số dư không đổi
      expect(tester.takeException(), isNull);
    });

    testWidgets('(b2) thẻ tín dụng đã giao dịch: type/balance khóa nhưng sửa được hạn mức', (
      tester,
    ) async {
      final c = await _register();
      await _open(tester, c, wallet: _credit, hasTransactions: true, size: const Size(800, 2400));

      expect(find.textContaining('Ví đã có giao dịch nên không đổi được loại ví'),
          findsOneWidget);
      // Hạn mức (trường riêng) vẫn sửa được.
      await tester.enterText(
        find.byKey(const ValueKey('field-credit-limit')),
        '25000000',
      );
      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();
      expect(find.byType(WalletFormScreen), findsNothing);
      final saved = _byName(c, 'Thẻ tín dụng VIB');
      expect(saved.creditLimit, 25000000);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(c) chưa giao dịch: đổi số dư ban đầu → ghi initial_balance=balance (acceptance 7)', (
      tester,
    ) async {
      final c = await _register(wallets: [_cashDefault, _newCash]);
      await _open(tester, c, wallet: _newCash, size: const Size(800, 2400));

      await tester.enterText(find.byKey(const ValueKey('field-balance')), '2000000');
      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();

      expect(find.byType(WalletFormScreen), findsNothing);
      final saved = _byName(c, 'Tiền mặt mới');
      expect(saved.balance, 2000000);
      expect(saved.initialBalanceValue, 2000000);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(d) đổi loại khi chưa giao dịch → trường riêng loại mới hiện', (
      tester,
    ) async {
      final c = await _register();
      await _open(tester, c, wallet: _cashDefault, size: const Size(800, 2400));

      await _tapChip(tester, 'Sổ tiết kiệm');
      expect(find.text('Kỳ hạn (tháng, tùy chọn)'), findsOneWidget);
      expect(find.text('Ngày đáo hạn (tùy chọn)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(e) default duy nhất → không tắt được cờ + giải thích', (tester) async {
      final c = await _register(wallets: [_cashDefault]);
      await _open(tester, c, wallet: _cashDefault, size: const Size(800, 2400));

      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      expect(
        find.textContaining('là ví mặc định duy nhất đang hoạt động nên không thể tắt'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('(f) lưu thất bại → báo lỗi, giữ dữ liệu đã nhập (FR-014)', (tester) async {
      // Repo ném lỗi khi update để giả lập lỗi lưu.
      final throwing = _ThrowingFakeWalletRepository([_cashDefault]);
      Get.reset();
      final c = WalletController(throwing);
      Get.put(c);
      await c.init();
      addTearDown(Get.reset);

      await _open(tester, c, wallet: _cashDefault, size: const Size(800, 2400));
      await tester.enterText(find.byKey(const ValueKey('field-name')), 'Tiền giữ lại');
      await tester.tap(find.text('Lưu ví'));
      await tester.pumpAndSettle();

      // Báo lỗi + form còn nguyên, dữ liệu giữ lại.
      expect(find.byType(WalletFormScreen), findsOneWidget);
      expect(find.text('Không lưu được ví. Vui lòng thử lại.'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(
          find.byKey(const ValueKey('field-name')),
        ).controller!.text,
        'Tiền giữ lại',
      );
      expect(tester.takeException(), isNull);
    });
  });
}

/// Fake repo ném lỗi ở `update` — kiểm FR-014.
class _ThrowingFakeWalletRepository extends FakeWalletRepository {
  _ThrowingFakeWalletRepository([super.seed]);

  @override
  Future<Wallet> update(Wallet wallet) async {
    throw Exception('lỗi lưu giả lập');
  }
}
