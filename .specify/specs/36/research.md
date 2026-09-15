# Nghiên cứu kỹ thuật: PBI 36 — Quét ảnh thông báo giao dịch ngân hàng

## R1 — Điểm phân nhánh nhận diện loại ảnh

**Quyết định**: Nhận diện nằm ở **tầng trích xuất thuần Dart** (`ReceiptExtractor`), không phải ở UI/luồng điều phối. `RuleBasedExtractor.extract()` gọi `looksLikeBankNotification(lines)` trước; đúng → `parseBankNotification(...)`, sai → `parseReceipt(...)` (không đổi). Nhánh AI (`LlmExtractor`) không cần phát hiện tách bạch — để model tự đọc ngữ cảnh và trả `type`/`amount` đúng, vì model đã "đọc hiểu" toàn văn bản, không cần rule riêng.

**Lý do**: Giữ đúng seam đã có từ PBI 24 (`ReceiptExtractor` 1 interface 2 impl, màn xác nhận dùng chung 1 định dạng kết quả) — không thêm điểm vào/luồng mới (đúng lựa chọn "tự động nhận diện trong luồng quét hiện có" đã chốt ở spec).

**Phương án khác đã xem xét**: Thêm bước chọn loại ảnh thủ công ở UI (màn `scan-01`) — bị loại vì spec đã chốt "tự động nhận diện", không cần lựa chọn tay.

## R2 — Ngưỡng phát hiện ảnh ngân hàng

**Quyết định**: Hàm thuần `looksLikeBankNotification(List<ScanTextLine>)` gộp toàn văn bản OCR, chuẩn hoá bằng `normalizeForMatch` (đã có, bỏ dấu + thường hoá), đếm số từ khoá trong tập cố định (`so du`, `tai khoan`, `ghi no`, `ghi co`, `giao dich`, `bien dong so du`, `(debit)`, `(credit)`, `ma giao dich`, `so tien`) — khớp **≥ 2** từ khoá mới coi là ảnh ngân hàng.

**Lý do**: Một từ khoá đơn lẻ (VD "giao dịch") có thể xuất hiện tình cờ trên hóa đơn cửa hàng (máy POS in "Mã giao dịch: ..."), gây dương tính giả. Yêu cầu ≥ 2 giảm rủi ro trong khi vẫn nhận đúng mọi ảnh mẫu thực tế (mỗi ảnh mẫu khớp 3–5 từ khoá).

**Phương án khác đã xem xét**: Regex tên ngân hàng cụ thể (ACB/VCB/Techcombank/...) — bị loại vì spec chốt "tổng quát, không giới hạn ngân hàng cụ thể"; danh sách tên ngân hàng sẽ không đầy đủ và phải bảo trì liên tục.

## R3 — Chọn đúng số tiền giao dịch (không phải số dư)

**Quyết định**: Trong `parseBankNotification`, **loại bỏ hoàn toàn** mọi dòng chứa từ khoá "so du" (số dư/số dư khả dụng) khỏi tập ứng viên số tiền — khác hẳn `_isNonAmountLine` của hóa đơn (chỉ loại dòng ngày/ĐT/MST). Trong các dòng còn lại, ưu tiên theo thứ tự: (1) số tiền có dấu `+`/`-` liền trước, hoặc nằm cùng dòng với `(debit)`/`(credit)`/`ghi no`/`ghi co`/`so tien`; (2) nếu không có, lấy số tiền **đầu tiên** xuất hiện trong văn bản (không phải "lớn nhất" như bộ luật hóa đơn).

**Lý do**: Ảnh mẫu cho thấy số dư gần như luôn **lớn hơn** số tiền giao dịch (số dư tích lũy > 1 giao dịch đơn lẻ) — heuristic "số lớn nhất" của hóa đơn (đúng cho hóa đơn, sai cho ngân hàng) sẽ chọn nhầm số dư. Ưu tiên "đầu tiên" giữ đúng vì thông báo ngân hàng luôn nêu số tiền giao dịch trước, số dư sau ("... + 29,896,000 lúc ... Số dư 38,677,245").

