import 'package:flutter/material.dart';

import '../date_label.dart';
import 'transaction.dart';

/// View-model thuần cho màn danh sách giao dịch (PBI 9) — gộp cặp transfer,
/// nhóm ngày & thống kê tháng. Không đọc DB, không state: nhận dữ liệu + `now`,
/// trả mô hình bất biến — test deterministic (research R3/R4).

/// Một dòng hiển thị (sau khi đã gộp 2 vế transfer thành 1 — FR-007).
class TxnRow {
  const TxnRow({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.sortId,
    this.detailTransactionId,
    this.detailGroupId,
  });

  final TxnType type;

  /// Tiêu đề dòng: tên danh mục (thu/chi), rỗng → [TxnType.label];
  /// chuyển khoản luôn `'Chuyển khoản'`.
  final String title;

  /// Dòng phụ: thu/chi = `'Ví'` hoặc `'Ví · ghi chú'`; chuyển khoản =
  /// `'ví nguồn → ví đích'`. Giao dịch không ghi chú → không dấu phân cách.
  final String subtitle;

  /// Thu/chi giữ nguyên dấu (dương/âm) — màn chọn màu/dấu theo [type];
  /// transfer & adjustment lưu **giá trị dương** (hiển thị trung tính không dấu).
  final int amount;

  /// Ngày giờ dòng — quyết định nhóm ngày & thứ tự.
  final DateTime date;

  /// Khóa thứ tự ổn định khi trùng ngày giờ (mỗi giao dịch đúng 1 lần — SC-004).
  final int sortId;

  /// Định danh mở màn chi tiết giao dịch (PBI 10, R2) — **đúng 1 trong 2 khác
  /// null**: dòng thường/adjustment/vế lẻ → [detailTransactionId] = id bút toán;
  /// dòng transfer đã gộp → [detailGroupId] = `transfer_group_id` (màn tìm đủ 2
  /// vế). Dòng dựng tay ở test không truyền → null (không dùng ref).
  final int? detailTransactionId;
  final int? detailGroupId;
}

/// Một nhóm ngày trong danh sách: nhãn [header] + các dòng sắp mới nhất trước.
class DayGroup {
  const DayGroup({
    required this.day,
    required this.header,
    required this.rows,
  });

  final DateTime day;
  final String header;
  final List<TxnRow> rows;
}

/// Thống kê "Thu/Chi tháng này" (FR-002/003/008) — cả hai đều **dương** để hiển
/// thị; giao dịch transfer & adjustment không tính.
class MonthStat {
  const MonthStat({this.incomeTotal = 0, this.expenseTotal = 0});

  final int incomeTotal;
  final int expenseTotal;
}

/// Gộp 2 vế `type=transfer` chung [Transaction.transferGroupId] thành 1 dòng
/// "Chuyển khoản" — vế âm = ví nguồn, vế dương = ví đích (FR-007, R2).
/// Vế lẻ (group thiếu cặp — dữ liệu bất thường) → dòng trung tính fallback,
/// không crash; giao dịch không phải cặp transfer giữ nguyên.
/// [walletName] map id → tên ví (đọc qua `loadAll()` kể cả ví ẩn).
List<TxnRow> buildDisplayRows(
  List<Transaction> transactions,
  Map<int, String> walletName,
) {
  final rows = <TxnRow>[];
  final byGroup = <int, List<Transaction>>{};
  for (final t in transactions) {
    final group = t.transferGroupId;
    if (t.type == TxnType.transfer && group != null) {
      byGroup.putIfAbsent(group, () => []).add(t);
    }
  }

  final consumed = <int>{};
  for (final legs in byGroup.values) {
    Transaction? source;
    Transaction? dest;
    for (final leg in legs) {
      if (leg.amount < 0) source ??= leg;
      if (leg.amount > 0) dest ??= leg;
    }
    if (source == null || dest == null) continue; // vế lẻ → xử như dòng thường.
    consumed.add(source.id);
    consumed.add(dest.id);
    rows.add(
      TxnRow(
        type: TxnType.transfer,
        title: 'Chuyển khoản',
        subtitle: '${walletName[source.walletId] ?? 'Ví'}'
            ' → ${walletName[dest.walletId] ?? 'Ví'}',
        amount: source.amount.abs(),
        date: source.date,
        sortId: source.id < dest.id ? source.id : dest.id,
        // Dòng transfer đã gộp chỉ còn biết nhóm → mang ref theo group để màn
        // chi tiết tìm đủ 2 vế nguồn/đích (R2/FR-006).
        detailGroupId: source.transferGroupId,
      ),
    );
  }

  for (final t in transactions) {
    if (consumed.contains(t.id)) continue;
    rows.add(_plainRow(t, walletName));
  }
  return rows;
}

