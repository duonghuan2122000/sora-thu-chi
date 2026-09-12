# Checklist chất lượng đặc tả: Tổng quan Ngân sách (ngân sách theo danh mục)

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-12
**PBI**: 20 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API) — không nêu drift/GetX/fl_chart/tên bảng; chỉ mô tả hành vi và dữ liệu nghiệp vụ
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ — đặt giới hạn chi, thấy ngay % đã dùng, tạo giữa kỳ phản ánh đúng thực tế
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc (mô tả, kịch bản, yêu cầu chức năng, tiêu chí thành công, thực thể, giả định, ngoài phạm vi)

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ] — 2 điểm đã được người dùng chốt ngày 2026-09-12 (ngân sách chu kỳ Tuần/Năm hiển thị tiến độ kỳ hiện tại của chính nó; màn Tổng quan chỉ hiển thị %, không hiển thị số tiền vượt)
- [x] Các yêu cầu rõ ràng, kiểm thử được (FR-001…FR-024)
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ (SC-001…SC-012 có số chạm, thời gian, %, số sai lệch)
- [x] Đầy đủ kịch bản chấp nhận (16 kịch bản) + luồng chính 13 bước
- [x] Đã xác định các trường hợp biên (11 trường hợp: tạo giữa kỳ, sửa giữa kỳ, xóa danh mục, xóa/sửa giao dịch, chu kỳ khác nhau, chưa có danh mục, số tiền không hợp lệ…)
- [x] Phạm vi rõ ràng (Quyết định đã chốt + Ngoài phạm vi liệt kê cụ thể theo mục 2a/2b/2c của doc nghiệp vụ)
- [x] Đã ghi nhận giả định và phụ thuộc (phụ thuộc module Danh mục, Giao dịch, ngôn ngữ PBI 19; phụ thuộc chưa có: Thông báo, Định dạng & Tiền tệ)

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
- [x] Kịch bản người dùng bao phủ luồng chính (tạo ngân sách → xem tiến độ → sửa) và các luồng phụ (trạng thái rỗng, kết thúc kỳ, chồng lấn)
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú

- Cả 2 điểm [CẦN LÀM RÕ] đã được người dùng chốt ngày 2026-09-12 và đã cập nhật vào spec (FR-002, FR-003, FR-005, kịch bản 17–18, SC-013/014, mục "Quyết định đã chốt") — không còn điểm mở.
- 6 quyết định đã chốt: 2 màn (`01` + `02`), điểm vào tab Báo cáo, chỉ ngân sách theo danh mục (2a), màu dải 80–99% coral nhạt, ngân sách chu kỳ Tuần/Năm hiển thị kỳ hiện tại của chính nó, màn Tổng quan chỉ hiển thị % (không hiện số tiền vượt).
- Mockup `01` đã trả lời điểm mở ⚠ "màu thanh tiến độ 80–99%" của wiki (coral nhạt) — cần đồng bộ wiki khi PBI được thi công.
- Spec đã sẵn sàng cho `/sora-plan 20`.
