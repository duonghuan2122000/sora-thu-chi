import 'dart:io';


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/category/category.dart';
import '../../core/scan/image_preprocess.dart';
import '../../core/scan/receipt_extractor.dart';
import '../../core/scan/receipt_ocr.dart';
import '../../core/scan/scan_image_store.dart';
import '../../core/scan/scan_result.dart';
import '../../data/scan_deps.dart';
import '../../data/wallet_deps.dart';
import '../../data/wallet_repository.dart';
import '../../theme/sora_colors.dart';
import 'scan_confirm_screen.dart';

/// Kết quả một bước của luồng quét — màn xử lý pop về cho `scan_flow` biết
/// bước tiếp theo (đọc không được ⇒ người dùng chọn chụp lại hay nhập tay).
enum ScanStepResult { saved, retry, manualEntry, cancelled }

/// Màn xử lý (mockup `scan-03`): ảnh thu nhỏ + vệt quét, 4 bước có trạng thái
/// xong/đang chạy/chưa tới, dòng cam kết không gửi dữ liệu đi đâu. Pipeline
/// chạy trong `initState`: tiền xử lý (isolate) → OCR → bộ luật → màn xác nhận.
/// Không đọc được chữ → thông báo + 2 nút, **không** gọi seam ghi nào (FR-020).
class ScanProcessingScreen extends StatefulWidget {
  const ScanProcessingScreen({
    super.key,
    required this.imagePath,
    this.ocr,
    this.extractor,
    this.repository,
    this.imageStore,
    this.now,
    this.preprocess,
    this.readBytes,
  });

  final String imagePath;
  final ReceiptOcr? ocr;
  final ReceiptExtractor? extractor;
  final WalletRepository? repository;
  final ScanImageStore? imageStore;
  final DateTime Function()? now;

  /// Seam test cho bước tiền xử lý; mặc định chạy [preprocessForOcr] trong
  /// isolate (`compute`) để không chặn UI (SC-007).
  final Future<Uint8List> Function(Uint8List)? preprocess;

  /// Seam test cho bước đọc file ảnh (test widget không chạy I/O thật được).
  final Future<Uint8List> Function(String path)? readBytes;

  @override
  State<ScanProcessingScreen> createState() => _ScanProcessingScreenState();
}

class _ScanProcessingScreenState extends State<ScanProcessingScreen> {
  static const List<String> _stepLabels = [
    'Đọc & xử lý ảnh hóa đơn',
    'Nhận diện chữ (OCR on-device)',
    'Phân tích số tiền, ngày, danh mục',
    'Chuẩn bị màn hình xác nhận',
  ];

  /// Bước đang chạy (0..3); 4 = xong hết.
  int _step = 0;
  bool _unreadable = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final ocr = widget.ocr ?? ensureReceiptOcr();
    final extractor = widget.extractor ?? const RuleBasedExtractor();
    final repository = widget.repository ?? ensureWalletRepository();
    final now = (widget.now ?? DateTime.now)();

    try {
      setState(() => _step = 1);
      final bytes = await (widget.readBytes ?? _readFile)(widget.imagePath);
      final preprocess = widget.preprocess;
      final processed = preprocess != null
          ? await preprocess(bytes)
          : await compute(preprocessForOcr, bytes);

      setState(() => _step = 2);
      final lines = await ocr.readText(processed);

      if (lines.isEmpty) {
        if (!mounted) return;
        setState(() => _unreadable = true);
        return;
      }

      setState(() => _step = 3);
      final expense = await repository.categories(type: CategoryType.expense);
      final income = await repository.categories(type: CategoryType.income);
      final extraction = await extractor.extract(
        lines: lines,
        now: now,
        expenseCategories: expense,
        incomeCategories: income,
      );

      if (!mounted) return;
      setState(() => _step = 4);
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ScanConfirmScreen(
            extraction: extraction,
            imagePath: widget.imagePath,
            rawText: _joinLines(lines),
            repository: repository,
            imageStore: widget.imageStore,
            now: now,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved == true ? ScanStepResult.saved : ScanStepResult.cancelled);
    } catch (_) {
      if (!mounted) return;
      setState(() => _unreadable = true);
    }
  }

  static String _joinLines(List<ScanTextLine> lines) =>
      lines.map((l) => l.text).join('\n');

  static Future<Uint8List> _readFile(String path) => File(path).readAsBytes();

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(ScanStepResult.cancelled);
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Quét hóa đơn'.tr)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _thumbnail(colors),
            const SizedBox(height: 20),
            if (_unreadable)
              _unreadableBlock(colors)
            else ...[
              Text(
                'Đang xử lý hóa đơn...'.tr,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Toàn bộ xử lý diễn ra ngay trên máy của bạn'.tr,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < _stepLabels.length; i++) _stepRow(i, colors),
              const SizedBox(height: 18),
              Text(
                'Không gửi dữ liệu lên bất kỳ máy chủ nào'.tr,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Ảnh thu nhỏ + "vệt quét" khi đang xử lý.
  Widget _thumbnail(SoraColors colors) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Image.file(
            File(widget.imagePath),
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 180,
              color: colors.softCardBg,
              alignment: Alignment.center,
              child: Icon(
                Icons.receipt_long_outlined,
                color: colors.tabInactive,
                size: 40,
              ),
            ),
          ),
          // "Vệt quét" chỉ chạy khi còn đang xử lý — xong thì tắt (mockup + để
          // màn không giữ animation vô hạn).
          if (!_unreadable && _step < 4)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
        ],
      ),
    );
  }

  Widget _stepRow(int index, SoraColors colors) {
    final done = index < _step;
    final running = index == _step;
    final icon = done
        ? Icons.check_circle
        : running
        ? Icons.radio_button_checked
        : Icons.radio_button_unchecked;
    final color = done || running ? colors.tealOnNeutral : colors.tabInactive;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            key: ValueKey('scan-step-$index-${done
                ? 'done'
                : running
                ? 'running'
                : 'pending'}'),
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _stepLabels[index].tr,
              style: TextStyle(
                color: done || running ? colors.textPrimary : colors.tabInactive,
                fontSize: 14,
                fontWeight: running ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unreadableBlock(SoraColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Không nhận diện được nội dung hóa đơn. Vui lòng chụp lại hoặc nhập tay.'.tr,
          style: TextStyle(color: colors.textPrimary, fontSize: 15),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            key: const ValueKey('scan-retry'),
            onPressed: () =>
                Navigator.of(context).pop(ScanStepResult.retry),
            child: Text('Chụp lại'.tr),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            key: const ValueKey('scan-manual'),
            onPressed: () =>
                Navigator.of(context).pop(ScanStepResult.manualEntry),
            child: Text('Nhập tay'.tr),
          ),
        ),
      ],
    );
  }
}
