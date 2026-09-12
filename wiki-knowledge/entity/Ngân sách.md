---
title: "Ngân sách"
date: 2026-09-12
tags: [module, budget, entity]
sources:
  - ../docs/budget/nghiep-vu-ngan-sach.md
  - ../docs/budget/man-hinh-01-tong-quan-ngan-sach.svg
  - ../docs/budget/man-hinh-02-them-ngan-sach.svg
  - ../docs/budget/man-hinh-03-chi-tiet-ngan-sach.svg
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../../.specify/specs/20/spec.md
  - ../../.specify/specs/21/spec.md
---

# Ngân sách

Đặt giới hạn chi cho một danh mục theo kỳ, theo dõi mức dùng **real-time** → kiểm soát tài chính **chủ động** thay vì ghi chép thụ động. Thuộc **GĐ2**.

**Trạng thái:** **2a** (ngân sách theo danh mục + theo dõi tiến độ, chưa push) — **PBI 20** (màn `01` Tổng quan, màn `02` Thêm/Sửa, bảng `budgets` schema **v6**). **Màn `03` Chi tiết ngân sách + phần 2c ở mức tối thiểu** (tiến độ/số tiền vượt/ngày còn lại, cảnh báo nhịp, so sánh 3 kỳ dự kiến–thực tế, đổi kỳ đang xem, **lưu trữ** ngân sách) — **PBI 21**, schema **v7**. Còn lại: **2b** + phần còn lại của **2c** (xem [[Lộ trình phát triển]]).

## Mô hình dữ liệu (đã chốt cho 2a + 03 — schema v7)
Bảng `budgets` **7 cột**: `id, category_id, amount, period(weekly|monthly|yearly), is_recurring(default true), start_date, is_archived(default false)`.

- **`is_archived` (PBI 21)**: cờ **ngừng theo dõi**, một chiều. Migration v6→v7 = `addColumn` có default `false` ⇒ mọi dòng cũ nhận `false`, **không seed**, không thêm bảng.
- `budgets()` **trả cả ngân sách đã lưu trữ** (repository **không** lọc) — lọc ở tầng view: `buildBudgetOverview` bỏ qua dòng `isArchived` khỏi **cả danh sách lẫn thẻ tổng**. Đây là chỗ duy nhất phải nhớ khi thêm consumer mới.
- Lưu trữ **không** thêm method repository: dùng `updateBudget(budget.copyWith(isArchived: true))` đã có.

**Chưa có hiệu lực** (đừng giả định là đã có): `scope`, `name`, `wallet_ids`, `currency`, `period_start_rule`, `end_date`, `alert_thresholds`, `rollover_unused`, `status`, `created_at/updated_at`, `archived_at`.

**Không có bảng `budget_period_snapshots`.** Doc §9 cho phép tính runtime khi dữ liệu nhỏ; "đã chi / % / còn lại / ngày còn lại / số thực tế từng kỳ" đều là **đại lượng tính toán**, dựng lại mỗi lần nạp màn từ `budgets` + `transactions` + `categories`. Hệ quả tốt: sửa `amount` **không thể** hồi tố kỳ trước, và giao dịch Chi bị sửa/xoá sau đó tự khớp lại (FR-018). **PBI 21 xác nhận lại quyết định này** — biểu đồ so sánh nhiều kỳ cũng tính từ dữ liệu, không snapshot.

