import 'package:flutter/material.dart';

import '../../data/scan_deps.dart';
import '../../screens/add_transaction_screen.dart';
import '../../screens/scan/device_check_screen.dart';
import '../../screens/scan/scan_camera_screen.dart';
import '../../screens/scan/scan_processing_screen.dart';
import 'device_probe.dart';
import 'receipt_extractor.dart';
import 'receipt_ocr.dart';
import 'scan_controller.dart';
import 'scan_image_store.dart';

/// Điều phối luồng quét (plan.md §4): kiểm tra cấu hình (nếu cần) → chụp ảnh →
/// xử lý → xác nhận. Trả `true` nếu đã lưu giao dịch để `AppShell` làm mới danh
/// sách + Tổng quan + Báo cáo (SC-015). Huỷ ở bất kỳ bước nào → `false` và
/// **không** ghi gì (FR-036).
Future<bool> startScanFlow(
  BuildContext context, {
  ScanController? controller,
  ReceiptOcr? ocr,
  ReceiptExtractor? extractor,
  ScanImageStore? imageStore,
  DeviceProbe? probe,
  DateTime Function()? now,
  CameraGateway? cameraGateway,
  Widget Function()? legacyFormBuilder,
}) async {
  final scan = controller ?? ensureScanController();
  final clock = now ?? DateTime.now;
  if (!scan.settings.value.enabled) return false;

  while (true) {
    if (!context.mounted) return false;
    // Kết quả đo đã lưu được tái sử dụng; chỉ đo lại khi chưa có hoặc quá 30
    // ngày (FR-008) hoặc người dùng bấm "Kiểm tra lại" ở màn Cài đặt.
    if (scan.settings.value.needsDeviceCheck(clock())) {
      final proceed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => DeviceCheckScreen(controller: scan),
        ),
      );
      if (proceed != true) return false;
    }

    // Mỗi bước đều có `await` → kiểm tra context còn sống trước khi đẩy tiếp.
    if (!context.mounted) return false;
    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ScanCameraScreen(gateway: cameraGateway),
      ),
    );
    if (imagePath == null || !context.mounted) return false;

    final step = await Navigator.of(context).push<ScanStepResult>(
      MaterialPageRoute<ScanStepResult>(
        builder: (_) => ScanProcessingScreen(
          imagePath: imagePath,
          ocr: ocr,
          // Tier A/B (đã tải model) → LLM; còn lại → bộ luật (T057/FR-012).
          extractor: extractor ?? extractorForSettings(scan.settings.value),
          imageStore: imageStore,
          now: clock,
        ),
      ),
    );
    if (!context.mounted) return false;

    switch (step) {
      case ScanStepResult.saved:
        return true;
      case ScanStepResult.retry:
        continue; // quay lại màn chụp, giữ nguyên kết quả kiểm tra cấu hình.
      case ScanStepResult.manualEntry:
        // "Nhập tay" → form thêm giao dịch **trống** (không mang dữ liệu quét).
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) =>
                legacyFormBuilder?.call() ?? const AddTransactionScreen(),
          ),
        );
        return saved == true;
      case ScanStepResult.cancelled:
      case null:
        return false;
    }
  }
}
