import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_controller.dart';
import 'package:sora_thu_chi/core/transaction/transaction_filter.dart';

import 'fakes/fake_wallet_repository.dart';

/// Anchor cố định 10/09 — seed 11 dòng mẫu (TransactionSource) nằm trong tháng
/// 9; lọc danh mục "Ăn uống" (id 1, expense) khớp 3 dòng chi categoryId null
/// theo fallback tên: id 1 (−85.000), id 6 (−450.000), id 10 (−350.000).
final _now = DateTime(2026, 9, 10, 9, 30);

FakeWalletRepository _seededRepo() => FakeWalletRepository(null, _now);

/// Bộ lọc chi + danh mục Ăn uống, bỏ giới hạn ngày — summary 3 dòng.
TxnSearchFilter _eatFilter() => TxnSearchFilter.defaults(
  now: _now,
).withDateRange(DatePreset.all).copyWith(
  type: TxnTypeFilter.expense,
  categoryIds: {1},
);

void main() {
  group('TransactionController — state bộ lọc (PBI 12, R13)', () {
    test('đường không-lọc (data) không đổi khi chưa setFilter', () async {
      final controller = TransactionController(_seededRepo());
      await controller.load(now: _now);

      expect(controller.activeFilter.value, isNull);
      expect(controller.filtered.value, isNull);

      final view = controller.data.value!;
      final rowCount = view.groups.fold<int>(0, (s, g) => s + g.rows.length);
      expect(rowCount, 10); // 11 seed − 1 gộp transfer.
      expect(view.stat.incomeTotal, 15000000);
      expect(view.stat.expenseTotal, 2455000);
    });

    test('setFilter sinh filtered đúng tập/sort/summary trên cache (không đọc DB)', () async {
      final controller = TransactionController(_seededRepo());
      await controller.load(now: _now);
      final before = controller.data.value!;

      controller.setFilter(_eatFilter());

      expect(controller.activeFilter.value, isNotNull);
      final view = controller.filtered.value!;
      // Sort ngày (mặc định dateNewest) → giữ nhóm.
      final rows = view.groups!.expand((g) => g.rows).toList();
      expect(rows.length, 3);
      expect(view.summary.count, 3);
      expect(view.summary.signedTotal, -885000); // −85k −450k −350k.
      // Tập chỉ chi Ăn uống — không lọt thu/chi khác.
      expect(
        rows.map((r) => r.title).toSet(),
        {'Ăn uống'},
      );
      // Đường không-lọc giữ nguyên (không hồi quy — R13).
      expect(controller.data.value, same(before));
    });

    test('clearFilter → về null (Bỏ lọc — FR-013)', () async {
      final controller = TransactionController(_seededRepo());
      await controller.load(now: _now);
      controller.setFilter(_eatFilter());
      expect(controller.filtered.value, isNotNull);

      controller.clearFilter();

      expect(controller.activeFilter.value, isNull);
      expect(controller.filtered.value, isNull);
    });

    test('sort tiền → flatRows phẳng; sort ngày cũ → groups đảo', () async {
      final controller = TransactionController(_seededRepo());
      await controller.load(now: _now);

      controller.setFilter(_eatFilter().copyWith(sort: SortOption.amountDesc));
      final flat = controller.filtered.value!;
      expect(flat.flatRows, isNotNull);
      expect(flat.groups, isNull);
      expect(flat.flatRows!.length, 3);
      // 450.000 lớn nhất đứng đầu.
      expect(flat.flatRows!.first.amount.abs(), 450000);

      controller.setFilter(_eatFilter().copyWith(sort: SortOption.dateOldest));
      final oldest = controller.filtered.value!;
      expect(oldest.groups, isNotNull);
      expect(oldest.flatRows, isNull);
    });

    test('bộ lọc còn hiệu lực qua load() lặp lại; dữ liệu mới làm mới không nhân đôi '
        '(SC-007, bất biến 7)', () async {
      final repo = _seededRepo();
      final controller = TransactionController(repo);
      await controller.load(now: _now);
      controller.setFilter(_eatFilter());
      expect(controller.filtered.value!.summary.count, 3);

      // Ra/vào tab → load lại, bộ lọc vẫn áp dụng trên dữ liệu mới.
      await controller.load(now: _now);
      expect(controller.activeFilter.value, isNotNull);
      expect(controller.filtered.value!.summary.count, 3); // không nhân đôi.

      // Thêm 1 chi Ăn uống mới → load → view lọc thêm đúng 1 dòng.
      await repo.addTransaction(
        walletId: 2,
        type: TxnType.expense,
        amount: 20000,
        category: const Category(
          id: 1,
          name: 'Ăn uống',
          type: CategoryType.expense,
          icon: 'restaurant',
          color: 0xFF3D8C77,
        ),
        date: _now,
        note: 'Cà phê giao',
      );
      await controller.load(now: _now);

      expect(controller.filtered.value!.summary.count, 4);
      expect(controller.filtered.value!.summary.signedTotal, -905000);
      // Đường không-lọc cũng thêm đúng 1 dòng (không hồi quy load()).
      final view = controller.data.value!;
      final rows = view.groups.fold<int>(0, (s, g) => s + g.rows.length);
      expect(rows, 11);
    });
  });
}
