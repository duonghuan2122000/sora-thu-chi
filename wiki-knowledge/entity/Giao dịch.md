---
title: "Giao dịch"
date: 2026-09-17
tags: [module, transaction, entity]
sources:
  - ../docs/transaction/nghiep-vu-thiet-ke-quan-ly-giao-dich.md
  - ../docs/wallet/nghiep-vu-vi-tai-khoan.md
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../docs/ai/tinh-nang-quet-hoa-don-ai-local.md
  - ../../.specify/specs/24/spec.md
  - ../../.specify/specs/24/data-model.md
  - ../../.specify/specs/39/spec.md
  - ../../.specify/specs/39/plan.md
---

# Giao dịch

Nhóm nghiệp vụ **trung tâm thao tác** (tần suất cao nhất) → gắn FAB giữa bottom nav ([[Design system]]). Ghi nhận Thu / Chi / Chuyển khoản nội bộ.

## Mô hình (drift — đặc tả trong wallet doc)
`transactions`: `id, wallet_id, type(income/expense/transfer/adjustment), amount, category_id, note, tags, receipt_image, location, transaction_date, transfer_group_id(null), exchange_rate(null), source(manual/aiScan)`.
- `type` gồm cả `adjustment` (điều chỉnh số dư — sinh từ nghiệp vụ ví, xem [[Ví & Tài khoản]]), không nằm trong 3 loại giao diện.
- `transfer_group_id` liên kết 2 dòng của 1 lần transfer (xóa/sửa đồng bộ).
- `exchange_rate` lưu tỷ giá khi transfer/đa tiền tệ tại thời điểm gd.
- **`source` thêm ở schema v8 (PBI 24)**: `TxnSource { manual, aiScan }`, **default `manual`** ⇒ mọi đường nhập tay giữ nguyên hành vi, dòng cũ sau migration nhận `manual` (migration chỉ `addColumn`, **không seed**). Đây là **nguồn gốc giao dịch**, độc lập với `type`; giao dịch quét vẫn sửa/xóa như giao dịch thường (không có luồng riêng).
- Bảng **`scan_sessions`** (schema v8) = nhật ký **mỗi lần quét**: `id, image_path, raw_text, parsed_json, engine(ruleBased/geminiNano/gemma3nE2b), transaction_id(nullable, trỏ giao dịch đã sinh), created_at`. `parsed_json` là bản chụp kết quả trích xuất **sau khi người dùng sửa** ở màn xác nhận; bảng này **không** tham gia tính số dư/báo cáo — chỉ để đối chiếu về sau.

## Thêm giao dịch
**Điểm vào FAB đổi ở PBI 24**: FAB giữa nav nay mở **bottom sheet "Thêm giao dịch"** (mockup `scan-01`) với 4 hàng — Khoản Thu / Khoản Chi / Chuyển khoản / **Quét hóa đơn (AI)** (nhãn "MỚI"); hàng quét **chỉ hiện khi** công tắc trong Cài đặt đang bật ([[Hồ sơ & Bảo mật]]). Chọn Thu/Chi → mở form với loại tương ứng sẵn; **Chuyển khoản → form tự mở luồng chuyển một lần**; Quét → `startScanFlow`. Cờ "đã lưu" của shell giữ nguyên ⇒ lưu xong vẫn làm mới danh sách + Tổng quan + Báo cáo.

- Segmented tab `Chi | Thu | Chuyển khoản`, **mặc định mở "Chi"**.
- Bắt buộc: Số tiền (>0, **bàn phím số của hệ thống** — PBI 38, xem dưới), Danh mục, Ví, Ngày giờ (default = now). Tùy chọn: ghi chú, **tag** (nhập được từ PBI 38), **ảnh hóa đơn** (đính kèm được từ PBI 38), vị trí GPS (vẫn chỉ ghi tự động, chưa có ô nhập tay).
- Transfer: thay Danh mục bằng cặp Ví nguồn → đích; không tính thu/chi; validate nguồn ≠ đích + cảnh báo mềm âm quỹ; **không có dòng Tag/Ảnh hóa đơn** (2 trường này chỉ thuộc form Thu/Chi).
- **Quick Add**: chỉ Số tiền + Danh mục + Ví (default = lần nhập gần nhất); gọi từ widget/notification.
- "Lưu & tiếp tục" (snackbar "Thêm giao dịch khác") — nhập chuỗi nhiều khoản.
- Danh mục phải **cùng type** với giao dịch; transfer **không gắn danh mục** ([[Danh mục]]).

