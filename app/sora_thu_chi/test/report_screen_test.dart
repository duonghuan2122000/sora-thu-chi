import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/core/report/report_controller.dart';
import 'package:sora_thu_chi/core/report/report_view.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_filter.dart';
import 'package:sora_thu_chi/data/report_deps.dart';
import 'package:sora_thu_chi/data/transaction_deps.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/report_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

/// Mốc "hôm nay" cố định (deterministic — không dùng giờ thật).
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

/// Repo mặc định: tháng 3/2026 thu 900.000, chi 300.000; cả năm 2026 chi thêm
/// 100.000 (tháng 1); 1 cặp chuyển khoản phải bị loại khỏi mọi con số.
FakeWalletRepository _seededRepo() => FakeWalletRepository.withCategories(
  transactions: [
    _income(1, 900000, DateTime(2026, 3, 5)),
    _expense(2, 300000, DateTime(2026, 3, 10), categoryId: 1),
    _expense(3, 100000, DateTime(2026, 1, 20), categoryId: 1),
    Transaction(
      id: 4,
      walletId: 1,
      type: TxnType.transfer,
      amount: -500000,
      date: DateTime(2026, 3, 11),
      transferGroupId: 4,
    ),
    Transaction(
      id: 5,
      walletId: 2,
      type: TxnType.transfer,
      amount: 500000,
      date: DateTime(2026, 3, 11),
      transferGroupId: 4,
    ),
  ],
  categoriesSeed: [_cat(1, 'Ăn uống')],
);

/// Kỳ chỉ có chuyển khoản nội bộ — không tính là thu/chi (biên spec).
FakeWalletRepository _transferOnlyRepo() =>
    FakeWalletRepository.withCategories(
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

class _ThrowingRepo extends FakeWalletRepository {
  @override
  Future<List<Transaction>> allTransactions() async =>
      throw StateError('lỗi đọc giả lập');
}

Future<ReportController> _pump(
  WidgetTester tester,
  FakeWalletRepository repo, {
  ValueChanged<int>? onSelectTab,
}) async {
  tester.view.physicalSize = const Size(1000, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  Get.put<WalletRepository>(repo);
  final controller = ensureReportController();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Scaffold(body: ReportScreen(onSelectTab: onSelectTab)),
    ),
  );
  await controller.load(now: _now);
  await tester.pumpAndSettle();
  return controller;
}

