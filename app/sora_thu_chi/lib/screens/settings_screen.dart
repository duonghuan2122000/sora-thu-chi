import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/date_label.dart';
import '../core/profile/device_profile.dart';
import '../core/scan/device_tier.dart';
import '../core/scan/scan_controller.dart';
import '../core/scan/scan_result.dart';
import '../core/security/pin_controller.dart';
import '../core/widgets/screen_header.dart';
import '../data/scan_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'backup_restore_screen.dart';
import 'category_list_screen.dart';
import 'notification_settings_screen.dart';
import 'scan/device_check_screen.dart';
import 'scan_log_list_screen.dart';
import 'utilities_screen.dart';
import 'wallet_list_screen.dart';

/// Màn trung tâm Cài đặt — khối hồ sơ + 2 nhóm mục. Các hàng còn lại là điểm
/// vào chưa kích hoạt — chạm không mở luồng; riêng hàng "Quản lý ví" điều hướng
/// sang [WalletListScreen] (FR-001 PBI 5), hàng "Danh mục" sang
/// [CategoryListScreen] (FR-001 PBI 13), hàng "Tiện ích & Cá nhân hóa" sang
/// [UtilitiesScreen] (FR-001 PBI 17) và hàng "Thông báo & nhắc nhở" sang
/// [NotificationSettingsScreen] (FR-001 PBI 28).
/// [profile]/[onManageWalletTap]/[onManageCategoryTap]/[onManageUtilitiesTap]/
/// [onManageNotificationsTap] là seam để test bơm giá trị; shell dùng mặc định.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.profile = DeviceProfile.initial,
    this.onManageWalletTap,
    this.onManageCategoryTap,
    this.onManageUtilitiesTap,
    this.onManageNotificationsTap,
    this.onManageBackupTap,
  });

  final DeviceProfile profile;
  final VoidCallback? onManageWalletTap;
  final VoidCallback? onManageCategoryTap;
  final VoidCallback? onManageUtilitiesTap;
  final VoidCallback? onManageNotificationsTap;
  final VoidCallback? onManageBackupTap;

  /// Default đẩy màn list ví; khi test bơm callback → gọi callback không push.
  void _openManageWallet(BuildContext context) {
    final callback = onManageWalletTap;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => WalletListScreen()),
    );
  }

  /// Default đẩy màn danh sách danh mục; test bơm callback → không push.
  void _openManageCategory(BuildContext context) {
    final callback = onManageCategoryTap;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CategoryListScreen()),
    );
  }

  /// Default đẩy màn Tiện ích & Cá nhân hóa; test bơm callback → không push.
  void _openManageUtilities(BuildContext context) {
    final callback = onManageUtilitiesTap;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => UtilitiesScreen()),
    );
  }

  /// Default đẩy màn Thông báo & nhắc nhở; test bơm callback → không push.
  void _openManageNotifications(BuildContext context) {
    final callback = onManageNotificationsTap;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationSettingsScreen(),
      ),
    );
  }

  /// Default đẩy màn Sao lưu & Khôi phục; test bơm callback → không push.
  void _openManageBackup(BuildContext context) {
    final callback = onManageBackupTap;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BackupRestoreScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Column(
      children: [
        ScreenHeader(title: 'Cài đặt'.tr, bottom: _ProfileBlock(profile: profile)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            children: [
              _SectionLabel('TÀI KHOẢN'.tr),
              _SettingsRow(
                label: 'Tiền tệ mặc định'.tr,
                trailing: Text(
                  profile.currencyCode,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _SettingsRow(
                label: 'Đổi mã PIN'.tr,
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.tabInactive,
                ),
              ),
              const _BiometricSwitchRow(),
              _SectionLabel('KHÁC'.tr),
              _SettingsRow(
                label: 'Quản lý ví'.tr,
                onTap: () => _openManageWallet(context),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.tabInactive,
                ),
              ),
              _SettingsRow(
                label: 'Danh mục'.tr,
                onTap: () => _openManageCategory(context),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.tabInactive,
                ),
              ),
              _SettingsRow(
                label: 'Tiện ích & Cá nhân hóa'.tr,
                onTap: () => _openManageUtilities(context),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.tabInactive,
                ),
              ),
              _SettingsRow(
                label: 'Thông báo & nhắc nhở'.tr,
                onTap: () => _openManageNotifications(context),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.tabInactive,
                ),
              ),
              _SettingsRow(
                label: 'Sao lưu & Khôi phục'.tr,
                onTap: () => _openManageBackup(context),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colors.tabInactive,
                ),
              ),
              _SectionLabel('QUÉT HÓA ĐƠN AI'.tr),
              const _ScanGroup(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Nhóm "QUÉT HÓA ĐƠN AI" (PBI 24, mockup `scan-11`): công tắc bật/tắt + khối
/// trạng thái (tier + mốc kiểm tra) + hàng chạy lại kiểm tra cấu hình. Đọc
/// `ScanController` qua `Obx` ⇒ đổi công tắc ở đây phản ánh ngay vào sheet FAB
/// (FR-003/FR-004, R15).
class _ScanGroup extends StatelessWidget {
  const _ScanGroup();

  void _openDeviceCheck(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DeviceCheckScreen()),
    );
  }

  /// Xoá model Tier B khỏi máy rồi đưa về Chế độ cơ bản — model không còn thì
  /// `effectiveEngine` cũng tự rơi về bộ luật (FR-012).
  Future<void> _deleteModel(BuildContext context, ScanController controller) async {
    final messenger = ScaffoldMessenger.of(context);
    await ensureScanModelManager().delete();
    controller.setModelBytes(0);
    controller.setMode(ScanEngine.ruleBased);
    messenger.showSnackBar(SnackBar(content: Text('Đã xoá model'.tr)));
  }

  /// `1.8 GB` / `850 MB` — đơn vị không dịch, chỉ hiển thị.
  static String formatBytes(int bytes) {
    if (bytes >= 1000000000) {
      return '${(bytes / 1000000000).toStringAsFixed(1)} GB';
    }
    return '${(bytes / 1000000).toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final controller = ensureScanController();
    return Obx(() {
      final settings = controller.settings.value;
      final check = settings.deviceCheck;
      return Column(
        children: [
          _SettingsRow(
            label: 'Quét hóa đơn bằng AI'.tr,
            trailing: Switch(
              key: const ValueKey('scan-enabled-switch'),
              value: settings.enabled,
              onChanged: controller.setEnabled,
            ),
          ),
          _SettingsRow(
            label: 'Trạng thái AI'.tr,
            trailing: Text(
              _modeLabel(settings.mode, check == null ? null : classifyTier(check)),
              key: const ValueKey('scan-ai-status'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          _SettingsRow(
            label: 'Lần kiểm tra gần nhất'.tr,
            trailing: Text(
              check == null
                  ? 'Chưa kiểm tra'.tr
                  : formatDateTimeLabel(check.checkedAt),
              key: const ValueKey('scan-last-check'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          if (settings.modelBytes > 0)
            _SettingsRow(
              label: 'Dung lượng model'.tr,
              trailing: Text(
                formatBytes(settings.modelBytes),
                key: const ValueKey('scan-model-size'),
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ),
          if (settings.modelBytes > 0)
            _SettingsRow(
              label: 'Xoá model'.tr,
              onTap: () => _deleteModel(context, controller),
              trailing: Icon(Icons.delete_outline, color: colors.tabInactive),
            ),
          _SettingsRow(
            label: 'Kiểm tra lại cấu hình máy'.tr,
            onTap: () => _openDeviceCheck(context),
            trailing: Icon(Icons.chevron_right, color: colors.tabInactive),
          ),
          _SettingsRow(
            label: 'Kiểm tra cập nhật model'.tr,
            onTap: () => _openDeviceCheck(context),
            trailing: Icon(Icons.chevron_right, color: colors.tabInactive),
          ),
          _SettingsRow(
            label: 'Nhật ký trích xuất AI'.tr,
            onTap: () => _openScanLog(context),
            trailing: Icon(Icons.chevron_right, color: colors.tabInactive),
          ),
        ],
      );
    });
  }

  /// Mở màn "Nhật ký trích xuất AI" (FR-006/FR-007, PBI 47) — độc lập với công
  /// tắc quét (xem lại nhật ký cả khi đã tắt tính năng).
  void _openScanLog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ScanLogListScreen()),
    );
  }

  /// Nhãn trạng thái: theo **chế độ đang chọn** (`mode`), không theo tier đo
  /// được của máy — máy đo Tier A vẫn có thể đang chạy Gemma 4 (Tier B) nếu
  /// người dùng chủ động chuyển (màn kiểm tra cấu hình máy). `tier` chỉ dùng
  /// để phân biệt "chưa kiểm tra" / "Tier C" khi `mode` là bộ luật.
  static String _modeLabel(ScanEngine mode, AiTier? tier) {
    return switch (mode) {
      ScanEngine.geminiNano => 'Gemini Nano (Tier A)',
      ScanEngine.gemma3nE2b => 'Gemma 4 E2B (Tier B)',
      ScanEngine.ruleBased =>
        tier == AiTier.c ? 'Chế độ cơ bản (Tier C)'.tr : 'Chế độ cơ bản'.tr,
    };
  }
}

/// Khối hồ sơ trong vùng teal: avatar tròn + tên hiển thị + dòng phụ.
/// Không gắn thao tác — chạm không phản hồi (FR-006).
class _ProfileBlock extends StatelessWidget {
  const _ProfileBlock({required this.profile});

  final DeviceProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.avatarBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initialsOf(profile.resolvedDisplayName),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.resolvedDisplayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Chạm để đổi ảnh đại diện'.tr,
                style: TextStyle(
                  color: colors.tealLightText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tiêu đề nhóm viết hoa (TÀI KHOẢN / KHÁC) — chữ mờ.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          color: colors.tabInactive,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Hàng cài đặt: nhãn trái (chống tràn cỡ chữ lớn) + trailing tuỳ chọn.
/// Có [onTap] → hàng chạm được (hiệu ứng mực); thiếu → đứng im. [subtitle] →
/// dòng phụ mờ dưới nhãn (VD giải thích lý do công tắc không bật được).
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    this.trailing,
    this.onTap,
    this.subtitle,
  });

  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.listDivider)),
      ),
      // `spaceBetween` giữ trailing sát mép phải; cả hai vế đều `Flexible` nên
      // giá trị dài (trạng thái AI, mốc kiểm tra) vẫn co được, không tràn hàng
      // khi cỡ chữ lớn (SC-014). Dùng `Expanded` cho nhãn sẽ khiến hàng chia đôi
      // không gian và đẩy trailing ra giữa màn hình.
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.listLabel,
                    fontSize: 15,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Flexible(child: trailing!),
          ],
        ],
      ),
    );
    final handler = onTap;
    if (handler == null) return row;
    return InkWell(onTap: handler, child: row);
  }
}

