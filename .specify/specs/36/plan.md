# Kế hoạch triển khai: Quét ảnh thông báo giao dịch ngân hàng

**Mã PBI**: 36
**Liên kết spec**: [.specify/specs/36/spec.md](./spec.md)
**Ngày tạo**: 2026-09-15

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter 3.44 (Android + iOS), app **offline hoàn toàn** |
| Framework / Thư viện chính | Không thêm dependency mới. Mở rộng module thuần Dart `lib/core/scan/` (PBI 24) + prompt AI của `LlmExtractor` (chặng 2 PBI 24) |
| Lưu trữ dữ liệu | drift `^2.34.4` — **không đổi schema**, giữ **v10**. Chỉ thêm khoá vào `scan_sessions.parsed_json` (JSON tự do có sẵn) |
| Kiểm thử | `flutter_test` — bổ sung ~4 file test mới + sửa ~4 file hiện có. Toàn bộ logic mới là hàm thuần Dart ⇒ không cần plugin |
| Nền tảng triển khai | Build local, không đổi cấu hình native (không đụng Android/iOS manifest, không kênh native mới) |
| Ràng buộc hiệu năng | Không phát sinh yêu cầu mới — tái dùng đúng pipeline OCR → trích xuất → xác nhận đã có (SC-001 PBI 24 vẫn áp dụng) |
| Ràng buộc khác | Tiếng Việt có dấu cho UI/tài liệu/commit; Design System (coral chỉ cho cảnh báo "Kiểm tra lại"); mọi nhãn mới có khoá dịch EN (`sora_translations_test` tự quét) |
| Nguồn chân lý nghiệp vụ | `.specify/specs/36/spec.md` (PBI này) + `.specify/specs/24/*` (seam `ReceiptExtractor`/`ScanExtraction` đang mở rộng) |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ"; toàn bộ quyết định kỹ thuật chốt ở `research.md` (R1…R9).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** ⇒ đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`/PBI 24.

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn | ✅ | Không thêm dependency, không request mạng; mọi trích xuất vẫn chạy trên máy (bộ luật thuần Dart + AI on-device đã có) |
| Ngôn ngữ tiếng Việt có dấu | ✅ | Nhãn "Kiểm tra lại" tái dùng khoá dịch có sẵn từ PBI 24, không thêm khoá tiếng Việt cứng ngoài i18n |
| Seam/kiến trúc đã chốt ở PBI 24 (`ReceiptExtractor`, `ScanExtraction`, màn xác nhận dùng chung) | ✅ | Mở rộng đúng trong seam có sẵn — không tạo interface/màn mới, không đổi luồng điều phối `scan_flow.dart` |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | FR-004: giao dịch đọc từ ảnh ngân hàng chỉ ra **thu** hoặc **chi**, không bao giờ gán `TxnType.transfer` |
| Số dư ví là đại lượng suy ra | ✅ | Vẫn ghi qua `addScannedTransaction` có sẵn (PBI 24) — không đổi cách bù `balance` |
| Design system: coral chỉ cho cảnh báo | ✅ | "Kiểm tra lại" ở Loại giao dịch tái dùng đúng `colors.coralOnNeutral` + style `_confidenceChip` hiện có, không thêm màu mới |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Không migration, không đụng bảng nào; chỉ thêm khoá JSON tự do |
| YAGNI / không abstraction sớm | ✅ | Không route/UI/entry-point mới (R1); không field `note` tách riêng (R5); không đổi `type` thành `ScanField<TxnType>` đầy đủ (R8, chỉ 1 bool) |
| Không phá vỡ hành vi PBI 24 cũ | ✅ | `parseReceipt` không đổi; nhánh hóa đơn luôn trả `typeNeedsReview = false` (bất biến #1 trong data-model.md) — mọi test PBI 24 hiện có phải xanh nguyên trạng |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **R1** — Nhận diện nằm ở tầng trích xuất thuần Dart (`RuleBasedExtractor` tự chọn nhánh `parseBankNotification`/`parseReceipt`); nhánh AI không cần phát hiện riêng, để model tự đọc ngữ cảnh.
- **R2** — Phát hiện ảnh ngân hàng: đếm từ khoá tiếng Việt phổ biến (đã chuẩn hoá bỏ dấu), ngưỡng ≥ 2 khớp mới coi là ảnh ngân hàng (tránh dương tính giả với hóa đơn).
- **R3** — Chọn số tiền giao dịch: loại hẳn dòng "số dư" khỏi ứng viên; ưu tiên số theo vị trí sát dấu +/- hoặc từ khoá ghi nợ/ghi có/số tiền; fallback lấy số **đầu tiên** (không phải lớn nhất như hóa đơn).
- **R4** — Suy loại GD theo thứ tự: ghi nợ/debit/dấu trừ ⇒ chi; ghi có/credit/dấu cộng ⇒ thu; "chuyển tiền thành công" không rõ dấu ⇒ chi mặc định (tin cậy trung bình); không khớp gì ⇒ giữ chi + bật `typeNeedsReview`.
- **R5** — Ghi chú tái dùng nguyên field `merchant` sẵn có (không field mới) — điền nội dung GD/người nhận thay vì tên cửa hàng.
- **R6** — Không suy category cho GD ngân hàng ở nhánh bộ luật; để trống, người dùng tự chọn.
- **R7** — Prompt AI mở rộng thành `buildScanPrompt` (hỏi thêm `type`, nhận cả 2 danh sách category); `parseLlmReceipt` đọc thêm `type` + set `typeNeedsReview`.
- **R8** — Thêm 1 field `bool typeNeedsReview` vào `ScanExtraction` (không đổi `type` thành `ScanField<TxnType>` đầy đủ — diện sửa quá rộng so với lợi ích).
- **R9** — Không đổi schema DB; chỉ thêm khoá JSON trong `parsed_json` sẵn có; schema giữ v10.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — mở rộng `ScanExtraction` (+1 field `bool`), 2 hàm thuần mới, 4 luật bất biến.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không API/CLI lộ ra ngoài (đồng nhất mọi PBI trước).
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — 6 nhóm QA tay A–F dựa trực tiếp trên các ảnh mẫu thật (SMS/app/email ACB) đã dùng để phát hiện vấn đề gốc.

### Kiến trúc chi tiết

**1. Tầng nghiệp vụ thuần — `lib/core/scan/` (1 file mới, 2 file sửa)**

| File | Thay đổi |
|---|---|
| `bank_notif_parser.dart` **(mới)** | `bool looksLikeBankNotification(List<ScanTextLine> lines)` (R2) + `ScanExtraction parseBankNotification({required lines, required now, required expenseCategories, required incomeCategories})` (R3–R6) — cùng chữ ký với `parseReceipt` để dispatcher hoán đổi được |
| `scan_result.dart` **(sửa)** | `ScanExtraction` thêm field `bool typeNeedsReview = false`; `copyWith` + `toJson()` cập nhật theo (R8) |
| `receipt_extractor.dart` **(sửa ~6 dòng)** | `RuleBasedExtractor.extract()` gọi `looksLikeBankNotification(lines)` để chọn `parseBankNotification` hoặc `parseReceipt` (R1) |

Không đọc DB/mạng/`BuildContext` ⇒ test thuần, giống mọi module `core/scan/` khác.

**2. Nhánh AI — `lib/core/scan/llm_extractor.dart` (sửa)**

- `buildReceiptPrompt(lines, expenseCategories)` → `buildScanPrompt(lines, expenseCategories, incomeCategories)`: thêm khoá `"type": "chi"|"thu"` vào JSON yêu cầu (định nghĩa rõ ràng trong prompt), đưa cả 2 danh sách category có gắn nhãn (R7).
- `parseLlmReceipt(...)` đọc thêm `type` → set `TxnType` tương ứng + `typeNeedsReview = true` khi thiếu/giá trị lạ; `resolveCategory` chọn đúng danh sách theo `type` đã đọc được (thay vì luôn `expenseCategories`).
- `LlmExtractor.extract()` gọi `buildScanPrompt(lines, expenseCategories, incomeCategories)` — truyền `incomeCategories` (tham số đã có sẵn trong chữ ký `extract`, hiện đang bị bỏ qua).

**3. Màn xác nhận — `lib/screens/scan/scan_confirm_screen.dart` (sửa ~15 dòng)**

- Đọc `widget.extraction.typeNeedsReview` → khi `true`, hiển thị dòng "Kiểm tra lại" (coral) ngay dưới `_typeSegmented(...)`, dùng lại đúng style chữ của `_confidenceChip` (tách 1 hàm nhỏ `_typeReviewHint` in ra `Text` cùng style, vì `_confidenceChip` nhận `ScanField<dynamic>` còn cờ này là `bool` — không ép kiểu gượng ép).
- `_finalExtraction()` giữ `typeNeedsReview: false` (người dùng đã xác nhận/sửa xong ở màn này — cờ chỉ có ý nghĩa **trước** khi xem, không cần lưu lại trạng thái "chưa chắc" sau khi đã qua xác nhận).
- Không đổi field/luồng nào khác (6 trường, nút lưu, cảnh báo trùng, khoanh vùng ảnh — nguyên trạng PBI 24).

**4. i18n — `lib/core/locale/sora_translations.dart` (sửa, +1 khóa)**

Thêm khoá "Kiểm tra lại" nếu chưa có sẵn (PBI 24 đã dùng chuỗi này cho `_confidenceChip` → **khả năng cao đã tồn tại**, việc thi công chỉ cần xác nhận lại, không chắc phải thêm mới).

**5. Test**

| File | Nội dung |
|---|---|
| `test/bank_notif_parser_test.dart` **(mới)** | `looksLikeBankNotification`: dưới 2 từ khoá → `false`, đủ 2+ → `true`, hóa đơn thường (không từ khoá ngân hàng) → `false`. `parseBankNotification` trên **4 fixture dựng từ đúng 4 ảnh mẫu thực tế đã phát hiện vấn đề** (SMS biến động số dư, app "Debit", email "Ghi nợ", app "Chuyển tiền thành công"): đúng `type`, đúng `amount` (khác số dư), `typeNeedsReview` đúng theo từng ca, ghi chú điền đúng nội dung/người nhận khi đọc được. Thêm ca "không đủ căn cứ" (không ghi nợ/có/chuyển tiền) → `typeNeedsReview = true` |
| `test/scan_result_test.dart` **(mới hoặc bổ sung nếu đã có)** | `typeNeedsReview` mặc định `false`; `copyWith`/`toJson` round-trip đúng khoá mới |
| `test/receipt_extractor_test.dart` **(mới hoặc bổ sung)** | `RuleBasedExtractor` với text hóa đơn → gọi `parseReceipt` (giữ hành vi cũ, `typeNeedsReview = false`); với text ngân hàng → gọi `parseBankNotification` |
| `test/llm_extractor_test.dart` **(sửa nếu đã có, hoặc mới)** | `buildScanPrompt` chứa cả 2 danh sách category + khoá `type`; `parseLlmReceipt` đọc `"type":"thu"` → `TxnType.income` + đúng danh sách category dùng để resolve; thiếu `type` → mặc định `expense` + `typeNeedsReview = true`; fallback AI lỗi/timeout → bộ luật (không hồi quy R7 PBI 24) |
| `test/scan_confirm_screen_test.dart` **(sửa)** | Thêm ca: `typeNeedsReview = true` → hiện dòng "Kiểm tra lại" dưới Loại giao dịch; `false` → không hiện; đổi loại tay ở segmented control vẫn hoạt động bình thường (không bị cờ này chặn) |
| `test/receipt_parser_test.dart` **(không đổi)** | Lưới hồi quy: mọi ca hóa đơn cũ vẫn đúng nguyên trạng (đảm bảo R1 không phá `parseReceipt`) |

Ghi chú test: dùng fixture text lấy trực tiếp từ nội dung 4 ảnh mẫu (đã ẩn số tài khoản/tên thật khi viết vào test, chỉ giữ cấu trúc câu chữ cần thiết để kiểm bộ luật) — không cần ảnh thật, vì toàn bộ logic PBI này nằm ở tầng text đã OCR xong.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline, không dependency mới | ✅ | Toàn bộ thay đổi là Dart thuần + 1 field mới, không package/kênh native nào |
| Không phá vỡ hành vi PBI 24 | ✅ | `parseReceipt`/`buildReceiptPrompt` cũ không bị xoá logic, chỉ được **bọc thêm** nhánh mới; test PBI 24 hiện có phải xanh nguyên trạng (kiểm bằng `flutter test` toàn bộ trước khi coi là xong) |
| Thu/chi/chuyển khoản đúng nghĩa | ✅ | `parseBankNotification`/`buildScanPrompt` chỉ sinh `income`/`expense`, không bao giờ `transfer` (R4, luật bất biến #2) |
| Design system + i18n | ✅ | "Kiểm tra lại" tái dùng màu/khoá dịch có sẵn, không thêm màu/hằng số mới |
| YAGNI / không abstraction sớm | ✅ | Không entry-point mới, không field `note` tách riêng, không `ScanField<TxnType>` đầy đủ — mỗi quyết định đều có lý do loại phương án phức tạp hơn (research.md) |
| Không sửa dữ liệu ngoài phạm vi | ✅ | Không migration, không đụng bảng/cột nào |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/scan/
│   │   ├── bank_notif_parser.dart          # MỚI — looksLikeBankNotification + parseBankNotification
│   │   ├── scan_result.dart                # SỬA — ScanExtraction +typeNeedsReview
│   │   ├── receipt_extractor.dart          # SỬA — RuleBasedExtractor chọn nhánh (R1)
│   │   └── llm_extractor.dart              # SỬA — buildScanPrompt + parseLlmReceipt đọc type
│   └── screens/scan/
│       └── scan_confirm_screen.dart        # SỬA — dòng "Kiểm tra lại" dưới Loại giao dịch
└── test/
    ├── bank_notif_parser_test.dart         # MỚI
    ├── scan_result_test.dart               # MỚI (nếu chưa có sẵn cho ScanExtraction)
    ├── receipt_extractor_test.dart         # MỚI (nếu chưa có sẵn cho dispatcher)
    ├── llm_extractor_test.dart             # MỚI/SỬA
    ├── scan_confirm_screen_test.dart       # SỬA
    └── receipt_parser_test.dart            # KHÔNG ĐỔI — lưới hồi quy PBI 24
```

Không tạo `contracts/`: dự án thuần nội bộ, không có giao diện lộ ra ngoài.

## Rủi ro & ngoại lệ có lý do

1. **Heuristic ≥ 2 từ khoá vẫn có thể sai** với ngân hàng dùng thuật ngữ lạ hoặc ảnh chụp thiếu ngữ cảnh (chỉ có số tiền, không "so du"/"giao dich"). **Giảm nhẹ**: sai theo hướng an toàn — rơi về `parseReceipt` (loại chi, cần xem lại thủ công ở màn xác nhận như hành vi cũ), không có ca nào "mất dữ liệu" hay tự lưu sai mà không qua xác nhận (FR-008/SC-003).
2. **R3 (số tiền đầu tiên thay vì lớn nhất) có thể sai** nếu ngân hàng đổi thứ tự nêu số tiền/số dư trong câu. **Giảm nhẹ**: SC-001/SC-002 chỉ yêu cầu ≥ 90%, không 100%; độ tin cậy `medium` (không phải `high`) cho số tiền nhánh ngân hàng ⇒ người dùng luôn thấy nhắc kiểm tra khi cần.
3. **`typeNeedsReview` không có "độ tin cậy 3 mức"** như field khác (R8) — quyết định có chủ đích giảm phạm vi sửa, nhưng nghĩa là mọi ca "không chắc" đều hiển thị y hệt nhau (không phân biệt "khá chắc" vs "hoàn toàn không biết"). **Giảm nhẹ**: đúng tinh thần FR-002/edge-case #3 của spec (chỉ yêu cầu "không đoán bừa", không yêu cầu phân cấp độ tin cậy cho trường này); nếu sau này cần chi tiết hơn, nâng cấp thành `ScanField<TxnType>` là thay đổi cục bộ, không phá cấu trúc đã có.
4. **Nhánh AI (R7) không tách rule phát hiện ảnh ngân hàng riêng** — phụ thuộc hoàn toàn vào khả năng đọc hiểu ngữ cảnh của model. **Giảm nhẹ**: đúng bản chất seam `ReceiptExtractor` (fallback AI→bộ luật trong cùng try/catch, FR-011 PBI 24) — nếu AI trả sai/lỗi, luôn rơi về bộ luật đã kiểm chứng riêng ở R1–R6; QA nhóm F (quickstart) chỉ chạy khi có thiết bị hỗ trợ, không chặn hoàn thành PBI.
5. **Không có dữ liệu mẫu đa dạng ngân hàng** để hiệu chỉnh từ khoá (R2 chỉ dựa trên 4 ảnh mẫu của 1 ngân hàng). **Giảm nhẹ**: từ khoá chọn ở mức tổng quát tiếng Việt (không cứng theo ACB — đúng lựa chọn đã chốt), QA tay nhóm A–D dùng đúng ảnh mẫu gốc; nếu phát sinh sai với ngân hàng khác, bổ sung từ khoá là thay đổi cục bộ trong `bank_notif_parser.dart`, không ảnh hưởng kiến trúc.