### Cập nhật giao diện màn Thêm giao dịch (PBI 38, đã triển khai)
> Nguồn: mockup `02-them-giao-dich-v2.svg`, `.specify/specs/38/`.

- **Bàn phím số hệ thống thay numpad tự vẽ**: ô Số tiền nay là `TextField(keyboardType: number)` (bám đúng pattern `_onAmountChanged` đã có sẵn ở màn Chuyển tiền — filter còn chữ số, format lại dấu chấm nghìn, giữ con trỏ cuối), viền màu theo ngữ cảnh loại giao dịch (coral/teal) thay underline cũ. Widget `AmountKeypad` (numpad tự vẽ) **không bị xóa** — vẫn dùng ở màn xác nhận quét hóa đơn và khoảng số tiền của màn Tìm kiếm & Lọc (xem [[Design system]]).
- **Tag nay ghi được, không chỉ hiển thị**: trước PBI 38, cột `tags` (schema v3) chỉ được `addScannedTransaction` ghi (luồng quét) và màn Chi tiết/Tìm kiếm chỉ *đọc*; `addTransaction` (đường nhập tay) luôn để trống. Nay dòng "Tag" mở màn **`TagPickerScreen`** mới (khuôn `CategoryPickerScreen`) — chọn nhiều tag đã dùng trước đó hoặc gõ tạo tag mới tại chỗ (khử trùng không phân biệt hoa/thường). **Không có bảng `tags` riêng**: danh sách gợi ý suy bằng cách quét `tags` của toàn bộ giao dịch hiện có (`distinctTags`) — chấp nhận được ở quy mô dữ liệu cá nhân, nâng cấp lên bảng riêng nếu sau này cần sửa/xóa tag hàng loạt.
- **Ảnh hóa đơn nay đính kèm được ở đường nhập tay**: chạm dòng "Ảnh hóa đơn" mở action sheet "Chụp ảnh"/"Chọn từ thư viện" (`image_picker`, không phải camera preview tự vẽ của luồng quét), ảnh lưu qua đúng seam `ScanImageStore`/`LocalScanImageStore` đã có từ PBI 24 (`<appDocuments>/receipts/`). Rời màn không lưu → ảnh vừa chụp/chọn bị xóa (không để rác) — vì vậy `isDirty` (hàm thuần màn Thêm) được bổ sung 2 điều kiện `hasTags`/`hasReceiptImage`, nếu không chỉ đính ảnh mà chưa đổi gì khác sẽ bị coi "sạch" và bỏ qua bước dọn file.
- `WalletRepository.addTransaction` thêm 2 tham số optional `tags`/`receiptImage` (default `''`, tương thích lời gọi cũ) — ghi thẳng vào 2 cột đã tồn tại từ schema v3, **không migration**.
- **Chưa làm** (ngoài phạm vi PBI 38, đã xây ở PBI 39 — xem mục dưới): nút/luồng "Sửa giao dịch" từ màn Chi tiết; màn quản lý Tag độc lập (đổi tên/xóa/gộp) vẫn chưa có.

## Sửa / xóa / nhân bản

### Sửa giao dịch — **đã triển khai (PBI 39)**
> Nguồn: `.specify/specs/39/`.

Nút "Sửa" ở màn Chi tiết giao dịch (trước là no-op từ PBI 10/38) nay tái dùng đúng 2 màn hiện có thay vì tạo màn riêng — bám mô tả nghiệp vụ gốc "mở lại màn Thêm với data điền sẵn":

