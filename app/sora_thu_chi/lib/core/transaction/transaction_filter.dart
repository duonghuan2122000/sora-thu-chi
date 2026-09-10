import 'package:get/get.dart';

import '../category/category.dart';
import 'transaction.dart';
import 'transaction_list.dart';

/// Module **thuần** lọc & sắp giao dịch cho màn "Tìm kiếm & Lọc" (PBI 12).
/// Không đọc DB/state — nhận dữ liệu + điều kiện, trả kết quả; mọi luật AND /
/// group-keep / summary / sort được test deterministic bằng tham số bơm (R1/R11).

/// Loại chip trên màn lọc — 4 nút đúng mockup `05`. **Không có** `adjustment`
/// (chỉ xuất hiện dưới `all` — R12).
enum TxnTypeFilter { all, income, expense, transfer }

extension TxnTypeFilterLabelX on TxnTypeFilter {
  String get label => switch (this) {
        TxnTypeFilter.all => 'Tất cả'.tr,
        TxnTypeFilter.income => 'Thu'.tr,
        TxnTypeFilter.expense => 'Chi'.tr,
        TxnTypeFilter.transfer => 'Chuyển khoản'.tr,
      };
}

/// Thứ tự tập kết quả — sort ngày giữ nhóm; sort tiền **phẳng** (R4).
enum SortOption { dateNewest, dateOldest, amountAsc, amountDesc }

extension SortOptionLabelX on SortOption {
  String get label => switch (this) {
        SortOption.dateNewest => 'Ngày mới nhất'.tr,
        SortOption.dateOldest => 'Ngày cũ nhất'.tr,
        SortOption.amountAsc => 'Số tiền tăng dần'.tr,
        SortOption.amountDesc => 'Số tiền giảm dần'.tr,
      };
}

/// Khoảng thời gian preset; `custom` = 2 ngày do người dùng chọn (R11).
enum DatePreset { today, thisWeek, thisMonth, all, custom }

extension DatePresetLabelX on DatePreset {
  String get label => switch (this) {
        DatePreset.today => 'Hôm nay'.tr,
        DatePreset.thisWeek => 'Tuần này'.tr,
        DatePreset.thisMonth => 'Tháng này'.tr,
        DatePreset.all => 'Toàn bộ'.tr,
        DatePreset.custom => 'Tùy chọn'.tr,
      };
}

/// Giải [preset] theo ngày lịch của [now] anchor → cặp `[start 00:00, dateEnd
/// hết ngày)`; `all` & `custom` (đã chọn cụ thể) trả `start/end` không từ `now`.
({DateTime? start, DateTime? end}) resolveDatePreset(
  DatePreset preset,
  DateTime now, {
  DateTime? customStart,
  DateTime? customEnd,
}) {
  switch (preset) {
    case DatePreset.today:
      final today = DateTime(now.year, now.month, now.day);
      return (start: today, end: today);
    case DatePreset.thisWeek:
      final today = DateTime(now.year, now.month, now.day);
      final monday = today.subtract(Duration(days: today.weekday - 1));
      return (start: monday, end: monday.add(const Duration(days: 6)));
    case DatePreset.thisMonth:
      return (
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      );
    case DatePreset.all:
      return (start: null, end: null);
    case DatePreset.custom:
      return (start: customStart, end: customEnd);
  }
}

/// Điều kiện tìm kiếm & lọc — **bất biến** (bản nháp màn lọc & bộ lọc đang áp
/// dụng dùng chung). Mang [now] anchor để preset `today/thisWeek/thisMonth` và
/// [reset] tự giải lại đúng "thời điểm" (deterministic test — data-model bất biến 8).
class TxnSearchFilter {
  const TxnSearchFilter({
    required this.now,
    this.keyword = '',
    this.type = TxnTypeFilter.all,
    this.datePreset = DatePreset.thisMonth,
    this.dateStart,
    this.dateEnd,
    this.categoryIds = const {},
    this.walletId,
    this.amountMin,
    this.amountMax,
    this.sort = SortOption.dateNewest,
  });

