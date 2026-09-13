import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/core/notification/notification_prefs.dart';
import 'package:sora_thu_chi/core/notification/notification_store.dart';
import 'package:sora_thu_chi/screens/daily_reminder_config_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_notification_store.dart';

/// Màn `01` giả: chỉ có nút mở màn `02` — để test được **back/pop** (cần có
/// route bên dưới) mà không kéo cả màn `01` vào.
class _Host extends StatelessWidget {
  const _Host({required this.store});

  final NotificationStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DailyReminderConfigScreen(store: store),
            ),
          ),
          child: const Text('mở màn 02'),
        ),
      ),
    );
  }
}

Future<void> pumpHost(
  WidgetTester tester, {
  required FakeNotificationStore store,
  Size size = const Size(390, 1000),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: _Host(store: store),
    ),
  );
  await tester.pumpAndSettle();
}

/// Mở màn `02` qua nút của [_Host].
Future<void> openScreen(
  WidgetTester tester, {
  required FakeNotificationStore store,
  Size size = const Size(390, 1000),
}) async {
  await pumpHost(tester, store: store, size: size);
  await tester.tap(find.text('mở màn 02'));
  await tester.pumpAndSettle();
}

Finder get hourUp => find.byIcon(Icons.keyboard_arrow_up).at(0);
Finder get hourDown => find.byIcon(Icons.keyboard_arrow_down).at(0);
Finder get minuteUp => find.byIcon(Icons.keyboard_arrow_up).at(1);
Finder get minuteDown => find.byIcon(Icons.keyboard_arrow_down).at(1);

/// Chip ngày [label] đang chọn (nền teal) hay không.
bool chipSelected(WidgetTester tester, String label) {
  final ink = find
      .ancestor(of: find.text(label), matching: find.byType(InkWell))
      .first;
  final container = tester.widget<Container>(
    find.descendant(of: ink, matching: find.byType(Container)).first,
  );
  return (container.decoration as BoxDecoration).color == AppColors.teal;
}

const _groupLabels = [
  'THỜI GIAN NHẮC',
  'LẶP LẠI VÀO CÁC NGÀY',
  'XEM TRƯỚC THÔNG BÁO',
];

