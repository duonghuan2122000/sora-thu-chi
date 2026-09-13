# Checklist chất lượng đặc tả: Logo ứng dụng & màn hình Splash

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-13
**PBI**: 25 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API) — spec chỉ nêu hiện tượng quan sát được (không chớp nền, tự kết thúc sau 5s); không nhắc plugin/file cấu hình cụ thể
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ — nhận diện thương hiệu, cảm giác app chuyên nghiệp, không còn icon mặc định
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc — có thêm mục "Điểm cần làm rõ"

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ] — 3 điểm đã được người dùng chốt (Q1=A phạm vi chỉ icon + splash, Q2=B icon dùng Concept A, Q3=A nền splash teal đặc)
- [x] Các yêu cầu rõ ràng, kiểm thử được (FR-001…FR-017 đều quan sát/đo được)
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ (SC-001…SC-008)
- [x] Đầy đủ kịch bản chấp nhận (9 kịch bản) + luồng chính + 2 luồng phụ
- [x] Đã xác định các trường hợp biên (nạp chậm, màn hình khởi động hệ thống, app bị kill khi ở nền, cỡ chữ hệ thống lớn, offline)
- [x] Phạm vi rõ ràng — có mục "Ngoài phạm vi"
- [x] Đã ghi nhận giả định và phụ thuộc

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
- [x] Kịch bản người dùng bao phủ luồng chính (cold start, resume, cài đè)
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú tự kiểm tra

- Lần 1: đạt toàn bộ trừ mục `[CẦN LÀM RÕ]` (3 điểm: phạm vi dùng logo, phương án icon launcher, màu nền splash). Ba điểm này ảnh hưởng tới phạm vi và trải nghiệm nên giữ lại để hỏi thay vì tự quyết.
- Lần 2 (sau khi chốt 1A / 2B / 3A): đã cập nhật spec — gỡ mục "Điểm cần làm rõ", đổi trạng thái sang **Sẵn sàng lập kế hoạch**; phát sinh thêm ràng buộc thị giác mới **FR-016 + SC-008** (nửa teal của đồng xu phải tách khỏi nền teal của splash bằng nét trắng — nếu không sẽ thành “hình tròn bị khuyết”).
- Đánh đổi đã ghi nhận trong Giả định: người dùng chọn Concept A cho icon launcher, **khác khuyến nghị của doc nghiệp vụ** (doc đề xuất Concept C cho icon vì rõ nét ở kích thước nhỏ) → SC-004 trở thành điều kiện bắt buộc.
