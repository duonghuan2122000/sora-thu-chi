import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;

import '../../../core/scan/scan_result.dart';
import '../../../theme/app_colors.dart';

/// Ảnh hóa đơn gốc trong [InteractiveViewer] + lớp phủ **khoanh vùng** theo
/// [highlight] (thuộc tính 0..1 — xem [ScanRect]). Không xác định vùng → không
/// khoanh gì (FR-029). Dùng cho "Xem ảnh gốc" ở màn xác nhận và lớp đối chiếu
/// khi chạm một trường.
class ReceiptViewer extends StatefulWidget {
  const ReceiptViewer({
    super.key,
    required this.imagePath,
    this.highlight,
    this.showAppBar = true,
  });

  final String imagePath;
  final ScanRect? highlight;

  /// `false` khi nhúng vào màn xác nhận (không tự dựng app bar).
  final bool showAppBar;

  @override
  State<ReceiptViewer> createState() => _ReceiptViewerState();
}

class _ReceiptViewerState extends State<ReceiptViewer> {
  late final Future<Size?> _size = _readSize();

  /// Kích thước ảnh thật — cần để tỉ lệ vùng khoanh khớp ảnh (ảnh không đọc
  /// được → null, chỉ hiện ảnh).
  Future<Size?> _readSize() async {
    try {
      final decoded = img.decodeImage(await File(widget.imagePath).readAsBytes());
      if (decoded == null) return null;
      return Size(decoded.width.toDouble(), decoded.height.toDouble());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: FutureBuilder<Size?>(
          future: _size,
          builder: (context, snapshot) {
            final size = snapshot.data;
            if (size == null || size.isEmpty) {
              return _imageOnly();
            }
            return InteractiveViewer(
              maxScale: 5,
              child: AspectRatio(
                aspectRatio: size.width / size.height,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    fit: StackFit.expand,
                    children: [
                      _imageOnly(),
                      if (widget.highlight != null)
                        _highlightBox(widget.highlight!, constraints),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (!widget.showAppBar) return body;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Ảnh hóa đơn'.tr),
      ),
      body: body,
    );
  }

  Widget _imageOnly() => Image.file(
    File(widget.imagePath),
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) => const Center(
      child: Icon(Icons.receipt_long_outlined, color: Colors.white54, size: 48),
    ),
  );

  Widget _highlightBox(ScanRect rect, BoxConstraints constraints) {
    return Positioned(
      key: const ValueKey('receipt-highlight'),
      left: rect.left * constraints.maxWidth,
      top: rect.top * constraints.maxHeight,
      width: rect.width * constraints.maxWidth,
      height: rect.height * constraints.maxHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.coral, width: 2),
          color: AppColors.coral.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
