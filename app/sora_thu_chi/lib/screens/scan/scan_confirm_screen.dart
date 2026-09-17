import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/category/category.dart';
import '../../core/date_label.dart';
import '../../core/money_format.dart';
import '../../core/scan/scan_duplicate.dart';
import '../../core/scan/scan_image_store.dart';
import '../../core/scan/scan_log.dart';
import '../../core/scan/scan_log_session.dart';
import '../../core/scan/scan_result.dart';
import '../../core/transaction/add_form.dart';
import '../../core/transaction/transaction.dart';
import '../../core/wallet/wallet.dart';
import '../../core/wallet/wallet_rules.dart';
import '../../core/widgets/amount_keypad.dart';
import '../../core/widgets/sub_page_scaffold.dart';
import '../../data/notification_deps.dart';
import '../../data/scan_deps.dart';
import '../../data/wallet_deps.dart';
import '../../data/wallet_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/sora_colors.dart';
import '../category_picker_screen.dart';
import 'widgets/receipt_viewer.dart';

/// Màn xác nhận kết quả quét (mockup `scan-04`) — **bắt buộc** đi qua trước khi
/// ghi (SC-004): 6 trường sửa được, chỉ báo độ tin cậy, banner cảnh báo trùng
/// nhẹ, nút "Lưu giao dịch" cố định chân màn. Chạm một trường → khoanh vùng
/// tương ứng trên ảnh. Pop `true` nếu đã lưu giao dịch.
class ScanConfirmScreen extends StatefulWidget {
  const ScanConfirmScreen({
    super.key,
    required this.extraction,
    required this.imagePath,
    this.rawText = '',
    this.repository,
    this.imageStore,
    this.now,
    this.readBytes,
    required this.logSession,
  });

  final ScanExtraction extraction;
  final String imagePath;
  final String rawText;
  final WalletRepository? repository;
  final ScanImageStore? imageStore;
  final DateTime? now;

  /// Nhật ký trích xuất AI (PBI 47) — phiên do `ScanProcessingScreen` tạo,
  /// màn này chỉ tích sự kiện sửa/back/lưu rồi gọi `finish()`.
  final ScanLogSession logSession;

  /// Seam test cho bước đọc file ảnh khi lưu (test widget không chạy I/O thật).
  final Future<Uint8List> Function(String path)? readBytes;

  @override
  State<ScanConfirmScreen> createState() => _ScanConfirmScreenState();
}

class _ScanConfirmScreenState extends State<ScanConfirmScreen> {
  late final WalletRepository _repository =
      widget.repository ?? ensureWalletRepository();
  late final ScanImageStore _imageStore = widget.imageStore ?? ensureScanImageStore();

  late TxnType _type = widget.extraction.type;
  late int _amount = widget.extraction.amount.value ?? 0;
  bool _amountEdited = false;
  late DateTime _date = widget.extraction.date.value ?? DateTime.now();
  late final TextEditingController _merchantCtrl = TextEditingController(
    text: widget.extraction.merchant.value ?? '',
  );
  late Category? _category = widget.extraction.category.value;

  List<Wallet> _wallets = const [];
  Wallet? _wallet;
  bool _loadingWallets = true;
  bool _saving = false;
  ScanRect? _activeRect;
  Transaction? _duplicate;

  /// Đã ghi sự kiện `save` + gọi `logSession.finish(saved)` chưa — chặn
  /// `PopScope` ghi thêm sự kiện `back`/`finish(cancelled)` sau khi đã lưu.
  bool _saved = false;

