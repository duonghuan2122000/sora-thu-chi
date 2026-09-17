import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';
import 'package:sora_thu_chi/data/wallet_repository.dart';
import 'package:sora_thu_chi/screens/tag_picker_screen.dart';

import 'fakes/fake_wallet_repository.dart';

/// Ngữ cảnh một test màn chọn tag: repo fake + kết quả pop (bám mẫu `_Ctx` của
/// `add_transaction_screen_test.dart` — bắt giá trị pop **sau** khi tương tác,
/// không phải giá trị tại thời điểm mở màn).
class _Ctx {
  _Ctx(this.repo);
  final FakeWalletRepository repo;
  List<String>? result;
}

Transaction _txnWithTags(int id, String tags) => Transaction(
  id: id,
  walletId: 1,
  type: TxnType.expense,
  amount: -1000,
  date: DateTime(2026, 9, 1),
  tags: tags,
);

/// Pump `TagPickerScreen` đẩy lên từ một host, seed sẵn giao dịch mang tag để
/// dựng danh sách gợi ý (PBI 38, chốt 2B — màn riêng, không hộp thoại gõ tự do).
Future<_Ctx> _pumpPicker(
  WidgetTester tester, {
  List<String> initialSelected = const [],
  List<Transaction>? seedTransactions,
}) async {
  Get.reset();
  final repo = FakeWalletRepository(
    [Wallet(id: 1, name: 'Tiền mặt', type: WalletType.cash, balance: 0)],
    null,
    seedTransactions ?? const [],
  );
  Get.put<WalletRepository>(repo);
  addTearDown(Get.reset);
  final ctx = _Ctx(repo);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                ctx.result = await Navigator.of(context).push<List<String>>(
                  MaterialPageRoute(
                    builder: (_) => TagPickerScreen(
                      repository: repo,
                      initialSelected: initialSelected,
                    ),
                  ),
                );
              },
              child: const Text('open-picker'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open-picker'));
  await tester.pumpAndSettle();
  return ctx;
}

void main() {
  group('TagPickerScreen — màn chọn/tạo tag (PBI 38, chốt 2B)', () {
    testWidgets('(a) chưa có tag nào → vẫn gõ tạo tag mới được', (tester) async {
      final ctx = await _pumpPicker(tester);

      expect(find.text('Chọn tag'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('new-tag-field')), 'ăn trưa');
      await tester.tap(find.byKey(const ValueKey('add-tag-button')));
      await tester.pumpAndSettle();
      expect(find.text('ăn trưa'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('confirm-tags')));
      await tester.pumpAndSettle();

      expect(ctx.result, ['ăn trưa']);
    });

    testWidgets('(b) danh sách gợi ý lấy từ tag đã dùng trước đó', (tester) async {
      await _pumpPicker(
        tester,
        seedTransactions: [
          _txnWithTags(1, 'công ty, ăn trưa'),
          _txnWithTags(2, 'ăn trưa, xăng xe'),
        ],
      );

      // Gộp + khử trùng — mỗi tag chỉ hiện 1 lần dù xuất hiện ở nhiều giao dịch.
      expect(find.text('công ty'), findsOneWidget);
      expect(find.text('ăn trưa'), findsOneWidget);
      expect(find.text('xăng xe'), findsOneWidget);
    });

    testWidgets('(c) chọn nhiều tag có sẵn rồi xác nhận → trả đúng list', (tester) async {
      final ctx = await _pumpPicker(
        tester,
        seedTransactions: [_txnWithTags(1, 'công ty, ăn trưa')],
      );

      await tester.tap(find.text('công ty'));
      await tester.tap(find.text('ăn trưa'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('confirm-tags')));
      await tester.pumpAndSettle();

      expect(ctx.result, unorderedEquals(['công ty', 'ăn trưa']));
    });

    testWidgets('(d) tên tag rỗng/toàn khoảng trắng → không cho tạo', (tester) async {
      await _pumpPicker(tester);

      await tester.enterText(find.byKey(const ValueKey('new-tag-field')), '   ');
      await tester.tap(find.byKey(const ValueKey('add-tag-button')));
      await tester.pumpAndSettle();

      // Không có chip nào được tạo thêm ngoài trạng thái rỗng ban đầu.
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('(e) tạo tag trùng tên (khác hoa/thường) → không tạo trùng lặp', (tester) async {
      await _pumpPicker(
        tester,
        seedTransactions: [_txnWithTags(1, 'Ăn trưa')],
      );

      await tester.enterText(find.byKey(const ValueKey('new-tag-field')), 'ăn trưa');
      await tester.tap(find.byKey(const ValueKey('add-tag-button')));
      await tester.pumpAndSettle();

      expect(find.text('Ăn trưa'), findsOneWidget);
      expect(find.text('ăn trưa'), findsNothing);
      expect(find.byType(FilterChip), findsOneWidget); // vẫn chỉ 1 chip.
    });

    testWidgets('(f) đã chọn sẵn từ trước (sửa lại) → tick sẵn, xác nhận giữ nguyên', (tester) async {
      final ctx = await _pumpPicker(
        tester,
        initialSelected: const ['ăn trưa'],
        seedTransactions: [_txnWithTags(1, 'ăn trưa, công ty')],
      );

      final chip = tester.widget<FilterChip>(
        find.ancestor(
          of: find.text('ăn trưa'),
          matching: find.byType(FilterChip),
        ),
      );
      expect(chip.selected, isTrue);

      await tester.tap(find.byKey(const ValueKey('confirm-tags')));
      await tester.pumpAndSettle();
      expect(ctx.result, ['ăn trưa']);
    });
  });
}
