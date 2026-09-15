# Quickstart kiểm thử: PBI 37 — Tier A đọc ảnh trực tiếp

Yêu cầu: máy/emulator hỗ trợ AICore (Tier A khả dụng — kiểm tra qua màn Cài đặt ▸ Quét hóa đơn ▸ Kiểm tra lại cấu hình).

## 1. Chạy test tự động

```bash
cd app/sora_thu_chi
flutter analyze
flutter test
```

Kỳ vọng: toàn bộ test hiện có pass (trừ 1 test đỏ có sẵn từ trước, không liên quan) + test mới cho seam ảnh (`llm_extractor_test.dart`, `gemini_nano_llm_test.dart`/tương đương, `scan_processing_screen_test.dart`).

## 2. QA tay trên emulator/máy thật (Tier A)

1. Vào **Cài đặt ▸ Quét hóa đơn**, đảm bảo đang ở Tier A (AI trên máy, không cần tải).
2. Quét một hóa đơn cửa hàng rõ nét (ảnh chụp mới hoặc chọn từ thư viện) → xác nhận màn xử lý vẫn hiển thị 4 bước như cũ, kết thúc ở màn xác nhận với số tiền/ngày/cửa hàng/danh mục hợp lý.
3. Quét một ảnh chụp màn hình thông báo chuyển khoản ngân hàng (có số dư + số tiền giao dịch đứng gần nhau) → xác nhận số tiền được chọn đúng là số tiền giao dịch, không nhầm số dư.
4. Bật chế độ máy bay / tắt mọi kết nối mạng (nếu có thể) → quét lại bước 2 → xác nhận vẫn ra kết quả bình thường (chứng minh xử lý trên máy, không cần mạng).
5. Giả lập lỗi AI (ví dụ tắt tạm AICore nếu công cụ cho phép, hoặc test bằng thiết bị Tier A "giả lỗi" trong môi trường dev) → xác nhận vẫn rơi về bộ luật, ra được màn xác nhận hoặc màn "không đọc được", không kẹt màn xử lý.
6. Chuyển sang Tier B (đã tải Gemma) và Chế độ cơ bản → quét lại bước 2 → xác nhận hành vi giống hệt trước khi có PBI 37 (không đổi).

## 3. Đối chiếu tiêu chí thành công

- SC-001: so kết quả đọc số tiền ở bước 2/3 với cách làm cũ (nếu còn giữ bản trước để so sánh) trên cùng ảnh mẫu.
- SC-002: bước 5 phải luôn ra được màn tiếp theo, không treo.
- SC-003: số bước/giao diện màn xử lý ở bước 2 giống hệt trước.
- SC-004: bước 6 không phát sinh khác biệt.
