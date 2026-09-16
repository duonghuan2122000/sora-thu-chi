import 'package:get/get.dart';

import '../core/scan/device_probe.dart';
import '../core/scan/llm_extractor.dart';
import '../core/scan/model_manager.dart';
import '../core/scan/receipt_extractor.dart';
import '../core/scan/receipt_ocr.dart';
import '../core/scan/scan_controller.dart';
import '../core/scan/scan_image_store.dart';
import '../core/scan/scan_result.dart';
import '../core/scan/scan_settings.dart';
import '../core/scan/scan_settings_store.dart';
import 'db/app_database.dart';
import 'platform/device_probe_platform.dart';
import 'platform/gemma_llm.dart';
import 'platform/gemma_model_manager.dart';
import 'platform/gemini_nano_llm.dart';
import 'scan_settings_store_drift.dart';

/// Đăng ký các singleton của tính năng quét hóa đơn (bám `ensureThemeStore` /
/// `ensureUtilitiesStore`). Test đăng ký fake (Get.put) trước → hàm trả về fake
/// đó, không tạo drift/plugin thật.

ScanSettingsStore ensureScanSettingsStore() {
  if (Get.isRegistered<ScanSettingsStore>()) {
    return Get.find<ScanSettingsStore>();
  }
  final store = DriftScanSettingsStore(AppDatabase());
  Get.put<ScanSettingsStore>(store);
  return store;
}

/// `ScanController` giữ trạng thái công tắc/chế độ dùng chung cho sheet FAB và
/// màn Cài đặt ⇒ đăng ký singleton ở gốc app (như `ThemeController`, R15).
ScanController ensureScanController() {
  if (Get.isRegistered<ScanController>()) {
    return Get.find<ScanController>();
  }
  final controller = ScanController(ensureScanSettingsStore(), ensureDeviceProbe());
  Get.put<ScanController>(controller);
  return controller;
}

/// OCR ML Kit (bundled) — điểm vào duy nhất của seam [ReceiptOcr].
ReceiptOcr ensureReceiptOcr() {
  if (Get.isRegistered<ReceiptOcr>()) {
    return Get.find<ReceiptOcr>();
  }
  final ocr = MlKitReceiptOcr();
  Get.put<ReceiptOcr>(ocr);
  return ocr;
}

/// Kho ảnh hóa đơn trong thư mục documents của app.
ScanImageStore ensureScanImageStore() {
  if (Get.isRegistered<ScanImageStore>()) {
    return Get.find<ScanImageStore>();
  }
  final store = LocalScanImageStore();
  Get.put<ScanImageStore>(store);
  return store;
}

/// Đo cấu hình máy (`device_info_plus` + kênh native).
DeviceProbe ensureDeviceProbe() {
  if (Get.isRegistered<DeviceProbe>()) {
    return Get.find<DeviceProbe>();
  }
  final probe = PlatformDeviceProbe();
  Get.put<DeviceProbe>(probe);
  return probe;
}

/// Tải/xoá model Tier B (Gemma 4) — singleton để [GemmaLlm] và màn Cài đặt
/// dùng chung một phiên tải (huỷ được từ màn kiểm tra cấu hình).
ScanModelManager ensureScanModelManager() {
  if (Get.isRegistered<ScanModelManager>()) {
    return Get.find<ScanModelManager>();
  }
  final manager = GemmaModelManager();
  Get.put<ScanModelManager>(manager);
  return manager;
}

/// Extractor theo cài đặt hiện tại (T057/FR-012): Tier A → Gemini Nano, Tier B
/// đã tải model → Gemma 4, còn lại (kể cả Tier B chưa tải) → bộ luật.
///
/// Tier A lỗi (kể cả AICore thiếu tính năng đa phương thức — lỗi
/// "FEATURE_NOT_FOUND" quan sát thực tế, mã nội bộ 636 — không có API công khai
/// để dò trước) ⇒ thử tiếp Tier B trước khi rơi về bộ luật, tận dụng seam
/// `fallback` sẵn có của [LlmExtractor] thay vì soi mã lỗi. Gemma 4 chưa tải
/// thì [GemmaLlm.generate] cũng ném ngay (không tự tải mạng) nên chuỗi này vẫn
/// rơi về bộ luật nhanh như cũ khi máy chỉ có Tier A.
ReceiptExtractor extractorForSettings(ScanSettings settings) {
  return switch (settings.effectiveEngine) {
    ScanEngine.geminiNano => LlmExtractor(
        const GeminiNanoLlm(),
        fallback: LlmExtractor(GemmaLlm()),
      ),
    ScanEngine.gemma3nE2b => LlmExtractor(GemmaLlm()),
    ScanEngine.ruleBased => const RuleBasedExtractor(),
  };
}
