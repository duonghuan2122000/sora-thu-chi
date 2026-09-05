import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/widgets/amount_keypad.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/add_transaction_screen.dart';
import 'package:sora_thu_chi/screens/wallet_transfer_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';

import 'fakes/fake_wallet_repository.dart';

/// Ngữ cảnh một test màn thêm: repo fake + kết quả pop của màn.
class _Ctx {
  _Ctx(this.repo);
  final FakeWalletRepository repo;
  bool? result;
}

/// Pump màn thêm đẩy lên từ một host (bắt kết quả pop qua [ctx.result]).
Future<_Ctx> _pumpAdd(
  WidgetTester tester, {
  List<Wallet>? seedWallets,
}) async {
  Get.reset();
  final repo = FakeWalletRepository(seedWallets);
  Get.put<WalletRepository>(repo);
  addTearDown(Get.reset);
  final ctx = _Ctx(repo);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                ctx.result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(repository: repo),
                  ),
                );
              },
              child: const Text('open-add'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open-add'));
  await tester.pumpAndSettle();
  return ctx;
}

Future<void> tapDigits(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.text(d));
    await tester.pump();
  }
}

Color _amountAccent(WidgetTester tester) {
  final c = tester.widget<Container>(
    find.byKey(const ValueKey('amount-underline')),
  );
  return (c.decoration! as BoxDecoration).color!;
}

