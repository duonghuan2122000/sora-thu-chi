import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/date_label.dart';
import '../core/money_format.dart';
import '../core/transaction/transaction.dart';
import '../core/wallet/transfer_rules.dart';
import '../core/wallet/wallet.dart';
import '../core/wallet/wallet_controller.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/wallet_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'wallet_form_screen.dart';
import 'wallet_transfer_screen.dart';

/// Màn chi tiết một ví — sub-page từ danh sách ví (PBI 5/6).
/// Vùng teal hero (tên ở app bar, số dư/credit + loại ví), 3 hành động nhanh
/// (**Chuyển tiền** mở [WalletTransferScreen] — PBI 8; **Sửa ví** mở
/// [WalletFormScreen] — PBI 7; Ẩn ví điểm vào PBI sau) và nhóm
/// "GIAO DỊCH GẦN ĐÂY" đúng ví.
/// [transactions] là seam để test bơm list tĩnh; null → đọc động từ
/// [WalletController.transactionsOf] (research R5) — mọi khoản chuyển mới hiện
/// ngay sau khi trở về (FR-014).
class WalletDetailScreen extends StatefulWidget {
  const WalletDetailScreen({
    super.key,
    required this.wallet,
    this.transactions,
  });

  final Wallet wallet;
  final List<Transaction>? transactions;

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  late final WalletController _controller;
  late Wallet _wallet = widget.wallet;

  /// Danh sách giao dịch hiển thị: [widget.transactions] seam bơm thẳng (đọc live
  /// theo mỗi build) hoặc [wallet] đọc từ repository qua [_txns].
  List<Transaction>? _txns;
  bool _loading = false;

  List<Transaction> get _currentTxns =>
      widget.transactions ?? _txns ?? const [];

  bool get _hasTransactions =>
      (widget.transactions ?? _txns)?.isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    _controller = ensureWalletController();
    if (widget.transactions == null) {
      _loadTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _loading = true);
    final list = await _controller.transactionsOf(_wallet.id);
    if (!mounted) return;
    setState(() {
      _txns = list;
      _loading = false;
    });
  }

  Future<void> _openEdit() async {
    final edited = await Navigator.of(context).push<Wallet>(
      MaterialPageRoute<Wallet>(
        builder: (_) => WalletFormScreen(
          wallet: _wallet,
          hasTransactions: _hasTransactions,
          controller: _controller,
        ),
      ),
    );
    if (edited != null && mounted) {
      // FR-013: tên/icon/… mới hiện ngay; số dư & lịch sử không đổi (SC-004).
      setState(() => _wallet = edited);
    }
  }

  /// Hành động nhanh "Chuyển tiền" (FR-001/018/019): thẻ tín dụng hoặc không
  /// còn ví đích hợp lệ → thông báo rõ, không mở màn; ngược lại mở màn chuyển
  /// với ví đang xem làm nguồn. Trở về `true` → số dư + danh sách giao dịch
  /// của ví được nạp lại (FR-014).
  Future<void> _openTransfer() async {
    if (!canTransferFromWallet(_wallet)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thẻ tín dụng chưa dùng để chuyển tiền.'.tr),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }
    if (!hasEligibleDestination(_controller.wallets, _wallet.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chưa có ví đích hợp lệ để chuyển tiền.'.tr),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }
    final transferred = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WalletTransferScreen(
          sourceWallet: _wallet,
          controller: _controller,
        ),
      ),
    );
    if (transferred == true && mounted) {
      await _reloadAfterTransfer();
    }
  }

  Future<void> _reloadAfterTransfer() async {
    Wallet? fresh;
    for (final w in _controller.wallets) {
      if (w.id == _wallet.id) {
        fresh = w;
        break;
      }
    }
    final list = await _controller.transactionsOf(_wallet.id);
    if (!mounted) return;
    setState(() {
      if (fresh != null) _wallet = fresh; // số dư mới (FR-014).
      _txns = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: _wallet.name,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Hero(wallet: _wallet),
            _QuickActions(
              onTransfer: _openTransfer,
              onEdit: _openEdit,
              onHide: () {}, // PBI sau.
            ),
            _SectionHeader('GIAO DỊCH GẦN ĐÂY'.tr),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_currentTxns.isEmpty)
              const _EmptyTransactions()
            else
              ..._currentTxns.map((t) => _TxnRow(transaction: t)),
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
                ? '@percent% hạn mức đã dùng'.trParams({
                    'percent': wallet.creditUsedPercent.toString(),
                  })
                : wallet.typeLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Ba hành động nhanh tròn teal nhạt. Chuyển tiền/Ẩn ví giữ no-op (PBI sau);
/// "Sửa ví" mở form sửa (FR-006/007 PBI 7).
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onTransfer,
    required this.onEdit,
    required this.onHide,
  });

  final VoidCallback onTransfer;
  final VoidCallback onEdit;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Row(
        children: [
          _action(Icons.swap_horiz, 'Chuyển tiền'.tr, onTransfer, colors),
          _action(Icons.edit_outlined, 'Sửa ví'.tr, onEdit, colors),
          _action(Icons.visibility_off_outlined, 'Ẩn ví'.tr, onHide, colors),
        ],
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onTap,
    SoraColors colors,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.tealLightBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colors.tealOnNeutral, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.listLabel,
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
    final colors = SoraColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
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

/// Một dòng giao dịch: tròn icon theo dấu + màu theo loại, tiêu đề, dòng phụ
/// "danh mục · ngày" và số tiền căn phải tô màu ngữ cảnh (FR-009/010).
class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final t = transaction;
    final title = t.note.isNotEmpty
        ? t.note
        : (t.category.isNotEmpty ? t.category : t.typeLabel);
    final subtitle = t.category.isNotEmpty ? t.category : t.typeLabel;
    final arrow = t.amount < 0 ? Icons.arrow_downward : Icons.arrow_upward;
    final (Color bubbleBg, Color fg) = switch (t.type) {
      TxnType.income => (colors.tealLightBg, colors.tealOnNeutral),
      TxnType.expense => (colors.coralLightBg, colors.coralOnNeutral),
      TxnType.transfer ||
      TxnType.adjustment => (colors.softCardBg, colors.listLabel),
    };

    return InkWell(
      onTap: () {}, // FR-011: điểm vào PBI Giao dịch, chưa mở màn.
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.listDivider)),
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
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$subtitle · ${relativeDayLabel(t.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
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
    final colors = SoraColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧾', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              'Chưa có giao dịch nào.'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Giao dịch của ví sẽ xuất hiện tại đây.'.tr,
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