  /// Bộ lọc mặc định (FR-005/014): Tháng này theo [now] anchor.
  factory TxnSearchFilter.defaults({DateTime? now}) {
    final anchor = now ?? DateTime.now();
    final range = resolveDatePreset(DatePreset.thisMonth, anchor);
    return TxnSearchFilter(
      now: anchor,
      datePreset: DatePreset.thisMonth,
      dateStart: range.start,
      dateEnd: range.end,
    );
  }

  /// Anchor thời gian — dùng giải preset & [reset].
  final DateTime now;

  /// Từ khóa — so khớp note/category/tags, bỏ dấu tiếng Việt (FR-002).
  final String keyword;

  /// Chip loại (FR-004).
  final TxnTypeFilter type;

  /// Preset khoảng thời gian đã chọn (để mở lại màn lọc hiện đúng lựa chọn).
  final DatePreset datePreset;

  /// Ngày bắt đầu / kết thúc **theo ngày lịch** (00:00 & hết ngày `dateEnd`);
  /// null = không giới hạn đầu đó.
  final DateTime? dateStart;
  final DateTime? dateEnd;

  /// Id danh mục đã chọn (cha lẫn con — mở rộng con khi khớp, R7). Rỗng = bỏ qua.
  final Set<int> categoryIds;

  /// null = tất cả ví (FR-007).
  final int? walletId;

  /// Biên độ `abs(amount)` bao gồm biên; null = bỏ giới hạn đầu đó (FR-008).
  final int? amountMin;
  final int? amountMax;

  /// Thứ tự tập kết quả (FR-009).
  final SortOption sort;

  /// Có điều kiện nào đang chặn tập (khác "không giới hạn") — dùng nhận diện
  /// bộ lọc có tác dụng; bộ lọc mặc định Tháng này → `true` (đã giới hạn tháng).
  bool get hasAnyCondition =>
      keyword.trim().isNotEmpty ||
      type != TxnTypeFilter.all ||
      categoryIds.isNotEmpty ||
      walletId != null ||
      amountMin != null ||
      amountMax != null ||
      dateStart != null ||
      dateEnd != null;

  /// Về mặc định FR-014 (cùng [now] anchor để preset "Tháng này" đúng thời điểm).
  TxnSearchFilter reset() => TxnSearchFilter.defaults(now: now);

  /// Đổi khoảng thời gian: preset không `custom` → giải từ [now]; `custom` lấy
  /// [customStart]/[customEnd] (2 date picker đã chặn start ≤ end — FR-008).
  TxnSearchFilter withDateRange(
    DatePreset preset, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final range = resolveDatePreset(
      preset,
      now,
      customStart: customStart,
      customEnd: customEnd,
    );
    // Dựng trực tiếp (không qua copyWith — null cần được gán rõ để bỏ giới hạn).
    return TxnSearchFilter(
      now: now,
      keyword: keyword,
      type: type,
      datePreset: preset,
      dateStart: range.start,
      dateEnd: range.end,
      categoryIds: categoryIds,
      walletId: walletId,
      amountMin: amountMin,
      amountMax: amountMax,
      sort: sort,
    );
  }

  /// Đổi ví chọn (null = Tất cả) — dựng trực tiếp để cho phép bỏ giới hạn.
  TxnSearchFilter withWalletId(int? id) => TxnSearchFilter(
    now: now,
    keyword: keyword,
    type: type,
    datePreset: datePreset,
    dateStart: dateStart,
    dateEnd: dateEnd,
    categoryIds: categoryIds,
    walletId: id,
    amountMin: amountMin,
    amountMax: amountMax,
    sort: sort,
  );

  /// Đổi khoảng tiền (null = bỏ giới hạn đầu đó — FR-008/R10).
  TxnSearchFilter withAmountBounds(int? min, int? max) => TxnSearchFilter(
    now: now,
    keyword: keyword,
    type: type,
    datePreset: datePreset,
    dateStart: dateStart,
    dateEnd: dateEnd,
    categoryIds: categoryIds,
    walletId: walletId,
    amountMin: min,
    amountMax: max,
    sort: sort,
  );

