import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/report/export_share.dart';
import 'package:sora_thu_chi/core/report/report_controller.dart';
import 'package:sora_thu_chi/core/report/report_file_save.dart';
import 'package:sora_thu_chi/core/report/report_view.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/data/report_deps.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/report_export_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_wallet_repository.dart';

/// Test màn **Xuất báo cáo** (màn `04`, PBI 27) — không DB: dữ liệu bơm qua
/// `FakeWalletRepository`, seam chia sẻ bơm bản giả, mốc "hôm nay" cố định.

final _now = DateTime(2026, 9, 20, 10);

Category _cat(
  int id,
  String name, {
  CategoryType type = CategoryType.expense,
  int? parentId,
  int sortOrder = 0,
}) => Category(
  id: id,
  name: name,
  type: type,
  icon: 'restaurant',
  color: 0xFF0F6E56,
  parentId: parentId,
  sortOrder: sortOrder,
);

Wallet _wallet(int id, String name, {int sortOrder = 0}) => Wallet(
  id: id,
  name: name,
  type: WalletType.cash,
  balance: 1000000,
  sortOrder: sortOrder,
);

Transaction _expense(
  int id,
  int amount,
  DateTime date, {
  int walletId = 1,
  int? categoryId,
  String category = 'Ăn uống',
  String tags = '',
}) => Transaction(
  id: id,
  walletId: walletId,
  type: TxnType.expense,
  category: category,
  amount: -amount,
  date: date,
  categoryId: categoryId,
  tags: tags,
);

Transaction _income(int id, int amount, DateTime date) => Transaction(
  id: id,
  walletId: 1,
  type: TxnType.income,
  category: 'Lương',
  amount: amount,
  date: date,
  categoryId: 4,
);

/// Tháng 9/2026: 3 giao dịch ví 1 (2 chi + 1 thu) + 1 chi ví 2 có tag;
/// 1 cặp chuyển khoản (vào danh sách, **không** vào con số).
FakeWalletRepository _seededRepo() => FakeWalletRepository.withCategories(
  wallets: [_wallet(1, 'Tiền mặt'), _wallet(2, 'Ngân hàng', sortOrder: 1)],
  transactions: [
    _expense(1, 300000, DateTime(2026, 9, 3), categoryId: 1),
    _expense(2, 200000, DateTime(2026, 9, 10), categoryId: 1),
    _income(3, 5000000, DateTime(2026, 9, 5)),
    _expense(
      4,
      150000,
      DateTime(2026, 9, 12),
      walletId: 2,
      categoryId: 3,
      category: 'Du lịch',
      tags: 'dulich',
    ),
    Transaction(
      id: 5,
      walletId: 1,
      type: TxnType.transfer,
      amount: -500000,
      date: DateTime(2026, 9, 15),
      transferGroupId: 5,
    ),
    Transaction(
      id: 6,
      walletId: 2,
      type: TxnType.transfer,
      amount: 500000,
      date: DateTime(2026, 9, 15),
      transferGroupId: 5,
    ),
  ],
  categoriesSeed: [
    _cat(1, 'Ăn uống'),
    _cat(2, 'Cà phê', parentId: 1, sortOrder: 1),
    _cat(3, 'Du lịch', sortOrder: 2),
    _cat(4, 'Lương', type: CategoryType.income, sortOrder: 3),
    _cat(5, 'Mua sắm', sortOrder: 4),
    _cat(6, 'Đi lại', sortOrder: 5),
  ],
);

/// Kỳ không có giao dịch thu/chi nào.
FakeWalletRepository _emptyRepo() => FakeWalletRepository.withCategories(
  wallets: [_wallet(1, 'Tiền mặt')],
  transactions: const [],
  categoriesSeed: [_cat(1, 'Ăn uống')],
);

class _ThrowingRepo extends FakeWalletRepository {
  @override
  Future<List<Transaction>> allTransactions() async =>
      throw StateError('lỗi đọc giả lập');
}

