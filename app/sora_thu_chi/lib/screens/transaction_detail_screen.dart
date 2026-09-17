import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/category/category.dart';
import '../core/date_label.dart';
import '../core/money_format.dart';
import '../core/transaction/transaction.dart';
import '../core/transaction/transaction_detail.dart';
import '../core/wallet/wallet.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/wallet_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'add_transaction_screen.dart';
import 'wallet_transfer_screen.dart';

/// Màn "Chi tiết giao dịch" — sub-page đè lên shell (AppBar riêng, không bottom
/// nav), theo mockup `04-chi-tiet-giao-dich.svg`. Nhận [ref] (R2); nạp lại dữ
/// liệu mỗi lần mở qua seam [loader] — mặc định đọc repository rồi dựng view
/// thuần [buildTransactionDetail] (FR-010, R1). Sửa (PBI 39) và Nhân bản
/// (PBI 40) đều mở lại [AddTransactionScreen]/[WalletTransferScreen] theo
/// đúng loại giao dịch; 3 chấm vẫn là điểm vào no-op (FR-012, Xóa PBI khác).
class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({super.key, required this.ref, this.loader});

  final TransactionDetailRef ref;

  /// Seam để test bơm view trực tiếp (không cần sqlite native); null → đọc qua
  /// `ensureWalletRepository()` (singleton). Trả null = không tìm thấy giao dịch.
  final Future<TransactionDetailView?> Function()? loader;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _loading = false;
  String? _error;
  TransactionDetailView? _view;

  /// Đang tải dữ liệu gốc để mở màn Sửa (PBI 39) — chặn bấm lặp/Nhân bản.
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _view = null;
    });
    try {
      final view = await (widget.loader ?? _loadDefault)();
      if (!mounted) return;
      setState(() {
        _view = view;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được dữ liệu giao dịch.'.tr;
        _loading = false;
      });
    }
  }

  Future<TransactionDetailView?> _loadDefault() async {
    final repository = ensureWalletRepository();
    final all = await repository.allTransactions();
    final wallets = await repository.loadAll();
    final names = {for (final w in wallets) w.id: w.name};
    return buildTransactionDetail(
      all: all,
      walletName: names,
      ref: widget.ref,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SubPageScaffold(
      title: 'Chi tiết giao dịch'.tr,
      actions: [
        // Điểm vào menu Sửa/Xóa — màn đích PBI sau, chạm không lỗi (FR-012).
        IconButton(
          icon: const Icon(Icons.more_vert),
          color: AppColors.white,
          onPressed: () {},
        ),
      ],
      bottomNavigationBar: _bottomActions(colors),
      child: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final error = _error;
    if (error != null) return _ErrorState(message: error, onRetry: _load);
    final view = _view;
    if (view == null) return const _NotFoundState();
    return _DetailContent(view: view);
  }

  /// Thanh 2 nút "Nhân bản" (phụ) / "Sửa" (chính) — chỉ hiện khi có view.
  Widget? _bottomActions(SoraColors colors) {
    final view = _view;
    if (view == null) return null;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _saving ? null : () => _duplicate(view),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.divider),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Nhân bản'.tr,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _saving ? null : () => _edit(view),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Sửa'.tr,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chạm "Sửa" (PBI 39): tải lại dữ liệu gốc rồi mở đúng màn theo loại giao
  /// dịch — Thu/Chi → [AddTransactionScreen] ở chế độ sửa (tải
  /// [Transaction]/[Category]/[Wallet] theo id); Chuyển khoản →
  /// [WalletTransferScreen] ở chế độ sửa (tải 2 vế theo `transferGroupId` +
  /// ví nguồn/đích). Kết quả `true` (đã lưu) → nạp lại màn Chi tiết
  /// (FR-001/FR-007/FR-008).
  Future<void> _edit(TransactionDetailView view) async {
    setState(() => _saving = true);
    try {
      final repository = ensureWalletRepository();
      final wallets = await repository.loadAll();
      Wallet? findWallet(int id) {
        for (final w in wallets) {
          if (w.id == id) return w;
        }
        return null;
      }

      bool? saved;
      if (view.type == TxnType.transfer) {
        final groupId = widget.ref.transferGroupId!;
        final all = await repository.allTransactions();
        final legs = all
            .where((t) => t.type == TxnType.transfer && t.transferGroupId == groupId)
            .toList();
        Transaction? source;
        Transaction? dest;
        for (final leg in legs) {
          if (leg.amount < 0) source ??= leg;
          if (leg.amount > 0) dest ??= leg;
        }
        if (source == null || dest == null) {
          throw StateError('Thiếu vế chuyển khoản $groupId.');
        }
        final sourceWallet = findWallet(source.walletId);
        final destWallet = findWallet(dest.walletId);
        if (sourceWallet == null) {
          throw StateError('Không tìm thấy ví nguồn ${source.walletId}.');
        }
        if (!mounted) return;
        setState(() => _saving = false);
        saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => WalletTransferScreen(
              sourceWallet: sourceWallet,
              destinationWallet: destWallet,
              controller: ensureWalletController(),
              editingTransferGroupId: groupId,
              initialAmount: source!.amount.abs(),
              initialDate: source.date,
              initialNote: source.note,
            ),
          ),
        );
      } else {
        final all = await repository.allTransactions();
        final original = all.firstWhere((t) => t.id == widget.ref.transactionId);
        final categoryType = original.type == TxnType.income
            ? CategoryType.income
            : CategoryType.expense;
        final categories = await repository.categoriesIncludingHidden(
          type: categoryType,
        );
        Category? category;
        for (final c in categories) {
          if (c.id == original.categoryId) {
            category = c;
            break;
          }
        }
        final wallet = findWallet(original.walletId);
        if (!mounted) return;
        setState(() => _saving = false);
        saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => AddTransactionScreen(
              editing: original,
              initialCategory: category,
              initialWallet: wallet,
            ),
          ),
        );
      }
      if (saved == true) await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không mở được màn sửa giao dịch.'.tr),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  /// Chạm "Nhân bản" (PBI 40): tải lại dữ liệu gốc rồi mở màn **tạo mới**
  /// đúng loại giao dịch — bám sát cấu trúc [_edit], khác duy nhất ở chỗ
  /// KHÔNG truyền `editing`/`editingTransferGroupId` (giữ nhánh tạo mới của
  /// `AddTransactionScreen`/`WalletTransferScreen`, không đụng bản gốc) và ép
  /// ngày giờ = hiện tại thay vì giữ ngày gốc (FR-002/FR-003/FR-005).
  Future<void> _duplicate(TransactionDetailView view) async {
    setState(() => _saving = true);
    try {
      final repository = ensureWalletRepository();
      final wallets = await repository.loadAll();
      Wallet? findWallet(int id) {
        for (final w in wallets) {
          if (w.id == id) return w;
        }
        return null;
      }

      bool? saved;
      if (view.type == TxnType.transfer) {
        final groupId = widget.ref.transferGroupId!;
        final all = await repository.allTransactions();
        final legs = all
            .where((t) => t.type == TxnType.transfer && t.transferGroupId == groupId)
            .toList();
        Transaction? source;
        Transaction? dest;
        for (final leg in legs) {
          if (leg.amount < 0) source ??= leg;
          if (leg.amount > 0) dest ??= leg;
        }
        if (source == null || dest == null) {
          throw StateError('Thiếu vế chuyển khoản $groupId.');
        }
        final sourceWallet = findWallet(source.walletId);
        final destWallet = findWallet(dest.walletId);
        if (sourceWallet == null) {
          throw StateError('Không tìm thấy ví nguồn ${source.walletId}.');
        }
        if (!mounted) return;
        setState(() => _saving = false);
        saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => WalletTransferScreen(
              sourceWallet: sourceWallet,
              destinationWallet: destWallet,
              controller: ensureWalletController(),
              initialAmount: source!.amount.abs(),
              initialDate: DateTime.now(),
              initialNote: source.note,
            ),
          ),
        );
      } else {
        final all = await repository.allTransactions();
        final original = all.firstWhere((t) => t.id == widget.ref.transactionId);
        final categoryType = original.type == TxnType.income
            ? CategoryType.income
            : CategoryType.expense;
        final categories = await repository.categoriesIncludingHidden(
          type: categoryType,
        );
        Category? category;
        for (final c in categories) {
          if (c.id == original.categoryId) {
            category = c;
            break;
          }
        }
        final wallet = findWallet(original.walletId);
        if (!mounted) return;
        setState(() => _saving = false);
        saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => AddTransactionScreen(
              initialType: original.type,
              initialCategory: category,
              initialWallet: wallet,
              initialAmount: original.amount.abs(),
              initialNote: original.note,
              initialDate: DateTime.now(),
              initialTags: original.tags,
              initialReceiptImage: original.receiptImage,
            ),
          ),
        );
      }
      if (saved == true) await _load();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không mở được màn nhân bản giao dịch.'.tr),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }
}

