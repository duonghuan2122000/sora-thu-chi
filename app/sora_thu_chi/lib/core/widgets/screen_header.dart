import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Vùng tiêu đề teal cho màn chính trong app shell.
/// Nội dung màn được đặt phía dưới header, nền trắng.
/// [bottom] là widget thô (do caller dựng) hiển thị phía dưới tiêu đề
/// trong cùng vùng teal — 3 màn chính còn lại không truyền, giữ layout cũ.
/// [centerTitle] căn giữa tiêu đề; [trailing] đặt bên phải cùng hàng tiêu đề
/// (màn Giao dịch truyền icon lọc). Hai tham số mặc định giữ layout cũ.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.bottom,
    this.centerTitle = false,
    this.trailing,
  });

  final String title;
  final Widget? bottom;
  final bool centerTitle;

  /// Widget đặt bên phải cùng hàng tiêu đề — thường là nút tròn 48px.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.teal,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: bottom == null
              ? _titleBar()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _titleBar(),
                    const SizedBox(height: 16),
                    bottom!,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _titleBar() {
    final titleText = Text(
      title,
      style: const TextStyle(
        color: AppColors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
    final hasTrailing = trailing != null;
    // Không có tham số tuỳ chọn → giữ nguyên layout cũ (tiêu đề trái, thẳng).
    if (!centerTitle && !hasTrailing) return titleText;

    // Ô nút bên phải cao 48, **rộng theo nội dung** — một nút tròn 48 giữ đúng
    // bề rộng cũ (PBI 26), nhiều nút cạnh nhau (màn Báo cáo: so sánh + xuất,
    // PBI 27) thì tiêu đề co lại thay vì tràn.
    Widget trailingSlot() => SizedBox(
      height: 48,
      child: Align(alignment: Alignment.center, child: trailing),
    );

    if (!centerTitle) {
      return Row(
        children: [
          Expanded(child: titleText),
          if (hasTrailing) trailingSlot(),
        ],
      );
    }
    if (!hasTrailing) return Center(child: titleText);
    return Row(
      children: [
        const SizedBox(width: 48),
        Expanded(child: Center(child: titleText)),
        trailingSlot(),
      ],
    );
  }
}
