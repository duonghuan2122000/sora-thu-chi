import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_source.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_controller.dart';
import 'package:sora_thu_chi/screens/wallet_detail_screen.dart';
import 'package:sora_thu_chi/screens/wallet_form_screen.dart';
import 'package:sora_thu_chi/screens/wallet_transfer_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/sora_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

const _bank = Wallet(
  id: 2,
  name: 'Vietcombank',
  type: WalletType.bank,
  icon: '🏦',
  balance: 14800000,
  sortOrder: 2,
);
const _credit = Wallet(
  id: 3,
  name: 'Thẻ tín dụng VIB',
  type: WalletType.credit,
  icon: '💳',
  balance: 0,
  sortOrder: 3,
  creditLimit: 20000000,
  creditUsed: 6500000,
);
const _momo = Wallet(
  id: 4,
  name: 'Momo',
  type: WalletType.eWallet,
  icon: '📱',
  balance: 1450000,
  sortOrder: 4,
);
const _savings = Wallet(
  id: 5,
  name: 'Sổ tiết kiệm',
  type: WalletType.savings,
  icon: '🏷️',
  balance: 9000000,
  isHidden: true,
  sortOrder: 5,
);

Transaction _txn(
  int id,
  int walletId,
  TxnType type, {
  String note = '',
  String category = '',
  required int amount,
  required DateTime date,
}) => Transaction(
  id: id,
  walletId: walletId,
  type: type,
  note: note,
  category: category,
  amount: amount,
  date: date,
);

Future<void> _pump(
  WidgetTester tester, {
  required Wallet wallet,
  List<Transaction>? transactions,
  List<Wallet>? wallets,
  double textScale = 1.0,
  EdgeInsets safe = EdgeInsets.zero,
}) async {
  // Đăng ký controller + fake repo trước pump: màn đọc động giao dịch qua
  // ensureWalletController() (transactions == null) và hành động Chuyển/Sửa
  // luôn cần controller — không bao giờ tạo DriftWalletRepository thật trong test.
  if (!Get.isRegistered<WalletController>()) {
    Get.reset();
    final controller = WalletController(FakeWalletRepository(wallets));
    Get.put(controller);
    await controller.init();
    addTearDown(Get.reset);
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
      home: WalletDetailScreen(wallet: wallet, transactions: transactions),
    ),
  );
  if (transactions == null) {
    await tester.pumpAndSettle(); // đợi nạp danh sách giao dịch (dynamic).
  }
}

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

