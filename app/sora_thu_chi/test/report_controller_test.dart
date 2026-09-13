import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/report/report_controller.dart';
import 'package:sora_thu_chi/core/report/report_view.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

import 'fakes/fake_wallet_repository.dart';

/// Đếm số lần đọc DB — khẳng định đổi kỳ **không** đọc lại (SC-007).
class _CountingRepo extends FakeWalletRepository {
  _CountingRepo({super.transactions, super.categoriesSeed})
    : super.withCategories();

  int loadCount = 0;
  bool shouldThrow = false;

  @override
  Future<List<Transaction>> allTransactions() async {
    loadCount++;
    if (shouldThrow) throw StateError('lỗi đọc giả lập');
    return super.allTransactions();
  }
}

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

void main() {
  final categories = [
    Category(
      id: 1,
      name: 'Ăn uống',
      type: CategoryType.expense,
      icon: 'restaurant',
      color: 0xFF0F6E56,
    ),
  ];

  _CountingRepo repo({bool withData = true}) => _CountingRepo(
    transactions: withData
        ? [
            _expense(1, 300000, DateTime(2026, 3, 10), categoryId: 1),
            _income(2, 900000, DateTime(2026, 3, 5)),
            _expense(3, 100000, DateTime(2026, 1, 20), categoryId: 1),
          ]
        : const [],
    categoriesSeed: categories,
  );

  tearDown(Get.reset);

  test('load() → có data, kỳ mặc định là Tháng', () async {
    final controller = ReportController(repo());
    expect(controller.period.value, ReportPeriod.month);
    expect(controller.data.value, isNull);

    await controller.load(now: DateTime(2026, 3, 15));

    expect(controller.data.value, isNotNull);
    expect(controller.data.value!.period, ReportPeriod.month);
    expect(controller.data.value!.income, 900000);
    expect(controller.data.value!.expense, 300000);
  });

  test('setPeriod đổi số liệu nhưng KHÔNG đọc lại DB (SC-007)', () async {
    final r = repo();
    final controller = ReportController(r);
    await controller.load(now: DateTime(2026, 3, 15));
    expect(r.loadCount, 1);

    controller.setPeriod(ReportPeriod.year);

    expect(controller.period.value, ReportPeriod.year);
    expect(controller.data.value!.period, ReportPeriod.year);
    expect(controller.data.value!.expense, 400000); // gồm cả giao dịch tháng 1
    expect(r.loadCount, 1); // không đọc DB lần nữa
  });

  test('load(now:) đổi mốc ⇒ kỳ tính lại theo mốc mới', () async {
    final controller = ReportController(repo());
    await controller.load(now: DateTime(2026, 3, 15));
    expect(controller.data.value!.range.start, DateTime(2026, 3, 1));

    await controller.load(now: DateTime(2026, 4, 2));

    expect(controller.data.value!.range.start, DateTime(2026, 4, 1));
    expect(controller.data.value!.expense, 0);
  });

  test('lỗi đọc ⇒ error được set, data cũ giữ nguyên', () async {
    final r = repo();
    final controller = ReportController(r);
    await controller.load(now: DateTime(2026, 3, 15));
    final previous = controller.data.value;

    r.shouldThrow = true;
    await controller.load(now: DateTime(2026, 3, 15));

    expect(controller.error.value, 'Không đọc được dữ liệu báo cáo.');
    expect(controller.data.value, same(previous));
  });

  test(
    'nạp lại hai lần với dữ liệu đổi ⇒ data phản ánh số mới (SC-008)',
    () async {
      final r = repo();
      final controller = ReportController(r);
      await controller.load(now: DateTime(2026, 3, 15));

      await r.addTransaction(
        walletId: 1,
        type: TxnType.expense,
        amount: 700000,
        category: categories.first,
        date: DateTime(2026, 3, 20),
      );
      await controller.load(now: DateTime(2026, 3, 15));

      expect(controller.data.value!.expense, 1000000);
    },
  );

  group('So sánh kỳ (PBI 26) — seam controller', () {
    test('comparison() trả null khi CHƯA load()', () {
      final controller = ReportController(repo());
      expect(
        controller.comparison(
          leftAnchor: DateTime(2026, 3, 15),
          rightAnchor: DateTime(2026, 2, 15),
        ),
        isNull,
      );
    });

    test('comparison() khớp kết quả gọi thẳng hàm thuần cùng tham số', () async {
      final controller = ReportController(repo());
      await controller.load(now: DateTime(2026, 3, 15));

      final fromController = controller.comparison(
        leftAnchor: DateTime(2026, 3, 15),
        rightAnchor: DateTime(2026, 2, 15),
      )!;
      final fromPure = reportComparison(
        transactions: await repo().allTransactions(),
        categories: categories,
        period: ReportPeriod.month,
        leftAnchor: DateTime(2026, 3, 15),
        rightAnchor: DateTime(2026, 2, 15),
      );

      expect(fromController.left.expense, fromPure.left.expense);
      expect(fromController.right.expense, fromPure.right.expense);
      expect(fromController.left.income, fromPure.left.income);
      expect(fromController.insight, fromPure.insight);
      // Kỳ chính T3/2026: chi 300.000, thu 900.000; kỳ đối chiếu T2/2026 rỗng.
      expect(fromController.left.expense, 300000);
      expect(fromController.right.expense, 0);
      expect(fromController.expenseDelta.percent, isNull);
      expect(fromController.isEmpty, isFalse);
    });

    test('hasAnyTxnBefore: chỉ Thu/Chi, mốc biên không tính', () async {
      final controller = ReportController(
        _CountingRepo(
          transactions: [
            _expense(1, 300000, DateTime(2026, 1, 20), categoryId: 1),
            _income(2, 900000, DateTime(2026, 3, 5)),
            Transaction(
              id: 3,
              walletId: 1,
              type: TxnType.transfer,
              amount: -500000,
              date: DateTime(2025, 12, 1),
              transferGroupId: 3,
            ),
            Transaction(
              id: 4,
              walletId: 1,
              type: TxnType.adjustment,
              amount: 50000,
              date: DateTime(2025, 12, 1),
            ),
          ],
          categoriesSeed: categories,
        ),
      );
      expect(controller.hasAnyTxnBefore(DateTime(2026, 1, 1)), isFalse);

      await controller.load(now: DateTime(2026, 3, 15));

      // transfer/adjustment (12/2025) không tính ⇒ chưa có gì trước 1/1/2026.
      expect(controller.hasAnyTxnBefore(DateTime(2026, 1, 1)), isFalse);
      // Thu 5/3 không nằm **trước** 5/3 (mốc biên) nhưng chi 20/1 thì có.
      expect(controller.hasAnyTxnBefore(DateTime(2026, 3, 5)), isTrue);
      expect(controller.hasAnyTxnBefore(DateTime(2026, 3, 6)), isTrue);
      expect(controller.hasAnyTxnBefore(DateTime(2026, 4, 1)), isTrue);
    });
  });
}
