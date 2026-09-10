import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/money_format.dart';
import '../core/wallet/wallet.dart';
import '../core/wallet/wallet_controller.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/wallet_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'wallet_detail_screen.dart';
import 'wallet_form_screen.dart';

/// Màn danh sách ví — sub-page từ Cài đặt (FR-001/002).
/// Nguồn sự thật: [WalletController] reactive (cache sau thêm/sửa tự cập nhật —
/// FR-013). Nút "+ Thêm ví mới" mở [WalletFormScreen] chế độ thêm.
class WalletListScreen extends StatefulWidget {
  const WalletListScreen({super.key});

  @override
  State<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends State<WalletListScreen> {
  WalletController? _controller;

  @override
  void initState() {
    super.initState();
    // Đăng ký controller (fake trong test, drift thật ở app) rồi đọc cache.
    _controller = ensureWalletController();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return SubPageScaffold(
      title: 'Quản lý ví',
      child: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final wallets = controller.wallets;
          final display = walletsByDisplayOrder(wallets);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TotalCard(
                total: activeTotal(wallets),
                count: activeCount(wallets),
              ),
              const _SectionTitle('VÍ CỦA BẠN'),
              Expanded(
                child: display.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: display.length,
                        itemBuilder: (_, index) =>
                            _WalletRow(wallet: display[index]),
                      ),
              ),
              _AddWalletButton(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => WalletFormScreen(controller: controller),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Card tổng số dư (FR-003): nhãn + tổng + dòng "N ví đang hoạt động".
class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.count});

  final int total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: colors.softCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TỔNG SỐ DƯ TẤT CẢ VÍ',
              style: TextStyle(
                color: colors.tabInactive,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatMoney(total),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count ví đang hoạt động',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiêu đề nhóm danh sách (viết hoa, xám).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

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

/// Một hàng ví: icon tròn + tên/dòng phụ + số bên phải.
class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final muted = wallet.isHidden;
    final titleColor = muted ? colors.tabInactive : colors.textPrimary;
    return InkWell(
      // FR-001 (PBI 6): chạm hàng mở màn chi tiết — mọi ví kể cả ví ẩn.
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WalletDetailScreen(wallet: wallet),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.listDivider)),
        ),
        child: Row(
          children: [
            _IconBubble(emoji: wallet.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    muted ? wallet.hiddenName : wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildSubtitle(muted, colors),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Trailing co được (ellipsis) để không tràn khi cỡ chữ lớn / số dài.
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildTrailing(muted, colors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(bool muted, SoraColors colors) {
    if (muted) {
      return Text(
        'Không tính vào tổng',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: colors.tabInactive),
      );
    }
    if (wallet.type == WalletType.credit) {
      return Text(
        wallet.creditUsageLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: colors.coralOnNeutral,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    if (wallet.isDefault) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Mặc định',
              style: TextStyle(
                color: colors.tealOnNeutral,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: ' • '),
            TextSpan(text: wallet.typeLabel),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: colors.listLabel),
      );
    }
    return Text(
      wallet.typeLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13, color: colors.listLabel),
    );
  }

  Widget _buildTrailing(bool muted, SoraColors colors) {
    if (wallet.type == WalletType.credit) {
      return Text(
        '${wallet.creditUsedPercent}%',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: colors.coralOnNeutral,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Text(
      formatMoney(wallet.balance),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: muted ? colors.tabInactive : colors.textPrimary,
      ),
    );
  }
}

/// Vòng tròn nền teal nhạt chứa emoji loại ví.
class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.tealLightBg,
        shape: BoxShape.circle,
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }
}

/// Trạng thái rỗng (FR-009) khi chưa có ví nào.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗂️', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              'Chưa có ví nào.',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Chạm '+ Thêm ví mới' để tạo ví đầu tiên.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.tabInactive,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút "+ Thêm ví mới" cố định chân màn — mở form thêm (FR-010/013).
class _AddWalletButton extends StatelessWidget {
  const _AddWalletButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: onTap,
          child: const Text('+ Thêm ví mới'),
        ),
      ),
    );
  }
}
