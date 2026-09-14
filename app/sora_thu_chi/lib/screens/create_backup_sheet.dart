import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../core/backup/backup_controller.dart';
import '../core/backup/backup_share.dart';
import '../core/backup/backup_summary.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

Future<void> _defaultShareBackupFile(String path) =>
    SharePlus.instance.share(ShareParams(files: [XFile(path)]));

/// Bottom sheet "Tạo bản sao lưu" (mockup `02`, PBI 35, US1) — tóm tắt số
/// liệu, tuỳ chọn mật khẩu, "Tạo & Chia sẻ" gọi [BackupController.createManualBackup]
/// rồi mở bảng chia sẻ hệ thống (FR-001..FR-003). Đóng sheet bằng
/// `Navigator.pop(path)` — nơi gọi (`BackupRestoreScreen`) tự đẩy màn thành
/// công, tránh dùng `context` của sheet sau khi đã pop (khuôn `AddSheetChoice`).
class CreateBackupSheet extends StatefulWidget {
  const CreateBackupSheet({
    super.key,
    required this.controller,
    this.shareFile = _defaultShareBackupFile,
  });

  final BackupController controller;
  final ShareBackupFile shareFile;

  @override
  State<CreateBackupSheet> createState() => _CreateBackupSheetState();
}

class _CreateBackupSheetState extends State<CreateBackupSheet> {
  late final Future<BackupSummary> _summary = widget.controller.currentSummary();
  bool _passwordEnabled = false;
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAndShare() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final password = _passwordEnabled && _passwordCtrl.text.isNotEmpty
          ? _passwordCtrl.text
          : null;
      final path = await widget.controller.createManualBackup(
        password: password,
      );
      await widget.shareFile(path);
      if (!mounted) return;
      Navigator.of(context).pop(path);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không tạo được file sao lưu'.tr);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tạo bản sao lưu'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<BackupSummary>(
              future: _summary,
              builder: (context, snapshot) {
                final summary = snapshot.data;
                if (summary == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Container(
                  key: const ValueKey('create-backup-summary'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.softCardBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '@wallets ví · @categories danh mục · @transactions giao dịch'
                        .trParams({
                          'wallets': '${summary.counts['wallets'] ?? 0}',
                          'categories': '${summary.counts['categories'] ?? 0}',
                          'transactions':
                              '${summary.counts['transactions'] ?? 0}',
                        }),
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Đặt mật khẩu bảo vệ file'.tr,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  ),
                ),
                Switch(
                  key: const ValueKey('create-backup-password-switch'),
                  value: _passwordEnabled,
                  onChanged: (v) => setState(() => _passwordEnabled = v),
                ),
              ],
            ),
            if (_passwordEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  key: const ValueKey('create-backup-password-field'),
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: colors.softCardBg,
                    hintText: 'Nhập mật khẩu'.tr,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: colors.coralOnNeutral, fontSize: 12),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      key: const ValueKey('create-backup-cancel'),
                      onPressed: _busy ? null : () => Navigator.of(context).pop(),
                      child: Text('Hủy'.tr),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      key: const ValueKey('create-backup-submit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _busy ? null : _createAndShare,
                      child: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Tạo & Chia sẻ'.tr),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
