import 'wallet.dart';

/// Bất biến ví mặc định — hàm thuần trên [List<Wallet>] (FR-007/008):
/// tại một thời điểm, trong số ví **hoạt động** có đúng 1 ví mang cờ mặc định.
/// Controller gọi các hàm này rồi ghi kết quả qua repository.

/// Số ví đang hoạt động (không ẩn).
int activeWalletCount(List<Wallet> wallets) =>
    wallets.where((w) => !w.isHidden).length;

/// Có ít nhất một ví hoạt động đang mang cờ mặc định không.
bool hasActiveDefault(List<Wallet> wallets) =>
    wallets.any((w) => !w.isHidden && w.isDefault);

/// Ví hoạt động đang mang cờ mặc định (nếu có) — đối tượng bị dời cờ.
Wallet? currentActiveDefault(List<Wallet> wallets) {
  for (final w in walletsByDisplayOrder(wallets)) {
    if (!w.isHidden && w.isDefault) return w;
  }
  return null;
}

/// Ví hoạt động đầu tiên theo thứ tự hiển thị, trừ [excludeId] — ứng viên tự
/// chọn làm mặc định thay thế khi tắt cờ của ví default (research Q6).
Wallet? firstActiveByDisplayOrder(List<Wallet> wallets, {int? excludeId}) {
  for (final w in walletsByDisplayOrder(wallets)) {
    if (!w.isHidden && w.id != excludeId) return w;
  }
  return null;
}

/// Quyết định cờ mặc định khi TẠO ví mới [draft] (acceptance 3/4).
/// - Không còn ví hoạt động nào → ép ví mới làm default.
/// - Ngược lại: theo [wantDefault]; nếu muốn default mà đang có ví default khác
///   → trả thêm [demote] (ví default cũ cần gỡ cờ) giữ bất biến đúng-1.
({Wallet draft, Wallet? demote}) resolveOnCreate(
  List<Wallet> wallets,
  Wallet draft, {
  required bool wantDefault,
}) {
  if (activeWalletCount(wallets) == 0) {
    return (draft: draft.copyWith(isDefault: true), demote: null);
  }
  if (!wantDefault) {
    return (draft: draft.copyWith(isDefault: false), demote: null);
  }
  final old = currentActiveDefault(wallets);
  final demote = (old != null && old.id != draft.id) ? old : null;
  return (draft: draft.copyWith(isDefault: true), demote: demote);
}

/// Quyết định cờ mặc định khi SỬA ví thành [edited] (FR-008, SC-005).
/// [wasDefault] = ví trước sửa đang mang cờ default? [wantDefault] = người dùng
/// bật cờ? Trả về:
/// - [edited]: ví sau khi chốt cờ (luôn có).
/// - [demote]: ví default cũ phải gỡ cờ (khi bật default cho ví khác).
/// - [promote]: ví thay thế được tự chọn làm default (khi tắt cờ default).
({Wallet edited, Wallet? demote, Wallet? promote}) resolveOnUpdate(
  List<Wallet> wallets,
  Wallet edited, {
  required bool wasDefault,
  required bool wantDefault,
}) {
  // Bật default cho ví đang không default → dời cờ khỏi ví default cũ.
  if (!wasDefault && wantDefault) {
    final old = currentActiveDefault(wallets);
    final demote = (old != null && old.id != edited.id) ? old : null;
    return (
      edited: edited.copyWith(isDefault: true),
      demote: demote,
      promote: null,
    );
  }
  // Tắt cờ của ví default.
  if (wasDefault && !wantDefault) {
    // Chỉ còn mình nó hoạt động → chặn tắt, giữ default (FR-008).
    if (activeWalletCount(wallets) <= 1) {
      return (
        edited: edited.copyWith(isDefault: true),
        demote: null,
        promote: null,
      );
    }
    final replacement = firstActiveByDisplayOrder(wallets, excludeId: edited.id);
    return (
      edited: edited.copyWith(isDefault: false),
      demote: null,
      promote: replacement,
    );
  }
  // Giữ trạng thái cờ như cũ — không đổi gì thêm.
  return (
    edited: edited.copyWith(isDefault: wasDefault),
    demote: null,
    promote: null,
  );
}
