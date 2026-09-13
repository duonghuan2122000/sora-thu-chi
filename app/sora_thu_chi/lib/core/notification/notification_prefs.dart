import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Khóa row cấu hình thông báo trong bảng key-value `AppSettings`.
const String kKeyNotificationPrefs = 'notificationPrefs';

/// Khoá row cờ **"đã hỏi quyền thông báo lần đầu"** (PBI 31, FR-017) — row
/// `AppSettings` riêng, **không** nằm trong khối JSON [NotificationPrefs] (cờ
/// này không phải cấu hình người dùng chỉnh, chỉ là dấu "đã hỏi"). Thêm row ⇒
/// **không** cần migration (nếp PBI 17/24/28).
const String kKeyNotificationPermissionAsked = 'notificationPermissionAsked';

/// Cấu hình 5 loại nhắc nhở của màn "Thông báo & nhắc nhở" (17 trường — đủ cho
/// 8 hàng của mockup `01` + tham số ngày của màn cấu hình nhắc hàng ngày). Bất
/// biến: mọi thay đổi qua [copyWith], mỗi lần đổi **chỉ** chạm trường của loại
/// được truyền ⇒ không có cơ chế "bật/tắt tất cả".
///
/// Lưu **nguyên khối** dưới dạng 1 row JSON (data-model §1.3): [toSettings] gói
/// `jsonEncode`, [fromSettings] parse **tolerant, không bao giờ ném** — row vắng
/// hoặc JSON hỏng → cả bộ mặc định; từng trường sai kiểu/ngoài miền → mặc định
/// **của riêng trường đó**. DB là dữ liệu người dùng (sửa tay/ghi dở) nên không
/// được làm trắng màn.
@immutable
class NotificationPrefs {
  const NotificationPrefs({
    this.dailyEnabled = true,
    this.dailyHour = 20,
    this.dailyMinute = 30,
    this.dailyOnlyIfNoTxnToday = true,
    this.dailyWeekdays = const [1, 2, 3, 4, 5, 6, 7],
    this.budgetEnabled = true,
    this.budgetEarlyPercent = 80,
    this.budgetOverPercent = 100,
    this.recurringEnabled = true,
    this.recurringDaysBefore = 3,
    this.goalEnabled = false,
    this.weeklyEnabled = true,
    this.weeklyHour = 20,
    this.weeklyMinute = 0,
    this.monthlyEnabled = true,
    this.monthlyHour = 20,
    this.monthlyMinute = 0,
  });

  /// Bộ mặc định FR-008 (mockup `01`): mọi loại bật **trừ** nhắc đóng góp mục
  /// tiêu; nhắc hàng ngày 20:30 kèm cờ "chỉ nhắc nếu chưa ghi"; ngưỡng
  /// 80%/100%; nhắc trước 3 ngày; tổng kết tuần/tháng 20:00.
  static const NotificationPrefs defaults = NotificationPrefs();

  /// Nhắc nhập giao dịch hằng ngày.
  final bool dailyEnabled;
  final int dailyHour;
  final int dailyMinute;

  /// Chỉ nhắc nếu hôm nay chưa ghi giao dịch nào.
  final bool dailyOnlyIfNoTxnToday;

  /// Các ngày trong tuần được nhắc: `1` = Thứ Hai … `7` = Chủ Nhật (ISO-8601).
  /// Bất biến: **khác rỗng**, phần tử ∈ 1…7, **đã sắp tăng**, không trùng.
  final List<int> dailyWeekdays;

  /// Đủ cả 7 ngày ⇒ dòng phụ màn "Thông báo & nhắc nhở" dùng chuỗi "mỗi ngày".
  bool get isEveryDay => dailyWeekdays.length == 7;

  /// Trạng thái một chip ngày ở màn cấu hình nhắc hàng ngày.
  bool isDayEnabled(int weekday) => dailyWeekdays.contains(weekday);

  /// Đảo trạng thái **một** ngày; tắt ngày bật cuối cùng → trả **chính object
  /// này** (`identical`) để không tồn tại trạng thái 0 ngày (FR-009).
  NotificationPrefs toggleDay(int weekday) {
    if (weekday < 1 || weekday > 7) return this;
    if (!dailyWeekdays.contains(weekday)) {
      return copyWith(dailyWeekdays: [...dailyWeekdays, weekday]..sort());
    }
    if (dailyWeekdays.length <= 1) return this;
    return copyWith(
      dailyWeekdays: dailyWeekdays.where((d) => d != weekday).toList(),
    );
  }

