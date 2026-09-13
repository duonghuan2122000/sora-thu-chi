import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/money_format.dart';
import '../core/transaction/transaction_controller.dart';
import '../core/transaction/transaction_filter.dart';
import '../core/widgets/month_stat_row.dart';
import '../core/widgets/screen_header.dart';
import '../core/widgets/txn_row_tile.dart';
import '../data/transaction_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'search_filter_screen.dart';

/// Màn "Giao dịch" (tab chính thứ 2) — theo mockup 01-danh-sach-giao-dich.svg:
/// header teal + icon lọc, card "Thu/Chi tháng này", danh sách giao dịch nhóm
/// ngày. Đọc qua [TransactionController]; nạp lại mỗi lần chọn tab (FR-011).
/// Icon lọc mở màn tìm/lọc (PBI 12); khi đang áp dụng bộ lọc → card tháng ẩn,
/// thay bằng thanh `N kết quả · Tổng` + Bỏ lọc (R5/FR-013).
class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  /// Mở màn lọc (bản nháp = bộ lọc đang áp dụng hoặc mặc định); Áp dụng →
  /// [TransactionController.setFilter], back → giữ tập cũ (FR-015).
  Future<void> _openFilter(
    BuildContext context,
    TransactionController controller,
  ) async {
    final filter = await Navigator.of(context).push<TxnSearchFilter>(
      MaterialPageRoute(
        builder: (_) => SearchFilterScreen(
          now: controller.now,
          initial: controller.activeFilter.value,
        ),
      ),
    );
    if (filter == null || !context.mounted) return;
    controller.setFilter(filter);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ensureTransactionController();
    return Column(
      children: [
        ScreenHeader(
          title: 'Giao dịch'.tr,
          centerTitle: true,
          trailing: _FilterButton(onTap: () => _openFilter(context, controller)),
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
            // Đang áp dụng bộ lọc → hiển thị tập đã lọc (additive, không hồi quy
            // đường không-lọc — R13). Bộ lọc sống trong controller (SC-007).
            if (controller.activeFilter.value != null) {
              final filteredView = controller.filtered.value;
              if (filteredView != null) {
                return _FilteredList(view: filteredView);
              }
            }
            return _TransactionList(view: view);
          }),
        ),
      ],
    );
  }
}

/// Nút lọc trong app bar — mở màn "Tìm kiếm & Lọc" (FR-014 → PBI 12).
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
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
    final colors = SoraColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: colors.coralOnNeutral, size: 40),
            const SizedBox(height: 12),
            Text(
              'Không đọc được dữ liệu giao dịch.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
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
              child: Text('Thử lại'.tr),
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
        SliverToBoxAdapter(child: MonthStatRow(stat: view.stat)),
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
              itemBuilder: (_, index) => TxnRowTile(row: group.rows[index]),
            ),
          ],
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 96),
        ),
      ],
    );
  }
}

/// Danh sách khi đang áp dụng bộ lọc (PBI 12, R4/R5): card "Thu/Chi tháng
/// này" **ẩn**, thay bằng thanh chỉ báo `N kết quả · Tổng: X đ` + Bỏ lọc; vẽ
/// nhóm ngày (sort ngày) hoặc **phẳng** (sort tiền); empty-khớp riêng.
class _FilteredList extends StatelessWidget {
  const _FilteredList({required this.view});

  final FilteredTxView view;

  @override
  Widget build(BuildContext context) {
    final groups = view.groups;
    final flat = view.flatRows;
    final empty =
        (groups?.isEmpty ?? true) && (flat?.isEmpty ?? true);
    return CustomScrollView(
      key: const PageStorageKey('transaction-filter-list'),
      slivers: [
        SliverToBoxAdapter(
          child: _FilterBar(
            count: view.summary.count,
            signedTotal: view.summary.signedTotal,
            onClear: () => ensureTransactionController().clearFilter(),
          ),
        ),
        if (empty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _NoMatchState(),
          )
        else if (groups != null)
          for (final group in groups) ...[
            SliverToBoxAdapter(child: _DayHeader(header: group.header)),
            SliverList.builder(
              itemCount: group.rows.length,
              itemBuilder: (_, index) =>
                  TxnRowTile(row: group.rows[index]),
            ),
          ]
        else
          SliverList.builder(
            itemCount: flat!.length,
            itemBuilder: (_, index) => TxnRowTile(row: flat[index]),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
    );
  }
}

/// Thanh chỉ báo lọc đầu danh sách (R5/FR-013) — thay card "Thu/Chi tháng này".
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.count,
    required this.signedTotal,
    required this.onClear,
  });

  final int count;
  final int signedTotal;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: colors.tealOnNeutral, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '@n kết quả · Tổng: @total'.trParams(
                {'n': '$count', 'total': formatMoney(signedTotal)},
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('clear-filter'),
            onPressed: onClear,
            child: Text('Bỏ lọc'.tr),
          ),
        ],
      ),
    );
  }
}

/// Empty khi tập khớp bộ lọc rỗng (FR-016/R14) — khác "Chưa có giao dịch nào."
class _NoMatchState extends StatelessWidget {
  const _NoMatchState();

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: colors.tabInactive, size: 44),
            const SizedBox(height: 12),
            Text(
              'Không có giao dịch khớp bộ lọc.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bỏ lọc để xem toàn bộ.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.tabInactive, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tiêu đề nhóm ngày — "HÔM NAY - dd/MM/yyyy" / "HÔM QUA - …" / "dd/MM/yyyy".
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.header});

  final String header;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        header,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Empty state (FR-010): chưa có giao dịch nào → hướng dẫn ghi giao dịch đầu
/// tiên qua FAB, card ở trên vẫn hiện `0 đ`.
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
            const Text('🧾', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              'Chưa có giao dịch nào.'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Chạm nút '+' giữa thanh dưới để ghi giao dịch đầu tiên.".tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.tabInactive, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
