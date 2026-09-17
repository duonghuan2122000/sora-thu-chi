# Danh sách Task: Nút back thiếu/không nhất quán

**Mã PBI**: 44
**Nguồn**: plan.md, spec.md, research.md, quickstart.md

## Pha 1: Setup

- [X] T001 Rà 4 test hiện có (`test/category_child_list_screen_test.dart`, `test/category_picker_screen_test.dart`, `test/tag_picker_screen_test.dart`, `test/backup_result_screen_test.dart`) — ghi lại selector nào dựa vào cấu trúc `AppBar`/`Scaffold` cũ sẽ cần sửa theo từng story bên dưới.

## Pha 2: Foundational

*(Không có — mỗi user story độc lập, không có hạ tầng dùng chung bắt buộc trước khi làm bất kỳ story nào.)*

## Pha 3: User Story 1 - Chuẩn hoá app bar màn Danh mục con (Ưu tiên: P1)

**Mục tiêu**: `category_child_list_screen` dùng chung `SubPageScaffold` thay vì tự dựng `Scaffold(appBar: AppBar(...))`, không còn hard-code `AppColors.white` (FR-001).
**Tiêu chí kiểm thử độc lập**: Mở màn Danh mục con — app bar teal chuẩn, tiêu đề 2 dòng vẫn chạm mở form sửa cha, nút "+" vẫn thêm con, back mũi tên quay đúng màn trước; `flutter test test/category_child_list_screen_test.dart` pass.

- [X] T002 [US1] Thêm tham số tùy chọn `titleWidget` (`Widget?`) vào `SubPageScaffold` tại `app/sora_thu_chi/lib/core/widgets/sub_page_scaffold.dart`; đổi `title` thành `String?`; khi `titleWidget != null` dùng nó thay khối `Text(title)`/2-dòng mặc định trong `AppBar.title`, giữ nguyên hành vi cũ khi không truyền `titleWidget`.
- [X] T003 [US1] Sửa `app/sora_thu_chi/lib/screens/category_child_list_screen.dart`: bỏ `Scaffold(appBar: AppBar(...))` tự dựng, thay bằng `SubPageScaffold(titleWidget: <khối InkWell 2 dòng hiện có, giữ key ValueKey('parent-title')>, actions: [IconButton key ValueKey('add-child') như cũ])`, bỏ import `AppColors` nếu không còn dùng.
- [X] T004 [US1] Chạy `flutter test test/category_child_list_screen_test.dart`; nếu có assertion dựa vào `find.byType(AppBar)`/cấu trúc `Scaffold` cũ bị vỡ do đổi sang `SubPageScaffold`, cập nhật assertion cho khớp cấu trúc mới (không đổi ý nghĩa test).

## Pha 4: User Story 2 - Chuẩn hoá app bar màn Chọn danh mục & Chọn Tag (Ưu tiên: P2)

**Mục tiêu**: `category_picker_screen` và `tag_picker_screen` dùng `SubPageScaffold` thay vì `Scaffold(appBar: AppBar(title: Text(...)))` trần (FR-002).
**Tiêu chí kiểm thử độc lập**: Mở 2 màn từ màn Thêm giao dịch — app bar teal chuẩn, chọn/xác nhận vẫn trả đúng kết quả (`Navigator.pop`); `flutter test test/category_picker_screen_test.dart test/tag_picker_screen_test.dart` pass.

- [X] T005 [P] [US2] Sửa `app/sora_thu_chi/lib/screens/category_picker_screen.dart`: thay `Scaffold(appBar: AppBar(title: Text('Chọn danh mục'.tr)), body: ...)` bằng `SubPageScaffold(title: 'Chọn danh mục'.tr, child: ...)`, giữ nguyên `_onTapCategory`/`Navigator.pop(category)`.
- [X] T006 [P] [US2] Sửa `app/sora_thu_chi/lib/screens/tag_picker_screen.dart`: thay `Scaffold(appBar: AppBar(title: Text('Chọn tag'.tr)), body: ..., bottomNavigationBar: ...)` bằng `SubPageScaffold(title: 'Chọn tag'.tr, child: ..., bottomNavigationBar: ...)`, giữ nguyên `_confirm`/`Navigator.pop(_selected.toList())` và key `ValueKey('confirm-tags')`.
- [X] T007 [US2] Chạy `flutter test test/category_picker_screen_test.dart test/tag_picker_screen_test.dart`; cập nhật assertion nào còn giả định cấu trúc `AppBar`/`Scaffold` cũ.

