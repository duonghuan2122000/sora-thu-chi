# Checklist chất lượng đặc tả: Chi tiết Ngân sách

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-12
**PBI**: 21 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API)
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc (mô tả, kịch bản, FR, SC, thực thể, giả định, quyết định đã chốt, ngoài phạm vi)

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ] — 3 điểm đã được chốt ngày 2026-09-12 (xem mục "Quyết định đã chốt" trong spec)
- [x] Các yêu cầu rõ ràng, kiểm thử được (FR-001…FR-024)
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ (SC-001…SC-012)
- [x] Đầy đủ kịch bản chấp nhận (21 kịch bản Given/When/Then)
- [x] Đã xác định các trường hợp biên (15 trường hợp)
- [x] Phạm vi rõ ràng (màn `03` + đổi kỳ xem + lưu trữ ngân sách; loại trừ 2b và phần còn lại của 2c)
- [x] Đã ghi nhận giả định và phụ thuộc (12 giả định, có ghi rõ phụ thuộc PBI 19/20)

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
- [x] Kịch bản người dùng bao phủ luồng chính (mở chi tiết → xem số liệu → đổi kỳ → xem giao dịch → sửa/lưu trữ)
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú tự kiểm tra

**Vòng 1** (2026-09-12):
- Đã sửa 1 điểm rò rỉ kỹ thuật ở bản nháp: bỏ mọi tham chiếu tên bảng/cột/controller, thay bằng mô tả nghiệp vụ ("dữ liệu lưu trên thiết bị").
- Bổ sung kịch bản i18n và bố cục/cỡ chữ để đồng bộ chuẩn chất lượng với PBI 20.
- Bổ sung trường hợp biên "Xem tất cả phải khớp số đã dùng" — rủi ro lệch số giữa màn Chi tiết và màn Giao dịch nếu bộ lọc không gộp danh mục con.

**Vòng 2** (2026-09-12, sau khi chốt 3 điểm mở):
- 1A — lưu trữ không có nơi xem lại: ghi vào "Ngoài phạm vi" + "Quyết định đã chốt".
- 2A + 3B — nút góc phải app bar = **đổi kỳ đang xem**, màn Chi tiết xem được các kỳ đã qua: thêm FR-023, FR-024 và kịch bản 2, 3, 12; cập nhật biểu đồ thành "3 kỳ gần nhất tính đến kỳ đang xem" (FR-008, FR-010, kịch bản 7, 18).
- Hệ quả kỳ đã kết thúc: ẩn băng cảnh báo tốc độ chi tiêu, thay "… ngày còn lại" bằng trạng thái đã kết thúc (FR-006, FR-007, kịch bản 2, 17).
- Thêm SC-012 (đổi kỳ → số liệu khớp kỳ đó) và 5 trường hợp biên cho kỳ đã kết thúc / kỳ đầu tiên / thao tác khi đang xem kỳ cũ.
