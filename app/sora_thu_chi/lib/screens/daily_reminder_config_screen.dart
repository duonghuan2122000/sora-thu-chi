import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/date_label.dart';
import '../core/notification/notification_prefs.dart';
import '../core/notification/notification_store.dart';
import '../core/widgets/sub_page_scaffold.dart';
import '../data/notification_deps.dart';
import '../theme/app_colors.dart';
import '../theme/sora_colors.dart';

/// Màn "Nhắc nhập giao dịch" (mockup `02`, PBI 29) — màn con của "Thông báo &
/// nhắc nhở": app bar teal + nút back, **không** bottom nav, **không** FAB;
/// `bottomNavigationBar` chỉ để ghim nút "Lưu thay đổi".
///
/// **Bản nháp**: mở màn **chỉ đọc** (`store.load()`), mọi thao tác (mũi tên giờ,
/// chip ngày, công tắc) chỉ đổi `_draft`; **chỉ** bấm "Lưu thay đổi" mới ghi
/// (FR-007/SC-014). Back giữa chừng bỏ thay đổi, không hỏi lại, không ghi.
///
/// Đợt này **không** chạm engine thông báo: 0 plugin, 0 quyền, 0 lịch (FR-014).
class DailyReminderConfigScreen extends StatefulWidget {
  const DailyReminderConfigScreen({super.key, this.store});

  /// Seam test: mặc định null → [ensureNotificationStore] khi vào.
  final NotificationStore? store;

  @override
  State<DailyReminderConfigScreen> createState() =>
      _DailyReminderConfigScreenState();
}

class _DailyReminderConfigScreenState extends State<DailyReminderConfigScreen> {
  late final NotificationStore _store;
  NotificationPrefs _draft = NotificationPrefs.defaults;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? ensureNotificationStore();
    _load();
  }

  /// Chỉ **đọc** — khác màn `01` (màn này không cần seed: mặc định đã được màn
  /// `01` ghi từ PBI 28, row cũ thiếu khoá ngày vẫn đọc ra đủ 7 ngày).
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await _store.load();
      if (!mounted) return;
      setState(() {
        _draft = prefs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không đọc được cài đặt.';
        _loading = false;
      });
    }
  }

  /// Quay vòng `% 24` / `% 60` (FR-003/SC-003).
  void _stepHour(int delta) => setState(() {
    _draft = _draft.copyWith(dailyHour: (_draft.dailyHour + delta + 24) % 24);
  });

  void _stepMinute(int delta) => setState(() {
    _draft = _draft.copyWith(
      dailyMinute: (_draft.dailyMinute + delta + 60) % 60,
    );
  });

  /// Tắt ngày bật cuối cùng → [NotificationPrefs.toggleDay] trả chính object cũ
  /// ⇒ không có trạng thái 0 ngày (FR-009).
  void _toggleDay(int weekday) =>
      setState(() => _draft = _draft.toggleDay(weekday));

  void _toggleOnlyIfNoTxn(bool value) => setState(() {
    _draft = _draft.copyWith(dailyOnlyIfNoTxnToday: value);
  });

  /// Ghi lỗi bỏ qua rồi vẫn về (đồng bộ cách chịu lỗi của màn `01`) — lần lưu
  /// sau ghi lại toàn trạng thái, không có nửa vời.
  Future<void> _save() async {
    try {
      await _store.save(_draft);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: 'Nhắc nhập giao dịch'.tr,
      bottomNavigationBar: _saveBar(),
      child: SafeArea(top: false, child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    final colors = SoraColors.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!.tr, style: TextStyle(color: colors.textPrimary)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: Text('Thử lại'.tr)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _SectionLabel('THỜI GIAN NHẮC'.tr),
        _timeBlock(colors),
        _SectionLabel('LẶP LẠI VÀO CÁC NGÀY'.tr),
        _dayChips(colors),
        _toggleRow(colors),
        _SectionLabel('XEM TRƯỚC THÔNG BÁO'.tr),
        _previewCard(colors),
      ],
    );
  }

  /// Khối thời gian: nền `softCardBg` bo 10 chứa 2 trục giờ/phút ngăn bởi `:`.
  Widget _timeBlock(SoraColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colors.softCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      // Bề rộng 2 trục là cố định theo thiết kế (mockup) — `FittedBox` thu nhỏ
      // cả khối khi cỡ chữ hệ thống lớn để không tràn ngang (FR-017).
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TimeColumn(
              colors: colors,
              value: _draft.dailyHour,
              onUp: () => _stepHour(1),
              onDown: () => _stepHour(-1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                ':',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _TimeColumn(
              colors: colors,
              value: _draft.dailyMinute,
              modulo: 60,
              onUp: () => _stepMinute(1),
              onDown: () => _stepMinute(-1),
            ),
          ],
        ),
      ),
    );
  }

  /// 7 chip tròn T2…CN — `Wrap` để cỡ chữ lớn/màn hẹp thì xuống hàng, không cắt.
  Widget _dayChips(SoraColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var weekday = 1; weekday <= 7; weekday++)
            _DayChip(
              colors: colors,
              label: dayLabel(weekday),
              selected: _draft.isDayEnabled(weekday),
              onTap: () => _toggleDay(weekday),
            ),
        ],
      ),
    );
  }

  Widget _toggleRow(SoraColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chỉ nhắc nếu chưa ghi giao dịch'.tr,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập'.tr,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _draft.dailyOnlyIfNoTxnToday,
            onChanged: _toggleOnlyIfNoTxn,
          ),
        ],
      ),
    );
  }

  /// Thẻ xem trước — mô phỏng tĩnh; giờ đọc **trực tiếp** từ `_draft` nên đổi
  /// ngay cùng nhịp chạm mũi tên (SC-004).
  Widget _previewCard(SoraColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.divider),
      ),
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
            child: Text(
              'S',
              style: TextStyle(
                color: colors.tealOnNeutral,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sora Thu Chi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Đừng quên ghi lại thu chi hôm nay nhé!'.tr,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatClock(_draft.dailyHour, _draft.dailyMinute),
            style: TextStyle(color: colors.tabInactive, fontSize: 10),
          ),
        ],
      ),
    );
  }

  /// Nút chính ghim đáy — khuôn 4 màn form đã QA; luôn bấm được (SC-014), kể cả
  /// khi không đổi gì.
  Widget _saveBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        child: SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton(
            key: const ValueKey('save-primary'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: _save,
            child: Text('Lưu thay đổi'.tr),
          ),
        ),
      ),
    );
  }
}

