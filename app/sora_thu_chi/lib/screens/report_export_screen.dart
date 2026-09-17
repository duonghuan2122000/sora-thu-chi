import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/category/category.dart';
import '../core/report/export_share.dart';
import '../core/report/report_export.dart';
import '../core/report/report_export_writers.dart';
import '../core/report/report_file_save.dart';
import '../core/report/report_view.dart';
import '../core/transaction/transaction.dart';
import '../core/wallet/wallet.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/report_deps.dart';
import '../data/wallet_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Màn **Xuất báo cáo** (mockup `04`, PBI 27) — màn con đè shell: app bar teal
/// + nút back, **không** bottom nav/FAB. Mở từ biểu tượng xuất trên vùng tiêu
/// đề màn Tổng quan (FR-001/FR-002).
///
/// Đọc dữ liệu **một lần** khi mở (`initState`) rồi giữ bản chụp trong state —
/// đổi bộ lọc không đọc lại kho (FR-026). Khoảng mặc định **kế thừa đúng kỳ**
/// đang xem của màn Tổng quan (FR-003). Bộ lọc/định dạng chỉ sống trong phiên
/// mở màn (FR-027).
class ReportExportScreen extends StatefulWidget {
  const ReportExportScreen({super.key, this.save, this.share});

  /// Seam lưu file (PBI 41) — test bơm bản giả; mặc định ghi ra Downloads
  /// công khai qua kênh native.
  final SaveReportFile? save;

  /// Seam chia sẻ (R12) — test bơm bản giả; mặc định dùng bảng chia sẻ hệ thống.
  final ShareExport? share;

  @override
  State<ReportExportScreen> createState() => _ReportExportScreenState();
}

class _ReportExportScreenState extends State<ReportExportScreen> {
  bool _loading = true;
  String? _error;
  List<Transaction> _all = const [];
  List<Wallet> _wallets = const [];
  Map<int, String> _walletNames = const {};
  List<Category> _categories = const [];

  late ReportExportFilter _filter;
  ExportFormat _format = ExportFormat.pdf;
  bool _busy = false;

  /// Font nhúng cho PDF — nạp **một lần** ở main isolate rồi truyền bytes vào
  /// `compute` (trong isolate nền `rootBundle` không dùng được — R11).
  Uint8List? _fontRegular;
  Uint8List? _fontBold;

  final TextEditingController _tagCtrl = TextEditingController();

  /// Số chip danh mục cha hiện thẳng trên hàng chip (R15) — phần vượt vào
  /// chip "+N khác".
  static const int _maxCategoryChips = 3;

  @override
  void initState() {
    super.initState();
    final controller = ensureReportController();
    _filter = ReportExportFilter.fromRange(
      reportPeriodRange(controller.period.value, controller.now),
    );
    _load();
  }

