# Kịch bản khởi động nhanh: PBI 48 — Privacy Mode Dashboard

Chạy `flutter run` từ `app/sora_thu_chi/`, vào tab **Tổng quan**.

1. **Trạng thái mặc định**: Số dư tổng, thẻ Thu/Chi tháng này, danh sách giao dịch gần đây hiển thị số thật. Icon con mắt ở vùng tiêu đề (cạnh chuông) ở trạng thái "mở".
2. **Bật Privacy mode từ Cài đặt**: Cài đặt → Tiện ích & Cá nhân hóa → bật "Ẩn số dư (Privacy mode)". Quay lại tab Tổng quan → mọi số tiền hiển thị dạng `••••••• đ`, icon mắt đổi sang trạng thái "đang ẩn" (gạch chéo).
3. **Xem tạm thời**: Chạm icon con mắt trên Tổng quan → số tiền hiện rõ ngay lập tức, không hỏi PIN/vân tay.
4. **Tự ẩn lại khi đổi tab**: Đang xem tạm thời (bước 3) → chuyển sang tab Giao dịch → quay lại tab Tổng quan → số tiền ẩn lại (không còn ở trạng thái xem tạm).
5. **Đồng bộ ngược**: Chạm icon mắt trên Tổng quan để bật Privacy mode (đang tắt) → vào Cài đặt → Tiện ích & Cá nhân hóa → công tắc "Ẩn số dư" hiển thị đã bật.
6. **Không đụng màn Giao dịch**: Với Privacy mode đang bật, mở tab Giao dịch → số tiền trong danh sách vẫn hiển thị bình thường (ngoài phạm vi PBI này).
7. **Khởi động lại app**: Tắt hẳn app rồi mở lại với Privacy mode đang bật → Tổng quan mở lên đã ẩn số tiền ngay (không hiện tạm thời trước).
