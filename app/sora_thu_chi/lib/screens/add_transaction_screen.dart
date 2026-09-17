import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../core/category/category.dart';
import '../core/date_label.dart';
import '../core/money_format.dart';
import '../core/scan/scan_image_store.dart';
import '../core/transaction/add_form.dart';
import '../core/transaction/transaction.dart';
import '../core/transaction/transaction_detail.dart' show joinTags, parseTags;
import '../core/wallet/wallet.dart';
import '../core/wallet/wallet_rules.dart';
import '../data/notification_deps.dart';
import '../data/wallet_deps.dart';
import '../data/wallet_repository.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'category_picker_screen.dart';
import 'tag_picker_screen.dart';
import 'wallet_transfer_screen.dart';

/// Seam chọn ảnh (camera hệ thống hoặc thư viện) — test bơm fake không cần
/// plugin thật (PBI 38, R). Impl thật: `ImagePicker().pickImage(source: ...)`.
typedef ReceiptImagePicker = Future<XFile?> Function(ImageSource source);

/// Chuỗi rỗng (giá trị mặc định cột `receipt_image`/`tags` khi không có) → coi
/// như chưa đính kèm (PBI 39, chế độ sửa nạp từ [Transaction] domain).
String? _emptyToNull(String? s) => (s == null || s.isEmpty) ? null : s;

