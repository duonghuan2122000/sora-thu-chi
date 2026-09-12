import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/budget/budget.dart';
import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/budget_form_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';
import 'package:sora_thu_chi/theme/sora_colors.dart';

import 'fakes/fake_wallet_repository.dart';

final _now = DateTime(2026, 9, 12, 10);

Budget _budget({
  int id = 1,
  int categoryId = 2,
  int amount = 3000000,
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

/// Đẩy màn Thêm/Sửa từ route trung gian để bắt được kết quả `pop(true)`.
Future<void> _openForm(
  WidgetTester tester,
  WalletRepository repository, {
  Budget? budget,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => BudgetFormScreen(
                      budget: budget,
                      repository: repository,
                      now: _now,
                    ),
                  ),
                );
                // Ghi lại kết quả pop để test khẳng định (null = không pop true).
                popped = saved;
              },
              child: const Text('mở form'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mở form'));
  await tester.pumpAndSettle();
}

/// Giá trị `pop(...)` của màn form — gán trong `_openForm`.
bool? popped;

Future<void> _pickCategory(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(const ValueKey('budget-category-row')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('budget-save')));
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

void main() {
  setUp(() => popped = null);

  group('BudgetFormScreen — mặc định theo mockup 02 (FR-009/012/013/014)', () {
    testWidgets('Theo danh mục chọn sẵn, Tháng chọn sẵn, 2 công tắc, 2 hàng chờ',
        (tester) async {
      await _openForm(tester, FakeWalletRepository.withCategories());

      expect(find.text('Thêm ngân sách'), findsOneWidget);
      expect(find.text('PHẠM VI NGÂN SÁCH'), findsOneWidget);
      expect(find.text('DANH MỤC'), findsOneWidget);
      expect(find.text('Chọn danh mục'), findsOneWidget);
      expect(find.text('SỐ TIỀN GIỚI HẠN'), findsOneWidget);
      expect(find.text('CHU KỲ'), findsOneWidget);
      expect(find.text('Ví áp dụng'), findsOneWidget);
      expect(find.text('Tất cả ví'), findsOneWidget);
      expect(find.text('Ngưỡng cảnh báo'), findsOneWidget);
      expect(find.text('80% và 100%'), findsOneWidget);

      // Phạm vi: "Theo danh mục" đang chọn (teal), "Tổng cộng" mờ.
      final selected = tester.widget<Text>(find.text('Theo danh mục'));
      final other = tester.widget<Text>(find.text('Tổng cộng'));
      expect(selected.style!.color, AppColors.white);
      expect(other.style!.color, SoraColors.light.tabInactive);

      // Chu kỳ: mặc định Tháng.
      final monthly = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('budget-period-monthly')),
          matching: find.byType(Container),
        ),
      );
      expect((monthly.decoration as BoxDecoration).color, AppColors.teal);

      // Công tắc: lặp lại BẬT (thật), cộng dồn TẮT + vô hiệu.
      final recurring = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('budget-recurring-switch')),
      );
      expect(recurring.value, isTrue);
      expect(recurring.onChanged, isNotNull);
      final rollover = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('budget-rollover-switch')),
      );
      expect(rollover.value, isFalse);
      expect(rollover.onChanged, isNull);

      // Không có bottom nav của shell (FR-008).
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('BudgetFormScreen — ô số tiền định dạng nghìn (FR-011, R12)', () {
    testWidgets('gõ 3000000 → ô hiện 3.000.000', (tester) async {
      await _openForm(tester, FakeWalletRepository.withCategories());

      await tester.enterText(
        find.byKey(const ValueKey('budget-amount')),
        '3000000',
      );
      await tester.pump();

      expect(find.text('3.000.000'), findsOneWidget);
    });

    testWidgets('gõ thêm số → phân tách lại, con trỏ về cuối', (tester) async {
      await _openForm(tester, FakeWalletRepository.withCategories());

      await tester.enterText(
        find.byKey(const ValueKey('budget-amount')),
        '1500',
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('budget-amount')),
        '1500000',
      );
      await tester.pump();

      expect(find.text('1.500.000'), findsOneWidget);
    });
  });

  group('BudgetFormScreen — luồng lưu (FR-015/FR-016)', () {
    testWidgets('thiếu danh mục → SnackBar, không ghi repo', (tester) async {
      final repo = FakeWalletRepository.withCategories();
      await _openForm(tester, repo);

      await tester.enterText(
        find.byKey(const ValueKey('budget-amount')),
        '3000000',
      );
      await _save(tester);

      expect(find.text('Vui lòng chọn danh mục.'), findsOneWidget);
      expect(find.byType(BudgetFormScreen), findsOneWidget);
      expect(await repo.budgets(), isEmpty);
    });

    testWidgets('tiền 0 / để trống → SnackBar số tiền, không ghi repo',
        (tester) async {
      final repo = FakeWalletRepository.withCategories();
      await _openForm(tester, repo);
      await _pickCategory(tester, 'Di chuyển');

      await _save(tester);

      expect(find.text('Vui lòng nhập số tiền lớn hơn 0.'), findsOneWidget);
      expect(await repo.budgets(), isEmpty);
    });

    testWidgets('hợp lệ → ghi repo + pop(true), đủ 6 trường', (tester) async {
      final repo = FakeWalletRepository.withCategories();
      await _openForm(tester, repo);

      await _pickCategory(tester, 'Di chuyển');
      await tester.enterText(
        find.byKey(const ValueKey('budget-amount')),
        '3000000',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('budget-period-yearly')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('budget-recurring-switch')));
      await tester.pump();
      await _save(tester);

      final saved = (await repo.budgets()).single;
      expect(saved.categoryId, 2); // Di chuyển
      expect(saved.amount, 3000000);
      expect(saved.period, BudgetPeriod.yearly);
      expect(saved.isRecurring, isFalse);
      expect(saved.startDate, _now);
      expect(popped, isTrue);
      expect(find.byType(BudgetFormScreen), findsNothing);
    });

    testWidgets('trùng danh mục + chu kỳ → SnackBar "Đã có ngân sách…", không ghi',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        budgetsSeed: [_budget(id: 1, categoryId: 2, amount: 1000000)],
      );
      await _openForm(tester, repo);

      await _pickCategory(tester, 'Di chuyển');
      await tester.enterText(
        find.byKey(const ValueKey('budget-amount')),
        '2000000',
      );
      await tester.pump();
      await _save(tester);

      expect(
        find.text(
          'Đã có ngân sách cho danh mục này trong kỳ. Hãy sửa ngân sách đang có.',
        ),
        findsOneWidget,
      );
      expect((await repo.budgets()).length, 1);
      expect((await repo.budgets()).single.amount, 1000000);
      expect(find.byType(BudgetFormScreen), findsOneWidget);
    });
  });

  group('BudgetFormScreen — chế độ Sửa (FR-017/FR-018)', () {
    testWidgets('tiêu đề "Sửa ngân sách" + điền sẵn danh mục/số tiền/chu kỳ/lặp lại',
        (tester) async {
      final repo = FakeWalletRepository.withCategories(
        budgetsSeed: [
          _budget(
            id: 3,
            categoryId: 4, // Hóa đơn
            amount: 2500000,
            period: BudgetPeriod.weekly,
            isRecurring: false,
            startDate: DateTime(2026, 8, 20),
          ),
        ],
      );
      await _openForm(tester, repo, budget: _budget(
        id: 3,
        categoryId: 4,
        amount: 2500000,
        period: BudgetPeriod.weekly,
        isRecurring: false,
        startDate: DateTime(2026, 8, 20),
      ));

      expect(find.text('Sửa ngân sách'), findsOneWidget);
      expect(find.text('Hóa đơn'), findsOneWidget);
      expect(find.text('2.500.000'), findsOneWidget);
      final weekly = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const ValueKey('budget-period-weekly')),
          matching: find.byType(Container),
        ),
      );
      expect((weekly.decoration as BoxDecoration).color, AppColors.teal);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('budget-recurring-switch')),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('sửa số tiền → updateBudget theo id, giữ startDate cũ',
        (tester) async {
      final existing = _budget(id: 3, categoryId: 4, amount: 2500000);
      final repo = FakeWalletRepository.withCategories(
        budgetsSeed: [existing],
      );
      await _openForm(tester, repo, budget: existing);

      await tester.enterText(
        find.byKey(const ValueKey('budget-amount')),
        '4500000',
      );
      await tester.pump();
      await _save(tester);

      final saved = (await repo.budgets()).single;
      expect(saved.id, 3);
      expect(saved.amount, 4500000);
      expect(saved.startDate, DateTime(2026, 9, 1)); // giữ nguyên, không theo `now`
      expect(popped, isTrue);
    });

    testWidgets('sửa chính nó không bị chặn chồng lấn', (tester) async {
      final existing = _budget(id: 3, categoryId: 4, amount: 2500000);
      final repo = FakeWalletRepository.withCategories(
        budgetsSeed: [existing],
      );
      await _openForm(tester, repo, budget: existing);

      await _save(tester);

      expect(popped, isTrue);
      expect((await repo.budgets()).single.amount, 2500000);
    });
  });

  group('BudgetFormScreen — English (FR-023)', () {
    testWidgets('nhãn tĩnh hiển thị tiếng Anh', (tester) async {
      useEnglish();
      await _openForm(tester, FakeWalletRepository.withCategories());

      expect(find.text('Add budget'), findsOneWidget);
      expect(find.text('BUDGET SCOPE'), findsOneWidget);
      expect(find.text('By category'), findsOneWidget);
      expect(find.text('CATEGORIES'), findsOneWidget);
      expect(find.text('LIMIT AMOUNT'), findsOneWidget);
      expect(find.text('PERIOD'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
      expect(find.text('Applies to wallets'), findsOneWidget);
      expect(find.text('All wallets'), findsOneWidget);
      expect(find.text('Auto-repeat every period'), findsOneWidget);
      expect(find.text('Roll over unused amount'), findsOneWidget);
      expect(find.text('Alert thresholds'), findsOneWidget);
      expect(find.text('80% and 100%'), findsOneWidget);
      expect(find.text('Save budget'), findsOneWidget);
      // Bắt lỗi QA emulator đã gặp: hàng giá trị thiếu `.tr` → sót "và".
      expect(find.text('80% và 100%'), findsNothing);
      expect(find.text('Thêm ngân sách'), findsNothing);
    });
  });
}