## Pha 5: User Story 3 - Nút back tường minh màn kết quả sao lưu/khôi phục (Ưu tiên: P3)

**Mục tiêu**: `backup_result_screen` có nút back nhìn thấy được, không còn là màn "kẹt" (FR-003), không đổi hành vi 2 nút hành động chính hiện có (FR-005).
**Tiêu chí kiểm thử độc lập**: Mở màn kết quả (sau backup hoặc restore) — thấy nút back góc trên-trái, chạm vào quay lại đúng màn trước (không nhảy về Tổng quan); nút "Xong"/"Về Tổng quan" vẫn giữ hành vi `popUntil(isFirst)`/`onDone` cũ; `flutter test test/backup_result_screen_test.dart` pass.

- [X] T008 [US3] Sửa `app/sora_thu_chi/lib/screens/backup_result_screen.dart`: thêm `IconButton(key: ValueKey('backup-result-back'), icon: Icons.arrow_back, onPressed: () => Navigator.of(context).pop())` ở góc trên-trái trong `SafeArea`/body hiện có (không dùng `AppBar`, không đổi `_done`/`_shareAgain`).
- [X] T009 [US3] Chạy `flutter test test/backup_result_screen_test.dart`; thêm assertion mới xác nhận nút back (`ValueKey('backup-result-back')`) tồn tại và gọi `Navigator.pop()` (không phải `popUntil`).

## Pha cuối: Polish & Cross-cutting

- [X] T010 Chạy `flutter analyze` toàn repo `app/sora_thu_chi/` — sửa mọi cảnh báo mới phát sinh từ 4 file đã đổi (import thừa, unused field...).
- [X] T011 Chạy toàn bộ `flutter test` — xác nhận không có test mới bị đỏ do PBI 44 (giữ nguyên số lượng test đỏ có sẵn từ trước, nếu có, không liên quan thay đổi này).
- [X] T012 QA tay theo `quickstart.md` (7 bước: Danh mục con, Chọn danh mục, Chọn Tag, Kết quả sao lưu, Khôi phục, kiểm tra hồi quy màn PIN/modal, `flutter analyze`+`flutter test`) trên emulator.

## Sơ đồ phụ thuộc

- T001 (Setup) không chặn story nào, chỉ là bước rà soát tham khảo — nên làm trước để biết trước rủi ro test ở mỗi story.
- US1 (T002–T004), US2 (T005–T007), US3 (T008–T009) **độc lập hoàn toàn** với nhau — không story nào phụ thuộc story khác (3 file/nhóm file khác nhau, không chia sẻ state).
- Trong US1: T002 (sửa `SubPageScaffold`) phải xong trước T003 (dùng `titleWidget` trong `category_child_list_screen`); T004 chạy sau T003.
- Trong US2: T005 và T006 độc lập (khác file) → chạy song song `[P]`; T007 chạy sau cả hai.
- Trong US3: T008 trước T009.
- Pha cuối (T010–T012) chạy sau khi cả 3 story xong.

## Ví dụ chạy song song

- Song song ngay: T005 (`category_picker_screen.dart`) và T006 (`tag_picker_screen.dart`) — khác file, không phụ thuộc nhau.
- Song song giữa story (nếu nhiều người làm): sau khi T001 xong, có thể giao US1, US2, US3 cho 3 người làm đồng thời — không đụng file chung.

## Chiến lược triển khai

- MVP đề xuất: User Story 1 (P1) — sửa đúng màn lệch chuẩn rõ nhất (tự dựng app bar + hard-code màu).
- Thứ tự giao hàng tăng dần: US1 → US2 → US3 → Polish; mỗi story có thể tự chạy test/QA độc lập và merge riêng nếu cần chia nhỏ PR.
