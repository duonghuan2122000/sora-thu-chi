import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/backup/backup_controller.dart';
import '../core/backup/backup_file_meta.dart';
import '../core/backup/backup_prefs.dart';
import '../core/backup/backup_reader.dart';
import '../core/backup/local_backup_store.dart';
import '../core/date_label.dart';
import '../core/money_format.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/backup_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';
import 'backup_result_screen.dart';
import 'create_backup_sheet.dart';
import 'restore_confirm_sheet.dart';

/// Mở trình chọn file hệ thống, lọc `.json`/`.zip` — trả path hoặc `null`
/// (người dùng huỷ). Kiểu hàm để test bơm giả (không cần plugin thật).
typedef PickBackupFile = Future<String?> Function();

Future<String?> _defaultPickBackupFile() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json', 'zip'],
  );
  return files.isEmpty ? null : files.single.path;
}

/// Màn "Sao lưu & Khôi phục" (mockup `01`, PBI 35) — sub-page từ Cài đặt: app
/// bar teal + nút back, không bottom nav/FAB. Gồm thẻ "Sao lưu gần nhất", nút
/// tạo backup (US1), nút chọn file khôi phục + danh sách bản sao lưu (US2),
/// khối "Tự động sao lưu" (US3).
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({
    super.key,
    this.controller,
    this.pickFile = _defaultPickBackupFile,
  });

  final BackupController? controller;
  final PickBackupFile pickFile;

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  late final BackupController _controller =
      widget.controller ?? ensureBackupController();
  String? _restoreError;

  @override
  void initState() {
    super.initState();
    _controller.load();
    // Dọn `_safety/` quá 24h mỗi lần mở màn (R10/T052).
    _controller.cleanupOldSafetySnapshots();
  }

  Future<void> _openCreateBackupSheet() async {
    final path = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateBackupSheet(controller: _controller),
    );
    if (path == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BackupResultScreen(
          mode: BackupResultMode.backup,
          filePath: path,
        ),
      ),
    );
  }

  Future<void> _startRestoreFlow(String path) async {
    setState(() => _restoreError = null);
    final BackupFileMeta meta;
    try {
      meta = await _controller.inspectBackupFile(path);
    } on BackupIncompatibleException {
      _showError('File backup từ phiên bản app mới hơn, không tương thích'.tr);
      return;
    } on BackupFormatException {
      _showError('File backup không hợp lệ hoặc đã bị hỏng'.tr);
      return;
    } catch (_) {
      _showError('Không đọc được file backup'.tr);
      return;
    }
    if (!mounted) return;
    final restored = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RestoreConfirmSheet(
        controller: _controller,
        path: path,
        meta: meta,
      ),
    );
    if (restored != true || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const BackupResultScreen(mode: BackupResultMode.restore),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _restoreError = message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickAndRestore() async {
    final path = await widget.pickFile();
    if (path == null || !mounted) return;
    await _startRestoreFlow(path);
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: 'Sao lưu & Khôi phục'.tr,
      child: Obx(() {
        if (_controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return _body(context);
      }),
    );
  }

  Widget _body(BuildContext context) {
    final colors = SoraColors.of(context);
    final prefs = _controller.prefs.value;
    return ListView(
      key: const ValueKey('backup-restore-screen'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _LastBackupCard(
          prefs: prefs,
          entries: _controller.backups,
          colors: colors,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            key: const ValueKey('backup-create-button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _openCreateBackupSheet,
            icon: const Icon(Icons.backup_outlined, size: 18),
            label: Text('Tạo bản sao lưu mới'.tr),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            key: const ValueKey('backup-pick-restore-button'),
            onPressed: _pickAndRestore,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: Text('Chọn file khôi phục'.tr),
          ),
        ),
        if (_restoreError != null) ...[
          const SizedBox(height: 8),
          Text(
            _restoreError!,
            key: const ValueKey('backup-restore-error'),
            style: TextStyle(color: colors.coralOnNeutral, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        _AutoBackupSection(controller: _controller, colors: colors),
        const SizedBox(height: 24),
        _SectionLabel('CÁC BẢN SAO LƯU'.tr, colors),
        _BackupList(
          entries: _controller.backups,
          colors: colors,
          onTap: _startRestoreFlow,
        ),
      ],
    );
  }
}

class _LastBackupCard extends StatelessWidget {
  const _LastBackupCard({
    required this.prefs,
    required this.entries,
    required this.colors,
  });

  final BackupPrefs prefs;
  final List<LocalBackupEntry> entries;
  final SoraColors colors;

  /// Chỉ hiện đường dẫn nếu bản gần nhất còn trong danh sách hiện tại và là
  /// bản tự động (research.md R2 — tra cứu chéo, không thêm cờ riêng).
  String? get _autoLastBackupPath {
    final path = prefs.lastBackupPath;
    if (path == null) return null;
    for (final entry in entries) {
      if (entry.path == path && entry.isAuto) return entry.path;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final lastAt = prefs.lastBackupAt;
    final autoPath = _autoLastBackupPath;
    return Container(
      key: const ValueKey('backup-last-card'),
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
            'Sao lưu gần nhất'.tr,
            style: TextStyle(
              color: colors.tabInactive,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (lastAt == null)
            Text(
              'Chưa từng sao lưu'.tr,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
            )
          else ...[
            Text(
              formatDateTimeLabel(lastAt),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '@wallets ví · @categories danh mục · @transactions giao dịch'
                  .trParams({
                    'wallets': '${prefs.lastBackupCounts?['wallets'] ?? 0}',
                    'categories':
                        '${prefs.lastBackupCounts?['categories'] ?? 0}',
                    'transactions':
                        '${prefs.lastBackupCounts?['transactions'] ?? 0}',
                  }),
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            if (autoPath != null) ...[
              const SizedBox(height: 2),
              Text(
                autoPath,
                key: const ValueKey('backup-last-auto-path'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.tabInactive, fontSize: 11),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _AutoBackupSection extends StatelessWidget {
  const _AutoBackupSection({required this.controller, required this.colors});

  final BackupController controller;
  final SoraColors colors;

  String _frequencyLabel(BackupFrequency f) => switch (f) {
    BackupFrequency.daily => 'Hàng ngày'.tr,
    BackupFrequency.weekly => 'Hàng tuần'.tr,
    BackupFrequency.monthly => 'Hàng tháng'.tr,
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final prefs = controller.prefs.value;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.softCardBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tự động sao lưu'.tr,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  key: const ValueKey('backup-auto-switch'),
                  value: prefs.autoEnabled,
                  onChanged: controller.setAutoEnabled,
                ),
              ],
            ),
            if (prefs.autoEnabled) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in BackupFrequency.values)
                    _FrequencyChip(
                      key: ValueKey('backup-auto-frequency-${f.name}'),
                      label: _frequencyLabel(f),
                      selected: prefs.autoFrequency == f,
                      colors: colors,
                      onTap: () => controller.setAutoFrequency(f),
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _FrequencyChip extends StatelessWidget {
  const _FrequencyChip({
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
          color: selected ? AppColors.teal : colors.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : colors.listLabel,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _BackupList extends StatelessWidget {
  const _BackupList({
    required this.entries,
    required this.colors,
    required this.onTap,
  });

  final List<LocalBackupEntry> entries;
  final SoraColors colors;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        key: const ValueKey('backup-list-empty'),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Chưa có bản sao lưu nào'.tr,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
      );
    }
    return Column(
      children: [
        for (final entry in entries)
          InkWell(
            key: ValueKey('backup-entry-${entry.path}'),
            onTap: () => onTap(entry.path),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(
                    entry.hasAttachments
                        ? Icons.folder_zip_outlined
                        : Icons.description_outlined,
                    size: 20,
                    color: colors.tabInactive,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${formatDateTimeLabel(entry.createdAt)}'
                          '${entry.isAuto ? ' · ${'Tự động'.tr}' : ''}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (entry.isAuto)
                          Text(
                            entry.path,
                            key: ValueKey('backup-entry-path-${entry.path}'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.tabInactive,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _sizeLabel(entry.sizeBytes),
                    style: TextStyle(color: colors.tabInactive, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _sizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    return '${formatAmount(bytes ~/ 1024)} KB';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.colors);

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