  TxnSearchFilter copyWith({
    String? keyword,
    TxnTypeFilter? type,
    DatePreset? datePreset,
    DateTime? dateStart,
    DateTime? dateEnd,
    Set<int>? categoryIds,
    int? walletId,
    int? amountMin,
    int? amountMax,
    SortOption? sort,
  }) => TxnSearchFilter(
    now: now,
    keyword: keyword ?? this.keyword,
    type: type ?? this.type,
    datePreset: datePreset ?? this.datePreset,
    dateStart: dateStart ?? this.dateStart,
    dateEnd: dateEnd ?? this.dateEnd,
    categoryIds: categoryIds ?? this.categoryIds,
    walletId: walletId ?? this.walletId,
    amountMin: amountMin ?? this.amountMin,
    amountMax: amountMax ?? this.amountMax,
    sort: sort ?? this.sort,
  );

  @override
  bool operator ==(Object other) =>
      other is TxnSearchFilter &&
      other.keyword == keyword &&
      other.type == type &&
      other.datePreset == datePreset &&
      other.dateStart == dateStart &&
      other.dateEnd == dateEnd &&
      other.walletId == walletId &&
      other.amountMin == amountMin &&
      other.amountMax == amountMax &&
      other.sort == sort &&
      _sameCategory(other.categoryIds, categoryIds);

  @override
  int get hashCode => Object.hash(
    keyword,
    type,
    datePreset,
    dateStart,
    dateEnd,
    walletId,
    amountMin,
    amountMax,
    sort,
  );

  static bool _sameCategory(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    for (final id in a) {
      if (!b.contains(id)) return false;
    }
    return true;
  }
}

/// Kết quả thống kê tập khớp (R3): [count] = số **dòng hiển thị** sau gộp
/// transfer; [signedTotal] = Σ thu − Σ chi (transfer/adjustment trong count,
/// **ngoài** total — FR-011).
class FilteredTxSummary {
  const FilteredTxSummary({required this.count, required this.signedTotal});

  final int count;
  final int signedTotal;

  FilteredTxSummary operator +(FilteredTxSummary other) => FilteredTxSummary(
    count: count + other.count,
    signedTotal: signedTotal + other.signedTotal,
  );
}

/// Đếm/tổng theo các [rows] **đã gộp** (đầu vào từ [buildDisplayRows]) — count
/// khớp đúng số dòng màn danh sách vẽ, total chỉ thu/chi (R3/FR-011).
FilteredTxSummary summarizeRows(List<TxnRow> rows) {
  var total = 0;
  for (final row in rows) {
    if (row.type == TxnType.income) {
      total += row.amount;
    } else if (row.type == TxnType.expense) {
      total += row.amount; // đã âm sẵn (thu dương/chi âm — PBI 9).
    }
  }
  return FilteredTxSummary(count: rows.length, signedTotal: total);
}

/// Lọc [all] theo [filter] (phép hội AND — FR-010, data-model §Luật khớp).
/// [catalog] = danh mục đang hoạt động (cha & con, cả thu + chi) để mở rộng cha
/// → con & fallback tên cho dòng `categoryId == null` (R7). Giữ **cả 2 vế**
/// transfer cùng nhóm khi một vế khớp (group-keep — R2, SC-010).
List<Transaction> filterTransactions(
  List<Transaction> all,
  TxnSearchFilter filter,
  List<Category> catalog,
) {
  if (all.isEmpty) return const [];
  final effective = _effectiveCategoryIds(filter.categoryIds, catalog);
  final effectiveNames = _normalizedNames(effective, catalog);

  final keep = List<bool>.generate(
    all.length,
    (i) => _matches(all[i], filter, effective, effectiveNames),
  );

  // Group-keep: dòng transfer giữ nếu chính nó khớp hoặc một vế cùng nhóm khớp.
  final groupHit = <int, bool>{};
  for (var i = 0; i < all.length; i++) {
    final t = all[i];
    final group = t.transferGroupId;
    if (keep[i] && t.type == TxnType.transfer && group != null) {
      groupHit[group] = true;
    }
  }

  final result = <Transaction>[];
  for (var i = 0; i < all.length; i++) {
    final t = all[i];
    if (keep[i]) {
      result.add(t);
    } else {
      final group = t.transferGroupId;
      if (t.type == TxnType.transfer &&
          group != null &&
          groupHit[group] == true) {
        result.add(t);
      }
    }
  }
  return result;
}

