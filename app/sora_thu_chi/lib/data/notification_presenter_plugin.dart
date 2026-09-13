import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/notification/app_notification.dart';
import '../core/notification/notification_presenter.dart';
import '../theme/app_colors.dart';

/// Id 3 kênh Android (R11/FR-025) — hằng số, **không** phải cấu hình người dùng.
const String kChannelDaily = 'sora_daily';
const String kChannelBudget = 'sora_budget';
const String kChannelSummary = 'sora_summary';

/// Impl thật của [NotificationPresenter] — bọc `FlutterLocalNotificationsPlugin`.
///
/// Ba quyết định đáng nhớ:
///
/// * **Múi giờ**: `zonedSchedule` cần `TZDateTime`; thiếu `flutter_timezone` thì
///   `tz.local` mãi là UTC ⇒ nhắc 20:30 bắn lúc 3:30 sáng (R1). Nạp lại mỗi lần
///   khởi động để đổi múi giờ thiết bị vẫn đúng (quickstart nhóm O).
/// * **Exact alarm**: khai `USE_EXACT_ALARM` nhưng hệ điều hành vẫn có quyền từ
///   chối — plugin khi đó **im lặng**, không lịch, không lỗi (bẫy chết người).
///   Vì vậy luôn hỏi [canScheduleExactNotifications] và **lùi** về lịch inexact
///   thay vì mất thông báo (R10).
/// * **Kênh coral**: chỉ kênh cảnh báo ngân sách dùng coral — teal cho 2 kênh
///   còn lại (FR-006/SC-001); màu lấy từ token, không hex cứng trong widget.
class PluginNotificationPresenter implements NotificationPresenter {
  PluginNotificationPresenter([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Đã `init()` chưa — tránh dựng kênh/nạp múi giờ lặp lại ở mỗi lần resume.
  bool _ready = false;

  @override
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Không đọc được múi giờ hệ thống → giữ mặc định; lịch vẫn đăng ký được,
      // chỉ có thể lệch giờ. Không được để lỗi này chặn khởi động app (FR-024).
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notif_bell'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
    );
    await _createChannels();
    _ready = true;
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  @override
  Future<bool> areEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.areNotificationsEnabled() ?? true;
    }
    // iOS: không có API "đang bật?" đối xứng; coi như bật, lối thoát vẫn còn ở
    // nút mở cài đặt hệ thống.
    return true;
  }

  @override
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.requestNotificationsPermission() ?? false;
    }
    return await _ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  @override
  Future<void> openSettings() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _android?.requestNotificationsPermission();
      return;
    }
    await _ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> schedule(OsNotification notification) async {
    await _plugin.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: tz.TZDateTime.from(notification.at, tz.local),
      notificationDetails: _detailsFor(notification.kind),
      androidScheduleMode: await _scheduleMode(),
      payload: notification.payload,
    );
  }

  @override
  Future<void> show(OsNotification notification) async {
    await _plugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      notificationDetails: _detailsFor(notification.kind),
      payload: notification.payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  /// Huỷ mọi mốc **đang chờ** thuộc [kind] — lọc theo **tiền tố payload**
  /// (`daily:`/`budget:`/`summary:`), không huỷ bừa id lạ nào chưa từng do mình
  /// đăng ký. 2 loại chưa có module ⇒ không có mốc nào, thoát sớm.
  @override
  Future<void> cancelKind(NotificationKind kind) async {
    final prefix = _payloadPrefixOf(kind);
    if (prefix == null) return;
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = request.payload;
      if (payload != null && payload.startsWith(prefix)) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  /// Lịch **một-lần** ở chế độ exact; hệ thống từ chối exact ⇒ lùi inexact
  /// (vẫn bắn, chỉ có thể lệch vài phút — quickstart §5 lệch 4).
  Future<AndroidScheduleMode> _scheduleMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// 3 kênh (R11): nhắc hàng ngày & tổng kết teal, cảnh báo ngân sách coral.
  Future<void> _createChannels() async {
    final android = _android;
    if (android == null) return;
    const channels = [
      AndroidNotificationChannel(
        kChannelDaily,
        'Nhắc nhập giao dịch',
        description: 'Nhắc ghi chép thu chi hằng ngày',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        kChannelBudget,
        'Cảnh báo ngân sách',
        description: 'Cảnh báo khi chi tiêu chạm ngưỡng ngân sách',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        kChannelSummary,
        'Tổng kết tuần/tháng',
        description: 'Tổng kết chi tiêu cuối tuần và cuối tháng',
        importance: Importance.high,
      ),
    ];
    for (final channel in channels) {
      await android.createNotificationChannel(channel);
    }
  }

  /// Icon **nhỏ** của Android buộc là drawable đơn sắc khai trong manifest res
  /// (R11) — không dùng `Icons.*` hay ảnh launcher.
  NotificationDetails _detailsFor(NotificationKind kind) {
    final channel = switch (kind) {
      NotificationKind.budgetAlert => kChannelBudget,
      NotificationKind.periodSummary => kChannelSummary,
      _ => kChannelDaily,
    };
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        _channelName(channel),
        icon: _iconFor(kind),
        importance: Importance.high,
        priority: Priority.high,
        color: kind == NotificationKind.budgetAlert
            ? AppColors.coral
            : AppColors.teal,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static String _channelName(String channelId) => switch (channelId) {
    kChannelBudget => 'Cảnh báo ngân sách',
    kChannelSummary => 'Tổng kết tuần/tháng',
    _ => 'Nhắc nhập giao dịch',
  };

  static String _iconFor(NotificationKind kind) => switch (kind) {
    NotificationKind.budgetAlert => 'ic_notif_warning',
    NotificationKind.periodSummary => 'ic_notif_summary',
    _ => 'ic_notif_bell',
  };

  /// Tiền tố khoá sổ của từng loại (`notification_schedule.dart` sinh khoá);
  /// `null` = loại chưa có mốc nào trong sổ (FR-002).
  static String? _payloadPrefixOf(NotificationKind kind) => switch (kind) {
    NotificationKind.dailyReminder => 'daily:',
    NotificationKind.budgetAlert => 'budget:',
    NotificationKind.periodSummary => 'summary:',
    NotificationKind.recurringDue || NotificationKind.goalReminder => null,
  };

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();
}
