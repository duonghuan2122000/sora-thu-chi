# Checklist chất lượng đặc tả: Báo cáo tổng quan

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-12
**PBI**: 22 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API)
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc (mô tả, kịch bản, FR, SC, thực thể, giả định, ngoài phạm vi)

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ] — 3 điểm đã được chốt ngày 2026-09-12 (xem mục "Quyết định đã chốt" trong spec)
- [x] Các yêu cầu rõ ràng, kiểm thử được (FR-001…FR-022)
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ (SC-001…SC-013)
- [x] Đầy đủ kịch bản chấp nhận (17 kịch bản Given/When/Then)
- [x] Đã xác định các trường hợp biên (14 trường hợp)
- [x] Phạm vi rõ ràng (màn `01` Tổng quan; loại trừ màn 02/03/04, bộ lọc nâng cao, xu hướng, dòng tiền theo ví, xuất báo cáo)
- [x] Đã ghi nhận giả định và phụ thuộc (13 giả định, ghi rõ phụ thuộc PBI 12/18/19/20 và các quyết định mở về tỷ giá/kỳ tài chính)

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
- [x] Kịch bản người dùng bao phủ luồng chính (mở tab → chọn kỳ → xem tổng/cột/phân bổ/top → chạm để lọc giao dịch)
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú tự kiểm tra

**Vòng 1** (2026-09-12):
- Đã sửa 1 điểm rò rỉ kỹ thuật ở bản nháp: bỏ tên bảng tổng hợp/cache và tên thư viện biểu đồ khỏi spec; các đề xuất kỹ thuật của doc nghiệp vụ (§2.2 bảng tổng hợp, §6 thư viện) chuyển thành **giả định** với ngưỡng đo được ở SC-007 (dưới 1 giây) để bước `/sora-plan` tự quyết.
- Bổ sung kịch bản 14–18 và FR-018…FR-022 (i18n, theme tối, bố cục/cỡ chữ, quy ước kỳ, lối vào Ngân sách không bị hỏng) để đồng bộ chuẩn chất lượng với PBI 20/21.
- Bổ sung ràng buộc "coral không dùng làm màu danh mục" (FR-011) — rủi ro xung đột ngữ nghĩa với Design System (coral = chi tiêu/cảnh báo) khi vẽ vòng tròn nhiều màu.
- Ghi rõ 2 điểm dễ lệch số giữa các màn: gộp danh mục con vào cha (FR-010) và tiền chi không gắn danh mục gộp vào "Khác" (FR-009, trường hợp biên) — nếu thiếu, tổng phân bổ sẽ không khớp tổng chi.

**Vòng 2** (2026-09-12, sau khi chốt 3 điểm mở):
- 1B — hàng điều hướng "Ngân sách" giữ trong màn Tổng quan, đặt ngay dưới khu đầu màn: cập nhật FR-017, kịch bản 1 và 17, SC-002 (ghi rõ khác biệt so với mockup).
- 2B — nút biểu tượng lịch để PBI sau: cập nhật FR-002 (không hiển thị), thêm ghi chú vào "Ngoài phạm vi" (bộ lọc khoảng thời gian tuỳ chỉnh) và SC-002 (liệt kê là khác biệt đã chốt).
- 3A — chạm danh mục mở màn Giao dịch đã lọc sẵn: giữ FR-012 và kịch bản 8, bổ sung giả định về việc màn Giao dịch đã có bộ lọc điền sẵn + gộp danh mục con (rủi ro lệch số, SC-006 chốt ràng buộc khớp).
