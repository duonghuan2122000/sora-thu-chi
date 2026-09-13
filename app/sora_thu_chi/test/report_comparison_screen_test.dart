import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/core/report/report_controller.dart';
import 'package:sora_thu_chi/core/report/report_view.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/data/report_deps.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/report_comparison_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';
import 'package:sora_thu_chi/theme/sora_colors.dart';

import 'fakes/fake_wallet_repository.dart';

/// Test màn **So sánh kỳ** (màn `03`, PBI 26) — không DB, dữ liệu bơm qua
/// `FakeWalletRepository`, mốc "hôm nay" cố định (Tháng 3/2026 vs Tháng 2/2026).
final _now = DateTime(2026, 3, 15, 10);

Category _cat(int id, String name) => Category(
  id: id,
  name: name,
  type: CategoryType.expense,
  icon: 'restaurant',
  color: 0xFF0F6E56,
);

Transaction _expense(
  int id,
  int amount,
  DateTime date, {
  int? categoryId,
  String category = 'Ăn uống',
}) => Transaction(
  id: id,
  walletId: 1,
  type: TxnType.expense,
  category: category,
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

/// Bộ dữ liệu như quickstart §1: T3/2026 thu 18.500.000 chi 12.300.000;
/// T2/2026 thu 17.100.000 chi 10.700.000 ⇒ badge Thu ▲ 8% (teal), Chi ▲ 15%
/// (coral); T3/2025 thu 15.000.000 chi 9.000.000 cho chế độ "cùng kỳ năm trước".
/// Kèm 1 cặp chuyển khoản trong T3 — **không** được xuất hiện ở con số nào.
FakeWalletRepository _seededRepo() => FakeWalletRepository.withCategories(
  transactions: [
    _income(1, 18500000, DateTime(2026, 3, 5)),
    _expense(2, 12300000, DateTime(2026, 3, 10), categoryId: 1),
    _income(3, 17100000, DateTime(2026, 2, 5)),
    _expense(4, 10700000, DateTime(2026, 2, 10), categoryId: 1),
    _income(7, 15000000, DateTime(2025, 3, 5)),
    _expense(8, 9000000, DateTime(2025, 3, 10), categoryId: 1),
    Transaction(
      id: 5,
      walletId: 1,
      type: TxnType.transfer,
      amount: -5000000,
      date: DateTime(2026, 3, 11),
      transferGroupId: 5,
    ),
    Transaction(
      id: 6,
      walletId: 2,
      type: TxnType.transfer,
      amount: 5000000,
      date: DateTime(2026, 3, 11),
      transferGroupId: 5,
    ),
  ],
  categoriesSeed: [_cat(1, 'Ăn uống')],
);

Future<ReportController> _pump(
  WidgetTester tester,
  FakeWalletRepository repo, {
  ReportPeriod period = ReportPeriod.month,
}) async {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  Get.put<WalletRepository>(repo);
  final controller = ensureReportController();
  await controller.load(now: _now);
  controller.setPeriod(period);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: const ReportComparisonScreen(),
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

/// Nhãn của chip kỳ (`left` = kỳ chính, `right` = kỳ đối chiếu) — đọc theo key
/// vì cùng chuỗi còn xuất hiện ở chú giải thẻ xu hướng.
String _chipLabel(WidgetTester tester, String which) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey('report-compare-chip-$which')),
        matching: find.byType(Text),
      ),
    )
    .data!;

/// Text của badge theo chỉ số.
String _badgeText(WidgetTester tester, String which) => tester
    .widget<Text>(find.byKey(ValueKey('report-compare-badge-$which')))
    .data!;

Color? _badgeColor(WidgetTester tester, String which) => tester
    .widget<Text>(find.byKey(ValueKey('report-compare-badge-$which')))
    .style
    ?.color;

/// Cao độ cột vẽ bằng `Container` màu [color] (cột đầu tiên tìm được — cột kỳ
/// đối chiếu dùng chung một màu xám nên luôn lấy `.first` = thẻ Thu nhập).
double _barHeight(WidgetTester tester, Color color) => tester
    .getSize(
      find
          .byWidgetPredicate(
            (w) => w is Container && w.color == color && w.constraints != null,
          )
          .first,
    )
    .height;

