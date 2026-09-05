# Nghiên cứu kỹ thuật — PBI 9: Màn hình danh sách giao dịch

Ngày: 2026-09-05
Trạng thái: giải quyết hết điểm mở — không còn `NEEDS CLARIFICATION`.

---

## R1 — Nguồn dữ liệu: đọc toàn bộ giao dịch mọi ví (kể cả ví ẩn), kèm `transfer_group_id`

**Quyết định**: Thêm method `allTransactions()` vào seam `WalletRepository` (trả mọi dòng `transactions` — không lọc ví), map `transfer_group_id` lên domain bằng cách **thêm field `transferGroupId` (int?, nullable) vào `Transaction`**. Drift `_toTransaction` điền field; `FakeWalletRepository` lưu/map tương ứng. Tên ví cho dòng phụ lấy từ `loadAll()` (đã có — trả cả ví ẩn).

**Lý do**: Màn danh sách cần *toàn bộ* giao dịch của thiết bị (FR-004: mọi ví kể cả ẩn) và cần `transfer_group_id` để **gộp 2 bút toán chuyển khoản thành 1 dòng** (FR-007) — thứ domain hiện chưa mang. Thêm field nullable chỉ là thay đổi cộng thêm (additive), không phá constructor/sort/detail ví hiện có; map 1-1 row↔domain vẫn giữ. `Transaction` là "subset màn cần" — nhưng màn Giao dịch (màn trục chính) chính là nơi group cần; thêm vào domain là trung thực nhất.

**Phương án khác đã xem xét**:
- DTO riêng `TransactionRow` kèm group/walletName → đẻ thêm 1 model song song domain đã map 1-1, dư.
- SQL `JOIN` lấy sẵn tên ví nguồn/đích khi chuyển → chuyên biệt quá; tên ví màn cần ở *mọi* dòng nên phải join 2 lần (`wallet` của dòng + wallet của vế kia) — phức tạp, trong khi 5 ví đọc qua `loadAll()` là đủ.
- Lọc ngay ở SQL "loại bỏ vế đích transfer" → phá bất biến dữ liệu, khó sửa/xóa đồng bộ sau.

---

## R2 — Gộp khoản chuyển khoản thành đúng 1 dòng hiển thị

**Quyết định**: Hàm thuần trong domain gộp cặp `type=transfer` có chung `transferGroupId`: vế `amount < 0` = ví nguồn, vế `amount > 0` = ví đích; hiển thị `amount = |x|`, phụ đề "ví nguồn → ví đích", màu trung tính, **không dấu** `+`/`−` (FR-007). Vế lẻ (group không có đủ cặp — dữ liệu bất thường) hiển thị như dòng trung tính fallback, không crash.

**Lý do**: 2 vế luôn cùng ngày/note/group (bất biến PBI 8, atomic). Quy ước "âm = nguồn" nhất quán với bất biến ghi 2 vế `−x/+x`. Gộp ở tầng view-model thuần, test deterministic được, DB không đổi.

**Phương án khác đã xem xét**: Giữ 2 dòng như màn chi tiết ví → phá FR-007 "không xuất hiện thành hai dòng"; gộp bằng SQL/GROUP BY → lằng nhằng, không test được ngoài sqlite host.

---

## R3 — Card "Thu/Chi tháng này": tính từ cùng bộ dữ liệu, thuần, mốc "thời điểm xem"

**Quyết định**: Hàm thuần `monthlyIncomeExpense(all, now)` tính trên cùng list đã đọc (R1): `incomeTotal = Σ income.amount`, `expenseTotal = −Σ expense.amount` (dương để hiển thị); chỉ dòng có `transaction_date` trong `[ngày 1 tháng dương lịch hiện tại, now]`; **loại trừ** `transfer` và `adjustment` bằng `type` (FR-003/FR-008); `now` truyền vào để test deterministic.

**Lý do**: Tránh thêm 1–2 câu SQL SUM riêng (trùng logic tháng, khó test). Mốc trên là `now` nên giao dịch đặt lịch tương lai *trong cùng tháng* không tính vào card (đúng edge "không tính nhầm vào card tháng"). Không có cột tháng lưu sẵn — tránh drift giữa DB và ngày.

**Phương án khác đã xem xét**: SUM ở drift theo `type IN (...) AND date BETWEEN` → nhanh hơn chút nhưng hai nguồn sự thật (query card + query list) dễ lệch; snapshot tháng lưu DB → phải invalidation khi ghi — quá sức cho DB một người dùng.

---

## R4 — Danh sách dài: đọc 1 lần toàn bộ + render lười theo cuộn (lazy), KHÔNG fetch phân trang SQL

