# Nghiên cứu — PBI 12: Tìm kiếm & lọc giao dịch

Ngày: 2026-09-05

## Bối cảnh ràng buộc

- App offline (drift SQLite), không thêm dependency; state GetX ở màn chính (`TransactionController` singleton qua `transaction_deps.dart`), sub-form dùng `StatefulWidget` + `WalletRepository` inject (seam PBI 11 — test bơm `FakeWalletRepository`, không cần sqlite native).
- **Chỉ đọc**: không tạo/sửa/xóa giao dịch (spec FR ngoài). Không đổi schema DB.
- Sẵn có: màn Giao dịch (PBI 9) là `StatelessWidget` đọc `TransactionController.data` (`TransactionView{groups,stat}`), icon lọc trong header **no-op** (`_FilterButton`); `transaction_list.dart` là các hàm thuần (`buildDisplayRows` gộp 2 vế transfer → `TxnRow`, `groupDisplayRows`, `monthlyIncomeExpense`); domain `Transaction` mang `categoryId?/tags/category(text snapshot)` (PBI 10/11). Seed 11 dòng mẫu ngày **tương đối** so giờ chạy; 5 ví; danh mục mặc định bảng `categories` (schema v4).
- Repository đang đủ: `allTransactions()` (mọi ví kể cả ẩn), `loadAll()`, `categories({type})` (hoạt động). Không cần method lọc mới.
- Mockup `docs/transaction/05-tim-kiem-loc.svg` chỉ vẽ **form** lọc (app bar teal có ô tìm pill + back, chip loại 4 nút, nhãn "BỘ LỌC NÂNG CAO", 5 dòng bộ lọc nâng cao, dòng tóm tắt, nút Đặt lại/Áp dụng). Trạng thái danh sách **đã lọc** không có mockup — user chốt 2 điểm (R4/R5).
- Nghiệp vụ "giao dịch ví ẩn/danh mục ẩn vẫn trong lịch sử", "transfer gộp 1 dòng", "thu dương chi âm", "đúng 1 dòng mỗi giao dịch" — đã nhất quán PBI 9/10, không đổi.

## R1 — Lọc **trong bộ nhớ** trên toàn bộ giao dịch, không SQL pushdown

**Quyết định**: Giữ nguyên repository; filter là **hàm thuần Dart** chạy trên tập `allTransactions()` đã nạp (module mới `transaction_filter.dart`). Controller nạp `allTransactions + loadAll` 1 lần mỗi `load()`, **cache raw list** trong memory; mọi tính summary/nhóm/sắp xếp tái dùng tập này, không đọc DB lại từng thao tác.

**Lý do**: (1) Màn danh sách PBI 9 **gộp 2 vế transfer thành 1 dòng** — lọc ở SQL theo từng dòng sẽ tách cặp khi tiêu chí chỉ khớp một vế (lọc Ví = vế nguồn khớp, vế đích thì không), phá cấu trúc "1 dòng/1 lần" (SC-010). Lọc trên toàn bộ tập rồi gộp giữ nguyên bất biến. (2) Dòng tóm tắt màn lọc phải **cập nhật tức thời** theo từ khóa/chip → cần đếm + tổng nhiều lần; đọc toàn bộ local vài nghìn dòng nhanh (tiền lệ `ponytail:` ở `transaction_list.dart`), đọc SQL lại từng lần lãng phí. (3) Phép hội (AND) nhiều tiêu chí + "Ẩn giữ lịch sử" (ví ẩn/danh mục ẩn vẫn đếm trong "Tất cả") dễ đúng khi xử lý trên tập đầy đủ.

**Phương án khác**: (a) `queryTransactions(filter)` SQL pushdown + aggregate count/sum — bác vì phá gộp transfer khi lọc Ví (R1), cần đếm/tổng thêm query, phình seam. (b) Filter chạy ngay trong SQL từng màn chi tiết ví — ngoài phạm vi (màn này chỉ là danh sách tổng).

## R2 — Transfer: tiêu chí khớp **một vế** thì giữ **cả nhóm** (group-keep)

**Quyết định**: Lọc từng dòng `Transaction`; riêng dòng `type=transfer` có `transferGroupId`: dòng được giữ nếu **chính nó** khớp điều kiện **hoặc có vế cùng nhóm** khớp — tức nhóm transfer khớp nếu bất kỳ vế nào khớp, luôn giữ trọn cả 2 vế để `buildDisplayRows` gộp được.