bool _matches(
  Transaction t,
  TxnSearchFilter f,
  Set<int> effectiveCategoryIds,
  Set<String> effectiveNames,
) {
  if (f.type != TxnTypeFilter.all) {
    final wanted = switch (f.type) {
      TxnTypeFilter.income => TxnType.income,
      TxnTypeFilter.expense => TxnType.expense,
      TxnTypeFilter.transfer => TxnType.transfer,
      TxnTypeFilter.all => null,
    };
    if (t.type != wanted) return false;
  }

  // Danh mục: không áp dụng khi chip là Chuyển khoản (transfer không danh mục).
  if (f.categoryIds.isNotEmpty && f.type != TxnTypeFilter.transfer) {
    final byId = t.categoryId != null && effectiveCategoryIds.contains(t.categoryId);
    final byName = !byId &&
        t.categoryId == null &&
        effectiveNames.contains(normalizeSearch(t.category));
    if (!byId && !byName) return false;
  }

  if (f.walletId != null && t.walletId != f.walletId) return false;

  final absAmount = t.amount.abs();
  if (f.amountMin != null && absAmount < f.amountMin!) return false;
  if (f.amountMax != null && absAmount > f.amountMax!) return false;

  if (f.dateStart != null && t.date.isBefore(f.dateStart!)) return false;
  if (f.dateEnd != null) {
    final endExclusive = DateTime(
      f.dateEnd!.year,
      f.dateEnd!.month,
      f.dateEnd!.day + 1,
    );
    if (!t.date.isBefore(endExclusive)) return false;
  }

  final keyword = f.keyword.trim();
  if (keyword.isNotEmpty) {
    final haystack = normalizeSearch('${t.note} ${t.category} ${t.tags}');
    if (!haystack.contains(normalizeSearch(keyword))) return false;
  }
  return true;
}

/// Tập id hiệu lực: id đã chọn + toàn bộ **con cháu** của cha được chọn
/// (descendant closure trên [catalog]) — chọn cha tự gộp con (R7/SC-008).
Set<int> _effectiveCategoryIds(Set<int> chosen, List<Category> catalog) {
  if (chosen.isEmpty || catalog.isEmpty) return chosen;
  final childByParent = <int, List<int>>{};
  for (final c in catalog) {
    final p = c.parentId;
    if (p != null) childByParent.putIfAbsent(p, () => []).add(c.id);
  }
  final result = <int>{...chosen};
  final queue = [...chosen];
  while (queue.isNotEmpty) {
    final id = queue.removeLast();
    for (final child in childByParent[id] ?? const <int>[]) {
      if (result.add(child)) queue.add(child);
    }
  }
  return result;
}

/// Tên (đã bỏ dấu) của các danh mục trong [effective] — dùng fallback so khớp
/// dòng `categoryId == null` theo chữ [Transaction.category] (R7).
Set<String> _normalizedNames(Set<int> effective, List<Category> catalog) {
  if (effective.isEmpty) return const {};
  final names = <String>{};
  for (final c in catalog) {
    if (effective.contains(c.id)) names.add(normalizeSearch(c.name));
  }
  return names;
}

/// Chuẩn hóa chuỗi tìm kiếm: lowercase + bỏ dấu tiếng Việt (bảng ánh xạ, không
/// thêm package — R9). Dùng chung cho từ khóa & chuỗi cần tìm.
String normalizeSearch(String input) {
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (var i = 0; i < lower.length; i++) {
    buffer.write(_diacriticMap[lower.codeUnitAt(i)] ?? lower[i]);
  }
  return buffer.toString();
}

