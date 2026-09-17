# Đặc tả tính năng: Dọn màn Tiện ích & Cá nhân hóa

**Mã PBI**: 45
**Ngày tạo**: 2026-09-17
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Màn "Tiện ích & Cá nhân hóa" hiện có 8 hàng nhưng 3 hàng chỉ là chevron trang trí không phản hồi chạm ("Định dạng & Tiền tệ", "Tìm kiếm toàn cục", "Quản lý Tag"), khiến người dùng bấm vào mà không có chuyện gì xảy ra — gây cảm giác màn lộn xộn, thiếu tin cậy (nêu tại `docs/ra-soat-nhat-quan-giao-dien.md` §2). Tính năng này ẩn 3 hàng chưa implement khỏi màn cho tới khi có tính năng thật đứng sau, giữ màn chỉ hiển thị những gì thực sự bấm được.

## Kịch bản & luồng người dùng

### Luồng chính

**Given** người dùng mở Cài đặt → "Tiện ích & Cá nhân hóa"
**When** màn hiển thị
**Then** chỉ thấy các hàng có hành vi thật khi chạm (điều hướng sang màn khác, bật/tắt công tắc, hoặc mở dialog hướng dẫn) — không còn hàng nào chạm vào mà im lặng.

### Kịch bản chấp nhận

1. **Given** màn Tiện ích đang hiển thị nhóm HIỂN THỊ, **When** người dùng nhìn danh sách, **Then** không còn hàng "Định dạng & Tiền tệ".
2. **Given** màn Tiện ích đang hiển thị nhóm DỮ LIỆU & TÌM KIẾM, **When** người dùng nhìn danh sách, **Then** không còn hàng "Tìm kiếm toàn cục" và "Quản lý Tag".
3. **Given** nhóm DỮ LIỆU & TÌM KIẾM chỉ còn 0 hàng sau khi ẩn, **When** màn dựng lại giao diện, **Then** cả nhãn nhóm "DỮ LIỆU & TÌM KIẾM" cũng không hiển thị (không để lại tiêu đề nhóm trống).
4. **Given** người dùng chạm hàng "Widget màn hình chính", **When** chạm, **Then** vẫn mở dialog hướng dẫn ghim widget như hiện tại (hành vi thật, giữ nguyên).
5. **Given** người dùng chạm hàng "Giao diện" hoặc "Ngôn ngữ", **When** chạm, **Then** vẫn điều hướng đúng sang màn con tương ứng (không đổi, đã có từ PBI 17/18/19).
6. **Given** người dùng bật/tắt "Ẩn số dư" hoặc "Máy tính khi nhập số tiền", **When** chạm công tắc, **Then** vẫn ghi nhớ trạng thái như hiện tại (không đổi).

### Trường hợp biên

- Nhóm HIỂN THỊ sau khi ẩn "Định dạng & Tiền tệ" vẫn còn 2 hàng thật (Giao diện, Ngôn ngữ) → nhóm và nhãn nhóm vẫn hiển thị bình thường, chỉ mất 1 hàng.
- Nhóm DỮ LIỆU & TÌM KIẾM mất cả 2 hàng duy nhất → toàn bộ nhãn nhóm + divider liên quan biến mất, màn không để lại khoảng trống bất thường hoặc divider mồ côi.
- Khi các tính năng "Định dạng & Tiền tệ", "Tìm kiếm toàn cục", "Quản lý Tag" được implement thật ở PBI sau, hàng tương ứng quay lại hiển thị bình thường (không cần thay đổi gì thêm ở tính năng này ngoài việc gỡ điều kiện ẩn).

## Yêu cầu chức năng

- **FR-001**: Màn Tiện ích & Cá nhân hóa PHẢI không hiển thị hàng "Định dạng & Tiền tệ".
- **FR-002**: Màn Tiện ích & Cá nhân hóa PHẢI không hiển thị hàng "Tìm kiếm toàn cục".
- **FR-003**: Màn Tiện ích & Cá nhân hóa PHẢI không hiển thị hàng "Quản lý Tag".
- **FR-004**: Khi một nhóm không còn hàng nào sau khi ẩn (ví dụ DỮ LIỆU & TÌM KIẾM), hệ thống PHẢI ẩn luôn nhãn nhóm đó — không để lại tiêu đề nhóm trống.
- **FR-005**: Hệ thống PHẢI giữ nguyên hành vi và giao diện của 5 hàng còn thật: Giao diện, Ngôn ngữ, Widget màn hình chính, Ẩn số dư, Máy tính khi nhập số tiền.
- **FR-006**: Tính năng này KHÔNG được thay đổi dữ liệu đã lưu (cài đặt Ẩn số dư / Máy tính) của người dùng hiện tại.

## Tiêu chí thành công

- **SC-001**: Màn Tiện ích & Cá nhân hóa chỉ còn hàng có phản hồi thật khi chạm — 100% hàng hiển thị đều điều hướng, bật/tắt được, hoặc mở hướng dẫn.
- **SC-002**: Số hàng hiển thị trên màn giảm từ 8 xuống 5, số nhóm hiển thị giảm từ 3 xuống 2.
- **SC-003**: Người dùng không còn báo cáo "chạm vào không có gì xảy ra" trên màn này.

## Giả định

- 3 tính năng bị ẩn (Định dạng & Tiền tệ, Tìm kiếm toàn cục, Quản lý Tag) chưa có PBI kế hoạch cụ thể trong lộ trình hiện tại — khi làm thật, chỉ cần đưa hàng trở lại hiển thị.
- Hàng "Widget màn hình chính" được coi là có hành vi thật (dialog hướng dẫn ghim) nên giữ nguyên, không thuộc phạm vi ẩn — quyết định đã xác nhận với người dùng khi viết đặc tả này.
- Không cần cờ cấu hình (feature flag) bật/tắt việc ẩn — ẩn thẳng bằng cách bỏ hàng khỏi danh sách dựng UI.

## Ngoài phạm vi

- Không implement tính năng thật cho "Định dạng & Tiền tệ", "Tìm kiếm toàn cục", "Quản lý Tag" — đó là các PBI riêng trong tương lai.
- Không đổi UI/state kiểu "Sắp ra mắt" — đã chọn hướng ẩn hẳn thay vì hiển thị nhãn chờ.
- Không sửa 2 vấn đề khác trong `docs/ra-soat-nhat-quan-giao-dien.md` (nút back thiếu/không nhất quán ở §1, điều hướng pop+callback ở §3) — nằm ngoài phạm vi PBI này.