/// Hàng "Mở khóa sinh trắc học": công tắc thật đọc/ghi qua [PinController]
/// (FR-001/FR-002/FR-009). Không có [PinController] đăng ký (VD test không
/// chạm module này) → coi như không hỗ trợ, công tắc tắt + không bật được.
class _BiometricSwitchRow extends StatefulWidget {
  const _BiometricSwitchRow();

  @override
  State<_BiometricSwitchRow> createState() => _BiometricSwitchRowState();
}

class _BiometricSwitchRowState extends State<_BiometricSwitchRow> {
  PinController? get _controller =>
      Get.isRegistered<PinController>() ? Get.find<PinController>() : null;

  bool _checking = true;
  bool _supported = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final supported = await _controller?.deviceSupportsBiometric() ?? false;
    if (!mounted) return;
    setState(() {
      _supported = supported;
      _checking = false;
    });
  }

  Future<void> _onChanged(bool value) async {
    final controller = _controller;
    if (controller == null) return;
    if (value) {
      await controller.enableBiometric();
    } else {
      await controller.disableBiometric();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final canToggle = controller != null && !_checking && _supported;
    return _SettingsRow(
      label: 'Mở khóa sinh trắc học'.tr,
      subtitle: (!_checking && !_supported)
          ? 'Thiết bị chưa hỗ trợ hoặc chưa đăng ký vân tay/khuôn mặt'.tr
          : null,
      trailing: Switch(
        value: controller?.biometricEnabled ?? false,
        onChanged: canToggle ? _onChanged : null,
      ),
    );
  }
}