- **Thu/Chi** → mở `AddTransactionScreen` ở chế độ sửa (tham số `editing`/`initialCategory`/`initialWallet`): điền sẵn toàn bộ trường (số tiền/danh mục/ví/ngày giờ/ghi chú/tag/ảnh hóa đơn), tiêu đề đổi "Sửa giao dịch". Lưu gọi `WalletRepository.updateTransaction` — **hoàn tác số dư cũ rồi áp lại số dư mới** (atomic, một `db.transaction()`, đúng cả khi đổi ví lẫn đổi loại) thay vì tính delta trực tiếp — bám nguyên tắc số dư là đại lượng suy ra ([[Nguyên tắc nghiệp vụ]]).
- **Chuyển khoản** → mở thẳng `WalletTransferScreen` ở chế độ sửa (tham số `editingTransferGroupId`/`destinationWallet`/`initialAmount`/`initialDate`/`initialNote`, không đi qua `AddTransactionScreen`), tiêu đề đổi "Sửa chuyển khoản", nút chính đổi "Lưu thay đổi". Lưu gọi `WalletRepository.updateTransfer` — **ghi đè tại chỗ 2 vế liên kết** (giữ nguyên `id`/`transfer_group_id`, không xóa/insert lại) sau khi hoàn tác số dư 2 ví cũ và áp lại theo ví/tiền mới.
- **Không đổi schema drift** — cả 2 method mới chỉ `UPDATE` dòng `transactions`/`wallets` đã có.
- **⚠ Quyết định thu hẹp phạm vi cố ý (PBI 39)**: khi sửa, đổi loại chỉ cho phép trong nhóm **Thu ⇄ Chi** (segmented tab khóa mục "Chuyển khoản" ở chế độ sửa) — **không** cho đổi giữa nhóm Thu/Chi và Chuyển khoản, vì khác cấu trúc lưu trữ (1 dòng ↔ 2 dòng liên kết) và spec không yêu cầu (xem [[Lộ trình phát triển]]).
- Rời màn sửa khi có thay đổi chưa lưu → hỏi xác nhận (áp dụng cho cả 2 màn ở chế độ sửa; luồng "Thêm mới"/"Chuyển tiền mới" giữ nguyên hành vi cũ, không hỏi khi đóng ngay cả khi có dữ liệu).

### Nhân bản giao dịch — **đã triển khai (PBI 40)**
> Nguồn: `.specify/specs/40/`.

Nút "Nhân bản" ở màn Chi tiết giao dịch (trước no-op) tái dùng đúng 2 màn của PBI 39 (Sửa) nhưng ở **chế độ tạo mới có điền sẵn** — không phải chế độ sửa:

- Method `_duplicate(view)` bám sát cấu trúc `_edit(view)` (tải lại `Transaction`/`Category`/`Wallet` gốc), khác duy nhất ở chỗ **không truyền `editing`/`editingTransferGroupId`** (giữ nhánh tạo mới `addTransaction`/`WalletController.transfer`, không đụng bản gốc) và **ép ngày giờ = `DateTime.now()`** thay vì giữ ngày gốc.
- `AddTransactionScreen` thêm 5 tham số optional mới `initialAmount`/`initialNote`/`initialDate`/`initialTags`/`initialReceiptImage` (song song `initialCategory`/`initialWallet` đã có từ PBI 38), dùng để điền state khi `editing == null`. Cờ `editing != null` **vẫn là điều kiện duy nhất** quyết định `addTransaction` vs `updateTransaction` — không đổi.
- `WalletTransferScreen` **không cần sửa gì** — cờ `editingTransferGroupId` đã tách biệt sẵn khỏi các tham số `initial*` từ PBI 39, khớp thẳng nhu cầu nhân bản.
- Ảnh hóa đơn nhân bản dùng chung tham chiếu file với giao dịch gốc — `_originalReceiptImage` (cơ chế chặn xóa nhầm file khi hủy màn/đổi ảnh, có từ PBI 39) mở rộng để tính cả ảnh điền sẵn lúc nhân bản, tránh xóa nhầm ảnh mà giao dịch gốc vẫn đang tham chiếu trong DB.
- Baseline `isDirty` (quyết định có hỏi "Hủy giao dịch?" khi rời màn) cũng đọc từ `initial*` khi `editing == null` — mở màn Nhân bản không sửa gì rồi thoát **không** hỏi xác nhận.
- Áp dụng cả 3 loại giao dịch (Thu/Chi/Chuyển khoản). Giao dịch định kỳ: không cần xử lý riêng vì `Transaction` không có trường liên kết định kỳ — bản sao tự động độc lập.
- **⚠ Lệch so với mô tả nghiệp vụ gốc (docs/transaction §3.3/§4.4)**: **không sao chép trường "Vị trí" (`location`)** — `AddTransactionScreen` (dùng chung cho Thêm/Sửa) chưa từng có ô nhập/hiển thị Vị trí; trường này chỉ được `addScannedTransaction` (luồng quét OCR) ghi, `WalletRepository.addTransaction` không có tham số `location`. Giữ nguyên giới hạn kiến trúc sẵn có, không mở rộng repository API cho tính năng nhỏ này.
- Không đổi schema drift.