  @override
  void dispose() {
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = ensureWalletRepository();
      final transactions = await repository.allTransactions();
      final wallets = await repository.loadAll();
      final categories = [
        ...await repository.categories(type: CategoryType.income),
        ...await repository.categories(type: CategoryType.expense),
      ];
      if (!mounted) return;
      setState(() {
        _all = transactions;
        _wallets = walletsByDisplayOrder(wallets);
        _walletNames = {for (final w in wallets) w.id: w.name};
        _categories = categories;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được dữ liệu để xuất báo cáo'.tr;
        _loading = false;
      });
    }
  }

  ReportExportData get _data => buildReportExport(
    transactions: _all,
    categories: _categories,
    walletNames: _walletNames,
    filter: _filter,
    format: _format,
  );

  /// Danh mục **cha đang hoạt động** (cả thu lẫn chi) theo `sortOrder` — danh
  /// mục ẩn đã bị lọc từ truy vấn nên không vào hàng chip (R15).
  List<Category> get _parentCategories =>
      _categories.where((c) => c.parentId == null).toList()
        ..sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
        });

  ReportExportFilter _withCategories(Set<int> ids) => ReportExportFilter(
    start: _filter.start,
    end: _filter.end,
    walletIds: _filter.walletIds,
    categoryIds: ids,
    tag: _filter.tag,
  );

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filter.start,
      firstDate: DateTime(2000),
      // Chặn chéo ngay ở bộ chọn ⇒ không có nhánh khoảng âm (luật 5).
      lastDate: _filter.lastDay,
    );
    if (picked == null || !mounted) return;
    setState(() => _filter = _filter.withStart(picked));
  }

  Future<void> _pickEnd() async {
    final lastAllowed = DateTime(_filter.start.year + 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: _filter.lastDay,
      firstDate: _filter.start,
      lastDate: lastAllowed,
    );
    if (picked == null || !mounted) return;
    setState(
      () => _filter = _filter.withEnd(
        DateTime(picked.year, picked.month, picked.day + 1),
      ),
    );
  }

  Future<void> _pickMoreCategories() async {
    final chosen = await showModalBottomSheet<Set<int>>(
      context: context,
      builder: (_) => _CategorySheet(
        categories: _parentCategories,
        selected: _filter.categoryIds,
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() => _filter = _withCategories(chosen));
  }

  Future<void> _loadFonts() async {
    if (_fontRegular != null) return;
    _fontRegular = await _readAsset('assets/fonts/Roboto-Regular.ttf');
    _fontBold = await _readAsset('assets/fonts/Roboto-Bold.ttf');
  }

  Future<Uint8List> _readAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<void> _export(ReportExportData data) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final format = _format;
      if (format == ExportFormat.pdf) await _loadFonts();
      final bytes = await compute(
        _buildExportBytes,
        _ExportPayload(
          data: data,
          format: format,
          fontRegular: _fontRegular,
          fontBold: _fontBold,
        ),
      );
      if (!mounted) return;
      final saved = await (widget.save ?? defaultSaveReportFile)(
        fileName: data.fileName,
        bytes: bytes,
        mimeType: format.mimeType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Đã lưu @file vào Tải xuống'.trParams({'file': saved.fileName}),
            ),
          ),
        );
      await (widget.share ?? defaultShareExport)(
        fileName: saved.fileName,
        filePath: saved.path,
        mimeType: format.mimeType,
      );
    } on ReportStoragePermissionDeniedException {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text('Cần quyền lưu trữ để lưu tệp báo cáo'.tr)),
          );
      }
    } catch (error, stack) {
      // In ra log để còn chẩn đoán trên thiết bị (SnackBar chỉ nói "không tạo
      // được tệp"); người dùng vẫn thấy thông báo dễ hiểu.
      debugPrint('Xuất báo cáo lỗi: $error\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text('Không tạo được tệp báo cáo'.tr)),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SubPageScaffold(
      title: 'Xuất báo cáo'.tr,
      child: _error != null
          ? _ErrorView(message: _error!, onRetry: _load)
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _body(_data, colors),
    );
  }

  Widget _body(ReportExportData data, SoraColors colors) {
    return ListView(
      key: const ValueKey('report-export-screen'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _SectionTitle('KHOẢNG THỜI GIAN'.tr, colors),
        _DateFields(
          start: _filter.start,
          lastDay: _filter.lastDay,
          colors: colors,
          onPickStart: _pickStart,
          onPickEnd: _pickEnd,
        ),
        const SizedBox(height: 18),
        _SectionTitle('VÍ'.tr, colors),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(
              key: const ValueKey('export-wallet-all'),
              label: 'Tất cả'.tr,
              selected: _filter.walletIds.isEmpty,
              colors: colors,
              onTap: () => setState(() => _filter = _filter.clearWallets()),
            ),
            for (final wallet in _wallets)
              _Chip(
                key: ValueKey('export-wallet-${wallet.id}'),
                label: wallet.name,
                selected: _filter.walletIds.contains(wallet.id),
                colors: colors,
                onTap: () =>
                    setState(() => _filter = _filter.toggleWallet(wallet.id)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionTitle('DANH MỤC'.tr, colors),
        _categoryChips(colors),
        const SizedBox(height: 18),
        _SectionTitle('TAG'.tr, colors),
        _tagField(colors),
        const SizedBox(height: 18),
        _SectionTitle('ĐỊNH DẠNG XUẤT'.tr, colors),
        _formatCards(colors),
        const SizedBox(height: 18),
        _SummaryBox(data: data, format: _format, colors: colors),
        if (data.isEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Bộ lọc hiện không có giao dịch nào'.tr,
            key: const ValueKey('export-empty-notice'),
            style: TextStyle(color: colors.coralOnNeutral, fontSize: 13),
          ),
        ],
        const SizedBox(height: 14),
        _PrivacyWarning(colors: colors),
        const SizedBox(height: 14),
        _exportButton(data),
      ],
    );
  }

  Widget _categoryChips(SoraColors colors) {
    final parents = _parentCategories;
    final shown = parents.take(_maxCategoryChips).toList();
    final hidden = parents.length - shown.length;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(
          key: const ValueKey('export-cat-all'),
          label: 'Tất cả'.tr,
          selected: _filter.categoryIds.isEmpty,
          colors: colors,
          onTap: () => setState(() => _filter = _filter.clearCategories()),
        ),
        for (final category in shown)
          _Chip(
            key: ValueKey('export-cat-${category.id}'),
            label: category.name.tr,
            selected: _filter.categoryIds.contains(category.id),
            colors: colors,
            onTap: () =>
                setState(() => _filter = _filter.toggleCategory(category.id)),
          ),
        if (hidden > 0)
          _Chip(
            key: const ValueKey('export-more-categories'),
            label: '+${'@count khác'.trParams({'count': '$hidden'})}',
            selected: _filter.categoryIds.any(
              (id) => !shown.any((c) => c.id == id),
            ),
            colors: colors,
            onTap: _pickMoreCategories,
          ),
      ],
    );
  }

  Widget _tagField(SoraColors colors) {
    return TextField(
      key: const ValueKey('export-tag-field'),
      controller: _tagCtrl,
      onChanged: (value) => setState(() => _filter = _filter.withTag(value)),
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: colors.softCardBg,
        hintText: 'Nhập tag để lọc (VD: #dulich)'.tr,
        hintStyle: TextStyle(color: colors.tabInactive, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _formatCards(SoraColors colors) {
    return Row(
      children: [
        for (final format in ExportFormat.values) ...[
          if (format != ExportFormat.values.first) const SizedBox(width: 8),
          Expanded(
            child: _FormatCard(
              format: format,
              selected: _format == format,
              colors: colors,
              onTap: () => setState(() => _format = format),
            ),
          ),
        ],
      ],
    );
  }

  Widget _exportButton(ReportExportData data) {
    final enabled = !data.isEmpty && !_busy;
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        key: const ValueKey('export-button'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: AppColors.white,
          elevation: 0,
          disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        onPressed: enabled ? () => _export(data) : null,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_busy ? 'Đang tạo tệp…'.tr : 'Xuất báo cáo'.tr),
        ),
      ),
    );
  }
}

