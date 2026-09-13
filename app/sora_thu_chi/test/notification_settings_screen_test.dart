import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/core/notification/notification_prefs.dart';
import 'package:sora_thu_chi/screens/daily_reminder_config_screen.dart';
import 'package:sora_thu_chi/screens/notification_settings_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';
import 'package:sora_thu_chi/theme/sora_colors.dart';

import 'fakes/fake_notification_store.dart';

/// 5 nhãn nhóm đúng thứ tự mockup `01` (FR-003).
const _groups = [
  'NHẮC NHỞ HÀNG NGÀY',
  'NGÂN SÁCH',
  'GIAO DỊCH ĐỊNH KỲ',
  'MỤC TIÊU TIẾT KIỆM',
  'TỔNG KẾT TỰ ĐỘNG',
];

/// 8 tiêu đề hàng + dòng phụ mặc định (quickstart B5) — thứ tự = thứ tự màn.
const _rows = <(String, String)>[
  ('Nhắc nhập giao dịch hằng ngày', '20:30 mỗi ngày · chỉ nhắc nếu chưa ghi'),
  ('Cảnh báo vượt ngân sách', 'Khi đạt 80% và khi vượt 100%'),
  ('Ngưỡng cảnh báo', 'Sớm: 80% · Vượt mức: 100%'),
  ('Nhắc hóa đơn sắp đến hạn', 'Tiền điện, tiền nhà, trả nợ...'),
  ('Nhắc trước', '3 ngày trước hạn thanh toán'),
  ('Nhắc đóng góp mục tiêu', 'Theo chu kỳ đã đặt cho từng mục tiêu'),
  ('Tổng kết cuối tuần', 'Chủ nhật hằng tuần, 20:00'),
  ('Tổng kết cuối tháng', 'Ngày cuối tháng, 20:00'),
];

/// Hàng nhóm NGÂN SÁCH (coral); 6 hàng còn lại teal (FR-004).
const _coralRows = {'Cảnh báo vượt ngân sách', 'Ngưỡng cảnh báo'};

/// Hàng chỉ có chevron (không công tắc).
const _navRows = {'Ngưỡng cảnh báo', 'Nhắc trước'};

class _RecordingObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}

Future<void> pumpScreen(
  WidgetTester tester, {
  required FakeNotificationStore store,
  NavigatorObserver? observer,
  Size size = const Size(390, 1400),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      navigatorObservers: observer == null ? const [] : [observer],
      home: NotificationSettingsScreen(store: store),
    ),
  );
  await tester.pumpAndSettle();
}

/// Hàng chứa [label] — `Row` gần nhất đi lên từ tiêu đề.
Finder rowOf(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Row)).first;

/// Vòng tròn icon của hàng [label] (Container đầu tiên trong hàng).
Color? iconCircleColorOf(WidgetTester tester, String label) {
  final container = tester.widget<Container>(
    find.descendant(of: rowOf(label), matching: find.byType(Container)).first,
  );
  return (container.decoration as BoxDecoration?)?.color;
}

Color? iconGlyphColorOf(WidgetTester tester, String label) => tester
    .widget<Icon>(find.descendant(of: rowOf(label), matching: find.byType(Icon)).first)
    .color;

