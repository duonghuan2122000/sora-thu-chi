# Checklist chất lượng đặc tả: Tiện ích & Cá nhân hóa (màn danh sách)

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-06
**PBI**: 17 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API)
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ]
- [x] Các yêu cầu rõ ràng, kiểm thử được
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ
- [x] Đầy đủ kịch bản chấp nhận (acceptance scenarios)
- [x] Đã xác định các trường hợp biên (edge cases)
- [x] Phạm vi rõ ràng
- [x] Đã ghi nhận giả định và phụ thuộc

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
- [x] Kịch bản người dùng bao phủ luồng chính
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú tự kiểm tra (validate)

- Đạt toàn bộ checklist trong lần kiểm tra đầu tiên. Không còn điểm [CẦN LÀM RÕ] — 3 câu hỏi đã được người dùng chốt: (1) công tắc tương tác thật + nhớ trạng thái, chưa hiệu ứng chức năng; (2) hàng "Widget màn hình chính" là hàng nhắc nhở mở hướng dẫn ghim, không phải công tắc thật; (3) hàng điều hướng giữ đủ hàng/trailing theo mockup, chạm no-op.
