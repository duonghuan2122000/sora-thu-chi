import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/core/report/report_controller.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_filter.dart';
import 'package:sora_thu_chi/data/report_deps.dart';
import 'package:sora_thu_chi/data/transaction_deps.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/report_category_detail_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

/// Test màn Chi tiêu theo danh mục (màn `02`, PBI 23) — không DB, dữ liệu bơm
/// qua `FakeWalletRepository`, mốc "hôm nay" cố định.
final _now = DateTime(2026, 3, 15, 10);

Category _cat(int id, String name) => Category(
  id: id,
  name: name,
  type: CategoryType.expense,
  icon: 'restaurant',
  color: 0xFF0F6E56,
);

Transaction _expense(int id, int amount, DateTime date, {int? categoryId}) =>
    Transaction(
      id: id,
      walletId: 1,
      type: TxnType.expense,
      category: 'Ăn uống',
      amount: -amount,
      date: date,
      categoryId: categoryId,
    );

Transaction _income(int id, int amount, DateTime date) => Transaction(
  id: id,
  walletId: 1,
  type: TxnType.income,
  category: 'Lương',
  amount: amount,
  date: date,
);

/// Tháng 3/2026: 3.000.000 "Ăn uống" + 1.000.000 "Đi lại" + 50.000 không gắn
/// danh mục (dòng "Khác").
FakeWalletRepository _seededRepo() => FakeWalletRepository.withCategories(
  transactions: [
    _expense(1, 3000000, DateTime(2026, 3, 5), categoryId: 1),
    _expense(2, 1000000, DateTime(2026, 3, 6), categoryId: 2),
    _expense(3, 50000, DateTime(2026, 3, 7)),
  ],
  categoriesSeed: [_cat(1, 'Ăn uống'), _cat(2, 'Đi lại')],
);

FakeWalletRepository _transferOnlyRepo() => FakeWalletRepository.withCategories(
  transactions: [
    Transaction(
      id: 1,
      walletId: 1,
      type: TxnType.transfer,
      amount: -500000,
      date: DateTime(2026, 3, 11),
      transferGroupId: 1,
    ),
    Transaction(
      id: 2,
      walletId: 2,
      type: TxnType.transfer,
      amount: 500000,
      date: DateTime(2026, 3, 11),
      transferGroupId: 1,
    ),
  ],
  categoriesSeed: [_cat(1, 'Ăn uống')],
);

