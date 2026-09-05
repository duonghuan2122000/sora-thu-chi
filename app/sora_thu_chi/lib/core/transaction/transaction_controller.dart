import 'package:get/get.dart';

import '../../data/wallet_repository.dart';
import '../category/category.dart';
import 'transaction.dart';
import 'transaction_filter.dart';
import 'transaction_list.dart';

/// Dữ liệu màn Giao dịch sau một lần [TransactionController.load] — bất biến.
class TransactionView {
  const TransactionView({required this.groups, required this.stat});

  final List<DayGroup> groups;
  final MonthStat stat;
}

/// View phụ khi đang áp dụng bộ lọc — sort ngày giữ nhóm ngày ([groups]) hoặc
/// sort tiền **phẳng** ([flatRows]); [summary] chung (R3/R4, data-model).
class FilteredTxView {
  const FilteredTxView({this.groups, this.flatRows, required this.summary});

  /// Khác null khi sort theo ngày (`dateNewest`/`dateOldest`).
  final List<DayGroup>? groups;

  /// Khác null khi sort theo tiền (`amountAsc`/`amountDesc`).
  final List<TxnRow>? flatRows;

  final FilteredTxSummary summary;
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

  /// Bộ lọc đang áp dụng; null = không lọc (hành vi PBI 9). Sống qua ra/vào
  /// tab — mỗi lần [load] nạp dữ liệu mới rồi dựng lại [filtered] (SC-007, R13).
  final Rxn<TxnSearchFilter> activeFilter = Rxn<TxnSearchFilter>();

  /// View đã lọc tương ứng [activeFilter]; null khi không lọc.
  final Rxn<FilteredTxView> filtered = Rxn<FilteredTxView>();

  List<Transaction> _all = const [];
  Map<int, String> _names = const {};
  List<Category> _categories = const [];
  late DateTime _now = DateTime.now();

  /// Anchor thời gian của lần nạp gần nhất — bộ lọc nhạy thời gian (preset)
  /// & nhãn ngày nhóm tính theo đây (data-model bất biến 8).
  DateTime get now => _now;

  /// [now] truyền vào để test deterministic; mặc định giờ thật khi app chạy.
  Future<void> load({DateTime? now}) async {
    isLoading.value = true;
    error.value = null;
    try {
      _now = now ?? DateTime.now();
      final transactions = await _repository.allTransactions();
      final wallets = await _repository.loadAll();
      _all = transactions;
      _names = {for (final w in wallets) w.id: w.name};
      // Danh mục đang hoạt động (cả thu + chi) — cache để mở rộng cha→con &
      // fallback tên khi dựng view đã lọc (không đọc DB lại từng thao tác — R1).
      _categories = [
        ...await _repository.categories(type: CategoryType.income),
        ...await _repository.categories(type: CategoryType.expense),
      ];
      data.value = TransactionView(
        groups: groupDisplayRows(
          buildDisplayRows(_all, _names),
          now: _now,
        ),
        stat: monthlyIncomeExpense(_all, _now),
      );
      _rebuildFiltered();
    } catch (_) {
      // Lỗi đọc — giữ data cũ (nếu có); chưa có thì màn hiện lỗi + Thử lại (R8).
      error.value = 'Không đọc được dữ liệu giao dịch.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Áp dụng bộ lọc [f] — tính lại view trên cache, không đọc DB (R6).
  void setFilter(TxnSearchFilter f) {
    activeFilter.value = f;
    _rebuildFiltered();
  }

  /// Bỏ lọc → về toàn bộ (FR-013).
  void clearFilter() {
    activeFilter.value = null;
    filtered.value = null;
  }

  /// Nạp lại từ màn lỗi.
  Future<void> retry() => load();

  void _rebuildFiltered() {
    final filter = activeFilter.value;
    if (filter == null) {
      filtered.value = null;
      return;
    }
    final matched = filterTransactions(_all, filter, _categories);
    final rows = buildDisplayRows(matched, _names);
    final summary = summarizeRows(rows);
    final isDateSort =
        filter.sort == SortOption.dateNewest ||
        filter.sort == SortOption.dateOldest;
    filtered.value = FilteredTxView(
      groups: isDateSort
          ? orderDateGroups(groupDisplayRows(rows, now: _now), filter.sort)
          : null,
      flatRows: isDateSort
          ? null
          : sortAmountRows(rows, filter.sort),
      summary: summary,
    );
  }
}