### Xóa / Undo / Định kỳ — **chưa triển khai**
- Xóa: nút 3 chấm ở màn Chi tiết vẫn no-op. Nghiệp vụ gốc: dialog xác nhận → snackbar **Undo ~5s** trước xóa vĩnh viễn.
- Sửa/xóa trong chuỗi định kỳ → hỏi phạm vi "Chỉ giao dịch này" / "Toàn bộ chuỗi từ đây" — chưa áp dụng vì app **chưa có tính năng giao dịch định kỳ**.

## Định kỳ (Recurring — GĐ2)
- Cấu hình: loại, số tiền (có thể trống nếu đổi mỗi kỳ), danh mục, ví, chu kỳ (ngày/tuần/tháng/năm + mốc, VD "ngày 25 hằng tháng"), ngày bắt đầu/kết thúc, nhắc trước N ngày.
- Tự sinh giao dịch đúng chu kỳ; gd sinh ra đánh dấu nguồn gốc "định kỳ" (icon riêng).
- Nhắc push trước hạn N ngày + xác nhận nhanh "Đã thu/chi" từ notification.
- Danh sách chuỗi có toggle Bật/Tắt nhanh (không xóa config).

## Tìm / lọc / sắp xếp — **đã triển khai (PBI 12)**

Màn con **"Tìm kiếm & Lọc"** (`05-tim-kiem-loc.svg`), toàn màn hình đè shell (không bottom nav): app bar teal = back + **ô tìm kiếm pill** trắng. Là **form trên bản nháp**: **Áp dụng** → trả bộ lọc về màn danh sách, **back/X** → giữ tập cũ; "Đặt lại" reset nháp về mặc định **Tháng này** (không pop).

- **Từ khóa** (ghi chú/tên danh mục/tag): **bỏ dấu tiếng Việt** tự viết (không thêm package) — "an uong" ↔ "Ăn uống", substring, debounce ~250ms.
- **Chip loại 4 nút** Tất cả / Thu / Chi / Chuyển khoản (không có chip "Điều chỉnh" — `adjustment` chỉ xuất hiện dưới Tất cả).
- **Lọc nâng cao** (5 dòng, mỗi dòng mở bottom sheet): **Khoảng thời gian** preset Hôm nay/Tuần này (thứ Hai đầu tuần)/Tháng này/Toàn bộ + "Tùy chọn…" (2 date picker chặn start>end); **Danh mục** multi chọn theo **loại chip** (Tất cả → thu+chi, Thu/Chi → đúng loại; chip Chuyển khoản → dòng **vô hiệu**), chọn cha **tự gộp con**; **Ví** một hoặc "Tất cả các ví" (gồm ví ẩn — xem lịch sử); **Khoảng số tiền** Từ–Đến theo `abs(amount)` **bao biên**, mỗi ô mở keypad (`AmountKeypad`), trống một đầu = bỏ giới hạn đầu đó, **min > max → báo đỏ + vô hiệu Áp dụng**; **Sắp xếp** 4 option Ngày mới nhất (mặc định)/Ngày cũ nhất/Số tiền tăng/giảm dần.
- **Tổng hợp điều kiện = AND**; mọi tổ hợp không tạo/mất/sửa giao dịch (chỉ đọc, không đổi schema).

