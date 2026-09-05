import 'package:get/get.dart';

import '../../data/wallet_repository.dart';
import 'transaction_list.dart';

/// Dữ liệu màn Giao dịch sau một lần [TransactionController.load] — bất biến.
class TransactionView {
  const TransactionView({required this.groups, required this.stat});

  final List<DayGroup> groups;
  final MonthStat stat;
}

/// Nạp toàn bộ giao dịch + tên ví (mọi ví kể cả ẩn) rồi sinh mô hình hiển thị
/// (nhóm ngày + thống kê tháng) qua hàm thuần [transaction_list.dart].
/// Nạp lại mỗi lần người dùng chọn tab Giao dịch (R6/FR-011) — không nạp ở
/// initState (IndexedStack build sẵn 4 màn từ boot, R6).
class TransactionController extends GetxController {
  TransactionController(this._repository);

  final WalletRepository _repository;

  /// Đang nạp (lần đầu — màn hiện spinner). Khởi đầu `false` vì màn build sẵn
  /// offstage từ boot (IndexedStack): nếu true sẵn thì spinner chạy ẩn vô hạn.
  /// Chỉ bật khi AppShell chọn tab → [load] (R6). Có dữ liệu rồi thì [data] ưu tiên.
  final RxBool isLoading = false.obs;

  /// Thông báo lỗi đọc; null = chưa lỗi.
  final RxnString error = RxnString();

  /// Dữ liệu sau lần nạp thành công; null = chưa có (lỗi/lần đầu).
  final Rxn<TransactionView> data = Rxn<TransactionView>();

  /// [now] truyền vào để test deterministic; mặc định giờ thật khi app chạy.
  Future<void> load({DateTime? now}) async {
    isLoading.value = true;
    error.value = null;
    try {
      final transactions = await _repository.allTransactions();
      final wallets = await _repository.loadAll();
      final names = {for (final w in wallets) w.id: w.name};
      final rows = buildDisplayRows(transactions, names);
      data.value = TransactionView(
        groups: groupDisplayRows(rows, now: now),
        stat: monthlyIncomeExpense(transactions, now ?? DateTime.now()),
      );
    } catch (_) {
      // Lỗi đọc — giữ data cũ (nếu có); chưa có thì màn hiện lỗi + Thử lại (R8).
      error.value = 'Không đọc được dữ liệu giao dịch.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Nạp lại từ màn lỗi.
  Future<void> retry() => load();
}
