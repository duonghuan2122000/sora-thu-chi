import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/category/category.dart';
import '../core/date_label.dart';
import '../core/money_format.dart';
import '../core/transaction/add_form.dart';
import '../core/transaction/transaction.dart';
import '../core/wallet/wallet.dart';
import '../core/wallet/wallet_rules.dart';
import '../core/widgets/amount_keypad.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'category_picker_screen.dart';
import 'wallet_transfer_screen.dart';

/// Màn "Thêm giao dịch" (mockup `02`, R7) — ghi khoản thu/chi mới, màn toàn
/// màn hình (app bar teal: X đóng / check lưu, **không** bottom nav).
/// Segmented Chi|Thu|Chuyển khoản (mặc định Chi); số tiền gõ bằng numpad tùy
/// chỉnh; 4 trường Danh mục/Ví/Ngày giờ/Ghi chú; nút "Lưu giao dịch" cố định.
/// Stateful + [WalletRepository] inject (không GetX — màn tác vụ một-lần, R11).
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.repository,
    this.initialType = TxnType.expense,
  });

  /// Seam test: mặc định null → [ensureWalletRepository] khi vào (R11).
  final WalletRepository? repository;

  /// Loại mở sẵn (PBI 24 R14) — `transfer` thì màn tự mở luồng chuyển khoản sau
  /// khi nạp ví xong. Mặc định `expense` = hành vi cũ.
  final TxnType initialType;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late final WalletRepository _repository;
  late final DateTime _openedAt = DateTime.now();

  late TxnType _type = widget.initialType;
  int _amount = 0;
  Category? _category;
  Wallet? _wallet;
  late DateTime _date = DateTime.now();
  final TextEditingController _noteCtrl = TextEditingController();

  bool _loading = true;
  List<Wallet> _activeWallets = const [];
  Set<String> _missing = {};
  bool _saving = false;

  /// Chỉ tự mở luồng chuyển khoản **một lần** cho mỗi lần vào màn (R14).
  bool _autoTransferOpened = false;

  bool get _hasActiveWallets => _activeWallets.isNotEmpty;

  bool get _noActiveWallet => !_loading && _activeWallets.isEmpty;

  bool get _isDirty => isDirty(
    amount: _amount,
    category: _category,
    note: _noteCtrl.text,
    date: _date,
    type: _type,
    now: _openedAt,
  );

  Color _amountAccent(SoraColors colors) =>
      _type == TxnType.income ? colors.tealOnNeutral : colors.coralOnNeutral;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ensureWalletRepository();
    _loadWallets();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    setState(() => _loading = true);
    try {
      final wallets = await _repository.loadAll();
      if (!mounted) return;
      final active = wallets.where((w) => !w.isHidden).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      // Pre-select ví mặc định (hoạt động); thiếu mặc định → ví hoạt động đầu.
      final preselect = currentActiveDefault(active) ?? firstActive(active);
      setState(() {
        _activeWallets = active;
        _wallet = preselect;
        _loading = false;
      });
      // Vào từ sheet với lựa chọn "Chuyển khoản" → mở luồng chuyển ngay, đúng
      // một lần (R14); bỏ qua hỏi "bỏ dữ liệu" vì form còn trống.
      if (widget.initialType == TxnType.transfer && !_autoTransferOpened) {
        _autoTransferOpened = true;
        await _openTransferFlow(skipDirtyCheck: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không đọc được danh sách ví.'.tr),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  static Wallet? firstActive(List<Wallet> wallets) =>
      wallets.isEmpty ? null : wallets.first;

  void _switchType(TxnType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _category = null; // danh mục khác loại → bỏ chọn cũ.
      _missing.clear();
    });
  }

  /// Chạm tab "Chuyển khoản" — mở luồng PBI 8; dirty thì xác nhận bỏ (R10).
  /// [skipDirtyCheck] dùng cho lần tự mở khi vào màn với `initialType` transfer.
  Future<void> _openTransferFlow({bool skipDirtyCheck = false}) async {
    if (!skipDirtyCheck && _isDirty) {
      final leave = await _confirmDiscard();
      if (leave != true || !mounted) return;
    }
    final source = _wallet;
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chưa có ví hoạt động để chuyển tiền.'.tr),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }
    final transferred = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WalletTransferScreen(
          sourceWallet: source,
          controller: ensureWalletController(),
        ),
      ),
    );
    // Transfer xong → màn thêm tự pop(true) để shell làm mới (R10).
    if (transferred == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _appendDigit(int digit) {
    setState(() {
      _amount = appendAmountDigit(_amount, digit);
      _missing.remove('amount');
    });
  }

  void _backspace() {
    setState(() => _amount = backspaceAmount(_amount));
  }

  Future<void> _pickCategory() async {
    final picked = await Navigator.of(context).push<Category>(
      MaterialPageRoute(
        builder: (_) => CategoryPickerScreen(type: _toCategoryType(_type)),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _category = picked;
        _missing.remove('category');
      });
    }
  }

  CategoryType _toCategoryType(TxnType t) => t == TxnType.income
      ? CategoryType.income
      : CategoryType.expense;

  Future<void> _pickWallet() async {
    if (_activeWallets.length <= 1) return; // 1 ví → nạp sẵn, không cần mở.
    final picked = await showModalBottomSheet<Wallet>(
      context: context,
      builder: (_) => _WalletSheet(wallets: _activeWallets),
    );
    if (picked != null && mounted) {
      setState(() {
        _wallet = picked;
        _missing.remove('wallet');
      });
    }
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
      _missing.remove('date');
    });
  }

  Future<void> _save() async {
    if (_saving || !_hasActiveWallets) return;
    final missing = missingRequiredFields(
      amount: _amount,
      category: _category,
      wallet: _wallet,
      date: _date,
    );
    setState(() => _missing = missing.toSet());
    if (missing.isNotEmpty) return;

    setState(() => _saving = true);
    try {
      await _repository.addTransaction(
        walletId: _wallet!.id,
        type: _type,
        amount: _amount,
        category: _category!,
        date: _date,
        note: _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không lưu được giao dịch. Vui lòng thử lại.'.tr),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  Future<bool?> _confirmDiscard() => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Hủy giao dịch?'.tr),
      content: Text('Dữ liệu đã nhập sẽ bị mất.'.tr),
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

  /// Đóng (X / back) — dirty thì xác nhận; đang lưu thì chặn rời (FR-014/R9).
  Future<void> _requestClose() async {
    if (_saving) return;
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await _confirmDiscard();
    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Thêm giao dịch'.tr),
          leading: IconButton(
            key: const ValueKey('close-add'),
            tooltip: 'Đóng'.tr,
            icon: const Icon(Icons.close),
            onPressed: _saving ? null : _requestClose,
          ),
          actions: [
            IconButton(
              key: const ValueKey('save-check'),
              tooltip: 'Lưu giao dịch'.tr,
              icon: const Icon(Icons.check),
              onPressed: _saving || !_hasActiveWallets ? null : _save,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _scrollableBody(colors)),
            AmountKeypad(onDigit: _appendDigit, onBackspace: _backspace),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('save-transaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _saving || !_hasActiveWallets ? null : _save,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Lưu giao dịch'.tr),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scrollableBody(SoraColors colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      children: [
        _segmented(colors),
        const SizedBox(height: 20),
        _amountSection(colors),
        if (_missing.contains('amount'))
          _fieldError('Vui lòng nhập số tiền lớn hơn 0'.tr, colors),
        const SizedBox(height: 12),
        if (_noActiveWallet)
          _emptyWalletBanner(colors)
        else ...[
          _fieldRow(
            key: const ValueKey('field-category'),
            icon: Icons.category_outlined,
            label: 'Danh mục'.tr,
            value: _category?.name.tr,
            hint: 'Chọn danh mục'.tr,
            onTap: _pickCategory,
            error: _missing.contains('category') ? 'Chưa chọn danh mục'.tr : null,
            colors: colors,
          ),
          _fieldRow(
            key: const ValueKey('field-wallet'),
            icon: Icons.account_balance_wallet_outlined,
            label: 'Ví'.tr,
            value: _wallet?.name,
            hint: 'Chọn ví'.tr,
            onTap: _pickWallet,
            error: _missing.contains('wallet') ? 'Chưa chọn ví'.tr : null,
            colors: colors,
          ),
          _fieldRow(
            key: const ValueKey('field-datetime'),
            icon: Icons.calendar_today_outlined,
            label: 'Ngày giờ'.tr,
            value: formatDateTimeDetailLabel(_date),
            onTap: _pickDateTime,
            error: _missing.contains('date') ? 'Chưa chọn ngày giờ'.tr : null,
            colors: colors,
          ),
          _noteRow(colors),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  /// Segmented Chi | Thu | Chuyển khoản — chosen teal pill, unchosen viền trắng.
  Widget _segmented(SoraColors colors) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.softCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _segment('Chi'.tr, TxnType.expense, colors),
          _segment('Thu'.tr, TxnType.income, colors),
          _transferSegment(colors),
        ],
      ),
    );
  }

  Widget _segment(String label, TxnType type, SoraColors colors) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchType(type),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.white : colors.listLabel,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _transferSegment(SoraColors colors) {
    return Expanded(
      child: GestureDetector(
        onTap: _openTransferFlow,
        child: Container(
          alignment: Alignment.center,
          child: Text(
            'Chuyển khoản'.tr,
            style: TextStyle(
              color: colors.listLabel,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountSection(SoraColors colors) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatMoney(_amount),
            key: const ValueKey('amount-text'),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          key: const ValueKey('amount-underline'),
          width: 110,
          height: 2,
          decoration: BoxDecoration(color: _amountAccent(colors)),
        ),
      ],
    );
  }

  Widget _fieldError(String message, SoraColors colors) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      message,
      style: TextStyle(color: colors.coralOnNeutral, fontSize: 12),
    ),
  );

  Widget _emptyWalletBanner(SoraColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.coralLightBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Chưa có ví hoạt động — hãy tạo ví trong Quản lý ví.'.tr,
        style: TextStyle(color: colors.coralOnNeutral, fontSize: 13),
      ),
    );
  }

  /// Một dòng trường bắt buộc: icon tròn teal nhạt + nhãn + value + chevron.
  Widget _fieldRow({
    required Key key,
    required IconData icon,
    required String label,
    String? value,
    String? hint,
    required VoidCallback onTap,
    String? error,
    required SoraColors colors,
  }) {
    return Column(
      children: [
        InkWell(
          key: key,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.tealLightBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: colors.tealOnNeutral, size: 15),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: colors.listLabel,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value ?? hint ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: value != null
                              ? colors.textPrimary
                              : colors.tabInactive,
                          fontSize: 14,
                          fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.tabInactive, size: 20),
              ],
            ),
          ),
        ),
        Divider(color: colors.listDivider, height: 1),
        if (error != null) _fieldError(error, colors),
      ],
    );
  }

  /// Dòng Ghi chú — TextField tùy chọn, nhập trực tiếp (FR-010).
  Widget _noteRow(SoraColors colors) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.tealLightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit_note, color: colors.tealOnNeutral, size: 15),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              child: Text(
                'Ghi chú'.tr,
                style: TextStyle(
                  color: colors.listLabel,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: TextField(
                  key: const ValueKey('note-field'),
                  controller: _noteCtrl,
                  minLines: 1,
                  maxLines: 3,
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Thêm ghi chú (tùy chọn)'.tr,
                    hintStyle: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Divider(color: colors.listDivider, height: 1),
      ],
    );
  }
}

/// Bottom sheet chọn ví hoạt động (gồm thẻ tín dụng — R8).
class _WalletSheet extends StatelessWidget {
  const _WalletSheet({required this.wallets});

  final List<Wallet> wallets;

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
              'Chọn ví'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final w in wallets)
            InkWell(
              onTap: () => Navigator.of(context).pop(w),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: colors.listDivider),
                  ),
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
