import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_controller.dart';
import 'package:sora_thu_chi/screens/wallet_detail_screen.dart';
import 'package:sora_thu_chi/screens/wallet_form_screen.dart';
import 'package:sora_thu_chi/screens/wallet_list_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

/// Đăng ký [WalletController] + fake repo (seed [wallets]) trước khi pump —
/// list đọc controller reactive (thay vì bơm tham số `wallets` cũ).
Future<WalletController> registerController(
  WidgetTester tester, {
  List<Wallet>? wallets,
}) async {
  Get.reset();
  final controller = WalletController(FakeWalletRepository(wallets));
  Get.put(controller);
  await controller.init();
  addTearDown(Get.reset);
  return controller;
}

Future<void> pumpList(
  WidgetTester tester, {
  List<Wallet>? wallets,
  double textScale = 1.0,
  EdgeInsets safe = EdgeInsets.zero,
}) async {
  await registerController(tester, wallets: wallets);
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
      home: const WalletListScreen(),
    ),
  );
}

Color? _textColor(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('WalletListScreen — màn danh sách ví', () {
    testWidgets('(a) 5 ví mẫu: card tổng 19.450.000 đ / 4 ví, đủ hàng', (
      tester,
    ) async {
      await pumpList(tester);

      expect(find.text('Quản lý ví'), findsOneWidget); // app bar
      expect(find.text('TỔNG SỐ DƯ TẤT CẢ VÍ'), findsOneWidget);
      expect(find.text('19.450.000 đ'), findsOneWidget);
      expect(find.text('4 ví đang hoạt động'), findsOneWidget);

      for (final name in [
        'Tiền mặt',
        'Vietcombank',
        'Thẻ tín dụng VIB',
        'Momo',
      ]) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('Sổ tiết kiệm (đã ẩn)'), findsOneWidget);
    });

    testWidgets(
      '(b) thẻ tín dụng: "Đã dùng…/…đ" + "32%" coral, không số dư dương',
      (tester) async {
        await pumpList(tester);

        expect(find.text('Đã dùng 6.500.000 / 20.000.000 đ'), findsOneWidget);
        expect(find.text('32%'), findsOneWidget);

        expect(
          _textColor(tester, 'Đã dùng 6.500.000 / 20.000.000 đ'),
          AppColors.coral,
        );
        expect(_textColor(tester, '32%'), AppColors.coral);

        // Không hiển thị dưới dạng số dư dương (balance thẻ = 0 không lộ ra).
        expect(find.text('0 đ'), findsNothing);
      },
    );

    testWidgets(
      '(c) ví ẩn mờ, tên "(đã ẩn)", không tính vào tổng, dư vẫn hiện, ở cuối',
      (tester) async {
        await pumpList(tester);

        final hiddenName = find.text('Sổ tiết kiệm (đã ẩn)');
        expect(hiddenName, findsOneWidget);
        expect(
          _textColor(tester, 'Sổ tiết kiệm (đã ẩn)'),
          AppColors.tabInactive,
        );
        expect(find.text('Không tính vào tổng'), findsOneWidget);
        expect(find.text('9.000.000 đ'), findsOneWidget); // số dư vẫn hiển thị

        // Xếp cuối danh sách (dưới hàng Momo đang hoạt động).
        final momoY = tester.getTopLeft(find.text('Momo')).dy;
        final hiddenY = tester.getTopLeft(hiddenName).dy;
        expect(hiddenY, greaterThan(momoY));
      },
    );

    testWidgets('(d) đúng 1 nhãn "Mặc định" trên ví tiền mặt', (tester) async {
      await pumpList(tester);

      // Dòng phụ mặc định = Text.rich "Mặc định • Tiền mặt" — duy nhất 1 hàng.
      final defaultFinder = find.byWidgetPredicate(
        (w) => w is Text && w.textSpan?.toPlainText() == 'Mặc định • Tiền mặt',
      );
      expect(defaultFinder, findsOneWidget);

      // Nhãn nằm ngay dưới tên "Tiền mặt".
      final cashY = tester.getTopLeft(find.text('Tiền mặt')).dy;
      final defaultY = tester.getTopLeft(defaultFinder).dy;
      expect(defaultY, greaterThan(cashY));
      expect(defaultY, lessThan(cashY + 80));
    });

    testWidgets('(e) danh sách rỗng → empty state + nút thêm còn, không lỗi', (
      tester,
    ) async {
      await pumpList(tester, wallets: const []);

      expect(find.text('0 đ'), findsOneWidget);
      expect(find.text('0 ví đang hoạt động'), findsOneWidget);
      expect(find.text('Chưa có ví nào.'), findsOneWidget);
      expect(find.text('+ Thêm ví mới'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('(f) balance âm → hiển thị dấu trừ, không gãy', (tester) async {
      const negative = Wallet(
        id: 6,
        name: 'Tiền mặt lẻ',
        type: WalletType.cash,
        icon: '💵',
        balance: -500000,
        sortOrder: 1,
      );
      await pumpList(tester, wallets: const [negative]);

      // Card tổng và hàng ví cùng hiển thị giá trị âm có dấu trừ.
      expect(find.text('-500.000 đ'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('(g) cỡ chữ lớn + vùng an toàn → không RenderFlex overflow', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpList(tester);
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
          home: const WalletListScreen(),
        ),
      );
      expect(tester.takeException(), isNull);

      // Cuộn hết danh sách → mọi hàng được build, không overflow.
      for (var i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '(h) tap hàng → mở chi tiết, back về list; "+ Thêm ví mới" mở form thêm',
      (tester) async {
        await pumpList(tester);

        await tester.tap(find.text('Vietcombank'));
        await tester.pumpAndSettle();

        expect(find.byType(WalletDetailScreen), findsOneWidget);
        expect(find.text('Vietcombank'), findsOneWidget); // app bar detail
        expect(find.byType(BackButton), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(WalletDetailScreen), findsNothing);
        expect(find.byType(WalletListScreen), findsOneWidget);

        // "+ Thêm ví mới" giờ mở WalletFormScreen (chế độ thêm).
        await tester.tap(find.text('+ Thêm ví mới'));
        await tester.pumpAndSettle();
        expect(find.byType(WalletFormScreen), findsOneWidget);
        expect(find.text('Thêm ví mới'), findsWidgets); // title app bar
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('(i) mở từ route khác → có BackButton trả về', (tester) async {
      await registerController(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WalletListScreen(),
                    ),
                  ),
                  child: const Text('mở danh sách ví'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('mở danh sách ví'));
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.text('Quản lý ví'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(WalletListScreen), findsNothing);
      expect(find.text('mở danh sách ví'), findsOneWidget);
    });

    testWidgets(
      '(j) tạo ví qua form → về list thấy ví mới + tổng tăng (FR-013)',
      (tester) async {
        await pumpList(tester);

        await tester.tap(find.text('+ Thêm ví mới'));
        await tester.pumpAndSettle();
        expect(find.byType(WalletFormScreen), findsOneWidget);

        await tester.enterText(find.byType(TextFormField).at(0), 'Quỹ chi tiêu hàng ngày');
        await tester.enterText(find.byType(TextFormField).at(1), '3200000');
        await tester.tap(find.text('Lưu ví'));
        await tester.pumpAndSettle();

        // Về list: tổng/count cập nhật ngay (FR-013) — kiểm ở đầu danh sách.
        expect(find.byType(WalletFormScreen), findsNothing);
        expect(find.text('22.650.000 đ'), findsOneWidget);
        expect(find.text('5 ví đang hoạt động'), findsOneWidget);

        // Cuộn xuống (ListView lazy) để hàng mới được dựng.
        for (var i = 0; i < 3; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, -400));
          await tester.pump();
        }
        expect(find.text('Quỹ chi tiêu hàng ngày'), findsOneWidget);
        expect(find.text('3.200.000 đ'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