String _ddMM(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Đăng ký controller + fake repo (mọi case detail "Sửa ví" mở form cần nó).
Future<void> _registerFakeController() async {
  Get.reset();
  final controller = WalletController(FakeWalletRepository());
  Get.put(controller);
  await controller.init();
  addTearDown(Get.reset);
}

void main() {
  group('WalletDetailScreen — màn chi tiết ví', () {
    testWidgets('(a) hero ví thường: số dư trắng cỡ lớn + loại ví', (
      tester,
    ) async {
      await _pump(tester, wallet: _bank, transactions: const []);

      expect(find.text('Vietcombank'), findsOneWidget); // app bar
      expect(find.text('14.800.000 đ'), findsOneWidget);
      expect(_textColor(tester, '14.800.000 đ'), AppColors.white);
      expect(find.text('Tài khoản ngân hàng'), findsOneWidget);
    });

    testWidgets('(b) thẻ tín dụng: "Đã dùng…" + phần trăm, không số dư dương', (
      tester,
    ) async {
      await _pump(tester, wallet: _credit, transactions: const []);

      expect(find.text('Đã dùng 6.500.000 / 20.000.000 đ'), findsOneWidget);
      expect(
        _textColor(tester, 'Đã dùng 6.500.000 / 20.000.000 đ'),
        AppColors.white,
      );
      expect(find.text('32% hạn mức đã dùng'), findsOneWidget);
      expect(find.text('0 đ'), findsNothing); // không hiện dạng số dư dương
    });

    testWidgets(
      '(c) nhóm "GIAO DỊCH GẦN ĐÂY": đúng ví, thu teal +, chi coral -, transfer trung tính',
      (tester) async {
        // Màn hình cao để mọi dòng trong ListView được dựng (không lazy cắt).
        await tester.binding.setSurfaceSize(const Size(360, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Không truyền transactions → default TransactionSource.forWallet(2)
        // phải lọc đúng ví Vietcombank (FR-008).
        await _pump(tester, wallet: _bank);

        expect(find.text('GIAO DỊCH GẦN ĐÂY'), findsOneWidget);
        expect(
          find.text('+12.000.000 đ'),
          findsOneWidget,
        ); // thu (Lương tháng 8)
        expect(_textColor(tester, '+12.000.000 đ'), AppColors.teal);
        expect(
          find.text('-450.000 đ'),
          findsOneWidget,
        ); // chi (Siêu thị Coopmart)
        expect(_textColor(tester, '-450.000 đ'), AppColors.coral);
        expect(find.text('-700.000 đ'), findsOneWidget); // chuyển khoản đi
        expect(_textColor(tester, '-700.000 đ'), SoraColors.light.listLabel);

        // Giao dịch ví khác (Tiền mặt/VIB) và vế đích Momo không xuất hiện.
        expect(find.text('Ăn trưa văn phòng'), findsNothing);
        expect(find.text('Mua sắm online'), findsNothing);
        expect(find.text('+700.000 đ'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '(d) transfer: nguồn -1.000.000 trung tính, đích +1.000.000 trung tính',
      (tester) async {
        final now = DateTime.now();
        final sourceRow = _txn(
          1,
          2,
          TxnType.transfer,
          note: 'Chuyển tiền đi Momo',
          amount: -1000000,
          date: now,
        );
        final destRow = _txn(
          2,
          4,
          TxnType.transfer,
          note: 'Chuyển tiền đi Momo',
          amount: 1000000,
          date: now,
        );

        await _pump(tester, wallet: _bank, transactions: [sourceRow]);
        expect(find.text('-1.000.000 đ'), findsOneWidget);
        expect(_textColor(tester, '-1.000.000 đ'), SoraColors.light.listLabel);

        await _pump(tester, wallet: _momo, transactions: [destRow]);
        expect(find.text('+1.000.000 đ'), findsOneWidget);
        expect(_textColor(tester, '+1.000.000 đ'), SoraColors.light.listLabel);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '(e) tiêu đề = note, dòng phụ "danh mục · ngày", đủ dạng nhãn ngày',
      (tester) async {
        final now = DateTime.now();
        final threeDays = now.subtract(const Duration(days: 3));
        final list = [
          _txn(
            1,
            2,
            TxnType.expense,
            note: 'Siêu thị Coopmart',
            category: 'Ăn uống',
            amount: -450000,
            date: now,
          ),
          _txn(
            2,
            2,
            TxnType.income,
            note: '',
            category: 'Lương',
            amount: 1000000,
            date: now.subtract(const Duration(days: 1)),
          ),
          _txn(
            3,
            2,
            TxnType.expense,
            note: '',
            category: 'Xăng xe',
            amount: -100000,
            date: threeDays,
          ),
        ];

        await _pump(tester, wallet: _bank, transactions: list);

        expect(
          find.text('Siêu thị Coopmart'),
          findsOneWidget,
        ); // tiêu đề = note
        expect(find.text('Ăn uống · Hôm nay'), findsOneWidget);
        expect(find.text('Lương · Hôm qua'), findsOneWidget);
        expect(
          find.textContaining('Xăng xe · ${_ddMM(threeDays)}'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('(f) ví ẩn không giao dịch vẫn mở, empty state không vỡ', (
      tester,
    ) async {
      await _pump(tester, wallet: _savings, transactions: const []);

      expect(find.text('Chưa có giao dịch nào.'), findsOneWidget);
      expect(find.text('9.000.000 đ'), findsOneWidget);
      expect(find.text('GIAO DỊCH GẦN ĐÂY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '(g) bơm [] → empty state, hero + hành động + tiêu đề vẫn hiện',
      (tester) async {
        await _pump(tester, wallet: _bank, transactions: const []);

        expect(find.text('14.800.000 đ'), findsOneWidget);
        expect(find.text('Chuyển tiền'), findsOneWidget);
        expect(find.text('Sửa ví'), findsOneWidget);
        expect(find.text('Ẩn ví'), findsOneWidget);
        expect(find.text('GIAO DỊCH GẦN ĐÂY'), findsOneWidget);
        expect(find.text('Chưa có giao dịch nào.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '(h) Chuyển tiền end-to-end: mở màn, chọn Momo, nhập 2.000.000, xác nhận → '
      'về chi tiết số dư mới + dòng chuyển trong giao dịch (FR-001/014, SC-002)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Nguồn Vietcombank, đọc động từ fake (có ví đích hợp lệ Momo/Tiền mặt).
        await _pump(tester, wallet: _bank);
        expect(find.text('14.800.000 đ'), findsOneWidget);

        // Mở màn chuyển tiền (sub-page, nút back, không bottom nav).
        await tester.tap(find.text('Chuyển tiền'));
        await tester.pumpAndSettle();
        expect(find.byType(WalletTransferScreen), findsOneWidget);
        expect(find.text('Chuyển tiền giữa ví'), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsNothing);

        // Chọn ví đích Momo từ sheet.
        await tester.tap(find.text('Chọn ví'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Momo'));
        await tester.pumpAndSettle();

        // Nhập số tiền → preview đúng 12.800.000 / 3.450.000 (SC-002).
        await tester.enterText(
          find.byKey(const ValueKey('amount-field')),
          '2000000',
        );
        await tester.pumpAndSettle();
        expect(find.text('12.800.000 đ / 3.450.000 đ'), findsOneWidget);

        // Xác nhận → pop về chi tiết với số dư & giao dịch đã nạp lại.
        await tester.tap(find.text('Xác nhận chuyển tiền'));
        await tester.pumpAndSettle();
        expect(find.byType(WalletTransferScreen), findsNothing);
        expect(find.text('12.800.000 đ'), findsOneWidget); // hero số dư mới
        expect(find.text('-2.000.000 đ'), findsOneWidget); // vế chuyển mới
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '(h1) chi tiết thẻ tín dụng: chạm "Chuyển tiền" → thông báo, không mở màn '
      '(acceptance 10, FR-018)',
      (tester) async {
        await _pump(tester, wallet: _credit, transactions: const []);

        await tester.tap(find.text('Chuyển tiền'));
        await tester.pumpAndSettle();

        expect(find.byType(WalletTransferScreen), findsNothing);
        expect(
          find.text('Thẻ tín dụng chưa dùng để chuyển tiền.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '(k) sửa tên Vietcombank đã có giao dịch → về chi tiết tên mới, số dư & lịch sử không đổi (SC-004)',
      (tester) async {
        await _registerFakeController();
        // Màn cao để đủ dòng giao dịch Vietcombank được dựng.
        await tester.binding.setSurfaceSize(const Size(360, 1800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // Default transactions của Vietcombank (đã có giao dịch → form khóa).
        await _pump(tester, wallet: _bank);

        await tester.tap(find.text('Sửa ví'));
        await tester.pumpAndSettle();
        expect(find.byType(WalletFormScreen), findsOneWidget);

        // Sửa tên (ô tên là TextFormField đầu tiên), giữ nguyên các trường khác.
        await tester.enterText(find.byType(TextFormField).at(0), 'Vietcombank CN');
        await tester.tap(find.text('Lưu ví'));
        await tester.pumpAndSettle();

        expect(find.byType(WalletFormScreen), findsNothing);
        expect(find.text('Vietcombank CN'), findsWidgets); // app bar detail
        // Số dư & lịch sử không đổi (SC-004).
        expect(find.text('14.800.000 đ'), findsOneWidget);
        expect(find.text('+12.000.000 đ'), findsOneWidget);
        expect(find.text('-450.000 đ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('(i) cỡ chữ 2.0 + vùng an toàn → cuộn hết, không overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Default transactions của Vietcombank (6 dòng) để căng chiều ngang/giữa.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              padding: EdgeInsets.only(bottom: 34),
              textScaler: TextScaler.linear(2.0),
            ),
            child: child!,
          ),
          home: WalletDetailScreen(
            wallet: _bank,
            transactions: TransactionSource.forWallet(_bank.id),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('(j) mở từ route khác → có BackButton trả về', (tester) async {
      await _registerFakeController(); // default-load cần controller (PBI 8).
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => WalletDetailScreen(wallet: _bank),
                    ),
                  ),
                  child: const Text('mở chi tiết ví'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('mở chi tiết ví'));
      await tester.pumpAndSettle();

      expect(find.byType(WalletDetailScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(WalletDetailScreen), findsNothing);
      expect(find.text('mở chi tiết ví'), findsOneWidget);
    });
  });
}
