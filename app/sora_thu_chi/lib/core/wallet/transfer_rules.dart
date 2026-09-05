import 'wallet.dart';

/// Bộ lọc ví nguồn/đích của khoản chuyển — hàm thuần trên [List<Wallet>]
/// (đúng tinh thần [wallet_rules.dart] PBI 7), spec FR-003/011/018/019.
/// Không chạm repository/UI để unit test thẳng không cần bơm.

/// Các ví hợp lệ làm **đích** khi chuyển từ ví [sourceId]: đang hoạt động
/// (không ẩn), cùng `currency` ví nguồn, không phải thẻ tín dụng, khác ví
/// nguồn. Không tìm thấy ví nguồn → danh sách rỗng (FR-019).
List<Wallet> eligibleDestinations(List<Wallet> wallets, int sourceId) {
  Wallet? source;
  for (final w in wallets) {
    if (w.id == sourceId) {
      source = w;
      break;
    }
  }
  if (source == null) return const [];
  final src = source;
  return wallets
      .where(
        (w) =>
            !w.isHidden &&
            w.id != sourceId &&
            w.type != WalletType.credit &&
            w.currency == src.currency,
      )
      .toList();
}

/// Ví [w] làm được **nguồn** chuyển tiền hay không — mọi loại trừ thẻ tín dụng
/// (FR-018). Ví ẩn đang đứng ở màn chi tiết vẫn chuyển được (spec §Giả định).
bool canTransferFromWallet(Wallet w) => w.type != WalletType.credit;

/// Còn ví đích hợp lệ nào cho nguồn [sourceId] không (FR-019) — báo "chưa có
/// ví đích" khi rỗng (spec biên: chỉ 1 ví hoạt động / chỉ còn thẻ tín dụng).
bool hasEligibleDestination(List<Wallet> wallets, int sourceId) =>
    eligibleDestinations(wallets, sourceId).isNotEmpty;
