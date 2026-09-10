import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'locale_prefs.dart';
import 'locale_store.dart';

/// Nguồn chân lý ngôn ngữ hiển thị trong phiên (bám [ThemeController]):
/// `Rx<Locale>` cho `GetMaterialApp.locale`, radio màn `03` và phần cuối hàng
/// "Ngôn ngữ" màn `01`. Mặc định `vi` trước khi [load] xong (FR-004).
///
/// Vì sao phải gọi [Get.updateLocale] ngoài việc hạ `locale:` xuống
/// `GetMaterialApp`: đo thực nghiệm cho thấy route đang mở **không** tự rebuild
/// khi `MaterialApp.locale` đổi (`LEAF BUILDS before=1 after=1`), nên FR-005
/// (nhãn đổi ngay ở màn đang mở) chỉ đạt được nếu reassemble cả cây. `updateLocale`
/// gọi `reassembleApplication()` — dựng lại widget tree, giữ nguyên state và
/// stack điều hướng. Thao tác hiếm (người dùng chủ động đổi ngôn ngữ), không
/// nằm trên đường đi nóng.
class LocaleController extends GetxController {
  LocaleController(this._store);

  final LocaleStore _store;

  final Rx<Locale> locale = kFallbackLocale.obs;

  /// Nối đuôi các lần ghi — chọn nhanh liên tiếp thì lần chạm cuối là trạng
  /// thái cuối (save cũ không đè save mới).
  Future<void> _saveTail = Future<void>.value();

  /// Nạp lựa chọn đã lưu. Chỉ reassemble khi giá trị thật sự khác mặc định —
  /// mở app lần đầu (chưa có row) hoặc đang ở `vi` không tốn nhịp dựng lại cây.
  Future<void> load() async {
    final stored = await _store.load();
    if (stored != null && stored != locale.value) {
      locale.value = stored;
      // Bắn-và-quên: `await` làm test treo (fake async không hoàn tất reassemble).
      Get.updateLocale(stored);
    }
  }

  void setLocale(Locale next) {
    // Chạm lại hàng đang chọn → no-op (không đổi, không ghi).
    if (next == locale.value) return;
    locale.value = next;
    Get.updateLocale(next);
    _saveTail = _saveTail.then((_) async {
      try {
        await _store.save(next);
      } catch (_) {
        // Ghi lỗi bỏ qua — lần chạm sau ghi lại trạng thái mới nhất.
      }
    });
  }
}
