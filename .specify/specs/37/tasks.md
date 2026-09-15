# Danh sách Task: Tier A đọc ảnh trực tiếp (Gemini Nano đa phương thức)

**Mã PBI**: 37
**Nguồn**: plan.md, spec.md, research.md, contracts/tier-a-image-input.md, quickstart.md

> **Ghi chú thi công**: repo có test **phẳng** trong `app/sora_thu_chi/test/` (không có thư mục con `core/scan/`, `data/platform/`, `screens/scan/` như plan.md giả định) — các task test dưới đây đã thực hiện tại đường dẫn thật: `test/llm_extractor_test.dart`, `test/gemini_nano_llm_test.dart` (mới), `test/scan_processing_screen_test.dart`.

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: có thể chạy song song (khác file, không phụ thuộc task chưa xong)
- `[Story]`: bắt buộc ở pha User Story (VD `[US1]`), không dùng ở Setup/Foundational/Polish

## Pha 1: Setup

- [X] T001 Xác nhận lại trong `app/sora_thu_chi/android/app/build.gradle.kts` dependency `com.google.mlkit:genai-prompt:1.0.0-beta4` đã có sẵn (không cần thêm/nâng version) — chỉ kiểm tra, không sửa nếu đã đúng.

## Pha 2: Foundational

*(Đổi chữ ký seam dùng chung cho mọi story — phải xong trước khi code hành vi đọc ảnh)*

- [X] T002 Thêm tham số ảnh tuỳ chọn (`Uint8List? image`, mặc định `null`) vào `ScanLlm.generate` tại `app/sora_thu_chi/lib/core/scan/llm_extractor.dart`.
- [X] T003 Thêm tham số ảnh tuỳ chọn vào `ReceiptExtractor.extract` tại `app/sora_thu_chi/lib/core/scan/receipt_extractor.dart`; `RuleBasedExtractor.extract` nhận tham số nhưng bỏ qua (không đổi logic).
- [X] T004 [P] Cập nhật `GemmaLlm` (Tier B) tại `app/sora_thu_chi/lib/data/platform/gemma_llm.dart` để khớp chữ ký `ScanLlm.generate` mới, bỏ qua tham số ảnh, hành vi không đổi.
- [X] T005 Thêm getter `bool get supportsImage` trên `ScanLlm` tại `app/sora_thu_chi/lib/core/scan/llm_extractor.dart` (mặc định `false`); `GeminiNanoLlm.supportsImage = true` (`gemini_nano_llm.dart`), `GemmaLlm.supportsImage = false` (`gemma_llm.dart`, khai báo tường minh vì `implements` không kế thừa default method).

## Pha 3: User Story 1 - Tier A gửi ảnh trực tiếp cho AI đọc (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Ở Tier A, ảnh đã tiền xử lý được gửi kèm hướng dẫn JSON cho Gemini Nano đọc trực tiếp, không còn nhét văn bản OCR vào prompt (FR-001, FR-003, FR-006).
**Tiêu chí kiểm thử độc lập**: Quét một hóa đơn rõ nét ở Tier A → màn xác nhận hiển thị đúng loại/số tiền/ngày/cửa hàng/danh mục; kiểm tra qua test rằng prompt gửi cho `ScanLlm` khi có ảnh không còn chứa danh sách dòng OCR.