void main() {
  tearDown(Get.reset);

  group('Màn 03 — khung màn & cặp chip (US1)', () {
    testWidgets('app bar teal + tiêu đề, KHÔNG bottom nav, KHÔNG FAB', (
      tester,
    ) async {
      await _pump(tester, _seededRepo());

      expect(find.text('So sánh kỳ'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(
        find.byKey(const ValueKey('report-comparison-screen')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'nhãn hai chip: kỳ chính T3/2026 (teal) · kỳ đối chiếu T2/2026',
      (tester) async {
        await _pump(tester, _seededRepo());

        expect(_chipLabel(tester, 'left'), 'Tháng 3/2026');
        expect(_chipLabel(tester, 'right'), 'Tháng 2/2026');
        // Chú giải thẻ xu hướng dùng **đúng** nhãn hai chip ⇒ mỗi nhãn 2 chỗ.
        expect(find.text('Tháng 3/2026'), findsNWidgets(2));
        expect(find.text('Tháng 2/2026'), findsNWidgets(2));

        final left = tester.widget<Container>(
          find
              .descendant(
                of: find.byKey(const ValueKey('report-compare-chip-left')),
                matching: find.byType(Container),
              )
              .first,
        );
        expect((left.decoration as BoxDecoration).color, AppColors.teal);
        expect(
          find.byKey(const ValueKey('report-compare-swap')),
          findsOneWidget,
        );
      },
    );

    testWidgets('ca English ⇒ 0 nhãn tiếng Việt còn sót', (tester) async {
      useEnglish();
      await _pump(tester, _seededRepo());

      expect(find.text('Compare periods'), findsOneWidget);
      expect(_chipLabel(tester, 'left'), 'Month 3/2026');
      expect(_chipLabel(tester, 'right'), 'Month 2/2026');
      expect(find.text('So sánh kỳ'), findsNothing);
      expect(find.text('Tháng 3/2026'), findsNothing);
    });
  });

  group('Màn 03 — hai thẻ số liệu (US1)', () {
    testWidgets('thẻ Thu nhập: hai dòng số, cột tỉ lệ, badge ▲ 8% teal', (
      tester,
    ) async {
      await _pump(tester, _seededRepo());

      expect(find.text('Thu nhập'), findsOneWidget);
      expect(find.text('18.500.000 đ'), findsOneWidget);
      expect(find.text('17.100.000 đ'), findsOneWidget);
      // Nhãn cột (`T3`/`T2`) có ở **cả hai** thẻ số liệu.
      expect(find.text('T3'), findsNWidgets(2));
      expect(find.text('T2'), findsNWidgets(2));

      expect(_badgeText(tester, 'income'), '▲ 8%');
      expect(_badgeColor(tester, 'income'), SoraColors.light.tealOnNeutral);

      // Cột kỳ chính chiếm trọn 64; cột kỳ đối chiếu tỉ lệ 17,1/18,5.
      final teal = _barHeight(tester, SoraColors.light.tealOnNeutral);
      final grey = _barHeight(
        tester,
        SoraColors.light.dotEmpty.withValues(alpha: 0.5),
      );
      expect(teal, closeTo(64, 0.01));
      expect(grey, closeTo(64 * 17100000 / 18500000, 0.5));
    });

    testWidgets('thẻ Chi tiêu: cột coral, badge ▲ 15% coral (chi tăng = xấu)', (
      tester,
    ) async {
      await _pump(tester, _seededRepo());

      expect(find.text('Chi tiêu'), findsOneWidget);
      expect(find.text('12.300.000 đ'), findsOneWidget);
      expect(find.text('10.700.000 đ'), findsOneWidget);

      expect(_badgeText(tester, 'expense'), '▲ 15%');
      expect(_badgeColor(tester, 'expense'), SoraColors.light.coralOnNeutral);
      expect(
        _barHeight(tester, SoraColors.light.coralOnNeutral),
        closeTo(64, 0.01),
      );
    });

    testWidgets('chuyển khoản nội bộ KHÔNG vào con số nào (FR-015)', (
      tester,
    ) async {
      await _pump(tester, _seededRepo());

      expect(find.text('5.000.000 đ'), findsNothing);
      expect(find.text('23.500.000 đ'), findsNothing); // 18,5 + 5,0
    });
  });

  group('Màn 03 — nút hoán đổi (US1)', () {
    testWidgets('hoán đổi đổi chỗ hai chip + cập nhật số liệu và màu badge', (
      tester,
    ) async {
      await _pump(tester, _seededRepo());

      await tester.tap(find.byKey(const ValueKey('report-compare-swap')));
      await tester.pumpAndSettle();

      // Chip đổi chỗ: trái = T2, phải = T3.
      expect(_chipLabel(tester, 'left'), 'Tháng 2/2026');
      expect(_chipLabel(tester, 'right'), 'Tháng 3/2026');
      // Chi 10,7 vs 12,3 ⇒ -13% nhưng **giảm là tốt** ⇒ teal.
      expect(_badgeText(tester, 'expense'), '▼ 13%');
      expect(_badgeColor(tester, 'expense'), SoraColors.light.tealOnNeutral);
      // Thu giảm ⇒ xấu ⇒ coral.
      expect(_badgeColor(tester, 'income'), SoraColors.light.coralOnNeutral);
    });

    testWidgets('hoán đổi lần hai trả về ĐÚNG trạng thái ban đầu (SC-007)', (
      tester,
    ) async {
      await _pump(tester, _seededRepo());
      final before = _badgeText(tester, 'expense');
      final beforeColor = _badgeColor(tester, 'expense');

      await tester.tap(find.byKey(const ValueKey('report-compare-swap')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('report-compare-swap')));
      await tester.pumpAndSettle();

      expect(_badgeText(tester, 'expense'), before);
      expect(_badgeColor(tester, 'expense'), beforeColor);
      expect(_chipLabel(tester, 'left'), 'Tháng 3/2026');
      expect(_chipLabel(tester, 'right'), 'Tháng 2/2026');
      // Kỳ chính trở lại bên trái ⇒ cột kỳ chính lại là cột teal chiếm trọn.
      expect(find.text('18.500.000 đ'), findsOneWidget);
    });
  });

  group('Màn 03 — chip kỳ đối chiếu: cùng kỳ năm trước (US2)', () {
    testWidgets('chạm chip phải → Tháng 3/2025 + số liệu cập nhật theo', (
      tester,
    ) async {
      await _pump(tester, _seededRepo());
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('report-compare-chip-right')),
          matching: find.byIcon(Icons.expand_more),
        ),
        findsOneWidget, // chỉ báo thị giác bấm được (FR-005)
      );

      await tester.tap(find.byKey(const ValueKey('report-compare-chip-right')));
      await tester.pumpAndSettle();

      expect(_chipLabel(tester, 'right'), 'Tháng 3/2025');
      expect(find.text('Tháng 2/2026'), findsNothing);
      // Kỳ chính KHÔNG đổi.
      expect(_chipLabel(tester, 'left'), 'Tháng 3/2026');
      // Thu 18,5 vs 15,0 ⇒ +23%; Chi 12,3 vs 9,0 ⇒ +37% (xấu ⇒ coral).
      expect(_badgeText(tester, 'income'), '▲ 23%');
      expect(_badgeColor(tester, 'income'), SoraColors.light.tealOnNeutral);
      expect(_badgeText(tester, 'expense'), '▲ 37%');
      expect(_badgeColor(tester, 'expense'), SoraColors.light.coralOnNeutral);
      expect(find.text('15.000.000 đ'), findsOneWidget);
    });

    testWidgets('chạm lần nữa → quay về Tháng 2/2026 trùng khớp ban đầu', (
      tester,
    ) async {
      await _pump(tester, _seededRepo());

      await tester.tap(find.byKey(const ValueKey('report-compare-chip-right')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('report-compare-chip-right')));
      await tester.pumpAndSettle();

      expect(_chipLabel(tester, 'right'), 'Tháng 2/2026');
      expect(_badgeText(tester, 'expense'), '▲ 15%');
      expect(_badgeColor(tester, 'expense'), SoraColors.light.coralOnNeutral);
      expect(find.text('17.100.000 đ'), findsOneWidget);
    });

    testWidgets('kỳ Ngày: hôm trước ⇄ cùng ngày năm trước', (tester) async {
      await _pump(tester, _seededRepo(), period: ReportPeriod.day);

      expect(_chipLabel(tester, 'left'), 'Ngày 15/03/2026');
      expect(_chipLabel(tester, 'right'), 'Ngày 14/03/2026');

      await tester.tap(find.byKey(const ValueKey('report-compare-chip-right')));
      await tester.pumpAndSettle();

      expect(_chipLabel(tester, 'right'), 'Ngày 15/03/2025');
      expect(_chipLabel(tester, 'left'), 'Ngày 15/03/2026');
    });

    testWidgets('kỳ Tuần: tuần trước ⇄ cùng tuần năm trước, vẫn bắt Thứ Hai', (
      tester,
    ) async {
      await _pump(tester, _seededRepo(), period: ReportPeriod.week);

      expect(_chipLabel(tester, 'left'), 'Tuần 09/03–15/03/2026');
      expect(_chipLabel(tester, 'right'), 'Tuần 02/03–08/03/2026');

      await tester.tap(find.byKey(const ValueKey('report-compare-chip-right')));
      await tester.pumpAndSettle();

      expect(_chipLabel(tester, 'right'), 'Tuần 03/03–09/03/2025');
      expect(_chipLabel(tester, 'left'), 'Tuần 09/03–15/03/2026');
    });

    testWidgets('kỳ Năm: năm trước (hai chế độ trùng nhau)', (tester) async {
      await _pump(tester, _seededRepo(), period: ReportPeriod.year);

      expect(_chipLabel(tester, 'left'), 'Năm 2026');
      expect(_chipLabel(tester, 'right'), 'Năm 2025');

      await tester.tap(find.byKey(const ValueKey('report-compare-chip-right')));
      await tester.pumpAndSettle();

      expect(_chipLabel(tester, 'right'), 'Năm 2025');
      expect(_chipLabel(tester, 'left'), 'Năm 2026');
    });
  });

  group('Màn 03 — thẻ xu hướng chi tiêu theo ngày (US3)', () {
    LineChart chartOf(WidgetTester tester) => tester.widget<LineChart>(
      find.byKey(const ValueKey('report-compare-trend')),
    );

    testWidgets('có LineChart 2 đường + chú giải khớp nhãn hai chip', (
      tester,
    ) async {
      await _pump(tester, _seededRepo());

      expect(find.text('Xu hướng chi tiêu theo ngày'), findsOneWidget);
      final lines = chartOf(tester).data.lineBarsData;
      expect(lines, hasLength(2));
      // Kỳ trái **nét liền** teal; kỳ phải **nét đứt** xám.
      expect(lines[0].color, SoraColors.light.tealOnNeutral);
      expect(lines[0].dashArray, isNull);
      expect(lines[1].color, SoraColors.light.tabInactive);
      expect(lines[1].dashArray, [4, 3]);
      expect(lines[0].dotData.show, isFalse);
      // Chú giải = nhãn hai kỳ (đã tính ở nhóm chip: mỗi nhãn 2 chỗ).
      expect(find.text('Tháng 3/2026'), findsNWidgets(2));
      expect(find.text('Tháng 2/2026'), findsNWidgets(2));
    });

    testWidgets('số điểm mỗi đường = số ngày kỳ đó (không kéo dài)', (
      tester,
    ) async {
      await _pump(tester, _seededRepo());

      final lines = chartOf(tester).data.lineBarsData;
      expect(lines[0].spots, hasLength(31)); // T3/2026
      expect(lines[1].spots, hasLength(28)); // T2/2026 — dừng ở ngày 28
      expect(lines[0].spots.first.x, 1); // trục hoành = ngày trong kỳ
      expect(lines[0].spots.last.x, 31);
      // Ngày 10/3 có 12.300.000 ⇒ điểm thứ 10 = đúng số tiền **của ngày đó**.
      expect(lines[0].spots[9].y, 12300000);
      expect(lines[0].spots[8].y, 0);
    });

    testWidgets('kỳ Ngày vẫn vẽ được (mỗi kỳ 1 điểm)', (tester) async {
      await _pump(
        tester,
        FakeWalletRepository.withCategories(
          transactions: [
            _expense(1, 300000, DateTime(2026, 3, 15), categoryId: 1),
            _expense(2, 100000, DateTime(2026, 3, 14), categoryId: 1),
          ],
          categoriesSeed: [_cat(1, 'Ăn uống')],
        ),
        period: ReportPeriod.day,
      );

      final lines = chartOf(tester).data.lineBarsData;
      expect(lines[0].spots, hasLength(1)); // 15/03/2026 — 300.000
      expect(lines[0].spots.single.y, 300000);
      expect(lines[1].spots, hasLength(1)); // 14/03/2026 — 100.000
      expect(lines[1].spots.single.y, 100000);
      expect(tester.takeException(), isNull);
    });
  });

  group('Màn 03 — thẻ Nhận xét (US4)', () {
    String insightOf(WidgetTester tester) => tester
        .widget<Text>(
          find
              .descendant(
                of: find.byKey(const ValueKey('report-compare-insight')),
                matching: find.byType(Text),
              )
              .last,
        )
        .data!;

    testWidgets('có thẻ Nhận xét, câu khớp tầng thuần (chi tăng + danh mục)', (
      tester,
    ) async {
      await _pump(tester, _seededRepo());

      expect(
        find.byKey(const ValueKey('report-compare-insight')),
        findsOneWidget,
      );
      expect(find.text('Nhận xét'), findsOneWidget);
      // T3 chi 12,3 vs T2 10,7 ⇒ +15%; Ăn uống tăng ⇒ nêu tên **cha**.
      expect(
        insightOf(tester),
        'Bạn chi nhiều hơn kỳ trước 15%. '
        'Chủ yếu do danh mục Ăn uống tăng mạnh.',
      );
    });

    testWidgets('chi giảm ⇒ câu "chi ít hơn"', (tester) async {
      await _pump(
        tester,
        FakeWalletRepository.withCategories(
          transactions: [
            _expense(1, 800000, DateTime(2026, 3, 10), categoryId: 1),
            _expense(2, 1000000, DateTime(2026, 2, 10), categoryId: 1),
          ],
          categoriesSeed: [_cat(1, 'Ăn uống')],
        ),
      );

      expect(insightOf(tester), startsWith('Bạn chi ít hơn kỳ trước 20%.'));
    });

    testWidgets('danh mục tăng là danh mục CON ⇒ câu nêu tên CHA', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeWalletRepository.withCategories(
          transactions: [
            _expense(1, 500000, DateTime(2026, 3, 10), categoryId: 2),
            _expense(2, 100000, DateTime(2026, 2, 10), categoryId: 2),
          ],
          categoriesSeed: [
            _cat(1, 'Ăn uống'),
            Category(
              id: 2,
              name: 'Cà phê',
              type: CategoryType.expense,
              icon: 'restaurant',
              color: 0xFF0F6E56,
              parentId: 1,
            ),
          ],
        ),
      );

      expect(insightOf(tester), contains('danh mục Ăn uống tăng mạnh.'));
      expect(insightOf(tester), isNot(contains('Cà phê')));
    });

    testWidgets('kỳ đối chiếu không có chi tiêu ⇒ câu nêu số tiền, không %', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeWalletRepository.withCategories(
          transactions: [
            _income(1, 900000, DateTime(2026, 2, 10)),
            _expense(2, 12300000, DateTime(2026, 3, 10), categoryId: 1),
          ],
          categoriesSeed: [_cat(1, 'Ăn uống')],
        ),
      );

      expect(insightOf(tester), startsWith('Kỳ này bạn chi 12.300.000 đ'));
      expect(insightOf(tester), isNot(contains('%')));
    });

    testWidgets('ca English ⇒ câu nhận xét dịch được (tham số có tên)', (
      tester,
    ) async {
      useEnglish();
      await _pump(tester, _seededRepo());

      expect(find.text('Insight'), findsOneWidget);
      expect(
        insightOf(tester),
        'You spent 15% more than the previous period. '
        'Mostly driven by a sharp rise in Food & Drink.',
      );
      expect(find.text('Nhận xét'), findsNothing);
    });
  });

  group('Màn 03 — trạng thái rỗng hai mức (US5)', () {
    testWidgets('cả hai kỳ rỗng ⇒ thông điệp rỗng, KHÔNG vẽ 3 thẻ', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeWalletRepository.withCategories(
          categoriesSeed: [_cat(1, 'Ăn uống')],
        ),
      );

      expect(
        find.byKey(const ValueKey('report-compare-empty')),
        findsOneWidget,
      );
      expect(
        find.text('Chưa có giao dịch nào trong hai kỳ này'),
        findsOneWidget,
      );
      expect(find.byType(LineChart), findsNothing);
      expect(
        find.byKey(const ValueKey('report-compare-insight')),
        findsNothing,
      );
      expect(find.text('Thu nhập'), findsNothing);
      // Vẫn còn lối đổi chế độ đối chiếu (FR-017).
      expect(
        find.byKey(const ValueKey('report-compare-chip-left')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('report-compare-chip-right')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('report-compare-swap')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('kỳ chỉ có chuyển khoản ⇒ coi như rỗng', (tester) async {
      await _pump(
        tester,
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
              date: DateTime(2026, 2, 11),
              transferGroupId: 1,
            ),
          ],
          categoriesSeed: [_cat(1, 'Ăn uống')],
        ),
      );

      expect(
        find.byKey(const ValueKey('report-compare-empty')),
        findsOneWidget,
      );
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets(
      'kỳ đối chiếu rỗng riêng ⇒ ghi chú thay badge, không NaN/▲ 0%',
      (tester) async {
        await _pump(
          tester,
          FakeWalletRepository.withCategories(
            transactions: [
              _income(1, 900000, DateTime(2026, 3, 5)),
              _expense(2, 12300000, DateTime(2026, 3, 10), categoryId: 1),
            ],
            categoriesSeed: [_cat(1, 'Ăn uống')],
          ),
        );

        // Cả hai chỉ số (Thu, Chi) đều không có kỳ đối chiếu ⇒ 2 ghi chú.
        expect(
          find.text('Kỳ đối chiếu không có dữ liệu để so sánh'),
          findsNWidgets(2),
        );
        expect(
          _badgeText(tester, 'expense'),
          'Kỳ đối chiếu không có dữ liệu để so sánh',
        );
        expect(find.textContaining('NaN'), findsNothing);
        expect(find.textContaining('∞'), findsNothing);
        expect(find.textContaining('0%'), findsNothing);
        // Cột kỳ đối chiếu cao 0 (không vẽ cột) nhưng thẻ vẫn có cặp cột.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('cả hai kỳ không có chi tiêu (chỉ Thu) ⇒ thẻ xu hướng ghi chú', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeWalletRepository.withCategories(
          transactions: [
            _income(1, 18500000, DateTime(2026, 3, 5)),
            _income(2, 17100000, DateTime(2026, 2, 5)),
          ],
          categoriesSeed: [_cat(1, 'Ăn uống')],
        ),
      );

      expect(find.byType(LineChart), findsNothing);
      expect(find.text('Chưa có chi tiêu nào trong kỳ này'), findsOneWidget);
      // Thẻ Thu nhập vẫn có badge bình thường (đánh giá theo **từng chỉ số**).
      expect(_badgeText(tester, 'income'), '▲ 8%');
      expect(find.text('Hai kỳ đều chưa có chi tiêu.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
