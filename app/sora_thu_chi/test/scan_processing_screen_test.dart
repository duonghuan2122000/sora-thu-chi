import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/scan/receipt_extractor.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/screens/scan/scan_confirm_screen.dart';
import 'package:sora_thu_chi/screens/scan/scan_processing_screen.dart';
import 'package:sora_thu_chi/theme/app_theme.dart';

import 'fakes/fake_scan_image_store.dart';
import 'fakes/fake_scan_log_session.dart';
import 'fakes/fake_scan_ocr.dart';
import 'fakes/fake_wallet_repository.dart';

/// Extractor giả — chỉ ghi lại tham số [image] nhận được, trả kết quả cố định
/// (PBI 37: xác nhận `ScanProcessingScreen` truyền đúng bytes ảnh đã tiền xử lý).
class _RecordingExtractor implements ReceiptExtractor {
  _RecordingExtractor({this.supportsImage = false});

  Uint8List? lastImage;

  @override
  final bool supportsImage;

  @override
  Future<ScanExtraction> extract({
    required List<ScanTextLine> lines,
    required DateTime now,
    required List<Category> expenseCategories,
    required List<Category> incomeCategories,
    ScanEngine engine = ScanEngine.ruleBased,
    Uint8List? image,
  }) async {
    lastImage = image;
    return ScanExtraction(
      type: TxnType.expense,
      amount: const ScanField<int>(value: 55000, confidence: FieldConfidence.high),
    );
  }
}

final _imageBytes = Uint8List.fromList([1, 2, 3, 4]);

final _invoiceLines = [
  const ScanTextLine(
    text: 'CIRCLE K VIỆT NAM',
    rect: ScanRect(left: 0.1, top: 0.05, right: 0.9, bottom: 0.1),
  ),
  const ScanTextLine(
    text: 'TỔNG CỘNG 55.000',
    rect: ScanRect(left: 0.1, top: 0.5, right: 0.9, bottom: 0.55),
  ),
];

/// Màn cao đủ để ListView dựng hết nội dung (mặc định 600px không đủ).
void useTallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class Host {
  ScanStepResult? result;
}

/// Pump host có nút đẩy màn xử lý rồi mở màn đó (I/O thật thay bằng seam —
/// test widget không chạy được I/O thật).
Future<Host> pushProcessing(
  WidgetTester tester, {
  required FakeScanOcr ocr,
  required FakeWalletRepository repository,
  FakeScanImageStore? imageStore,
  ReceiptExtractor? extractor,
}) async {
  final host = Host();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: Builder(
        builder: (context) => ElevatedButton(
          key: const ValueKey('start'),
          onPressed: () async {
            host.result = await Navigator.of(context).push<ScanStepResult>(
              MaterialPageRoute(
                builder: (_) => ScanProcessingScreen(
                  imagePath: '/tmp/hoa-don.jpg',
                  ocr: ocr,
                  extractor: extractor,
                  repository: repository,
                  imageStore: imageStore ?? FakeScanImageStore(),
                  now: () => DateTime(2026, 9, 12, 8, 24),
                  preprocess: (bytes) async => bytes,
                  readBytes: (_) async => _imageBytes,
                  scanLogStore: FakeScanLogStore(),
                  scanLogImageStore: FakeScanLogImageStore(),
                ),
              ),
            );
          },
          child: const Text('bắt đầu'),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('start')));
  await tester.pump();
  return host;
}

void main() {
  testWidgets('4 bước hiện đủ; bước đang chạy khác bước đã xong', (tester) async {
    useTallView(tester);
    final ocr = FakeScanOcr(_invoiceLines)..gate = Completer<void>();

    await pushProcessing(tester, ocr: ocr, repository: FakeWalletRepository());
    // Cho pipeline chạy tới bước OCR (đang bị gate giữ) + hết hiệu ứng đẩy màn.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Đọc & xử lý ảnh hóa đơn'), findsOneWidget);
    expect(find.text('Nhận diện chữ (OCR on-device)'), findsOneWidget);
    expect(find.text('Phân tích số tiền, ngày, danh mục'), findsOneWidget);
    expect(find.text('Chuẩn bị màn hình xác nhận'), findsOneWidget);
    expect(find.text('Đang xử lý hóa đơn...'), findsOneWidget);
    expect(find.text('Không gửi dữ liệu lên bất kỳ máy chủ nào'), findsOneWidget);

    // OCR đang bị gate giữ ⇒ bước 2 "đang chạy", 0/1 đã xong, 3 chưa tới.
    expect(find.byKey(const ValueKey('scan-step-2-running')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-step-0-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-step-1-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-step-3-pending')), findsOneWidget);

    ocr.gate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('OCR đọc được chữ → đẩy sang màn xác nhận', (tester) async {
    useTallView(tester);
    await pushProcessing(
      tester,
      ocr: FakeScanOcr(_invoiceLines),
      repository: FakeWalletRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ScanConfirmScreen), findsOneWidget);
    expect(find.text('Xác nhận hóa đơn'), findsOneWidget);
    expect(find.text('55.000 đ'), findsOneWidget);
  });

  testWidgets('OCR không đọc được gì → thông báo + 2 nút, không ghi gì',
      (tester) async {
    useTallView(tester);
    final repository = FakeWalletRepository();
    final imageStore = FakeScanImageStore();
    final host = await pushProcessing(
      tester,
      ocr: FakeScanOcr(const []),
      repository: repository,
      imageStore: imageStore,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Không nhận diện được nội dung hóa đơn. Vui lòng chụp lại hoặc nhập tay.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('scan-retry')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-manual')), findsOneWidget);
    expect(find.byType(ScanConfirmScreen), findsNothing);

    // "Chụp lại" → trả retry để luồng mở lại màn chụp.
    await tester.tap(find.byKey(const ValueKey('scan-retry')));
    await tester.pumpAndSettle();
    expect(host.result, ScanStepResult.retry);

    // Không seam ghi nào được gọi: không giao dịch quét, không file ảnh mới.
    expect(repository.scannedCalls, isEmpty);
    expect(imageStore.saved, isEmpty);
  });

  testWidgets(
    'truyền đúng bytes ảnh đã tiền xử lý cho extractor (PBI 37)',
    (tester) async {
      useTallView(tester);
      final extractor = _RecordingExtractor();
      await pushProcessing(
        tester,
        ocr: FakeScanOcr(_invoiceLines),
        repository: FakeWalletRepository(),
        extractor: extractor,
      );
      await tester.pumpAndSettle();

      expect(extractor.lastImage, _imageBytes);
    },
  );

  testWidgets(
    'OCR rỗng nhưng extractor tự đọc ảnh (Tier A) → vẫn đẩy sang màn xác nhận',
    (tester) async {
      useTallView(tester);
      final extractor = _RecordingExtractor(supportsImage: true);
      await pushProcessing(
        tester,
        ocr: FakeScanOcr(const []),
        repository: FakeWalletRepository(),
        extractor: extractor,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ScanConfirmScreen), findsOneWidget);
      expect(extractor.lastImage, _imageBytes);
    },
  );

  testWidgets('"Nhập tay" → trả manualEntry', (tester) async {
    useTallView(tester);
    final host = await pushProcessing(
      tester,
      ocr: FakeScanOcr(const []),
      repository: FakeWalletRepository(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('scan-manual')));
    await tester.pumpAndSettle();
    expect(host.result, ScanStepResult.manualEntry);
  });
}
