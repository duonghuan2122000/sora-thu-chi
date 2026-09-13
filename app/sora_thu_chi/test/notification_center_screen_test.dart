import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/notification/app_notification.dart';
import 'package:sora_thu_chi/core/notification/notification_store.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/add_transaction_screen.dart';
import 'package:sora_thu_chi/screens/budget_detail_screen.dart';
import 'package:sora_thu_chi/screens/notification_center_screen.dart';
import 'package:sora_thu_chi/screens/notification_settings_screen.dart';
import 'package:sora_thu_chi/theme/app_colors.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';
import 'package:sora_thu_chi/theme/sora_colors.dart';

import 'fakes/fake_notification_history_store.dart';
import 'fakes/fake_notification_store.dart';
import 'fakes/fake_wallet_repository.dart';

/// 2026-09-13 là Chủ Nhật; 12 → Thứ Bảy; 10 → Thứ Năm; 24/08 → Thứ Hai.
final _now = DateTime(2026, 9, 13, 9, 0);

AppNotification _n({
  required int id,
  required NotificationKind kind,
  required String title,
  String body = '',
  required DateTime createdAt,
  DateTime? readAt,
  int? relatedId,
}) => AppNotification(
  id: id,
  kind: kind,
  title: title,
  body: body,
  createdAt: createdAt,
  readAt: readAt,
  relatedId: relatedId,
);

/// Bộ 5 mục phủ đủ 3 nhóm + 2 sắc icon + đọc/chưa đọc, **mới nhất trước**.
List<AppNotification> _sample() => [
  _n(
    id: 2,
    kind: NotificationKind.budgetAlert,
    title: 'Sắp vượt ngân sách Ăn uống',
    body: 'Đã dùng 82% ngân sách tháng này',
    createdAt: DateTime(2026, 9, 13, 20, 30),
    relatedId: 1,
  ),
  _n(
    id: 1,
    kind: NotificationKind.dailyReminder,
    title: 'Nhắc ghi chép hôm nay',
    body: 'Bạn chưa ghi giao dịch nào hôm nay',
    createdAt: DateTime(2026, 9, 13, 8, 30),
  ),
  _n(
    id: 5,
    kind: NotificationKind.recurringDue,
    title: 'Hóa đơn tiền điện sắp đến hạn',
    createdAt: DateTime(2026, 9, 12, 7, 0),
  ),
  _n(
    id: 3,
    kind: NotificationKind.periodSummary,
    title: 'Tổng kết tuần',
    createdAt: DateTime(2026, 9, 10, 10, 0),
    readAt: DateTime(2026, 9, 11, 10, 0),
  ),
  _n(
    id: 4,
    kind: NotificationKind.goalReminder,
    title: 'Nhắc đóng góp mục tiêu',
    createdAt: DateTime(2026, 8, 24, 9, 0),
    readAt: DateTime(2026, 8, 25, 9, 0),
  ),
];

/// Đăng ký fake cho mọi màn đích có thể bị push (bánh răng / mục) để không mở
/// drift thật; trả về store lịch sử để assert trạng thái đọc.
FakeNotificationHistoryStore _registerFakes() {
  Get.reset();
  Get.put<NotificationStore>(FakeNotificationStore());
  Get.put<WalletRepository>(FakeWalletRepository());
  addTearDown(Get.reset);
  return FakeNotificationHistoryStore();
}

