import 'package:flutter/material.dart';

/// Token màu **đổi theo giao diện** (bộ 2 theme qua `ThemeExtension`).
/// Giá trị light giữ nguyên hằng cũ trong `AppColors` → test light không đổi
/// kết quả; bản dark theo `docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md` §1.2.
///
/// Màu **bất biến** (fill teal thương hiệu, coral cảnh báo, trắng on-brand,
/// bảng màu danh mục/ví) vẫn nằm ở `AppColors` — không đổi theo theme.
@immutable
class SoraColors extends ThemeExtension<SoraColors> {
  const SoraColors({
    required this.background,
    required this.surface,
    required this.softCardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.tabInactive,
    required this.listLabel,
    required this.divider,
    required this.listDivider,
    required this.dotEmpty,
    required this.tealLightBg,
    required this.coralLightBg,
    required this.tealLightText,
    required this.tealOnNeutral,
    required this.coralOnNeutral,
  });

  /// Nền màn / bottom nav / thân — thay `AppColors.white` khi dùng làm **nền**.
  final Color background;

  /// Nền card phân lớp trên [background] — thay `AppColors.white` làm nền card.
  final Color surface;

  /// Card beige / panel / ô nhập — thay `AppColors.softCardBg`.
  final Color softCardBg;

  /// Chữ chính — thay `AppColors.textPrimary`.
  final Color textPrimary;

  /// Chữ phụ — thay `AppColors.textSecondary`.
  final Color textSecondary;

  /// Nhãn mờ / icon mờ / section label — thay `AppColors.tabInactive`.
  final Color tabInactive;

  /// Label chữ trong danh sách — thay `AppColors.listLabel`.
  final Color listLabel;

  /// Kẻ ngang phân cách khối — thay `AppColors.divider`.
  final Color divider;

  /// Kẻ hàng/list — thay `AppColors.listDivider`.
  final Color listDivider;

  /// Chấm rỗng radio/dot — thay `AppColors.dotEmpty`.
  final Color dotEmpty;

  /// Vòng nền icon xanh nhạt — thay `AppColors.tealLightBg`.
  final Color tealLightBg;

  /// Vòng nền icon cam nhạt — thay `AppColors.coralLightBg`.
  final Color coralLightBg;

  /// Text xanh nhạt đặt trên nền teal — thay `AppColors.tealLightText`.
  final Color tealLightText;

  /// Glyph/icon/chữ teal trên nền **trung tính** — thay `AppColors.teal` ở ngữ
  /// cảnh icon/chữ (không thay fill). Sáng hơn ở theme tối (FR-009).
  final Color tealOnNeutral;

  /// Glyph/chữ chi (coral) trên nền **trung tính** — thay `AppColors.coral` ở
  /// ngữ cảnh chữ/icon. Sáng hơn ở theme tối (FR-009).
  final Color coralOnNeutral;

  static const SoraColors light = SoraColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    softCardBg: Color(0xFFF1EFE8),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF6B6B6B),
    tabInactive: Color(0xFF9B9B9B),
    listLabel: Color(0xFF5F5E5A),
    divider: Color(0xFFE0E0E0),
    listDivider: Color(0xFFEFEFEF),
    dotEmpty: Color(0xFFB4B2A9),
    tealLightBg: Color(0xFFE1F5EE),
    coralLightBg: Color(0xFFFAECE7),
    tealLightText: Color(0xFFCDE9DF),
    tealOnNeutral: Color(0xFF0F6E56),
    coralOnNeutral: Color(0xFFD85A30),
  );

  static const SoraColors dark = SoraColors(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    softCardBg: Color(0xFF242420),
    textPrimary: Color(0xFFF2F2F0),
    textSecondary: Color(0xFFA8A8A3),
    tabInactive: Color(0xFFA8A8A3),
    listLabel: Color(0xFFB4B4AE),
    divider: Color(0xFF3A3A36),
    listDivider: Color(0xFF2E2E2A),
    dotEmpty: Color(0xFF6E6D66),
    tealLightBg: Color(0xFF17332C),
    coralLightBg: Color(0xFF3A2518),
    tealLightText: Color(0xFFCDE9DF),
    tealOnNeutral: Color(0xFF3FA98A),
    coralOnNeutral: Color(0xFFE8734C),
  );

  /// Token theo theme hiện hành; theme chưa đăng ký extension → [light]
  /// (test pump `MaterialApp` thường không crash).
  static SoraColors of(BuildContext context) =>
      Theme.of(context).extension<SoraColors>() ?? light;

  @override
  SoraColors copyWith({
    Color? background,
    Color? surface,
    Color? softCardBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? tabInactive,
    Color? listLabel,
    Color? divider,
    Color? listDivider,
    Color? dotEmpty,
    Color? tealLightBg,
    Color? coralLightBg,
    Color? tealLightText,
    Color? tealOnNeutral,
    Color? coralOnNeutral,
  }) {
    return SoraColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      softCardBg: softCardBg ?? this.softCardBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      tabInactive: tabInactive ?? this.tabInactive,
      listLabel: listLabel ?? this.listLabel,
      divider: divider ?? this.divider,
      listDivider: listDivider ?? this.listDivider,
      dotEmpty: dotEmpty ?? this.dotEmpty,
      tealLightBg: tealLightBg ?? this.tealLightBg,
      coralLightBg: coralLightBg ?? this.coralLightBg,
      tealLightText: tealLightText ?? this.tealLightText,
      tealOnNeutral: tealOnNeutral ?? this.tealOnNeutral,
      coralOnNeutral: coralOnNeutral ?? this.coralOnNeutral,
    );
  }

  @override
  SoraColors lerp(covariant SoraColors? other, double t) {
    if (other == null) return this;
    return SoraColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      softCardBg: Color.lerp(softCardBg, other.softCardBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      tabInactive: Color.lerp(tabInactive, other.tabInactive, t)!,
      listLabel: Color.lerp(listLabel, other.listLabel, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      listDivider: Color.lerp(listDivider, other.listDivider, t)!,
      dotEmpty: Color.lerp(dotEmpty, other.dotEmpty, t)!,
      tealLightBg: Color.lerp(tealLightBg, other.tealLightBg, t)!,
      coralLightBg: Color.lerp(coralLightBg, other.coralLightBg, t)!,
      tealLightText: Color.lerp(tealLightText, other.tealLightText, t)!,
      tealOnNeutral: Color.lerp(tealOnNeutral, other.tealOnNeutral, t)!,
      coralOnNeutral: Color.lerp(coralOnNeutral, other.coralOnNeutral, t)!,
    );
  }
}
