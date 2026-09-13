import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/locale/sora_translations.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/screens/scan/scan_confirm_screen.dart';
import 'package:sora_thu_chi/screens/scan/widgets/receipt_viewer.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';
import 'package:sora_thu_chi/theme/sora_colors.dart';

import 'fakes/fake_scan_image_store.dart';
import 'fakes/fake_wallet_repository.dart';

const _amountRect = ScanRect(left: 0.1, top: 0.5, right: 0.9, bottom: 0.55);
const _merchantRect = ScanRect(left: 0.1, top: 0.05, right: 0.9, bottom: 0.1);
const _dateRect = ScanRect(left: 0.1, top: 0.6, right: 0.9, bottom: 0.65);

final _eatCategory = CategorySource.all.firstWhere((c) => c.name == 'Ăn uống');

ScanExtraction extraction({
  int? amount = 55000,
  FieldConfidence amountConfidence = FieldConfidence.high,
  FieldConfidence merchantConfidence = FieldConfidence.low,
  Category? category,
}) => ScanExtraction(
  amount: ScanField(
    value: amount,
    confidence: amountConfidence,
    rect: amount == null ? null : _amountRect,
  ),
  date: ScanField(
    value: DateTime(2026, 9, 12, 8, 24),
    confidence: FieldConfidence.high,
    rect: _dateRect,
  ),
  merchant: ScanField(
    value: 'CIRCLE K VIỆT NAM',
    confidence: merchantConfidence,
    rect: _merchantRect,
  ),
  category: ScanField(
    value: category,
    confidence: FieldConfidence.medium,
  ),
  engine: ScanEngine.ruleBased,
);

/// Màn cao đủ để ListView dựng hết nội dung.
void useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class Host {
  bool? result;
}

Future<Host> pumpConfirm(
  WidgetTester tester, {
  required FakeWalletRepository repository,
  ScanExtraction? scan,
  FakeScanImageStore? imageStore,
  bool english = false,
}) async {
  useTallView(tester);
  if (english) {
    Get.addTranslations(SoraTranslations().keys);
    Get.locale = const Locale('en');
    addTearDown(() => Get.locale = null);
  }
  final host = Host();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Builder(
        builder: (context) => ElevatedButton(
          key: const ValueKey('start'),
          onPressed: () async {
            host.result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ScanConfirmScreen(
                  extraction: scan ?? extraction(),
                  imagePath: '/tmp/hoa-don.jpg',
                  rawText: 'CIRCLE K\nTỔNG CỘNG 55.000',
                  repository: repository,
                  imageStore: imageStore ?? FakeScanImageStore(),
                  now: DateTime(2026, 9, 12, 8, 24),
                  readBytes: (_) async => Uint8List.fromList([1, 2, 3]),
                ),
              ),
            );
          },
          child: const Text('mở'),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('start')));
  await tester.pumpAndSettle();
  return host;
}