/// Bật tiếng Anh — pump `MaterialApp` thường nên phải tự đăng ký bản đồ dịch
/// rồi khôi phục `Get.locale`/DI (bài học PBI 19).
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

  group('ReportScreen — khu đầu màn (US1)', () {
    testWidgets('tiêu đề, 4 lựa chọn kỳ (mặc định Tháng), 2 số tổng, hàng Ngân sách',
        (tester) async {
      await _pump(tester, _seededRepo());

      expect(find.text('Báo cáo'), findsOneWidget);
      expect(find.text('Ngày'), findsOneWidget);
      expect(find.text('Tuần'), findsOneWidget);
      expect(find.text('Tháng'), findsOneWidget);
      expect(find.text('Năm'), findsOneWidget);
      expect(find.text('Tổng thu'), findsOneWidget);
      // "Tổng chi" dùng ở cả khu đầu màn lẫn giữa vòng tròn phân bổ.
      expect(find.text('Tổng chi'), findsNWidgets(2));
      expect(find.text('900.000 đ'), findsOneWidget);
      expect(find.text('300.000 đ'), findsWidgets); // transfer bị loại
      expect(find.text('Ngân sách'), findsOneWidget);
    });

    testWidgets('KHÔNG có nút biểu tượng lịch (FR-002)', (tester) async {
      await _pump(tester, _seededRepo());
      expect(find.byIcon(Icons.calendar_today), findsNothing);
      expect(find.byIcon(Icons.calendar_month), findsNothing);
    });

    testWidgets('mặc định kỳ Tháng, đổi sang Năm → số liệu tính lại', (tester) async {
      final controller = await _pump(tester, _seededRepo());
      expect(controller.period.value, ReportPeriod.month);
      expect(controller.data.value!.range.start, DateTime(2026, 3, 1));

      await tester.tap(find.byKey(const ValueKey('report-period-year')));
      await tester.pumpAndSettle();

      expect(controller.period.value, ReportPeriod.year);
      expect(find.text('400.000 đ'), findsWidgets); // đầu màn + tâm vòng tròn + dòng top
    });

    testWidgets('lỗi đọc → thông báo + nút Thử lại', (tester) async {
      await _pump(tester, _ThrowingRepo());

      expect(find.text('Không đọc được dữ liệu báo cáo.'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ReportScreen — biểu đồ dòng tiền (US2)', () {
    testWidgets('tiêu đề theo kỳ + chú giải Thu/Chi + 6 nhóm cột', (tester) async {
      await _pump(tester, _seededRepo());

      expect(find.text('Dòng tiền 6 tháng gần đây'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Chi'), findsOneWidget);

      final chart = tester.widget<BarChart>(
        find.byKey(const ValueKey('report-flow-chart')),
      );
      expect(chart.data.barGroups, hasLength(6));
      // Cột cuối = tháng đang chọn: thu 900.000, chi 300.000.
      expect(chart.data.barGroups.last.barRods[0].toY, 900000);
      expect(chart.data.barGroups.last.barRods[1].toY, 300000);
      // Kỳ chưa có giao dịch vẫn có mặt với 2 cột 0 (FR-006).
      expect(chart.data.barGroups.first.barRods[0].toY, 0);
    });

    testWidgets('đổi sang kỳ Năm → tiêu đề đổi theo', (tester) async {
      await _pump(tester, _seededRepo());
      await tester.tap(find.byKey(const ValueKey('report-period-year')));
      await tester.pumpAndSettle();

      expect(find.text('Dòng tiền 6 năm gần đây'), findsOneWidget);
      expect(find.text('Dòng tiền 6 tháng gần đây'), findsNothing);
    });

    testWidgets('kỳ rỗng → cả 3 thẻ hiện thông điệp rỗng', (tester) async {
      await _pump(tester, _transferOnlyRepo());

      expect(
        find.text('Chưa có giao dịch nào trong kỳ này'),
        findsNWidgets(3),
      );
      expect(find.byKey(const ValueKey('report-flow-chart')), findsNothing);
      expect(find.byKey(const ValueKey('report-donut')), findsNothing);
    });
  });

  group('ReportScreen — phân bổ chi tiêu & drill-down (US3)', () {
    /// Chạm dòng chú giải ở thẻ phân bổ ([key] = id danh mục cha hoặc `other`).
    Future<void> tapLegend(WidgetTester tester, Object key) async {
      await tester.tap(find.byKey(ValueKey('report-legend-$key')));
      await tester.pumpAndSettle();
    }

    testWidgets('nhãn "Tổng chi" giữa vòng tròn + chú giải giảm dần kèm %',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [
          _expense(1, 3000000, DateTime(2026, 3, 5), categoryId: 1),
          _expense(2, 1000000, DateTime(2026, 3, 6), categoryId: 2),
        ],
        categoriesSeed: [_cat(1, 'Ăn uống'), _cat(2, 'Đi lại')],
      );
      await _pump(tester, repo);

      expect(find.text('Phân bổ chi tiêu theo danh mục'), findsOneWidget);
      expect(find.text('Tổng chi'), findsNWidgets(2)); // đầu màn + tâm vòng tròn
      expect(find.text('4.000.000 đ'), findsNWidgets(2)); // đầu màn + tâm vòng tròn
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('chạm dòng chú giải danh mục → đặt bộ lọc Chi + kỳ + đổi tab',
        (tester) async {
      final repo = _seededRepo();
      Get.put<WalletRepository>(repo);
      final txController = ensureTransactionController();
      final tabs = <int>[];
      await _pump(tester, repo, onSelectTab: tabs.add);

      await tapLegend(tester, 1);

      final filter = txController.activeFilter.value;
      expect(filter, isNotNull);
      expect(filter!.type, TxnTypeFilter.expense);
      expect(filter.dateStart, DateTime(2026, 3, 1));
      expect(filter.dateEnd, DateTime(2026, 3, 31));
      expect(filter.categoryIds, {1});
      expect(tabs, [1]);
    });

    testWidgets('chạm nhóm "Khác" → không đổi bộ lọc, không đổi tab',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [
          _expense(1, 100000, DateTime(2026, 3, 5), categoryId: 1),
          _expense(2, 50000, DateTime(2026, 3, 6)), // không danh mục → "Khác"
        ],
        categoriesSeed: [_cat(1, 'Ăn uống')],
      );
      Get.put<WalletRepository>(repo);
      final txController = ensureTransactionController();
      final tabs = <int>[];
      await _pump(tester, repo, onSelectTab: tabs.add);

      await tapLegend(tester, 'other');

      expect(txController.activeFilter.value, isNull);
      expect(tabs, isEmpty);
    });
  });

  group('ReportScreen — top danh mục chi tiêu (US4)', () {
    testWidgets('3 danh mục chi → 3 dòng, mỗi dòng có thanh tiến độ', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [
          _expense(1, 2000000, DateTime(2026, 3, 5), categoryId: 1),
          _expense(2, 1000000, DateTime(2026, 3, 6), categoryId: 2),
          _expense(3, 500000, DateTime(2026, 3, 7), categoryId: 3),
        ],
        categoriesSeed: [
          _cat(1, 'Ăn uống'),
          _cat(2, 'Đi lại'),
          _cat(3, 'Nhà cửa'),
        ],
      );
      await _pump(tester, repo);

      expect(find.text('Top danh mục chi tiêu'), findsOneWidget);
      expect(find.byKey(const ValueKey('report-top-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-top-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-top-3')), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
      expect(find.text('2.000.000 đ'), findsOneWidget); // dòng top (tổng chi 3.500.000)
      expect(tester.takeException(), isNull);
    });

    testWidgets('> 5 danh mục → đúng 5 dòng, KHÔNG có dòng "Khác"', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [
          for (var i = 1; i <= 6; i++)
            _expense(i, 100000 * (7 - i), DateTime(2026, 3, 5), categoryId: i),
        ],
        categoriesSeed: [
          for (var i = 1; i <= 6; i++) _cat(i, 'Danh mục $i'),
        ],
      );
      await _pump(tester, repo);

      expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
      expect(find.byKey(const ValueKey('report-top-6')), findsNothing);
      // "Khác" chỉ có ở vòng tròn phân bổ, không có dòng top nào mang tên đó.
      expect(find.byKey(const ValueKey('report-top-other')), findsNothing);
    });

    testWidgets('số tiền dòng top khớp lát cắt cùng danh mục', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [
          _expense(1, 3000000, DateTime(2026, 3, 5), categoryId: 1),
          _expense(2, 1000000, DateTime(2026, 3, 6), categoryId: 2),
        ],
        categoriesSeed: [_cat(1, 'Ăn uống'), _cat(2, 'Đi lại')],
      );
      await _pump(tester, repo);

      // 3.000.000 đ: dòng top + tâm vòng tròn (tổng chi bằng đúng lát cắt).
      expect(find.text('3.000.000 đ'), findsOneWidget); // dòng top (tổng chi 4.000.000)
      expect(find.text('1.000.000 đ'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });
  });

  group('ReportScreen — trạng thái rỗng (US5)', () {
    testWidgets('kỳ rỗng → 3 thẻ rỗng + 2 số tổng 0', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: const [],
        categoriesSeed: [_cat(1, 'Ăn uống')],
      );
      await _pump(tester, repo);

      expect(find.text('Chưa có giao dịch nào trong kỳ này'), findsNWidgets(3));
      // 2 số tổng ở khu đầu màn đều 0 (Tổng thu + Tổng chi).
      expect(find.text('Tổng thu'), findsOneWidget);
      expect(find.text('0 đ'), findsNWidgets(2));
      // "Ngân sách" vẫn còn để vào module con.
      expect(find.text('Ngân sách'), findsOneWidget);
    });

    testWidgets('kỳ chỉ có Thu → biểu đồ vẫn vẽ, 2 thẻ chi tiêu rỗng',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [_income(1, 900000, DateTime(2026, 3, 5))],
        categoriesSeed: [_cat(1, 'Ăn uống')],
      );
      await _pump(tester, repo);

      expect(find.byKey(const ValueKey('report-flow-chart')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-donut')), findsNothing);
      expect(find.text('Chưa có chi tiêu nào trong kỳ này'), findsNWidgets(2));
      expect(find.text('Chưa có giao dịch nào trong kỳ này'), findsNothing);
    });

    testWidgets('kỳ chỉ có chuyển khoản → như kỳ rỗng', (tester) async {
      await _pump(tester, _transferOnlyRepo());

      expect(find.text('Chưa có giao dịch nào trong kỳ này'), findsNWidgets(3));
      expect(find.byKey(const ValueKey('report-flow-chart')), findsNothing);
    });
  });
}
