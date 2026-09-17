# Kế hoạch triển khai: Nút back thiếu/không nhất quán

**Mã PBI**: 44
**Liên kết spec**: .specify/specs/44/spec.md
**Ngày tạo**: 2026-09-17

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter |
| Framework / Thư viện chính | Flutter Material, `SubPageScaffold` (`core/widgets/sub_page_scaffold.dart`) |
| Lưu trữ dữ liệu | Không liên quan (thay đổi UI thuần) |
| Kiểm thử | `flutter test` (widget test hiện có cho 4 màn bị ảnh hưởng) + `flutter analyze` |
| Nền tảng triển khai | Android/iOS (app hiện có, không thêm dependency) |
| Ràng buộc hiệu năng | Không áp dụng |
| Ràng buộc khác | Không đổi hành vi nghiệp vụ/kết quả trả về của 3 màn (FR-005); không đụng màn PIN/modal (FR-004) |

Không có `.specify/memory/constitution.md` trong repo — bỏ qua bước đối chiếu hiến pháp.

## Giai đoạn 0 — Kết quả nghiên cứu

Xem `research.md`. Tóm tắt:

- **Quyết định 1**: `SubPageScaffold` thêm tham số tùy chọn `titleWidget` để `category_child_list_screen` dùng chung app bar chuẩn nhưng vẫn giữ tiêu đề 2 dòng tappable.
- **Quyết định 2**: `category_picker_screen` và `tag_picker_screen` đổi thẳng sang `SubPageScaffold(title: ...)`, giữ nguyên `bottomNavigationBar`/logic chọn lựa.
- **Quyết định 3**: `backup_result_screen` thêm 1 `IconButton` back (pop 1 cấp) ở góc trên-trái, không bọc `SubPageScaffold`, không thêm `PopScope` (hành vi pop mặc định đã đúng).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: không áp dụng — không có thực thể dữ liệu mới/thay đổi.
- **Hợp đồng giao diện**: không áp dụng — không có API/CLI công khai liên quan.
- **Kịch bản khởi động nhanh**: xem `quickstart.md`.

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/lib/
  core/widgets/sub_page_scaffold.dart      # sửa: thêm titleWidget tùy chọn, title thành optional
  screens/category_child_list_screen.dart  # sửa: Scaffold+AppBar riêng → SubPageScaffold(titleWidget: ...)
  screens/category_picker_screen.dart      # sửa: Scaffold+AppBar trần → SubPageScaffold(title: ...)
  screens/tag_picker_screen.dart           # sửa: Scaffold+AppBar trần → SubPageScaffold(title: ..., bottomNavigationBar: ...)
  screens/backup_result_screen.dart        # sửa: thêm IconButton back góc trên-trái (pop 1 cấp)
app/sora_thu_chi/test/
  # cập nhật/bổ sung test cho 4 file trên tương ứng thay đổi widget tree
  # (đường dẫn test cụ thể xác định ở bước /sora-task khi rà cấu trúc test/ hiện có)
```

## Rủi ro & ngoại lệ có lý do

- **Rủi ro**: test widget hiện có của 4 màn có thể tìm `AppBar`/`Text` theo cấu trúc cũ (VD `find.widgetWithText(AppBar, ...)`) — cần rà và cập nhật selector khi đổi sang `SubPageScaffold`, tránh test đỏ giả (không liên quan lỗi thật).
- **Rủi ro**: `category_child_list_screen` có `key: ValueKey('parent-title')` và `key: ValueKey('add-child')` trên title/action — khi chuyển sang `SubPageScaffold.titleWidget`/`actions` phải giữ nguyên các key này để không vỡ test/automation đang trỏ vào đó.
- **Ngoại lệ có lý do**: `backup_result_screen` không dùng `SubPageScaffold` như 3 màn còn lại (xem Quyết định 3, research.md) — chấp nhận vì đây là màn "kết quả" có bố cục đặc thù (minh họa + 2 nút hành động), ép app bar teal vào sẽ phá thiết kế mà không giải quyết thêm vấn đề gì (vấn đề gốc chỉ là thiếu affordance back, không phải thiếu app bar).
