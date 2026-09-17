# Rà soát nhất quán giao diện — điểm cần cải tiến

> Audit thủ công toàn bộ 36 màn hình (`app/sora_thu_chi/lib/screens/`) đối chiếu `design-system-app-thu-chi.md`, tập trung 3 vấn đề người dùng phản ánh: thiếu nút back, màn Tiện ích lộn xộn, điều hướng gượng gạo. Ngày rà soát: 2026-09-17.

## 1. Nút back thiếu/không nhất quán

Đang tồn tại song song 4 kiểu "back" khác nhau, trong khi design system (§2.2, §7) chỉ định mọi sub-page phải dùng chung mẫu app bar teal + nút back.

- **Chuẩn đúng**: đa số sub-screen dùng chung `SubPageScaffold` (app bar teal + back tự động) — `wallet_list_screen.dart`, `wallet_detail_screen.dart`, `category_list_screen.dart`, `budget_detail_screen.dart`, `utilities_screen.dart`, `theme_screen.dart`, `language_screen.dart`...
- **Lệch #1** — `lib/screens/category_child_list_screen.dart:151-196`: tự dựng `Scaffold(appBar: AppBar(...))` riêng thay vì `SubPageScaffold`, hard-code màu chữ/icon `AppColors.white` thay vì đọc theme.
- **Lệch #2** — `lib/screens/category_picker_screen.dart:93-94` và `lib/screens/tag_picker_screen.dart:116-117`: dùng `Scaffold(appBar: AppBar(title: Text(...)))` trần — tạo thêm 1 biến thể app bar thứ 3, khác header 2 dòng của `SubPageScaffold`.
- **Lệch #3** — `lib/screens/backup_result_screen.dart:51-127`: không có `AppBar`, không nút back, không `PopScope` chặn vuốt back hệ thống — hành vi không tường minh.
- **Chủ đích, không phải lỗi**: `pin_lock_screen.dart`, `pin_setup_screen.dart` dùng `PopScope(canPop: false)`, không app bar — đúng vì là màn bảo mật độc lập (design system §2.2). `scan_camera_screen.dart:139` và `add_transaction_screen.dart:508-513` dùng icon "X" (close) thay vì mũi tên back — hợp lý cho màn kiểu modal, nhưng vẫn là 1 biến thể "back" thứ 4 cần biết là có chủ đích.

**Đề xuất**: chuyển 3 màn lệch chuẩn (`category_child_list_screen`, `category_picker_screen`, `tag_picker_screen`) sang dùng `SubPageScaffold`. Thêm `PopScope` tường minh cho `backup_result_screen` (chặn hoặc cho phép pop, chọn 1 chủ đích rõ ràng).

## 2. Màn "Tiện ích & Cá nhân hóa" lộn xộn

`lib/screens/utilities_screen.dart:183-267` — 3 nhóm / 8 hàng:

| Nhóm | Hàng | Trạng thái |
|---|---|---|
| HIỂN THỊ | Giao diện | điều hướng thật → `ThemeScreen` |
| HIỂN THỊ | Ngôn ngữ | điều hướng thật → `LanguageScreen` |
| HIỂN THỊ | Định dạng & Tiền tệ | **chevron giả**, không `onTap` (dòng 214-220) |
| TRẢI NGHIỆM | Widget màn hình chính | **switch giả**, `onChanged: null`, luôn hiện bật, chạm mở dialog hướng dẫn (dòng 224-230) |
| TRẢI NGHIỆM | Ẩn số dư | switch thật |
| TRẢI NGHIỆM | Máy tính khi nhập số tiền | switch thật |
| DỮ LIỆU & TÌM KIẾM | Tìm kiếm toàn cục | **chevron giả**, không `onTap` (dòng 250-256) |
| DỮ LIỆU & TÌM KIẾM | Quản lý Tag | **chevron giả**, không `onTap` (dòng 258-264) |