/// Màn ảo cao (logical 360x1000) — đủ hiện mọi dòng trường + nút lưu không cần
/// cuộn; test về cỡ chữ nhỏ tự đặt lại (xem case (l)).
void useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(720, 2000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('AddTransactionScreen — màn thêm giao dịch (mockup 02, R7)', () {
    testWidgets('(a) bố cục mockup: title, X/check, segmented Chi, 4 trường + numpad + Lưu',
        (tester) async {
      useTallView(tester);
      await _pumpAdd(tester);

      expect(find.text('Thêm giao dịch'), findsOneWidget);
      expect(find.byKey(const ValueKey('close-add')), findsOneWidget);
      expect(find.byKey(const ValueKey('save-check')), findsOneWidget);
      for (final label in ['Chi', 'Thu', 'Chuyển khoản']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('0 đ'), findsOneWidget);
      for (final label in ['Danh mục', 'Ví', 'Ngày giờ', 'Ghi chú']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byType(AmountKeypad), findsOneWidget);
      expect(find.text('Lưu giao dịch'), findsOneWidget);
      // Không có bottom nav shell.
      expect(find.text('Tổng quan'), findsNothing);
    });

    testWidgets('(b) numpad 1250000 → 1.250.000 đ; backspace; phím "," no-op; Thu → teal',
        (tester) async {
      useTallView(tester);
      await _pumpAdd(tester);

      await tapDigits(tester, '1250000');
      expect(find.text('1.250.000 đ'), findsOneWidget);
      // Accent chi = coral.
      expect(_amountAccent(tester), AppColors.coral);

      // Phím "," (VND số nguyên) no-op.
      await tester.tap(find.text(','));
      await tester.pump();
      expect(find.text('1.250.000 đ'), findsOneWidget);

      // Backspace xóa một số.
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(find.text('125.000 đ'), findsOneWidget);

      // Đổi Thu → accent teal.
      await tester.tap(find.text('Thu'));
      await tester.pump();
      expect(_amountAccent(tester), AppColors.teal);
    });

    testWidgets('(c) chọn danh mục: chỉ chi khi ở Chi; chọn con Ăn ngoài → field hiện tên',
        (tester) async {
      await _pumpAdd(tester);

      await tester.tap(find.byKey(const ValueKey('field-category')));
      await tester.pumpAndSettle();

      expect(find.text('Chọn danh mục'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Lương'), findsNothing); // danh mục thu không hiện khi Chi.

      await tester.tap(find.text('Ăn uống'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ăn ngoài'));
      await tester.pumpAndSettle();

      expect(find.text('Chọn danh mục'), findsNothing); // đã quay về màn thêm.
      expect(find.text('Ăn ngoài'), findsOneWidget);
    });

    testWidgets('(d) chọn ví + ngày giờ + ghi chú', (tester) async {
      useTallView(tester);
      await _pumpAdd(tester);

      // Ví mặc định (Tiền mặt) nạp sẵn.
      expect(find.text('Tiền mặt'), findsOneWidget);
      // Mở sheet đổi sang Momo.
      await tester.tap(find.byKey(const ValueKey('field-wallet')));
      await tester.pumpAndSettle();
      expect(find.text('Chọn ví'), findsOneWidget);
      expect(find.text('Sổ tiết kiệm'), findsNothing); // ví ẩn không xuất hiện.
      await tester.tap(find.text('Momo'));
      await tester.pumpAndSettle();
      expect(find.text('Momo'), findsOneWidget);

      // Ngày giờ: mặc định hiện; chạm mở date picker rồi dismiss (giữ mặc định).
      final dateFinder = find.textContaining('·');
      expect(dateFinder, findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('field-datetime')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tapAt(const Offset(4, 4)); // dismiss qua barrier → giữ nguyên.
      await tester.pumpAndSettle();
      expect(dateFinder, findsOneWidget);

      // Ghi chú nhập được.
      await tester.enterText(find.byKey(const ValueKey('note-field')), 'Ăn trưa cùng team');
      expect(find.text('Ăn trưa cùng team'), findsOneWidget);
    });

    testWidgets('(e) đủ dữ liệu + Lưu → pop(true) và ghi đúng 1 dòng', (tester) async {
      useTallView(tester);
      final ctx = await _pumpAdd(tester);

      await tapDigits(tester, '50000');
      await tester.tap(find.byKey(const ValueKey('field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ăn uống'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ăn ngoài'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('note-field')), 'Tiền ăn trưa');
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('save-transaction')));
      await tester.pumpAndSettle();

      expect(ctx.result, isTrue);
      final added = (await ctx.repo.allTransactions())
          .where((t) => t.note == 'Tiền ăn trưa')
          .toList();
      expect(added.length, 1);
      final t = added.first;
      expect(t.type, TxnType.expense);
      expect(t.amount, -50000);
      expect(t.category, 'Ăn ngoài');
      expect(t.categoryId, isNotNull);
      expect(t.walletId, 1); // ví mặc định Tiền mặt.
      // Balance ví Tiền mặt giảm 50.000.
      final cash = (await ctx.repo.loadAll()).firstWhere((w) => w.id == 1);
      expect(cash.balance, 3150000);
    });

    testWidgets('(f) thiếu trường → báo caption tại đúng trường, không tạo dòng', (tester) async {
      final ctx = await _pumpAdd(tester);

      await tester.tap(find.byKey(const ValueKey('save-transaction')));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập số tiền lớn hơn 0'), findsOneWidget);
      expect(find.text('Chưa chọn danh mục'), findsOneWidget);
      // Ví + ngày giờ đã có (mặc định) → không báo lỗi.
      expect(find.text('Chưa chọn ví'), findsNothing);
      expect(find.text('Chưa chọn ngày giờ'), findsNothing);
      expect((await ctx.repo.allTransactions()).length, 11); // không tạo dòng.
    });

    testWidgets('(g) X khi dirty → dialog; Thoát → rời không tạo; Hủy → ở lại; sạch → thoát thẳng',
        (tester) async {
      // Dirty: gõ tiền rồi X.
      var ctx = await _pumpAdd(tester);
      await tapDigits(tester, '1000');
      await tester.tap(find.byKey(const ValueKey('close-add')));
      await tester.pumpAndSettle();

      expect(find.text('Hủy giao dịch?'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Thêm giao dịch'), findsOneWidget); // ở lại, dữ liệu giữ.
      expect(find.text('1.000 đ'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('close-add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thoát'));
      await tester.pumpAndSettle();
      expect(ctx.result, isNull); // pop không kèm true — không báo đã lưu.
      expect((await ctx.repo.allTransactions()).length, 11);

      // Sạch (mở mới) → X thoát thẳng, không dialog.
      ctx = await _pumpAdd(tester);
      await tester.tap(find.byKey(const ValueKey('close-add')));
      await tester.pumpAndSettle();
      expect(find.text('Hủy giao dịch?'), findsNothing);
      expect(ctx.result, isNull);
    });

    testWidgets('(h) Lưu 2 lần nhanh → chỉ 1 giao dịch (cờ _saving)', (tester) async {
      final ctx = await _pumpAdd(tester);

      await tapDigits(tester, '20000');
      await tester.tap(find.byKey(const ValueKey('field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhà ở'));
      await tester.pumpAndSettle();

      final save = find.byKey(const ValueKey('save-transaction'));
      await tester.tap(save);
      // Tap lần 2 ngay (trước khi rebuild) — cờ _saving phải chặn tạo trùng.
      await tester.tap(save, warnIfMissed: false);
      await tester.pumpAndSettle();

      final added = (await ctx.repo.allTransactions())
          .where((t) => t.category == 'Nhà ở' && t.amount == -20000)
          .toList();
      expect(added.length, 1);
    });

    testWidgets('(i) tab Chuyển khoản mở luồng PBI 8', (tester) async {
      await _pumpAdd(tester);

      await tester.tap(find.text('Chuyển khoản'));
      await tester.pumpAndSettle();

      expect(find.byType(WalletTransferScreen), findsOneWidget);
      expect(find.text('Chuyển tiền giữa ví'), findsOneWidget);
    });

    testWidgets('(j) 0 ví hoạt động → thông báo chặn Lưu, X thoát được', (tester) async {
      final ctx = await _pumpAdd(
        tester,
        seedWallets: [
          Wallet(
            id: 1,
            name: 'Ví ẩn',
            type: WalletType.cash,
            balance: 100000,
            isHidden: true,
          ),
        ],
      );

      expect(find.textContaining('Chưa có ví hoạt động'), findsOneWidget);
      // Lưu bị chặn (nút vô hiệu) — chạm không tạo dòng.
      await tester.tap(find.byKey(const ValueKey('save-transaction')));
      await tester.pumpAndSettle();
      expect((await ctx.repo.allTransactions()).length, 11);
      // Vẫn thoát được bằng X.
      await tester.tap(find.byKey(const ValueKey('close-add')));
      await tester.pumpAndSettle();
      expect(find.text('Thêm giao dịch'), findsNothing);
    });

    testWidgets('(k) 1 ví hoạt động → nạp sẵn, không cần mở sheet', (tester) async {
      final ctx = await _pumpAdd(
        tester,
        seedWallets: [
          Wallet(id: 1, name: 'Tiền mặt', type: WalletType.cash, balance: 1000000, isDefault: true),
        ],
      );

      expect(find.text('Tiền mặt'), findsOneWidget);
      // Không có ví khác để mở sheet.
      await tester.tap(find.byKey(const ValueKey('field-wallet')));
      await tester.pumpAndSettle();
      expect(find.text('Chọn ví'), findsNothing);
      expect(find.text('Thêm giao dịch'), findsOneWidget);
      expect(ctx.result, isNull);
    });

    testWidgets('(l) cỡ chữ lớn + màn thấp: cuộn tới ghi chú, không overflow', (tester) async {
      tester.view.physicalSize = const Size(720, 1400); // logical 360x700 @2x.
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await _pumpAdd(tester);
      expect(tester.takeException(), isNull);

      // Cuộn xuống tới dòng Ghi chú — mọi thứ cuộn được, nút Lưu cố định.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('note-field')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Lưu giao dịch'), findsOneWidget);
    });
  });
}
