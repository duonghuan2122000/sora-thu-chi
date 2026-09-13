# Checklist chất lượng đặc tả: Thông báo đẩy — engine bắn thông báo & nhắc nhở

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-13
**PBI**: 31 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API)
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ] — Q1/Q2/Q3 đã chốt (A/C/A) ngày 2026-09-13
- [x] Các yêu cầu rõ ràng, kiểm thử được (FR-001…FR-032)
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ (SC-001…SC-019)
- [x] Đầy đủ kịch bản chấp nhận (acceptance scenarios) — 29 kịch bản + 7 luồng
- [x] Đã xác định các trường hợp biên (edge cases) — 18 trường hợp
- [x] Phạm vi rõ ràng (mục "Ngoài phạm vi")
- [x] Đã ghi nhận giả định và phụ thuộc

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
- [x] Kịch bản người dùng bao phủ luồng chính
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú tự kiểm tra

- **Vòng 1 (2026-09-13)**: 3 mục còn `[CẦN LÀM RÕ]` (Q1/Q2/Q3) — đã trình bày cho người dùng. Các mục còn lại **đạt**.
- **Vòng 2 (2026-09-13)**: người dùng chốt **1A · 2C · 3A**; đã cập nhật FR-002/FR-016/FR-017 + thêm FR-032, 3 kịch bản (27–29) + 2 luồng phụ, 2 tiêu chí (SC-018/SC-019), 3 trường hợp biên, mục "Quyết định đã chốt"; **0** điểm `[CẦN LÀM RÕ]` còn lại → **đạt toàn bộ**.
- **Rà soát chi tiết triển khai**: các từ khoá kỹ thuật (`drift`, `flutter_local_notifications`, `zonedSchedule`, `FCM`, tên bảng/cột, tên interface nội bộ) **đã loại khỏi** phần yêu cầu — chỉ mô tả hành vi quan sát được ("lịch nhắc vẫn tới đúng giờ khi app đã bị đóng", "tách nhóm thông báo theo loại ở cấp hệ điều hành"). Ranh giới giữ lại **có chủ ý** ở phần "Giả định"/"Thực thể chính": mô tả **trạng thái chống bắn trùng** và **lịch nhắc đã đăng ký** dưới dạng khái niệm nghiệp vụ, vì đây là dữ liệu người dùng cần được lưu bền (kiểm thử được: bắn trùng sau khi khởi động lại thiết bị).
- **Nguồn đối chiếu**: `docs/notification/notification-solution.md` (§1 không FCM, §2 bảng 5 loại + tần suất tối đa + deep link, §3.2 cơ chế lên lịch/kiểm tra, §3.3 quyền & giới hạn nền tảng, §5 luồng người dùng) và mockup `docs/notification/04-mau-thong-bao-day.svg` (mẫu nội dung + màu/icon theo loại).
- **Điểm nối đã có sẵn từ PBI trước**: cấu hình nhắc nhở (PBI 28/29) và tầng ghi/đọc lịch sử + Trung tâm thông báo (PBI 30, gồm cả điều hướng theo loại và trần 200) — PBI này **chỉ bổ sung phần còn thiếu**, không nới rộng phạm vi của các màn đã xong.