void main() {
  group('DailyReminderConfigScreen — US1: bố cục màn 02', () {
    testWidgets('Đủ 3 nhãn nhóm + hàng công tắc + nút Lưu; không bottom nav/FAB', (
      tester,
    ) async {
      await openScreen(tester, store: FakeNotificationStore());

      expect(find.text('Nhắc nhập giao dịch'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);

      double prev = -1;
      for (final label in _groupLabels) {
        expect(find.text(label), findsOneWidget, reason: 'thiếu nhãn nhóm $label');
        final y = tester.getTopLeft(find.text(label)).dy;
        expect(y, greaterThan(prev), reason: '$label sai thứ tự');
        prev = y;
      }

      expect(find.text('Chỉ nhắc nếu chưa ghi giao dịch'), findsOneWidget);
      expect(
        find.text('Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập'),
        findsOneWidget,
      );
      expect(find.byType(Switch), findsOneWidget, reason: 'đúng 1 công tắc');
      expect(find.text('Lưu thay đổi'), findsOneWidget);
      expect(find.text('Sora Thu Chi'), findsOneWidget);
      expect(
        find.text('Đừng quên ghi lại thu chi hôm nay nhé!'),
        findsOneWidget,
      );
    });

    testWidgets('Khối thời gian: mỗi trục hiện giá trị đang chọn + 2 lân cận', (
      tester,
    ) async {
      await pumpHost(tester, store: FakeNotificationStore());
      await tester.tap(find.text('mở màn 02'));
      await tester.pumpAndSettle();

      // 20:30 → giờ 19/20/21, phút 29/30/31; 2 trục ⇒ 4 mũi tên.
      for (final value in ['19', '20', '21', '29', '30', '31']) {
        expect(find.text(value), findsOneWidget, reason: 'thiếu giá trị $value');
      }
      expect(find.byIcon(Icons.keyboard_arrow_up), findsNWidgets(2));
      expect(find.byIcon(Icons.keyboard_arrow_down), findsNWidgets(2));
      expect(find.text(':'), findsOneWidget);
      expect(find.text('20:30'), findsOneWidget, reason: 'giờ khối xem trước');
    });

    testWidgets('7 chip đủ T2…CN, mặc định cả 7 đang chọn', (tester) async {
      await openScreen(tester, store: FakeNotificationStore());

      for (final label in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']) {
        expect(find.text(label), findsOneWidget, reason: 'thiếu chip $label');
        expect(chipSelected(tester, label), isTrue, reason: '$label phải đang chọn');
      }
    });
  });

  group('DailyReminderConfigScreen — US1: mũi tên giờ/phút', () {
    testWidgets('Giờ ±1 và quay vòng 23 ↔ 00', (tester) async {
      final store = FakeNotificationStore(
        storedPrefs: const NotificationPrefs(dailyHour: 23, dailyMinute: 30),
      );
      await openScreen(tester, store: store);
      expect(find.text('23:30'), findsOneWidget);

      await tester.tap(hourUp);
      await tester.pumpAndSettle();
      expect(find.text('00:30'), findsOneWidget, reason: '23 + 1 → 00');

      await tester.tap(hourDown);
      await tester.pumpAndSettle();
      expect(find.text('23:30'), findsOneWidget, reason: '00 - 1 → 23');

      // Lân cận cũng quay vòng: 23 → lân cận trên 22, dưới 00.
      expect(find.text('22'), findsOneWidget);
      expect(find.text('00'), findsOneWidget);
    });

    testWidgets('Phút ±1 và quay vòng 00 ↔ 59', (tester) async {
      final store = FakeNotificationStore(
        storedPrefs: const NotificationPrefs(dailyHour: 20, dailyMinute: 0),
      );
      await openScreen(tester, store: store);
      expect(find.text('20:00'), findsOneWidget);

      await tester.tap(minuteDown);
      await tester.pumpAndSettle();
      expect(find.text('20:59'), findsOneWidget, reason: '00 - 1 → 59');

      await tester.tap(minuteUp);
      await tester.pumpAndSettle();
      expect(find.text('20:00'), findsOneWidget, reason: '59 + 1 → 00');
    });

    testWidgets('Chạm 30 lần liên tiếp: giá trị luôn trong miền', (tester) async {
      await openScreen(tester, store: FakeNotificationStore());

      for (var i = 0; i < 30; i++) {
        await tester.tap(hourUp);
        await tester.tap(minuteUp);
      }
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // 20 + 30 ≡ 2 (mod 24); 30 + 30 ≡ 0 (mod 60).
      expect(find.text('02:00'), findsOneWidget);
    });

    testWidgets('Đổi giờ → khối xem trước đổi NGAY, store chưa bị ghi', (
      tester,
    ) async {
      final store = FakeNotificationStore();
      await openScreen(tester, store: store);
      expect(find.text('20:30'), findsOneWidget);

      await tester.tap(hourUp);
      await tester.pumpAndSettle();

      expect(find.text('21:30'), findsOneWidget, reason: 'xem trước đổi tức thì');
      expect(
        store.storedPrefs,
        NotificationPrefs.defaults,
        reason: 'chưa bấm Lưu ⇒ store không đổi',
      );
    });
  });

  group('DailyReminderConfigScreen — US1: chip ngày', () {
    testWidgets('Chạm chip chỉ đổi chip đó', (tester) async {
      final store = FakeNotificationStore();
      await openScreen(tester, store: store);

      await tester.tap(find.text('CN'));
      await tester.pumpAndSettle();

      expect(chipSelected(tester, 'CN'), isFalse);
      for (final label in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7']) {
        expect(chipSelected(tester, label), isTrue, reason: '$label bị đổi theo');
      }
      expect(store.storedPrefs.isEveryDay, isTrue, reason: 'store chưa ghi');

      await tester.tap(find.text('CN'));
      await tester.pumpAndSettle();
      expect(chipSelected(tester, 'CN'), isTrue, reason: 'chạm lại → bật lại');
    });

    testWidgets('Chip cuối cùng không tắt được, không hộp thoại', (tester) async {
      final store = FakeNotificationStore(
        storedPrefs: const NotificationPrefs(dailyWeekdays: [3]),
      );
      await openScreen(tester, store: store);

      expect(chipSelected(tester, 'T4'), isTrue);
      await tester.tap(find.text('T4'));
      await tester.pumpAndSettle();

      expect(chipSelected(tester, 'T4'), isTrue, reason: 'không tắt được chip cuối');
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Bấm Lưu sau khi đổi chip → store nhận đúng tập ngày', (
      tester,
    ) async {
      final store = FakeNotificationStore();
      await openScreen(tester, store: store);

      await tester.tap(find.text('CN'));
      await tester.tap(find.text('T5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(store.storedPrefs.dailyWeekdays, [1, 2, 3, 5, 6]);
    });
  });

  group('DailyReminderConfigScreen — US1: bản nháp / lưu / back', () {
    testWidgets('Back giữa chừng → store KHÔNG ghi, mở lại thấy giá trị cũ', (
      tester,
    ) async {
      final store = FakeNotificationStore();
      await openScreen(tester, store: store);

      await tester.tap(hourUp);
      await tester.tap(find.text('CN'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(DailyReminderConfigScreen), findsNothing);
      expect(store.storedPrefs, NotificationPrefs.defaults, reason: 'thay đổi bị bỏ');
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing, reason: 'không hỏi lại');

      await tester.tap(find.text('mở màn 02'));
      await tester.pumpAndSettle();
      expect(find.text('20:30'), findsOneWidget, reason: 'vẫn giờ cũ');
      expect(chipSelected(tester, 'CN'), isTrue, reason: 'vẫn đủ 7 chip');
    });

    testWidgets('Bấm Lưu → store nhận đúng bản nháp rồi pop', (tester) async {
      final store = FakeNotificationStore();
      await openScreen(tester, store: store);

      await tester.tap(hourUp);
      await tester.tap(minuteUp);
      await tester.tap(find.text('CN'));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyReminderConfigScreen), findsNothing, reason: 'pop');
      expect(store.storedPrefs.dailyHour, 21);
      expect(store.storedPrefs.dailyMinute, 31);
      expect(store.storedPrefs.dailyWeekdays, [1, 2, 3, 4, 5, 6]);
      expect(store.storedPrefs.dailyOnlyIfNoTxnToday, isFalse);
      expect(store.storedPrefs.dailyEnabled, isTrue, reason: 'công tắc màn 01 không đổi');
      expect(
        store.storedPrefs.budgetEarlyPercent,
        80,
        reason: 'các loại nhắc khác không đổi',
      );
    });

    testWidgets('Bấm Lưu khi không đổi gì → vẫn pop, giá trị không đổi', (
      tester,
    ) async {
      const initial = NotificationPrefs(dailyHour: 7, dailyMinute: 5, dailyWeekdays: [2, 4]);
      final store = FakeNotificationStore(storedPrefs: initial);
      await openScreen(tester, store: store);

      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(find.byType(DailyReminderConfigScreen), findsNothing);
      expect(store.storedPrefs, initial);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Tắt công tắc rồi Lưu → chỉ cờ đó đổi', (tester) async {
      final store = FakeNotificationStore();
      await openScreen(tester, store: store);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(store.storedPrefs.dailyOnlyIfNoTxnToday, isTrue, reason: 'chưa ghi');

      await tester.tap(find.text('Lưu thay đổi'));
      await tester.pumpAndSettle();

      expect(store.storedPrefs.dailyOnlyIfNoTxnToday, isFalse);
      expect(store.storedPrefs.dailyHour, 20);
      expect(store.storedPrefs.dailyWeekdays, [1, 2, 3, 4, 5, 6, 7]);
    });

    testWidgets('Load lỗi → thông báo + Thử lại đọc lại thành công', (tester) async {
      final store = FakeNotificationStore(failLoad: true);
      await openScreen(tester, store: store);

      expect(find.text('Không đọc được cài đặt.'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.text('THỜI GIAN NHẮC'), findsNothing);

      store.failLoad = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('Không đọc được cài đặt.'), findsNothing);
      expect(find.text('THỜI GIAN NHẮC'), findsOneWidget);
    });
  });

  group('DailyReminderConfigScreen — US3: tiếng Anh & cỡ chữ lớn', () {
    testWidgets('English: mọi nhãn tĩnh dịch hết, giờ vẫn HH:mm', (tester) async {
      Get.addTranslations(SoraTranslations().keys);
      Get.locale = const Locale('en');
      addTearDown(() => Get.locale = null);

      await openScreen(tester, store: FakeNotificationStore());

      expect(find.text('Transaction reminder'), findsOneWidget);
      for (final label in [
        'REMINDER TIME',
        'REPEAT ON DAYS',
        'NOTIFICATION PREVIEW',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'thiếu $label');
      }
      expect(find.text('Only remind if nothing is logged'), findsOneWidget);
      expect(
        find.text('Skip the reminder if you already logged today'),
        findsOneWidget,
      );
      expect(
        find.text("Don't forget to log today's income and expenses!"),
        findsOneWidget,
      );
      expect(find.text('Save changes'), findsOneWidget);
      // 7 nhãn chip tiếng Anh, không còn T2…CN.
      for (final label in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
        expect(find.text(label), findsOneWidget, reason: 'thiếu chip $label');
      }
      for (final label in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']) {
        expect(find.text(label), findsNothing, reason: 'sót nhãn tiếng Việt $label');
      }
      // Giờ và tên app không dịch.
      expect(find.text('20:30'), findsOneWidget);
      expect(find.text('Sora Thu Chi'), findsOneWidget);
      for (final label in [
        'Nhắc nhập giao dịch',
        'THỜI GIAN NHẮC',
        'LẶP LẠI VÀO CÁC NGÀY',
        'XEM TRƯỚC THÔNG BÁO',
        'Chỉ nhắc nếu chưa ghi giao dịch',
        'Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập',
        'Đừng quên ghi lại thu chi hôm nay nhé!',
        'Lưu thay đổi',
      ]) {
        expect(find.text(label), findsNothing, reason: 'sót tiếng Việt: $label');
      }
    });

    testWidgets('Cỡ chữ 2.0 + màn 360×640: không tràn, nút Lưu vẫn tới được', (
      tester,
    ) async {
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );

      await openScreen(
        tester,
        store: FakeNotificationStore(),
        size: const Size(360, 640),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'không được có RenderFlex overflow khi cỡ chữ lớn',
      );

      // Cuộn hết nội dung rồi vẫn thấy nút Lưu (ghim đáy) và không tràn.
      await tester.dragUntilVisible(
        find.text('XEM TRƯỚC THÔNG BÁO'),
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lưu thay đổi'), findsOneWidget);
      expect(find.text('Đừng quên ghi lại thu chi hôm nay nhé!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