**2 lựa chọn hiển thị do user chốt (đã triển khai, ghi PBI 12):**
- **R4 — sort tiền thì danh sách phẳng** (không header ngày), xếp theo `abs(amount)`; sort ngày thì giữ nhóm ngày như list thường (đảo nhóm & dòng cho "Ngày cũ nhất").
- **R5 — khi đang lọc, card "Thu/Chi tháng này" ẩn**, thay bằng thanh `N kết quả · Tổng: X đ` + nút **"Bỏ lọc"** (về toàn bộ). Hết lọc → card tháng hiện lại.

**Dòng tóm tắt `N kết quả · Tổng: X đ`** (live khi gõ/chip; thống kê cả form lẫn thanh danh sách dùng chung 1 hàm thuần): `N` = số dòng **sau gộp transfer**; `Tổng` = Σ thu − Σ chi (transfer/adjustment có trong N nhưng **không vào Tổng**). Giao dịch transfer cùng `transfer_group_id`: tiêu chí khớp 1 vế → **giữ cả 2 vế** (để gộp 1 dòng, không tách cặp khi lọc Ví). Tập rỗng → "0 kết quả"; danh sách sau Áp dụng hiện "Không có giao dịch khớp bộ lọc." (khác empty "Chưa có giao dịch nào." khi không lọc).

**Kỹ thuật**: bộ lọc sống trong `TransactionController` (`activeFilter` + view đã lọc), **bền qua ra/vào tab**; màn lọc là Stateful với repository inject (seam PBI 11) + `now` anchor. Lọc **trong bộ nhớ** trên tập `allTransactions` cache (mỗi `load()` 1 lần), không SQL pushdown — giữ đúng gộp transfer. Không đổi schema/repository; không `build_runner`. Dòng giao dịch cũ chưa có `category_id` vẫn lọc được theo **tên danh mục** (fallback — giữ lịch sử, xem [[Danh mục]]).

## Quét hóa đơn bằng AI — đã triển khai **chặng 1 + chặng 2** (PBI 24)
> Nguồn: `docs/ai/tinh-nang-quet-hoa-don-ai-local.md` + `.specify/specs/24/`. **Chặng 1 = trọn luồng ở Chế độ cơ bản (bộ luật, không LLM) + kiểm tra cấu hình máy + mục Cài đặt**; **chặng 2 = AI nâng cao Tier A/B** (Gemini Nano / Gemma 3n E2B) cùng seam, tự fallback về bộ luật.

**Luồng**: FAB → sheet `scan-01` → màn chụp `scan-02` (camera hoặc **Thư viện**) → màn xử lý `scan-03` → màn xác nhận `scan-04` → **Lưu**. Huỷ ở bất kỳ bước nào ⇒ **không ghi gì**; đặc biệt ảnh chỉ được ghi vào `<appDocuments>/receipts/<millis>.jpg` ở **nhánh lưu** (không để lại file rác giữa luồng).

**Trích xuất (bộ luật `RuleBasedExtractor`)** — trả kèm **độ tin cậy** + **vùng ảnh** cho từng trường:
- **Số tiền**: nhận `55.000` / `55,000` / `55 000` / `55000` / `55.000đ`; **loại** số thập phân (`12.5`) và số **< 1000 không nhóm nghìn**. Ưu tiên dòng có **từ khoá tổng** (TỔNG CỘNG / THÀNH TIỀN…), không có thì lấy **số lớn nhất ở cuối** hóa đơn ⇒ tránh lấy dòng mặt hàng; dòng chỉ có ĐT/MST không bị coi là tiền.
- **Ngày**: 4 định dạng; **không đọc được ⇒ `now` + độ tin cậy thấp**; ngày **không hợp lệ** (VD `31/02`) bị bỏ qua.
- **Cửa hàng**: theo từ khoá, hoặc dòng **cỡ chữ lớn trong 30% đầu** hóa đơn.
- **Danh mục gợi ý**: từ điển ~50 khoá cửa hàng (bỏ dấu + thường hoá, khớp chuỗi con) → tên danh mục **seed**; **chỉ** resolve vào danh mục **đang hoạt động**, không khớp ⇒ để trống ([[Danh mục]]).

