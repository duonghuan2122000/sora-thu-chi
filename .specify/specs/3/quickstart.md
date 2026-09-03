# Kịch bản kiểm thử: Khóa ứng dụng bằng mã PIN

**Mã PBI**: 3

Cách chạy nhanh tính năng trên thiết bị/emulator (Android là nền tảng kiểm chứng chính):

```bash
cd app/sora_thu_chi
flutter pub get
flutter analyze        # phải sạch
flutter test           # toàn bộ test pass (shell cũ + luồng PIN)
flutter run            # chạy app
```

> Test trên máy đã cài app bản trước (đã có PIN): **gỡ app hoặc xóa dữ liệu** trước khi kiểm tra "lần đầu" (chỉ có cách gỡ — app chưa có màn tắt khóa).

## Nhóm A — Lần đầu mở app (thiết lập PIN)

1. Mở app lần đầu (dữ liệu sạch) → phải vào **màn thiết lập mã PIN**, không thấy nội dung app, không có nút bỏ qua/back. *(SC-001, SC-005)*
2. Nhập `1234` → chấm đặc theo từng ký tự, số không hiển thị chữ số thật → màn "xác nhận lại".
3. Nhập `1234` lần hai → vào thẳng màn chính (Tổng quan), **không** bị hỏi lại PIN. *(SC-001, FR-002)*
4. Thử lại từ đầu: nhập `1234` rồi xác nhận `5678` → báo lỗi, nhập lại từ đầu, không kích hoạt. *(FR-004)*
5. Thử PIN yếu `1111` (hoặc `1234`, `4321`) → dialog cảnh báo "dễ đoán"; chọn Tiếp tục → lưu được. *(FR-002 + giả định)*
6. Đang giữa màn thiết lập → back cử chỉ hệ thống → không ra được; thoát hẳn app rồi mở lại → **vẫn bắt thiết lập lại**. *(FR-010, SC-006)*

## Nhóm B — Khóa & mở khóa

7. Đã có PIN, tắt hẳn app rồi mở lại → hiện **màn hình khóa toàn màn hình** trước mọi nội dung, màn phía dưới không lộ ra. Lặp 10 lần → 10/10. *(SC-002, FR-005)*
8. Nhập đúng PIN → vào ngay, đúng màn đang đứng trước khi khóa (thử từ màn chính và từ sub-page như "Thêm giao dịch"). *(FR-007, SC-003)*
9. Nhập sai PIN → báo lỗi chung, xóa ký tự vừa gõ, cho nhập lại. *(FR-008)*
10. Nhập 1 số rồi backspace sửa giữa chừng → không tính là lần sai. *(edge)*
11. Trong lúc ở màn khóa, đưa app xuống nền rồi mở lại → vẫn ở màn khóa, không lộ nội dung. *(edge)*

## Nhóm C — Chống dò (anti-brute-force)

12. Nhập sai 5 lần liên tiếp (mỗi lần đủ 4 số) → **chặn 30 giây**: bàn phím không bấm được, có đếm ngược/thông báo. Hết giờ → nhập đúng → mở khóa bình thường, đếm về 0. *(SC-004, FR-009)*
13. Đang bị chặn → tắt hẳn app → mở lại → **thời gian chặn còn hiệu lực**, không nhập được cho tới khi hết giờ. *(edge, FR-009)*
14. Hết chặn, nhập sai tiếp (lần 6) → chặn **1 phút**; sai tiếp → 5 phút; chặn không vượt quá 15 phút (kiểm tra đến bậc 15p tùy thời gian). *(FR-009)*

## Nhóm D — Hiển thị & layout

15. Bật cỡ chữ lớn nhất hỗ trợ + màn có vùng an toàn (không tai thỏ/có nút cử chỉ) → bàn phím, chấm PIN, thông báo hiển thị đủ, không vỡ. *(SC-007, FR-012)*
16. Màn thiết lập & màn khóa: nền trắng, icon khóa trên nền tròn teal nhạt, tiêu đề/subtitle đúng màu design doc, numpad tròn viền xám, dot teal đặc/rỗng xám. *(đối chiếu `02-khoa-pin.svg`)*

## Phạm vi KHÔNG kiểm tra đợt này
Nút vân tay/Face ID (để trống), đổi PIN, quên PIN, tắt khóa, tự khóa sau N giây, Onboarding hoàn chỉnh — đều ngoài đợt (spec §Ngoài phạm vi).
