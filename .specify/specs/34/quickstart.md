# Kịch bản khởi động nhanh: Mở khóa bằng sinh trắc học (PBI 34)

Yêu cầu thiết bị thật hoặc emulator **có cấu hình vân tay ảo** (Android Studio emulator: Extended controls → Fingerprint → "Touch sensor" giả lập chạm vân tay đã đăng ký). Emulator mặc định không có vân tay đăng ký ⇒ nhóm F sẽ đúng ngay không cần cấu hình gì.

## Chuẩn bị

1. Cài app lần đầu (hoặc xoá dữ liệu app) → hoàn tất thiết lập PIN 4 số (PBI 3).
2. Vào **Cài đặt** → xác nhận hàng "Mở khóa sinh trắc học" hiện đúng theo thiết bị (bật được nếu đã đăng ký vân tay/Face ID, tắt+giải thích nếu chưa).

## Nhóm A — Bật/tắt công tắc

1. Bật công tắc → hệ thống mời xác thực sinh trắc học ngay (không hộp thoại app tự vẽ chen giữa).
2. Xác thực đúng → công tắc chuyển bật; thoát/mở lại Cài đặt vẫn thấy bật (SC — persist qua khởi động lại).
3. Bật công tắc nhưng huỷ/xác thực sai → công tắc giữ nguyên tắt (đối chiếu FR-002, trường hợp biên #1).
4. Tắt công tắc đang bật → không hỏi gì thêm, tắt ngay (FR-009).

## Nhóm B — Mời tự động khi vào màn khóa

1. Bật công tắc, thoát app hẳn (kill), mở lại → màn khóa hiện thẳng giao diện mockup `03` (icon + "Chạm để xác thực"), không phải bàn phím PIN trước.
2. Xác thực đúng → vào thẳng Tổng quan (hoặc đúng màn đang đứng nếu resume từ nền — mở 1 sub-page, đưa app xuống nền, quay lại, xác thực → về đúng sub-page đó, đối chiếu FR-006).

## Nhóm C — Fallback PIN & nút Hủy

1. Ở màn mời sinh trắc học, bấm **"Dùng mã PIN thay thế"** → chuyển ngay bàn phím PIN, nhập đúng PIN vẫn vào được app.
2. Xác thực sinh trắc học sai/huỷ (không bấm nút nào) → tự chuyển bàn phím PIN (FR-005), không thoát app.
3. Bấm **"Hủy"** → vẫn đứng ở màn mời sinh trắc học (không chuyển PIN, không vào app) — đối chiếu giả định đã chốt (spec §Giả định).
4. Sau khi rơi về PIN do thất bại/huỷ sinh trắc học nhiều lần liên tiếp → xác nhận bộ đếm chống dò PIN (PBI 3) vẫn hoạt động đúng (5 lần **sai PIN thật** mới chặn — lần thất bại sinh trắc học không tính vào bộ đếm này, FR-005).

## Nhóm D — Thu hồi quyền hệ điều hành

1. Bật công tắc trong app. Vào Cài đặt hệ điều hành → Ứng dụng → Sora Thu Chi → tắt quyền "Vân tay/Sinh trắc học" (hoặc tắt hẳn khoá màn hình thiết bị nếu không có quyền riêng).
2. Kill app, mở lại → màn khóa hiện thẳng bàn phím PIN (không mời sinh trắc học đã mất hiệu lực, FR-007).
3. Vào Cài đặt trong app → công tắc "Mở khóa sinh trắc học" đã tự về tắt.

## Nhóm E — Đổi sinh trắc học đã đăng ký

1. Bật công tắc trong app (thiết bị/emulator đang chỉ có vân tay). Vào Cài đặt hệ điều hành, **thêm phương thức Face ID/khuôn mặt** (hoặc trên emulator: đổi cấu hình sang có thêm loại sinh trắc khác nếu công cụ hỗ trợ).
2. Kill app, mở lại → màn khóa hiện thẳng PIN (không mời sinh trắc học, FR-008); vào Cài đặt thấy công tắc đã tắt.
3. Bật lại công tắc → phải xác thực sinh trắc học lại từ đầu (đúng luồng FR-002), không có đường tắt.

> Ghi chú giới hạn: đổi/thêm-xoá vân tay **cùng loại** (fingerprint↔fingerprint) không kích hoạt được nhóm này trên phần lớn emulator/thiết bị thật do giới hạn `local_auth` (xem `research.md` R5) — nhóm E chỉ kiểm chứng được chắc chắn khi đổi **loại** sinh trắc học.

## Nhóm F — Thiết bị không hỗ trợ / chưa đăng ký

1. Trên emulator **chưa cấu hình vân tay** (mặc định): vào Cài đặt → hàng "Mở khóa sinh trắc học" hiện tắt, không bật được, có dòng phụ giải thích lý do (kịch bản chấp nhận #1).

## Nhóm G — Hồi quy nhanh

1. Ngôn ngữ English: đổi lịch chuyển "Tiếng Việt"→English (PBI 19) → nhãn màn mời sinh trắc học + hàng Cài đặt dịch đúng.
2. Giao diện Tối (PBI 18): màn mời sinh trắc học đọc đúng token màu tối, không hex cứng vỡ theme.
3. `flutter analyze` sạch; `flutter test` không tăng số ca đỏ so với baseline hiện tại của repo.
