# Checklist chất lượng đặc tả: Màn hình thêm / sửa danh mục

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-05
**PBI**: 14 — [Liên kết tới spec.md](../spec.md)

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

## Tự kiểm tra

- [x] Không rò rỉ kỹ thuật (không nhắc drift, GetX, schema, widget...)
- [x] Các quyết định chốt với người dùng được ghi vào mục "Quyết định đã chốt"
- [x] Khớp chốt PBI 13 (điểm vào FAB / dòng không con; danh mục có con đi màn con; hiển thị "Đã ẩn")
- [x] Bao phủ ràng buộc nghiệp vụ doc: tên ≤ 30 & duy nhất trong nhóm cha/loại, 2 cấp, con cùng loại cha, khóa đổi loại khi đã gắn giao dịch, danh mục hệ thống
