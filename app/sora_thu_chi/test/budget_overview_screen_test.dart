import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/budget_overview_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';
import 'package:sora_thu_chi/theme/sora_colors.dart';

import 'fakes/fake_wallet_repository.dart';

/// Mốc "hôm nay" cố định cho mọi test màn (deterministic — không giờ thật).
final _now = DateTime(2026, 9, 12, 10);

Budget _budget({
  required int id,
  required int categoryId,
  required int amount,
  BudgetPeriod period = BudgetPeriod.monthly,
  bool isRecurring = true,
  DateTime? startDate,
}) => Budget(
  id: id,
  categoryId: categoryId,
  amount: amount,
  period: period,
  isRecurring: isRecurring,
  startDate: startDate ?? DateTime(2026, 9, 1),
);

Transaction _expense(int categoryId, int amount, DateTime date) => Transaction(
  id: categoryId * 10000 + amount,
  walletId: 1,
  type: TxnType.expense,
  amount: -amount,
  date: date,
  categoryId: categoryId,
);

/// Bộ seed mockup `01`: 5 danh mục chi tiêu + 1 ngân sách Tuần (Sức khỏe),
/// % lần lượt 107 / 96 / 84 / 53 / 45 / 24.
FakeWalletRepository _seededRepo() => FakeWalletRepository.withCategories(
  transactions: [
    _expense(1, 3210000, DateTime(2026, 9, 5)), // Ăn uống → 107%
    _expense(6, 1150000, DateTime(2026, 9, 6)), // Giải trí → 96%
    _expense(4, 2100000, DateTime(2026, 9, 7)), // Hóa đơn → 84%
    _expense(2, 800000, DateTime(2026, 9, 8)), // Di chuyển → 53%
    _expense(5, 450000, DateTime(2026, 9, 9)), // Mua sắm → 45%
    _expense(7, 120000, DateTime(2026, 9, 9)), // Sức khỏe (Tuần) → 24%
    _expense(1, 5000000, DateTime(2026, 8, 20)), // tháng 8 — ngoài kỳ đang xem
  ],
  budgetsSeed: [
    _budget(id: 1, categoryId: 1, amount: 3000000),
    _budget(id: 2, categoryId: 6, amount: 1200000),
    _budget(id: 3, categoryId: 4, amount: 2500000),
    _budget(id: 4, categoryId: 2, amount: 1500000),
    _budget(id: 5, categoryId: 5, amount: 1000000),
    _budget(
      id: 6,
      categoryId: 7,
      amount: 500000,
      period: BudgetPeriod.weekly,
      startDate: DateTime(2026, 9, 7),
    ),
  ],
);

/// Đẩy màn Tổng quan từ route trung gian (giữ được `pop()` của bottom nav).
Future<void> _openScreen(
  WidgetTester tester,
  WalletRepository repository, {
  ValueChanged<int>? onSelectTab,
}) async {
  // Khung cao: danh sách ngân sách dài, viewport mặc định 600px chỉ build vài
  // dòng đầu (ListView lười) → test dưới đây cần thấy hết.
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BudgetOverviewScreen(
                    repository: repository,
                    onSelectTab: onSelectTab,
                    now: _now,
                  ),
                ),
              ),
              child: const Text('mở ngân sách'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở ngân sách'));
  await tester.pumpAndSettle();
}

/// Bật tiếng Anh cho test — pump `MaterialApp` thường nên phải tự đăng ký bản đồ
/// dịch rồi khôi phục `Get.locale`/DI trong teardown (bài học PBI 19).
void useEnglish() {
  Get.addTranslations(SoraTranslations().keys);
  Get.locale = const Locale('en');
  addTearDown(() {
    Get.locale = null;
    Get.reset();
  });
}

Color? _colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

