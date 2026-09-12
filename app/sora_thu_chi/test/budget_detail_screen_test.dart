import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_controller.dart';
import 'package:sora_thu_chi/core/transaction/transaction_filter.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/budget_detail_screen.dart';
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

Transaction _expense(
  int categoryId,
  int amount,
  DateTime date, {
  String note = '',
  int id = 0,
}) => Transaction(
  id: id == 0 ? categoryId * 1000000 + amount : id,
  walletId: 1,
  type: TxnType.expense,
  amount: -amount,
  note: note,
  date: date,
  categoryId: categoryId,
);

void main() {
  /// Ngân sách "Ăn uống" 3.000.000 — đã chi 3.210.000 (danh mục con 13 góp
  /// 1.210.000) ⇒ 107%, vượt 210.000, còn 18 ngày, có băng cảnh báo tốc độ.
  FakeWalletRepository overRepo() => FakeWalletRepository.withCategories(
    transactions: [
      _expense(1, 2000000, DateTime(2026, 9, 5, 12, 30), note: 'Quán ăn Ngon'),
      _expense(13, 1210000, DateTime(2026, 9, 20, 8, 15), note: 'Cà phê Highlands'),
      _expense(2, 900000, DateTime(2026, 9, 6, 9)), // danh mục khác
      Transaction(
        id: 800,
        walletId: 1,
        type: TxnType.income,
        amount: 5000000,
        date: DateTime(2026, 9, 7),
        categoryId: 1,
      ),
      Transaction(
        id: 801,
        walletId: 1,
        type: TxnType.transfer,
        amount: -400000,
        date: DateTime(2026, 9, 8),
        categoryId: 1,
      ),
    ],
    budgetsSeed: [_budget(id: 1, categoryId: 1, amount: 3000000)],
  );

  Future<void> open(
    WidgetTester tester,
    WalletRepository repository, {
    int budgetId = 1,
    ValueChanged<int>? onSelectTab,
  }) async {
    // Khung cao: màn dài, viewport mặc định 600px chỉ build vài phần tử đầu.
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
                    builder: (_) => BudgetDetailScreen(
                      budgetId: budgetId,
                      repository: repository,
                      now: _now,
                      onSelectTab: onSelectTab,
                    ),
                  ),
                ),
                child: const Text('mở chi tiết'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('mở chi tiết'));
    await tester.pumpAndSettle();
  }

  void useEnglish() {
    Get.addTranslations(SoraTranslations().keys);
    Get.locale = const Locale('en');
    addTearDown(() {
      Get.locale = null;
      Get.reset();
    });
  }

  Color? colorOf(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  group('BudgetDetailScreen — bố cục mockup 03 (FR-001…FR-006)', () {
    testWidgets('app bar 2 dòng, thẻ tiến độ, huy hiệu vượt, ngày còn lại',
        (tester) async {
      await open(tester, overRepo());

      // App bar: tên danh mục + dòng phụ "chu kỳ • kỳ đang xem" (FR-002).
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Ngân sách tháng • Tháng 9, 2026'), findsOneWidget);

      // Thẻ tiến độ (FR-003).
      expect(find.text('Đã dùng'), findsOneWidget);
      expect(find.text('3.210.000 đ'), findsOneWidget);
      expect(find.text('trên 3.000.000 đ giới hạn'), findsOneWidget);
      expect(find.text('Trạng thái'), findsOneWidget);
      expect(find.text('Vượt 107%'), findsOneWidget);
      expect(find.text('Vượt 210.000 đ'), findsOneWidget);
      expect(find.text('18 ngày còn lại'), findsOneWidget);

      // Nhóm giao dịch (FR-011/FR-012).
      expect(find.text('GIAO DỊCH TRONG KỲ'), findsOneWidget);
      expect(find.text('Xem tất cả'), findsOneWidget);
      expect(find.text('Quán ăn Ngon'), findsOneWidget);
      expect(find.text('Cà phê Highlands'), findsOneWidget);

      // Màn con đè shell — không có bottom nav.
      expect(find.text('Tổng quan'), findsNothing);
      expect(find.text('Báo cáo'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('đã vượt → số đã dùng màu coral; chưa vượt → teal (FR-004)',
        (tester) async {
      final colors = SoraColors.light;
      await open(tester, overRepo());
      expect(colorOf(tester, '3.210.000 đ'), colors.coralOnNeutral);
      expect(colorOf(tester, 'Vượt 107%'), colors.coralOnNeutral);
    });

    testWidgets('chưa vượt → huy hiệu không có chữ "Vượt" + "Còn lại …"',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [_expense(5, 400000, DateTime(2026, 9, 4))],
        budgetsSeed: [_budget(id: 1, categoryId: 5, amount: 1000000)],
      );
      await open(tester, repo);

      expect(find.text('Bình thường 40%'), findsOneWidget);
      expect(find.textContaining('Vượt'), findsNothing);
      expect(find.text('Còn lại 600.000 đ'), findsOneWidget);
      expect(find.text('400.000 đ'), findsOneWidget);
      expect(colorOf(tester, '400.000 đ'), SoraColors.light.tealOnNeutral);
    });

    testWidgets('dải 80–99% → "Sắp đạt {p}%"', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [_expense(5, 900000, DateTime(2026, 9, 4))],
        budgetsSeed: [_budget(id: 1, categoryId: 5, amount: 1000000)],
      );
      await open(tester, repo);

      expect(find.text('Sắp đạt 90%'), findsOneWidget);
      expect(find.text('Còn lại 100.000 đ'), findsOneWidget);
    });

    testWidgets('Thu và chuyển khoản không lọt vào danh sách hay số đã dùng',
        (tester) async {
      await open(tester, overRepo());
      // Chỉ 2 giao dịch Chi của phạm vi ngân sách.
      expect(find.text('Quán ăn Ngon'), findsOneWidget);
      expect(find.text('Cà phê Highlands'), findsOneWidget);
      expect(find.text('3.210.000 đ'), findsOneWidget);
    });
  });

  group('BudgetDetailScreen — băng cảnh báo tốc độ (FR-007, SC-004)', () {
    testWidgets('chi nhanh hơn nhịp → băng hiện đúng % ngày / % ngân sách',
        (tester) async {
      await open(tester, overRepo());

      expect(find.text('Tốc độ chi tiêu nhanh hơn dự kiến'), findsOneWidget);
      expect(
        find.text('Đã dùng 40% ngày nhưng chi 107% ngân sách'),
        findsOneWidget,
      );
    });

    testWidgets('chi chậm hơn nhịp → băng ẩn', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [_expense(5, 200000, DateTime(2026, 9, 4))],
        budgetsSeed: [_budget(id: 1, categoryId: 5, amount: 1000000)],
      );
      await open(tester, repo);

      expect(find.text('Tốc độ chi tiêu nhanh hơn dự kiến'), findsNothing);
    });
  });

  group('BudgetDetailScreen — khối so sánh (FR-008/FR-009/FR-010)', () {
    /// Ngân sách Tháng bắt đầu từ tháng 7 → 3 kỳ T7/T8/T9 (T9 là kỳ đang xem).
    FakeWalletRepository threePeriodRepo() =>
        FakeWalletRepository.withCategories(
          transactions: [
            _expense(1, 1000000, DateTime(2026, 7, 20)), // 33% — teal
            _expense(1, 3500000, DateTime(2026, 8, 20)), // 117% — coral
            _expense(1, 3210000, DateTime(2026, 9, 5)), // 107% — coral
            _expense(1, 900000, DateTime(2026, 6, 20)), // trước khi bắt đầu
          ],
          budgetsSeed: [
            _budget(id: 1, categoryId: 1, amount: 3000000, startDate: DateTime(2026, 7, 1)),
          ],
        );

    testWidgets('chú giải, đường mốc nét đứt và 3 cặp cột', (tester) async {
      await open(tester, threePeriodRepo());

      expect(find.text('SO SÁNH DỰ KIẾN • THỰC TẾ'), findsOneWidget);
      expect(find.text('Dự kiến'), findsOneWidget);
      expect(find.text('Thực tế'), findsOneWidget);

      // Nhãn đường mốc do fl_chart vẽ trên canvas (không phải widget) nên kiểm
      // qua dữ liệu chart: 1 đường nét đứt đúng mức giới hạn hiện tại.
      final data = tester.widget<BarChart>(find.byType(BarChart)).data;
      final line = data.extraLinesData.horizontalLines.single;
      expect(line.y, 3000000);
      expect(line.dashArray, [3, 3]);
      expect(line.label.show, isTrue);
      expect(line.label.labelResolver(line), 'Dự kiến 3.000.000 đ');

      // 3 cặp cột: Dự kiến (trung tính) + Thực tế (teal/coral theo kết quả kỳ).
      expect(data.barGroups, hasLength(3));
      for (final group in data.barGroups) {
        expect(group.barRods, hasLength(2));
        expect(group.barRods.first.toY, 3000000);
      }
      expect(
        data.barGroups.first.barRods.first.color,
        data.barGroups.last.barRods.first.color,
      ); // cột "Dự kiến" cùng một màu trung tính cho mọi kỳ (FR-009).
      expect(data.barGroups[0].barRods[1].color, SoraColors.light.tealOnNeutral);
      expect(data.barGroups[1].barRods[1].color, SoraColors.light.coralOnNeutral);
      expect(data.barGroups[2].barRods[1].color, SoraColors.light.coralOnNeutral);

      expect(find.text('T7'), findsOneWidget);
      expect(find.text('T8'), findsOneWidget);
      expect(find.text('T9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nhãn kỳ đang xem (cột cuối) đậm hơn các kỳ trước',
        (tester) async {
      await open(tester, threePeriodRepo());

      FontWeight? weightOf(String label) =>
          tester.widget<Text>(find.text(label)).style?.fontWeight;
      expect(weightOf('T9'), FontWeight.w700);
      expect(weightOf('T8'), FontWeight.w400);
      expect(weightOf('T7'), FontWeight.w400);
    });

    testWidgets('ngân sách mới có 1 kỳ → 1 cột, không lỗi (kịch bản 19)',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [_expense(1, 500000, DateTime(2026, 9, 5))],
        budgetsSeed: [_budget(id: 1, categoryId: 1, amount: 3000000)],
      );
      await open(tester, repo);

      expect(find.text('T9'), findsOneWidget);
      expect(find.text('T8'), findsNothing);
      expect(
        tester.widget<BarChart>(find.byType(BarChart)).data.barGroups,
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ngân sách Tuần → nhãn trục theo ngày/tháng', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [_expense(1, 100000, DateTime(2026, 9, 9))],
        budgetsSeed: [
          _budget(
            id: 1,
            categoryId: 1,
            amount: 500000,
            period: BudgetPeriod.weekly,
            startDate: DateTime(2026, 9, 7),
          ),
        ],
      );
      await open(tester, repo);

      expect(find.text('Ngân sách tuần • Tuần 7/9 – 13/9'), findsOneWidget);
      expect(find.text('7/9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('BudgetDetailScreen — nhóm giao dịch (FR-012/FR-013)', () {
    testWidgets('chỉ hiện 5 dòng gần nhất dù kỳ có nhiều giao dịch',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [
          for (var day = 1; day <= 7; day++)
            _expense(
              1,
              100000,
              DateTime(2026, 9, day, 12),
              note: 'GD$day',
              id: day,
            ),
        ],
        budgetsSeed: [_budget(id: 1, categoryId: 1, amount: 3000000)],
      );
      await open(tester, repo);

      // Mới nhất trước: GD7…GD3 vào danh sách, GD2/GD1 rơi ra ngoài.
      for (final day in [7, 6, 5, 4, 3]) {
        expect(find.text('GD$day'), findsOneWidget);
      }
      expect(find.text('GD2'), findsNothing);
      expect(find.text('GD1'), findsNothing);
      // Tổng kỳ vẫn là 7 × 100.000 — danh sách chỉ là bản rút gọn.
      expect(find.text('700.000 đ'), findsOneWidget);
    });

    testWidgets('kỳ rỗng → trạng thái rỗng, không danh sách trơ', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [_expense(1, 900000, DateTime(2026, 8, 20))],
        budgetsSeed: [_budget(id: 1, categoryId: 1, amount: 3000000)],
      );
      await open(tester, repo);

      expect(find.text('Chưa có giao dịch Chi nào trong kỳ.'), findsOneWidget);
      expect(find.text('0 đ'), findsOneWidget);
      expect(find.text('Xem tất cả'), findsOneWidget);
    });

    testWidgets('dòng ghi chú rỗng → tiêu đề là tên danh mục, phụ có giờ',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [_expense(1, 150000, DateTime(2026, 9, 12, 12, 30))],
        budgetsSeed: [_budget(id: 1, categoryId: 1, amount: 3000000)],
      );
      await open(tester, repo);

      expect(find.text('Hôm nay, 12:30'), findsOneWidget);
      expect(find.text('-150.000 đ'), findsOneWidget);
    });
  });

  group('BudgetDetailScreen — "Xem tất cả" (FR-014, SC-005)', () {
    testWidgets('đặt bộ lọc Chi + khoảng kỳ + phạm vi danh mục, đổi tab',
        (tester) async {
      final repo = overRepo();
      final controller = TransactionController(repo);
      Get.put(controller);
      addTearDown(Get.reset);
      await controller.load(now: _now);

      final calls = <int>[];
      await open(tester, repo, onSelectTab: calls.add);
      await tester.tap(find.byKey(const ValueKey('budget-detail-see-all')));
      await tester.pumpAndSettle();

      final filter = controller.activeFilter.value!;
      expect(filter.type, TxnTypeFilter.expense);
      expect(filter.dateStart, DateTime(2026, 9, 1));
      expect(filter.dateEnd, DateTime(2026, 9, 30));
      expect(filter.categoryIds, {1, 13, 14, 15});
      expect(filter.sort, SortOption.dateNewest);
      expect(calls, [1]);
      expect(find.byType(BudgetDetailScreen), findsNothing);
    });

    testWidgets('không có callback tab → vẫn đặt bộ lọc và pop', (tester) async {
      final repo = overRepo();
      final controller = TransactionController(repo);
      Get.put(controller);
      addTearDown(Get.reset);
      await controller.load(now: _now);

      await open(tester, repo);
      await tester.tap(find.byKey(const ValueKey('budget-detail-see-all')));
      await tester.pumpAndSettle();

      expect(controller.activeFilter.value!.categoryIds, {1, 13, 14, 15});
      expect(find.byType(BudgetDetailScreen), findsNothing);
      expect(find.text('mở chi tiết'), findsOneWidget);
    });
  });

  group('BudgetDetailScreen — danh mục đã xóa (FR-019)', () {
    testWidgets('báo không hợp lệ, ẩn số liệu/biểu đồ/danh sách', (tester) async {
      final repo = FakeWalletRepository.withCategories(
        budgetsSeed: [_budget(id: 1, categoryId: 999, amount: 3000000)],
      );
      await open(tester, repo);

      expect(find.text('Danh mục của ngân sách đã bị xóa.'), findsOneWidget);
      expect(
        find.text('Chạm "Chỉnh sửa" để gán lại danh mục khác.'),
        findsOneWidget,
      );
      expect(find.text('Đã dùng'), findsNothing);
      expect(find.text('GIAO DỊCH TRONG KỲ'), findsNothing);
    });
  });

  group('BudgetDetailScreen — đổi kỳ đang xem (FR-023/FR-024, SC-012)', () {
    /// Ngân sách Tháng từ 1/7: T7 không chi, T8 chi 1.000.000, T9 chi 3.210.000.
    FakeWalletRepository pastPeriodRepo() =>
        FakeWalletRepository.withCategories(
          transactions: [
            _expense(1, 1000000, DateTime(2026, 8, 20, 14, 5), note: 'Tháng 8'),
            _expense(1, 3210000, DateTime(2026, 9, 5), note: 'Tháng 9'),
          ],
          budgetsSeed: [
            _budget(id: 1, categoryId: 1, amount: 3000000, startDate: DateTime(2026, 7, 1)),
          ],
        );

    testWidgets('mở bộ chọn → đúng các kỳ, kỳ đang xem được đánh dấu',
        (tester) async {
      await open(tester, pastPeriodRepo());

      await tester.tap(
        find.byKey(const ValueKey('budget-detail-period-picker')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chọn kỳ'), findsOneWidget);
      expect(find.text('Tháng 7, 2026'), findsOneWidget);
      // 'Tháng 8, 2026' xuất hiện 2 lần: dòng phụ app bar → đổi kỳ ở T9 thì
      // dòng phụ là T9, nên T8 chỉ có trong danh sách; T9 có ở cả hai chỗ.
      expect(find.text('Tháng 8, 2026'), findsOneWidget);
      expect(find.text('Tháng 9, 2026'), findsWidgets);
      expect(find.byIcon(Icons.check), findsOneWidget);
      // Không có kỳ nào trước khi ngân sách bắt đầu.
      expect(find.text('Tháng 6, 2026'), findsNothing);
    });

    testWidgets('chọn kỳ đã qua → số liệu tính lại, "Đã kết thúc", băng ẩn',
        (tester) async {
      await open(tester, pastPeriodRepo());
      expect(find.text('Tốc độ chi tiêu nhanh hơn dự kiến'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('budget-detail-period-picker')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('budget-detail-period-2026-08-01T00:00:00.000')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ngân sách tháng • Tháng 8, 2026'), findsOneWidget);
      expect(find.text('1.000.000 đ'), findsOneWidget);
      expect(find.text('Bình thường 33%'), findsOneWidget);
      expect(find.text('Còn lại 2.000.000 đ'), findsOneWidget);
      expect(find.text('Đã kết thúc'), findsOneWidget);
      expect(find.text('Tốc độ chi tiêu nhanh hơn dự kiến'), findsNothing);
      expect(find.text('Tháng 8'), findsOneWidget); // dòng giao dịch của kỳ đó
    });

    testWidgets('"Xem tất cả" ở kỳ cũ lọc theo khoảng của kỳ đó', (tester) async {
      final repo = pastPeriodRepo();
      final controller = TransactionController(repo);
      Get.put(controller);
      addTearDown(Get.reset);
      await controller.load(now: _now);

      await open(tester, repo);
      await tester.tap(
        find.byKey(const ValueKey('budget-detail-period-picker')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('budget-detail-period-2026-08-01T00:00:00.000')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('budget-detail-see-all')));
      await tester.pumpAndSettle();

      final filter = controller.activeFilter.value!;
      expect(filter.dateStart, DateTime(2026, 8, 1));
      expect(filter.dateEnd, DateTime(2026, 8, 31));
    });

    testWidgets('không lặp lại đã hết kỳ → mở đúng kỳ đã kết thúc, 1 lựa chọn',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        transactions: [_expense(1, 400000, DateTime(2026, 8, 20))],
        budgetsSeed: [
          _budget(
            id: 1,
            categoryId: 1,
            amount: 1000000,
            isRecurring: false,
            startDate: DateTime(2026, 8, 10),
          ),
        ],
      );
      await open(tester, repo);

      expect(find.text('Ngân sách tháng • Tháng 8, 2026'), findsOneWidget);
      expect(find.text('Đã kết thúc'), findsOneWidget);
      expect(find.text('400.000 đ'), findsOneWidget);
      expect(find.text('Tốc độ chi tiêu nhanh hơn dự kiến'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('budget-detail-period-picker')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tháng 8, 2026'), findsWidgets);
      expect(find.text('Tháng 9, 2026'), findsNothing);
    });
  });

  group('BudgetDetailScreen — chỉnh sửa & lưu trữ (FR-015…FR-017, FR-024)', () {
    FakeWalletRepository editRepo() => FakeWalletRepository.withCategories(
      transactions: [_expense(1, 3210000, DateTime(2026, 9, 5), note: 'Tháng 9')],
      budgetsSeed: [
        _budget(id: 1, categoryId: 1, amount: 3000000, startDate: DateTime(2026, 7, 1)),
      ],
    );

    testWidgets('hai nút hiện ở mọi kỳ, kể cả khi danh mục đã bị xóa (FR-024)',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        budgetsSeed: [_budget(id: 1, categoryId: 999, amount: 3000000)],
      );
      await open(tester, repo);

      expect(find.byKey(const ValueKey('budget-detail-edit')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('budget-detail-archive')),
        findsOneWidget,
      );
    });

    testWidgets('chạm "Chỉnh sửa" → mở form Sửa điền sẵn', (tester) async {
      await open(tester, editRepo());

      await tester.tap(find.byKey(const ValueKey('budget-detail-edit')));
      await tester.pumpAndSettle();

      expect(find.text('Sửa ngân sách'), findsOneWidget);
      expect(find.text('3.000.000'), findsOneWidget);
    });

    testWidgets('sửa giới hạn → số liệu tính lại theo giới hạn mới (FR-015)',
        (tester) async {
      final repo = editRepo();
      await open(tester, repo);
      expect(find.text('Vượt 107%'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('budget-detail-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('budget-amount')),
        '6000000',
      );
      await tester.tap(find.byKey(const ValueKey('budget-save')));
      await tester.pumpAndSettle();

      expect(find.text('trên 6.000.000 đ giới hạn'), findsOneWidget);
      expect(find.text('Bình thường 54%'), findsOneWidget);
      expect(find.text('Còn lại 2.790.000 đ'), findsOneWidget);
      expect((await repo.budgets()).single.amount, 6000000);
    });

    testWidgets('sửa khi đang xem kỳ cũ → vẫn giữ kỳ đó (FR-024)', (tester) async {
      await open(tester, editRepo());

      await tester.tap(
        find.byKey(const ValueKey('budget-detail-period-picker')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('budget-detail-period-2026-08-01T00:00:00.000')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ngân sách tháng • Tháng 8, 2026'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('budget-detail-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('budget-amount')),
        '6000000',
      );
      await tester.tap(find.byKey(const ValueKey('budget-save')));
      await tester.pumpAndSettle();

      expect(find.text('Ngân sách tháng • Tháng 8, 2026'), findsOneWidget);
      expect(find.text('Đã kết thúc'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('đổi chu kỳ Tháng → Tuần → không lỗi, về kỳ mặc định mới',
        (tester) async {
      await open(tester, editRepo());

      await tester.tap(find.byKey(const ValueKey('budget-detail-edit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('budget-period-weekly')));
      await tester.tap(find.byKey(const ValueKey('budget-save')));
      await tester.pumpAndSettle();

      // Ngân sách Tuần bắt đầu 1/7/2026 → kỳ đang xem là tuần chứa `now`.
      expect(find.text('Ngân sách tuần • Tuần 7/9 – 13/9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lưu trữ: hủy → không ghi gì, vẫn ở màn Chi tiết', (tester) async {
      final repo = editRepo();
      await open(tester, repo);

      await tester.tap(find.byKey(const ValueKey('budget-detail-archive')));
      await tester.pumpAndSettle();
      expect(find.text('Lưu trữ ngân sách?'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('budget-detail-cancel-archive')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BudgetDetailScreen), findsOneWidget);
      expect((await repo.budgets()).single.isArchived, isFalse);
    });

    testWidgets('lưu trữ: xác nhận → ghi isArchived + đóng màn (FR-016)',
        (tester) async {
      final repo = editRepo();
      await open(tester, repo);

      await tester.tap(find.byKey(const ValueKey('budget-detail-archive')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('budget-detail-confirm-archive')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BudgetDetailScreen), findsNothing);
      expect(find.text('mở chi tiết'), findsOneWidget);
      expect((await repo.budgets()).single.isArchived, isTrue);
      // Giao dịch không bị đụng tới (FR-017).
      expect((await repo.allTransactions()).length, 1);
    });
  });

  group('BudgetDetailScreen — English (FR-021)', () {
    testWidgets('nhãn tĩnh tiếng Anh, không sót tiếng Việt', (tester) async {
      useEnglish();
      await open(tester, overRepo());

      expect(find.text('Monthly budget • 9/2026'), findsOneWidget);
      expect(find.text('Used'), findsOneWidget);
      expect(find.text('of 3.000.000 đ limit'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Over 107%'), findsOneWidget);
      expect(find.text('Over 210.000 đ'), findsOneWidget);
      expect(find.text('18 days left'), findsOneWidget);
      expect(find.text('Spending faster than planned'), findsOneWidget);
      expect(find.text('TRANSACTIONS IN PERIOD'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);

      expect(find.text('Đã dùng'), findsNothing);
      expect(find.text('Trạng thái'), findsNothing);
      expect(find.text('GIAO DỊCH TRONG KỲ'), findsNothing);
      expect(find.text('Xem tất cả'), findsNothing);
    });
  });
}
