import 'package:sora_thu_chi/core/utilities/utilities.dart';
import 'package:sora_thu_chi/core/utilities/utilities_store.dart';

/// Bản map bộ nhớ của [UtilitiesStore] — dùng cho mọi test widget (không cần
/// sqlite native). [storedPrefs] cho phép test khởi tạo trạng thái có sẵn
/// (VD round-trip mở lại màn) và assert trạng thái store sau toggle.
class FakeUtilitiesStore implements UtilitiesStore {
  FakeUtilitiesStore({UtilitiesPrefs? storedPrefs})
      : _prefs = storedPrefs ?? const UtilitiesPrefs();

  UtilitiesPrefs _prefs;

  /// Store hiện tại (chỉ đọc) — test assert sau khi bật/tắt công tắc.
  UtilitiesPrefs get storedPrefs => _prefs;

  @override
  Future<UtilitiesPrefs> load() async => _prefs;

  @override
  Future<void> save(UtilitiesPrefs prefs) async {
    _prefs = prefs;
  }
}
