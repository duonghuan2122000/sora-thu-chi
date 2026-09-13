import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/scan/device_tier.dart';
import '../../core/scan/model_manager.dart';
import '../../core/scan/scan_controller.dart';
import '../../core/scan/scan_result.dart';
import '../../core/widgets/sub_page_scaffold.dart';
import '../../data/scan_deps.dart';
import '../../theme/app_colors.dart';
import '../../theme/sora_colors.dart';

/// Màn kiểm tra cấu hình máy (mockup `scan-10`): đo 4 chỉ số, phân loại tier,
/// hiện **thẻ kết quả** tương ứng và cho người dùng chọn chế độ. Pop `true` khi
/// người dùng chọn dùng tiếp (Tier A/B đã kích hoạt, hoặc Chế độ cơ bản);
/// `null` = back ra.
class DeviceCheckScreen extends StatefulWidget {
  const DeviceCheckScreen({super.key, this.controller, this.modelManager});

  /// Seam test; mặc định lấy singleton đã đăng ký.
  final ScanController? controller;
  final ScanModelManager? modelManager;

  @override
  State<DeviceCheckScreen> createState() => _DeviceCheckScreenState();
}

class _DeviceCheckScreenState extends State<DeviceCheckScreen> {
  late final ScanController _controller = widget.controller ?? ensureScanController();
  late final ScanModelManager _modelManager =
      widget.modelManager ?? ensureScanModelManager();

  DeviceCapability? _capability;
  bool _measuring = true;
  bool _downloading = false;
  int _progress = 0;
  bool _downloadFailed = false;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  Future<void> _measure() async {
    setState(() => _measuring = true);
    final capability = await _controller.checkDevice();
    if (!mounted) return;
    setState(() {
      _capability = capability;
      _measuring = false;
    });
  }

  /// Tier A: model do AICore quản lý — bật là dùng được, không tải gì.
  void _activateGeminiNano() {
    _controller.setMode(ScanEngine.geminiNano);
    Navigator.of(context).pop(true);
  }

