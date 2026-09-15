# Hợp đồng nội bộ: đường đi ảnh cho Tier A

Không có API/endpoint công khai ra bên ngoài (ứng dụng offline). Hai ranh giới nội bộ thay đổi:

## 1. Kênh nền tảng (Dart ⇄ Kotlin), `sora_thu_chi/device_probe`

Method hiện có `genAiGenerate` (chỉ nhận `prompt: String`) giữ nguyên cho tương thích, **thêm** tham số ảnh tuỳ chọn thay vì tạo method mới:

| Tham số | Kiểu | Bắt buộc | Ghi chú |
|---|---|---|---|
| `prompt` | `String` | có | Hướng dẫn JSON 5 khoá, không còn chứa văn bản OCR khi có ảnh đính kèm |
| `image` | `Uint8List` (→ `ByteArray` phía Kotlin) | không | Ảnh đã tiền xử lý (cùng bytes dùng cho OCR); có ảnh ⇒ Kotlin build `GenerateContentRequest` với `ImagePart` + `TextPart`; không có ⇒ giữ hành vi cũ (`generateContent(prompt)` dạng text thuần) |

Lỗi (model chưa sẵn sàng, request quá lớn, engine bận...) tiếp tục trả `result.error(...)` để tầng Dart bắt và fallback — không đổi hợp đồng lỗi.

## 2. Seam Dart nội bộ (`core/scan/`)

- `ScanLlm.generate` nhận thêm tham số ảnh tuỳ chọn (mặc định không dùng). `GeminiNanoLlm` truyền ảnh xuống kênh nền tảng khi có; `GemmaLlm` (Tier B) bỏ qua tham số này, hành vi không đổi.
- `ReceiptExtractor.extract` / `LlmExtractor.extract` nhận thêm tham số ảnh tuỳ chọn (bytes đã tiền xử lý). `RuleBasedExtractor` bỏ qua tham số này. `LlmExtractor` chỉ dựng prompt kèm ảnh khi `ScanLlm` đang dùng hỗ trợ ảnh (Tier A); các trường hợp còn lại dựng prompt từ text OCR như cũ.
- `ScanProcessingScreen` truyền `processed` (bytes ảnh sau tiền xử lý, đã có sẵn trong luồng hiện tại) vào `extractor.extract(...)` — không cần đọc/tiền xử lý ảnh thêm lần nữa.

## Bất biến (không đổi)

- Định dạng JSON 5 khoá model phải trả về.
- Cơ chế đối chiếu số tiền ảnh ngân hàng (so sánh với tín hiệu cỡ chữ của bộ luật).
- Thời gian chờ tối đa một lượt gọi AI mỗi lần quét.
- Hành vi khi không đọc được gì (màn "không đọc được", 2 nút chụp lại/nhập tay).
