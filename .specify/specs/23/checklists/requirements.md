# Checklist chất lượng đặc tả: Chi tiết theo danh mục (màn 02 Báo cáo)

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-12
**PBI**: 23 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API)
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc (mô tả, kịch bản, FR, SC, thực thể, giả định, ngoài phạm vi)

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ] — 2 điểm đã được chốt ngày 2026-09-12 (xem mục "Quyết định đã chốt" trong spec)
- [x] Các yêu cầu rõ ràng, kiểm thử được (FR-001…FR-020)
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ (SC-001…SC-014)
- [x] Đầy đủ kịch bản chấp nhận (18 kịch bản Given/When/Then)
- [x] Đã xác định các trường hợp biên (13 trường hợp)
- [x] Phạm vi rõ ràng (màn `02` + liên kết "Xem tất cả" ở màn `01`; loại trừ màn 03/04, bộ lọc nâng cao, toggle danh mục con, xuất báo cáo)
- [x] Đã ghi nhận giả định và phụ thuộc (13 giả định, ghi rõ phụ thuộc PBI 12/18/19/22 và các quyết định mở về tỷ giá/kỳ tài chính)

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
- [x] Kịch bản người dùng bao phủ luồng chính (mở từ "Xem tất cả" → xem vòng tròn + danh sách đầy đủ → chạm danh mục để lọc giao dịch → back)
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú tự kiểm tra

**Vòng 1** (2026-09-12):
- Đã đối chiếu mockup `02` với code PBI 22 để chốt các khác biệt **cố ý** giữa hai màn và ghi thành giả định: (a) chấm màu/thanh tiến độ trên màn `02` lấy **màu lát cắt theo thứ hạng**, không lấy màu riêng của danh mục như bubble thẻ top ở màn `01`; (b) danh sách **không giới hạn 5 dòng** (doc §3.5); (c) app bar + back, **không** bottom nav (trang con).
- Đã bổ sung FR-017 (back không đổi kỳ của màn Tổng quan) và kịch bản 2/17 để chặn rủi ro màn `02` ghi ngược trạng thái kỳ sang màn `01`.
- Đã ghi rõ ràng buộc khớp số khi drill-down (FR-011/SC-006) và ràng buộc % cộng = 100 (FR-008/SC-004) — hai điểm dễ lệch số nhất giữa vòng tròn, danh sách và màn Giao dịch.
- Đã bổ sung SC-007 (màu dòng trùng màu lát cắt) vì màu là thông tin duy nhất nối vòng tròn với danh sách.
- 2 điểm chưa chốt được đánh dấu `[CẦN LÀM RÕ]`: số danh mục khi vượt bảng màu (FR-006/FR-007, trường hợp biên "nhiều hơn số màu") và hình thức tương tác của chip kỳ (FR-003).

**Vòng 2** (2026-09-12, sau khi chốt 2 điểm mở):
- 1B (đầy đủ, màu lặp lại) — cập nhật FR-004/FR-005/FR-006/FR-007/FR-010, thêm kịch bản 18, sửa trường hợp biên "nhiều hơn số màu", thêm SC-014; ghi rõ dòng "Khác" giờ **chỉ** dành cho tiền chi không gắn danh mục (không còn gộp phần ngoài top 5).
- 2A (chip chỉ hiển thị) — cập nhật FR-003 (nhãn tĩnh, không mũi tên/menu), kịch bản 3, SC-001 (ghi rõ khác biệt đã chốt so với mockup `02`), thêm giả định về chip; bộ lọc thời gian vẫn nằm trong "Ngoài phạm vi".