/// Lỗi đọc repository — thông báo + nút Thử lại gọi lại loader.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
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
            Icon(Icons.error_outline, color: colors.coralOnNeutral, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
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

/// Không tìm thấy giao dịch (ref lỗi thời) — trạng thái gọn, không crash.
class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🧾', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy giao dịch.'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nội dung cuộn: khối tóm tắt trên + các hàng chi tiết có điều kiện.
class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.view});

  final TransactionDetailView view;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Summary(view: view),
        _DetailRows(view: view),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Khối tóm tắt: bubble icon tròn + tên danh mục/nhãn + số tiền lớn màu ngữ
/// cảnh — thu teal `+`, chi coral `−`, transfer/adjustment trung tính không
/// dấu (FR-002/004, SC-003).
class _Summary extends StatelessWidget {
  const _Summary({required this.view});

  final TransactionDetailView view;

  bool get _neutral =>
      view.type == TxnType.transfer || view.type == TxnType.adjustment;

  Color _accent(SoraColors colors) => switch (view.type) {
    TxnType.income => colors.tealOnNeutral,
    TxnType.expense => colors.coralOnNeutral,
    TxnType.transfer || TxnType.adjustment => colors.listLabel,
  };

  Color _bubbleBg(SoraColors colors) =>
      _neutral ? colors.softCardBg : colors.tealLightBg;