**Màn xác nhận là bắt buộc — không bao giờ tự lưu**: 6 trường sửa được (Loại / Số tiền / Ngày giờ / Cửa hàng-Ghi chú / Danh mục / Ví), chạm một trường ⇒ **khoanh vùng coral** tương ứng trên ảnh (không xác định được vùng thì không khoanh). Chỉ báo độ tin cậy: **cao → teal, trung bình → xám, thấp/rỗng → coral + "Kiểm tra lại"** ([[Design system]]). Ví mặc định được chọn sẵn; **không có ví hợp lệ → bắt chọn**; nút Lưu vô hiệu khi số tiền rỗng/≤ 0 và có cờ chống bấm đúp.

**Cảnh báo trùng (mềm)**: cùng số tiền trong **±24h** (bỏ qua transfer/adjustment) → banner coral nhắc đối chiếu, **không chặn lưu**.

**Ghi dữ liệu là 1 transaction DB duy nhất**: bù `balance` ví theo loại + insert `transactions` (`source = aiScan`, `receipt_image` = đường dẫn đã lưu, `category_id` **có thể null**, `note` = tên cửa hàng) + insert `scan_sessions` (trỏ `transaction_id` vừa sinh, ghi `engine` **đã dùng thật**).

**Chọn engine & fallback (chặng 2)** — cùng một seam, màn xác nhận **không biết** engine nào đã chạy:
- **Tier A** (Gemini Nano, AICore hệ thống) và **Tier B** (Gemma 3n E2B, đã tải model) → gọi LLM **một lần cho mỗi lần quét**; Tier B chưa tải model thì tự rơi về Chế độ cơ bản.
- **Tier A đọc trực tiếp ảnh** (prompt đa phương thức, PBI 37) — **không** còn nhét văn bản OCR vào prompt; OCR vẫn chạy song song **chỉ** để dành cho fallback bộ luật (dòng dưới) và đối chiếu số tiền ảnh ngân hàng (mục kế tiếp). Tier B vẫn dựa hoàn toàn trên văn bản OCR như trước — không đổi.
- LLM **timeout 10 giây**, ném lỗi, hoặc trả về không đọc được JSON ⇒ **tự chuyển sang bộ luật cho riêng lần quét đó**: người dùng vẫn ra màn xác nhận, **không** phải chụp lại, **không** thấy thông báo lỗi kỹ thuật; phiên quét ghi `engine = ruleBased` (FR-011/SC-009).
- LLM **không** trả vùng chữ ⇒ khoanh vùng ảnh gốc để trống ở nhánh AI (nhánh "không xác định vùng" của `scan-04`).

