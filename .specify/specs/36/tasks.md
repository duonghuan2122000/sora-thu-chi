# Danh sách Task: Quét ảnh thông báo giao dịch ngân hàng

**Mã PBI**: 36
**Nguồn**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [quickstart.md](./quickstart.md)

## Pha 1: Setup

- [X] T001 Chạy `flutter test` toàn bộ tại `app/sora_thu_chi/` để xác nhận baseline xanh trước khi bắt đầu (không thêm dependency/thư mục mới — PBI này không cần bước khởi tạo)

## Pha 2: Foundational

*Chặn mọi User Story bên dưới — cả 3 story đều đọc/ghi field mới này.*

- [X] T002 [P] Thêm field `bool typeNeedsReview = false` vào `ScanExtraction` (+ cập nhật `copyWith`, `toJson`) tại `app/sora_thu_chi/lib/core/scan/scan_result.dart` (data-model.md, R8)
- [X] T003 [P] Viết test cho field mới: mặc định `false`, `copyWith` giữ/đổi đúng, `toJson` có khoá `typeNeedsReview` tại `app/sora_thu_chi/test/scan_result_test.dart`

## Pha 3: User Story 1 - Nhận diện & trích xuất đúng bằng bộ luật (Ưu tiên: P1)

**Mục tiêu**: Ảnh thông báo ngân hàng (SMS/app/email) quét bằng Chế độ cơ bản (Tier C, không cần AI) ra đúng loại giao dịch (thu/chi theo ghi nợ/ghi có) và đúng số tiền giao dịch — không nhầm số dư. Đây là phần sửa lỗi gốc mà người dùng báo cáo.

**Tiêu chí kiểm thử độc lập**: Chạy `bank_notif_parser_test.dart` độc lập với 4 fixture dựng từ đúng 4 ảnh mẫu đã phát hiện vấn đề — không cần UI, không cần AI, không cần ảnh thật.

- [X] T004 [US1] Viết test `looksLikeBankNotification`: dưới 2 từ khoá → `false`, đủ ≥2 → `true`, text hóa đơn thường → `false` tại `app/sora_thu_chi/test/bank_notif_parser_test.dart` (research.md R2)
- [X] T005 [US1] Viết test `parseBankNotification` trên 4 fixture (SMS biến động số dư "+29.896.000...Số dư 38.677.245", app "(Debit) 44.100...Số dư khả dụng 12.540.601", email "Ghi nợ -40.000...Số dư mới 30.691.405", app "Chuyển tiền thành công 55.000" không có ghi nợ/có rõ) + 1 ca "không đủ căn cứ" → đúng `type`/`amount` (khác số dư)/`typeNeedsReview`/ghi chú, tiếp tục trong cùng `app/sora_thu_chi/test/bank_notif_parser_test.dart` (research.md R3–R6)
- [X] T006 [US1] Cài `bool looksLikeBankNotification(List<ScanTextLine> lines)` tại `app/sora_thu_chi/lib/core/scan/bank_notif_parser.dart` (research.md R2) — cho T004 xanh
- [X] T007 [US1] Cài `ScanExtraction parseBankNotification({required lines, required now, required expenseCategories, required incomeCategories})` cùng file `app/sora_thu_chi/lib/core/scan/bank_notif_parser.dart`: loại dòng "so du" khỏi ứng viên số tiền, ưu tiên số theo vị trí sát dấu +/-/từ khoá ghi nợ-có, suy `type` theo thứ tự ghi nợ→chi/ghi có→thu/chuyển tiền thành công→chi (tin cậy trung bình)/không khớp→chi + `typeNeedsReview=true`, điền ghi chú từ dòng nội dung/người nhận vào field `merchant` (research.md R3–R6) — cho T005 xanh
- [X] T008 [US1] Nối dispatcher trong `RuleBasedExtractor.extract()` tại `app/sora_thu_chi/lib/core/scan/receipt_extractor.dart`: gọi `looksLikeBankNotification(lines)` để chọn `parseBankNotification(...)` hoặc `parseReceipt(...)` (research.md R1)
- [X] T009 [US1] Viết test dispatcher tại `app/sora_thu_chi/test/receipt_extractor_test.dart`: text ngân hàng → gọi nhánh `parseBankNotification`; text hóa đơn → gọi nhánh `parseReceipt` với `typeNeedsReview = false` (hành vi PBI 24 giữ nguyên)
- [X] T010 [US1] Chạy lại toàn bộ `flutter test` tại `app/sora_thu_chi/`, xác nhận `receipt_parser_test.dart` (lưới hồi quy PBI 24) và mọi test cũ vẫn xanh nguyên trạng