- [X] T006 [US1] Sửa `buildScanPrompt` tại `app/sora_thu_chi/lib/core/scan/llm_extractor.dart`: thêm tham số `includeText` — `false` ⇒ bỏ đoạn văn bản OCR, thay bằng câu dẫn ngắn nói nội dung cần đọc nằm trong ảnh đính kèm; giữ nguyên toàn bộ phần hướng dẫn JSON 5 khoá và danh sách danh mục.
- [X] T007 [US1] Sửa `LlmExtractor.extract` tại `app/sora_thu_chi/lib/core/scan/llm_extractor.dart`: khi `_llm.supportsImage == true` và có tham số ảnh, dựng prompt với `includeText: false` và gọi `_llm.generate(prompt, image: ...)`; khi không, giữ nguyên hành vi dựng prompt từ text OCR như cũ.
- [X] T008 [US1] Sửa `GeminiNanoLlm.generate` tại `app/sora_thu_chi/lib/data/platform/gemini_nano_llm.dart`: khi có ảnh, gọi kênh nền tảng `genAiGenerate` kèm key `image` (bytes); khi không có ảnh, giữ nguyên lời gọi chỉ `prompt` như cũ.
- [X] T009 [US1] Sửa `GenAiChannel.kt` tại `app/sora_thu_chi/android/app/src/main/kotlin/com/sorathuchi/sora_thu_chi/GenAiChannel.kt`: đọc thêm argument `image` (ByteArray?) từ `call`; có ảnh ⇒ dựng `ImagePart(image)` + `TextPart(prompt)` rồi `GenerateContentRequest.Builder(imagePart, textPart).build()` gọi `model.generateContent(request)`; không có ảnh ⇒ giữ `model.generateContent(prompt)` như cũ.
- [X] T010 [US1] Sửa `ScanProcessingScreen._run` tại `app/sora_thu_chi/lib/screens/scan/scan_processing_screen.dart`: truyền `processed` (bytes ảnh đã tiền xử lý) vào `extractor.extract(..., image: processed)`.
- [X] T011 [P] [US1] Thêm test tại `app/sora_thu_chi/test/llm_extractor_test.dart` (nhóm "LlmExtractor đọc ảnh trực tiếp (PBI 37)" + case `includeText: false` trong nhóm `buildScanPrompt`): case `supportsImage = true` + có ảnh → prompt không chứa văn bản OCR, `lastImage` đúng bytes; case `supportsImage = true` không ảnh, và `supportsImage = false` có ảnh → vẫn dùng văn bản OCR như cũ.
- [X] T012 [P] [US1] Tạo mới `app/sora_thu_chi/test/gemini_nano_llm_test.dart` (mock `kDeviceProbeChannel` qua `TestDefaultBinaryMessengerBinding`): xác nhận `invokeMethod` gọi `genAiGenerate` kèm đúng key `image` khi truyền bytes; không kèm key đó khi không có ảnh; `engine`/`supportsImage` đúng giá trị.
- [X] T013 [P] [US1] Sửa test tại `app/sora_thu_chi/test/scan_processing_screen_test.dart`: thêm `_RecordingExtractor` (implements `ReceiptExtractor`) + test "truyền đúng bytes ảnh đã tiền xử lý cho extractor" xác nhận `extractor.extract` nhận đúng `image`.

## Pha 4: User Story 2 - Vẫn rơi về bộ luật khi AI lỗi/treo (Ưu tiên: P2)

**Mục tiêu**: OCR tiếp tục chạy song song ở Tier A; khi AI lỗi/treo quá thời gian chờ/trả kết quả không đọc được, hệ thống rơi về bộ luật dùng kết quả OCR đã có — không đổi cơ chế fallback gốc của PBI 24 (FR-002, FR-004).
**Tiêu chí kiểm thử độc lập**: Giả lập `ScanLlm.generate` ném lỗi/timeout khi có ảnh đính kèm → `LlmExtractor.extract` vẫn trả kết quả từ `RuleBasedExtractor` dùng dòng OCR, `engine = ruleBased`.

- [X] T014 [US2] Thêm test tại `app/sora_thu_chi/test/llm_extractor_test.dart`: case ảnh đính kèm + `_llm.generate` ném lỗi hoặc quá `timeout` → `extract` trả về kết quả bộ luật dùng `lines` OCR gốc, `engine = ScanEngine.ruleBased`.
- [X] T015 [US2] Xác nhận tại `app/sora_thu_chi/lib/screens/scan/scan_processing_screen.dart`: `ocr.readText` vẫn luôn chạy trước `extractor.extract` bất kể Tier — code hiện có (T010) đã đúng, không cần sửa thêm.
- [X] T016 [P] [US2] Xác nhận test có sẵn tại `app/sora_thu_chi/test/scan_processing_screen_test.dart` ("OCR không đọc được gì → thông báo + 2 nút, không ghi gì") đã bao phủ đúng case này (OCR rỗng ⇒ `_unreadable = true`, không gọi `extractor.extract`) — không cần thêm test trùng lặp.

## Pha 5: User Story 3 - Tier B, Chế độ cơ bản và đối chiếu ngân hàng không đổi (Ưu tiên: P3)

**Mục tiêu**: Xác nhận hồi quy — Tier B (Gemma 3n), Chế độ cơ bản (bộ luật), và cơ chế đối chiếu số tiền ảnh ngân hàng (`_reconcileAmount`) giữ nguyên hành vi như trước PBI 37 (FR-005, phần bất biến trong contracts/tier-a-image-input.md).
**Tiêu chí kiểm thử độc lập**: Chạy lại toàn bộ test hiện có của `receipt_extractor`, `bank_notif_parser`, `llm_extractor` — không có test nào đổi kỳ vọng ngoài phần mở rộng ở US1/US2, tất cả pass.