TxnRow _plainRow(Transaction t, Map<int, String> walletName) {
  final wallet = walletName[t.walletId] ?? '';
  final note = t.note;
  final subtitle = note.isEmpty
      ? wallet
      : (wallet.isEmpty ? note : '$wallet · $note');
  final neutral = t.type == TxnType.transfer || t.type == TxnType.adjustment;
  return TxnRow(
    type: t.type,
    title: t.category.isEmpty ? t.typeLabel : t.category,
    subtitle: subtitle,
    amount: neutral ? t.amount.abs() : t.amount,
    date: t.date,
    sortId: t.id,
    // Dòng thường mở chi tiết đúng bút toán theo id (R2/FR-001).
    detailTransactionId: t.id,
  );
}

/// Nhóm [rows] theo ngày lịch, ngày mới nhất ở trên (FR-004); mỗi nhóm mang
/// [DayGroup.header] qua [formatDayGroupHeader]. Trong nhóm xếp giảm dần theo
/// ngày giờ, trùng ngày giờ ổn định theo [TxnRow.sortId] tăng (SC-004).
List<DayGroup> groupDisplayRows(List<TxnRow> rows, {DateTime? now}) {
  if (rows.isEmpty) return const [];
  final sorted = [...rows]..sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return a.sortId.compareTo(b.sortId);
  });

  final byDay = <DateTime, List<TxnRow>>{};
  for (final row in sorted) {
    final day = DateTime(row.date.year, row.date.month, row.date.day);
    byDay.putIfAbsent(day, () => []).add(row);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days)
      DayGroup(
        day: day,
        header: formatDayGroupHeader(day, now: now),
        rows: byDay[day]!,
      ),
  ];
}

/// Tổng thu / tổng chi (dương) của các dòng thu/chi có ngày trong
/// `[ngày 1 tháng dương lịch của now, now]` — gồm ví ẩn, loại trừ transfer &
/// adjustment bằng [TxnType] (FR-003/008, R3). Giao dịch đặt lịch tương lai
/// cùng tháng không tính (cận trên = thời điểm xem).
MonthStat monthlyIncomeExpense(List<Transaction> transactions, DateTime now) {
  final firstOfMonth = DateTime(now.year, now.month, 1);
  var income = 0;
  var expense = 0;
  for (final t in transactions) {
    if (t.type == TxnType.transfer || t.type == TxnType.adjustment) continue;
    if (t.date.isBefore(firstOfMonth) || t.date.isAfter(now)) continue;
    if (t.type == TxnType.income) {
      income += t.amount;
    } else if (t.type == TxnType.expense) {
      expense += t.amount.abs();
    }
  }
  return MonthStat(incomeTotal: income, expenseTotal: expense);
}

/// Glyph mặc định tạm cho bubble danh mục (research R5) — vài danh mục mẫu quen
/// thuộc + fallback chung. `transactions.category` chỉ là chữ (chưa có bảng
/// `categories`/icon/màu); **tầng presentation của màn**, gỡ khi module Danh mục
/// cấp icon/màu thật (quyết định mở #1).
IconData categoryGlyph(String category) {
  const map = <String, IconData>{
    'Ăn uống': Icons.restaurant,
    'Di chuyển': Icons.directions_car,
    'Xăng xe': Icons.local_gas_station,
    'Mua sắm': Icons.shopping_bag,
    'Lương': Icons.payments,
    'Thu nhập khác': Icons.attach_money,
    'Bán đồ cũ': Icons.sell,
    'Hóa đơn': Icons.receipt,
    'Y tế': Icons.medical_services,
    'Giáo dục': Icons.school,
  };
  return map[category] ?? Icons.receipt_long;
}