/// Seam lưu file giả (PBI 41) — ghi lại mọi lần gọi, trả path giả cố định.
class _FakeSave {
  final List<({String fileName, Uint8List bytes, String mimeType})> calls = [];
  bool fail = false;
  bool permissionDenied = false;

  Future<SavedReportFile> call({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    calls.add((fileName: fileName, bytes: bytes, mimeType: mimeType));
    if (permissionDenied) {
      throw const ReportStoragePermissionDeniedException();
    }
    if (fail) throw StateError('lưu lỗi giả lập');
    return SavedReportFile(path: 'fake/downloads/$fileName', fileName: fileName);
  }
}

/// Seam chia sẻ giả — ghi lại mọi lần gọi.
class _FakeShare {
  final List<({String fileName, String filePath, String mimeType})> calls = [];
  bool fail = false;
  Completer<void>? gate;

  Future<void> call({
    required String fileName,
    required String filePath,
    required String mimeType,
  }) async {
    calls.add((fileName: fileName, filePath: filePath, mimeType: mimeType));
    if (gate != null) await gate!.future;
    if (fail) throw StateError('chia sẻ lỗi giả lập');
  }
}

Future<ReportController> _pump(
  WidgetTester tester,
  FakeWalletRepository repo, {
  SaveReportFile? save,
  ShareExport? share,
  ReportPeriod period = ReportPeriod.month,
}) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  Get.put<WalletRepository>(repo);
  final controller = ensureReportController();
  await controller.load(now: _now);
  controller.setPeriod(period);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: ReportExportScreen(save: save, share: share),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

String _dateText(WidgetTester tester, String key) =>
    tester.widget<Text>(find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(Text),
    ).last).data!;

String _summaryText(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('export-summary')),
        matching: find.byType(Text),
      ),
    )
    .map((t) => t.data ?? '')
    .join(' | ');