void main() {
  testWidgets('Vẽ đủ 6 trường + ảnh + dòng nguồn + nút lưu', (tester) async {
    await pumpConfirm(tester, repository: FakeWalletRepository());

    expect(find.byKey(const ValueKey('scan-confirm-screen')), findsOneWidget);
    expect(find.text('Xác nhận hóa đơn'), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-view-original')), findsOneWidget);
    expect(find.text('LOẠI GIAO DỊCH'), findsOneWidget);
    expect(find.text('SỐ TIỀN'), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-date-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-merchant-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-category-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-wallet-field')), findsOneWidget);
    expect(find.text('55.000 đ'), findsOneWidget);
    expect(
      find.text('Nguồn: Quét hóa đơn (AI) • xử lý hoàn toàn trên máy'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('scan-save')), findsOneWidget);
    // Không có bottom nav — màn con phủ shell.
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('Số tiền rỗng → nút lưu vô hiệu; nhập số hợp lệ → bật', (tester) async {
    await pumpConfirm(
      tester,
      repository: FakeWalletRepository(),
      scan: extraction(amount: null, amountConfidence: FieldConfidence.low),
    );

    ElevatedButton saveButton() =>
        tester.widget<ElevatedButton>(find.byKey(const ValueKey('scan-save')));
    expect(saveButton().onPressed, isNull);
    expect(find.text('0 đ'), findsOneWidget);

    for (final digit in ['5', '5', '0', '0', '0']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    expect(find.text('55.000 đ'), findsOneWidget);
    expect(saveButton().onPressed, isNotNull);
  });

  testWidgets('Nhãn tin cậy: rỗng/thấp → coral "Kiểm tra lại"; cao → teal',
      (tester) async {
    await pumpConfirm(
      tester,
      repository: FakeWalletRepository(),
      scan: extraction(amountConfidence: FieldConfidence.high),
    );

    // Cửa hàng suy theo cỡ chữ ⇒ low ⇒ "Kiểm tra lại" (coral).
    final review = tester.widget<Text>(
      find.byKey(const ValueKey('scan-confidence-merchant')),
    );
    final high = tester.widget<Text>(
      find.byKey(const ValueKey('scan-confidence-amount')),
    );
    expect(review.data, 'Kiểm tra lại');
    expect(high.data, 'Độ tin cậy cao');
    expect(review.style!.color, isNot(high.style!.color));
    // Nhãn coral đúng ngữ nghĩa cảnh báo của design system.
    expect(review.style!.color, SoraColors.light.coralOnNeutral);
    expect(high.style!.color, SoraColors.light.tealOnNeutral);
  });

  testWidgets('Chạm trường → ảnh khoanh đúng vùng của trường đó', (tester) async {
    await pumpConfirm(tester, repository: FakeWalletRepository());

    ReceiptViewer viewer() =>
        tester.widget<ReceiptViewer>(find.byType(ReceiptViewer).first);
    expect(viewer().highlight, isNull);

    void expectRect(ScanRect? actual, ScanRect expected) {
      expect(actual, isNotNull);
      expect(actual!.left, expected.left);
      expect(actual.top, expected.top);
      expect(actual.right, expected.right);
      expect(actual.bottom, expected.bottom);
    }

    await tester.tap(find.byKey(const ValueKey('scan-amount-field')));
    await tester.pump();
    expectRect(viewer().highlight, _amountRect);

    // Trường Cửa hàng khoanh vùng của chính nó (khác vùng số tiền).
    await tester.tap(find.byKey(const ValueKey('scan-merchant-field')));
    await tester.pump();
    expectRect(viewer().highlight, _merchantRect);

    // Bỏ focus để không còn con trỏ nhấp nháy khi kết thúc test.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
  });

  testWidgets('Có giao dịch cùng số tiền trong 24h → hiện banner trùng',
      (tester) async {
    final repository = FakeWalletRepository.withCategories(
      transactions: [
        Transaction(
          id: 1,
          walletId: 1,
          type: TxnType.expense,
          amount: -55000,
          date: DateTime(2026, 9, 12, 7),
        ),
      ],
    );
    await pumpConfirm(tester, repository: repository);
    expect(find.byKey(const ValueKey('scan-duplicate-banner')), findsOneWidget);
  });

  testWidgets('Không có giao dịch trùng → không hiện banner', (tester) async {
    await pumpConfirm(
      tester,
      repository: FakeWalletRepository.withCategories(),
    );
    expect(find.byKey(const ValueKey('scan-duplicate-banner')), findsNothing);
  });

  testWidgets('Bấm lưu 2 lần → repo chỉ nhận 1 lần gọi', (tester) async {
    final repository = FakeWalletRepository();
    final imageStore = FakeScanImageStore();
    final host = await pumpConfirm(
      tester,
      repository: repository,
      imageStore: imageStore,
    );

    await tester.tap(find.byKey(const ValueKey('scan-save')));
    await tester.tap(find.byKey(const ValueKey('scan-save')));
    await tester.pumpAndSettle();

    expect(repository.scannedCalls, hasLength(1));
    expect(imageStore.saved, hasLength(1));
    expect(host.result, isTrue);
  });

  testWidgets('Sửa danh mục/ghi chú rồi lưu → tham số xuống repo đúng',
      (tester) async {
    final repository = FakeWalletRepository();
    await pumpConfirm(tester, repository: repository);

    await tester.enterText(
      find.byKey(const ValueKey('scan-merchant-field')),
      'Circle K - Trần Duy Hưng',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('scan-save')));
    await tester.pumpAndSettle();

    final call = repository.scannedCalls.single;
    expect(call.amount, 55000);
    expect(call.type, TxnType.expense);
    expect(call.note, 'Circle K - Trần Duy Hưng');
    expect(call.engine, ScanEngine.ruleBased);
    expect(call.rawText, contains('TỔNG CỘNG'));
    expect(call.parsedJson, contains('"amount":55000'));
    expect(call.receiptImage, isNotEmpty);
    // Giao dịch ghi vào repo mang nguồn aiScan + ảnh.
    final saved = (await repository.allTransactions())
        .firstWhere((t) => t.amount == -55000 && t.source == TxnSource.aiScan);
    expect(saved.receiptImage, isNotEmpty);
  });

  testWidgets('Danh mục gợi ý sẵn → lưu xuống repo kèm category', (tester) async {
    final repository = FakeWalletRepository();
    await pumpConfirm(
      tester,
      repository: repository,
      scan: extraction(category: _eatCategory),
    );

    expect(find.text('Ăn uống'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scan-save')));
    await tester.pumpAndSettle();
    expect(repository.scannedCalls.single.category?.name, 'Ăn uống');
  });

  testWidgets('Lưu lỗi → thông báo tiếng Việt, không pop', (tester) async {
    final repository = FakeWalletRepository()..failOnScanned = true;
    final host = await pumpConfirm(tester, repository: repository);

    await tester.tap(find.byKey(const ValueKey('scan-save')));
    await tester.pumpAndSettle();

    expect(find.text('Không lưu được giao dịch. Vui lòng thử lại.'), findsOneWidget);
    expect(host.result, isNull);
    expect(find.byKey(const ValueKey('scan-confirm-screen')), findsOneWidget);
  });

  testWidgets('English → không còn nhãn tiếng Việt', (tester) async {
    await pumpConfirm(tester, repository: FakeWalletRepository(), english: true);

    expect(find.text('Confirm receipt'), findsOneWidget);
    expect(find.text('AMOUNT'), findsOneWidget);
    expect(find.text('Save transaction'), findsOneWidget);
    expect(find.text('Xác nhận hóa đơn'), findsNothing);
    expect(find.text('SỐ TIỀN'), findsNothing);
    expect(find.text('Lưu giao dịch'), findsNothing);
  });
}
