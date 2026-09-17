# Đặc tả tính năng: Chế độ riêng tư trên Tổng quan (Privacy Mode Dashboard)

**Mã PBI**: 48
**Ngày tạo**: 2026-09-17
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Công tắc "Ẩn số dư (Privacy mode)" đã có ở Cài đặt → Tiện ích (PBI 17) nhưng chưa gây tác dụng ở bất kỳ màn hình nào. Tính năng này làm cho công tắc đó thực sự che số tiền trên màn hình Tổng quan (Dashboard) khi bật, đồng thời thêm biểu tượng con mắt ngay trên Tổng quan để bật/xem tạm thời — giúp người dùng dùng app ở nơi công cộng mà không lộ số liệu tài chính.

## Kịch bản & luồng người dùng

### Luồng chính

1. Người dùng bật "Ẩn số dư (Privacy mode)" (từ Cài đặt → Tiện ích, hoặc chạm biểu tượng con mắt trên Tổng quan).
2. Toàn bộ số tiền trên Tổng quan (số dư tổng, thu tháng này, chi tháng này, số tiền từng giao dịch gần đây) được thay bằng chuỗi che (dấu chấm), độ dài xấp xỉ số chữ số gốc, không tiết lộ giá trị thật.
3. Biểu tượng con mắt trên Tổng quan đổi trạng thái (mắt gạch chéo) phản ánh đang ở chế độ ẩn.
4. Người dùng chạm biểu tượng con mắt để xem tạm thời — số tiền hiện rõ ngay, không cần xác thực lại.
5. Chạm lại biểu tượng con mắt (hoặc rời khỏi Tổng quan rồi quay lại) → số tiền ẩn trở lại.
6. Trạng thái bật/tắt Privacy mode (khác với việc "xem tạm thời") được lưu bền, giữ nguyên qua các lần mở app, và đồng bộ hai chiều với công tắc ở Cài đặt → Tiện ích.

### Kịch bản chấp nhận

1. **Given** Privacy mode đang tắt, **When** người dùng mở Tổng quan, **Then** mọi số tiền hiển thị bình thường, biểu tượng con mắt ở trạng thái "đang mở" (không gạch chéo).
2. **Given** người dùng bật công tắc "Ẩn số dư" tại Cài đặt → Tiện ích, **When** quay lại Tổng quan, **Then** số dư tổng, thu/chi tháng này và số tiền từng giao dịch gần đây đều hiển thị dạng che, biểu tượng con mắt đổi sang trạng thái "đang ẩn".
3. **Given** Privacy mode đang bật trên Tổng quan, **When** người dùng chạm biểu tượng con mắt, **Then** toàn bộ số tiền hiện rõ ngay lập tức mà không yêu cầu nhập PIN/sinh trắc học.
4. **Given** số tiền đang hiện tạm thời (sau bước 3), **When** người dùng chạm lại biểu tượng con mắt, **Then** số tiền ẩn trở lại.
5. **Given** số tiền đang hiện tạm thời, **When** người dùng rời khỏi Tổng quan (sang tab khác) rồi quay lại, **Then** số tiền tự ẩn lại (không giữ trạng thái xem tạm thời giữa các lần vào màn hình).
6. **Given** người dùng chạm biểu tượng con mắt trên Tổng quan để bật Privacy mode (đang tắt), **When** vào Cài đặt → Tiện ích, **Then** công tắc "Ẩn số dư" hiển thị đã bật.
7. **Given** Privacy mode đang bật, **When** người dùng đóng và mở lại app (tắt hẳn, không phải background), **Then** Tổng quan vẫn hiển thị số tiền ở dạng che (không tự động hiện tạm thời).

### Trường hợp biên

- Số tiền âm hoặc bằng 0 vẫn được che như số tiền bình thường (không có ngoại lệ hiển thị nguyên bản).
- Danh sách "Giao dịch gần đây" rỗng (chưa có giao dịch) → không có số tiền nào để che, không phát sinh lỗi.
- Số tiền có độ dài rất lớn (nhiều chữ số) vẫn dùng chuỗi che có độ dài xấp xỉ, không tràn layout thẻ/dòng.
- Bật/tắt Privacy mode trong lúc màn hình Tổng quan đang mở → cập nhật hiển thị ngay, không cần tải lại màn hình thủ công.

## Yêu cầu chức năng