**Nhận diện ảnh thông báo ngân hàng (PBI 36)** — cùng luồng/engine ở trên, **không thêm điểm vào mới**; nguồn AI Scan nay tự suy ra **cả thu lẫn chi** thay vì luôn mặc định là chi như trước:
> Nguồn: `.specify/specs/36/`.
- **Nhận diện**: `RuleBasedExtractor` đếm từ khoá ngân hàng (`số dư`, `tài khoản`, `ghi nợ`, `ghi có`, `giao dịch`, `biến động số dư`, `(debit)`, `(credit)`, `mã giao dịch`, `số tiền`) trên toàn văn OCR; khớp **≥ 2** từ khoá ⇒ chạy `parseBankNotification` thay vì `parseReceipt` (1 từ khoá đơn lẻ dễ dương tính giả trên hóa đơn POS in "Mã giao dịch"). Nhánh AI không cần bước phát hiện riêng — 1 prompt chung tự đọc ngữ cảnh và trả `type`.
- **Số tiền giao dịch (không phải số dư)**: loại **hoàn toàn** dòng chứa "số dư" khỏi ứng viên (khác hóa đơn — vốn chỉ loại dòng ngày/ĐT/MST); trong các dòng còn lại ưu tiên số có dấu `+`/`-` liền trước hoặc cùng dòng với `(debit)`/`(credit)`/`ghi nợ`/`ghi có`/`số tiền`, không có thì lấy số **đầu tiên** xuất hiện (khác hóa đơn — lấy số **lớn nhất**, vì số dư ngân hàng gần như luôn lớn hơn số tiền giao dịch đơn lẻ).
- **Loại giao dịch (thu/chi)**: `ghi nợ`/`debit`/`-` ⇒ **chi**; `ghi có`/`credit`/`+` ⇒ **thu**; không khớp nhưng có "chuyển tiền thành công" ⇒ **chi** (tiền luôn rời tài khoản nguồn, không tự gán "chuyển khoản nội bộ" của app dù người nhận là ai); không khớp gì ⇒ mặc định **chi** + bật cờ **`typeNeedsReview`**.
- **`ScanExtraction.typeNeedsReview`** (field mới, mặc định `false`, không đổi schema DB — chỉ thêm khoá vào `parsed_json`): `true` khi bộ luật/AI không đủ căn cứ suy thu/chi ⇒ màn `scan-04` hiện dòng **"Kiểm tra lại"** (coral, tái dùng style chỉ báo độ tin cậy) ngay dưới ô Loại giao dịch. Hóa đơn cửa hàng luôn `typeNeedsReview = false` (hành vi PBI 24 giữ nguyên).
- **Ghi chú**: tái dùng nguyên field `merchant` (đổ vào ô "Cửa hàng / Ghi chú" và cột `note`) — với ảnh ngân hàng chứa nội dung/người nhận-gửi (nhãn `GD:`, `Nội dung`, `Đến:`) thay vì tên cửa hàng.
- **Danh mục gợi ý**: nhánh bộ luật để **trống** (không đủ cơ sở như tên cửa hàng); nhánh AI vẫn được yêu cầu gợi ý nếu ngữ cảnh đủ rõ, chọn đúng danh sách chi/thu theo `type` model suy ra (prompt gửi **cả 2** danh sách danh mục có gắn nhãn).
- **Tổng quát, không giới hạn ngân hàng cụ thể** — dựa từ khoá/mẫu câu tiếng Việt phổ biến, không cứng theo tên/bố cục riêng một ngân hàng.

## Nhật ký trích xuất AI — đã triển khai (PBI 47)
> Nguồn: `.specify/specs/47/`. Mục đích: thu thập dữ liệu (kết quả AI sai ở đâu, người dùng sửa gì) để **sau này** dùng tinh chỉnh prompt/model trích xuất — bản thân PBI này **không** huấn luyện lại gì, chỉ ghi log local.

**Độc lập hoàn toàn với `scan_sessions`** (mục trên) — bảng mới **`scan_extraction_logs`** (schema **v11**, không FK) ghi **mọi** phiên quét (kể cả hủy/lỗi, khác `scan_sessions` vốn chỉ ghi khi **đã lưu**): `id, created_at, image_path?, raw_text?, extraction_json?, engine?, outcome(saved/cancelled/error), final_values_json?, error_message?, events_json`. Ghi **một lần** lúc phiên kết thúc (không update lại) — `ScanLogSession` (buffer trong bộ nhớ suốt luồng chụp→xử lý→xác nhận) tích event rồi `finish()` 1 lần, tự chống gọi lặp.

**Chuỗi hành vi** (`events_json`, đúng thứ tự thời gian): sự kiện `edit` (trường/giá trị trước/sau — loại, số tiền, ngày, danh mục; riêng "cửa hàng/ghi chú" không có callback rời rạc nên diff tại thời điểm lưu thay vì instrument từng phím gõ), `back` (thoát mà chưa lưu), `save`. **3 kết cục** (`outcome`): `saved` (có `final_values_json`), `cancelled` (back/thoát giữa chừng — vẫn giữ ảnh/OCR đã có), `error` (OCR rỗng hoặc trích xuất AI lỗi/exception — vẫn ghi log dù chưa tới màn xác nhận).