/// Màn "Thêm/Sửa giao dịch" (mockup `02-them-giao-dich-v2`, PBI 38 + chế độ
/// sửa PBI 39) — ghi khoản thu/chi mới **hoặc** sửa khoản đã có (qua
/// [editing]), màn toàn màn hình (app bar teal: X đóng / check lưu, **không**
/// bottom nav). Segmented Chi|Thu|Chuyển khoản (mặc định Chi, khóa mục
/// "Chuyển khoản" khi [editing] != null — R4); số tiền gõ bằng bàn phím số
/// của hệ thống; 6 trường Danh mục/Ví/Ngày giờ/Tag/Ảnh hóa đơn/Ghi chú; nút
/// "Lưu giao dịch" cố định. Điểm vào chế độ sửa: nút "Sửa" ở
/// `transaction_detail_screen.dart`. Stateful + [WalletRepository] inject
/// (không GetX — màn tác vụ một-lần, R11).
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.repository,
    this.initialType = TxnType.expense,
    this.pickImage,
    this.imageStore,
    this.editing,
    this.initialCategory,
    this.initialWallet,
  });

  /// Seam test: mặc định null → [ensureWalletRepository] khi vào (R11).
  final WalletRepository? repository;

  /// Loại mở sẵn (PBI 24 R14) — `transfer` thì màn tự mở luồng chuyển khoản sau
  /// khi nạp ví xong. Mặc định `expense` = hành vi cũ. Bỏ qua khi [editing] != null.
  final TxnType initialType;

  /// Seam test đính kèm Ảnh hóa đơn (PBI 38) — mặc định `ImagePicker().pickImage`.
  final ReceiptImagePicker? pickImage;

  /// Seam test nơi lưu file ảnh hóa đơn — mặc định [LocalScanImageStore] (tái
  /// dùng đúng seam của luồng quét OCR, `<appDocuments>/receipts/`).
  final ScanImageStore? imageStore;

  /// Giao dịch Thu/Chi gốc đang sửa (PBI 39) — `null` = chế độ Thêm mới (hành
  /// vi cũ). Khác `null` → màn nạp sẵn toàn bộ trường, đổi tiêu đề "Sửa giao
  /// dịch", khóa tab "Chuyển khoản" (R4), `_save()` gọi `updateTransaction`.
  final Transaction? editing;

  /// Danh mục gốc của [editing] — truyền kèm vì [Transaction] chỉ giữ
  /// `categoryId`/tên snapshot, không đủ dựng lại đối tượng [Category] cho picker.
  final Category? initialCategory;

  /// Ví gốc của [editing] — tương tự [initialCategory].
  final Wallet? initialWallet;

  /// Đang ở chế độ sửa — tiện dùng ở nhiều nơi trong state.
  bool get isEditing => editing != null;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late final WalletRepository _repository;
  late final ReceiptImagePicker _pickImage =
      widget.pickImage ?? ((source) => ImagePicker().pickImage(source: source));
  late final ScanImageStore _imageStore = widget.imageStore ?? LocalScanImageStore();
  late final DateTime _openedAt = DateTime.now();

  Transaction? get _editing => widget.editing;

  late TxnType _type = _editing?.type ?? widget.initialType;
  late final TextEditingController _amountCtrl = TextEditingController(
    text: _editing == null ? '' : formatAmount(_editing!.amount.abs()),
  );
  int get _amount => parseAmount(_amountCtrl.text);
  late Category? _category = widget.initialCategory;
  late Wallet? _wallet = widget.initialWallet;
  late DateTime _date = _editing?.date ?? DateTime.now();
  late final TextEditingController _noteCtrl = TextEditingController(
    text: _editing?.note ?? '',
  );
  late List<String> _tags = parseTags(_editing?.tags ?? '');

  /// Baseline tag gốc (chế độ sửa) — so sánh nội dung (không chỉ có/không) để
  /// phát hiện đổi tag dù vẫn còn ít nhất 1 tag trước/sau (FR-006). Tính thẳng
  /// từ [_editing] (không đọc lại `_tags`) — `late` chỉ khởi tạo ở lần đọc đầu
  /// tiên, mà lúc đó `_tags` có thể đã bị đổi (test (q) từng lộ bug này).
  late final List<String> _initialTags = parseTags(_editing?.tags ?? '');

  /// Đường dẫn ảnh hóa đơn hiện tại — `null` = chưa đính kèm. Ở chế độ sửa,
  /// khởi tạo bằng ảnh đã có sẵn của giao dịch gốc (đã lưu, **không** phải
  /// file chờ commit — không được xóa khi hủy nếu chưa đổi, khác
  /// [_originalReceiptImage]). Nếu rời màn không lưu và đã đổi sang ảnh khác,
  /// chỉ ảnh mới (chưa gắn giao dịch) bị xóa (không để rác, bám R12 của luồng
  /// quét OCR) — ảnh gốc của giao dịch đang sửa giữ nguyên.
  late String? _receiptImagePath = _emptyToNull(widget.editing?.receiptImage);

  /// Ảnh gốc đã gắn sẵn với giao dịch đang sửa (`null` ở chế độ Thêm mới) —
  /// mốc để phân biệt "ảnh đã lưu từ trước" với "ảnh vừa chọn trong phiên sửa
  /// này, chưa lưu". Tính thẳng từ [widget.editing] (không đọc lại
  /// `_receiptImagePath` — cùng bẫy `late` lười khởi tạo như [_initialTags]).
  late final String? _originalReceiptImage = _emptyToNull(
    widget.editing?.receiptImage,
  );

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
    // So sánh nội dung (không chỉ có/không) — đúng cho cả chế độ Thêm (baseline
    // rỗng) lẫn Sửa (baseline = dữ liệu gốc, PBI 39 R5).
    hasTags: joinTags(_tags) != joinTags(_initialTags),
    hasReceiptImage: _receiptImagePath != _originalReceiptImage,
    initialAmount: _editing == null ? 0 : _editing!.amount.abs(),
    initialCategory: widget.initialCategory,
    initialNote: _editing?.note ?? '',
    initialDate: _editing?.date,
    initialType: _editing?.type ?? TxnType.expense,
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
    _amountCtrl.dispose();
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
      // Chế độ sửa (PBI 39) giữ nguyên ví gốc đã seed từ constructor thay vì
      // ghi đè bằng ví mặc định.
      final preselect = widget.isEditing
          ? _wallet
          : currentActiveDefault(active) ?? firstActive(active);
      setState(() {
        _activeWallets = active;
        _wallet = preselect;
        _loading = false;
      });
      // Vào từ sheet với lựa chọn "Chuyển khoản" → mở luồng chuyển ngay, đúng
      // một lần (R14); bỏ qua hỏi "bỏ dữ liệu" vì form còn trống. Không áp dụng
      // ở chế độ sửa (R4).
      if (!widget.isEditing &&
          widget.initialType == TxnType.transfer &&
          !_autoTransferOpened) {
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

  /// Tự format lại ô Số tiền khi gõ (bàn phím hệ thống) — bám đúng mẫu
  /// `wallet_transfer_screen.dart`: lọc còn chữ số, format dấu chấm nghìn,
  /// giữ con trỏ ở cuối. Không giới hạn số chữ số riêng — `LengthLimitingTextInputFormatter`
  /// ở `TextField` đã chặn tràn.
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
    if (_missing.contains('amount')) setState(() => _missing.remove('amount'));
    setState(() {});
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

  /// Chạm dòng Tag — mở màn chọn tag riêng (mockup v2, PBI 38, chốt 2B).
  Future<void> _pickTags() async {
    final picked = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => TagPickerScreen(initialSelected: _tags),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _tags = picked);
    }
  }

  /// Chạm dòng Ảnh hóa đơn — chọn nguồn rồi lưu vào kho `receipts/` (PBI 38,
  /// FR-007/FR-008). Ảnh cũ (nếu có) bị xóa trước khi thay bằng ảnh mới — trừ
  /// [_originalReceiptImage] (PBI 39): ảnh gốc của giao dịch đang sửa vẫn
  /// đang được tham chiếu (còn lưu ở DB) cho tới khi bấm Lưu, không được xóa.
  Future<void> _pickReceiptImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => const _ReceiptImageSourceSheet(),
    );
    if (source == null || !mounted) return;
    final file = await _pickImage(source);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    final path = await _imageStore.save(bytes);
    final old = _receiptImagePath;
    if (!mounted) return;
    setState(() => _receiptImagePath = path);
    if (old != null && old != _originalReceiptImage) {
      unawaited(_imageStore.delete(old));
    }
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
      final editing = _editing;
      if (editing != null) {
        await _repository.updateTransaction(
          original: editing,
          walletId: _wallet!.id,
          type: _type,
          amount: _amount,
          category: _category!,
          date: _date,
          note: _noteCtrl.text.trim(),
          tags: joinTags(_tags),
          receiptImage: _receiptImagePath ?? '',
        );
      } else {
        await _repository.addTransaction(
          walletId: _wallet!.id,
          type: _type,
          amount: _amount,
          category: _category!,
          date: _date,
          note: _noteCtrl.text.trim(),
          tags: joinTags(_tags),
          receiptImage: _receiptImagePath ?? '',
        );
      }
      // Ảnh đã gắn vào giao dịch — bỏ theo dõi để `_requestClose`/dispose
      // không xóa nhầm nếu có gọi lại sau khi pop (an toàn, không nên xảy ra).
      _receiptImagePath = null;
      // Thông báo đẩy (PBI 31): huỷ mốc nhắc hôm nay nếu cờ "chỉ nhắc nếu chưa
      // ghi" đang bật + xét ngưỡng ngân sách. **Fire-and-forget** — không await,
      // lỗi nuốt bên trong engine (FR-024/SC-012): luồng lưu không đổi.
      unawaited(
        ensureNotificationEngine().onTransactionSaved(at: _date, type: _type),
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
  /// Rời màn mà chưa lưu → xóa ảnh hóa đơn đã copy vào `receipts/` (nếu có),
  /// tránh để rác file (PBI 38, bám R12 của luồng quét OCR).
  Future<void> _requestClose() async {
    if (_saving) return;
    if (!_isDirty) {
      _discardPendingReceiptImage();
      Navigator.of(context).pop();
      return;
    }
    final leave = await _confirmDiscard();
    if (leave == true && mounted) {
      _discardPendingReceiptImage();
      Navigator.of(context).pop();
    }
  }

  void _discardPendingReceiptImage() {
    final path = _receiptImagePath;
    // Ảnh gốc của giao dịch đang sửa (chưa đổi) không phải file chờ commit —
    // không xóa (PBI 39).
    if (path != null && path != _originalReceiptImage) {
      _receiptImagePath = null;
      unawaited(_imageStore.delete(path));
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
          title: Text((widget.isEditing ? 'Sửa giao dịch' : 'Thêm giao dịch').tr),
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
        body: _scrollableBody(colors),
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
          _fieldRow(
            key: const ValueKey('field-tags'),
            icon: Icons.sell_outlined,
            label: 'Tag'.tr,
            value: _tags.isEmpty ? null : _tags.join(', '),
            hint: 'Thêm tag (tùy chọn)'.tr,
            onTap: _pickTags,
            colors: colors,
          ),
          _receiptImageRow(colors),
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

  /// Ở chế độ sửa (PBI 39 R4), khóa mục này — sửa giao dịch Thu/Chi không đổi
  /// được sang Chuyển khoản (khác cấu trúc lưu trữ 1 dòng ↔ 2 dòng liên kết).
  Widget _transferSegment(SoraColors colors) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.isEditing ? null : _openTransferFlow,
        child: Container(
          alignment: Alignment.center,
          child: Text(
            'Chuyển khoản'.tr,
            style: TextStyle(
              color: widget.isEditing
                  ? colors.listLabel.withValues(alpha: 0.4)
                  : colors.listLabel,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  /// Ô Số tiền (mockup `02-them-giao-dich-v2`, PBI 38 R): bàn phím số của
  /// **hệ thống** thay numpad tự vẽ — bám đúng mẫu `wallet_transfer_screen.dart`
  /// (`_onAmountChanged` format lại khi gõ). Viền màu theo ngữ cảnh loại giao
  /// dịch (Thu teal / Chi coral), như quy tắc `_amountAccent` cũ.
  Widget _amountSection(SoraColors colors) {
    final accent = _amountAccent(colors);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SỐ TIỀN'.tr,
          style: TextStyle(
            color: colors.tabInactive,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const ValueKey('amount-field'),
          controller: _amountCtrl,
          onChanged: _onAmountChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: '0',
            suffixText: 'đ',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Dòng "Ảnh hóa đơn" (mockup v2, PBI 38) — thumbnail thay icon khi đã đính
  /// kèm; chạm mở action sheet chọn "Chụp ảnh"/"Chọn từ thư viện" (FR-007/008).
  Widget _receiptImageRow(SoraColors colors) {
    final path = _receiptImagePath;
    return Column(
      children: [
        InkWell(
          key: const ValueKey('field-receipt-image'),
          onTap: _pickReceiptImage,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: path == null
                      ? Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.tealLightBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            color: colors.tealOnNeutral,
                            size: 15,
                          ),
                        )
                      : Image.file(
                          File(path),
                          key: const ValueKey('receipt-image-thumbnail'),
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ảnh hóa đơn'.tr,
                        style: TextStyle(
                          color: colors.listLabel,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        path == null ? 'Đính kèm ảnh (tùy chọn)'.tr : 'Đã đính kèm'.tr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: path != null ? colors.textPrimary : colors.tabInactive,
                          fontSize: 14,
                          fontWeight: path != null ? FontWeight.w500 : FontWeight.w400,
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
                  minLines: 3,
                  maxLines: 6,
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

/// Bottom sheet chọn nguồn ảnh hóa đơn — "Chụp ảnh" (camera hệ thống) hoặc
/// "Chọn từ thư viện" (PBI 38).
class _ReceiptImageSourceSheet extends StatelessWidget {
  const _ReceiptImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            key: const ValueKey('receipt-source-camera'),
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text('Chụp ảnh'.tr),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            key: const ValueKey('receipt-source-gallery'),
            leading: const Icon(Icons.photo_library_outlined),
            title: Text('Chọn từ thư viện'.tr),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
