# Checklist chất lượng đặc tả: Trung tâm thông báo trong app (màn `03`)

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-13
**PBI**: 30 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API) — chỉ nhắc tên bảng/màn hình đã có ở mức điểm nối, không chốt cấu trúc kỹ thuật
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc (mô tả, luồng, FR, SC, thực thể, giả định, ngoài phạm vi)

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ] — 3/3 đã chốt (Q1 phạm vi = A, Q2 lối vào = A, Q3 lưu trữ = A)
- [x] Các yêu cầu rõ ràng, kiểm thử được (FR-001…FR-019)
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ (SC-001…SC-014)
- [x] Đầy đủ kịch bản chấp nhận (luồng chính + luồng phụ rỗng + trường hợp biên)
- [x] Đã xác định các trường hợp biên (lịch sử rỗng, loại chưa có màn đích, cỡ chữ lớn, không mạng, múi giờ)
- [x] Phạm vi rõ ràng (mục "Ngoài phạm vi" liệt kê engine, quyền hệ thống, mockup `04`)
- [x] Đã ghi nhận giả định và phụ thuộc (engine chưa có ⇒ màn rỗng; phụ thuộc PBI 18/19/28)

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
- [x] Kịch bản người dùng bao phủ luồng chính
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú tự kiểm tra

- **Vòng 1**: còn 3 điểm [CẦN LÀM RÕ] → đã hỏi người dùng (Q1 phạm vi, Q2 lối vào/dấu chưa đọc, Q3 lưu trữ).
- **Vòng 2**: người dùng chốt **1A / 2A / 3A** → đã cập nhật spec (FR-001 chấm đỏ trên chuông, FR-010 trần 200 mục, FR-019 không nút "đọc tất cả", SC-013/SC-014, mục "Quyết định đã chốt"). Tất cả mục checklist **đạt**.
- **Rủi ro đã nhận diện (đã chấp nhận)**: với Q1 = A, trên app thật màn **luôn ở trạng thái rỗng** cho tới khi engine ra đời (chưa có gì ghi lịch sử). Các kịch bản đọc/chưa đọc/lọc tab cần dữ liệu lịch sử để QA — spec ghi rõ giả định "không dựng seed dữ liệu mẫu trong app"; kế hoạch kỹ thuật cần nêu cách QA phần này.
