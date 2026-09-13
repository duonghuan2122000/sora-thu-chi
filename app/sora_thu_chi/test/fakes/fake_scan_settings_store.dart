import 'package:sora_thu_chi/core/scan/scan_settings.dart';
import 'package:sora_thu_chi/core/scan/scan_settings_store.dart';

/// Fake [ScanSettingsStore] — bám `FakeUtilitiesStore`: khởi tạo trạng thái có
/// sẵn, assert trạng thái sau khi đổi công tắc.
class FakeScanSettingsStore implements ScanSettingsStore {
  FakeScanSettingsStore({ScanSettings? stored})
    : _settings = stored ?? const ScanSettings();

  ScanSettings _settings;
  int saveCount = 0;

  /// Trạng thái hiện tại (chỉ đọc) — test assert sau toggle.
  ScanSettings get storedSettings => _settings;

  @override
  Future<ScanSettings> load() async => _settings;

  @override
  Future<void> save(ScanSettings settings) async {
    saveCount++;
    _settings = settings;
  }
}
