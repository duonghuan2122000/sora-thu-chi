# Checklist chất lượng đặc tả: Màn hình danh sách danh mục

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-05
**PBI**: 13 — [Liên kết tới spec.md](../spec.md)

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

- Không lọt chi tiết kỹ thuật (không nhắc drift/GetX/Flutter/widget cụ thể) — chỉ nhắc tên màn đích theo doc.
- Không còn [CẦN LÀM RÕ]; 2 điểm nghiệp vụ (hiển thị danh mục ẩn, icon sắp xếp) đã chốt với người dùng và ghi vào "Quyết định đã chốt".
- Kịch bản chấp nhận phủ: mở màn + bố cục (1), nội dung/thứ tự/số con (2), chuyển tab (3), danh mục ẩn (4), làm mới dữ liệu (5), điểm vào chạm dòng có/không con (6-7), khả năng đọc không vỡ (8).
- Trạng thái spec: **Sẵn sàng lập kế hoạch**.