- **FR-001**: Khi Privacy mode đang bật, hệ thống PHẢI che (thay bằng chuỗi dấu chấm) toàn bộ số tiền trên Tổng quan: số dư tổng, thu tháng này, chi tháng này, và số tiền của từng giao dịch trong danh sách "Giao dịch gần đây".
- **FR-002**: Chuỗi che PHẢI có độ dài xấp xỉ theo số chữ số của số tiền gốc, không hiển thị giá trị hoặc gợi ý chính xác số tiền thật.
- **FR-003**: Tổng quan PHẢI có biểu tượng con mắt cho biết trạng thái Privacy mode hiện tại (đang ẩn/đang mở) và cho phép chạm để xem tạm thời khi đang ẩn.
- **FR-004**: Người dùng PHẢI xem được số tiền thật ngay khi chạm biểu tượng con mắt lúc Privacy mode đang bật, không yêu cầu xác thực (PIN/sinh trắc học).
- **FR-005**: Trạng thái "xem tạm thời" PHẢI tự động tắt (số tiền ẩn trở lại) khi người dùng rời khỏi Tổng quan hoặc khi mở lại app từ đầu; PHẢI không được lưu bền.
- **FR-006**: Trạng thái bật/tắt Privacy mode (khác trạng thái xem tạm thời) PHẢI dùng chung một nguồn lưu trữ với công tắc "Ẩn số dư" ở Cài đặt → Tiện ích — thay đổi ở nơi này PHẢI phản ánh ngay ở nơi kia.
- **FR-007**: Khi Privacy mode đang tắt, Tổng quan PHẢI hiển thị số tiền bình thường như hiện tại, không có gì thay đổi.

## Tiêu chí thành công

- **SC-001**: Khi bật Privacy mode, 100% số tiền hiển thị trên Tổng quan (số dư tổng, thu/chi tháng này, số tiền giao dịch gần đây) được che, không còn số tiền nào lộ ra ngoài ý muốn.
- **SC-002**: Người dùng xem lại số tiền thật trong vòng 1 thao tác chạm (không qua bước xác thực), và số tiền tự ẩn lại khi rời màn hình mà không cần thao tác thêm.
- **SC-003**: Bật/tắt Privacy mode ở Tổng quan hay ở Cài đặt → Tiện ích đều cho kết quả nhất quán ở cả hai nơi, không có trường hợp hai nơi hiển thị trạng thái khác nhau.

## Giả định

- Biểu tượng con mắt khi chạm chỉ tạo hiệu ứng "xem tạm thời" (không đổi giá trị bật/tắt Privacy mode đã lưu); muốn tắt hẳn Privacy mode vẫn phải dùng công tắc "Ẩn số dư" (Tổng quan hoặc Cài đặt).
- Không yêu cầu xác thực lại (PIN/sinh trắc học) khi xem tạm thời — theo đúng mặc định nêu trong tài liệu nghiệp vụ (mục 3.8), vì tùy chọn "xác thực khi thao tác nhạy cảm" (mục 3.9) là tính năng nâng cao chưa có trong phạm vi này.
- Phạm vi che số tiền giới hạn ở đúng các phần tử xuất hiện trên mockup Tổng quan (`06-privacy-mode-dashboard.svg`): số dư tổng, thu/chi tháng này, danh sách giao dịch gần đây. Các màn hình khác (Giao dịch, Báo cáo, Ví, Ngân sách) không thuộc phạm vi PBI này.
- Công tắc "Ẩn số dư" và dữ liệu lưu trữ liên quan (đã có từ PBI 17) được tái sử dụng nguyên trạng, không đổi tên hay thêm trạng thái lưu bền mới ngoài cái đã có.

## Ngoài phạm vi

- Che số tiền ở các màn hình khác ngoài Tổng quan (Giao dịch, Chi tiết giao dịch, Báo cáo, Danh sách ví, Ngân sách...).
- Yêu cầu xác thực (PIN/sinh trắc học) khi xem tạm thời số tiền — thuộc nhóm tính năng "Xác thực cho hành động nhạy cảm" (mục 3.9 tài liệu nghiệp vụ), không nằm trong PBI này.
- Phủ lớp che nội dung khi app vào chế độ đa nhiệm/task switcher (mục 3.7 tài liệu nghiệp vụ) — thuộc PBI khóa app/auto-lock, không thuộc PBI này.