  /// Cảnh báo vượt ngân sách.
  final bool budgetEnabled;

  /// Ngưỡng cảnh báo sớm (%).
  final int budgetEarlyPercent;

  /// Ngưỡng vượt mức (%).
  final int budgetOverPercent;

  /// Nhắc hóa đơn sắp đến hạn.
  final bool recurringEnabled;

  /// Nhắc trước hạn thanh toán (ngày).
  final int recurringDaysBefore;

  /// Nhắc đóng góp mục tiêu tiết kiệm.
  final bool goalEnabled;

  /// Tổng kết cuối tuần.
  final bool weeklyEnabled;
  final int weeklyHour;
  final int weeklyMinute;

  /// Tổng kết cuối tháng.
  final bool monthlyEnabled;
  final int monthlyHour;
  final int monthlyMinute;

  Map<String, Object> toJson() => {
    'dailyEnabled': dailyEnabled,
    'dailyHour': dailyHour,
    'dailyMinute': dailyMinute,
    'dailyOnlyIfNoTxnToday': dailyOnlyIfNoTxnToday,
    'dailyWeekdays': dailyWeekdays,
    'budgetEnabled': budgetEnabled,
    'budgetEarlyPercent': budgetEarlyPercent,
    'budgetOverPercent': budgetOverPercent,
    'recurringEnabled': recurringEnabled,
    'recurringDaysBefore': recurringDaysBefore,
    'goalEnabled': goalEnabled,
    'weeklyEnabled': weeklyEnabled,
    'weeklyHour': weeklyHour,
    'weeklyMinute': weeklyMinute,
    'monthlyEnabled': monthlyEnabled,
    'monthlyHour': monthlyHour,
    'monthlyMinute': monthlyMinute,
  };

  /// Đúng 1 row `(kKeyNotificationPrefs, <JSON 16 khóa>)`.
  Map<String, String> toSettings() => {
    kKeyNotificationPrefs: jsonEncode(toJson()),
  };