  int _nowMillis() => (widget.now ?? DateTime.now()).millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _repository.loadAll();
      if (!mounted) return;
      final active = wallets.where((w) => !w.isHidden).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _wallets = active;
        _wallet = currentActiveDefault(active) ?? (active.isEmpty ? null : active.first);
        _loadingWallets = false;
      });
      await _refreshDuplicate();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingWallets = false);
    }
  }

  /// Cảnh báo trùng **nhẹ** — cùng số tiền trong ±24h, không chặn lưu (FR-035).
  Future<void> _refreshDuplicate() async {
    if (_amount <= 0) {
      if (mounted) setState(() => _duplicate = null);
      return;
    }
    try {
      final all = await _repository.allTransactions();
      if (!mounted) return;
      setState(() {
        _duplicate = findRecentDuplicate(all, amount: _amount, date: _date);
      });
    } catch (_) {
      // Không đọc được danh sách → bỏ qua cảnh báo, không chặn luồng.
    }
  }

  bool get _canSave => !_saving && _amount > 0 && _wallet != null;

  void _appendDigit(int digit) {
    final from = _amount;
    setState(() {
      // Lần gõ đầu tiên thay thế số trích xuất (không nối vào đuôi).
      _amount = _amountEdited ? appendAmountDigit(_amount, digit) : digit;
      _amountEdited = true;
    });
    _logAmountEdit(from);
  }

  void _backspace() {
    final from = _amount;
    setState(() {
      _amountEdited = true;
      _amount = backspaceAmount(_amount);
    });
    _logAmountEdit(from);
  }

  void _logAmountEdit(int from) {
    if (from == _amount) return;
    widget.logSession.addEvent(
      ScanLogEvent(
        type: ScanLogEventType.edit,
        field: 'amount',
        fromValue: '$from',
        toValue: '$_amount',
        atMillis: _nowMillis(),
      ),
    );
  }

  void _switchType(TxnType type) {
    if (type == _type) return;
    final from = _type;
    setState(() {
      _type = type;
      _category = null;
      _activeRect = null;
    });
    widget.logSession.addEvent(
      ScanLogEvent(
        type: ScanLogEventType.edit,
        field: 'type',
        fromValue: from.name,
        toValue: type.name,
        atMillis: _nowMillis(),
      ),
    );
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
    final from = _date;
    setState(() {
      _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _activeRect = widget.extraction.date.rect;
    });
    widget.logSession.addEvent(
      ScanLogEvent(
        type: ScanLogEventType.edit,
        field: 'date',
        fromValue: from.toIso8601String(),
        toValue: _date.toIso8601String(),
        atMillis: _nowMillis(),
      ),
    );
    await _refreshDuplicate();
  }

  Future<void> _pickCategory() async {
    final picked = await Navigator.of(context).push<Category>(
      MaterialPageRoute<Category>(
        builder: (_) => CategoryPickerScreen(
          type: _type == TxnType.income ? CategoryType.income : CategoryType.expense,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final from = _category;
    setState(() => _category = picked);
    widget.logSession.addEvent(
      ScanLogEvent(
        type: ScanLogEventType.edit,
        field: 'category',
        fromValue: from?.name,
        toValue: picked.name,
        atMillis: _nowMillis(),
      ),
    );
  }

  Future<void> _pickWallet() async {
    if (_wallets.length <= 1) return;
    final picked = await showModalBottomSheet<Wallet>(
      context: context,
      builder: (_) => _WalletSheet(wallets: _wallets),
    );
    if (picked != null && mounted) setState(() => _wallet = picked);
  }

  void _openOriginal() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptViewer(
          imagePath: widget.imagePath,
          highlight: _activeRect,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final wallet = _wallet;
    if (_amount <= 0) return;
    if (wallet == null) {
      _snack('Vui lòng chọn ví trước khi lưu.'.tr);
      return;
    }
    setState(() => _saving = true);
    try {
      // Ảnh chỉ được ghi vào kho ở **nhánh lưu** (FR-036) — huỷ giữa luồng
      // không để lại file nào.
      final bytes = await (widget.readBytes ?? _readFile)(widget.imagePath);
      final savedPath = await _imageStore.save(bytes);
      await _repository.addScannedTransaction(
        walletId: wallet.id,
        type: _type,
        amount: _amount,
        date: _date,
        receiptImage: savedPath,
        engine: widget.extraction.engine,
        rawText: widget.rawText,
        parsedJson: jsonEncode(_finalExtraction().toJson()),
        category: _category,
        note: _merchantCtrl.text.trim(),
        createdAt: widget.now ?? DateTime.now(),
      );
      // Thông báo đẩy (PBI 31): fire-and-forget — lỗi nuốt bên trong engine.
      unawaited(ensureNotificationEngine().onTransactionSaved(at: _date, type: _type));
      _logSave();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Không lưu được giao dịch. Vui lòng thử lại.'.tr);
    }
  }

  /// Kết quả trích xuất sau khi người dùng sửa — nguồn của `parsed_json`.
  ScanExtraction _finalExtraction() => ScanExtraction(
    type: _type,
    amount: ScanField(value: _amount, confidence: widget.extraction.amount.confidence),
    date: ScanField(value: _date, confidence: widget.extraction.date.confidence),
    merchant: ScanField(
      value: _merchantCtrl.text.trim(),
      confidence: widget.extraction.merchant.confidence,
    ),
    category: ScanField(value: _category, confidence: widget.extraction.category.confidence),
    engine: widget.extraction.engine,
  );

  /// Ghi diff trường "cửa hàng/ghi chú" (không có callback đổi rời rạc như
  /// các trường khác — diff tại thời điểm lưu, research.md Quyết định 4 ngoại
  /// lệ cho trường text tự do) + sự kiện `save`, rồi kết thúc phiên nhật ký.
  void _logSave() {
    final originalMerchant = widget.extraction.merchant.value ?? '';
    final finalMerchant = _merchantCtrl.text.trim();
    if (finalMerchant != originalMerchant) {
      widget.logSession.addEvent(
        ScanLogEvent(
          type: ScanLogEventType.edit,
          field: 'merchant',
          fromValue: originalMerchant,
          toValue: finalMerchant,
          atMillis: _nowMillis(),
        ),
      );
    }
    widget.logSession.addEvent(
      ScanLogEvent(type: ScanLogEventType.save, atMillis: _nowMillis()),
    );
    _saved = true;
    unawaited(
      widget.logSession.finish(
        outcome: ScanLogOutcome.saved,
        finalValuesJson: jsonEncode({
          'type': _type.name,
          'amount': _amount,
          'date': _date.toIso8601String(),
          'categoryId': _category?.id,
          'categoryName': _category?.name,
          'merchant': finalMerchant,
          'walletId': _wallet?.id,
        }),
      ),
    );
  }

  static Future<Uint8List> _readFile(String path) => File(path).readAsBytes();

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.coral),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final saveBar = SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('scan-save'),
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
              onPressed: _canSave ? _save : null,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Lưu giao dịch'.tr),
              ),
            ),
          ),
        ),
      );
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop || _saved) return;
        widget.logSession.addEvent(
          ScanLogEvent(type: ScanLogEventType.back, atMillis: _nowMillis()),
        );
        unawaited(widget.logSession.finish(outcome: ScanLogOutcome.cancelled));
      },
      child: SubPageScaffold(
        title: 'Xác nhận hóa đơn'.tr,
        bottomNavigationBar: saveBar,
        child: Column(
          key: const ValueKey('scan-confirm-screen'),
          children: [
            Expanded(child: _body(colors)),
            AmountKeypad(onDigit: _appendDigit, onBackspace: _backspace),
          ],
        ),
      ),
    );
  }

  Widget _body(SoraColors colors) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      children: [
        SizedBox(
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ReceiptViewer(
              imagePath: widget.imagePath,
              highlight: _activeRect,
              showAppBar: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('scan-view-original'),
            onPressed: _openOriginal,
            child: Text('Xem ảnh gốc'.tr),
          ),
        ),
        Text(
          'Chạm vào 1 trường bên dưới để khoanh vùng đối chiếu trên ảnh'.tr,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),

        // 1. Loại giao dịch
        _label('LOẠI GIAO DỊCH'.tr, colors),
        _typeSegmented(colors),
        if (widget.extraction.typeNeedsReview) _typeReviewHint(colors),
        const SizedBox(height: 12),

        // 2. Số tiền
        _label('SỐ TIỀN'.tr, colors),
        InkWell(
          key: const ValueKey('scan-amount-field'),
          onTap: () => setState(() => _activeRect = widget.extraction.amount.rect),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatMoney(_amount),
                key: const ValueKey('scan-amount-text'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _confidenceChip(widget.extraction.amount, colors, key: 'scan-confidence-amount'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Ngày giờ
        _fieldRow(
          key: const ValueKey('scan-date-field'),
          label: 'NGÀY GIỜ'.tr,
          value: formatDateTimeDetailLabel(_date),
          confidence: widget.extraction.date,
          onTap: _pickDateTime,
          colors: colors,
        ),

        // 4. Cửa hàng / Ghi chú
        _label('CỬA HÀNG / GHI CHÚ'.tr, colors),
        TextField(
          key: const ValueKey('scan-merchant-field'),
          controller: _merchantCtrl,
          onTap: () => setState(() => _activeRect = widget.extraction.merchant.rect),
          style: TextStyle(fontSize: 15, color: colors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Tên cửa hàng'.tr,
            hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ),
        _confidenceChip(widget.extraction.merchant, colors, key: 'scan-confidence-merchant'),
        const SizedBox(height: 12),

        // 5. Danh mục gợi ý
        _fieldRow(
          key: const ValueKey('scan-category-field'),
          label: 'DANH MỤC GỢI Ý'.tr,
          value: _category?.name.tr,
          hint: 'Chọn danh mục'.tr,
          confidence: ScanField<Category>(
            value: _category,
            confidence: widget.extraction.category.confidence,
          ),
          onTap: _pickCategory,
          colors: colors,
        ),

        // 6. Ví áp dụng
        _fieldRow(
          key: const ValueKey('scan-wallet-field'),
          label: 'VÍ ÁP DỤNG'.tr,
          value: _wallet?.name ?? (_loadingWallets ? 'Đang tải...'.tr : null),
          hint: 'Chọn ví'.tr,
          confidence: ScanField<String>(
            value: _wallet?.name,
            confidence: _wallet == null ? FieldConfidence.low : FieldConfidence.high,
          ),
          onTap: _pickWallet,
          colors: colors,
        ),
        if (!_loadingWallets && _wallets.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Chưa có ví hoạt động — hãy tạo ví trong Quản lý ví.'.tr,
              style: TextStyle(color: colors.coralOnNeutral, fontSize: 12),
            ),
          ),

        if (_duplicate != null) _duplicateBanner(colors),

        const SizedBox(height: 12),
        Text(
          'Nguồn: Quét hóa đơn (AI) • xử lý hoàn toàn trên máy'.tr,
          key: const ValueKey('scan-source-note'),
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _label(String text, SoraColors colors) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        color: colors.listLabel,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _typeSegmented(SoraColors colors) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.softCardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _typeSegment('Chi tiêu'.tr, TxnType.expense, 'scan-type-expense', colors),
          _typeSegment('Thu nhập'.tr, TxnType.income, 'scan-type-income', colors),
        ],
      ),
    );
  }

  Widget _typeSegment(
    String label,
    TxnType type,
    String key,
    SoraColors colors,
  ) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        key: ValueKey(key),
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

  /// Nhắc kiểm tra lại loại GD (PBI 36, R8) — bộ luật/AI không đủ căn cứ suy
  /// thu/chi; tái dùng đúng style/màu của [_confidenceChip].
  Widget _typeReviewHint(SoraColors colors) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      'Kiểm tra lại'.tr,
      key: const ValueKey('scan-type-review-hint'),
      style: TextStyle(
        color: colors.coralOnNeutral,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _fieldRow({
    required Key key,
    required String label,
    String? value,
    String? hint,
    required ScanField<dynamic> confidence,
    required VoidCallback onTap,
    required SoraColors colors,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(label, colors),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: value != null ? colors.textPrimary : colors.tabInactive,
                      fontSize: 15,
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.tabInactive, size: 20),
              ],
            ),
            _confidenceChip(confidence, colors),
          ],
        ),
      ),
    );
  }

  /// Chỉ báo độ tin cậy (FR-026): cao → teal, trung bình → xám, thấp/rỗng →
  /// **coral + "Kiểm tra lại"** (đúng ngữ nghĩa cảnh báo của design system).
  Widget _confidenceChip(
    ScanField<dynamic> field,
    SoraColors colors, {
    String? key,
  }) {
    final review = field.needsReview;
    final text = review
        ? 'Kiểm tra lại'.tr
        : field.confidence == FieldConfidence.medium
        ? 'Độ tin cậy trung bình'.tr
        : 'Độ tin cậy cao'.tr;
    final color = review
        ? colors.coralOnNeutral
        : field.confidence == FieldConfidence.medium
        ? colors.textSecondary
        : colors.tealOnNeutral;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        key: key == null ? null : ValueKey(key),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _duplicateBanner(SoraColors colors) {
    return Container(
      key: const ValueKey('scan-duplicate-banner'),
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.coralLightBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Có thể trùng với giao dịch đã nhập. Bạn vẫn có thể lưu.'.tr,
        style: TextStyle(color: colors.coralOnNeutral, fontSize: 13),
      ),
    );
  }
}

/// Bottom sheet chọn ví hoạt động (bám màn thêm giao dịch).
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
          for (final w in wallets)
            InkWell(
              onTap: () => Navigator.of(context).pop(w),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.listDivider)),
                ),
                child: Row(
                  children: [
                    Text(w.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        formatMoney(w.balance),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
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