- [X] T017 [P] [US3] Chạy `flutter test` toàn bộ — xác nhận không có assertion cũ nào phải sửa ngoài các thay đổi chữ ký ở Pha 2 (T002-T005); không có test `gemma_llm`/`bank_notif_parser`/`receipt_extractor` riêng biệt trong repo (đã kiểm tra bằng grep) nên hồi quy được xác nhận qua toàn bộ suite (1330/1330 pass).
- [X] T018 [P] [US3] Rà lại `_reconcileAmount` tại `app/sora_thu_chi/lib/core/scan/llm_extractor.dart` — xác nhận không cần sửa (vẫn nhận `ScanField<int> llmAmount` + `List<ScanTextLine> lines` như cũ, độc lập với việc `llmAmount` được suy ra từ ảnh hay từ text).

## Pha cuối: Polish & Cross-cutting

- [X] T019 Chạy `flutter analyze` tại `app/sora_thu_chi/` — **sạch, không issue**.
- [X] T020 Chạy toàn bộ `flutter test` tại `app/sora_thu_chi/` — **1330/1330 pass** (baseline trước PBI 37 không có test đỏ tồn đọng vào thời điểm này — khác ghi chú "1 test đỏ có sẵn" ở các PBI trước, đã kiểm tra lại: suite hiện tại xanh toàn bộ).
- [X] T021 QA tay theo `.specify/specs/37/quickstart.md` mục 2 (các bước 1-6) trên emulator/máy thật hỗ trợ Tier A — người dùng xác nhận đạt.
- [X] T022 Rà `wiki-knowledge/`: cập nhật [[Giao dịch]] §"Chọn engine & fallback" (thêm dòng cơ chế Tier A đọc ảnh trực tiếp) + [[Stack kỹ thuật]] (dòng `genai-prompt` + đoạn kênh `sora_thu_chi/device_probe`) + `index.md` (dòng tóm tắt PBI 24/36) + `log.md` (mục `[2026-09-15] implement`).

## Sơ đồ phụ thuộc

```text
Setup (T001) → Foundational (T002-T005) → US1 (T006-T013) → US2 (T014-T016) → US3 (T017-T018) → Polish (T019-T022)
```

US2 phụ thuộc US1 (cần seam ảnh đã có để test đường lỗi/timeout khi có ảnh). US3 chỉ cần Foundational xong (kiểm tra hồi quy chữ ký), có thể chạy sớm hơn nhưng đặt sau US1/US2 để không che lấp lỗi thật của story chính.

## Ví dụ chạy song song

```text
# Trong US1, sau khi T006-T010 xong, 3 task test sau chạy song song (khác file):
T011 [P] [US1] test/llm_extractor_test.dart
T012 [P] [US1] test/gemini_nano_llm_test.dart
T013 [P] [US1] test/scan_processing_screen_test.dart

# Trong US3, cả 2 task đều chỉ đọc/chạy test, không sửa cùng file:
T017 [P] [US3] ...
T018 [P] [US3] ...
```

## Chiến lược triển khai

- **MVP**: User Story 1 (T001-T013) — đã đủ để Tier A đọc ảnh trực tiếp và có test bảo vệ hành vi mới.
- **Giao hàng tăng dần**: US1 (đọc ảnh) → US2 (đảm bảo fallback không vỡ) → US3 (đảm bảo hồi quy Tier B/cơ bản/đối chiếu ngân hàng) → Polish (analyze/test toàn bộ/QA tay/wiki).

## Kết quả thi công (2026-09-15)

- **22/22 task hoàn tất** — T021 QA tay đã được người dùng xác nhận đạt trên thiết bị thật.
- File đã sửa: `lib/core/scan/llm_extractor.dart`, `lib/core/scan/receipt_extractor.dart`, `lib/data/platform/gemma_llm.dart`, `lib/data/platform/gemini_nano_llm.dart`, `lib/screens/scan/scan_processing_screen.dart`, `android/app/src/main/kotlin/com/sorathuchi/sora_thu_chi/GenAiChannel.kt`.
- File test đã sửa: `test/llm_extractor_test.dart`, `test/scan_processing_screen_test.dart`.
- File test mới: `test/gemini_nano_llm_test.dart`.
- Wiki đã sync: `wiki-knowledge/entity/Giao dịch.md`, `wiki-knowledge/concept/Stack kỹ thuật.md`, `wiki-knowledge/index.md`, `wiki-knowledge/log.md`.
- `flutter analyze`: sạch. `flutter test`: **1330/1330 pass**.
