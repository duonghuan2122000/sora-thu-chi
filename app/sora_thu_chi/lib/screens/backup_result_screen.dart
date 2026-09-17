import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/backup/backup_share.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Chế độ nội dung màn — dùng chung 1 màn cho cả 2 luồng (mockup `04`, doc §6).
enum BackupResultMode { backup, restore }

/// Màn "thành công" (mockup `04`, PBI 35) — màn con, không bottom nav/FAB.
/// [mode] `backup` → tuỳ chọn "Chia sẻ lại file" (FR-018); `mode` `restore` →
/// nút chính về Tổng quan (FR-017). [onDone] là seam test (khuôn các màn thành
/// công khác) — mặc định `popUntil` về route gốc.
class BackupResultScreen extends StatelessWidget {
  const BackupResultScreen({
    super.key,
    required this.mode,
    this.filePath,
    this.onDone,
    this.shareFile = defaultShareBackupFile,
  });

  final BackupResultMode mode;

  /// Path file vừa tạo — chỉ dùng ở `mode == backup` để chia sẻ lại (FR-018).
  final String? filePath;

  final VoidCallback? onDone;
  final ShareBackupFile shareFile;

  void _done(BuildContext context) {
    final callback = onDone;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _shareAgain() async {
    final path = filePath;
    if (path == null) return;
    await shareFile(path);
  }

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final isBackup = mode == BackupResultMode.backup;
    return Scaffold(
      key: const ValueKey('backup-result-screen'),
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.tealLightBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 40,
                  color: colors.tealOnNeutral,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isBackup
                    ? 'Đã tạo bản sao lưu'.tr
                    : 'Khôi phục dữ liệu thành công'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isBackup
                    ? 'Bạn có thể lưu file này ở nơi an toàn.'.tr
                    : 'Dữ liệu trên máy đã được cập nhật theo file đã chọn.'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 32),
              if (isBackup && filePath != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    key: const ValueKey('backup-result-share-again'),
                    onPressed: _shareAgain,
                    child: Text('Chia sẻ lại file'.tr),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  key: const ValueKey('backup-result-done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _done(context),
                  child: Text(isBackup ? 'Xong'.tr : 'Về Tổng quan'.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
