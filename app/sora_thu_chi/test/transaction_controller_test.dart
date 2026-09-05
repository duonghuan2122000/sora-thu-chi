import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_controller.dart';

import 'fakes/fake_wallet_repository.dart';

/// Seed mẫu với ngày cố định 10/09 — mọi dòng nằm trong tháng 9 để số card
/// tròn trịa 15.000.000 / 2.455.000 (không phụ thuộc ngày chạy thật).
final _now = DateTime(2026, 9, 10, 9, 30);

FakeWalletRepository _seededRepo() => FakeWalletRepository(null, _now);

void main() {
  group('TransactionController — nạp & tái nạp màn Giao dịch', () {
    test('load() sinh DayGroups + MonthStat khớp seed 11 dòng (gộp transfer)', () async {
      final controller = TransactionController(_seededRepo());
      // Không spinner khi chưa chọn tab (màn offstage từ boot — R6).
      expect(controller.isLoading.value, isFalse);

      await controller.load(now: _now);

      expect(controller.isLoading.value, isFalse);
      expect(controller.error.value, isNull);
      final view = controller.data.value!;

      // 5 nhóm ngày (cách 0/1/2/3/5 ngày), header mới nhất đúng.
      expect(view.groups.length, 5);
      expect(view.groups.first.header, 'HÔM NAY - 10/09/2026');

      // 11 dòng seed − 1 (2 vế chuyển gộp) = 10 dòng hiển thị.
      final rowCount = view.groups.fold<int>(0, (sum, g) => sum + g.rows.length);
      expect(rowCount, 10);

      // Thu/Chi tháng đúng tổng; chuyển khoản không tính (FR-003/008).
      expect(view.stat.incomeTotal, 15000000);
      expect(view.stat.expenseTotal, 2455000);

      // Cặp transfer → đúng 1 dòng "Vietcombank → Momo" |700.000|.
      final transfers = view.groups
          .expand((g) => g.rows)
          .where((r) => r.type == TxnType.transfer)
          .toList();
      expect(transfers.length, 1);
      expect(transfers.single.title, 'Chuyển khoản');
      expect(transfers.single.subtitle, 'Vietcombank → Momo');
      expect(transfers.single.amount, 700000);
    });

    test('load() lần 2 sau khi performTransfer → có dòng chuyển mới, card không đổi', () async {
      final repo = _seededRepo();
      final controller = TransactionController(repo);
      await controller.load(now: _now);
      final before = controller.data.value!;

      // Ghi thêm 1 chuyển khoản ở nơi khác (PBI 8) rồi quay lại tab → load.
      await repo.performTransfer(
        fromWalletId: 2,
        toWalletId: 4,
        amount: 200000,
        date: _now,
        note: 'Nạp ví điện tử',
      );
      await controller.load(now: _now);

      final after = controller.data.value!;
      final rowsAfter = after.groups
          .expand((g) => g.rows)
          .toList();
      expect(rowsAfter.length, before.groups.fold<int>(0, (s, g) => s + g.rows.length) + 1);
      final newTransfer = rowsAfter
          .where((r) => r.type == TxnType.transfer && r.amount == 200000)
          .toList();
      expect(newTransfer.length, 1);
      expect(newTransfer.single.subtitle, 'Vietcombank → Momo');
      // Thống kê tháng không đổi — chuyển khoản không tính (FR-003/011).
      expect(after.stat.incomeTotal, before.stat.incomeTotal);
      expect(after.stat.expenseTotal, before.stat.expenseTotal);
    });

    test('repo lỗi → trạng thái lỗi; retry() thành công → nội dung (R8)', () async {
      final repo = _FlakyRepo();
      final controller = TransactionController(repo);

      await controller.load(now: _now);

      expect(controller.error.value, isNotNull);
      expect(controller.data.value, isNull);

      repo.fail = false;
      await controller.retry();

      expect(controller.error.value, isNull);
      expect(controller.data.value, isNotNull);
    });
  });
}

class _FlakyRepo extends FakeWalletRepository {
  _FlakyRepo() : super(null, _now);

  bool fail = true;

  @override
  Future<List<Transaction>> allTransactions() async {
    if (fail) throw Exception('Lỗi đọc giao dịch.');
    return super.allTransactions();
  }
}
