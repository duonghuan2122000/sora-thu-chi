# Kế hoạch triển khai: Tier A đọc ảnh trực tiếp (Gemini Nano đa phương thức)

**Mã PBI**: 37
**Liên kết spec**: .specify/specs/37/spec.md
**Ngày tạo**: 2026-09-15

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart (Flutter) cho app; Kotlin cho kênh nền tảng Android |
| Framework / Thư viện chính | GetX (state); ML Kit Text Recognition (OCR, không đổi); `com.google.mlkit:genai-prompt:1.0.0-beta4` (đã có sẵn — dùng thêm API `ImagePart`/`GenerateContentRequest.Builder` đã xác nhận tồn tại trong bản đang dùng, không nâng version) |
| Lưu trữ dữ liệu | Không đổi — không thêm/sửa bảng drift |
| Kiểm thử | `flutter test` (unit cho `llm_extractor.dart`, `gemini_nano_llm.dart`; widget cho `scan_processing_screen.dart`); fake `ScanLlm`/`ReceiptOcr` như các PBI trước |
| Nền tảng triển khai | Android (Tier A/AICore chỉ khả dụng Android — không đổi phạm vi nền tảng của tính năng gốc) |
| Ràng buộc hiệu năng | Giữ nguyên timeout 10 giây/lượt gọi AI (`LlmExtractor.timeout`) |
| Ràng buộc khác | Offline hoàn toàn — ảnh không rời khỏi máy; không thêm dependency mới |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md` trong repo — đối chiếu với các quyết định kỹ thuật đã chốt trong `CLAUDE.md`/`wiki-knowledge/`:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Ứng dụng offline hoàn toàn, không gửi dữ liệu ra ngoài | ✅ | Ảnh vẫn xử lý qua AICore trên máy, không qua mạng (FR-006) |
| Fallback AI→bộ luật trong cùng seam (R7/FR-011 của PBI 24) | ✅ | Giữ nguyên qua Quyết định 3 (research.md) — OCR vẫn chạy song song |
| Không thêm dependency mới không cần thiết | ✅ | Dùng lại `genai-prompt` hiện có, không nâng version |
| Tier B/Chế độ cơ bản không đổi hành vi | ✅ | Tham số ảnh là tuỳ chọn, các nhánh đó bỏ qua |

## Giai đoạn 0 — Nghiên cứu

Xem `research.md`. Tóm tắt các quyết định chính:

- **Quyết định 1**: Dùng `GenerateContentRequest.Builder(ImagePart, TextPart)` có sẵn trong `genai-prompt:1.0.0-beta4` (đã kiểm chứng bằng `javap` trên jar thật) — không thêm dependency.
- **Quyết định 2**: Giữ nguyên phần hướng dẫn JSON 5 khoá trong prompt, chỉ bỏ đoạn văn bản OCR khi có ảnh đính kèm.
- **Quyết định 3**: OCR vẫn chạy song song ở Tier A, chỉ dùng cho fallback bộ luật + đối chiếu số tiền ngân hàng, không còn đưa vào prompt.
- **Quyết định 4**: Thêm tham số ảnh **tuỳ chọn** vào seam `ScanLlm`/`ReceiptExtractor` thay vì tạo interface song song.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: không áp dụng — không có thực thể/bảng dữ liệu mới hay thay đổi.
- **Hợp đồng giao diện**: xem `contracts/tier-a-image-input.md` (kênh nền tảng `genAiGenerate` + seam Dart nội bộ).
- **Kịch bản khởi động nhanh**: xem `quickstart.md`.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn | ✅ | Không đổi so với trước thiết kế |
| Fallback AI→bộ luật | ✅ | `contracts/tier-a-image-input.md` §Bất biến giữ nguyên cơ chế lỗi/timeout |
| Không thêm dependency | ✅ | Xác nhận API đã tồn tại trong jar hiện tại |
| Tier B/Chế độ cơ bản không đổi | ✅ | Tham số tuỳ chọn, `GemmaLlm`/`RuleBasedExtractor` không sửa logic |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── android/app/src/main/kotlin/com/sorathuchi/sora_thu_chi/
│   └── GenAiChannel.kt                  # sửa: nhận "image" (ByteArray?) trong genAiGenerate, build request multimodal khi có ảnh
├── lib/core/scan/
│   ├── llm_extractor.dart               # sửa: ScanLlm.generate + ReceiptExtractor.extract thêm tham số ảnh tuỳ chọn; buildScanPrompt tách bản có/không kèm ảnh
│   └── receipt_extractor.dart           # sửa: chữ ký ReceiptExtractor.extract + RuleBasedExtractor (bỏ qua tham số ảnh)
├── lib/data/platform/
│   └── gemini_nano_llm.dart             # sửa: truyền ảnh xuống kênh nền tảng khi có
├── lib/screens/scan/
│   └── scan_processing_screen.dart      # sửa: truyền `processed` (bytes) vào extractor.extract(...)
└── test/
    ├── core/scan/llm_extractor_test.dart              # sửa/thêm: case gọi kèm ảnh, prompt không còn text khi có ảnh
    ├── data/platform/gemini_nano_llm_test.dart         # thêm (nếu chưa có): truyền ảnh xuống channel đúng key
    └── screens/scan/scan_processing_screen_test.dart   # sửa: assert extractor nhận được bytes ảnh
```

## Rủi ro & ngoại lệ có lý do

- **Rủi ro**: API `ImagePart`/`GenerateContentRequest.Builder` đang ở bản beta (`1.0.0-beta4`) — có thể đổi chữ ký ở bản beta sau. Chấp nhận vì đây là dependency đã chọn từ PBI 36, không nâng version trong phạm vi PBI này.
- **Rủi ro**: Ảnh lớn có thể tăng thời gian phản hồi AI so với chỉ gửi text — vẫn nằm trong timeout 10 giây hiện có (đã tính vào SC-002/quickstart bước 5); không cần đổi ngưỡng.
- Không có ngoại lệ vi phạm nguyên tắc dự án cần biện minh.
