import 'package:get/get.dart';

import '../../data/wallet_repository.dart';
import '../category/category.dart';
import '../transaction/transaction.dart';
import 'report_view.dart';

/// Nạp dữ liệu màn Tổng quan Báo cáo **một lần** khi mở tab rồi tính mọi kỳ
/// trên cùng danh sách trong RAM (SC-007) — đổi kỳ **không** đọc DB.
/// Bám khuôn [TransactionController]: màn build sẵn offstage trong `IndexedStack`
/// nên `isLoading` khởi đầu `false`, việc nạp do `AppShell` gọi khi chọn tab.
class ReportController extends GetxController {
  ReportController(this._repository);

  final WalletRepository _repository;

  /// Kỳ đang chọn trên segmented control — mặc định **Tháng** (FR-002).
  final Rx<ReportPeriod> period = ReportPeriod.month.obs;

  /// Số liệu đã dựng; null = chưa nạp được lần nào.
  final Rxn<ReportView> data = Rxn<ReportView>();

  /// Đang nạp lần đầu (màn hiện spinner) — xem chú thích lớp.
  final RxBool isLoading = false.obs;

  final RxnString error = RxnString();

  List<Transaction> _transactions = const [];
  List<Category> _categories = const [];
  late DateTime _now = DateTime.now();
  bool _loaded = false;

  /// Mốc "hôm nay" của lần nạp gần nhất — drill-down dùng lại đúng kỳ đang xem.
  DateTime get now => _now;

  /// [now] bơm được để test deterministic; mặc định giờ thật khi app chạy.
  Future<void> load({DateTime? now}) async {
    isLoading.value = true;
    error.value = null;
    try {
      _now = now ?? DateTime.now();
      final transactions = await _repository.allTransactions();
      final categories = await _repository.categoriesIncludingHidden(
        type: CategoryType.expense,
      );
      _transactions = transactions;
      _categories = categories;
      _loaded = true;
      _rebuild();
    } catch (_) {
      // Giữ data cũ (nếu có) — màn hiện lỗi + nút "Thử lại".
      error.value = 'Không đọc được dữ liệu báo cáo.';
    } finally {
      isLoading.value = false;
    }
  }

  /// Đổi kỳ — dựng lại số liệu từ dữ liệu **đã nạp trong RAM** (FR-003/SC-007).
  void setPeriod(ReportPeriod value) {
    period.value = value;
    if (_loaded) _rebuild();
  }

  /// Số liệu màn Chi tiết theo danh mục (PBI 23) — dựng lại từ bản chụp RAM mỗi
  /// lần gọi; màn 02 chỉ mở được từ màn Tổng quan đã có dữ liệu (research R1).
  ReportCategoryDetail? categoryDetail() {
    if (!_loaded) return null;
    return reportCategoryDetail(
      transactions: _transactions,
      categories: _categories,
      period: period.value,
      now: _now,
    );
  }

  void _rebuild() {
    data.value = buildReportView(
      transactions: _transactions,
      categories: _categories,
      period: period.value,
      now: _now,
    );
  }
}