**Lý do**: Lọc Ví = "chọn ví A" → khoản chuyển A→B phải hiện **1 dòng** đúng nghĩa màn danh sách (nguồn → đích), không hiện dòng vế lẻ trung tính (bất biến PBI 9). Lọc từ khóa/tiền cũng có thể chỉ khớp một vế (ghi chú chung nhưng amount hai vế cùng độ lớn). SC-010 "không thừa không thiếu".

**Phương án khác**: Lọc rồi mới gộp (vế lẻ fallback `_plainRow`) — transfer hiện sai dạng khi chỉ lọc một ví (bác).

## R3 — Ngữ nghĩa "N kết quả · Tổng: X đ"

**Quyết định**: `N` = **số dòng hiển thị** sau gộp transfer của tập khớp (nhất quán đúng cái màn danh sách vẽ — SC-002 đối chiếu khớp). `Tổng` = **thu dương − chi âm** (tức `Σ income.amount − Σ expense.abs`) trên các dòng thu/chi của tập khớp; dòng transfer & adjustment **có trong N nhưng KHÔNG vào Tổng** (FR-011, acceptance 4). Tổng hiển thị `formatMoney` (số âm tự có dấu `−`); `0` → `0 đ`.

**Lý do**: FR-011 quy định đúng hành vi trên; lấy theo dòng hiển thị để dòng tóm tắt và danh sách không bao giờ lệch nhau. Dùng chung 1 hàm thuần cho dòng tóm tắt màn lọc (live) và chỉ báo màn danh sách (đã áp dụng).

**Phương án khác**: N đếm theo bút toán (2 vế transfer = 2) — lệch số dòng thấy được trên list (bác).

## R4 — Sắp xếp: giữ nhóm ngày khi sắp theo ngày; **phẳng** khi sắp theo số tiền (user chốt)

**Quyết định** (user chốt — "Phẳng khi sắp tiền"): Màn danh sách Giao dịch khi đang lọc:
- Sắp **Ngày mới nhất** (mặc định) → giữ nhóm ngày header (HÔM NAY/dd/MM/yyyy) như PBI 9, nhóm mới nhất trên.
- Sắp **Ngày cũ nhất** → giữ nhóm ngày, nhóm cũ nhất lên trên (đảo hướng).
- Sắp **Số tiền tăng/giảm dần** → danh sách **phẳng** (không header ngày), xếp toàn cục theo **độ lớn `abs(amount)`** (chi 1.200.000 > chi 85.000 đúng trực giác "khoản tiền lớn"), trùng giá trị → ngày mới nhất trước rồi id tăng (ổn định, mỗi dòng đúng 1 lần — SC-010). Transfer/adjustment dùng `abs` amount đã lưu dương (như dòng hiển thị).

**Lý do**: Đã hỏi user vì mockup `05` chỉ vẽ form; thứ tự toàn cục theo tiền mâu thuẫn nhóm theo ngày. User chọn: giữ cấu trúc quen (nhóm ngày) cho sort theo ngày — vốn là sort "tự nhiên" của list; đổi phẳng chỉ khi thật sự sort không theo ngày để "đúng sắp xếp đã chọn" (FR-009/012).

**Phương án khác**: Luôn giữ nhóm ngày / luôn phẳng khi lọc — user bác (chọn phương án phân loại trên).

## R5 — Chỉ báo bộ lọc trên màn danh sách: **thay** card "Thu/Chi tháng này" (user chốt)

**Quyết định** (user chốt — "Thay bằng thanh lọc"): Khi `activeFilter != null`, màn Giao dịch **ẩn card "Thu/Chi tháng này"** và hiện **thanh chỉ báo** đầu danh sách: icon lọc + `N kết quả · Tổng: X đ` (định dạng R3) + nút **"Bỏ lọc"** → về toàn bộ (FR-013). Hết lọc → card tháng hiện lại như cũ.

**Lý do**: Card tháng tính cả tháng (không theo bộ lọc) — giữ cạnh dòng "Tổng" của tập đã lọc gây 2 kiểu tổng đối lập, dễ hiểu nhầm; user chốt thay thế. Không đổi logic card (chỉ ẩn/hiện khi đang lọc) → không hồi quy PBI 9 (test cũ giữ nguyên khi không lọc).

**Phương án khác**: Giữ card + thêm thanh — user bác (dễ nhầm 2 tổng).

## R6 — State bộ lọc sống trong `TransactionController`; form lọc là màn tác vụ trên **bản nháp**