  String get _amountText =>
      _neutral ? formatMoney(view.amount) : formatSignedMoney(view.amount);

  Color _amountColor(SoraColors colors) =>
      _neutral ? colors.textPrimary : _accent(colors);

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Container(
      width: double.infinity,
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _bubbleBg(colors),
              shape: BoxShape.circle,
            ),
            child: Icon(view.summaryGlyph, color: _accent(colors), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            view.summaryTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _amountText,
              style: TextStyle(
                color: _amountColor(colors),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Các hàng chi tiết — mỗi hàng icon dẫn đầu teal nhỏ + cột (nhãn / giá trị),
/// ngăn cách bằng đường kẻ mảnh `SoraColors.listDivider` giữa các hàng (FR-008).
/// Hàng hiển thị có điều kiện: rỗng → ẩn hẳn, không dòng trống (FR-007).
class _DetailRows extends StatelessWidget {
  const _DetailRows({required this.view});

  final TransactionDetailView view;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final v = view;
    final rows = <Widget>[];
    final hasPair =
        v.sourceWalletName != null && v.destWalletName != null;
    if (hasPair) {
      // Chuyển khoản: tách rõ chiều "Ví nguồn" → "Ví đích" (FR-006/SC-005).
      rows.add(_InfoRow(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Ví nguồn'.tr,
        value: _valueText(v.sourceWalletName!, colors),
      ));
      rows.add(_InfoRow(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Ví đích'.tr,
        value: _valueText(v.destWalletName!, colors),
      ));
    } else {
      rows.add(_InfoRow(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Ví'.tr,
        value: _valueText(v.singleWalletName ?? 'Ví'.tr, colors),
      ));
    }
    rows.add(_InfoRow(
      icon: Icons.schedule,
      label: 'Ngày giờ'.tr,
      value: _valueText(formatDateTimeDetailLabel(v.date), colors),
    ));
    if (v.note.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.notes,
        label: 'Ghi chú'.tr,
        value: _valueText(v.note, colors),
      ));
    }
    if (v.tags.isNotEmpty) {
      rows.add(_TagRow(tags: v.tags));
    }
    if (v.receiptImage.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.image_outlined,
        label: 'Ảnh hóa đơn'.tr,
        value: _ReceiptThumb(path: v.receiptImage),
      ));
    }
    if (v.location.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.location_on_outlined,
        label: 'Vị trí'.tr,
        value: _valueText(v.location, colors),
      ));
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, color: colors.listDivider),
          rows[i],
        ],
      ],
    );
  }

  Widget _valueText(String text, SoraColors colors) => Text(
    text,
    style: TextStyle(color: colors.textPrimary, fontSize: 15),
  );
}

/// Một hàng chi tiết: icon dẫn đầu nhỏ + cột nhãn (13 `listLabel`) / giá trị.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Icon(icon, size: 18, color: colors.tealOnNeutral),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.listLabel,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                value,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hàng Tag — dãy chip pill (`#tag`) trên nền [softCardBg], không icon dẫn
/// riêng (mockup); đủ mọi tag, không cắt (R4, FR-007).
class _TagRow extends StatelessWidget {
  const _TagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tag'.tr,
                  style: TextStyle(
                    color: colors.listLabel,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final tag in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.softCardBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: colors.tealOnNeutral,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hàng Ảnh hóa đơn — thumbnail 56×56 bo 8; file thiếu/lỗi → placeholder icon
/// (errorBuilder), không crash (R3/R7).
class _ReceiptThumb extends StatelessWidget {
  const _ReceiptThumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 56,
          height: 56,
          color: colors.softCardBg,
          child: Icon(Icons.image_outlined, color: colors.listLabel),
        ),
      ),
    );
  }
}
