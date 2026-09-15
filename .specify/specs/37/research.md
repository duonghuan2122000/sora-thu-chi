# Nghiên cứu kỹ thuật: PBI 37 — Tier A đọc ảnh trực tiếp

## Quyết định 1: API multimodal của ML Kit GenAI Prompt

- **Quyết định**: Dùng `GenerateContentRequest.Builder(ImagePart, TextPart)` (đã có sẵn trong `com.google.mlkit:genai-prompt:1.0.0-beta4`, dependency hiện tại — không thêm dependency mới) để gửi cả ảnh lẫn hướng dẫn văn bản trong **một** lượt gọi `GenerativeModel.generateContent(request)`. `ImagePart` nhận trực tiếp `ByteArray` (ảnh đã tiền xử lý dạng bytes, không cần decode thành `Bitmap` ở phía Dart).
- **Lý do**: Đã giải nén jar `genai-prompt-1.0.0-beta4-api.jar` và xác nhận bằng `javap` — `ImagePart`, `TextPart`, `Content.Builder`, `GenerateContentRequest.Builder` đều tồn tại và hỗ trợ đúng luồng ảnh + text trong một request kể từ bản beta4 đang dùng trong repo. Không cần nâng version thư viện.
- **Phương án khác đã xem xét**:
  - Nâng cấp lên AICore SDK (`com.google.ai.edge.aicore`) hoặc Firebase AI SDK để có API multimodal "chính thức" hơn — **loại bỏ** vì tốn thêm dependency, thêm rủi ro tương thích, trong khi thư viện hiện tại đã đủ khả năng.
  - Dùng `Content.Builder().text(...).image(bitmap)` (nhận `Bitmap` thay vì `ByteArray`) — cả hai cách đều khả dụng; chọn `ImagePart(ByteArray)` trực tiếp vì tránh phải decode `Bitmap` ở tầng Kotlin cho mỗi lượt gọi, tận dụng đúng bytes đã tiền xử lý sẵn có ở phía Dart.

## Quyết định 2: Cấu trúc prompt gửi kèm ảnh

- **Quyết định**: Giữ nguyên toàn bộ phần hướng dẫn JSON 5 khoá (`type/amount/date/merchant/category`) và danh sách danh mục đang có trong `buildScanPrompt`, chỉ **bỏ** đoạn `Nội dung: $text` (văn bản OCR) — thay bằng câu dẫn ngắn nói rõ nội dung cần đọc nằm trong ảnh đính kèm.
- **Lý do**: Phần hướng dẫn JSON là phần đã được kiểm chứng qua PBI 24/36 (đối chiếu số tiền, phân loại type, chọn danh mục) — không có lý do nghiệp vụ để đổi. Chỉ điểm khác biệt là nguồn nội dung (ảnh thay vì text).
- **Phương án khác đã xem xét**: Viết lại toàn bộ prompt riêng cho luồng ảnh — loại bỏ vì tăng rủi ro hồi quy so với việc chỉnh tối thiểu.

## Quyết định 3: Vẫn chạy OCR song song ở Tier A

- **Quyết định**: Luồng xử lý Tier A tiếp tục gọi OCR như hiện tại (không bỏ bước OCR trong `ScanProcessingScreen`); kết quả OCR truyền cho `ReceiptExtractor` để dùng cho fallback bộ luật khi AI lỗi/timeout, và cho việc đối chiếu số tiền ảnh ngân hàng — nhưng OCR **không** còn được nhét vào nội dung request gửi cho AI.
- **Lý do**: Theo chốt đã thống nhất khi lập spec — giữ đúng FR-002/FR-004, không phá vỡ cam kết fallback (FR-011 gốc của PBI 24).
- **Phương án khác đã xem xét**: Bỏ OCR hẳn ở Tier A — loại bỏ vì mất khả năng fallback bộ luật và đối chiếu số tiền ngân hàng khi AI lỗi.

## Quyết định 4: Phạm vi thay đổi giao diện seam Dart

- **Quyết định**: Thêm khả năng "đọc ảnh" cho seam `ScanLlm`/`LlmExtractor`/`ReceiptExtractor` qua tham số **tuỳ chọn** (ảnh dạng bytes), có giá trị mặc định `null`/không dùng cho các cài đặt không hỗ trợ (Tier B, bộ luật) — không đổi chữ ký các phương thức đã có theo cách phá vỡ code gọi cũ; các implementation không hỗ trợ ảnh bỏ qua tham số này.
- **Lý do**: Tier B (`GemmaLlm`) và `RuleBasedExtractor` không đổi hành vi (FR-005) — thêm tham số tuỳ chọn là cách nhỏ gọn nhất để không đụng vào 2 nhánh đó.
- **Phương án khác đã xem xét**: Tạo interface `ScanLlm` mới riêng cho ảnh song song interface cũ — loại bỏ vì làm `LlmExtractor` phải phân nhánh loại interface, phức tạp hơn một tham số tuỳ chọn.
