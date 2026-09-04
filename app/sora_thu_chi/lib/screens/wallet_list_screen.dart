import 'package:flutter/material.dart';

import '../core/money_format.dart';
import '../core/wallet/wallet.dart';
import '../core/wallet/wallet_source.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../theme/app_colors.dart';
import 'wallet_detail_screen.dart';

/// Màn danh sách ví — sub-page từ Cài đặt (FR-001/002), chế độ chỉ hiển thị.
/// Card tổng + tiêu đề nhóm + danh sách từng ví (loại/mặc định/thẻ/ví ẩn).
/// [wallets] là seam để test bơm dữ liệu; shell dùng 5 ví mẫu mặc định.
class WalletListScreen extends StatelessWidget {
  WalletListScreen({super.key, List<Wallet>? wallets})
    : wallets = wallets ?? WalletSource.all();

  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context) {
    final display = walletsByDisplayOrder(wallets);
    return SubPageScaffold(
      title: 'Quản lý ví',
      child: SafeArea(
        top: false,
        child: Column(
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
            const _AddWalletButton(),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.softCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TỔNG SỐ DƯ TẤT CẢ VÍ',
              style: TextStyle(
                color: AppColors.tabInactive,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              formatMoney(total),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$count ví đang hoạt động',
              style: const TextStyle(
                color: AppColors.textSecondary,
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

/// Một hàng ví: icon tròn + tên/dòng phụ + số bên phải.
class _WalletRow extends StatelessWidget {
  const _WalletRow({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final muted = wallet.isHidden;
    final titleColor = muted ? AppColors.tabInactive : AppColors.textPrimary;
    return InkWell(
      // FR-001 (PBI 6): chạm hàng mở màn chi tiết — mọi ví kể cả ví ẩn.
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WalletDetailScreen(wallet: wallet),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.listDivider)),
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
                  _buildSubtitle(muted),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Trailing co được (ellipsis) để không tràn khi cỡ chữ lớn / số dài.
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildTrailing(muted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(bool muted) {
    if (muted) {
      return const Text(
        'Không tính vào tổng',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: AppColors.tabInactive),
      );
    }
    if (wallet.type == WalletType.credit) {
      return Text(
        wallet.creditUsageLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.coral,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    if (wallet.isDefault) {
      return Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'Mặc định',
              style: TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: ' • '),
            TextSpan(text: wallet.typeLabel),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: AppColors.listLabel),
      );
    }
    return Text(
      wallet.typeLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, color: AppColors.listLabel),
    );
  }

  Widget _buildTrailing(bool muted) {
    if (wallet.type == WalletType.credit) {
      return Text(
        '${wallet.creditUsedPercent}%',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.coral,
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
        color: muted ? AppColors.tabInactive : AppColors.textPrimary,
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
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.tealLightBg,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗂️', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            const Text(
              'Chưa có ví nào.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Chạm '+ Thêm ví mới' để tạo ví đầu tiên.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.tabInactive,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút "+ Thêm ví mới" cố định chân màn — điểm vào chưa kích hoạt (FR-010/013).
class _AddWalletButton extends StatelessWidget {
  const _AddWalletButton();

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
          onPressed: () {}, // FR-010: chưa mở luồng — không lỗi khi chạm.
          child: const Text('+ Thêm ví mới'),
        ),
      ),
    );
  }
}