/// Màn 02 là `home:` của `MaterialApp` ⇒ `popUntil(isFirst)` không pop mất chính
/// nó (ghi chú test plan.md).
Future<ReportController> _pump(
  WidgetTester tester,
  FakeWalletRepository repo, {
  ValueChanged<int>? onSelectTab,
}) async {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  Get.put<WalletRepository>(repo);
  final controller = ensureReportController();
  await controller.load(now: _now);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: ReportCategoryDetailScreen(onSelectTab: onSelectTab),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

/// Bật tiếng Anh — pump `MaterialApp` thường nên phải tự đăng ký bản đồ dịch rồi
/// khôi phục `Get.locale`/DI (bài học PBI 19).
void useEnglish() {
  Get.addTranslations(SoraTranslations().keys);
  Get.locale = const Locale('en');
  addTearDown(() {
    Get.locale = null;
    Get.reset();
  });
}

void main() {
  tearDown(Get.reset);

  group('Màn 02 — bố cục & danh sách đầy đủ (US1)', () {
    testWidgets('app bar + chip kỳ + nhãn giữa vòng tròn + tiêu đề nhóm đủ dòng',
        (tester) async {
      await _pump(tester, _seededRepo());

      expect(find.text('Chi tiêu theo danh mục'), findsOneWidget);
      expect(find.byKey(const ValueKey('report-detail-chip')), findsOneWidget);
      expect(find.text('Tháng 3/2026'), findsOneWidget);
      expect(find.text('Tổng chi tháng'), findsOneWidget);
      // 4.050.000 ở nhãn giữa vòng tròn; 2 dòng danh mục + "Khác" = 3 dòng.
      expect(find.text('4.050.000 đ'), findsOneWidget);
      expect(find.text('DANH MỤC (3)'), findsOneWidget);
      expect(find.byKey(const ValueKey('report-detail-donut')), findsOneWidget);
      expect(
        find.text('Chạm vào một danh mục để xem các giao dịch'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('KHÔNG có bottom nav (màn con đè shell)', (tester) async {
      await _pump(tester, _seededRepo());
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('7 danh mục ⇒ đủ 7 dòng + "Khác", không cắt ở 5', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [
          for (var i = 1; i <= 7; i++)
            _expense(i, 100000 * (8 - i), DateTime(2026, 3, 5), categoryId: i),
          _expense(8, 1000, DateTime(2026, 3, 6)),
        ],
        categoriesSeed: [for (var i = 1; i <= 7; i++) _cat(i, 'Danh mục $i')],
      );
      await _pump(tester, repo);

      expect(find.text('DANH MỤC (8)'), findsOneWidget);
      expect(find.byKey(const ValueKey('report-detail-row-7')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('report-detail-row-other')),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNWidgets(8));
    });

    testWidgets('ca English ⇒ không còn nhãn tiếng Việt nào', (tester) async {
      useEnglish();
      await _pump(tester, _seededRepo());

      expect(find.text('Spending by category'), findsOneWidget);
      expect(find.text('Month total'), findsOneWidget);
      expect(find.text('Month 3/2026'), findsOneWidget);
      expect(find.text('CATEGORIES (3)'), findsOneWidget);
      expect(
        find.text('Tap a category to see its transactions'),
        findsOneWidget,
      );
      expect(find.text('Khác'), findsNothing);
      expect(find.text('Chi tiêu theo danh mục'), findsNothing);
    });
  });

  group('Màn 02 — drill-down sang màn Giao dịch (US2)', () {
    testWidgets('chạm dòng danh mục → bộ lọc Chi + kỳ + danh mục, đổi tab',
        (tester) async {
      final repo = _seededRepo();
      Get.put<WalletRepository>(repo);
      final txController = ensureTransactionController();
      final tabs = <int>[];
      await _pump(tester, repo, onSelectTab: tabs.add);

      await tester.tap(find.byKey(const ValueKey('report-detail-row-1')));
      await tester.pumpAndSettle();

      final filter = txController.activeFilter.value;
      expect(filter, isNotNull);
      expect(filter!.type, TxnTypeFilter.expense);
      expect(filter.dateStart, DateTime(2026, 3, 1));
      expect(filter.dateEnd, DateTime(2026, 3, 31));
      expect(filter.categoryIds, {1});
      expect(tabs, [1]);
    });

    testWidgets('chạm dòng "Khác" → không đổi bộ lọc, không đổi tab',
        (tester) async {
      final repo = _seededRepo();
      Get.put<WalletRepository>(repo);
      final txController = ensureTransactionController();
      final tabs = <int>[];
      await _pump(tester, repo, onSelectTab: tabs.add);

      await tester.tap(
        find.byKey(const ValueKey('report-detail-row-other')),
      );
      await tester.pumpAndSettle();

      expect(txController.activeFilter.value, isNull);
      expect(tabs, isEmpty);
    });
  });

  group('Màn 02 — trạng thái rỗng (US3)', () {
    testWidgets('kỳ rỗng → thông điệp "chưa có giao dịch", không vẽ vòng tròn',
        (tester) async {
      await _pump(tester, FakeWalletRepository.withCategories(categoriesSeed: [
        _cat(1, 'Ăn uống'),
      ]));

      expect(
        find.byKey(const ValueKey('report-detail-empty')),
        findsOneWidget,
      );
      expect(find.text('Chưa có giao dịch nào trong kỳ này'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
      expect(find.text('DANH MỤC (0)'), findsNothing);
      expect(find.byKey(const ValueKey('report-detail-chip')), findsNothing);
    });

    testWidgets('kỳ chỉ có Thu → "chưa có chi tiêu", không vẽ vòng tròn',
        (tester) async {
      await _pump(
        tester,
        FakeWalletRepository.withCategories(
          transactions: [_income(1, 900000, DateTime(2026, 3, 5))],
          categoriesSeed: [_cat(1, 'Ăn uống')],
        ),
      );

      expect(
        find.byKey(const ValueKey('report-detail-empty')),
        findsOneWidget,
      );
      expect(find.text('Chưa có chi tiêu nào trong kỳ này'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });

    testWidgets('kỳ chỉ có chuyển khoản → như kỳ rỗng', (tester) async {
      await _pump(tester, _transferOnlyRepo());

      expect(
        find.byKey(const ValueKey('report-detail-empty')),
        findsOneWidget,
      );
      expect(find.text('Chưa có giao dịch nào trong kỳ này'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });
  });
}