## Quy tắc nghiệp vụ (đã chốt)
1. **Chỉ giao dịch Chi** tính vào ngân sách; Thu và **chuyển khoản nội bộ** bị loại hoàn toàn — ở **mọi** số liệu và mọi danh sách.
2. Khớp phạm vi: `category_id` **bằng chính danh mục HOẶC là con trực tiếp** của nó (cây 2 cấp, không lấy cháu). Khớp theo `category_id` chứ không theo text tên — dòng cũ nâng cấp `< v4` có `category_id = null` **không** được suy đoán theo tên.
3. Ngày tính = `transaction_date ∈ [periodStart, periodEnd)` — **end độc quyền**.
4. **Đã chi = `-Σ amount`** (amount trong DB có dấu, Chi = âm).
5. **Mốc kỳ**: Tháng/Năm **dương lịch**; **Tuần bắt đầu Thứ Hai**. `periodStartRule` ngoài phạm vi.
6. **Không chồng lấn**: chặn 2 ngân sách **cùng `category_id` + cùng `period`** có **khoảng hiệu lực** giao nhau. Khoảng hiệu lực = `start_date → ∞` nếu `is_recurring`, ngược lại = **đúng kỳ chứa `start_date`**. Cùng danh mục **khác chu kỳ** được song song. Khi sửa, bỏ qua chính nó theo `id`.
7. **Tạo giữa kỳ** → đã chi khởi tạo bằng tổng Chi đã có **từ đầu kỳ** (không phải 0).
8. Sửa `amount` giữa kỳ → áp dụng kỳ hiện tại, không hồi tố kỳ đã qua.
9. **Một phép lọc duy nhất** (PBI 21, R11): `budgetPeriodTransactions()` trong `core/budget/budget_view.dart` trả danh sách Chi trong kỳ (mới nhất trước); `budgetSpent` **cộng lại chính danh sách đó**. Màn `03` hiển thị `take(5)` của cùng danh sách ⇒ **tổng danh sách không thể lệch** số "đã dùng" (SC-005). Đừng viết bộ lọc thứ hai.
10. **Lưu trữ** (PBI 21): ngân sách ngừng theo dõi nhưng **không xoá/sửa bất kỳ giao dịch nào**; số dư ví bất biến (SC-007). Một chiều trong đợt này — **chưa có phục hồi và chưa có nơi xem lại** (quyết định đã chốt 2026-09-12; màn `01` giữ nguyên mockup, không thêm nhóm "Đã lưu trữ").

## Vòng đời kỳ & trạng thái (suy ra, không lưu cột `status`)
| Trạng thái | Điều kiện | Kỳ dùng để tính "đã chi" | Vào thẻ tổng? |
|---|---|---|---|
| `active` | `is_recurring`, **hoặc** không lặp lại mà `now` nằm trong kỳ chứa `start_date` | Tháng → **tháng đang xem**; Tuần/Năm → kỳ chứa `now` | ✅ |
| `ended` | không lặp lại và `now` đã ra ngoài kỳ chứa `start_date` | kỳ chứa `start_date` (cố định) | ❌ — hiện "Đã kết thúc" |
| `invalid` | danh mục không còn trong bảng `categories` | (vô nghĩa) | ❌ — hiện "Danh mục đã bị xóa", **không** tự xoá ngân sách, nhắc gán lại |
| *đã lưu trữ* | `is_archived = true` | — | ❌ — biến mất khỏi màn `01`; dữ liệu giao dịch còn nguyên |

- `is_recurring = true` sang kỳ mới **tự tiếp tục** với cùng giới hạn (không sinh bản ghi mới).
- `rollover_unused` (cộng dồn) và "Sao chép tháng trước" **hiển thị theo mockup nhưng chưa hoạt động** — thuộc 2b.

