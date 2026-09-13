# Checklist chất lượng đặc tả: Cài đặt Thông báo & nhắc nhở

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-13
**PBI**: 28 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API) — không nêu package, bảng dữ liệu, tên lớp; chỉ nói hành vi người dùng thấy được
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ — kiểm soát nhắc nhở, không bị làm phiền
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc (mô tả, kịch bản, FR, SC, thực thể, giả định, ngoài phạm vi, quyết định đã chốt)

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ] — 3 điểm Q1/Q2/Q3 đã đóng bằng phản hồi 1A/2A/3A (vòng 2)
- [x] Các yêu cầu rõ ràng, kiểm thử được (FR-001…FR-018, mỗi FR đều quan sát được)
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ (SC-001…SC-012)
- [x] Đầy đủ kịch bản chấp nhận (19 kịch bản, phủ luồng chính + luồng phụ)
- [x] Đã xác định các trường hợp biên (9 mục: mặc định lần đầu, tắt hết rồi restart, hàng chevron chạm liên tục, kỳ vọng bắn thông báo, cỡ chữ lớn, đổi múi giờ/ngôn ngữ, offline…)
- [x] Phạm vi rõ ràng (mục "Ngoài phạm vi" liệt kê 10 nhóm bị loại, có đối chiếu mockup/doc)
- [x] Đã ghi nhận giả định và phụ thuộc (12 giả định, gồm phụ thuộc module Ngân sách/Báo cáo và các module chưa tồn tại)

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng (kịch bản 1–19 ↔ FR-001…FR-018 ↔ SC-001…SC-012)
- [x] Kịch bản người dùng bao phủ luồng chính (xem màn, bật/tắt, nhớ cấu hình, quay lại) và luồng phụ (tắt hết rồi bật lại)
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú kiểm tra

**Vòng 1** — 3 điểm `[CẦN LÀM RÕ]` (Q1 phạm vi engine, Q2 hàng cấu hình chi tiết/màn `02`, Q3 hai nhóm chưa có module) đã trình bày cho người dùng; các mục còn lại đạt.

**Vòng 2 (2026-09-13)** — người dùng chốt **1A / 2A / 3A**; spec đã cập nhật theo:
- Q1=A ⇒ **bỏ toàn bộ yêu cầu về engine bắn thông báo** (chống trùng, nội dung nhắc, không bắn khi đang ở màn liên quan, quyền thông báo) khỏi FR — chuyển sang "Ngoài phạm vi"; thêm FR-012 nói rõ đợt này chỉ ghi nhận cấu hình, không bắn, không xin quyền.
- Q2=A ⇒ FR-011 đổi thành **hàng chevron chỉ hiển thị giá trị, chạm không mở gì**; ngoài phạm vi ghi rõ việc chỉnh tham số + màn `02`.
- Q3=A ⇒ FR-014 chốt **hiện đủ 5 nhóm, công tắc lưu được, không lộ "chưa hỗ trợ"**.
- SC đổi theo: bỏ 5 tiêu chí về bắn thông báo, thêm SC-007 (0 thông báo/0 lần hỏi quyền), SC-008 (chevron không mở gì), SC-012 (0 thay đổi dữ liệu nghiệp vụ).

**Kết luận**: đạt toàn bộ mục — sẵn sàng sang `/sora-plan 28`.
