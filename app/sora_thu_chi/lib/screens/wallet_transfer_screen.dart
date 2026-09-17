import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../core/date_label.dart';
import '../core/money_format.dart';
import '../core/wallet/transfer_rules.dart';
import '../core/wallet/wallet.dart';
import '../core/wallet/wallet_controller.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Màn chuyển tiền giữa hai ví (spec PBI 8, FR-001…019) — bám mockup
/// `docs/wallet/wallet-transfer-screen.svg`. Mở từ màn chi tiết ví nguồn;
/// [sourceWallet] nạp sẵn ô "Từ ví", ô "Đến ví" chọn từ danh sách lọc bởi
/// [eligibleDestinations]. Xác nhận → [WalletController.transfer] ghi atomic 2
/// vế, pop `true` để chi tiết nạp lại (FR-014).
///
/// **Chế độ sửa** (PBI 39, qua [editingTransferGroupId]): nạp sẵn
/// [destinationWallet]/[initialAmount]/[initialDate]/[initialNote], tiêu đề
/// đổi "Sửa chuyển khoản", xác nhận gọi [WalletController.updateTransfer]
/// (ghi đè tại chỗ 2 vế, không tạo dòng mới), rời màn khi có thay đổi chưa
/// lưu → hỏi xác nhận (FR-006, không áp dụng ở luồng Chuyển tiền mới — hành
/// vi cũ). Điểm vào: nút "Sửa" ở `transaction_detail_screen.dart`.
class WalletTransferScreen extends StatefulWidget {
  const WalletTransferScreen({
    super.key,
    required this.sourceWallet,
    required this.controller,
    this.editingTransferGroupId,
    this.destinationWallet,
    this.initialAmount,
    this.initialDate,
    this.initialNote,
  });

  final Wallet sourceWallet;
  final WalletController controller;

  /// Sửa giao dịch Chuyển khoản đã có (PBI 39) — id vế nguồn, bất biến. `null`
  /// = chế độ Chuyển tiền mới (hành vi cũ). Khác `null` → nạp sẵn
  /// [destinationWallet]/[initialAmount]/[initialDate]/[initialNote], tiêu đề
  /// đổi "Sửa chuyển khoản", nhãn nút chính đổi "Lưu thay đổi", xác nhận gọi
  /// `WalletController.updateTransfer` thay vì `transfer`.
  final int? editingTransferGroupId;

  /// Ví đích gốc — chỉ dùng khi [editingTransferGroupId] != null.
  final Wallet? destinationWallet;
  final int? initialAmount;
  final DateTime? initialDate;
  final String? initialNote;

  bool get isEditing => editingTransferGroupId != null;

  @override
  State<WalletTransferScreen> createState() => _WalletTransferScreenState();
}

class _WalletTransferScreenState extends State<WalletTransferScreen> {
  late Wallet _source = widget.sourceWallet;
  late Wallet? _destination = widget.destinationWallet;

  late final TextEditingController _amountCtrl = TextEditingController(
    text: widget.initialAmount == null
        ? ''
        : formatAmount(widget.initialAmount!),
  );
  late final TextEditingController _noteCtrl = TextEditingController(
    text: widget.initialNote ?? '',
  );

  late DateTime _date = widget.initialDate ?? DateTime.now();

  /// Baseline gốc (chế độ sửa) — so sánh khi rời màn để hỏi xác nhận (FR-006).
  late final Wallet _initialSource = widget.sourceWallet;
  late final Wallet? _initialDestination = widget.destinationWallet;
  late final int _initialAmount = widget.initialAmount ?? 0;
  late final String _initialNote = widget.initialNote ?? '';
  late final DateTime _initialDate = widget.initialDate ?? _date;

  bool get _isDirty =>
      _source.id != _initialSource.id ||
      _destination?.id != _initialDestination?.id ||
      _amount != _initialAmount ||
      _noteCtrl.text.trim() != _initialNote.trim() ||
      _date != _initialDate;

  /// Lỗi hiển thị tại trường số tiền sau khi bấm Xác nhận (FR-010).
  String? _amountError;
  bool _saving = false;

  WalletController get _controller => widget.controller;