  /// Row vắng / JSON hỏng → cả bộ mặc định; từng trường lạ → mặc định của nó.
  factory NotificationPrefs.fromSettings(Map<String, String> rows) {
    final raw = rows[kKeyNotificationPrefs];
    if (raw == null) return defaults;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return defaults;
    }
    if (decoded is! Map) return defaults;
    return NotificationPrefs(
      dailyEnabled: _bool(decoded['dailyEnabled'], true),
      dailyHour: _int(decoded['dailyHour'], 20, 0, 23),
      dailyMinute: _int(decoded['dailyMinute'], 30, 0, 59),
      dailyOnlyIfNoTxnToday: _bool(decoded['dailyOnlyIfNoTxnToday'], true),
      dailyWeekdays: _weekdays(decoded['dailyWeekdays']),
      budgetEnabled: _bool(decoded['budgetEnabled'], true),
      budgetEarlyPercent: _int(decoded['budgetEarlyPercent'], 80, 0, 100),
      budgetOverPercent: _int(decoded['budgetOverPercent'], 100, 0, 100),
      recurringEnabled: _bool(decoded['recurringEnabled'], true),
      recurringDaysBefore: _int(decoded['recurringDaysBefore'], 3, 0, 30),
      goalEnabled: _bool(decoded['goalEnabled'], false),
      weeklyEnabled: _bool(decoded['weeklyEnabled'], true),
      weeklyHour: _int(decoded['weeklyHour'], 20, 0, 23),
      weeklyMinute: _int(decoded['weeklyMinute'], 0, 0, 59),
      monthlyEnabled: _bool(decoded['monthlyEnabled'], true),
      monthlyHour: _int(decoded['monthlyHour'], 20, 0, 23),
      monthlyMinute: _int(decoded['monthlyMinute'], 0, 0, 59),
    );
  }

  static bool _bool(Object? raw, bool fallback) =>
      raw is bool ? raw : fallback;

  /// Sai kiểu (kể cả số thực) hoặc ngoài miền → mặc định (giá trị ghi ra luôn
  /// hợp lệ nên không cần clamp lại).
  static int _int(Object? raw, int fallback, int min, int max) =>
      raw is int && raw >= min && raw <= max ? raw : fallback;

  /// Chuẩn hoá tập ngày, **không bao giờ ném**: không phải `List` → cả 7 ngày;
  /// phần tử không phải `int` hoặc ngoài 1…7 → lọc bỏ; bỏ trùng và sắp tăng;
  /// tập rỗng (kể cả list rỗng/toàn phần tử sai) → cả 7 ngày — không tồn tại
  /// trạng thái 0 ngày (FR-009). Giá trị ghi ra luôn đã chuẩn hoá.
  static List<int> _weekdays(Object? raw) {
    if (raw is! List) return const [1, 2, 3, 4, 5, 6, 7];
    final days = raw.whereType<int>().where((d) => d >= 1 && d <= 7).toSet().toList()
      ..sort();
    return days.isEmpty ? const [1, 2, 3, 4, 5, 6, 7] : days;
  }

  /// Chỉ đổi trường được truyền — tắt một loại **không** chạm tham số của loại
  /// đó (bật lại đọc ra đúng tham số cũ).
  NotificationPrefs copyWith({
    bool? dailyEnabled,
    int? dailyHour,
    int? dailyMinute,
    bool? dailyOnlyIfNoTxnToday,
    List<int>? dailyWeekdays,
    bool? budgetEnabled,
    int? budgetEarlyPercent,
    int? budgetOverPercent,
    bool? recurringEnabled,
    int? recurringDaysBefore,
    bool? goalEnabled,
    bool? weeklyEnabled,
    int? weeklyHour,
    int? weeklyMinute,
    bool? monthlyEnabled,
    int? monthlyHour,
    int? monthlyMinute,
  }) => NotificationPrefs(
    dailyEnabled: dailyEnabled ?? this.dailyEnabled,
    dailyHour: dailyHour ?? this.dailyHour,
    dailyMinute: dailyMinute ?? this.dailyMinute,
    dailyOnlyIfNoTxnToday: dailyOnlyIfNoTxnToday ?? this.dailyOnlyIfNoTxnToday,
    dailyWeekdays: dailyWeekdays ?? this.dailyWeekdays,
    budgetEnabled: budgetEnabled ?? this.budgetEnabled,
    budgetEarlyPercent: budgetEarlyPercent ?? this.budgetEarlyPercent,
    budgetOverPercent: budgetOverPercent ?? this.budgetOverPercent,
    recurringEnabled: recurringEnabled ?? this.recurringEnabled,
    recurringDaysBefore: recurringDaysBefore ?? this.recurringDaysBefore,
    goalEnabled: goalEnabled ?? this.goalEnabled,
    weeklyEnabled: weeklyEnabled ?? this.weeklyEnabled,
    weeklyHour: weeklyHour ?? this.weeklyHour,
    weeklyMinute: weeklyMinute ?? this.weeklyMinute,
    monthlyEnabled: monthlyEnabled ?? this.monthlyEnabled,
    monthlyHour: monthlyHour ?? this.monthlyHour,
    monthlyMinute: monthlyMinute ?? this.monthlyMinute,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationPrefs &&
      other.dailyEnabled == dailyEnabled &&
      other.dailyHour == dailyHour &&
      other.dailyMinute == dailyMinute &&
      other.dailyOnlyIfNoTxnToday == dailyOnlyIfNoTxnToday &&
      listEquals(other.dailyWeekdays, dailyWeekdays) &&
      other.budgetEnabled == budgetEnabled &&
      other.budgetEarlyPercent == budgetEarlyPercent &&
      other.budgetOverPercent == budgetOverPercent &&
      other.recurringEnabled == recurringEnabled &&
      other.recurringDaysBefore == recurringDaysBefore &&
      other.goalEnabled == goalEnabled &&
      other.weeklyEnabled == weeklyEnabled &&
      other.weeklyHour == weeklyHour &&
      other.weeklyMinute == weeklyMinute &&
      other.monthlyEnabled == monthlyEnabled &&
      other.monthlyHour == monthlyHour &&
      other.monthlyMinute == monthlyMinute;

  @override
  int get hashCode => Object.hash(
    dailyEnabled,
    dailyHour,
    dailyMinute,
    dailyOnlyIfNoTxnToday,
    Object.hashAll(dailyWeekdays),
    budgetEnabled,
    budgetEarlyPercent,
    budgetOverPercent,
    recurringEnabled,
    recurringDaysBefore,
    goalEnabled,
    weeklyEnabled,
    weeklyHour,
    weeklyMinute,
    monthlyEnabled,
    monthlyHour,
    monthlyMinute,
  );
}