Future<FakeNotificationHistoryStore> pumpCenter(
  WidgetTester tester, {
  List<AppNotification>? items,
  bool failLoad = false,
  ValueChanged<int>? onSelectTab,
}) async {
  final store = _registerFakes();
  store.failLoad = failLoad;
  store.stored.addAll(items ?? _sample());
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: NotificationCenterScreen(
        store: store,
        now: _now,
        onSelectTab: onSelectTab,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

/// Ô 8×8 của chấm chưa đọc (mọi mục đều có, kể cả đã đọc — để không xô lệch).
Finder _dotSlots() => find.byWidgetPredicate(
  (w) => w is SizedBox && w.width == 8 && w.height == 8,
);

Finder _tealDots() => find.descendant(
  of: _dotSlots(),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        (w.decoration as BoxDecoration).color == AppColors.teal,
  ),
);

/// Vòng tròn 36 px nền nhạt của icon — đếm theo sắc nền.
Finder _iconCircles(Color color) => find.byWidgetPredicate(
  (w) =>
      w is Container &&
      (w.decoration is BoxDecoration) &&
      ((w.decoration as BoxDecoration).color == color) &&
      ((w.decoration as BoxDecoration).shape == BoxShape.circle),
);

void main() {
  group('NotificationCenterScreen — khung màn (FR-002)', () {
    testWidgets('app bar: tiêu đề "Thông báo" + nút bánh răng', (tester) async {
      await pumpCenter(tester);

      expect(find.text('Thông báo'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('notification-settings-entry')),
        findsOneWidget,
      );
      // Màn con: không bottom nav, không FAB.
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  group('NotificationCenterScreen — 2 tab lọc (FR-003, R7)', () {
    testWidgets('2 nhãn tab; gạch chân teal chỉ ở tab đang chọn', (tester) async {
      await pumpCenter(tester);

      expect(find.text('Tất cả'), findsOneWidget);
      expect(find.text('Chưa đọc'), findsOneWidget);

      BorderSide underline(String key) {
        final box =
            tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: find.byKey(ValueKey(key)),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        return (box.border as Border).bottom;
      }

      expect(underline('notification-tab-all').color, AppColors.teal);
      expect(underline('notification-tab-unread').color, Colors.transparent);

      await tester.tap(find.byKey(const ValueKey('notification-tab-unread')));
      await tester.pumpAndSettle();

      expect(underline('notification-tab-unread').color, AppColors.teal);
      expect(underline('notification-tab-all').color, Colors.transparent);
    });

    testWidgets('tab "Chưa đọc" chỉ còn mục chưa đọc, giữ nguyên nhóm',
        (tester) async {
      await pumpCenter(tester);

      // Tab "Tất cả": 5 mục, đủ 3 nhóm.
      expect(_dotSlots(), findsNWidgets(5));
      expect(find.text('HÔM NAY'), findsOneWidget);
      expect(find.text('TUẦN NÀY'), findsOneWidget);
      expect(find.text('TRƯỚC ĐÓ'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('notification-tab-unread')));
      await tester.pumpAndSettle();

      // Còn 3 mục chưa đọc: 2 hôm nay + 1 tuần này; nhóm TRƯỚC ĐÓ biến mất.
      expect(_dotSlots(), findsNWidgets(3));
      expect(find.text('HÔM NAY'), findsOneWidget);
      expect(find.text('TUẦN NÀY'), findsOneWidget);
      expect(find.text('TRƯỚC ĐÓ'), findsNothing);
      expect(find.text('Tổng kết tuần'), findsNothing);
      expect(find.text('Nhắc đóng góp mục tiêu'), findsNothing);
    });
  });

  group('NotificationCenterScreen — nhóm & mục (FR-004, FR-005, FR-006)', () {
    testWidgets('nhãn nhóm đúng thứ tự, KHÔNG vẽ nhóm rỗng', (tester) async {
      await pumpCenter(
        tester,
        items: [
          _n(
            id: 1,
            kind: NotificationKind.dailyReminder,
            title: 'Chỉ hôm nay',
            createdAt: DateTime(2026, 9, 13, 8, 0),
          ),
        ],
      );

      expect(find.text('HÔM NAY'), findsOneWidget);
      expect(find.text('TUẦN NÀY'), findsNothing);
      expect(find.text('TRƯỚC ĐÓ'), findsNothing);
    });

    testWidgets('chấm teal chỉ ở mục chưa đọc; mọi mục đều chiếm 8 px',
        (tester) async {
      await pumpCenter(tester);

      expect(_dotSlots(), findsNWidgets(5), reason: 'đã đọc vẫn chiếm chỗ');
      expect(_tealDots(), findsNWidgets(3), reason: 'id 2, 1, 5 chưa đọc');
    });

    testWidgets('2 sắc icon: coral CHỈ ở cảnh báo ngân sách', (tester) async {
      await pumpCenter(tester);

      expect(_iconCircles(SoraColors.light.coralLightBg), findsOneWidget);
      expect(_iconCircles(SoraColors.light.tealLightBg), findsNWidgets(4));
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
      expect(find.byIcon(Icons.track_changes), findsOneWidget);
      expect(find.byIcon(Icons.pie_chart_outline), findsOneWidget);
    });

    testWidgets('nhãn thời gian 3 dạng: HH:mm / tên thứ / dd/MM', (tester) async {
      await pumpCenter(tester);

      expect(find.text('20:30'), findsOneWidget);
      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('Thứ Bảy'), findsOneWidget);
      expect(find.text('Thứ Năm'), findsOneWidget);
      expect(find.text('24/08'), findsOneWidget);
    });

    testWidgets('nội dung bản ghi hiện NGUYÊN VĂN (không dịch lại)', (tester) async {
      await pumpCenter(tester);

      expect(find.text('Sắp vượt ngân sách Ăn uống'), findsOneWidget);
      expect(find.text('Đã dùng 82% ngân sách tháng này'), findsOneWidget);
    });
  });

  group('NotificationCenterScreen — trạng thái rỗng (FR-011)', () {
    testWidgets('lịch sử rỗng → câu chung; tab "Chưa đọc" vẫn câu chung đó',
        (tester) async {
      await pumpCenter(tester, items: []);

      expect(find.text('Chưa có thông báo nào'), findsOneWidget);
      expect(find.text('Thông báo và nhắc nhở sẽ hiện ở đây.'), findsOneWidget);
      expect(find.text('HÔM NAY'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('notification-tab-unread')));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có thông báo nào'), findsOneWidget);
      expect(find.text('Không có thông báo chưa đọc'), findsNothing);
    });

    testWidgets('lịch sử có mục mà mọi mục đã đọc → câu RIÊNG ở tab "Chưa đọc"',
        (tester) async {
      await pumpCenter(
        tester,
        items: [
          _n(
            id: 1,
            kind: NotificationKind.periodSummary,
            title: 'Tổng kết tuần',
            createdAt: DateTime(2026, 9, 10, 10, 0),
            readAt: DateTime(2026, 9, 11),
          ),
        ],
      );

      await tester.tap(find.byKey(const ValueKey('notification-tab-unread')));
      await tester.pumpAndSettle();

      expect(find.text('Không có thông báo chưa đọc'), findsOneWidget);
      expect(find.text('Bạn đã đọc hết thông báo.'), findsOneWidget);
      expect(find.text('Chưa có thông báo nào'), findsNothing);
      expect(find.text('HÔM NAY'), findsNothing);
    });
  });

  group('NotificationCenterScreen — đọc lỗi & bánh răng', () {
    testWidgets('đọc lỗi → câu lỗi + "Thử lại" đọc lại được', (tester) async {
      final store = await pumpCenter(tester, failLoad: true);

      expect(find.text('Không đọc được thông báo.'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      store.failLoad = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();

      expect(find.text('Không đọc được thông báo.'), findsNothing);
      expect(find.text('Sắp vượt ngân sách Ăn uống'), findsOneWidget);
    });

    testWidgets('bánh răng → màn "Thông báo & nhắc nhở" (PBI 28)', (tester) async {
      await pumpCenter(tester);

      await tester.tap(
        find.byKey(const ValueKey('notification-settings-entry')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(find.text('Thông báo & nhắc nhở'), findsOneWidget);
    });
  });

  group('NotificationCenterScreen — chạm mục (FR-007, FR-008, FR-019)', () {
    testWidgets('chưa đọc → ghi readAt vào store + mở đúng 1 route đích',
        (tester) async {
      final store = await pumpCenter(tester);

      await tester.tap(find.text('Nhắc ghi chép hôm nay'));
      await tester.pumpAndSettle();

      final read = store.stored.firstWhere((n) => n.id == 1);
      expect(read.isRead, isTrue);
      expect(read.readAt, _now);
      // Mục khác không đổi (FR-007).
      expect(store.stored.firstWhere((n) => n.id == 5).readAt, isNull);
      expect(store.stored.firstWhere((n) => n.id == 3).readAt,
          DateTime(2026, 9, 11, 10, 0));
      expect(find.byType(AddTransactionScreen), findsOneWidget);
    });

    testWidgets('cảnh báo ngân sách → mở Chi tiết ngân sách của relatedId',
        (tester) async {
      await pumpCenter(tester);

      await tester.tap(find.text('Sắp vượt ngân sách Ăn uống'));
      await tester.pumpAndSettle();

      expect(find.byType(BudgetDetailScreen), findsOneWidget);
    });

    testWidgets('đã đọc → vẫn điều hướng, readAt KHÔNG đổi', (tester) async {
      final store = await pumpCenter(tester);

      await tester.tap(find.text('Tổng kết tuần'));
      await tester.pumpAndSettle();

      expect(
        store.stored.firstWhere((n) => n.id == 3).readAt,
        DateTime(2026, 9, 11, 10, 0),
      );
      expect(find.byType(NotificationCenterScreen), findsOneWidget);
    });

    testWidgets(
      'loại chưa có màn đích / thiếu relatedId → 0 route, im lặng, VẪN đã đọc',
      (tester) async {
        final store = await pumpCenter(
          tester,
          items: [
            _n(
              id: 1,
              kind: NotificationKind.recurringDue,
              title: 'Định kỳ',
              createdAt: DateTime(2026, 9, 13, 8, 0),
            ),
            _n(
              id: 2,
              kind: NotificationKind.goalReminder,
              title: 'Mục tiêu',
              createdAt: DateTime(2026, 9, 13, 7, 0),
            ),
            _n(
              id: 3,
              kind: NotificationKind.budgetAlert,
              title: 'Cảnh báo thiếu id',
              createdAt: DateTime(2026, 9, 13, 6, 0),
            ),
          ],
        );

        for (final title in ['Định kỳ', 'Mục tiêu', 'Cảnh báo thiếu id']) {
          await tester.tap(find.text(title));
          await tester.pumpAndSettle();
          expect(find.byType(NotificationCenterScreen), findsOneWidget);
          expect(find.byType(SnackBar), findsNothing);
          expect(find.byType(AlertDialog), findsNothing);
        }
        expect(store.stored.every((n) => n.isRead), isTrue);
      },
    );

    testWidgets('tổng kết kỳ → pop về màn gốc + onSelectTab(2)', (tester) async {
      final store = _registerFakes();
      store.stored.addAll(_sample());
      final tabs = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.themeData,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => NotificationCenterScreen(
                        store: store,
                        now: _now,
                        onSelectTab: tabs.add,
                      ),
                    ),
                  ),
                  child: const Text('open-center'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open-center'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tổng kết tuần'));
      await tester.pumpAndSettle();

      expect(find.byType(NotificationCenterScreen), findsNothing);
      expect(find.text('open-center'), findsOneWidget);
      expect(tabs, [2]);
    });

    testWidgets('đọc mục chưa đọc cuối → tab "Chưa đọc" rỗng đúng câu riêng',
        (tester) async {
      await pumpCenter(
        tester,
        items: [
          _n(
            id: 1,
            kind: NotificationKind.recurringDue,
            title: 'Định kỳ duy nhất',
            createdAt: DateTime(2026, 9, 13, 8, 0),
          ),
        ],
      );

      await tester.tap(find.text('Định kỳ duy nhất'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('notification-tab-unread')));
      await tester.pumpAndSettle();

      expect(find.text('Không có thông báo chưa đọc'), findsOneWidget);
      expect(find.text('Định kỳ duy nhất'), findsNothing);
    });
  });

  group('NotificationCenterScreen — cỡ chữ lớn & màn hẹp (FR-016)', () {
    testWidgets('textScale 2 + 360×640 → không overflow, cuộn tới mục cuối',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final items = [
        for (var i = 0; i < 12; i++)
          _n(
            id: i + 1,
            kind: NotificationKind.dailyReminder,
            title: 'Tiêu đề rất dài số $i để thử xuống dòng ở cỡ chữ lớn',
            body: 'Dòng mô tả cũng dài để kiểm tra wrap tự nhiên, không cắt.',
            createdAt: DateTime(2026, 9, 13).add(Duration(minutes: i)),
          ),
      ];
      await pumpCenter(tester, items: items);

      await tester.scrollUntilVisible(
        find.text('Tiêu đề rất dài số 11 để thử xuống dòng ở cỡ chữ lớn'),
        400,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Cuộn hết danh sách → mục cuối (số 11) hiện ra, hàng tab vẫn nguyên.
      expect(find.text('Tiêu đề rất dài số 11 để thử xuống dòng ở cỡ chữ lớn'),
          findsOneWidget);
      expect(find.byKey(const ValueKey('notification-tab-all')), findsOneWidget);
    });
  });
}
