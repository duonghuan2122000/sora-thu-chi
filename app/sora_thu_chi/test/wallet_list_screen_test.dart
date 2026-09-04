import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/core/wallet/wallet_source.dart';
import 'package:sora_thu_chi/screens/wallet_detail_screen.dart';
import 'package:sora_thu_chi/screens/wallet_list_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

const _cash = Wallet(
  id: 1,
  name: 'Tiền mặt',
  type: WalletType.cash,
  icon: '💵',
  balance: 3200000,
  isDefault: true,
  sortOrder: 1,
);
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
const _ewallet = Wallet(
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

Future<void> pumpList(
  WidgetTester tester, {
  List<Wallet>? wallets,
  double textScale = 1.0,
  EdgeInsets safe = EdgeInsets.zero,
}) async {
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
      home: WalletListScreen(wallets: wallets),
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
      await pumpList(tester, wallets: WalletSource.all());

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
        await pumpList(tester, wallets: WalletSource.all());

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
        await pumpList(tester, wallets: WalletSource.all());

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
      await pumpList(tester, wallets: WalletSource.all());

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
          home: WalletListScreen(
            wallets: const [_cash, _bank, _credit, _ewallet, _savings],
          ),
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
      '(h) tap hàng ví → mở WalletDetailScreen, back về list, "+ Thêm ví mới" không mở route',
      (tester) async {
        await pumpList(tester, wallets: WalletSource.all());

        await tester.tap(find.text('Vietcombank'));
        await tester.pumpAndSettle();

        // FR-001: điều hướng sang màn chi tiết đúng ví.
        expect(find.byType(WalletDetailScreen), findsOneWidget);
        expect(find.text('Vietcombank'), findsOneWidget); // app bar detail
        expect(find.byType(BackButton), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.byType(WalletDetailScreen), findsNothing);
        expect(find.byType(WalletListScreen), findsOneWidget);

        // "+ Thêm ví mới" vẫn là điểm vào chưa kích hoạt — không mở route.
        await tester.tap(find.text('+ Thêm ví mới'));
        await tester.pumpAndSettle();
        expect(find.byType(WalletDetailScreen), findsNothing);
        expect(find.byType(WalletListScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('(i) mở từ route khác → có BackButton trả về', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          WalletListScreen(wallets: WalletSource.all()),
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
  });
}
