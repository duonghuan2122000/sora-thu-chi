# Nghiên cứu: Dọn màn Tiện ích & Cá nhân hóa (PBI 45)

## Quyết định 1 — Cách ẩn hàng

**Quyết định**: Bỏ hẳn 3 lời gọi `_navRow(...)` (Định dạng & Tiền tệ, Tìm kiếm toàn cục, Quản lý Tag) khỏi mảng truyền vào `_rows(...)` trong `utilities_screen.dart`, không dùng cờ ẩn/hiện hay điều kiện runtime.

**Lý do**: Đây là ẩn tĩnh vĩnh viễn cho tới khi có PBI implement tính năng thật — không có state nào cần bật/tắt lúc chạy. Xoá thẳng dòng code là ít nhất, đúng chuẩn "lazy" của dự án (không thêm feature flag cho giá trị không bao giờ đổi trong runtime).

**Phương án khác đã xem xét**: Thêm cờ `bool _showComingSoon` hoặc field cấu hình — bị loại vì không có nhu cầu bật/tắt lúc chạy, chỉ tạo thêm state thừa.

## Quyết định 2 — Ẩn nhãn nhóm rỗng

**Quyết định**: Nhóm "DỮ LIỆU & TÌM KIẾM" mất cả 2 hàng còn 0 hàng con → xoá luôn `_SectionLabel('DỮ LIỆU & TÌM KIẾM'.tr)` và toàn bộ block nhóm đó khỏi `_body()`, không dựng UI có điều kiện `if (rows.isNotEmpty)`.

**Lý do**: Danh sách hàng trong nhóm này là hằng số biết trước lúc build (không phụ thuộc dữ liệu người dùng), nên có thể xoá trực tiếp thay vì thêm logic kiểm tra rỗng lúc chạy — ít code hơn, dễ đọc hơn.

**Phương án khác đã xem xét**: Giữ hàm `_rows`/`_SectionLabel` chung và bọc điều kiện `isNotEmpty` — bị loại vì nhóm rỗng ở đây là sự thật tĩnh (biết trước khi build), thêm điều kiện runtime là dư thừa.

## Quyết định 3 — Hàng "Widget màn hình chính"

**Quyết định**: Giữ nguyên hoàn toàn (đã xác nhận với người dùng ở bước spec) — không đổi trailing, không đổi hành vi.

**Lý do**: Dialog hướng dẫn ghim là hành vi thật, không thuộc phạm vi "hàng giả" cần ẩn.

**Phương án khác đã xem xét**: Không có — quyết định đã chốt ở spec.md (mục Giả định).

Không còn điểm `NEEDS CLARIFICATION` nào cần giải quyết thêm — thay đổi chỉ chạm 1 file UI hiện có, không đổi schema, không đổi seam/store.
