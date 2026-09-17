import 'package:get/get.dart';

import '../utilities/utilities.dart';
import '../utilities/utilities_store.dart';

/// Nguồn chân lý duy nhất của 2 công tắc màn Tiện ích (`hideBalance`,
/// `amountCalculatorEnabled`) — bám `ThemeController`. Cả màn Tiện ích lẫn
/// Tổng quan đọc/ghi qua đây, không giữ cache riêng, tránh 2 nguồn lệch nhau
/// khi thao tác gần nhau ở 2 màn (PBI 48 research R2).
///
/// `revealed`: "đang xem tạm thời" số tiền trên Tổng quan khi `hideBalance`
/// đang bật — **không** lưu bền, reset khi rời tab Tổng quan (R3).
class PrivacyController extends GetxController {
  PrivacyController(this._store);

  final UtilitiesStore _store;

  final Rx<bool> hideBalance = false.obs;
  final Rx<bool> amountCalculatorEnabled = true.obs;
  final Rx<bool> revealed = false.obs;

  /// Nối đuôi các lần ghi — bật/tắt liên tiếp thì lần chạm cuối là trạng thái
  /// cuối (save cũ không đè save mới).
  Future<void> _saveTail = Future<void>.value();

  Future<void> load() async {
    final prefs = await _store.load();
    hideBalance.value = prefs.hideBalance;
    amountCalculatorEnabled.value = prefs.amountCalculatorEnabled;
  }

  void setHideBalance(bool value) {
    if (value == hideBalance.value) return;
    hideBalance.value = value;
    if (!value) revealed.value = false;
    _save();
  }

  void setAmountCalculatorEnabled(bool value) {
    if (value == amountCalculatorEnabled.value) return;
    amountCalculatorEnabled.value = value;
    _save();
  }

  void _save() {
    final prefs = UtilitiesPrefs(
      hideBalance: hideBalance.value,
      amountCalculatorEnabled: amountCalculatorEnabled.value,
    );
    _saveTail = _saveTail.then((_) async {
      try {
        await _store.save(prefs);
      } catch (_) {
        // Ghi lỗi bỏ qua — lần chạm sau ghi lại trạng thái mới nhất.
      }
    });
  }
}
