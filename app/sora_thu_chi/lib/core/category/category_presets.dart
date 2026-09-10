import '../../theme/app_colors.dart';
import '../../theme/sora_colors.dart';
import 'category.dart';

/// Preset biểu tượng & bảng màu danh mục cho form thêm/sửa (màn `02`).
/// Màu tham chiếu token [AppColors] — không hex cứng trong widget; bảng màu là
/// **dữ liệu** (ARGB int như cột `categories.color`), tập trung một chỗ (R2).

/// Đúng 15 khóa đang có trong map [categoryIcon] (widget `category_icon.dart`)
/// — mọi ô chọn render được; thứ tự ổn định.
const List<String> categoryIconChoices = [
  'restaurant',
  'directions_car',
  'home',
  'receipt',
  'shopping_bag',
  'sports_esports',
  'medical_services',
  'school',
  'payments',
  'redeem',
  'show_chart',
  'category',
  'local_cafe',
  'restaurant_menu',
  'shopping_cart',
];

/// Biểu tượng chọn sẵn theo loại (màn Thêm) — thuộc [categoryIconChoices].
String defaultIconFor(CategoryType type) => switch (type) {
  CategoryType.income => 'payments',
  CategoryType.expense => 'receipt',
};

/// Màu chọn sẵn theo loại (màn Thêm) — ARGB, thuộc [categoryPresetColors].
int defaultColorFor(CategoryType type) => AppColors.teal.toARGB32();

/// Bảng màu preset (13 ô): hợp 5 màu seed dữ liệu (danh mục hiện có luôn chọn
/// lại được màu cũ) + 8 màu palette mockup `02`. ARGB int (dữ liệu) — màu nhận
/// diện, **không đổi theo giao diện** nên hai ô mượn token sáng dùng thẳng
/// `SoraColors.light` (giá trị cố định, không theo theme đang bật).
final List<int> categoryPresetColors = [
  AppColors.teal.toARGB32(),
  AppColors.avatarBg.toARGB32(),
  SoraColors.light.listLabel.toARGB32(),
  AppColors.coral.toARGB32(),
  SoraColors.light.tabInactive.toARGB32(),
  AppColors.categoryOrange.toARGB32(),
  AppColors.categoryBlue.toARGB32(),
  AppColors.categoryPurple.toARGB32(),
  AppColors.categoryYellow.toARGB32(),
  AppColors.categoryRed.toARGB32(),
  AppColors.categoryCyan.toARGB32(),
  AppColors.categoryGreen.toARGB32(),
  AppColors.categoryViolet.toARGB32(),
];