void main() {
  group('BudgetOverviewScreen — trạng thái rỗng (FR-019)', () {
    testWidgets('không có ngân sách → lời nhắc + nút, không thẻ tổng/danh sách',
        (tester) async {
      await _openScreen(tester, FakeWalletRepository.withCategories());

      expect(find.text('Chưa có ngân sách nào.'), findsOneWidget);
      expect(find.text('Thêm ngân sách'), findsOneWidget);
      expect(find.text('Tổng ngân sách tháng này'), findsNothing);
      expect(find.text('DANH MỤC'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('BudgetOverviewScreen — bố cục mockup 01 + số liệu (FR-002/003/004)', () {
    testWidgets('tiêu đề + nút +, bộ chọn kỳ, thẻ tổng, DANH MỤC, từng dòng',
        (tester) async {
      await _openScreen(tester, _seededRepo());

      expect(find.text('Ngân sách'), findsOneWidget);
      expect(find.byKey(const ValueKey('budget-add')), findsOneWidget);
      expect(find.text('Tháng 9, 2026'), findsOneWidget);

      // Thẻ tổng: tổng đã chi / giới hạn + còn lại + ngày còn lại.
      // 3.210.000 + 1.150.000 + 2.100.000 + 800.000 + 450.000 + 120.000 = 7.830.000
      // giới hạn: 3.000.000+1.200.000+2.500.000+1.500.000+1.000.000+500.000
      expect(find.text('Tổng ngân sách tháng này'), findsOneWidget);
      expect(find.text('Còn lại 1.870.000 đ'), findsOneWidget);
      expect(find.text('19 ngày còn lại'), findsOneWidget);

      expect(find.text('DANH MỤC'), findsOneWidget);
      expect(find.text('Sao chép tháng trước'), findsOneWidget);

      // 5 dòng ngân sách Tháng + 1 dòng Tuần.
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Sức khỏe'), findsOneWidget);
      expect(find.text('3.210.000 đ / 3.000.000 đ'), findsOneWidget);
      expect(find.text('1.150.000 đ / 1.200.000 đ'), findsOneWidget);
      expect(find.text('120.000 đ / 500.000 đ'), findsOneWidget);

      // % + nhãn chu kỳ cho dòng không phải Tháng.
      expect(find.text('107%'), findsOneWidget);
      expect(find.text('96%'), findsOneWidget);
      expect(find.text('84%'), findsOneWidget);
      expect(find.text('53%'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);
      expect(find.text('24%'), findsOneWidget);
      expect(find.text('Tuần'), findsOneWidget);

      // Bottom nav thật, tab Báo cáo đang chọn (index 2).
      expect(find.text('Tổng quan'), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('màu % theo 3 dải ngưỡng: teal / coral / coral (FR-005)',
        (tester) async {
      await _openScreen(tester, _seededRepo());
      final colors = SoraColors.light;

      expect(_colorOf(tester, '45%'), colors.tealOnNeutral);
      expect(_colorOf(tester, '107%'), colors.coralOnNeutral);
      expect(_colorOf(tester, '84%'), colors.coralOnNeutral);
      expect(_colorOf(tester, '96%'), colors.coralOnNeutral);
      expect(_colorOf(tester, '24%'), colors.tealOnNeutral);
    });

    testWidgets('dòng không lặp lại đã qua kỳ → "Đã kết thúc", không vào tổng',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [
          _expense(1, 100000, DateTime(2026, 9, 5)),
          _expense(3, 200000, DateTime(2026, 8, 15)),
        ],
        budgetsSeed: [
          _budget(id: 1, categoryId: 1, amount: 1000000),
          _budget(
            id: 2,
            categoryId: 3,
            amount: 500000,
            isRecurring: false,
            startDate: DateTime(2026, 8, 10),
          ),
        ],
      );
      await _openScreen(tester, repo);

      expect(find.text('Đã kết thúc'), findsOneWidget);
      expect(find.text('Nhà ở'), findsOneWidget);
      // Tổng giới hạn chỉ còn ngân sách đang chạy (1.000.000).
      expect(find.text('Còn lại 900.000 đ'), findsOneWidget);
    });
  });

  group('BudgetOverviewScreen — bộ chọn kỳ (FR-002)', () {
    testWidgets('mũi tên đổi tháng → tính lại; dòng Tuần giữ nguyên', (tester) async {
      await _openScreen(tester, _seededRepo());

      await tester.tap(find.byKey(const ValueKey('budget-month-next')));
      await tester.pumpAndSettle();

      expect(find.text('Tháng 10, 2026'), findsOneWidget);
      // Tháng 10 chưa có giao dịch Chi → dòng Tháng về 0%.
      expect(find.text('0 đ / 3.000.000 đ'), findsOneWidget);
      expect(find.text('0%'), findsWidgets);
      // Dòng Tuần vẫn giữ kỳ của `now`.
      expect(find.text('120.000 đ / 500.000 đ'), findsOneWidget);
      expect(find.text('24%'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('budget-month-prev')));
      await tester.tap(find.byKey(const ValueKey('budget-month-prev')));
      await tester.pumpAndSettle();
      expect(find.text('Tháng 8, 2026'), findsOneWidget);
      expect(find.text('5.000.000 đ / 3.000.000 đ'), findsOneWidget);
    });
  });

  group('BudgetOverviewScreen — điều hướng', () {
    testWidgets('chạm tab khác ở bottom nav → pop rồi gọi onSelectTab',
        (tester) async {
      final calls = <int>[];
      await _openScreen(
        tester,
        FakeWalletRepository.withCategories(),
        onSelectTab: calls.add,
      );

      await tester.tap(find.text('Tổng quan'));
      await tester.pumpAndSettle();

      expect(calls, [0]);
      expect(find.byType(BudgetOverviewScreen), findsNothing);
      expect(find.text('mở ngân sách'), findsOneWidget);
    });

    testWidgets('chạm tab Báo cáo (đang chọn) → không pop, không gọi callback',
        (tester) async {
      final calls = <int>[];
      await _openScreen(
        tester,
        FakeWalletRepository.withCategories(),
        onSelectTab: calls.add,
      );

      await tester.tap(find.text('Báo cáo'));
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
      expect(find.byType(BudgetOverviewScreen), findsOneWidget);
    });

    testWidgets('chạm dòng ngân sách → mở màn Sửa điền sẵn (FR-017)',
        (tester) async {
      await _openScreen(tester, _seededRepo());

      await tester.tap(find.byKey(const ValueKey('budget-row-1')));
      await tester.pumpAndSettle();

      expect(find.text('Sửa ngân sách'), findsOneWidget);
      expect(find.text('3.000.000'), findsOneWidget);
    });
  });

  group('BudgetOverviewScreen — English (FR-023)', () {
    testWidgets('nhãn tĩnh hiển thị tiếng Anh, không sót tiếng Việt',
        (tester) async {
      useEnglish();
      await _openScreen(tester, _seededRepo());

      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('9/2026'), findsOneWidget);
      expect(find.text("This month's total budget"), findsOneWidget);
      expect(find.text('19 days left'), findsOneWidget);
      expect(find.text('CATEGORIES'), findsOneWidget);
      expect(find.text('Copy last month'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Sao chép tháng trước'), findsNothing);
      expect(find.text('DANH MỤC'), findsNothing);
    });
  });
}