**Quyết định**: Controller đọc toàn bộ giao dịch local 1 lần (drift, vài ms với ~nghìn dòng), gộp nhóm ngày thành mô hình trong bộ nhớ, `ListView.builder` build lười theo viewport (nhóm ngày = 1 item chứa rows) + `PageStorageKey` giữ vị trí cuộn. **Không** dùng `LIMIT/OFFSET` nạp theo lần cuộn.

**Lý do**: 
- DB **local sqlite một người dùng**: quy mô thực tế là nghìn→ chục nghìn dòng cá nhân nhiều năm, không phải triệu dòng. Đọc 1 lần thoả SC-001 (≤1s với 1.000 dòng) và SC-007 (cuộn mượt vì chỉ build item hiển thị).
- FR-012 yêu cầu "không trùng lặp/bỏ sót giữa các lần nạp" — snapshot duy nhất **đảm bảo tuyệt đối** điều này (không có "các lần nạp" để lệch). Fetch phân trang lại *tự gây ra* đúng rủi ro đó ở biên nhóm ngày và biên cặp transfer vắt 2 page.
- Gộp nhóm ngày + ghép cặp transfer xuyên "page" phức tạp không tương xứng lợi ích.

**`ponytail:` ceiling**: nếu dữ liệu vượt ~vài chục nghìn dòng gây giật → chuyển sang fetch theo *nhóm ngày* (query `WHERE date <= X ORDER BY date DESC LIMIT K` rồi chốt đủ nhóm cuối), không fetch theo row.

---

## R5 — Icon/màu bubble dòng: danh mục chưa có dữ liệu icon/màu → glyph mặc định tạm