/// Payload gửi sang isolate dựng bytes — **thuần dữ liệu** (không `BuildContext`,
/// không asset): asset/font đã nạp ở main isolate trước khi gọi `compute` (R11).
class _ExportPayload {
  const _ExportPayload({
    required this.data,
    required this.format,
    this.fontRegular,
    this.fontBold,
  });

  final ReportExportData data;
  final ExportFormat format;

  /// Font PDF đã nạp ở **main isolate** (`rootBundle` không dùng được trong
  /// isolate nền — R11); chỉ có ở nhánh PDF.
  final Uint8List? fontRegular;
  final Uint8List? fontBold;
}

/// Nhãn khối trong màn (chữ hoa nhỏ, màu mờ).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.colors);

  final String text;
  final SoraColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: colors.tabInactive,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Hai trường ngày `Từ ngày` / `Đến ngày` — chạm mở bộ chọn ngày có chặn chéo.
class _DateFields extends StatelessWidget {
  const _DateFields({
    required this.start,
    required this.lastDay,
    required this.colors,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime start;
  final DateTime lastDay;
  final SoraColors colors;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateField(
            fieldKey: const ValueKey('export-date-from'),
            label: 'Từ ngày'.tr,
            value: start,
            colors: colors,
            onTap: onPickStart,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DateField(
            fieldKey: const ValueKey('export-date-to'),
            label: 'Đến ngày'.tr,
            value: lastDay,
            colors: colors,
            onTap: onPickEnd,
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.colors,
    required this.onTap,
  });

  final Key fieldKey;
  final String label;
  final DateTime value;
  final SoraColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: fieldKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.softCardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: colors.tabInactive, fontSize: 10),
            ),
            const SizedBox(height: 3),
            Text(
              formatFileDate(value),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip chọn một lựa chọn lọc — đang chọn: nền teal + chữ trắng (R15).
class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final SoraColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : colors.softCardBg,
          borderRadius: BorderRadius.circular(15),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.white : colors.listLabel,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ chọn định dạng xuất — đang chọn: viền 2 px teal + dấu chọn tròn góc phải
/// trên (R17/FR-009).
class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.format,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final ExportFormat format;
  final bool selected;
  final SoraColors colors;
  final VoidCallback onTap;

  IconData get _icon => switch (format) {
    ExportFormat.pdf => Icons.picture_as_pdf_outlined,
    ExportFormat.excel => Icons.table_chart_outlined,
    ExportFormat.csv => Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('export-format-${format.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.teal : colors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? colors.tealLightBg : colors.softCardBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _icon,
                    size: 17,
                    color: selected ? colors.tealOnNeutral : colors.tabInactive,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  format.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  format.hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, fontSize: 10),
                ),
              ],
            ),
            if (selected)
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: colors.tealOnNeutral,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hộp tóm tắt — 2 dòng: số giao dịch + khoảng ngày, và định dạng đang chọn
/// (FR-010/FR-011).
class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.data,
    required this.format,
    required this.colors,
  });

  final ReportExportData data;
  final ExportFormat format;
  final SoraColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('export-summary'),
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
            '@count giao dịch • @from – @to'.trParams({
              'count': '${data.count}',
              'from': formatFileDate(data.filter.start),
              'to': formatFileDate(data.filter.lastDay),
            }),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Định dạng: @format (@hint)'.trParams({
              'format': format.label,
              'hint': format.hint,
            }),
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Dòng cảnh báo **hiển thị sẵn** trước khi bấm xuất (FR-028) — nền coral nhạt
/// + icon cảnh báo; không hộp thoại xác nhận.
class _PrivacyWarning extends StatelessWidget {
  const _PrivacyWarning({required this.colors});