**Quyết định**: 
- Controller (Get singleton, sống suốt shell) giữ `activeFilter` + cache `_all`/`_names` từ lần `load()` gần nhất. `setFilter(f)`/`clearFilter()` chỉ **tính lại view** trên cache (không đọc DB). Bộ lọc **còn hiệu lực qua ra/vào tab Giao dịch** (mỗi lần chọn tab shell gọi `load()` → nạp lại dữ liệu mới, áp filter cũ) — SC-007.
- `SearchFilterScreen` (màn `05`) là màn con **Stateful** (`repository` inject, seam PBI 11; mặc định `ensureWalletRepository`), làm việc trên **bản nháp riêng** của filter: mở lúc đầu = điều kiện `activeFilter` đang áp dụng **hoặc mặc định** nếu chưa áp dụng lần nào (FR-015). Mỗi thay đổi nháp → tính summary live. **Áp dụng** → `Navigator.pop(nháp)`; **quay lại/nút back** → `pop(null)` — màn danh sách giữ nguyên tập cũ (FR-015). "Đặt lại" chỉ reset nháp về mặc định (FR-014), không pop.

**Lý do**: Filter phải bền qua các lần ra/vào tab (SC-007) và không biến mất khi mở lại màn lọc — nơi duy nhất sống dai là controller trong shell. Tách nháp khỏi áp dụng cho đúng FR-015 ("chưa Áp dụng thì không ảnh hưởng"). `now` của màn lọc lấy từ `controller.now` (anchor lần nạp gần nhất, mặc định giờ thật) để widget test deterministic.

**Phương án khác**: Filter state trong `TransactionScreen` (Stateless hiện tại) → mất khi ra/vào tab & khi shell rebuild (bác). Màn lọc tự đọc DB mỗi lần → summary cần dataset riêng, trùng nguồn dữ liệu với list (bác).

## R7 — Lọc Danh mục: chọn cha tự gộp con; so khớp `category_id` + fallback tên; nguồn theo loại chip

**Quyết định**:
- Điều kiện lưu `Set<int>` id danh mục đã chọn (cho phép cha lẫn con). Một giao dịch thu/chi khớp nếu `category_id ∈ (chọn ∪ con của cha được chọn)`; **hoặc** `category_id == null` mà `category` (text) trùng tên một danh mục trong tập hiệu lực — giữ lịch sử cho dòng cũ chưa nối id (spec: danh mục ẩn/giao dịch cũ vẫn hiện theo lịch sử; SC-008 "chọn cha hiện đủ gồm con").
- Nguồn để chọn: `repo.categories(type)` (danh mục **hoạt động**, gồm cha & con). Chip loại đang chọn quyết định danh sách: **Tất cả** → cả thu+chi, **Thu** → chỉ thu, **Chi** → chỉ chi (FR-006). Chip **Chuyển khoản** → dòng Danh mục **vô hiệu & bỏ chọn cũ** (transfer/adjustment không có danh mục; không thể lọc thứ không có).
- UI chọn nhiều: mở sheet danh sách cuộn (icon tròn màu `category.color` + tên + checkbox), chọn xong → dòng bộ lọc hiện **chip đã chọn + ô "+ Thêm"** (mockup `05`); chạm X trên chip → bỏ; cha hiển thị kèm chú thích "(gồm con)" khi có con.

**Lý do**: Spec FR-006/SC-008 bắt chọn cha gộp con; dữ liệu `category_id` chưa đầy đủ cho dòng lịch sử (PBI 11 gán id cho dòng khớp tên, còn lại null) → phải có fallback tên nếu không sẽ **bỏ lọt** giao dịch đang hiển thị (SC-002/010). `repo.categories` đã lọc `isHidden` (đúng "chỉ chọn danh mục hoạt động"; giao dịch của danh mục ẩn vẫn xuất hiện khi không lọc theo nó — giữ lịch sử).

**Phương án khác**: (a) Lọc chỉ theo `category_id` — bỏ lọt dòng null id (bác). (b) Cho chọn cả danh mục ẩn — ngược nguyên tắc picker PBI 11 (bác). (c) Chọn cha bằng drill lưới (như picker ghi mới) — multi-select + nhiều cấp khó dùng trong 1 dòng lọc (dùng sheet list thay).

## R8 — Lọc Ví: một ví hoặc "Tất cả các ví"; gồm ví ẩn khi xem lịch sử