**Phương án khác đã xem xét**: Vẫn dùng "số lớn nhất" nhưng chỉ loại dòng "so du" — không đủ, vì đôi khi số dư nằm cùng dòng với số tiền giao dịch (ảnh mẫu 1: "...+ 29,896,000 lúc 13:49... Số dư 38,677,245" nằm 1 dòng liền) ⇒ phải tách theo **vị trí trong dòng** (số ngay sau dấu `+`/`-`), không tách theo dòng.

## R4 — Suy loại giao dịch (thu/chi) từ ghi nợ/ghi có

**Quyết định**: Thứ tự ưu tiên trên đoạn văn bản quanh số tiền đã chọn (R3):
1. Chứa `ghi no`/`debit`/dấu `-` ngay trước số tiền ⇒ **chi**.
2. Chứa `ghi co`/`credit`/dấu `+` ngay trước số tiền ⇒ **thu**.
3. Không khớp (1)/(2) nhưng có `chuyen tien thanh cong` (xác nhận chuyển tiền) ⇒ **chi** (tiền luôn rời tài khoản nguồn khi ảnh là xác nhận chuyển đi), độ tin cậy **trung bình**.
4. Không khớp gì ⇒ giữ mặc định **chi** (FR-025 cũ vẫn là baseline an toàn) nhưng bật cờ `typeNeedsReview = true` để màn xác nhận nhắc người dùng tự kiểm tra (FR-002/edge-case #3 của spec).

**Lý do**: Đúng FR-004 — không tự gán "chuyển khoản nội bộ" của app; ảnh "Chuyển tiền thành công" tới bên thứ ba (ảnh mẫu 2: chuyển tới "CÔNG TY CỔ PHẦN ZION...") luôn là **chi** theo chiều tiền ra khỏi tài khoản ngân hàng, bất kể người nhận là ai.

**Phương án khác đã xem xét**: Dùng AI/NLP để suy luận ngữ nghĩa cho nhánh bộ luật — quá phức tạp cho Chế độ cơ bản (Tier C, không có AI); bộ luật chỉ cần đúng phần lớn ca phổ biến, phần còn lại có `typeNeedsReview` + màn xác nhận làm lưới an toàn.

## R5 — Ghi chú (nội dung/người nhận-gửi)

**Quyết định**: Tái dùng nguyên trạng field `merchant` hiện có của `ScanExtraction` (đã đổ vào ô "Cửa hàng / Ghi chú" và lưu vào cột `note` khi lưu giao dịch — hành vi có sẵn từ PBI 24, không đổi). Với ảnh ngân hàng, `parseBankNotification` điền dòng theo khoá `GD:`, `Nội dung`, hoặc `Đến:` (tên người nhận) vào field này thay vì tên cửa hàng.

**Lý do**: Không cần field mới — mockup `scan-04` đã đặt tên nhãn "Cửa hàng / Ghi chú" (dùng chung cho 2 ngữ cảnh), và đường ghi (`_finalExtraction` → `note: _merchantCtrl.text.trim()`) đã tồn tại nguyên vẹn.

**Phương án khác đã xem xét**: Thêm field `note` riêng tách khỏi `merchant` — bị loại (YAGNI), vì 2 field cùng đổ vào 1 ô UI và cùng 1 cột DB, tách ra chỉ thêm state không cần thiết.

## R6 — Danh mục gợi ý

**Quyết định**: Không cố suy category cho giao dịch ngân hàng ở nhánh bộ luật — để trống (`ScanField<Category>()` rỗng mặc định), người dùng tự chọn ở màn xác nhận. Nhánh AI vẫn được yêu cầu gợi ý category nếu ngữ cảnh đủ rõ (VD nội dung "CHUYEN KHOAN LUONG" khớp danh mục "Lương").

**Lý do**: Giả định đã chốt ở spec.md; hầu hết ảnh ngân hàng không có "tên cửa hàng" để tra `merchant_dictionary.dart` — cố suy sẽ sai nhiều hơn đúng.

**Phương án khác đã xem xét**: Thêm từ điển từ khoá riêng cho ngân hàng (VD "luong" → "Lương", "chuyen khoan" → bỏ qua) — có thể làm ở PBI sau nếu cần; đợt này không đủ dữ liệu để hiệu chỉnh, giữ tối thiểu.

## R7 — Prompt AI (Tier A/B) mở rộng cho cả 2 loại ảnh

**Quyết định**: Đổi `buildReceiptPrompt(lines, expenseCategories)` → `buildScanPrompt(lines, expenseCategories, incomeCategories)`: hỏi thêm trường `"type": "chi"|"thu"` (định nghĩa rõ trong prompt: chi = tiền ra/ghi nợ/mua hàng, thu = tiền vào/ghi có), đưa **cả 2** danh sách category (gắn nhãn rõ danh mục nào ứng với chi, danh mục nào ứng với thu) để model chọn đúng theo `type` nó suy ra. `parseLlmReceipt` đọc thêm `type`, set `typeNeedsReview = true` khi thiếu/giá trị lạ (giữ mặc định chi), và `resolveCategory` chọn đúng danh sách theo `type` đã đọc. `LlmExtractor.extract()` gọi hàm mới, truyền `incomeCategories` (hiện tại đang bỏ qua tham số này).

**Lý do**: Một prompt/engine dùng chung cho cả hóa đơn lẫn ảnh ngân hàng (giống cách bộ luật dùng chung 1 seam `ReceiptExtractor`) — model đủ khả năng tự phân biệt ngữ cảnh, không cần 2 prompt tách biệt hay bước phát hiện loại ảnh riêng ở nhánh AI.

**Phương án khác đã xem xét**: Viết `looksLikeBankNotification` rồi chọn 1 trong 2 prompt khác nhau cho AI — thừa, vì mô hình ngôn ngữ vốn đã xử lý được ngữ cảnh hỗn hợp trong 1 prompt, tách prompt chỉ tăng số lần gọi/độ phức tạp mà không tăng độ chính xác đáng kể.

## R8 — Đánh dấu "cần xem lại" cho loại giao dịch

**Quyết định**: Thêm **1 field mới** `bool typeNeedsReview` (mặc định `false`) vào `ScanExtraction` — **không** đổi `type` thành `ScanField<TxnType>` đầy đủ 3 mức tin cậy như các field khác. Màn xác nhận (`scan_confirm_screen.dart`) hiển thị dòng "Kiểm tra lại" (màu coral, tái dùng đúng style `_confidenceChip` đang có) ngay dưới ô "Loại giao dịch" khi cờ này bật.

**Lý do**: `type` trong ScanExtraction đã luôn "có giá trị" (không có khái niệm rỗng như `amount`/`date`/`merchant`/`category` — luôn phải là thu hoặc chi), nên không cần đủ 3 mức `FieldConfidence`; chỉ cần 1 cờ nhị phân "có nên xem lại hay không" (YAGNI). Đổi hẳn sang `ScanField<TxnType>` sẽ lan ra toàn bộ nơi đọc/ghi `.type` hiện có (receipt_parser, llm_extractor, scan_confirm_screen, wallet_repository call site, ~5 file test) mà không thêm giá trị nghiệp vụ nào.

**Phương án khác đã xem xét**: Đổi `type` thành `ScanField<TxnType>` đồng bộ các field khác — cân nhắc nhưng loại vì diện sửa rộng hơn hẳn lợi ích (chỉ cần 1 bit thông tin).

## R9 — Không đổi schema cơ sở dữ liệu

**Quyết định**: Không migration, schema **giữ nguyên v10**. `type`/`typeNeedsReview` chỉ thêm khoá mới vào `ScanExtraction.toJson()` — được ghi vào `scan_sessions.parsed_json` (cột `TEXT` JSON tự do, đã tồn tại từ PBI 24), không đụng cấu trúc bảng nào.

**Lý do**: `parsed_json` vốn được thiết kế để chứa toàn bộ kết quả trích xuất dưới dạng JSON tự do (data-model PBI 24 §2.4) — thêm khoá không cần đổi cột/bảng.

**Phương án khác đã xem xét**: Không có — không có lý do kỹ thuật nào để đổi schema ở PBI này.