  final SoraColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('export-privacy-warning'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.coralLightBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: colors.coralOnNeutral,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tệp xuất ra không còn được app bảo vệ. Hãy cẩn thận khi chia sẻ.'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet chọn nhiều danh mục cha — trả về tập id đã chọn khi bấm "Xong".
class _CategorySheet extends StatefulWidget {
  const _CategorySheet({required this.categories, required this.selected});

  final List<Category> categories;
  final Set<int> selected;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late final Set<int> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SafeArea(
      child: SizedBox(
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'Chọn danh mục'.tr,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final category in widget.categories)
                    InkWell(
                      key: ValueKey('export-cat-option-${category.id}'),
                      onTap: () => setState(() {
                        if (!_selected.add(category.id)) {
                          _selected.remove(category.id);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Icon(
                              _selected.contains(category.id)
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 20,
                              color: _selected.contains(category.id)
                                  ? colors.tealOnNeutral
                                  : colors.tabInactive,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  key: const ValueKey('export-cat-done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: Text('Xong'.tr),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhánh lỗi đọc dữ liệu — thông báo + nút thử lại (khuôn PBI 21).
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text('Thử lại'.tr)),
          ],
        ),
      ),
    );
  }
}

/// Dựng bytes theo định dạng đang chọn — **top-level** để gọi được trong
/// `compute()`. Nhận đúng dữ liệu đã đóng gói ở main isolate (R11).
Future<Uint8List> _buildExportBytes(_ExportPayload payload) async =>
    switch (payload.format) {
      ExportFormat.csv => buildCsvBytes(payload.data.rows),
      ExportFormat.excel => buildXlsxBytes(payload.data),
      ExportFormat.pdf => await buildPdfBytes(
        data: payload.data,
        fontRegular: payload.fontRegular!,
        fontBold: payload.fontBold!,
      ),
    };