  /// Tier B: tải model rồi mới bật. Thất bại/huỷ ⇒ **không** đổi chế độ, người
  /// dùng vẫn ở Chế độ cơ bản (FR-012).
  Future<void> _downloadModel() async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _downloadFailed = false;
    });
    final ok = await _modelManager.download(
      onProgress: (percent) {
        if (mounted) setState(() => _progress = percent);
      },
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _downloading = false;
        _downloadFailed = true;
      });
      return;
    }
    _controller.setModelBytes(await _modelManager.installedBytes());
    _controller.setMode(ScanEngine.gemma3nE2b);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _useBasicMode() {
    if (_downloading) _modelManager.cancelDownload();
    _controller.setMode(ScanEngine.ruleBased);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final capability = _capability;
    return SubPageScaffold(
      title: 'Kiểm tra cấu hình máy'.tr,
      child: ListView(
        key: const ValueKey('device-check-screen'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          if (_measuring)
            Text(
              'ĐANG KIỂM TRA'.tr,
              key: const ValueKey('device-check-measuring'),
              style: TextStyle(
                color: colors.tabInactive,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (capability != null) ...[
            _measureRow(
              key: 'device-check-row-ram',
              label: 'Bộ nhớ RAM'.tr,
              value: '${capability.ramGb} GB',
              passed: capability.ramGb >= 4,
              colors: colors,
            ),
            _measureRow(
              key: 'device-check-row-storage',
              label: 'Dung lượng trống'.tr,
              value: '${capability.freeStorageGb.toStringAsFixed(0)} GB',
              passed: capability.freeStorageGb >= 2.0,
              colors: colors,
            ),
            _measureRow(
              key: 'device-check-row-ai',
              label: 'Hỗ trợ AI trên máy (AICore)'.tr,
              value: capability.supportsOnDeviceAi ? 'Có'.tr : 'Không'.tr,
              passed: capability.supportsOnDeviceAi,
              colors: colors,
            ),
            _measureRow(
              key: 'device-check-row-os',
              label: 'Phiên bản hệ điều hành'.tr,
              value: capability.osVersion.isEmpty
                  ? 'Không xác định'.tr
                  : capability.osVersion,
              passed: capability.supportsGpuDelegate,
              colors: colors,
            ),
            const SizedBox(height: 20),
            _resultCard(classifyTier(capability), capability, colors),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: OutlinedButton(
              key: const ValueKey('device-check-retry'),
              onPressed: _measuring ? null : _measure,
              child: Text('Kiểm tra lại'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _measureRow({
    required String key,
    required String label,
    required String value,
    required bool passed,
    required SoraColors colors,
  }) {
    return Padding(
      key: ValueKey(key),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$value — ${passed ? 'Đạt'.tr : 'Không đạt'.tr}',
            style: TextStyle(
              color: passed ? colors.tealOnNeutral : colors.coralOnNeutral,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Đúng **một** thẻ kết quả theo tier đo được.
  Widget _resultCard(AiTier tier, DeviceCapability capability, SoraColors colors) {
    return switch (tier) {
      AiTier.a => _card(
        key: 'device-check-tier-a',
        title: 'Đủ điều kiện — Tier A'.tr,
        subtitle: 'Dùng ngay Gemini Nano'.tr,
        body: 'Model do hệ thống Android quản lý — không cần tải thêm, sẵn sàng dùng ngay.'.tr,
        action: _primaryButton(
          'device-check-activate-a',
          'Kích hoạt Gemini Nano'.tr,
          _activateGeminiNano,
        ),
        colors: colors,
        accentTeal: true,
      ),
      AiTier.b => _card(
        key: 'device-check-tier-b',
        title: 'Đủ điều kiện dùng Gemma 3n E2B'.tr,
        subtitle: 'Cần tải model khoảng 1.8GB qua Wifi'.tr,
        action: _gemmaActions(colors),
        colors: colors,
        accentTeal: true,
      ),
      AiTier.c => _card(
        key: 'device-check-tier-c',
        title: 'Chưa đủ điều kiện dùng AI nâng cao'.tr,
        subtitle: 'Bạn vẫn dùng được ở Chế độ cơ bản'.tr,
        body: _missingCriteria(capability),
        action: _primaryButton(
          'device-check-use-basic',
          'Dùng chế độ cơ bản'.tr,
          _useBasicMode,
        ),
        colors: colors,
        accentTeal: false,
      ),
    };
  }

  /// Nút hành động chính của thẻ kết quả (bật Tier A / tải model Tier B).
  Widget _primaryButton(String key, String label, VoidCallback onPressed) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        key: ValueKey(key),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  Widget _secondaryButton(String key, String label) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        key: ValueKey(key),
        onPressed: _useBasicMode,
        child: Text(label),
      ),
    );
  }

  /// Thẻ Tier B: tải model (kèm tiến trình) hoặc chọn Chế độ cơ bản. Tải thất
  /// bại/bị huỷ ⇒ **không** bật AI, vẫn ở Chế độ cơ bản (FR-012).
  Widget _gemmaActions(SoraColors colors) {
    if (_downloading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            key: const ValueKey('device-check-download-progress'),
            value: _progress <= 0 ? null : _progress / 100,
          ),
          const SizedBox(height: 6),
          Text(
            'Đang tải model... @percent%'.trParams({'percent': '$_progress'}),
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          _secondaryButton('device-check-use-basic', 'Dùng chế độ cơ bản'.tr),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_downloadFailed) ...[
          Text(
            'Tải model thất bại. Bạn vẫn dùng được Chế độ cơ bản.'.tr,
            key: const ValueKey('device-check-download-failed'),
            style: TextStyle(color: colors.coralOnNeutral, fontSize: 12),
          ),
          const SizedBox(height: 8),
        ],
        _primaryButton(
          'device-check-download-b',
          _downloadFailed ? 'Thử lại'.tr : 'Tải model (1.8GB)'.tr,
          _downloadModel,
        ),
        const SizedBox(height: 8),
        _secondaryButton('device-check-use-basic', 'Dùng chế độ cơ bản'.tr),
      ],
    );
  }

  Widget _card({
    required String key,
    required String title,
    required String subtitle,
    required Widget action,
    required SoraColors colors,
    required bool accentTeal,
    String? body,
  }) {
    return Container(
      key: ValueKey(key),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentTeal ? colors.tealOnNeutral : colors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accentTeal ? colors.tealOnNeutral : colors.coralOnNeutral,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            Text(
              body,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          action,
        ],
      ),
    );
  }

  /// Liệt kê tiêu chí chưa đạt của Tier C (doc §11.3).
  String _missingCriteria(DeviceCapability c) {
    final missing = <String>[
      if (!c.supportsOnDeviceAi) 'Hỗ trợ AI trên máy — Không'.tr,
      if (c.ramGb < 4)
        'RAM @gb GB — cần tối thiểu 4 GB'.trParams({'gb': '${c.ramGb}'}),
      if (c.freeStorageGb < 2.0)
        'Dung lượng trống @gb GB — cần tối thiểu 2 GB'
            .trParams({'gb': c.freeStorageGb.toStringAsFixed(1)}),
      if (!c.supportsGpuDelegate) 'Chip không hỗ trợ tăng tốc AI'.tr,
    ];
    return missing.join('\n');
  }
}