/// Một trục (giờ hoặc phút): mũi tên ▲ → lân cận trên → giá trị đang chọn (nền
/// nhạt, chữ teal) → lân cận dưới → mũi tên ▼. Lân cận quay vòng cùng miền.
class _TimeColumn extends StatelessWidget {
  const _TimeColumn({
    required this.colors,
    required this.value,
    required this.onUp,
    required this.onDown,
    this.modulo = 24,
  });

  final SoraColors colors;
  final int value;
  final int modulo;
  final VoidCallback onUp;
  final VoidCallback onDown;

  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final selected = TextStyle(
      color: colors.tealOnNeutral,
      fontSize: 26,
      fontWeight: FontWeight.w600,
    );
    final adjacent = TextStyle(color: colors.tabInactive, fontSize: 15);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onUp,
          icon: const Icon(Icons.keyboard_arrow_up),
          color: colors.listLabel,
        ),
        Text(_pad((value - 1 + modulo) % modulo), style: adjacent),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: colors.tealOnNeutral.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(_pad(value), style: selected),
        ),
        Text(_pad((value + 1) % modulo), style: adjacent),
        IconButton(
          onPressed: onDown,
          icon: const Icon(Icons.keyboard_arrow_down),
          color: colors.listLabel,
        ),
      ],
    );
  }
}

/// Chip ngày tròn 36 px: đang chọn → nền teal chữ trắng; không chọn → nền
/// `surface` viền `divider` chữ mờ. Nhãn chặn cỡ chữ ≤1.4 để 7 chip đủ chỗ trên
/// một hàng ở màn 360 px.
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.colors,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final SoraColors colors;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : colors.surface,
          shape: BoxShape.circle,
          border: selected ? null : Border.all(color: colors.divider),
        ),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.4,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.white : colors.tabInactive,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Nhãn nhóm viết hoa — khuôn màn `01`.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          color: SoraColors.of(context).tabInactive,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