## Pha 4: User Story 2 - Cảnh báo "Kiểm tra lại" khi không chắc loại GD (Ưu tiên: P2)

**Mục tiêu**: Khi bộ luật/AI không đủ căn cứ suy loại thu/chi (`typeNeedsReview = true`), màn xác nhận phải nhắc người dùng tự kiểm tra thay vì im lặng dùng mặc định sai.

**Tiêu chí kiểm thử độc lập**: Pump `ScanConfirmScreen` với `ScanExtraction(typeNeedsReview: true/false)` trực tiếp (không cần chạy qua US1/US3 thật) — kiểm tra dòng "Kiểm tra lại" hiện/ẩn đúng.

- [X] T011 [US2] Viết test tại `app/sora_thu_chi/test/scan_confirm_screen_test.dart`: `typeNeedsReview: true` → hiện dòng "Kiểm tra lại" (coral) dưới ô Loại giao dịch; `false` → không hiện; chạm đổi Chi/Thu ở segmented control vẫn hoạt động bình thường khi cờ bật
- [X] T012 [US2] Thêm `_typeReviewHint` (tái dùng style/màu của `_confidenceChip`) hiển thị theo `widget.extraction.typeNeedsReview`, đặt ngay dưới `_typeSegmented(colors)` tại `app/sora_thu_chi/lib/screens/scan/scan_confirm_screen.dart` — cho T011 xanh
- [X] T013 [US2] Xác nhận khoá dịch "Kiểm tra lại" đã tồn tại (dùng lại từ `_confidenceChip` PBI 24) bằng cách chạy `sora_translations_test`; nếu thiếu, thêm khoá EN tại `app/sora_thu_chi/lib/core/locale/sora_translations.dart`

## Pha 5: User Story 3 - Nhánh AI (Tier A/B) đồng bộ hành vi (Ưu tiên: P3)

**Mục tiêu**: Khi bật AI on-device, model cũng tự suy loại thu/chi và trả đúng danh mục theo loại đó — không chỉ nhánh bộ luật mới đúng.

**Tiêu chí kiểm thử độc lập**: `parseLlmReceipt` nhận raw JSON giả lập `"type":"thu"`/`"type":"chi"`/thiếu `type` → kiểm tra độc lập, không cần model AI thật (đã có `ScanLlm` fake sẵn từ PBI 24).

- [X] T014 [US3] Viết test tại `app/sora_thu_chi/test/llm_extractor_test.dart`: `buildScanPrompt` chứa cả danh sách `expenseCategories` và `incomeCategories` gắn nhãn rõ + khoá `"type"` trong JSON yêu cầu; `parseLlmReceipt` đọc `"type":"thu"` → `TxnType.income` + resolve theo `incomeCategories`; đọc `"type":"chi"` → `TxnType.expense` + resolve theo `expenseCategories`; thiếu/giá trị lạ → `TxnType.expense` + `typeNeedsReview = true`
- [X] T015 [US3] Đổi `buildReceiptPrompt(lines, expenseCategories)` → `buildScanPrompt(lines, expenseCategories, incomeCategories)` tại `app/sora_thu_chi/lib/core/scan/llm_extractor.dart`: thêm khoá `"type": "chi"|"thu"` vào JSON yêu cầu kèm định nghĩa rõ ràng, đưa cả 2 danh sách category có gắn nhãn (research.md R7) — cho phần prompt của T014 xanh
- [X] T016 [US3] Sửa `parseLlmReceipt(...)` đọc thêm `type` → set `TxnType` + `typeNeedsReview`; `resolveCategory` chọn đúng danh sách theo `type` đã đọc, cùng file `app/sora_thu_chi/lib/core/scan/llm_extractor.dart` — cho phần parse của T014 xanh
- [X] T017 [US3] Sửa `LlmExtractor.extract()` gọi `buildScanPrompt(lines, expenseCategories, incomeCategories)` (truyền tham số `incomeCategories` đã có sẵn trong chữ ký nhưng đang bị bỏ qua), cùng file `app/sora_thu_chi/lib/core/scan/llm_extractor.dart`
- [X] T018 [US3] Xác nhận fallback AI lỗi/timeout → bộ luật vẫn đúng (không hồi quy FR-011/R7 PBI 24) bằng test hiện có + chạy lại toàn bộ `flutter test`

