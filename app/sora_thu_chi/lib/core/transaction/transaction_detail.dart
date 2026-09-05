import 'package:flutter/material.dart';

import 'transaction.dart';
import 'transaction_list.dart' show categoryGlyph;

/// View-model thuần cho màn chi tiết giao dịch (PBI 10) — bất biến, dựng trong
/// bộ nhớ từ [Transaction] + tên ví (R1/R9). Không đọc DB, không state.
/// Mọi trường phụ (note/tags/receiptImage/location) chỉ điền khi có dữ liệu —
/// màn ẩn hàng rỗng (FR-007).

/// Định danh đối tượng mở chi tiết — **đúng 1 trong 2 khác null** (R2):
/// [transactionId] mở 1 bút toán; [transferGroupId] mở 1 màn chuyển khoản
/// (gộp 2 vế nguồn/đích chung group).
class TransactionDetailRef {
  const TransactionDetailRef({this.transactionId, this.transferGroupId})
      : assert(
          (transactionId == null) != (transferGroupId == null),
          'Phải truyền đúng 1 trong transactionId / transferGroupId.',
        );

  final int? transactionId;
  final int? transferGroupId;
}

/// View hiển thị một màn chi tiết — [amount] là số tiền đã **abs** với
/// transfer/adjustment (trung tính), giữ dấu với thu/chi (màn tô màu/dấu theo
/// [type]). Ví: thu/chi/adjustment điền [singleWalletName]; transfer đủ 2 vế
/// điền [sourceWalletName]/[destWalletName] (FR-006).
class TransactionDetailView {
  const TransactionDetailView({
    required this.type,
    required this.summaryTitle,
    required this.summaryGlyph,
    required this.amount,
    required this.date,
    this.singleWalletName,
    this.sourceWalletName,
    this.destWalletName,
    this.note = '',
    this.tags = const [],
    this.receiptImage = '',
    this.location = '',
  });

  final TxnType type;

  /// Nhãn tóm tắt: danh mục (thu/chi, rỗng → [TxnType.label]);
  /// transfer/adjustment luôn [TxnType.label].
  final String summaryTitle;

  final IconData summaryGlyph;
  final int amount;
  final DateTime date;

  /// Tên ví: 1 hàng "Ví" (thu/chi/adjustment) hoặc 2 hàng nguồn/đích (transfer).
  final String? singleWalletName;
  final String? sourceWalletName;
  final String? destWalletName;

  final String note;
  final List<String> tags;
  final String receiptImage;
  final String location;
}

/// Dựng view chi tiết theo [ref] từ toàn bộ bút toán [all] + map tên ví
/// [walletName] (đọc qua `loadAll()` — kể cả ví ẩn, FR-011).
/// - [ref.transactionId] → tìm theo id, dựng view đơn.
/// - [ref.transferGroupId] → lọc các vế transfer chung group; vế âm = nguồn /
///   vế dương = đích; đủ 2 vế → 1 view 2 ví; nhóm thiếu vế → fallback view đơn
///   (không crash); không khớp dòng nào → trả null (màn báo trạng thái).
TransactionDetailView? buildTransactionDetail({
  required List<Transaction> all,
  required Map<int, String> walletName,
  required TransactionDetailRef ref,
}) {
  if (ref.transactionId != null) {
    for (final t in all) {
      if (t.id == ref.transactionId) return _single(t, walletName);
    }
    return null;
  }

  final groupId = ref.transferGroupId!;
  final legs = all
      .where((t) =>
          t.type == TxnType.transfer && t.transferGroupId == groupId)
      .toList();
  Transaction? source;
  Transaction? dest;
  for (final leg in legs) {
    if (leg.amount < 0) source ??= leg;
    if (leg.amount > 0) dest ??= leg;
  }
  // Đủ 2 vế → 1 view trung tính với "Ví nguồn"/"Ví đích" (FR-006/SC-005).
  if (source != null && dest != null) {
    final fallback = walletName[source.walletId] ?? 'Ví';
    final destName = walletName[dest.walletId] ?? 'Ví';
    return TransactionDetailView(
      type: TxnType.transfer,
      summaryTitle: TxnType.transfer.label,
      summaryGlyph: Icons.swap_horiz,
      amount: source.amount.abs(),
      date: source.date,
      sourceWalletName: fallback,
      destWalletName: destName,
      note: source.note,
      tags: parseTags(source.tags),
      receiptImage: source.receiptImage,
      location: source.location,
    );
  }
  // Nhóm thiếu vế → fallback view đơn của vế tìm được (không crash).
  final single = source ?? dest;
  if (single == null) return null;
  return _single(single, walletName);
}

/// Dựng view đơn cho 1 bút toán [t] — thu/chi theo danh mục; transfer
/// (vế lẻ) & adjustment trung tính không dấu (FR-004).
TransactionDetailView _single(Transaction t, Map<int, String> walletName) {
  final neutral =
      t.type == TxnType.transfer || t.type == TxnType.adjustment;
  if (neutral) {
    return TransactionDetailView(
      type: t.type,
      summaryTitle: t.typeLabel,
      summaryGlyph: t.type == TxnType.transfer
          ? Icons.swap_horiz
          : Icons.tune,
      amount: t.amount.abs(),
      date: t.date,
      singleWalletName: walletName[t.walletId] ?? 'Ví',
      note: t.note,
      tags: parseTags(t.tags),
      receiptImage: t.receiptImage,
      location: t.location,
    );
  }
  return TransactionDetailView(
    type: t.type,
    // summaryTitle/glyph: danh mục; rỗng → nhãn loại + glyph fallback.
    summaryTitle: t.category.isEmpty ? t.typeLabel : t.category,
    summaryGlyph: t.category.isEmpty ? categoryGlyph(t.typeLabel) : categoryGlyph(t.category),
    amount: t.amount,
    date: t.date,
    singleWalletName: walletName[t.walletId] ?? 'Ví',
    note: t.note,
    tags: parseTags(t.tags),
    receiptImage: t.receiptImage,
    location: t.location,
  );
}

/// Phân tích chuỗi tag thô → list: split `,`, trim, lọc rỗng (R4). Rỗng → `[]`.
List<String> parseTags(String tags) {
  if (tags.trim().isEmpty) return const [];
  return tags
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();
}