void main() {
  tearDown(Get.reset);

  /// Chờ `compute()` (isolate nền) chạy xong — `pumpAndSettle` chỉ bơm frame,
  /// không chờ async thật.
  Future<void> settleExport(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 400)),
    );
    await tester.pumpAndSettle();
  }

  group('US1 — khung màn & điểm vào', () {
    testWidgets('app bar teal + tiêu đề, không bottom nav', (tester) async {
      await _pump(tester, _seededRepo());
      expect(find.text('Xuất báo cáo'), findsWidgets);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.byKey(const ValueKey('report-export-screen')), findsOne);
    });

    testWidgets('đủ 5 mục lọc + hộp tóm tắt + dòng cảnh báo', (tester) async {
      await _pump(tester, _seededRepo());
      expect(find.text('KHOẢNG THỜI GIAN'), findsOne);
      expect(find.text('VÍ'), findsOne);
      expect(find.text('DANH MỤC'), findsOne);
      expect(find.text('TAG'), findsOne);
      expect(find.text('ĐỊNH DẠNG XUẤT'), findsOne);
      expect(find.byKey(const ValueKey('export-summary')), findsOne);
    });

    testWidgets('kỳ rỗng ⇒ màn vẫn mở đủ 5 mục + nút vô hiệu hoá',
        (tester) async {
      await _pump(tester, _emptyRepo());
      expect(find.text('KHOẢNG THỜI GIAN'), findsOne);
      expect(find.text('ĐỊNH DẠNG XUẤT'), findsOne);
      expect(find.byKey(const ValueKey('export-empty-notice')), findsOne);
      final button = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('export-button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('lỗi đọc dữ liệu ⇒ thông báo + nút thử lại', (tester) async {
      await _pump(tester, _ThrowingRepo());
      expect(
        find.text('Không đọc được dữ liệu để xuất báo cáo'),
        findsOne,
      );
      expect(find.text('Thử lại'), findsOne);
    });

    testWidgets('dòng cảnh báo hiện SẴN khi chưa bấm xuất', (tester) async {
      await _pump(tester, _seededRepo());
      expect(
        find.byKey(const ValueKey('export-privacy-warning')),
        findsOne,
      );
      expect(
        find.text(
          'Tệp xuất ra không còn được app bảo vệ. Hãy cẩn thận khi chia sẻ.',
        ),
        findsOne,
      );
    });
  });

  group('US1 — khoảng thời gian kế thừa kỳ đang xem', () {
    testWidgets('Tháng ⇒ 01/09/2026 – 30/09/2026', (tester) async {
      await _pump(tester, _seededRepo());
      expect(_dateText(tester, 'export-date-from'), '01/09/2026');
      expect(_dateText(tester, 'export-date-to'), '30/09/2026');
    });

    testWidgets('Năm ⇒ 01/01/2026 – 31/12/2026', (tester) async {
      await _pump(tester, _seededRepo(), period: ReportPeriod.year);
      expect(_dateText(tester, 'export-date-from'), '01/01/2026');
      expect(_dateText(tester, 'export-date-to'), '31/12/2026');
    });

    testWidgets('Ngày ⇒ đúng ngày đang xem (20/09)', (tester) async {
      await _pump(tester, _seededRepo(), period: ReportPeriod.day);
      expect(_dateText(tester, 'export-date-from'), '20/09/2026');
      expect(_dateText(tester, 'export-date-to'), '20/09/2026');
    });

    testWidgets('Tuần ⇒ Thứ Hai 14/09 – Chủ Nhật 20/09', (tester) async {
      await _pump(tester, _seededRepo(), period: ReportPeriod.week);
      expect(_dateText(tester, 'export-date-from'), '14/09/2026');
      expect(_dateText(tester, 'export-date-to'), '20/09/2026');
    });

    testWidgets('hộp tóm tắt hiện đúng số giao dịch + khoảng ngày',
        (tester) async {
      await _pump(tester, _seededRepo());
      // 4 giao dịch thu/chi + 2 vế chuyển khoản = 6 dòng.
      expect(_summaryText(tester), contains('6 giao dịch'));
      expect(_summaryText(tester), contains('01/09/2026 – 30/09/2026'));
      expect(_summaryText(tester), contains('Định dạng: PDF'));
    });
  });

  group('US1 — lọc ví / danh mục / tag', () {
    testWidgets('chip ví lọc lại hộp tóm tắt', (tester) async {
      await _pump(tester, _seededRepo());
      await tester.tap(find.byKey(const ValueKey('export-wallet-2')));
      await tester.pumpAndSettle();
      // ví 2: 1 chi + 1 vế chuyển khoản (không group-keep).
      expect(_summaryText(tester), contains('2 giao dịch'));
    });

    testWidgets('chip Tất cả xoá hết lựa chọn ví', (tester) async {
      await _pump(tester, _seededRepo());
      await tester.tap(find.byKey(const ValueKey('export-wallet-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-wallet-all')));
      await tester.pumpAndSettle();
      expect(_summaryText(tester), contains('6 giao dịch'));
    });

    testWidgets('chọn danh mục cha ⇒ gồm con', (tester) async {
      await _pump(tester, _seededRepo());
      await tester.tap(find.byKey(const ValueKey('export-cat-1')));
      await tester.pumpAndSettle();
      // 2 chi 'Ăn uống' (cha + con) — không có transfer/adjustment.
      expect(_summaryText(tester), contains('2 giao dịch'));
    });

    testWidgets('chip "+N khác" mở sheet đủ danh mục cha', (tester) async {
      await _pump(tester, _seededRepo());
      // 5 danh mục cha ⇒ 3 chip hiện + "+2 khác".
      expect(find.text('+2 khác'), findsOne);
      await tester.tap(find.byKey(const ValueKey('export-more-categories')));
      await tester.pumpAndSettle();
      expect(find.text('Chọn danh mục'), findsOne);
      for (final name in ['Ăn uống', 'Du lịch', 'Mua sắm', 'Đi lại', 'Lương']) {
        expect(find.text(name), findsWidgets, reason: name);
      }
    });

    testWidgets('chọn trong sheet rồi Xong ⇒ áp bộ lọc', (tester) async {
      await _pump(tester, _seededRepo());
      await tester.tap(find.byKey(const ValueKey('export-more-categories')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-cat-option-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-cat-done')));
      await tester.pumpAndSettle();
      expect(_summaryText(tester), contains('1 giao dịch'));
    });

    testWidgets('gõ tag lọc đúng giao dịch có tag', (tester) async {
      await _pump(tester, _seededRepo());
      await tester.enterText(
        find.byKey(const ValueKey('export-tag-field')),
        '#dulich',
      );
      await tester.pumpAndSettle();
      expect(_summaryText(tester), contains('1 giao dịch'));
    });

    testWidgets('tag không khớp gì ⇒ nút vô hiệu + thông báo', (tester) async {
      await _pump(tester, _seededRepo());
      await tester.enterText(
        find.byKey(const ValueKey('export-tag-field')),
        'khongtontai',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('export-empty-notice')), findsOne);
      final button = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('export-button')),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('US1 — định dạng xuất', () {
    testWidgets('mặc định PDF; chọn Excel ⇒ chỉ 1 thẻ chọn + dòng 2 đổi',
        (tester) async {
      await _pump(tester, _seededRepo());
      expect(_summaryText(tester), contains('Định dạng: PDF'));
      expect(_summaryText(tester), contains('Có biểu đồ'));

      await tester.tap(find.byKey(const ValueKey('export-format-excel')));
      await tester.pumpAndSettle();
      expect(_summaryText(tester), contains('Định dạng: Excel'));
      expect(_summaryText(tester), contains('Bảng dữ liệu'));
      expect(_summaryText(tester), isNot(contains('Định dạng: PDF')));
    });

    testWidgets('chọn CSV ⇒ dòng 2 đổi, không tạo tệp nào', (tester) async {
      final share = _FakeShare();
      await _pump(tester, _seededRepo(), share: share.call);
      await tester.tap(find.byKey(const ValueKey('export-format-csv')));
      await tester.pumpAndSettle();
      expect(_summaryText(tester), contains('Dữ liệu thô'));
      expect(share.calls, isEmpty);
    });
  });

  group('US4 — xuất PDF thật (font asset + compute)', () {
    testWidgets('mặc định PDF: seam lưu nhận bytes bắt đầu bằng %PDF', (tester) async {
      final save = _FakeSave();
      final share = _FakeShare();
      await _pump(tester, _seededRepo(), save: save.call, share: share.call);

      await tester.tap(find.byKey(const ValueKey('export-button')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tạo được tệp báo cáo'), findsNothing);
      expect(save.calls, hasLength(1));
      final call = save.calls.single;
      expect(call.fileName, 'bao-cao-thu-chi_20260901-20260930.pdf');
      expect(call.mimeType, 'application/pdf');
      expect(
        String.fromCharCodes(call.bytes.sublist(0, 4)),
        '%PDF',
        reason: 'bytes phải là tệp PDF hợp lệ',
      );
      expect(share.calls, hasLength(1));
      expect(share.calls.single.filePath, 'fake/downloads/${call.fileName}');
    });

    testWidgets('Excel: seam lưu nhận bytes zip (.xlsx)', (tester) async {
      final save = _FakeSave();
      final share = _FakeShare();
      await _pump(tester, _seededRepo(), save: save.call, share: share.call);
      await tester.tap(find.byKey(const ValueKey('export-format-excel')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('export-button')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Không tạo được tệp báo cáo'), findsNothing);
      expect(save.calls, hasLength(1));
      expect(save.calls.single.fileName, endsWith('.xlsx'));
      expect(save.calls.single.bytes.sublist(0, 2), [0x50, 0x4B]);
    });
  });

  group('US2 — xuất CSV qua seam chia sẻ', () {
    testWidgets('gọi seam đúng 1 lần, tên tệp + mime + bytes đúng',
        (tester) async {
      final save = _FakeSave();
      final share = _FakeShare();
      await _pump(tester, _seededRepo(), save: save.call, share: share.call);
      await tester.tap(find.byKey(const ValueKey('export-format-csv')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-button')));
      await settleExport(tester);

      expect(save.calls, hasLength(1));
      final call = save.calls.single;
      expect(call.fileName, 'bao-cao-thu-chi_20260901-20260930.csv');
      expect(call.mimeType, 'text/csv');
      expect(call.bytes, isNotEmpty);
      expect(share.calls, hasLength(1));
      expect(share.calls.single.fileName, call.fileName);
    });

    testWidgets('bấm 2 lần liên tiếp ⇒ seam chỉ gọi 1 lần', (tester) async {
      final save = _FakeSave();
      final share = _FakeShare()..gate = Completer<void>();
      await _pump(tester, _seededRepo(), save: save.call, share: share.call);
      await tester.tap(find.byKey(const ValueKey('export-format-csv')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('export-button')));
      // compute() xong, seam đang chờ `gate` ⇒ `_busy` vẫn bật.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('export-button')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(share.calls, hasLength(1));

      share.gate!.complete();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('seam chia sẻ ném lỗi ⇒ SnackBar + bộ lọc/định dạng giữ nguyên',
        (tester) async {
      final save = _FakeSave();
      final share = _FakeShare()..fail = true;
      await _pump(tester, _seededRepo(), save: save.call, share: share.call);
      await tester.tap(find.byKey(const ValueKey('export-wallet-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('export-format-csv')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('export-button')));
      await settleExport(tester);

      expect(find.text('Không tạo được tệp báo cáo'), findsOne);
      expect(_summaryText(tester), contains('2 giao dịch'));
      expect(_summaryText(tester), contains('Định dạng: CSV'));
      final button = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('export-button')),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('US1 — thông báo đường dẫn lưu tệp (PBI 41)', () {
    testWidgets('lưu thành công ⇒ SnackBar báo tên tệp trước khi gọi seam chia sẻ',
        (tester) async {
      final save = _FakeSave();
      final share = _FakeShare();
      await _pump(tester, _seededRepo(), save: save.call, share: share.call);
      await tester.tap(find.byKey(const ValueKey('export-format-csv')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('export-button')));
      await settleExport(tester);

      final fileName = save.calls.single.fileName;
      expect(find.textContaining(fileName), findsWidgets);
      expect(share.calls, hasLength(1));
      expect(share.calls.single.filePath, 'fake/downloads/$fileName');
    });

    testWidgets('seam lưu ném lỗi ⇒ thông báo lỗi tạo tệp, không gọi seam chia sẻ',
        (tester) async {
      final save = _FakeSave()..fail = true;
      final share = _FakeShare();
      await _pump(tester, _seededRepo(), save: save.call, share: share.call);
      await tester.tap(find.byKey(const ValueKey('export-format-csv')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('export-button')));
      await settleExport(tester);

      expect(find.text('Không tạo được tệp báo cáo'), findsOne);
      expect(share.calls, isEmpty);
    });

    testWidgets('seam lưu báo thiếu quyền ⇒ thông báo quyền lưu trữ riêng',
        (tester) async {
      final save = _FakeSave()..permissionDenied = true;
      final share = _FakeShare();
      await _pump(tester, _seededRepo(), save: save.call, share: share.call);
      await tester.tap(find.byKey(const ValueKey('export-format-csv')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('export-button')));
      await settleExport(tester);

      expect(find.text('Cần quyền lưu trữ để lưu tệp báo cáo'), findsOne);
      expect(find.text('Không tạo được tệp báo cáo'), findsNothing);
      expect(share.calls, isEmpty);
    });
  });
}
