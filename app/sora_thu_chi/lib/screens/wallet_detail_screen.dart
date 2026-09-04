import 'package:flutter/material.dart';

import '../core/date_label.dart';
import '../core/money_format.dart';
import '../core/transaction/transaction.dart';
import '../core/transaction/transaction_source.dart';
import '../core/wallet/wallet.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../theme/app_colors.dart';

/// Màn chi tiết một ví — sub-page từ danh sách ví (PBI 5, FR-001/002).
/// Vùng teal hero (tên ở app bar, số dư/credit + loại ví), 3 hành động nhanh
/// (điểm vào chưa kích hoạt, FR-006/007) và nhóm "GIAO DỊCH GẦN ĐÂY" đúng ví
/// (FR-008..012). Chỉ xem: không thao tác nào đổi dữ liệu (SC-008).
/// [transactions] là seam để test bơm; default lấy [TransactionSource.forWallet].
class WalletDetailScreen extends StatelessWidget {
  WalletDetailScreen({
    super.key,
    required Wallet wallet,
    List<Transaction>? transactions,
  }) : wallet = wallet,
       transactions = transactions ?? TransactionSource.forWallet(wallet.id);

  final Wallet wallet;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: wallet.name,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Hero(wallet: wallet),
            const _QuickActions(),
            const _SectionHeader('GIAO DỊCH GẦN ĐÂY'),
            if (transactions.isEmpty)
              const _EmptyTransactions()
            else
              ...transactions.map((t) => _TxnRow(transaction: t)),
          ],
        ),
      ),
    );
  }
}

/// Vùng teal đầu màn: tròn icon + số dư/credit cỡ lớn trắng + dòng loại ví.
/// Thẻ tín dụng hiển thị dạng "Đã dùng X / Hạn mức Y đ" + phần trăm (FR-005),
/// không hiện số dư dương. Chữ luôn trắng trên nền teal.
class _Hero extends StatelessWidget {
  const _Hero({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final isCredit = wallet.type == WalletType.credit;
    return Container(
      width: double.infinity,
      color: AppColors.teal,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(wallet.icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 14),
          Text(
            isCredit ? wallet.creditUsageLabel : formatMoney(wallet.balance),
            style: TextStyle(
              color: AppColors.white,
              fontSize: isCredit ? 18 : 34,
              fontWeight: isCredit ? FontWeight.w600 : FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isCredit
                ? '${wallet.creditUsedPercent}% hạn mức đã dùng'
                : wallet.typeLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Ba hành động nhanh tròn teal nhạt — chạm không mở luồng (FR-006/007).
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Row(
        children: [
          _action(Icons.swap_horiz, 'Chuyển tiền'),
          _action(Icons.edit_outlined, 'Sửa ví'),
          _action(Icons.visibility_off_outlined, 'Ẩn ví'),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label) {
    return Expanded(
      child: InkWell(
        onTap: () {}, // FR-007: điểm vào PBI sau, chưa kích hoạt.
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Ink(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.tealLightBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.teal, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.listLabel,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiêu đề nhóm viết hoa — cùng kiểu các màn khác.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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

/// Một dòng giao dịch: tròn icon theo dấu + màu theo loại, tiêu đề, dòng phụ
/// "danh mục · ngày" và số tiền căn phải tô màu ngữ cảnh (FR-009/010).
class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final title = t.note.isNotEmpty
        ? t.note
        : (t.category.isNotEmpty ? t.category : t.typeLabel);
    final subtitle = t.category.isNotEmpty ? t.category : t.typeLabel;
    final arrow = t.amount < 0 ? Icons.arrow_downward : Icons.arrow_upward;
    final (Color bubbleBg, Color fg) = switch (t.type) {
      TxnType.income => (AppColors.tealLightBg, AppColors.teal),
      TxnType.expense => (AppColors.coralLightBg, AppColors.coral),
      TxnType.transfer ||
      TxnType.adjustment => (AppColors.softCardBg, AppColors.listLabel),
    };

    return InkWell(
      onTap: () {}, // FR-011: điểm vào PBI Giao dịch, chưa mở màn.
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.listDivider)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bubbleBg,
                shape: BoxShape.circle,
              ),
              child: Icon(arrow, color: fg, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$subtitle · ${relativeDayLabel(t.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatSignedMoney(t.amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trạng thái rỗng nhóm giao dịch (FR-012) — hero + hành động + tiêu đề vẫn hiện.
class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧾', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            const Text(
              'Chưa có giao dịch nào.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Giao dịch của ví sẽ xuất hiện tại đây.',
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