## Cảnh báo & hiển thị tiến độ
- **3 dải màu** (chốt theo mockup `01`, xem [[Design system]]): `< 80%` → thanh + % **teal**; **`80–99%` → thanh coral nhạt (`alpha 0.6`), chữ coral**; `≥ 100%` → thanh **coral đậm**, chữ coral. Màn `03` dùng **đúng** 3 dải này cho số tiền đã dùng, huy hiệu và thanh tiến độ.
- Màn `01`: dòng vượt giới hạn **chỉ hiện %**, **không** hiện số tiền vượt (số tiền vượt thuộc màn `03`).
- **Huy hiệu trạng thái màn `03`** (R8): `< 80%` "Bình thường {p}%" · `80–99%` "Sắp đạt {p}%" · `≥ 100%` "Vượt {p}%" (nền coral nhạt từ 80% trở lên). **Đúng 100% hiển thị "Vượt 100%"** với số tiền vượt `0` — FR-005 chốt "từ 100% trở lên" dùng "Vượt".
- **Số ngày còn lại — LƯU Ý LỆCH 1 NGÀY GIỮA 2 MÀN**: màn `03` tính **gồm hôm nay** (`elapsed = clamp(today − start + 1, 0, total)`, `left = total − elapsed`, sàn 0) ⇒ tháng 9 ngày 12 ra **18 ngày**, đúng mockup `03`. Màn `01` (PBI 20) vẫn dùng `end − today` ⇒ ra 19. **Cố ý không đồng bộ trong PBI 21** (ngoài phạm vi, màn `01` có test riêng khẳng định số cũ). Muốn đồng bộ: đổi màn `01` sang gọi `budgetDaysLeft` — một dòng + cập nhật 1 khẳng định test.
- **Cảnh báo tốc độ chi tiêu** (FR-007, màn `03`): hiện khi `!ended && %đã dùng > %ngày đã qua` — **chỉ một băng** (chi nhanh hơn), không có băng "chi chậm hơn", **không** dự báo số tiền tới hết kỳ. Kỳ **đã kết thúc** thì băng **ẩn** (khi đó vị trí ngày còn lại hiện "Đã kết thúc").
- Thẻ tổng màn `01`: nhãn "Tổng ngân sách tháng này", cặp **tổng đã chi / tổng giới hạn**, thanh tiến độ tổng, "Còn lại … đ", "… ngày còn lại"; tổng **chỉ cộng dòng `active`** (và nay loại cả dòng đã lưu trữ).
- **Thứ tự danh sách màn `01`**: `active` **giảm dần theo %**; dòng `ended`/`invalid` xuống cuối, trong nhóm sắp theo tên.
- Bộ chọn kỳ ở màn `01` **chỉ điều khiển ngân sách chu kỳ Tháng**; dòng Tuần/Năm luôn hiện tiến độ kỳ hiện tại của chính nó + **nhãn chu kỳ**.
- Trạng thái rỗng màn `01`: lời nhắc + nút "Thêm ngân sách", **không** hiện thẻ tổng/danh sách trơ.

## Màn `03` Chi tiết Ngân sách (PBI 21 — mockup `man-hinh-03`)
Màn **con đè shell**: `SubPageScaffold` app bar teal **2 dòng** (tham số `subtitle` mới, `toolbarHeight 68`), **không** bottom nav. Điểm vào: **chạm một dòng ngân sách ở màn `01`** (thay hành vi cũ mở thẳng form `02` — FR-001); form `02` nay vào từ nút "Chỉnh sửa".

**Kỳ đang xem**: mặc định kỳ chứa `now`; ngân sách **không lặp lại** → kỳ chứa `start_date` (kỳ đã kết thúc — FR-020). Đổi được qua nút lịch góc phải → `showModalBottomSheet` liệt kê `budgetPeriodOptions()` **giảm dần**, kỳ đang xem đánh dấu teal; chọn → `setState` tính lại **toàn bộ** màn. Danh sách kỳ **chỉ** từ kỳ chứa `start_date` đến kỳ hiện tại — **không có kỳ nào trước khi ngân sách bắt đầu**; ngân sách không lặp lại ⇒ **đúng 1 lựa chọn**.

**Thứ tự thân màn** (theo mockup): thẻ tiến độ → băng cảnh báo nhịp (nếu có) → khối **SO SÁNH DỰ KIẾN • THỰC TẾ** → nhóm **GIAO DỊCH TRONG KỲ** (tối đa **5** dòng + "Xem tất cả") → 2 nút cố định chân màn.

