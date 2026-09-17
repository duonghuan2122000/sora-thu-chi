import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/date_label.dart';
import '../core/scan/scan_log.dart';
import '../core/scan/scan_log_export.dart';
import '../core/scan/scan_log_store.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/scan_deps.dart';
import '../theme/sora_colors.dart';
import 'scan_log_detail_screen.dart';

/// Màn "Nhật ký trích xuất AI" (spec PBI 47, kịch bản 3/4/5/6) — danh sách mọi
/// phiên quét hóa đơn AI đã kết thúc, mới nhất trước; chạm 1 dòng mở chi tiết.
class ScanLogListScreen extends StatefulWidget {
  const ScanLogListScreen({super.key, this.store, this.share});

  /// Seam test: mặc định `ensureScanLogStore()`.
  final ScanLogStore? store;

  /// Seam test cho bảng chia sẻ hệ thống (FR-010).
  final ShareScanLogExport? share;

  @override
  State<ScanLogListScreen> createState() => _ScanLogListScreenState();
}

class _ScanLogListScreenState extends State<ScanLogListScreen> {
  late final ScanLogStore _store = widget.store ?? ensureScanLogStore();
  List<ScanExtractionLog> _logs = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logs = await _store.loadAll();
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _confirmDeleteAll() async {
    final colors = SoraColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa toàn bộ nhật ký?'.tr),
        content: Text(
          'Toàn bộ bản ghi và ảnh đính kèm sẽ bị xóa vĩnh viễn.'.tr,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Hủy'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Xóa tất cả'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _store.deleteAll();
    await _load();
  }

  Future<void> _export() => exportScanLogs(_store, share: widget.share);

  Future<void> _openDetail(ScanExtractionLog log) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ScanLogDetailScreen(log: log, store: _store)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: 'Nhật ký trích xuất AI'.tr,
      actions: [
        if (_logs.isNotEmpty) ...[
          IconButton(
            key: const ValueKey('scan-log-export'),
            icon: const Icon(Icons.ios_share),
            onPressed: _export,
          ),
          IconButton(
            key: const ValueKey('scan-log-delete-all'),
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDeleteAll,
          ),
        ],
      ],
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final colors = SoraColors.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_logs.isEmpty) {
      return Center(
        key: const ValueKey('scan-log-empty'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Chưa có nhật ký trích xuất AI nào — quét hóa đơn một lần để bắt đầu.'
                .tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _logs.length,
      separatorBuilder: (_, _) => Divider(color: colors.listDivider, height: 1),
      itemBuilder: (context, index) => _row(context, _logs[index]),
    );
  }

  Widget _row(BuildContext context, ScanExtractionLog log) {
    final colors = SoraColors.of(context);
    return ListTile(
      key: ValueKey('scan-log-row-${log.id}'),
      onTap: () => _openDetail(log),
      leading: _outcomeIcon(log.outcome, colors),
      title: Text(formatDateTimeLabel(log.createdAt)),
      subtitle: Text(_outcomeLabel(log.outcome), style: TextStyle(color: colors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: colors.tabInactive),
    );
  }

  Widget _outcomeIcon(ScanLogOutcome outcome, SoraColors colors) {
    final (icon, color) = switch (outcome) {
      ScanLogOutcome.saved => (Icons.check_circle, colors.tealOnNeutral),
      ScanLogOutcome.cancelled => (Icons.undo, colors.tabInactive),
      ScanLogOutcome.error => (Icons.error_outline, colors.coralOnNeutral),
    };
    return Icon(icon, color: color);
  }

  String _outcomeLabel(ScanLogOutcome outcome) => switch (outcome) {
    ScanLogOutcome.saved => 'Đã lưu giao dịch'.tr,
    ScanLogOutcome.cancelled => 'Đã hủy'.tr,
    ScanLogOutcome.error => 'Lỗi trích xuất'.tr,
  };
}