## Pha cuối: Polish & Cross-cutting

- [X] T019 [P] Chạy `flutter analyze` tại `app/sora_thu_chi/`, sửa mọi cảnh báo phát sinh từ PBI này
- [ ] T020 QA tay theo `quickstart.md` nhóm A–E trên emulator (nhóm F chỉ khi có thiết bị hỗ trợ Tier A/B thật)
- [X] T021 Đồng bộ `wiki-knowledge/` theo skill `sora-wiki`: cập nhật page entity **Giao dịch** (nguồn AI Scan nay nhận diện được cả thu/chi từ ảnh thông báo ngân hàng, không chỉ luôn là chi) + append `wiki-knowledge/log.md` + cập nhật `wiki-knowledge/index.md`
- [X] T022 Tick `checklists/requirements.md` tại `.specify/specs/36/checklists/requirements.md` sau khi toàn bộ task trên xong

## Sơ đồ phụ thuộc

```
Pha 1 (Setup) → Pha 2 (Foundational: T002/T003)
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
  US1 (T004-T010)  US2 (T011-T013)  US3 (T014-T018)
   (độc lập file:    (độc lập file:   (độc lập file:
   bank_notif_parser  scan_confirm_    llm_extractor.dart)
   + receipt_extractor) screen.dart)
        │               │               │
        └───────────────┴───────────────┘
                        ▼
              Pha cuối (T019-T022)
```

US1/US2/US3 chạm **3 file lib/ khác nhau** (`bank_notif_parser.dart`+`receipt_extractor.dart`, `scan_confirm_screen.dart`, `llm_extractor.dart`) và **3 file test khác nhau** ⇒ có thể làm song song sau khi Pha 2 xong. US2 phụ thuộc **cờ** `typeNeedsReview` (Pha 2) chứ không phụ thuộc US1/US3 sinh ra cờ đó thật — test bằng `ScanExtraction` dựng tay là đủ độc lập.

## Chiến lược triển khai

- **MVP đề xuất**: User Story 1 (P1) — đây là phần sửa đúng lỗi người dùng báo cáo (nhận diện sai loại GD + lấy nhầm số dư). Có thể dừng ở đây và coi là "đã sửa được vấn đề gốc" nếu cần giao sớm; US2/US3 nâng cao trải nghiệm và đồng bộ nhánh AI nhưng không phải điều kiện để giải quyết bug ban đầu.
- **Thứ tự giao hàng tăng dần**: Setup/Foundational → US1 (sửa lỗi gốc, QA nhóm A–D quickstart) → US2 (cảnh báo minh bạch khi không chắc) → US3 (đồng bộ nhánh AI, QA nhóm F khi có thiết bị) → Polish (wiki + QA tay đầy đủ + analyze sạch).
- **Chạy song song**: nếu có ≥2 người, sau Pha 2 có thể chia US1/US2/US3 làm đồng thời (file độc lập hoàn toàn); trong mỗi story, task test luôn đi trước task cài đặt tương ứng (TDD nhẹ, theo đúng cấu trúc "Test → cài đặt" của kế hoạch).
