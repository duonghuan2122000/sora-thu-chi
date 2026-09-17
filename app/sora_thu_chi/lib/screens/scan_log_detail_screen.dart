import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/date_label.dart';
import '../core/scan/scan_log.dart';
import '../core/scan/scan_log_store.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../theme/sora_colors.dart';

/// Chi tiết 1 bản ghi nhật ký trích xuất AI (spec PBI 47, kịch bản 3) — ảnh
/// gốc, OCR thô, kết quả AI đề xuất ban đầu, giá trị cuối đã lưu (nếu có), và
/// timeline sự kiện đúng thứ tự thời gian.
class ScanLogDetailScreen extends StatelessWidget {
  const ScanLogDetailScreen({super.key, required this.log, required this.store});

  final ScanExtractionLog log;
  final ScanLogStore store;

  Future<void> _delete(BuildContext context) async {
    final colors = SoraColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa bản ghi này?'.tr),
        content: Text(
          'Ảnh và dữ liệu của phiên quét này sẽ bị xóa vĩnh viễn.'.tr,
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Hủy'.tr)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Xóa'.tr)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await store.deleteOne(log.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final extraction = log.extractionJson == null
        ? null
        : jsonDecode(log.extractionJson!) as Map<String, dynamic>;
    final finalValues = log.finalValuesJson == null
        ? null
        : jsonDecode(log.finalValuesJson!) as Map<String, dynamic>;
    final events = log.events;

    return SubPageScaffold(
      title: 'Chi tiết nhật ký'.tr,
      actions: [
        IconButton(
          key: const ValueKey('scan-log-delete-one'),
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(context),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _outcomeBadge(colors),
          const SizedBox(height: 12),
          Text(formatDateTimeLabel(log.createdAt), style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 16),
          if (log.imagePath != null) _image(colors),
          if (log.errorMessage != null) ...[
            const SizedBox(height: 16),
            _section('LỖI'.tr, colors),
            Text(log.errorMessage!, style: TextStyle(color: colors.coralOnNeutral)),
          ],
          const SizedBox(height: 16),
          _section('AI ĐỀ XUẤT BAN ĐẦU'.tr, colors),
          if (extraction == null)
            Text('Không có dữ liệu.'.tr, style: TextStyle(color: colors.textSecondary))
          else
            _jsonMap(extraction, colors),
          const SizedBox(height: 16),
          _section('GIÁ TRỊ CUỐI ĐÃ LƯU'.tr, colors),
          if (finalValues == null)
            Text('Phiên chưa lưu giao dịch.'.tr, style: TextStyle(color: colors.textSecondary))
          else
            _jsonMap(finalValues, colors),
          const SizedBox(height: 16),
          _section('VĂN BẢN OCR'.tr, colors),
          Text(
            log.rawText?.isEmpty ?? true ? '(rỗng)'.tr : log.rawText!,
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _section('CHUỖI THAO TÁC'.tr, colors),
          if (events.isEmpty)
            Text('Không có thao tác nào.'.tr, style: TextStyle(color: colors.textSecondary))
          else
            for (final e in events) _eventRow(e, colors),
        ],
      ),
    );
  }

  Widget _outcomeBadge(SoraColors colors) {
    final (label, color) = switch (log.outcome) {
      ScanLogOutcome.saved => ('Đã lưu giao dịch'.tr, colors.tealOnNeutral),
      ScanLogOutcome.cancelled => ('Đã hủy'.tr, colors.tabInactive),
      ScanLogOutcome.error => ('Lỗi trích xuất'.tr, colors.coralOnNeutral),
    };
    return Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16));
  }

  Widget _image(SoraColors colors) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.file(
      File(log.imagePath!),
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: 200,
        color: colors.softCardBg,
        alignment: Alignment.center,
        child: Icon(Icons.receipt_long_outlined, color: colors.tabInactive, size: 40),
      ),
    ),
  );

  Widget _section(String text, SoraColors colors) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(color: colors.listLabel, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );

  Widget _jsonMap(Map<String, dynamic> map, SoraColors colors) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final entry in map.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
          ),
        ),
    ],
  );

  Widget _eventRow(ScanLogEvent e, SoraColors colors) {
    final label = switch (e.type) {
      ScanLogEventType.edit => '${'Sửa'.tr} ${e.field}: ${e.fromValue} → ${e.toValue}',
      ScanLogEventType.back => 'Quay lại / thoát'.tr,
      ScanLogEventType.save => 'Lưu giao dịch'.tr,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(label, style: TextStyle(color: colors.textPrimary, fontSize: 13)),
    );
  }
}