**Vấn đề**: 4/8 hàng trông giống có thể bấm (chevron hoặc switch) nhưng thực chất không làm gì — người dùng không phân biệt được hàng thật/giả chỉ qua giao diện. Đây là nguồn chính gây cảm giác "không nhất quán, không liên quan" trong màn này.

**Đề xuất** (chọn 1 hướng, không làm cả 2):
- (a) Ẩn hẳn 4 mục chưa có tính năng thật khỏi UI cho tới khi implement xong — rẻ, không cần thêm state.
- (b) Giữ nhưng đổi UI báo rõ "Sắp ra mắt" (nhãn xám, bỏ chevron/switch giả) — cần thêm 1 style trạng thái mới.

## 3. Điều hướng gượng gạo

Điểm tích cực: không trộn `Get.to`/`Navigator` — toàn bộ 27 điểm push trong codebase đều dùng `Navigator.of(context).push(MaterialPageRoute(...))`, nhất quán (dù `GetMaterialApp` có dùng cho i18n/Obx ở `app.dart:142`).

**Điểm lệch duy nhất đáng sửa** — `lib/screens/budget_detail_screen.dart:171`: gọi `Navigator.of(context).pop(); widget.onSelectTab?.call(index);` để "quay về rồi nhảy sang tab khác" — kết hợp pop + side-effect callback, chỉ xuất hiện ở đây, dễ vỡ nếu route stack thay đổi.

**Tiểu tiết không gấp**: thiếu route đặt tên (mọi push đều inline `MaterialPageRoute`, không deep-link được); type annotation không đồng nhất (`MaterialPageRoute<void>` ở một số nơi, không khai báo type ở nơi khác — vd `core/scan/scan_flow.dart`, `wallet_detail_screen.dart`, `transaction_detail_screen.dart`).

**Đề xuất**: thay cơ chế pop+callback ở `budget_detail_screen` bằng trả kết quả qua `Navigator.pop(context, index)` và xử lý chuyển tab ở nơi gọi (không lồng side-effect vào callback truyền xuống).

## Phạm vi không cần sửa

36 màn tổng cộng, phần lớn đã đúng chuẩn (`SubPageScaffold`, `Navigator` thuần, không route/transition tùy biến rải rác) — không cần đại tu toàn app, chỉ 3 mục trên.

## Danh sách toàn bộ màn hình (tham chiếu)

```
lib/screens/add_transaction_screen.dart
lib/screens/backup_restore_screen.dart
lib/screens/backup_result_screen.dart
lib/screens/budget_detail_screen.dart
lib/screens/budget_form_screen.dart
lib/screens/budget_overview_screen.dart
lib/screens/category_child_list_screen.dart
lib/screens/category_form_screen.dart
lib/screens/category_list_screen.dart
lib/screens/category_picker_screen.dart
lib/screens/category_sort_screen.dart
lib/screens/daily_reminder_config_screen.dart
lib/screens/dashboard_screen.dart
lib/screens/language_screen.dart
lib/screens/notification_center_screen.dart
lib/screens/notification_settings_screen.dart
lib/screens/report_category_detail_screen.dart
lib/screens/report_comparison_screen.dart
lib/screens/report_export_screen.dart
lib/screens/report_screen.dart
lib/screens/pin/pin_lock_screen.dart
lib/screens/pin/pin_setup_screen.dart
lib/screens/scan/device_check_screen.dart
lib/screens/scan/scan_camera_screen.dart
lib/screens/scan/scan_confirm_screen.dart
lib/screens/scan/scan_processing_screen.dart
lib/screens/search_filter_screen.dart
lib/screens/settings_screen.dart
lib/screens/tag_picker_screen.dart
lib/screens/theme_screen.dart
lib/screens/transaction_detail_screen.dart
lib/screens/transaction_screen.dart
lib/screens/utilities_screen.dart
lib/screens/wallet_detail_screen.dart
lib/screens/wallet_form_screen.dart
lib/screens/wallet_list_screen.dart
lib/screens/wallet_transfer_screen.dart
```
