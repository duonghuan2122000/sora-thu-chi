import 'package:flutter/material.dart';

import '../../screens/transaction_detail_screen.dart';
import '../../theme/sora_colors.dart';
import '../money_format.dart';
import '../transaction/transaction.dart';
import '../transaction/transaction_detail.dart';
import '../transaction/transaction_list.dart';

/// Một dòng giao dịch: icon bubble + tên/dòng phụ + số tiền căn phải.
/// Thu teal `+`, chi coral `−`, chuyển khoản/điều chỉnh trung tính không dấu.
/// Tách từ `transaction_screen.dart` để dùng chung với màn Tổng quan (PBI 33).
class TxnRowTile extends StatelessWidget {
  const TxnRowTile({super.key, required this.row});

  final TxnRow row;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final neutral =
        row.type == TxnType.transfer || row.type == TxnType.adjustment;
    final accent =
        row.type == TxnType.income
            ? colors.tealOnNeutral
            : row.type == TxnType.expense
            ? colors.coralOnNeutral
            : colors.listLabel;
    return InkWell(
      // Mở màn chi tiết theo ref (R2): dòng transfer đã gộp → theo group tìm
      // đủ 2 vế; dòng thường → theo id bút toán. Detail là sub-page đè lên
      // shell; quay lại giữ vị trí cuộn danh sách (route dưới — SC-008).
      onTap: () {
        final detailRef = row.detailGroupId != null
            ? TransactionDetailRef(transferGroupId: row.detailGroupId)
            : TransactionDetailRef(transactionId: row.detailTransactionId);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(ref: detailRef),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.listDivider)),
        ),
        child: Row(
          children: [
            _RowBubble(neutral: neutral, row: row, accent: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.listLabel, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  neutral
                      ? formatMoney(row.amount)
                      : formatSignedMoney(row.amount),
                  style: TextStyle(
                    color: accent,
                    fontSize: 15,
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

/// Vòng tròn icon: thu/chi nền teal nhạt + glyph theo danh mục;
/// transfer/điều chỉnh nền trung tính + glyph theo loại.
class _RowBubble extends StatelessWidget {
  const _RowBubble({required this.neutral, required this.row, required this.accent});

  final bool neutral;
  final TxnRow row;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final icon = neutral
        ? (row.type == TxnType.transfer ? Icons.swap_horiz : Icons.tune)
        : categoryGlyph(row.title);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: neutral ? colors.softCardBg : colors.tealLightBg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: accent),
    );
  }
}
