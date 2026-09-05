import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/money_format.dart';
import '../core/transaction/transaction.dart';
import '../core/transaction/transaction_controller.dart';
import '../core/transaction/transaction_list.dart';
import '../core/widgets/screen_header.dart';
import '../data/transaction_deps.dart';
import '../theme/app_colors.dart';

/// Màn "Giao dịch" (tab chính thứ 2) — theo mockup 01-danh-sach-giao-dich.svg:
/// header teal + icon lọc, card "Thu/Chi tháng này", danh sách giao dịch nhóm
/// ngày. Đọc qua [TransactionController]; nạp lại mỗi lần chọn tab (FR-011).
/// FAB / icon lọc / chạm dòng là điểm vào no-op — màn đích ở PBI sau (FR-014).
class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ensureTransactionController();
    return Column(
      children: [
        ScreenHeader(
          title: 'Giao dịch',
          centerTitle: true,
          trailing: const _FilterButton(),
        ),
        Expanded(
          child: Obx(() {
            final view = controller.data.value;
            if (view == null) {
              // Lỗi có thông báo + nút Thử lại; đang nạp → spinner; trước khi
              // chọn tab (offstage từ boot) → trống tĩnh, không animation ẩn.
              if (controller.error.value != null) {
                return _ErrorState(onRetry: controller.retry);
              }
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return const SizedBox.expand();
            }
            return _TransactionList(view: view);
          }),
        ),
      ],
    );
  }
}

/// Nút lọc trong app bar — điểm vào tìm kiếm/lọc (PBI sau), chạm không lỗi.
class _FilterButton extends StatelessWidget {
  const _FilterButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {}, // no-op — FR-014
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Icon(Icons.filter_list, color: AppColors.white, size: 22),
      ),
    );
  }
}

/// Lỗi đọc repo (R8): thông báo + nút Thử lại.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.coral, size: 40),
            const SizedBox(height: 12),
            const Text(
              'Không đọc được dữ liệu giao dịch.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nội dung danh sách: card thống kê + các nhóm ngày (lười theo cuộn) hoặc
/// empty state khi chưa có giao dịch. Giữ vị trí cuộn qua PageStorageKey (R4).
class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.view});

  final TransactionView view;

  @override
  Widget build(BuildContext context) {
    final groups = view.groups;
    // ponytail: đọc 1 lần + build lười theo cuộn (không fetch phân trang SQL) —
    // DB local một người dùng, nghìn dòng đọc nhanh. Nếu vượt ~vài chục nghìn
    // gây giật → chuyển fetch theo nhóm ngày (R4). Đảm bảo FR-012 không trùng/sót.
    return CustomScrollView(
      key: const PageStorageKey('transaction-list'),
      slivers: [
        SliverToBoxAdapter(child: _MonthStatCard(stat: view.stat)),
        if (groups.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(),
          )
        else
          for (final group in groups) ...[
            SliverToBoxAdapter(child: _DayHeader(header: group.header)),
            SliverList.builder(
              itemCount: group.rows.length,
              itemBuilder: (_, index) => _TransactionRow(row: group.rows[index]),
            ),
          ],
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 96),
        ),
      ],
    );
  }
}

/// Tiêu đề nhóm ngày — "HÔM NAY - dd/MM/yyyy" / "HÔM QUA - …" / "dd/MM/yyyy".
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.header});

  final String header;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        header,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Card "Thu tháng này / Chi tháng này" (FR-002/003): 2 khối cạnh nhau.
class _MonthStatCard extends StatelessWidget {
  const _MonthStatCard({required this.stat});

  final MonthStat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _StatBlock(label: 'Thu tháng này', isIncome: true, value: stat.incomeTotal)),
          const SizedBox(width: 10),
          Expanded(child: _StatBlock(label: 'Chi tháng này', isIncome: false, value: stat.expenseTotal)),
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
  });

  final String label;
  final bool isIncome;
  final int value;

  @override
  Widget build(BuildContext context) {
    final accent = isIncome ? AppColors.teal : AppColors.coral;
    final amountColor = isIncome ? AppColors.textPrimary : AppColors.coral;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.softCardBg,
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
              formatMoney(value),
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

/// Một dòng giao dịch: icon bubble + tên/dòng phụ + số tiền căn phải.
/// Thu teal `+`, chi coral `−`, chuyển khoản/điều chỉnh trung tính không dấu.
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.row});

  final TxnRow row;

  @override
  Widget build(BuildContext context) {
    final neutral =
        row.type == TxnType.transfer || row.type == TxnType.adjustment;
    final accent =
        row.type == TxnType.income
            ? AppColors.teal
            : row.type == TxnType.expense
            ? AppColors.coral
            : AppColors.listLabel;
    return InkWell(
      onTap: () {}, // điểm vào chi tiết giao dịch — PBI sau, no-op (FR-014)
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.listDivider)),
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
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.listLabel,
                      fontSize: 13,
                    ),
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
  const _RowBubble({
    required this.neutral,
    required this.row,
    required this.accent,
  });

  final bool neutral;
  final TxnRow row;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final icon = neutral
        ? (row.type == TxnType.transfer ? Icons.swap_horiz : Icons.tune)
        : categoryGlyph(row.title);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: neutral ? AppColors.softCardBg : AppColors.tealLightBg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: accent),
    );
  }
}

/// Empty state (FR-010): chưa có giao dịch nào → hướng dẫn ghi giao dịch đầu
/// tiên qua FAB, card ở trên vẫn hiện `0 đ`.
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
            const Text('🧾', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            const Text(
              'Chưa có giao dịch nào.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Chạm nút '+' giữa thanh dưới để ghi giao dịch đầu tiên.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.tabInactive, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