**Ảnh log lưu kho riêng** `<appDocuments>/scan_logs/` (không dùng chung `receipts/` của `ScanImageStore` — store đó **chỉ** ghi khi lưu giao dịch thành công, còn nhật ký cần ảnh cả khi hủy/lỗi). **Trần `kMaxScanLogs = 200`** cưỡng chế ngay trong `DriftScanLogStore.append` (cùng kỹ thuật FIFO của `NotificationHistoryStore`), kèm xóa file ảnh của dòng bị trim.

**Màn hình mới**: "Nhật ký trích xuất AI" — danh sách mới nhất trước (Cài đặt → cạnh mục "Quét hóa đơn AI", [[Hồ sơ & Bảo mật]]) → chi tiết 1 bản ghi (ảnh, OCR, AI đề xuất ban đầu vs giá trị cuối, timeline sự kiện) → xóa từng bản ghi/xóa tất cả → **xuất file JSON** toàn bộ nhật ký qua bảng chia sẻ hệ thống (tái dùng `share_plus`, không dependency mới — [[Stack kỹ thuật]]).

## Import CSV/Excel (chưa có PBI)
- Chọn file → map cột → preview → xác nhận → báo cáo lỗi. Danh mục chưa có → tạo mới hoặc map "Khác". Vẫn **chưa định vị giai đoạn** — [[Lộ trình phát triển]].

## Màu theo loại (ràng buộc thiết kế riêng)
| Loại | Màu |
|---|---|
| Thu | Teal `#0F6E56` (số tiền + mũi tên lên) |
| Chi | Coral `#D85A30` (số tiền + mũi tên xuống) |
| Transfer | Trung tính (chữ chính + icon 2 mũi tên xám) — tránh nhầm với thu/chi |

## Màn hình
| File | Loại |
|---|---|
| `01-danh-sach-giao-dich.svg` | Màn chính (header teal + bottom nav) — card thu/chi tháng này |
| `02-them-giao-dich-v2.svg` | Full-screen modal (segmented + bàn phím số hệ thống + Tag/Ảnh hóa đơn, PBI 38 — thay `02-them-giao-dich.svg` bản numpad cũ) |
| `03-chon-danh-muc.svg` | Sub-page — lưới 4 cột icon tròn |
| `04-chi-tiet-giao-dich.svg` | Sub-page — tóm tắt + menu Sửa/Xóa/Nhân bản |
| `05-tim-kiem-loc.svg` | Sub-page — ô search + chip lọc nhanh |
| `06-giao-dich-dinh-ky.svg` | Sub-page — form + DS chuỗi toggle |
| `ai/scan-01-quick-add-sheet.svg` | Bottom sheet "Thêm giao dịch" (4 hàng) — điểm vào FAB |
| `ai/scan-02-camera-capture.svg` | Màn chụp ảnh hóa đơn (nền tối cố định) |
| `ai/scan-03-processing.svg` | Màn xử lý (4 bước) |
| `ai/scan-04-confirm-result.svg` | Màn xác nhận kết quả quét (6 trường) |

## Liên kết
- [[Ví & Tài khoản]] — Transfer, adjustment, phí transfer.
- [[Danh mục]] — gắn 1 danh mục cùng type; transfer không danh mục; danh mục gợi ý khi quét hóa đơn.
- [[Ngân sách]] — gd Chi tính vào budget theo categoryId/subcategory + ví.
- [[Hồ sơ & Bảo mật]] — công tắc bật tính năng quét + màn kiểm tra cấu hình máy.
- [[Design system]] — bottom sheet, màn chụp nền tối cố định, chỉ báo độ tin cậy, bàn phím số hệ thống (PBI 38).
- [[Stack kỹ thuật]] — seam OCR/device-probe/ảnh, kênh native `device_probe`, schema v8; tái dùng `ScanImageStore`/`image_picker` cho Ảnh hóa đơn ở màn Thêm giao dịch (PBI 38).
