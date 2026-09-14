import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/backup/backup_controller.dart';
import '../core/backup/backup_crypto.dart';
import '../core/backup/backup_file_meta.dart';
import '../core/backup/backup_password_attempt.dart';
import '../core/date_label.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Bottom sheet "Xác nhận khôi phục" (mockup `03`, PBI 35, US2) — file **có**
/// mật khẩu: không hiện số liệu tóm tắt cho tới khi giải mã đúng (FR-016), sai
/// vẫn cho thử lại với độ trễ tăng dần (T037/[BackupPasswordAttemptDelay]).
/// Nút khôi phục chỉ bật khi đã tick "Tôi hiểu và muốn tiếp tục" (FR-013).
/// Đóng bằng `Navigator.pop(true)` khi khôi phục xong — nơi gọi
/// (`BackupRestoreScreen`) tự đẩy màn thành công (khuôn `CreateBackupSheet`).
class RestoreConfirmSheet extends StatefulWidget {
  const RestoreConfirmSheet({
    super.key,
    required this.controller,
    required this.path,
    required this.meta,
  });

  final BackupController controller;
  final String path;
  final BackupFileMeta meta;

  @override
  State<RestoreConfirmSheet> createState() => _RestoreConfirmSheetState();
}

class _RestoreConfirmSheetState extends State<RestoreConfirmSheet> {
  final TextEditingController _passwordCtrl = TextEditingController();
  final BackupPasswordAttemptDelay _attemptDelay = BackupPasswordAttemptDelay();

  Map<String, int>? _counts;
  String? _verifiedPassword;
  bool _checked = false;
  bool _busy = false;
  String? _passwordError;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.meta.hasPassword) {
      _counts = widget.meta.counts;
    }
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyPassword() async {
    final delay = _attemptDelay.nextDelay;
    if (delay > Duration.zero) await Future.delayed(delay);
    setState(() {
      _busy = true;
      _passwordError = null;
    });
    try {
      final data = await widget.controller.previewBackupFile(
        widget.path,
        password: _passwordCtrl.text,
      );
      _attemptDelay.recordSuccess();
      if (!mounted) return;
      setState(() {
        _counts = data.counts;
        _verifiedPassword = _passwordCtrl.text;
        _busy = false;
      });
    } on BackupDecryptException {
      _attemptDelay.recordFailure();
      if (!mounted) return;
      setState(() {
        _passwordError = 'Sai mật khẩu, vui lòng thử lại'.tr;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _passwordError = 'Không đọc được file'.tr;
        _busy = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_busy || !_checked) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.confirmRestore(
        path: widget.path,
        password: _verifiedPassword,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Khôi phục thất bại, vui lòng thử lại'.tr);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _needsPassword => widget.meta.hasPassword && _counts == null;

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
              'Xác nhận khôi phục'.tr,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatDateTimeLabel(widget.meta.exportedAt),
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (_needsPassword) _passwordSection(colors) else _summarySection(colors),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: colors.coralOnNeutral, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _passwordSection(SoraColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'File này được bảo vệ bằng mật khẩu. Nhập mật khẩu để xem trước khi khôi phục.'
              .tr,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('restore-password-field'),
          controller: _passwordCtrl,
          obscureText: true,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.softCardBg,
            hintText: 'Nhập mật khẩu'.tr,
            errorText: _passwordError,
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
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            key: const ValueKey('restore-password-submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _busy ? null : _verifyPassword,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text('Xác nhận mật khẩu'.tr),
          ),
        ),
      ],
    );
  }

  Widget _summarySection(SoraColors colors) {
    final counts = _counts ?? const {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          key: const ValueKey('restore-summary'),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.softCardBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '@wallets ví · @categories danh mục · @transactions giao dịch'
                .trParams({
                  'wallets': '${counts['wallets'] ?? 0}',
                  'categories': '${counts['categories'] ?? 0}',
                  'transactions': '${counts['transactions'] ?? 0}',
                }),
            style: TextStyle(color: colors.textPrimary, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const ValueKey('restore-warning-banner'),
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
                  'Dữ liệu hiện tại trên máy sẽ bị ghi đè hoàn toàn và không thể hoàn tác.'
                      .tr,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          key: const ValueKey('restore-confirm-checkbox-row'),
          onTap: () => setState(() => _checked = !_checked),
          child: Row(
            children: [
              Checkbox(
                value: _checked,
                onChanged: (v) => setState(() => _checked = v ?? false),
              ),
              Expanded(
                child: Text(
                  'Tôi hiểu và muốn tiếp tục'.tr,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            key: const ValueKey('restore-confirm-submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: AppColors.white,
              elevation: 0,
              disabledBackgroundColor: AppColors.coral.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: (_checked && !_busy) ? _confirm : null,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : Text('Khôi phục dữ liệu'.tr),
          ),
        ),
      ],
    );
  }
}