**Quyết định**: Điều kiện `walletId` nullable (null = tất cả, mặc định). Sheet chọn: dòng "Tất cả các ví" (mặc định) + từng ví xếp `walletsByDisplayOrder` (hoạt động trước theo sortOrder, ví ẩn cuối, có nhãn "(đã ẩn)" qua `Wallet.hiddenName`) — người dùng có thể chọn cả ví ẩn để xem riêng lịch sử của nó (FR-007). Gồm thẻ tín dụng, sổ tiết kiệm (mọi loại). Transfer theo R2 (chọn ví A vẫn hiện đủ 1 dòng A→B).

**Lý do**: FR-007 "nhất quán nguyên tắc ẩn giữ lịch sử"; tái dùng `walletsByDisplayOrder` có sẵn.

**Phương án khác**: Chỉ liệt kê ví hoạt động — không xem được lịch sử ví ẩn đã chủ động ẩn (bác).

## R9 — Tìm kiếm từ khóa: chuẩn hóa tiếng Việt không dấu; substring trên note/category/tags; debounce

**Quyết định**: Hàm thuần `normalizeSearch(String)` — lowercase + **bỏ dấu tiếng Việt** qua bảng ánh xạ ký tự (ă â đ ê ô ơ ư + nguyên âm dấu sắc/huyền/hỏi/ngã/nặng, không thêm dependency). Khớp từ khóa: chuẩn hóa từ khóa & chuẩn hóa từng chuỗi `note`, `category`, `tags` rồi **substring** (FR-002: "an uong" ↔ "Ăn uống"; không phân biệt hoa/thường & dấu). Summary live khi gõ có **debounce ~250ms** (Timer, hủy khi dispose) — spec giả định "độ trễ nhỏ khi gõ"; chip/range/tắt timer cập nhật ngay. Gõ nhanh/dài không treo (SC-003/004).

**Lý do**: Spec bắt bỏ dấu; viết bảng ánh xạ 1 file thuần (không thêm package). Debounce bảo vệ summary trên vài nghìn dòng.

**Phương án khác**: Dependency `diacritics` — thêm lib cho việc vài chục dòng (bác, rung 3: stdlib/không thêm).

## R10 — Khoảng số tiền: ô "Từ/Đến" mở sheet nhập dùng lại `AmountKeypad`; min > max chặn Áp dụng

**Quyết định**: Mỗi ô Từ/Đến hiển thị giá trị `formatMoney` hoặc placeholder ("Từ 0 đ" gợi ý mockup khi trống); chạm → bottom sheet: preview lớn + `AmountKeypad` (đã có PBI 11) + nút Xong, trả `int?` (null = bỏ giới hạn đầu đó). Lưu `amountMin/amountMax` nullable. Khớp theo `abs(amount)` **bao gồm biên** (FR-008: chi 85.000 ∈ 0–100.000; income +12.000.000 abs 12.000.000). Nếu `min != null && max != null && min > max` → dòng Khoảng số tiền báo lỗi "Số tiền tối thiểu không được lớn hơn tối đa", **vô hiệu Áp dụng** (FR-008: ngăn trả kết quả sai); summary khi đó hiện 0 kết quả (hoặc giữ nguyên — chọn: hiện 0 kèm đỏ, không nhập nhằng).

**Lý do**: Tái dùng `AmountKeypad`/`formatAmount` có sẵn thay vì TextField + bàn phím hệ thống, đúng style nhập số của app. Biên độ giá trị tuyệt đối là spec chốt (giả định). Chặn min>max ở UI là "ngăn" (spec cho phép ngăn hoặc coi vô hiệu) — rõ ràng nhất.

**Phương án khác**: Ô text nhập trực tiếp (như transfer `parseAmount`) — chưa khớp UX numpad & dễ sai định dạng (bác). Coi min>max vô hiệu không báo — người dùng không hiểu vì sao (bác).

## R11 — Khoảng thời gian: preset + tùy chỉnh; anchor `now`

**Quyết định**: Row hiển thị "dd/MM/yyyy - dd/MM/yyyy" (hoặc "Toàn bộ"); chạm → bottom sheet preset: **Hôm nay / Tuần này / Tháng này / Toàn bộ** + mục **"Tùy chọn…"** mở 2 `showDatePicker` (ngày bắt đầu/ngày kết thúc; ràng buộc `firstDate/lastDate` chặn start > end — FR-008 edge). Khớp theo **ngày lịch**: `t.date >= start(00:00)` và `< end + 1 ngày`. Preset mặc định form = **Tháng này** (mockup `05`, FR-005); "Toàn bộ" = bỏ giới hạn (hai đầu null). Lưu `datePreset` (để mở lại hiển thị preset đã chọn) + cặp `dateStart/dateEnd` đã giải (tùy chỉnh do user đặt). Tuần = thứ Hai đầu tuần.

