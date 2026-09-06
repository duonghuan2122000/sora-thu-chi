import 'package:flutter/material.dart';

import '../core/profile/device_profile.dart';
import '../core/widgets/screen_header.dart';
import '../theme/app_colors.dart';
import 'category_list_screen.dart';
import 'utilities_screen.dart';
import 'wallet_list_screen.dart';

/// Màn trung tâm Cài đặt — khối hồ sơ + 2 nhóm mục. Các hàng còn lại là điểm
/// vào chưa kích hoạt — chạm không mở luồng; riêng hàng "Quản lý ví" điều hướng
/// sang [WalletListScreen] (FR-001 PBI 5), hàng "Danh mục" sang
/// [CategoryListScreen] (FR-001 PBI 13) và hàng "Tiện ích & Cá nhân hóa" sang
/// [UtilitiesScreen] (FR-001 PBI 17).
/// [profile]/[onManageWalletTap]/[onManageCategoryTap]/[onManageUtilitiesTap]
/// là seam để test bơm giá trị; shell dùng mặc định.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.profile = DeviceProfile.initial,
    this.onManageWalletTap,
    this.onManageCategoryTap,
    this.onManageUtilitiesTap,
  });

  final DeviceProfile profile;
  final VoidCallback? onManageWalletTap;
  final VoidCallback? onManageCategoryTap;
  final VoidCallback? onManageUtilitiesTap;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenHeader(title: 'Cài đặt', bottom: _ProfileBlock(profile: profile)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            children: [
              const _SectionLabel('TÀI KHOẢN'),
              _SettingsRow(
                label: 'Tiền tệ mặc định',
                trailing: Text(
                  profile.currencyCode,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const _SettingsRow(
                label: 'Đổi mã PIN',
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.tabInactive,
                ),
              ),
              const _SettingsRow(
                label: 'Mở khóa sinh trắc học',
                trailing: Switch(value: false, onChanged: null),
              ),
              const _SectionLabel('KHÁC'),
              _SettingsRow(
                label: 'Quản lý ví',
                onTap: () => _openManageWallet(context),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.tabInactive,
                ),
              ),
              _SettingsRow(
                label: 'Danh mục',
                onTap: () => _openManageCategory(context),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.tabInactive,
                ),
              ),
              _SettingsRow(
                label: 'Tiện ích & Cá nhân hóa',
                onTap: () => _openManageUtilities(context),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.tabInactive,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Khối hồ sơ trong vùng teal: avatar tròn + tên hiển thị + dòng phụ.
/// Không gắn thao tác — chạm không phản hồi (FR-006).
class _ProfileBlock extends StatelessWidget {
  const _ProfileBlock({required this.profile});

  final DeviceProfile profile;

  @override
  Widget build(BuildContext context) {
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
                'Chạm để đổi ảnh đại diện',
                style: const TextStyle(
                  color: AppColors.tealLightText,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.tabInactive,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Hàng cài đặt: nhãn trái (chống tràn cỡ chữ lớn) + trailing tuỳ chọn.
/// Có [onTap] → hàng chạm được (hiệu ứng mực); thiếu → đứng im.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, this.trailing, this.onTap});

  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.listDivider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.listLabel,
                fontSize: 15,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
    final handler = onTap;
    if (handler == null) return row;
    return InkWell(onTap: handler, child: row);
  }
}
