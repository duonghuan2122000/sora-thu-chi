import 'dart:async';

import 'package:get/get.dart';

import '../../data/notification_deps.dart';
import '../../data/wallet_repository.dart';
import '../transaction/transaction.dart';
import 'wallet.dart';
import 'wallet_rules.dart';

/// Giữ cache ví reactive (RxList) — nguồn sự thật cho màn danh sách/chi tiết.
/// Mọi thao tác tạo/sửa đều gọi [wallet_rules] giữ bất biến "đúng 1 ví mặc định",
/// ghi qua repository rồi reload cache (FR-013).
class WalletController extends GetxController {
  WalletController(this._repository);

  final WalletRepository _repository;

  final RxList<Wallet> _wallets = <Wallet>[].obs;
  final RxBool _loading = true.obs;

  /// Cache ví hiện tại (thứ tự đọc từ repo).
  List<Wallet> get wallets => _wallets;

  /// Đang nạp lần đầu — màn danh sách hiện spinner, tránh nháy empty state.
  bool get isLoading => _loading.value;

  /// Nạp cache từ repository; đảm bảo có đúng 1 ví mặc định nếu còn ví hoạt động.
  Future<void> init() async {
    _loading.value = true;
    try {
      await _reload();
      await _ensureDefaultIfMissing();
    } finally {
      _loading.value = false;
    }
  }

  /// Tạo ví mới. [wantDefault] = người dùng bật "Đặt làm ví mặc định".
  /// Ví đầu tiên luôn tự thành mặc định (acceptance 3); bật cho ví mới khi đã có
  /// default khác → dời cờ (acceptance 4). Trả ví đã lưu (có id).
  Future<Wallet> create(Wallet draft, {bool wantDefault = false}) async {
    final current = List<Wallet>.from(_wallets);
    final nextSortOrder =
        current.fold<int>(0, (max, w) => w.sortOrder > max ? w.sortOrder : max) +
        1;
    final seeded = draft.copyWith(
      sortOrder: nextSortOrder,
      initialBalance: draft.initialBalanceValue,
    );
    final decision = resolveOnCreate(current, seeded, wantDefault: wantDefault);

    if (decision.demote != null) {
      await _repository.update(decision.demote!.copyWith(isDefault: false));
    }
    final created = await _repository.insert(decision.draft);
    await _reload();
    return created;
  }

  /// Sửa ví thành [updated] (đã mang giá trị mới của các trường sửa được).
  /// [wantDefault] = cờ mặc định sau khi lưu (mặc định giữ nguyên trạng thái cũ);
  /// rules tự chọn ví thay thế khi tắt cờ default (FR-008) và chặn tắt khi chỉ
  /// còn một ví hoạt động. Trả ví đã lưu.
  Future<Wallet> updateWallet(
    Wallet updated, {
    bool? wantDefault,
  }) async {
    final current = List<Wallet>.from(_wallets);
    Wallet existing;
    try {
      existing = current.firstWhere((w) => w.id == updated.id);
    } on StateError {
      // Ví không còn trong cache (đã ẩn/xóa ngoài phiên) — không sửa được.
      return updated;
    }

    final decision = resolveOnUpdate(
      current,
      updated,
      wasDefault: existing.isDefault,
      wantDefault: wantDefault ?? existing.isDefault,
    );

    // Ghi các ví đổi cờ trước, rồi ví chính — cuối cùng luôn đúng 1 default.
    if (decision.demote != null) {
      await _repository.update(decision.demote!.copyWith(isDefault: false));
    }
    if (decision.promote != null && decision.promote!.id != decision.edited.id) {
      await _repository.update(decision.promote!.copyWith(isDefault: true));
    }
    final saved = await _repository.update(decision.edited);
    await _reload();
    return saved;
  }

  /// Ghi atomic một lần chuyển tiền rồi reload cache (số dư cả 2 ví mới —
  /// FR-014). [amount] > 0; validation nghiệp vụ do màn chuyển ([transfer_rules])
  /// đảm nhận. Ném lỗi nếu ghi thất bại — UI báo, giữ dữ liệu đã nhập (FR-015).
  Future<void> transfer({
    required int fromId,
    required int toId,
    required int amount,
    required DateTime date,
    String note = '',
  }) async {
    await _repository.performTransfer(
      fromWalletId: fromId,
      toWalletId: toId,
      amount: amount,
      date: date,
      note: note,
    );
    // Thông báo đẩy (PBI 31, FR-011): chuyển khoản **không** tính vào ngân sách
    // nhưng **có** tính là "hôm nay đã ghi giao dịch" — engine chỉ đọc, chạy
    // fire-and-forget và tự nuốt lỗi (FR-023/FR-024).
    unawaited(ensureNotificationEngine().onTransactionSaved(at: date, type: TxnType.transfer));
    await _reload();
  }

  /// Sửa atomic một giao dịch Chuyển khoản đã có (PBI 39) rồi reload cache —
  /// mirror [transfer] nhưng ghi đè 2 vế hiện có thay vì tạo mới.
  Future<void> updateTransfer({
    required int transferGroupId,
    required int fromId,
    required int toId,
    required int amount,
    required DateTime date,
    String note = '',
  }) async {
    await _repository.updateTransfer(
      transferGroupId: transferGroupId,
      fromWalletId: fromId,
      toWalletId: toId,
      amount: amount,
      date: date,
      note: note,
    );
    unawaited(ensureNotificationEngine().onTransactionSaved(at: date, type: TxnType.transfer));
    await _reload();
  }

  /// Giao dịch đúng ví [walletId], mới nhất trước — façade cho màn chi tiết
  /// đọc qua controller (không đụng repository trực tiếp, FR-014).
  Future<List<Transaction>> transactionsOf(int walletId) =>
      _repository.transactionsOf(walletId);

  Future<void> _reload() async {
    _wallets.assignAll(await _repository.loadAll());
  }

  /// Nếu có ví hoạt động nhưng chưa có ví mặc định → tự chọn ví active đầu theo
  /// thứ tự hiển thị làm mặc định (giữ bất biến FR-007).
  Future<void> _ensureDefaultIfMissing() async {
    if (hasActiveDefault(_wallets) || activeWalletCount(_wallets) == 0) return;
    final replacement = firstActiveByDisplayOrder(_wallets);
    if (replacement == null) return;
    await _repository.update(replacement.copyWith(isDefault: true));
    await _reload();
  }
}
