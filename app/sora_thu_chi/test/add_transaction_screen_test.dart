import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/scan/scan_image_store.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
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

/// [ScanImageStore] giả cho test — không đụng file thật, ghi lại đường dẫn đã
/// lưu/xóa để assert hành vi dọn rác (PBI 38).
class _FakeImageStore implements ScanImageStore {
  final List<String> saved = [];
  final List<String> deleted = [];
  var _next = 0;

  @override
  Future<String> save(Uint8List bytes) async {
    final path = '/fake/receipts/${_next++}.jpg';
    saved.add(path);
    return path;
  }

  @override
  Future<void> delete(String path) async {
    deleted.add(path);
  }
}

/// Pump màn thêm đẩy lên từ một host (bắt kết quả pop qua [ctx.result]).
/// [pickImage]/[imageStore] (PBI 38): seam Ảnh hóa đơn — mặc định null dùng
/// hành vi thật (không cần trong test không đụng ảnh).
Future<_Ctx> _pumpAdd(
  WidgetTester tester, {
  List<Wallet>? seedWallets,
  ReceiptImagePicker? pickImage,
  ScanImageStore? imageStore,
  Transaction? editing,
  Category? initialCategory,
  Wallet? initialWallet,
  FakeWalletRepository? repo,
}) async {
  Get.reset();
  repo ??= FakeWalletRepository(seedWallets);
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
                    builder: (_) => AddTransactionScreen(
                      repository: repo,
                      pickImage: pickImage,
                      imageStore: imageStore,
                      editing: editing,
                      initialCategory: initialCategory,
                      initialWallet: initialWallet,
                    ),
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

/// Gõ số tiền qua bàn phím hệ thống (mô phỏng bằng `enterText` trên ô
/// `amount-field`) — thay `tapDigits` numpad cũ (PBI 38: bỏ `AmountKeypad`
/// khỏi màn này, dùng `TextField` số hệ thống như `wallet_transfer_screen`).
Future<void> enterAmount(WidgetTester tester, String digits) async {
  await tester.enterText(find.byKey(const ValueKey('amount-field')), digits);
  await tester.pump();
}

Color _amountAccent(WidgetTester tester) {
  final field = tester.widget<TextField>(
    find.byKey(const ValueKey('amount-field')),
  );
  final border = field.decoration!.enabledBorder! as OutlineInputBorder;
  return border.borderSide.color;
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
    testWidgets('(a) bố cục mockup: title, X/check, segmented Chi, 4 trường + ô số tiền hệ thống + Lưu',
        (tester) async {
      useTallView(tester);
      await _pumpAdd(tester);

      expect(find.text('Thêm giao dịch'), findsOneWidget);
      expect(find.byKey(const ValueKey('close-add')), findsOneWidget);
      expect(find.byKey(const ValueKey('save-check')), findsOneWidget);
      for (final label in ['Chi', 'Thu', 'Chuyển khoản']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('amount-field')), findsOneWidget);
      for (final label in ['Danh mục', 'Ví', 'Ngày giờ', 'Ghi chú']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Lưu giao dịch'), findsOneWidget);
      // Không có bottom nav shell.
      expect(find.text('Tổng quan'), findsNothing);
    });

    testWidgets('(b) gõ 1250000 → 1.250.000 (bàn phím hệ thống); sửa lại còn 125000; Thu → teal',
        (tester) async {
      useTallView(tester);
      await _pumpAdd(tester);

      await enterAmount(tester, '1250000');
      expect(find.text('1.250.000'), findsOneWidget);
      // Accent chi = coral.
      expect(_amountAccent(tester), AppColors.coral);

      // Sửa lại còn 125000 (mô phỏng backspace của bàn phím hệ thống).
      await enterAmount(tester, '125000');
      expect(find.text('125.000'), findsOneWidget);

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

      await enterAmount(tester, '50000');
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
      await enterAmount(tester, '1000');
      await tester.tap(find.byKey(const ValueKey('close-add')));
      await tester.pumpAndSettle();

      expect(find.text('Hủy giao dịch?'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Thêm giao dịch'), findsOneWidget); // ở lại, dữ liệu giữ.
      expect(find.text('1.000'), findsOneWidget);

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

      await enterAmount(tester, '20000');
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

    testWidgets('(m) chạm dòng Tag → chọn/tạo tag → hiện lại trên dòng, lưu mang đúng tag (PBI 38)',
        (tester) async {
      useTallView(tester);
      final ctx = await _pumpAdd(tester);

      await tester.tap(find.byKey(const ValueKey('field-tags')));
      await tester.pumpAndSettle();
      expect(find.text('Chọn tag'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('new-tag-field')), 'ăn trưa');
      await tester.tap(find.byKey(const ValueKey('add-tag-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-tags')));
      await tester.pumpAndSettle();

      expect(find.text('Chọn tag'), findsNothing); // đã quay về màn thêm.
      expect(find.text('ăn trưa'), findsOneWidget); // hiện trên dòng Tag.

      await enterAmount(tester, '30000');
      await tester.tap(find.byKey(const ValueKey('field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhà ở'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-transaction')));
      await tester.pumpAndSettle();

      expect(ctx.result, isTrue);
      final added = (await ctx.repo.allTransactions())
          .where((t) => t.category == 'Nhà ở' && t.amount == -30000)
          .toList();
      expect(added.single.tags, 'ăn trưa');
    });

    testWidgets('(n) không chọn Tag → vẫn lưu được bình thường (trường tùy chọn, FR-009)',
        (tester) async {
      final ctx = await _pumpAdd(tester);

      await enterAmount(tester, '15000');
      await tester.tap(find.byKey(const ValueKey('field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhà ở'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-transaction')));
      await tester.pumpAndSettle();

      expect(ctx.result, isTrue);
      final added = (await ctx.repo.allTransactions())
          .where((t) => t.category == 'Nhà ở' && t.amount == -15000)
          .toList();
      expect(added.single.tags, '');
    });

    testWidgets('(o) đính kèm ảnh hóa đơn (chụp ảnh) → thumbnail hiện, lưu mang đúng đường dẫn (PBI 38)',
        (tester) async {
      useTallView(tester);
      final store = _FakeImageStore();
      final ctx = await _pumpAdd(
        tester,
        imageStore: store,
        pickImage: (source) async {
          expect(source, ImageSource.camera);
          return XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'hoadon.jpg');
        },
      );

      await tester.tap(find.byKey(const ValueKey('field-receipt-image')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('receipt-source-camera')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('receipt-image-thumbnail')), findsOneWidget);
      expect(store.saved, ['/fake/receipts/0.jpg']);

      await enterAmount(tester, '40000');
      await tester.tap(find.byKey(const ValueKey('field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhà ở'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-transaction')));
      await tester.pumpAndSettle();

      expect(ctx.result, isTrue);
      final added = (await ctx.repo.allTransactions())
          .where((t) => t.category == 'Nhà ở' && t.amount == -40000)
          .toList();
      expect(added.single.receiptImage, '/fake/receipts/0.jpg');
      // Đã gắn vào giao dịch — không bị xóa.
      expect(store.deleted, isEmpty);
    });

    testWidgets('(p) không đính kèm ảnh → vẫn lưu bình thường (trường tùy chọn, FR-009)',
        (tester) async {
      final ctx = await _pumpAdd(tester);

      await enterAmount(tester, '18000');
      await tester.tap(find.byKey(const ValueKey('field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhà ở'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-transaction')));
      await tester.pumpAndSettle();

      expect(ctx.result, isTrue);
      final added = (await ctx.repo.allTransactions())
          .where((t) => t.category == 'Nhà ở' && t.amount == -18000)
          .toList();
      expect(added.single.receiptImage, '');
    });

    testWidgets('(q) đính kèm ảnh rồi thoát không lưu → file bị xóa, không để rác (PBI 38)',
        (tester) async {
      final store = _FakeImageStore();
      await _pumpAdd(
        tester,
        imageStore: store,
        pickImage: (source) async =>
            XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'hoadon.jpg'),
      );

      await tester.tap(find.byKey(const ValueKey('field-receipt-image')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('receipt-source-gallery')));
      await tester.pumpAndSettle();
      expect(store.saved, ['/fake/receipts/0.jpg']);

      // Đã đính kèm ảnh → coi là dirty, X hiện dialog xác nhận.
      await tester.tap(find.byKey(const ValueKey('close-add')));
      await tester.pumpAndSettle();
      expect(find.text('Hủy giao dịch?'), findsOneWidget);
      await tester.tap(find.text('Thoát'));
      await tester.pumpAndSettle();

      expect(store.deleted, ['/fake/receipts/0.jpg']);
    });
  });

  group('AddTransactionScreen — chế độ sửa (PBI 39)', () {
    /// Chuẩn bị 1 ví + 1 giao dịch Chi đã lưu trong repo; trả về repo + giao
    /// dịch + danh mục/ví gốc để bơm màn ở chế độ sửa.
    Future<
      ({
        FakeWalletRepository repo,
        Transaction original,
        Category category,
        Wallet wallet,
      })
    >
    seedExisting() async {
      final wallet = Wallet(id: 1, name: 'Tiền mặt', type: WalletType.cash, balance: 1000000);
      // Danh sách giao dịch rỗng tường minh — seed mặc định (11 dòng mẫu) sẽ
      // đụng `walletId`/id và làm `.single` bên dưới ném lỗi "Too many elements".
      final repo = FakeWalletRepository([wallet], null, []);
      final category = (await repo.categories(type: CategoryType.expense))
          .firstWhere((c) => c.name == 'Nhà ở');
      await repo.addTransaction(
        walletId: wallet.id,
        type: TxnType.expense,
        amount: 50000,
        category: category,
        date: DateTime(2026, 9, 1, 12, 0),
        note: 'Tiền điện',
      );
      final original = (await repo.transactionsOf(wallet.id)).single;
      return (repo: repo, original: original, category: category, wallet: wallet);
    }

    testWidgets('mở màn: tiêu đề "Sửa giao dịch", điền sẵn đúng dữ liệu gốc',
        (tester) async {
      useTallView(tester);
      final seed = await seedExisting();
      await _pumpAdd(
        tester,
        repo: seed.repo,
        editing: seed.original,
        initialCategory: seed.category,
        initialWallet: seed.wallet,
      );

      expect(find.text('Sửa giao dịch'), findsOneWidget);
      expect(find.text('Thêm giao dịch'), findsNothing);
      expect(
        tester.widget<TextField>(find.byKey(const ValueKey('amount-field'))).controller!.text,
        '50.000',
      );
      expect(find.text('Nhà ở'), findsOneWidget);
      expect(find.text('Tiền mặt'), findsOneWidget);
      final noteField = tester.widget<TextField>(find.byKey(const ValueKey('note-field')));
      expect(noteField.controller!.text, 'Tiền điện');
    });

    testWidgets('tab "Chuyển khoản" bị khóa ở chế độ sửa (R4)', (tester) async {
      final seed = await seedExisting();
      await _pumpAdd(
        tester,
        repo: seed.repo,
        editing: seed.original,
        initialCategory: seed.category,
        initialWallet: seed.wallet,
      );

      final segment = tester.widget<GestureDetector>(find.ancestor(
        of: find.text('Chuyển khoản'),
        matching: find.byType(GestureDetector),
      ));
      expect(segment.onTap, isNull);
    });

    testWidgets('đổi số tiền + ghi chú rồi Lưu → gọi updateTransaction đúng, không tạo dòng mới',
        (tester) async {
      final seed = await seedExisting();
      final ctx = await _pumpAdd(
        tester,
        repo: seed.repo,
        editing: seed.original,
        initialCategory: seed.category,
        initialWallet: seed.wallet,
      );

      await enterAmount(tester, '80000');
      await tester.enterText(find.byKey(const ValueKey('note-field')), 'Tiền điện tháng 9');
      await tester.tap(find.byKey(const ValueKey('save-transaction')));
      await tester.pumpAndSettle();

      expect(ctx.result, isTrue);
      final all = await seed.repo.allTransactions();
      expect(all.length, 1, reason: 'sửa không tạo thêm dòng mới');
      final updated = all.single;
      expect(updated.id, seed.original.id);
      expect(updated.amount, -80000);
      expect(updated.note, 'Tiền điện tháng 9');
      final wallets = await seed.repo.loadAll();
      // 1.000.000 − 50.000 (cũ) + −30.000 (đổi thêm) = 920.000.
      expect(wallets.firstWhere((w) => w.id == seed.wallet.id).balance, 920000);
    });

    testWidgets('đổi loại Chi → Thu rồi Lưu → lưu đúng loại/danh mục mới',
        (tester) async {
      final seed = await seedExisting();
      final ctx = await _pumpAdd(
        tester,
        repo: seed.repo,
        editing: seed.original,
        initialCategory: seed.category,
        initialWallet: seed.wallet,
      );

      await tester.tap(find.text('Thu'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('field-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lương'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('save-transaction')));
      await tester.pumpAndSettle();

      expect(ctx.result, isTrue);
      final updated = (await seed.repo.allTransactions()).single;
      expect(updated.type, TxnType.income);
      expect(updated.amount, 50000);
      expect(updated.category, 'Lương');
    });

    testWidgets('bỏ trống số tiền rồi Lưu → báo thiếu trường, giữ nguyên bản gốc',
        (tester) async {
      final seed = await seedExisting();
      final ctx = await _pumpAdd(
        tester,
        repo: seed.repo,
        editing: seed.original,
        initialCategory: seed.category,
        initialWallet: seed.wallet,
      );

      await enterAmount(tester, '');
      await tester.tap(find.byKey(const ValueKey('save-transaction')));
      await tester.pumpAndSettle();

      expect(ctx.result, isNull);
      expect(find.text('Vui lòng nhập số tiền lớn hơn 0'), findsOneWidget);
      final unchanged = (await seed.repo.allTransactions()).single;
      expect(unchanged.amount, -50000);
    });

    testWidgets('đổi 1 trường rồi bấm đóng → hộp thoại xác nhận xuất hiện',
        (tester) async {
      final seed = await seedExisting();
      await _pumpAdd(
        tester,
        repo: seed.repo,
        editing: seed.original,
        initialCategory: seed.category,
        initialWallet: seed.wallet,
      );

      await enterAmount(tester, '80000');
      await tester.tap(find.byKey(const ValueKey('close-add')));
      await tester.pumpAndSettle();

      expect(find.text('Hủy giao dịch?'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      // Chọn "Hủy" ở hộp thoại → ở lại màn sửa, dữ liệu vừa đổi còn nguyên.
      expect(find.text('Sửa giao dịch'), findsOneWidget);
    });
  });
}
