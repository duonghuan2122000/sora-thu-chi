# Checklist chất lượng đặc tả: Cấu hình nhắc nhập giao dịch hằng ngày (màn 02)

**Mục đích**: Kiểm tra tính đầy đủ và chất lượng của đặc tả trước khi lập kế hoạch
**Ngày tạo**: 2026-09-13
**PBI**: 29 — [spec.md](../spec.md)

## Chất lượng nội dung

- [x] Không chứa chi tiết triển khai (ngôn ngữ, framework, API)
- [x] Tập trung vào giá trị người dùng và nhu cầu nghiệp vụ
- [x] Viết dễ hiểu cho người không chuyên kỹ thuật
- [x] Đầy đủ các mục bắt buộc

## Tính đầy đủ của yêu cầu

- [x] Không còn điểm đánh dấu [CẦN LÀM RÕ] — đã chốt Q1=B, Q2=A, Q3=A (mục "Quyết định đã chốt" của spec)
- [x] Các yêu cầu rõ ràng, kiểm thử được
- [x] Tiêu chí thành công đo lường được và không phụ thuộc công nghệ
- [x] Đầy đủ kịch bản chấp nhận (acceptance scenarios) — 21 kịch bản
- [x] Đã xác định các trường hợp biên (edge cases)
- [x] Phạm vi rõ ràng
- [x] Đã ghi nhận giả định và phụ thuộc

## Sẵn sàng cho bước tiếp theo

- [x] Mỗi yêu cầu chức năng có tiêu chí chấp nhận rõ ràng
- [x] Kịch bản người dùng bao phủ luồng chính
- [x] Không có chi tiết triển khai rò rỉ vào đặc tả

## Ghi chú tự kiểm tra

- 3 điểm `[CẦN LÀM RÕ]` đã được trình bày cho người dùng và **đã chốt** (Q1=B điểm vào là vùng tiêu đề hàng công tắc; Q2=A nút "Lưu thay đổi", back bỏ thay đổi; Q3=A mặc định cả 7 ngày). Đặc tả đã cập nhật, chạy lại kiểm tra: **đạt toàn bộ**.
- Bổ sung sau khi chốt: kịch bản chấp nhận **22** (bấm Lưu khi không đổi gì), tiêu chí thành công **SC-014** (chỉ ghi khi bấm Lưu), 1 luồng phụ (rời màn chưa lưu).
- **Tổng**: 22 kịch bản chấp nhận, 18 yêu cầu chức năng, 14 tiêu chí thành công.
- Ràng buộc đã đối chiếu: PBI 28 (màn `01`, cấu hình lưu bền, hàng công tắc), doc nghiệp vụ `docs/notification/notification-solution.md` §2 loại 1 + §4 mockup `02`, mockup `02-cau-hinh-nhac-nhap-giao-dich.svg`, Design System (teal/coral, bo góc, app bar teal + back), PBI 18 (theme), PBI 19 (i18n).