**Lý do**: FR-005 đòi preset + custom + ngăn khoảng vô lý; default Tháng này. Giữ preset riêng để mở lại màn lọc hiện đúng lựa chọn (SC-007 không nhân đôi), cặp ngày đã giải cho phép truy vấn ngay không phụ thuộc "now".

**Phương án khác**: Lưu chỉ cặp ngày — mở lại hiện "dd/MM" thay vì tên preset, lệch SC-007 trực giác (bác). RangePicker thư viện — không thêm dep (bác).

## R12 — Chip loại: Tất cả / Thu / Chi / Chuyển khoản (không có chip "Điều chỉnh")

**Quyết định**: 4 chip đúng mockup; ánh xạ Thu→`income`, Chi→`expense`, Chuyển khoản→`transfer`. **Điều chỉnh số dư** (`adjustment`) chỉ xuất hiện dưới **Tất cả** (không chip riêng — mockup 4 chip; FR-004). Chọn loại ⇒ chỉ giữ giao dịch đúng loại (FR-004); adjustment + transfer không cộng vào Tổng (R3/FR-011). Chip đang chọn tô `AppColors.teal` chữ trắng, còn lại nền trắng viền `#E0E0E0` (mockup/FR-004), hàng cuộn ngang.

**Lý do**: Bám mockup & FR; adjustment niche, không thêm chip gây nhiễu hàng chip.

## R13 — Controller `load()` không hồi quy; view đã lọc là đường dữ liệu phụ

**Quyết định**: Giữ nguyên `TransactionView.data` cho trạng thái **không lọc** (test cũ PBI 9 không đổi). Thêm trên controller: `Rx<TxnSearchFilter?> activeFilter`, `Rx<FilteredTxView?> filtered` (groups khi sort ngày / `flatRows` khi sort tiền + `count/signedTotal`), cache `_all`/`_names`, `DateTime now` (anchor). `load()`: nạp all + names, **luôn** dựng `data` (không lọc, cho đúng test cũ & khi `activeFilter` null), rồi nếu `activeFilter != null` → dựng `filtered`. Screen đọc `activeFilter` để chọn nhánh hiển thị.

**Lý do**: Tối thiểu đụng chạm, không làm vỡ 248 test cũ (additive). View phụ cho đúng FR-012 (danh sách đã lọc) mà không đổi cấu trúc `TransactionView`.

**Phương án khác**: Gộp view lọc vào `TransactionView` → đổi cấu trúc shared, phình hồi quy test (bác).

## R14 — Empty state & ràng buộc hiển thị an toàn

**Quyết định**: (1) Trong form: dòng tóm tắt "0 kết quả" khi không khớp (không lỗi — FR-016). (2) Danh sách sau Áp dụng khi tập rỗng: thanh chỉ báo "0 kết quả · Tổng: 0 đ" + nội dung "Không có giao dịch khớp bộ lọc." + hint "Bỏ lọc để xem toàn bộ" (khác empty "Chưa có giao dịch nào." khi không lọc). (3) Cỡ chữ lớn + vùng an toàn: toàn màn cuộn được, nút Đặt lại/Áp dụng không bị cắt (bottomNavigationBar cố định như `SubPageScaffold`, SC-011). (4) Màn chỉ mở sau khi app đã mở khóa — route trong shell sau boot-gate PBI 3, không lộ số tiền qua màn khóa (FR-018, không làm thêm).

**Lý do**: Các edge spec chỉ rõ; tái dùng `SubPageScaffold.bottomNavigationBar` cho hàng nút chân form (pattern PBI 8/11).

**Phương án khác**: — 

## Kết luận

Không còn `NEEDS CLARIFICATION`. Không đổi schema (`schemaVersion` giữ 4, **không cần** `build_runner`), không thêm dependency, không thêm method repository — mọi logic đọc-lọc là hàm thuần mới + widget màn form + nối controller/màn danh sách. User đã chốt 2 lựa chọn hiển thị (R4 sort phẳng theo tiền; R5 thay card bằng thanh lọc).