/// Bảng bỏ dấu: khóa = mã code-unit (0..255) của ký tự thường tiếng Việt,
/// giá trị = ký tự gốc không dấu. `đ` → `d`; i/y giữ nguyên.
const Map<int, String> _diacriticMap = {
  0xE0: 'a', 0xE1: 'a', 0xE2: 'a', 0xE3: 'a', 0xE4: 'a', 0xE5: 'a', // àáâãäå
  0xE7: 'c', // ç
  0xE8: 'e', 0xE9: 'e', 0xEA: 'e', 0xEB: 'e', // èéêë
  0xEC: 'i', 0xED: 'i', 0xEE: 'i', 0xEF: 'i', // ìíîï
  0xF2: 'o', 0xF3: 'o', 0xF4: 'o', 0xF5: 'o', 0xF6: 'o', // òóôõö
  0xF9: 'u', 0xFA: 'u', 0xFB: 'u', 0xFC: 'u', // ùúûü
  0x169: 'u', // ũ
  0xFD: 'y', 0xFF: 'y', // ý ÿ
  0x103: 'a', // ă
  0x1A1: 'o', // ơ
  0x1B0: 'u', // ư
  0x1EA1: 'a', 0x1EA3: 'a', 0x1EA5: 'a', 0x1EA7: 'a', 0x1EA9: 'a',
  0x1EAB: 'a', 0x1EAD: 'a', 0x1EAF: 'a', 0x1EB1: 'a', 0x1EB3: 'a',
  0x1EB5: 'a', 0x1EB7: 'a', // ạ ả ấ ầ ẩ ẫ ậ ắ ằ ẳ ẵ ặ (a family)
  0x111: 'd', // đ
  0x1EB9: 'e', 0x1EBB: 'e', 0x1EBD: 'e', 0x1EBF: 'e', 0x1EC1: 'e',
  0x1EC3: 'e', 0x1EC5: 'e', 0x1EC7: 'e', // ẹ ẻ ẽ ế ề ể ễ ệ
  0x129: 'i', // ĩ
  0x1EC9: 'i', 0x1ECB: 'i', // ỉ ị
  0x1ECD: 'o', 0x1ECF: 'o', 0x1ED1: 'o', 0x1ED3: 'o', 0x1ED5: 'o',
  0x1ED7: 'o', 0x1ED9: 'o', 0x1EDB: 'o', 0x1EDD: 'o', 0x1EDF: 'o',
  0x1EE1: 'o', 0x1EE3: 'o', // ọ ỏ ố ồ ổ ỗ ộ ớ ờ ở ỡ ợ
  0x1EE5: 'u', 0x1EE7: 'u', 0x1EE9: 'u', 0x1EEB: 'u', 0x1EED: 'u',
  0x1EEF: 'u', 0x1EF1: 'u', // ụ ủ ứ ừ ử ữ ự
  0x1EF3: 'y', 0x1EF5: 'y', 0x1EF7: 'y', 0x1EF9: 'y', 0x1EFD: 'y', // ỳ ý ỷ ỹ ỵ
};

/// Sắp [rows] **phẳng** theo tiền (R4) — asc: nhỏ → lớn, desc: lớn → nhỏ theo
/// `abs(amount)`; trùng giá trị → ngày mới nhất trước, trùng tiếp → `sortId`
/// tăng (ổn định, mỗi dòng đúng 1 lần — SC-010). Không đổi list đầu vào.
List<TxnRow> sortAmountRows(List<TxnRow> rows, SortOption sort) {
  final sorted = [...rows];
  final descending = sort == SortOption.amountDesc;
  sorted.sort((a, b) {
    final byAmount = a.amount.abs().compareTo(b.amount.abs());
    if (byAmount != 0) return descending ? -byAmount : byAmount;
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;
    return a.sortId.compareTo(b.sortId);
  });
  return sorted;
}

/// Nhóm [groups] (đang mới nhất trên — [groupDisplayRows]) theo hướng [sort]:
/// `dateNewest` giữ nguyên; `dateOldest` đảo nhóm & dòng trong nhóm (R4).
List<DayGroup> orderDateGroups(List<DayGroup> groups, SortOption sort) {
  if (groups.isEmpty || sort != SortOption.dateOldest) return groups;
  return [
    for (final group in groups.reversed)
      DayGroup(
        day: group.day,
        header: group.header,
        rows: group.rows.reversed.toList(),
      ),
  ];
}
