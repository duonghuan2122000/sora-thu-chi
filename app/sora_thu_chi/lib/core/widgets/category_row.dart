import 'package:flutter/material.dart';

import '../../theme/sora_colors.dart';
import '../category/category.dart';
import 'category_icon.dart';

/// Dòng danh mục dùng chung màn danh sách `01` (PBI 13), màn danh mục con `03`
/// (PBI 15) & màn sắp xếp `04` (PBI 16) — trích nguyên trạng `_row` của màn
/// `01`: bubble tròn nền nhạt alpha [Category.color] chứa icon màu nhận diện
/// (mờ khi ẩn), tên (ellipsis — không cắt chevron), nhãn "Đã ẩn" khi ẩn, dòng
/// phụ tùy chọn [subtitle], chevron `›` phải (tắt bằng [showChevron]). Trạng
/// thái ẩn tự suy từ [category]; [subtitle] & hành động do caller quyết (màn
/// `01` đếm con, màn `03` không truyền — con cấp 2 không có con). Màn `04`
/// truyền [leading] là tay cầm kéo–thả, [showChevron] false, [onTap] no-op.
/// Không nhận trạng thái chọn-bật (chưa cần) — onTap do caller truyền.
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.category,
    this.subtitle,
    required this.onTap,
    this.leading,
    this.showChevron = true,
  });

  final Category category;

  /// Dòng phụ dưới tên (VD "N danh mục con" màn `01`); null = không render.
  final String? subtitle;

  final VoidCallback onTap;

  /// Widget đứng trước bubble tròn (VD tay cầm kéo–thả màn sắp xếp `04`);
  /// null = không render — màn `01`/`03` không đổi.
  final Widget? leading;

  /// Hiện chevron `›` cuối dòng hay không (màn `04` không điều hướng → tắt).
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = SoraColors.of(context);
    final hidden = category.isHidden;
    final labelColor = hidden ? colors.tabInactive : colors.textPrimary;
    final iconColor = hidden ? colors.tabInactive : Color(category.color);
    return InkWell(
      key: ValueKey('category-row-${category.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            // Bubble nền nhạt phái sinh màu danh mục + icon màu đầy đủ.
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(category.color).withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                categoryIcon(category.icon),
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hidden) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Đã ẩn',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: colors.tabInactive,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, color: colors.tabInactive, size: 20),
          ],
        ),
      ),
    );
  }
}
