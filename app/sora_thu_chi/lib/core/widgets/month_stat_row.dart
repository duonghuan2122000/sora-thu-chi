import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/sora_colors.dart';
import '../money_format.dart';
import '../transaction/transaction_list.dart';

/// 2 khối "Thu tháng này / Chi tháng này" cạnh nhau (FR-002/003). Tách từ
/// `transaction_screen.dart` để dùng chung với màn Tổng quan (PBI 33).
/// [masked] che số tiền cho Privacy mode (mặc định `false` — giữ nguyên hành
/// vi cũ; chỉ màn Tổng quan truyền `true`, màn Giao dịch không đổi — PBI 48).
class MonthStatRow extends StatelessWidget {
  const MonthStatRow({super.key, required this.stat, this.masked = false});

  final MonthStat stat;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _StatBlock(
              label: 'Thu tháng này'.tr,
              isIncome: true,
              value: stat.incomeTotal,
              masked: masked,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatBlock(
              label: 'Chi tháng này'.tr,
              isIncome: false,
              value: stat.expenseTotal,
              masked: masked,
            ),
          ),
        ],
      ),
    );
  }
}

/// Một khối thống kê: nhãn + mũi tên (lên teal / xuống coral) + tổng tiền.
class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.isIncome,
    required this.value,
    this.masked = false,
  });

  final String label;
  final bool isIncome;
  final int value;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final accent = isIncome ? colors.tealOnNeutral : colors.coralOnNeutral;
    final amountColor = isIncome ? colors.textPrimary : colors.coralOnNeutral;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colors.softCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              masked ? maskMoney(value) : formatMoney(value),
              style: TextStyle(
                color: amountColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