**Quyết định**: `transactions.category` hiện chỉ là **chữ** (schema v2 PBI 8, chưa có bảng `categories`/icon/màu). Vì vậy bubble dòng:
- Thu & Chi: nền `tealLightBg` (#E1F5EE) + glyph teal — **khớp mockup SVG** (mọi bubble danh mục đồng màu teal-soft; màu nhận diện thu/chi nằm ở *số tiền*, dòng §5 doc Giao dịch).
- Chuyển khoản: nền `softCardBg` + glyph hoán đổi trung tính; Điều chỉnh số dư: nền `softCardBg` + glyph trung tính.
- Glyph trong bubble thu/chi: hàm pure nhỏ `categoryGlyph(name)` — vài tên danh mục mặc định quen thuộc (Ăn uống→restaurant, Di chuyển→…, Lương→payments…) + fallback chung; **tầng presentation của màn, không phải dữ liệu/DB**; gỡ khi bảng `categories` (module Danh mục) cung cấp icon/màu thật (quyết định mở #1).

**Lý do**: Bám "hiển thị dữ liệu hiện có" của spec; không đẻ một "bảng danh mục giả" hay lưu màu vào DB. Mapping ngắn (~15 dòng thuần, test được) chỉ phục vụ QA đối chiếu mockup (SC-006) với bộ mẫu seed — dữ liệu icon/màu riêng mỗi danh mục **chưa tồn tại trong hệ thống**, không thể lấy từ đâu khác.

**Phương án khác đã xem xét**: Một glyph chung cho mọi dòng thu/chi (không map tên) → ít code hơn nhưng mọi hàng giống hệt, QA SC-006 lệch glyph từng danh mục; dựng bảng `categories` + seed ngay trong PBI này → trộn phạm vi (module Danh mục là PBI riêng), vi phạm "mỗi PBI một màn".

---

## R6 — Làm mới khi giao dịch đổi ở nơi khác (FR-011): nạp lại khi người dùng quay lại tab

**Quyết định**: `TransactionController` (GetX) + hàm ensure trong tầng deps. `AppShell` khi `onTabSelected(index == 1)` gọi `ensureTransactionController().load()` (fire-and-forget). Màn dùng `Obx` đọc trạng thái. **Không** nạp trong `initState` của `TransactionScreen`.

**Lý do**: `AppShell` giữ 4 màn chính sống bằng `IndexedStack` — tất cả build từ lúc boot; nạp trong `initState` sẽ mở drift DB ngay khi mở app dù người dùng chưa bao giờ vào tab Giao dịch (phình boot). Nạp *tại thời điểm chọn tab* vừa đủ: (1) lần đầu hiển thị; (2) mỗi lần quay lại sau khi thao tác ở nơi khác (hiện chỉ có luồng chuyển tiền PBI 8 ghi giao dịch — đi qua Cài đặt, quay lại tab là có reload). Khi PBI thêm/sửa giao dịch đến, luồng đó tự gọi `controller.load()` sau khi lưu — mở rộng chỗ này sau.

**Phương án khác đã xem xét**: WalletController gọi sang TransactionController sau `transfer` (couple 2 module); "data-changed bus"/event → dư kiến trúc cho 1 nguồn ghi; reload mỗi build/Obx watch DB → cháy query.

---

## R7 — Dùng chung 1 drift DB / repository giữa 2 controller

**Quyết định**: Thêm `ensureWalletRepository()` (Get, singleton) tạo `DriftWalletRepository(AppDatabase())` **một lần**. `ensureWalletController` (sửa) và `ensureTransactionController` (mới) đều dùng chung instance repository/DB đó.

**Lý do**: Nếu mỗi controller tự tạo `AppDatabase()` → 2 connection drift trên cùng file sqlite (rủi ro lock/đồng bộ), 2 repo dư. Repository là stateless so với DB → chia sẻ an toàn. Test đã theo mô hình `Get.put(controller/fake)`; thêm bước đăng ký repo fake là mở rộng nhỏ, nhất quán.

**Phương án khác đã xem xét**: Tạo controller con trong deps riêng mỗi module, mỗi cái một DB riêng → nguy cơ 2 handle file; singleton repository chung là chuẩn GetX/drift.

---

## R8 — Trạng thái màn & empty state

**Quyết định**: Máy trạng thái UI: `isLoading` lần đầu (spinner) → nội dung | empty state | lỗi đọc. Empty (chưa có giao dịch nào): card thống kê hiển thị `0 đ` cho cả 2 khối (FR-010) + vùng giữa hiển thị hướng dẫn ghi giao dịch đầu tiên (trỏ FAB), không báo lỗi. Lỗi đọc repo: thông báo + nút thử lại.

**Lý do**: Bám FR-010 & edge "chưa có giao dịch nào → card `0 đ`, không lỗi". Không đẻ thêm trạng thái không dùng tới.

**Phương án khác đã xem xét**: Rỗng mà ẩn luôn card → lệch FR-010 "card hiển thị `0` hợp lệ"; chỉ spinner mãi khi lỗi → màn treo.

---

## R9 — Header + layout khớp mockup với tối thiểu thay đổi widget dùng chung

**Quyết định**: `ScreenHeader` (widget chung 4 màn main) thêm 2 tham số tuỳ chọn **mặc định giữ nguyên layout hiện tại**: `centerTitle` (bool, default false) và `trailing` (Widget?, default null). Màn Giao dịch truyền `centerTitle: true` + `trailing` = icon lọc (InkWell no-op → điểm vào PBI sau, chạm không lỗi FR-014). Card thống kê đặt ở *đầu body* trắng: `Row` 2 khối (nền `softCardBg`, bo 10, gap 10, padding 20/16) — label + mũi tên (lên/teal, xuống/coral) + số (Thu: `textPrimary`; Chi: `coral` — bám SVG §4.1/doc §5). List dưới có đệm đáy đủ tránh FAB/nav che hàng cuối.

**Lý do**: SVG đặt tiêu đề giữa + icon lọc phải; header hiện để trái. Thêm param mặc định cũ → không vỡ 4 màn đang dùng; tránh viết header riêng (trùng lặp). Số tiền trên màn căn phải trong khối `Flexible` + không ellipsis cắt số — dùng scale-down nếu cần (FR-009: số rất lớn hiển thị đầy đủ, không tràn/cắt).

**Phương án khác đã xem xét**: Header tuỳ biến nằm hẳn trong màn → trùng code với 3 màn main còn lại; sửa `ScreenHeader` thành center cứng → vỡ màn khác.

---

## R10 — Kiểm thử không phụ thuộc sqlite native (bám convention PBI 7/8)

**Quyết định**: Mọi test màn/controller dùng `FakeWalletRepository` (thêm `allTransactions` + tự gán `transferGroupId` cho 2 vế khi seed/`performTransfer`); pure grouping/thống kê/label test thuần với `now` cố định; drift DAO test (`NativeDatabase.memory()`) mở rộng xác minh `allTransactions` trả 2 vế cùng group — skip-guard khi host thiếu sqlite (như PBI 7/8).

**Lý do**: Host Windows không có `sqlite3.dll` tin cậy trong widget/unit; giữ mọi logic màn chạy trên fake để test nhanh/ổn định; một DAO test chặn hồi quy map group.

**Phương án khác đã xem xét**: Dùng drift thật cho widget test → flaky trên host; bỏ test DAO → không kiểm map `transfer_group_id` ở tầng drift.