void main() {
  group('NotificationSettingsScreen — US1 (mockup 01)', () {
    testWidgets('Mở lần đầu: đủ 5 nhóm + 8 hàng + 8 dòng phụ đúng thứ tự', (
      tester,
    ) async {
      await pumpScreen(tester, store: FakeNotificationStore());

      // App bar + không bottom nav/FAB (FR-002).
      expect(find.text('Thông báo & nhắc nhở'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);

      double prevGroup = -1;
      for (final label in _groups) {
        expect(find.text(label), findsOneWidget, reason: 'thiếu nhãn nhóm $label');
        final y = tester.getTopLeft(find.text(label)).dy;
        expect(y, greaterThan(prevGroup), reason: '$label sai thứ tự nhóm');
        prevGroup = y;
      }
      double prevRow = tester.getTopLeft(find.text(_groups.first)).dy;
      for (final (title, subtitle) in _rows) {
        expect(find.text(title), findsOneWidget, reason: 'thiếu hàng $title');
        expect(
          find.text(subtitle),
          findsOneWidget,
          reason: 'dòng phụ sai ở hàng $title',
        );
        final y = tester.getTopLeft(find.text(title)).dy;
        expect(y, greaterThan(prevRow), reason: '$title sai thứ tự hàng');
        prevRow = y;
      }
    });

    testWidgets('6 công tắc + 2 chevron; không hàng nào có cả hai', (tester) async {
      await pumpScreen(tester, store: FakeNotificationStore());

      expect(find.byType(Switch), findsNWidgets(6));
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));

      for (final (title, _) in _rows) {
        final switches = tester
            .widgetList(find.descendant(of: rowOf(title), matching: find.byType(Switch)))
            .length;
        final chevrons = tester
            .widgetList(
              find.descendant(
                of: rowOf(title),
                matching: find.byIcon(Icons.chevron_right),
              ),
            )
            .length;
        if (_navRows.contains(title)) {
          expect(chevrons, 1, reason: '$title phải có đúng 1 chevron');
          expect(switches, 0, reason: '$title không được có công tắc');
        } else {
          expect(switches, 1, reason: '$title phải có đúng 1 công tắc');
          expect(chevrons, 0, reason: '$title không được có chevron');
        }
      }
    });

    testWidgets('Sắc icon: 2 hàng Ngân sách coral, 6 hàng còn lại teal', (
      tester,
    ) async {
      await pumpScreen(tester, store: FakeNotificationStore());

      for (final (title, _) in _rows) {
        final coral = _coralRows.contains(title);
        expect(
          iconCircleColorOf(tester, title),
          coral ? SoraColors.light.coralLightBg : SoraColors.light.tealLightBg,
          reason: 'nền vòng tròn sai ở hàng $title',
        );
        expect(
          iconGlyphColorOf(tester, title),
          coral ? SoraColors.light.coralOnNeutral : SoraColors.light.tealOnNeutral,
          reason: 'màu glyph sai ở hàng $title',
        );
      }
    });

    testWidgets(
      'Chạm công tắc "Cảnh báo vượt ngân sách": chỉ hàng đó đổi, ngưỡng giữ nguyên',
      (tester) async {
        final store = FakeNotificationStore();
        await pumpScreen(tester, store: store);

        final budgetSwitch = find.descendant(
          of: rowOf('Cảnh báo vượt ngân sách'),
          matching: find.byType(Switch),
        );
        expect(tester.widget<Switch>(budgetSwitch).value, isTrue);

        await tester.tap(budgetSwitch);
        await tester.pumpAndSettle();

        expect(tester.widget<Switch>(budgetSwitch).value, isFalse);
        // 5 công tắc còn lại giữ nguyên.
        final others = [
          'Nhắc nhập giao dịch hằng ngày',
          'Nhắc hóa đơn sắp đến hạn',
          'Nhắc đóng góp mục tiêu',
          'Tổng kết cuối tuần',
          'Tổng kết cuối tháng',
        ];
        for (final title in others) {
          final value = tester
              .widget<Switch>(
                find.descendant(of: rowOf(title), matching: find.byType(Switch)),
              )
              .value;
          expect(
            value,
            title == 'Nhắc đóng góp mục tiêu' ? isFalse : isTrue,
            reason: '$title không được đổi theo',
          );
        }
        // Hàng chevron ngay dưới vẫn hiện đủ ngưỡng (không bị reset/xoá).
        expect(find.text('Sớm: 80% · Vượt mức: 100%'), findsOneWidget);
      },
    );

    testWidgets('Chạm 2 hàng chevron: không route mới, không dialog/SnackBar', (
      tester,
    ) async {
      final observer = _RecordingObserver();
      await pumpScreen(
        tester,
        store: FakeNotificationStore(),
        observer: observer,
      );

      final before = observer.pushes;
      for (final title in _navRows) {
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text(title));
          await tester.pump();
        }
      }
      await tester.pumpAndSettle();

      expect(observer.pushes, before, reason: 'không được mở màn nào');
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Store load() lỗi → "Không đọc được cài đặt." + nút Thử lại chạy', (
      tester,
    ) async {
      final store = FakeNotificationStore(failLoad: true);
      await pumpScreen(tester, store: store);

      expect(find.text('Không đọc được cài đặt.'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.text('NHẮC NHỞ HÀNG NGÀY'), findsNothing);

      store.failLoad = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('Không đọc được cài đặt.'), findsNothing);
      expect(find.text('NHẮC NHỞ HÀNG NGÀY'), findsOneWidget);
    });
  });

  group('NotificationSettingsScreen — US2 (ghi bền)', () {
    testWidgets('Mở lần đầu trên store rỗng → mặc định được ghi NGAY, không cần chạm', (
      tester,
    ) async {
      final store = FakeNotificationStore();
      expect(store.storedPrefs, NotificationPrefs.defaults);

      await pumpScreen(tester, store: store);

      expect(store.storedPrefs, NotificationPrefs.defaults);
    });

    testWidgets('Chạm 1 công tắc → ghi đúng trường đó, 15 trường còn lại nguyên', (
      tester,
    ) async {
      final store = FakeNotificationStore();
      await pumpScreen(tester, store: store);

      await tester.tap(
        find.descendant(
          of: rowOf('Nhắc hóa đơn sắp đến hạn'),
          matching: find.byType(Switch),
        ),
      );
      await tester.pumpAndSettle();

      expect(store.storedPrefs.recurringEnabled, isFalse);
      expect(
        store.storedPrefs,
        NotificationPrefs.defaults.copyWith(recurringEnabled: false),
      );
      expect(store.storedPrefs.recurringDaysBefore, 3, reason: 'tham số giữ nguyên');
    });

    testWidgets('Mở lại màn với store đã đổi → UI + dòng phụ đúng trạng thái đã lưu', (
      tester,
    ) async {
      final store = FakeNotificationStore(
        storedPrefs: const NotificationPrefs(
          dailyEnabled: false,
          dailyHour: 7,
          dailyMinute: 5,
          dailyOnlyIfNoTxnToday: false,
          budgetEarlyPercent: 50,
          recurringDaysBefore: 8,
          goalEnabled: true,
        ),
      );
      await pumpScreen(tester, store: store);

      // Dòng phụ đọc từ cấu hình đã lưu, không hằng cứng.
      expect(find.text('07:05 mỗi ngày'), findsOneWidget);
      expect(find.text('Khi đạt 50% và khi vượt 100%'), findsOneWidget);
      expect(find.text('Sớm: 50% · Vượt mức: 100%'), findsOneWidget);
      expect(find.text('8 ngày trước hạn thanh toán'), findsOneWidget);
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: rowOf('Nhắc nhập giao dịch hằng ngày'),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Switch>(
              find.descendant(
                of: rowOf('Nhắc đóng góp mục tiêu'),
                matching: find.byType(Switch),
              ),
            )
            .value,
        isTrue,
      );
    });

    testWidgets('Tắt "Nhắc nhập giao dịch hằng ngày" rồi bật lại → tham số giữ nguyên', (
      tester,
    ) async {
      final store = FakeNotificationStore();
      await pumpScreen(tester, store: store);

      final dailySwitch = find.descendant(
        of: rowOf('Nhắc nhập giao dịch hằng ngày'),
        matching: find.byType(Switch),
      );
      await tester.tap(dailySwitch);
      await tester.pumpAndSettle();
      expect(store.storedPrefs.dailyEnabled, isFalse);
      // Hậu tố "chỉ nhắc nếu chưa ghi" chỉ phụ thuộc cờ riêng, không phụ thuộc công tắc.
      expect(find.text('20:30 mỗi ngày · chỉ nhắc nếu chưa ghi'), findsOneWidget);

      await tester.tap(dailySwitch);
      await tester.pumpAndSettle();
      expect(store.storedPrefs.dailyEnabled, isTrue);
      expect(store.storedPrefs.dailyHour, 20);
      expect(store.storedPrefs.dailyMinute, 30);
      expect(store.storedPrefs.dailyOnlyIfNoTxnToday, isTrue);
    });

    testWidgets('Tắt cả 6 công tắc → lưu hợp lệ, mở lại không công tắc nào tự bật', (
      tester,
    ) async {
      final store = FakeNotificationStore();
      await pumpScreen(tester, store: store);

      final titles = [
        'Nhắc nhập giao dịch hằng ngày',
        'Cảnh báo vượt ngân sách',
        'Nhắc hóa đơn sắp đến hạn',
        'Nhắc đóng góp mục tiêu',
        'Tổng kết cuối tuần',
        'Tổng kết cuối tháng',
      ];
      for (final title in titles) {
        final finder = find.descendant(
          of: rowOf(title),
          matching: find.byType(Switch),
        );
        // "Nhắc đóng góp mục tiêu" mặc định tắt — chỉ chạm công tắc đang bật.
        if (!tester.widget<Switch>(finder).value) continue;
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      final saved = store.storedPrefs;
      expect(saved.dailyEnabled, isFalse);
      expect(saved.budgetEnabled, isFalse);
      expect(saved.recurringEnabled, isFalse);
      expect(saved.goalEnabled, isFalse);
      expect(saved.weeklyEnabled, isFalse);
      expect(saved.monthlyEnabled, isFalse);

      // Mở lại màn mới trên cùng store → vẫn tắt hết.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await pumpScreen(tester, store: FakeNotificationStore(storedPrefs: saved));
      for (final title in titles) {
        expect(
          tester
              .widget<Switch>(
                find.descendant(of: rowOf(title), matching: find.byType(Switch)),
              )
              .value,
          isFalse,
          reason: '$title tự bật lại',
        );
      }
    });

    testWidgets('Bật/tắt liên tiếp 4 lần → store giữ trạng thái cuối', (tester) async {
      final store = FakeNotificationStore();
      await pumpScreen(tester, store: store);

      final goalSwitch = find.descendant(
        of: rowOf('Nhắc đóng góp mục tiêu'),
        matching: find.byType(Switch),
      );
      // Bật (false→true), tắt, bật, tắt — không pump giữa các lần chạm để save
      // xếp hàng đuôi nhau.
      for (var i = 0; i < 4; i++) {
        await tester.tap(goalSwitch);
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(store.storedPrefs.goalEnabled, isFalse, reason: 'lần chạm cuối thắng');
      expect(
        tester.widget<Switch>(goalSwitch).value,
        isFalse,
        reason: 'UI khớp trạng thái cuối',
      );
    });
  });

  group('NotificationSettingsScreen — US2 (PBI 29): điểm vào màn 02 + dòng phụ', () {
    testWidgets('Chạm vùng tiêu đề/dòng phụ hàng nhắc hàng ngày → đúng 1 route', (
      tester,
    ) async {
      final observer = _RecordingObserver();
      await pumpScreen(
        tester,
        store: FakeNotificationStore(),
        observer: observer,
      );

      final before = observer.pushes;
      await tester.tap(find.text('Nhắc nhập giao dịch hằng ngày'));
      await tester.pumpAndSettle();

      expect(observer.pushes, before + 1);
      expect(find.byType(DailyReminderConfigScreen), findsOneWidget);
      expect(find.text('THỜI GIAN NHẮC'), findsOneWidget);
    });

    testWidgets('Chạm dòng phụ hoặc icon cũng mở màn 02 (cả hàng trừ công tắc)', (
      tester,
    ) async {
      final observer = _RecordingObserver();
      await pumpScreen(
        tester,
        store: FakeNotificationStore(),
        observer: observer,
      );

      final before = observer.pushes;
      await tester.tap(
        find.text('20:30 mỗi ngày · chỉ nhắc nếu chưa ghi'),
      );
      await tester.pumpAndSettle();
      expect(observer.pushes, before + 1, reason: 'dòng phụ cũng là vùng chạm');
    });

    testWidgets('Chạm CÔNG TẮC hàng nhắc hàng ngày → 0 route mới, chỉ đổi trạng thái', (
      tester,
    ) async {
      final observer = _RecordingObserver();
      final store = FakeNotificationStore();
      await pumpScreen(tester, store: store, observer: observer);

      final before = observer.pushes;
      final dailySwitch = find.descendant(
        of: rowOf('Nhắc nhập giao dịch hằng ngày'),
        matching: find.byType(Switch),
      );
      await tester.tap(dailySwitch);
      await tester.pumpAndSettle();

      expect(observer.pushes, before, reason: 'chạm công tắc không mở màn');
      expect(find.byType(DailyReminderConfigScreen), findsNothing);
      expect(tester.widget<Switch>(dailySwitch).value, isFalse);
      expect(store.storedPrefs.dailyEnabled, isFalse);
    });

    testWidgets('5 hàng công tắc còn lại không mở màn nào', (tester) async {
      final observer = _RecordingObserver();
      await pumpScreen(
        tester,
        store: FakeNotificationStore(),
        observer: observer,
      );

      final before = observer.pushes;
      for (final title in const [
        'Cảnh báo vượt ngân sách',
        'Nhắc hóa đơn sắp đến hạn',
        'Nhắc đóng góp mục tiêu',
        'Tổng kết cuối tuần',
        'Tổng kết cuối tháng',
      ]) {
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
      }
      expect(observer.pushes, before, reason: 'chỉ hàng nhắc hàng ngày mở màn 02');
    });

    testWidgets('Dòng phụ theo tập ngày: mỗi ngày / T2–T7 / T2–T4, T6 / T2, CN', (
      tester,
    ) async {
      const cases = <List<int>, String>{
        [1, 2, 3, 4, 5, 6, 7]: '20:30 mỗi ngày',
        [1, 2, 3, 4, 5, 6]: '20:30 vào T2–T7',
        [1, 2, 3, 5]: '20:30 vào T2–T4, T6',
        [1, 7]: '20:30 vào T2, CN',
      };
      for (final entry in cases.entries) {
        // Gỡ màn cũ trước mỗi lượt — nếu không, `State` giữ lại store của lượt
        // trước (cùng loại widget, không key) và dòng phụ không nạp lại.
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await pumpScreen(
          tester,
          store: FakeNotificationStore(
            storedPrefs: NotificationPrefs(
              dailyWeekdays: entry.key,
              dailyOnlyIfNoTxnToday: false,
            ),
          ),
        );
        expect(
          find.text(entry.value),
          findsOneWidget,
          reason: 'tập ${entry.key} → "${entry.value}"',
        );
        // Các hàng khác không bị ảnh hưởng.
        expect(find.text('Sớm: 80% · Vượt mức: 100%'), findsOneWidget);
      }
    });

    testWidgets('Dòng phụ dạng liệt kê giữ hậu tố "chỉ nhắc nếu chưa ghi"', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        store: FakeNotificationStore(
          storedPrefs: const NotificationPrefs(dailyWeekdays: [1, 7]),
        ),
      );
      expect(
        find.text('20:30 vào T2, CN · chỉ nhắc nếu chưa ghi'),
        findsOneWidget,
      );
    });

    testWidgets('Lưu ở màn 02 → quay về màn 01, dòng phụ đọc lại theo giá trị mới', (
      tester,
    ) async {
      final store = FakeNotificationStore();
      await pumpScreen(tester, store: store);

      await tester.tap(find.text('Nhắc nhập giao dịch hằng ngày'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.keyboard_arrow_up).at(0));
      await tester.tap(find.text('CN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(find.text('21:30 vào T2–T7 · chỉ nhắc nếu chưa ghi'), findsOneWidget);
      expect(store.storedPrefs.dailyWeekdays, [1, 2, 3, 4, 5, 6]);
    });
  });

  group('NotificationSettingsScreen — chất lượng hiển thị', () {
    testWidgets('English: nhãn tĩnh dịch hết, giờ/số giữ nguyên định dạng', (
      tester,
    ) async {
      // Đổi ngôn ngữ gọi `Get.updateLocale` → reassemble; khôi phục ở tearDown
      // (khuôn `budget_overview_screen_test`).
      Get.addTranslations(SoraTranslations().keys);
      Get.locale = const Locale('en');
      addTearDown(() => Get.locale = null);

      await pumpScreen(tester, store: FakeNotificationStore());

      expect(find.text('Notifications & reminders'), findsOneWidget);
      for (final label in const [
        'DAILY REMINDER',
        'BUDGET',
        'RECURRING TRANSACTIONS',
        'SAVINGS GOALS',
        'AUTOMATIC SUMMARIES',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'thiếu nhãn nhóm $label');
      }
      for (final title in const [
        'Daily transaction reminder',
        'Budget overspend alert',
        // Khoá dùng chung với màn Ngân sách (PBI 21) — bản dịch đã có sẵn.
        'Alert thresholds',
        'Upcoming bill reminder',
        'Remind ahead',
        'Goal contribution reminder',
        'Weekly summary',
        'Monthly summary',
      ]) {
        expect(find.text(title), findsOneWidget, reason: 'thiếu hàng $title');
      }
      // Dòng phụ dạng mô tả là tiếng Anh…
      expect(
        find.text('Every day at 20:30 · only if nothing logged yet'),
        findsOneWidget,
      );
      expect(
        find.text('When reaching 80% and when over 100%'),
        findsOneWidget,
      );
      expect(find.text('Early: 80% · Over: 100%'), findsOneWidget);
      expect(
        find.text('Electricity, rent, loan payments...'),
        findsOneWidget,
      );
      expect(find.text('3 days before the due date'), findsOneWidget);
      expect(
        find.text('Follows the schedule set for each goal'),
        findsOneWidget,
      );
      expect(find.text('Every Sunday, 20:00'), findsOneWidget);
      expect(find.text('Last day of the month, 20:00'), findsOneWidget);

      // …và 0 nhãn tĩnh tiếng Việt sót lại.
      for (final (title, subtitle) in _rows) {
        expect(find.text(title), findsNothing, reason: 'sót tiếng Việt: $title');
        expect(
          find.text(subtitle),
          findsNothing,
          reason: 'sót tiếng Việt ở dòng phụ: $subtitle',
        );
      }
      expect(find.text('NHẮC NHỞ HÀNG NGÀY'), findsNothing);
    });

    testWidgets('Cỡ chữ 2.0 + màn 360×640: không tràn, cuộn tới hàng cuối', (
      tester,
    ) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );

      await pumpScreen(
        tester,
        store: FakeNotificationStore(),
        size: const Size(360, 640),
      );

      await tester.dragUntilVisible(
        find.text('Tổng kết cuối tháng'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tổng kết cuối tháng'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Không được có FlutterError (RenderFlex overflow) khi cỡ chữ lớn',
      );
    });
  });
}