- **Thẻ tiến độ**: "Đã dùng" + số tiền cỡ lớn theo 3 dải; "trên {giới hạn} giới hạn"; "Trạng thái" + huy hiệu; thanh tiến độ bo `3px`; dòng cuối trái = **"Vượt {số} đ"** khi `≥ 100%` ngược lại **"Còn lại {số} đ"**, phải = **"{n} ngày còn lại"** hoặc **"Đã kết thúc"**.
- **Băng cảnh báo nhịp**: nền coral nhạt, icon `!` tròn coral, "Tốc độ chi tiêu nhanh hơn dự kiến" + "Đã dùng {p}% ngày nhưng chi {q}% ngân sách".
- **Biểu đồ so sánh**: `fl_chart` `BarChart` — **cột đôi mỗi kỳ** (Dự kiến = một màu **trung tính** `dotEmpty.withValues(alpha: 0.5)` cho **mọi** kỳ; Thực tế = **teal** nếu kỳ đó không vượt, **coral** nếu vượt), **đường mốc giới hạn nét đứt** (`dashArray [3,3]`, màu `dotEmpty`) kèm nhãn "Dự kiến {giới hạn}", nhãn kỳ dưới trục (`T9` / `7/9` / `2026` theo chu kỳ) với **kỳ đang xem in đậm**; `maxY = max(giới hạn, max đã chi) × 1.15`; không grid, không border.
  - **Luôn 3 kỳ gần nhất tính đến kỳ đang xem** (kỳ đang xem là **cột cuối**), đi lùi theo đúng bước chu kỳ và **không vượt quá kỳ chứa `start_date`** ⇒ ngân sách mới có 1–2 kỳ thì biểu đồ vẽ đúng 1–2 cặp cột, không đòi tối thiểu (kịch bản 19).
  - **Cột "Dự kiến" = `amount` HIỆN TẠI cho mọi kỳ** (giả định spec: không lưu giới hạn theo thời điểm) ⇒ sửa giới hạn thì mốc + cột Dự kiến **đổi theo**, còn **số thực tế của các kỳ trước không hồi tố**.
- **Danh sách giao dịch trong kỳ**: icon bubble màu danh mục, tiêu đề = **ghi chú** (rỗng → tên danh mục), dòng phụ = `relativeDayLabel + ', ' + HH:mm` (VD "Hôm nay, 12:30"), số tiền **coral** dạng `-185.000 đ`; kỳ rỗng → trạng thái rỗng. Chạm dòng **chưa** mở chi tiết giao dịch (ngoài phạm vi đợt này).
- **"Xem tất cả"**: dựng `TxnSearchFilter` (`Chi` + `DatePreset.custom` khoảng kỳ đang xem + phạm vi danh mục **gồm con** + mới nhất trước) → `ensureTransactionController().setFilter()` → `popUntil(isFirst)` → đổi tab Giao dịch qua `onSelectTab` (callback `AppShell → màn 01 → màn 03`). Dùng lại hạ tầng lọc PBI 12 nên **khớp số** với thẻ tiến độ (SC-005) và **đang xem kỳ cũ thì lọc theo kỳ cũ**.
- **2 nút cuối màn** — hiện ở **mọi kỳ** và **cả khi danh mục đã bị xoá** (FR-024 + luật 10): **"Chỉnh sửa"** → form `02`; lưu xong nạp lại và **giữ kỳ đang xem** (khớp `range.start`; **đổi chu kỳ** làm kỳ đó không còn tồn tại → về kỳ mặc định của chu kỳ mới, không lỗi). **"Lưu trữ ngân sách"** → hộp thoại xác nhận → ghi `is_archived = true` → đóng màn về `01`.
- **4 nhánh thân màn**: đang nạp (spinner) → lỗi ("Không đọc được ngân sách." + Thử lại) → **không hợp lệ** (`category == null`: thông báo + nhắc gán lại, **ẩn** thẻ tiến độ/biểu đồ/danh sách, 2 nút vẫn hiện) → nội dung.