  int get _amount => parseAmount(_amountCtrl.text);

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<Wallet> get _choices =>
      eligibleDestinations(_controller.wallets, _source.id);

  void _onAmountChanged(String _) {
    final digits = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _amountCtrl.clear();
    } else {
      final formatted = formatAmount(int.parse(digits));
      if (_amountCtrl.text != formatted) {
        _amountCtrl.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
    if (_amountError != null) setState(() => _amountError = null);
    setState(() {});
  }

  Future<void> _pickDestination() async {
    final picked = await showModalBottomSheet<Wallet>(
      context: context,
      builder: (_) => _DestinationSheet(choices: _choices),
    );
    if (picked != null && mounted) {
      setState(() => _destination = picked);
    }
  }

  void _swap() {
    final dest = _destination;
    if (dest == null) return;
    final newSource = dest;
    final newDest = _source;
    // Không cho hạ đích xuống ví không hợp lệ (ví dụ ẩn khi đảo từ ví ẩn) —
    // buộc chọn lại giữ bất biến (FR-003/011).
    final newSourceChoices = eligibleDestinations(
      _controller.wallets,
      newSource.id,
    );
    final nextDest = newSourceChoices.any((w) => w.id == newDest.id)
        ? newDest
        : null;
    setState(() {
      _source = newSource;
      _destination = nextDest;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 20),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null || !mounted) return;
    setState(() {
      _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  /// Đủ điều kiện bấm Xác nhận: đã chọn ví đích + chưa đang lưu (FR-010/SC-006).
  /// Lỗi số tiền ≤ 0 được báo tại trường khi bấm (không chặn khả năng bấm).
  bool get _canConfirm => _destination != null && !_saving;

  Future<void> _confirm() async {
    final dest = _destination;
    if (dest == null || _saving) return;
    final amount = _amount;
    if (amount <= 0) {
      setState(() => _amountError = 'Vui lòng nhập số tiền lớn hơn 0'.tr);
      return;
    }
    setState(() => _saving = true);
    try {
      final groupId = widget.editingTransferGroupId;
      if (groupId != null) {
        await _controller.updateTransfer(
          transferGroupId: groupId,
          fromId: _source.id,
          toId: dest.id,
          amount: amount,
          date: _date,
          note: _noteCtrl.text.trim(),
        );
      } else {
        await _controller.transfer(
          fromId: _source.id,
          toId: dest.id,
          amount: amount,
          date: _date,
          note: _noteCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không chuyển được tiền. Vui lòng thử lại.'.tr),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  Future<bool?> _confirmDiscard() => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Hủy sửa chuyển khoản?'.tr),
      content: Text('Dữ liệu đã sửa sẽ bị mất.'.tr),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Hủy'.tr),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Thoát'.tr),
        ),
      ],
    ),
  );

  /// Chỉ chặn back khi đang sửa và có thay đổi chưa lưu (R hành vi mới, PBI
  /// 39) — luồng "Chuyển tiền mới" giữ nguyên hành vi cũ (không hỏi).
  Future<void> _requestClose() async {
    if (_saving) return;
    if (!widget.isEditing || !_isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await _confirmDiscard();
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return PopScope(
      canPop: !widget.isEditing || !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: SubPageScaffold(
        title:
            (widget.isEditing ? 'Sửa chuyển khoản' : 'Chuyển tiền giữa ví').tr,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  disabledBackgroundColor: AppColors.teal.withValues(
                    alpha: 0.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _canConfirm ? _confirm : null,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    (widget.isEditing ? 'Lưu thay đổi' : 'Xác nhận chuyển tiền')
                        .tr,
                  ),
                ),
              ),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _fieldLabel('Từ ví'.tr, colors),
              _WalletCard(
                wallet: _source,
                trailing: null,
                onTap: null, // chỉ đọc (acceptance 1, FR-001)
              ),
              const SizedBox(height: 4),
              Center(
                child: _SwapButton(enabled: _destination != null, onTap: _swap),
              ),
              const SizedBox(height: 4),
              _fieldLabel('Đến ví'.tr, colors),
              if (_destination == null)
                _ChooseDestinationCard(onTap: _pickDestination)
              else
                _WalletCard(
                  wallet: _destination!,
                  trailing: Icon(Icons.expand_more, color: colors.tabInactive),
                  onTap: _pickDestination,
                ),
              const SizedBox(height: 20),
              _fieldLabel('Số tiền chuyển'.tr, colors),
              TextFormField(
                key: const ValueKey('amount-field'),
                controller: _amountCtrl,
                onChanged: _onAmountChanged,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
                ],
                maxLength: 14,
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: 'đ',
                  counterText: '',
                  errorText: _amountError,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Ngày giờ'.tr, colors),
              InkWell(
                key: const ValueKey('datetime-field'),
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatDateTimeLabel(_date),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: colors.tabInactive,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Ghi chú'.tr, colors),
              TextField(
                key: const ValueKey('note-field'),
                controller: _noteCtrl,
                decoration: InputDecoration(
                  hintText: 'Ghi chú (không bắt buộc)'.tr,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _AfterBalancePreview(
                source: _source,
                destination: _destination,
                amount: _amount,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một ô ví (nguồn hoặc đích): vòng icon + tên + số dư, có nút mở chọn nếu đích.
class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.wallet, required this.trailing, this.onTap});

  final Wallet wallet;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Material(
      color: colors.softCardBg,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.tealLightBg,
                  shape: BoxShape.circle,
                ),
                child: Text(wallet.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.name,
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
                      'Số dư: @amount'.trParams({
                        'amount': formatMoney(wallet.balance),
                      }),
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
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Ô "Đến ví" chưa chọn — chạm mở danh sách ví đích.
class _ChooseDestinationCard extends StatelessWidget {
  const _ChooseDestinationCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return Material(
      color: colors.softCardBg,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Chọn ví'.tr,
                  style: TextStyle(color: colors.tabInactive, fontSize: 15),
                ),
              ),
              Icon(Icons.expand_more, color: colors.tabInactive),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nút hoán đổi nguồn/đích (FR-004) — chỉ dùng khi đã chọn đủ 2 ví.
class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? colors.tealLightBg : colors.softCardBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.swap_vert,
            color: enabled ? colors.tealOnNeutral : colors.tabInactive,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet liệt kê ví đích hợp lệ (FR-003/011/018): mỗi dòng icon + tên +
/// số dư. Không chứa ví nguồn / thẻ tín dụng / ví ẩn / khác tiền tệ.
class _DestinationSheet extends StatelessWidget {
  const _DestinationSheet({required this.choices});

  final List<Wallet> choices;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              'Chọn ví đến'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final w in choices)
            InkWell(
              onTap: () => Navigator.of(context).pop(w),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                        color: colors.tealLightBg,
                        shape: BoxShape.circle,
                      ),
                      child: Text(w.icon, style: const TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.name,
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
                            w.typeLabel,
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
                      child: Text(
                        formatMoney(w.balance),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Dòng "Số dư sau chuyển" (FR-008): cập nhật live khi đủ nguồn + đích + tiền.
/// Số dư nguồn âm → chữ coral + cảnh báo mềm, không chặn (FR-009).
class _AfterBalancePreview extends StatelessWidget {
  const _AfterBalancePreview({
    required this.source,
    required this.destination,
    required this.amount,
  });

  final Wallet source;
  final Wallet? destination;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final dst = destination;
    final sourceAfter = source.balance - amount;
    final computable = dst != null && amount > 0;
    final negative = computable && sourceAfter < 0;
    final preview = computable
        ? '${formatMoney(sourceAfter)} / ${formatMoney(dst.balance + amount)}'
        : '— / —';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.softCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Số dư sau chuyển'.tr,
            style: TextStyle(
              color: colors.tabInactive,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            preview,
            style: TextStyle(
              color: negative ? colors.coralOnNeutral : colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (negative) ...[
            const SizedBox(height: 6),
            Text(
              'Số dư sau chuyển sẽ âm'.tr,
              style: TextStyle(color: colors.coralOnNeutral, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// Nhãn mục nhỏ xám (bên trên từng trường) — cùng kiểu các màn quản lý ví.
Widget _fieldLabel(String text, SoraColors colors) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(
    text,
    style: TextStyle(
      color: colors.listLabel,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  ),
);
