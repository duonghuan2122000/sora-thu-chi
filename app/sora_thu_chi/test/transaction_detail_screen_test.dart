import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_detail.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/transaction_detail_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/sora_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

/// Mở [screen] như một route đẩy lên trên màn host (có back button) — bơm seam
/// [loader] trực tiếp, không cần sqlite/fake repo.
Future<void> _open(
  WidgetTester tester,
  Widget screen, {
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
      home: _Host(screen: screen),
    ),
  );
  await tester.tap(find.text('mở chi tiết'));
  await tester.pumpAndSettle();
}

class _Host extends StatelessWidget {
  const _Host({required this.screen});

  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => screen),
          ),
          child: const Text('mở chi tiết'),
        ),
      ),
    );
  }
}

/// Dựng [TransactionDetailScreen] bơm seam loader trả sẵn [view].
Widget _screen(TransactionDetailView view) => TransactionDetailScreen(
  ref: const TransactionDetailRef(transactionId: 1),
  loader: () async => view,
);

/// Dựng [TransactionDetailScreen] với loader tùy biến (test lỗi/retry/null).
Widget _screenWith(Future<TransactionDetailView?> Function() loader) =>
    TransactionDetailScreen(
      ref: const TransactionDetailRef(transactionId: 1),
      loader: loader,
    );

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('TransactionDetailScreen — khối tóm tắt màu/dấu theo loại (SC-003)', () {
    testWidgets('(a) thu: bubble + tên + "+…" teal (acceptance 2)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final view = TransactionDetailView(
        type: TxnType.income,
        summaryTitle: 'Lương',
        summaryGlyph: Icons.payments,
        amount: 12000000,
        date: DateTime(2026, 9, 4, 9, 0),
        singleWalletName: 'Vietcombank',
      );
      await _open(tester, _screen(view));

      expect(find.text('Chi tiết giao dịch'), findsOneWidget);
      expect(find.text('Lương'), findsOneWidget);
      expect(find.byIcon(Icons.payments), findsOneWidget); // bubble glyph.
      expect(find.text('+12.000.000 đ'), findsOneWidget);
      expect(_textColor(tester, '+12.000.000 đ'), AppColors.teal);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(b) chi: "−" coral (acceptance 1)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final view = TransactionDetailView(
        type: TxnType.expense,
        summaryTitle: 'Ăn uống · Ăn ngoài',
        summaryGlyph: Icons.restaurant,
        amount: -85000,
        date: DateTime(2026, 9, 3, 12, 15),
        singleWalletName: 'Tiền mặt',
        note: 'Ăn trưa cùng đồng nghiệp',
        tags: const ['côngty'],
        receiptImage: '',
        location: '123 Láng Hạ, Đống Đa, Hà Nội',
      );
      await _open(tester, _screen(view));

      expect(find.text('Ăn uống · Ăn ngoài'), findsOneWidget); // cha·con.
      expect(find.text('-85.000 đ'), findsOneWidget);
      expect(_textColor(tester, '-85.000 đ'), AppColors.coral);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(c) transfer: trung tính không dấu + 2 hàng Ví nguồn/đích '
        '(acceptance 3, SC-005); adjustment cũng trung tính', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final transfer = TransactionDetailView(
        type: TxnType.transfer,
        summaryTitle: 'Chuyển khoản',
        summaryGlyph: Icons.swap_horiz,
        amount: 700000,
        date: DateTime(2026, 9, 2, 8, 0),
        sourceWalletName: 'Vietcombank',
        destWalletName: 'Momo',
      );
      await _open(tester, _screen(transfer));

      expect(find.text('Chuyển khoản'), findsOneWidget);
      expect(find.text('700.000 đ'), findsOneWidget);
      expect(_textColor(tester, '700.000 đ'), SoraColors.light.textPrimary);
      expect(find.text('+700.000 đ'), findsNothing);
      expect(find.text('-700.000 đ'), findsNothing);
      expect(find.text('Ví nguồn'), findsOneWidget);
      expect(find.text('Ví đích'), findsOneWidget);
      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('Momo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(d) adjustment trung tính: nhãn typeLabel, không màu thu/chi '
        '(FR-004, edge)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final adj = TransactionDetailView(
        type: TxnType.adjustment,
        summaryTitle: 'Điều chỉnh số dư',
        summaryGlyph: Icons.tune,
        amount: 3000,
        date: DateTime(2026, 9, 1, 10, 0),
        singleWalletName: 'Vietcombank',
      );
      await _open(tester, _screen(adj));

      expect(find.text('Điều chỉnh số dư'), findsOneWidget);
      expect(find.text('3.000 đ'), findsOneWidget);
      expect(_textColor(tester, '3.000 đ'), SoraColors.light.textPrimary);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TransactionDetailScreen — vùng chi tiết có điều kiện (FR-007)', () {
    testWidgets('(d2) không note/tag/ảnh/vị trí → chỉ Ví + Ngày giờ, không dòng '
        'trống/phân cách thừa (acceptance 4)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final view = TransactionDetailView(
        type: TxnType.income,
        summaryTitle: 'Bán đồ cũ',
        summaryGlyph: Icons.sell,
        amount: 2500000,
        date: DateTime(2026, 9, 5, 14, 30),
        singleWalletName: 'Vietcombank',
      );
      await _open(tester, _screen(view));

      expect(find.text('Ví'), findsOneWidget);
      expect(find.text('Ngày giờ'), findsOneWidget);
      expect(find.text('Ghi chú'), findsNothing);
      expect(find.text('Tag'), findsNothing);
      expect(find.text('Ảnh hóa đơn'), findsNothing);
      expect(find.text('Vị trí'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(e) đủ dữ liệu → hàng Ghi chú gói dòng, chip #tag, ảnh, Vị trí '
        '(acceptance 1)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final view = TransactionDetailView(
        type: TxnType.expense,
        summaryTitle: 'Ăn uống',
        summaryGlyph: Icons.restaurant,
        amount: -120000,
        date: DateTime(2026, 9, 3, 12, 15),
        singleWalletName: 'Tiền mặt',
        note: 'Ăn trưa cùng đồng nghiệp — ghi chú dài cần gói dòng để hiển thị '
            'trọn văn bản không cắt bớt.',
        tags: const ['côngty', 'ăntrưa'],
        receiptImage: '/tmp/khong-ton-tai.jpg',
        location: '123 Láng Hạ, Đống Đa, Hà Nội',
      );
      await _open(tester, _screen(view));

      expect(find.text('Ghi chú'), findsOneWidget);
      expect(
        find.textContaining('ghi chú dài cần gói dòng'),
        findsOneWidget,
      );
      expect(find.text('#côngty'), findsOneWidget);
      expect(find.text('#ăntrưa'), findsOneWidget);
      expect(find.text('Ảnh hóa đơn'), findsOneWidget); // path giả → placeholder.
      expect(find.text('Vị trí'), findsOneWidget);
      expect(find.text('123 Láng Hạ, Đống Đa, Hà Nội'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TransactionDetailScreen — khung & điểm vào no-op (FR-001/012)', () {
    testWidgets('(f) app bar: tiêu đề + back + 3 chấm; chạm không crash, không '
        'rời màn', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final view = TransactionDetailView(
        type: TxnType.expense,
        summaryTitle: 'Mua sắm',
        summaryGlyph: Icons.shopping_bag,
        amount: -1200000,
        date: DateTime(2026, 9, 4, 20, 0),
        singleWalletName: 'Thẻ tín dụng VIB',
      );
      await _open(tester, _screen(view));

      expect(find.text('Chi tiết giao dịch'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // 3 điểm vào đều no-op: không crash, không rời màn.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.tap(find.text('Nhân bản'));
      await tester.pump();
      await tester.tap(find.text('Sửa'));
      await tester.pump();
      expect(find.text('Chi tiết giao dịch'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Back thật → về màn host.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('mở chi tiết'), findsOneWidget);
      expect(find.text('Chi tiết giao dịch'), findsNothing);
    });
  });

  group('TransactionDetailScreen — trạng thái nạp/lỗi/null (R10)', () {
    testWidgets('(g) loader trả null → thông báo; loader lỗi → "Thử lại" gọi '
        'lại thành công', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Lần 1 ném lỗi, lần 2 trả view (loader seam tùy biến).
      var calls = 0;
      final view = TransactionDetailView(
        type: TxnType.income,
        summaryTitle: 'Lương',
        summaryGlyph: Icons.payments,
        amount: 12000000,
        date: DateTime(2026, 9, 4, 9, 0),
        singleWalletName: 'Vietcombank',
      );
      await _open(tester, _screenWith(() async {
        calls += 1;
        if (calls == 1) throw Exception('đọc lỗi');
        return view;
      }));

      expect(find.text('Không đọc được dữ liệu giao dịch.'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('+12.000.000 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loader trả null mọi lần → "Không tìm thấy giao dịch." không '
        'crash', (tester) async {
      await _open(tester, _screenWith(() async => null));
      expect(find.text('Không tìm thấy giao dịch.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TransactionDetailScreen — độ bền bố cục (FR-009/014, edge)', () {
    testWidgets('(h) cỡ chữ lớn + vùng an toàn → cuộn tới hàng cuối + nút dưới, '
        'không RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final view = TransactionDetailView(
        type: TxnType.expense,
        summaryTitle: 'Ăn uống · Ăn ngoài · Đi ăn tối',
        summaryGlyph: Icons.restaurant,
        amount: -85000,
        date: DateTime(2026, 9, 3, 12, 15),
        singleWalletName: 'Tiền mặt',
        note: 'Ăn trưa cùng đồng nghiệp — ghi chú rất dài cần gói dòng để hiển '
            'thị trọn văn bản không cắt bớt khi cỡ chữ lớn.',
        tags: const ['côngty', 'ăntrưa', 'vănphòng'],
        receiptImage: '/tmp/khong-ton-tai.jpg',
        location: '123 Láng Hạ, Đống Đa, Hà Nội — tòa nhà cạnh ngã tư',
      );
      await _open(
        tester,
        _screen(view),
        textScale: 2.0,
        safe: const EdgeInsets.only(bottom: 34),
        size: const Size(360, 640),
      );

      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -400));
        await tester.pump();
      }
      expect(find.text('Vị trí'), findsOneWidget);
      expect(find.text('Nhân bản'), findsOneWidget); // nút dưới không cắt.
      expect(find.text('Sửa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(i) số tiền rất lớn → không tràn vùng chứa (FR-009)', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final view = TransactionDetailView(
        type: TxnType.income,
        summaryTitle: 'Thu nhập khác',
        summaryGlyph: Icons.attach_money,
        amount: 1234567890123,
        date: DateTime(2026, 9, 5, 9, 0),
        singleWalletName: 'Vietcombank',
      );
      await _open(tester, _screen(view));

      expect(find.text('+1.234.567.890.123 đ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(j) ngày tương lai (đặt lịch) hiển thị bình thường (edge)', (
      tester,
    ) async {
      final view = TransactionDetailView(
        type: TxnType.expense,
        summaryTitle: 'Hóa đơn',
        summaryGlyph: Icons.receipt,
        amount: -200000,
        date: DateTime(2026, 9, 20, 6, 5),
        singleWalletName: 'Tiền mặt',
      );
      await _open(tester, _screen(view));

      expect(find.text('20/09/2026 · 06:05'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('TransactionDetailScreen — chạm "Sửa" điều hướng (PBI 39)', () {
    testWidgets(
      'giao dịch Chi: mở đúng AddTransactionScreen điền sẵn, lưu xong hiển thị dữ liệu mới',
      (tester) async {
        Get.reset();
        addTearDown(Get.reset);
        final wallet = Wallet(id: 1, name: 'Tiền mặt', type: WalletType.cash, balance: 1000000);
        // Danh sách giao dịch rỗng tường minh — seed mặc định (11 dòng mẫu) sẽ
        // đụng `walletId`/id của giao dịch chèn dưới đây.
        final repo = FakeWalletRepository([wallet], null, []);
        Get.put<WalletRepository>(repo);
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

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: _Host(
              screen: TransactionDetailScreen(
                ref: TransactionDetailRef(transactionId: original.id),
              ),
            ),
          ),
        );
        await tester.tap(find.text('mở chi tiết'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sửa'));
        await tester.pumpAndSettle();

        // Mở đúng màn sửa, điền sẵn dữ liệu gốc.
        expect(find.text('Sửa giao dịch'), findsOneWidget);
        expect(find.text('Nhà ở'), findsOneWidget);
        expect(find.text('Tiền mặt'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('amount-field')),
          '80000',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('save-transaction')));
        await tester.pumpAndSettle();

        // Quay lại Chi tiết, đã nạp lại đúng dữ liệu mới.
        expect(find.text('Chi tiết giao dịch'), findsOneWidget);
        expect(find.text('-80.000 đ'), findsOneWidget);
        final updated = (await repo.allTransactions()).single;
        expect(updated.id, original.id);
        expect(updated.amount, -80000);
      },
    );

    testWidgets(
      'giao dịch Chuyển khoản: mở đúng WalletTransferScreen điền sẵn, lưu xong hiển thị dữ liệu mới',
      (tester) async {
        Get.reset();
        addTearDown(Get.reset);
        final vcb = Wallet(id: 1, name: 'Vietcombank', type: WalletType.bank, balance: 14800000);
        final momo = Wallet(id: 2, name: 'Momo', type: WalletType.eWallet, balance: 1450000);
        final repo = FakeWalletRepository([vcb, momo], null, []);
        Get.put<WalletRepository>(repo);
        await repo.performTransfer(
          fromWalletId: vcb.id,
          toWalletId: momo.id,
          amount: 700000,
          date: DateTime(2026, 9, 1, 10, 0),
          note: 'Nạp Momo',
        );
        final source = (await repo.allTransactions())
            .firstWhere((t) => t.walletId == vcb.id);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.themeData,
            home: _Host(
              screen: TransactionDetailScreen(
                ref: TransactionDetailRef(transferGroupId: source.id),
              ),
            ),
          ),
        );
        await tester.tap(find.text('mở chi tiết'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sửa'));
        await tester.pumpAndSettle();

        // Mở đúng màn sửa chuyển khoản, điền sẵn dữ liệu gốc.
        expect(find.text('Sửa chuyển khoản'), findsOneWidget);
        expect(find.text('Momo'), findsOneWidget);

        await tester.enterText(
          find.byKey(const ValueKey('amount-field')),
          '1000000',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lưu thay đổi'));
        await tester.pumpAndSettle();

        // Quay lại Chi tiết, đã nạp lại đúng dữ liệu mới.
        expect(find.text('Chi tiết giao dịch'), findsOneWidget);
        expect(find.text('1.000.000 đ'), findsOneWidget);
        final legs = (await repo.allTransactions())
            .where((t) => t.type == TxnType.transfer)
            .toList();
        expect(legs.length, 2);
        expect(legs.firstWhere((t) => t.walletId == vcb.id).amount, -1000000);
        expect(legs.firstWhere((t) => t.walletId == momo.id).amount, 1000000);
      },
    );
  });
}