## Seam dữ liệu & màn hình
- `WalletRepository` mở rộng **3 method** `budgets() / insertBudget / updateBudget` (PBI 20) — **không đổi chữ ký ở PBI 21**, chỉ map thêm cột `is_archived`. Repository **không** tự validate chồng lấn (luật ở module thuần + UI) và **không** lọc archived (tầng view lọc).
- Module thuần: `core/budget/{budget, budget_view, budget_detail, budget_rules}.dart` — **`budget_detail.dart` là file mới PBI 21** (màn `03`): `budgetPeriodOptions`, `budgetDefaultRange`, `budgetDaysLeft`, `budgetElapsedPercent`, `budgetPaceWarning`, `budgetComparisonSeries`, `buildBudgetDetail` + `class {BudgetPeriodSummary, BudgetDetail}`. Tách khỏi `budget_view.dart` (đã 236 dòng, chỉ phục vụ màn `01`).
- Màn `01` **Tổng quan Ngân sách**: màn **cấp tab** đẩy từ tab Báo cáo (nút `+` riêng, **không** nút back) nên tự dựng `AppBottomNavBar` + FAB thêm giao dịch **dùng chung**; chạm tab khác → `pop()` rồi đổi tab thật qua callback từ `AppShell`. **Ngoại lệ có lý do** của quy tắc "màn con đè shell thì không bottom nav". Quay về từ màn `03` → nạp lại im lặng (có thể vừa sửa hoặc vừa lưu trữ).
- Màn `02` Thêm/Sửa: sub-page, nút "Lưu ngân sách" cao `44px`; ô số tiền chỉ nhận chữ số + định dạng phân tách nghìn ngay khi gõ; chế độ Sửa giữ nguyên `start_date`.
- Màn `03`: `ValueKey` cho test — `budget-detail-period-picker`, `budget-detail-period-<startISO>`, `budget-detail-edit`, `budget-detail-archive`, `budget-detail-see-all`, `budget-detail-confirm-archive`, `budget-detail-cancel-archive`.
- **Giới hạn đã biết**: picker danh mục tái dùng (PBI 11) **không chọn được danh mục cha có con** ⇒ từ UI hiện chỉ tạo được ngân sách cho danh mục không con / danh mục con. Luật gộp con vào cha vẫn đúng ở tầng tính toán.
- Mọi nhãn tĩnh của 3 màn có bản dịch **vi/en** (PBI 19). **Bẫy `trParams`**: tham số **không** được chứa `%` — `'Vượt @p%'` phải truyền `p = '107'` (chuỗi đã có `%` sẽ ra `107%%`).
- **`fl_chart ^1.2.0` đã dùng thật lần đầu ở PBI 21** (trước đó chỉ khai báo trong `pubspec.yaml`) — xem [[Stack kỹ thuật]].

## Ngoài phạm vi (2b + phần còn lại của 2c)
Ngân sách **tổng** (`scope = total`), ngân sách theo **ví**, **cộng dồn** phần chưa dùng, tuỳ chỉnh **ngưỡng cảnh báo**, **sao chép ngân sách kỳ trước**, **cảnh báo đẩy/thông báo hệ thống**, **dự báo số tiền chi tới hết kỳ**, băng "chi chậm hơn dự kiến", **xóa cứng ngân sách**, **phục hồi ngân sách đã lưu trữ** và **mọi nơi xem lại ngân sách đã lưu trữ**, kỳ tài chính lệch ngày, **đa tiền tệ**, phần còn lại của tab Báo cáo (biểu đồ thu/chi, phân bổ danh mục, xuất Excel/PDF), hiệu ứng công tắc "Ẩn số dư" lên số tiền ngân sách.

## Liên kết
- [[Giao dịch]] — nguồn "đã chi" (chỉ Chi, đúng kỳ); màn Giao dịch là đích của "Xem tất cả".
- [[Danh mục]] — phạm vi `category_id` + con; danh mục bị xoá → trạng thái không hợp lệ.
- [[Ví & Tài khoản]] — đợt này ngân sách áp dụng **tất cả ví** (ví ẩn không ảnh hưởng).
- [[Hồ sơ & Bảo mật]] — tiền tệ mặc định & kỳ tài chính lệch (2b+).
- [[Design system]] — 3 dải màu tiến độ, cột "Dự kiến" trung tính + đường mốc nét đứt.
- [[Stack kỹ thuật]] — `fl_chart` (BarChart) đã dùng.
- [[Lộ trình phát triển]] — 2b + phần còn lại của 2c.
