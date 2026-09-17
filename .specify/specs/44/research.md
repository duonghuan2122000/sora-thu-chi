# Nghiên cứu: PBI 44 — Nút back thiếu/không nhất quán

## Quyết định 1 — `category_child_list_screen.dart`: mở rộng `SubPageScaffold` thay vì Scaffold riêng

**Quyết định**: Thêm tham số tùy chọn `titleWidget` (Widget?) vào `SubPageScaffold` — khi có thì dùng thay cho `Text(title)`/khối title mặc định, nhưng vẫn qua chung `AppBar` (màu teal từ theme, back tự động) của `SubPageScaffold`. `title` (String) đổi thành optional, giữ nguyên hành vi cũ khi không truyền `titleWidget`. `CategoryChildListScreen` dùng `SubPageScaffold(titleWidget: <InkWell 2 dòng hiện có>, actions: [IconButton +])`.

**Lý do**: Màn này cần tiêu đề dạng widget chạm được (2 dòng: tên cha + "Danh mục con", `InkWell` mở form sửa cha) — `SubPageScaffold` hiện chỉ nhận `String title` + `String? subtitle` (không tappable). Thêm 1 tham số tùy chọn là thay đổi nhỏ nhất giữ được đúng 1 nguồn app bar chuẩn (FR-001), không cần viết `AppBar` riêng, không hard-code `AppColors.white` (đọc theo `AppBarTheme` mặc định của `SubPageScaffold`).

**Phương án khác đã xem xét**:
- Giữ nguyên `Scaffold(appBar: AppBar(...))` riêng, chỉ sửa màu hard-code → không đạt FR-001 (vẫn là app bar tự dựng, không dùng chung mẫu).
- Tạo biến thể `SubPageScaffold2` riêng cho màn có tiêu đề tappable → tạo thêm 1 mẫu app bar thứ 2, đi ngược mục tiêu SC-001 (chỉ 1 kiểu chuẩn).

## Quyết định 2 — `category_picker_screen.dart` & `tag_picker_screen.dart`: đổi sang `SubPageScaffold`

**Quyết định**: Thay `Scaffold(appBar: AppBar(title: Text(...)))` bằng `SubPageScaffold(title: '...'.tr, child: ..., bottomNavigationBar: ...)`. `tag_picker_screen` giữ nguyên `bottomNavigationBar` (nút "Xác nhận") — `SubPageScaffold` đã hỗ trợ sẵn tham số này.

**Lý do**: Cả 2 màn chỉ cần tiêu đề dạng chuỗi đơn giản, không có gì đặc biệt — khớp thẳng API hiện có của `SubPageScaffold`, không cần đổi logic chọn lựa (`Navigator.pop(category)` / `Navigator.pop(selected)` giữ nguyên).

**Phương án khác đã xem xét**: Không có — đây là trường hợp thay thế trực tiếp, không có đánh đổi đáng kể.

## Quyết định 3 — `backup_result_screen.dart`: thêm nút back tường minh, giữ nguyên layout thành công

**Quyết định**: Thêm 1 `IconButton(icon: Icons.arrow_back)` góc trên-trái trong `SafeArea`/body hiện có, gọi `Navigator.of(context).pop()` (pop 1 cấp — quay đúng màn trước, khác với `_done` hiện tại là `popUntil(isFirst)`). Không bọc `SubPageScaffold` (sẽ ép thêm 1 `AppBar` teal + tiêu đề, phá bố cục minh họa thành công đang có), không thêm `PopScope` chặn (giữ hành vi vuốt-back mặc định của Flutter — vốn đã cho phép pop, chỉ thiếu affordance nhìn thấy được).

**Lý do**: Đây là màn "kết quả" tự đứng (illustration + 2 nút hành động chính), không phải sub-page danh sách/form — ép dùng `SubPageScaffold` sẽ thêm 1 app bar không cần thiết và đổi hẳn bố cục đã đúng thiết kế. Vấn đề thực sự chỉ là "không có cách thoát nhìn thấy được", nên chỉ cần thêm 1 nút back tối thiểu, không đổi 2 nút hành động chính (giữ đúng FR-005).

**Phương án khác đã xem xét**:
- Bọc `SubPageScaffold` → vi phạm bố cục màn "kết quả" hiện có, không cần thiết cho mục tiêu (chỉ cần lối thoát tường minh).
- Thêm `PopScope(canPop: false)` + nút back tự xử lý pop → sai chủ đích, màn này không phải màn cần khoá luồng (khác PIN); chọn `canPop: true` mặc định (không cần khai báo `PopScope` khi hành vi mặc định đã đúng — tránh code thừa).
