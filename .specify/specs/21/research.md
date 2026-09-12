# Nghiên cứu kỹ thuật: PBI 21 — Chi tiết Ngân sách (tiến độ, tốc độ chi tiêu, so sánh nhiều kỳ)

**Mã PBI**: 21 · **Ngày**: 2026-09-12 · **Liên kết spec**: [spec.md](./spec.md)

Không còn `NEEDS CLARIFICATION`: spec đã "Đã làm rõ", checklist `requirements.md` xác nhận 0 điểm mở. Dưới đây là các quyết định kỹ thuật cho những chỗ spec **cố ý** để trống (chi tiết triển khai).

## R1 — Điểm vào: chạm dòng ở màn Tổng quan → **đẩy màn Chi tiết**, không mở thẳng form

- **Quyết định**: `budget_overview_screen.dart` đổi hành vi chạm dòng từ `BudgetFormScreen` sang `BudgetDetailScreen(budgetId: …, repository: …, now: …, onSelectTab: widget.onSelectTab)`. Màn Chi tiết dùng `SubPageScaffold` (app bar teal + nút back, **không** bottom nav — FR-001); nút **"Chỉnh sửa"** trong thân màn mới là đường vào form `02`. Quay về từ Chi tiết ⇒ nạp lại màn Tổng quan (im lặng) vì có thể vừa sửa hoặc lưu trữ.
- **Lý do**: FR-001 nói rõ màn Chi tiết **thay cho** hành vi cũ; form `02` vẫn nguyên vẹn nên không mất đường sửa, chỉ đổi điểm vào.
- **Phương án khác**: giữ chạm dòng = mở form, thêm nút "Chi tiết" riêng trên dòng — vi phạm FR-001 và mockup `03` không có nút đó.

## R2 — App bar 2 dòng: **thêm tham số `subtitle` cho `SubPageScaffold`**

- **Quyết định**: mở rộng `core/widgets/sub_page_scaffold.dart` bằng tham số **tùy chọn** `String? subtitle`; khi có, app bar dựng `Column` (tiêu đề 16px + dòng phụ 11px trắng 80%) và nâng `toolbarHeight` lên 68. Màn Chi tiết truyền `title: tên danh mục`, `subtitle: 'Ngân sách @chu kỳ • @kỳ'`, `actions: [nút đổi kỳ]`.
- **Lý do**: mockup `03` vẽ app bar cao 76 có 2 dòng; `SubPageScaffold` hiện chỉ nhận `String title`. Thêm tham số tùy chọn là thay đổi **additive** — 8 màn đang dùng không đổi hành vi, không test nào đỏ.
- **Phương án khác**: màn Chi tiết tự dựng `Scaffold` + `AppBar` riêng — nhân bản cấu hình app bar thương hiệu ở một chỗ nữa, dễ lệch theme (dark mode).

## R3 — Schema **v7**: thêm cột `is_archived` vào `budgets`, không thêm bảng

- **Quyết định**: `Budgets` thêm `BoolColumn isArchived` (default `false`); `schemaVersion => 7`; migration `if (from < 7) addColumn(budgets, budgets.isArchived)`. Domain `Budget` thêm `final bool isArchived` (mặc định `false` — **mọi chỗ khởi tạo cũ biên dịch nguyên**) + `copyWith`. `budgets()` **giữ nguyên** (trả cả đã lưu trữ); `buildBudgetOverview` bỏ qua dòng `isArchived`. Lưu trữ = `updateBudget(budget.copyWith(isArchived: true))` — **không** thêm method repository nào.
- **Lý do**: FR-016/FR-017 chỉ cần một cờ "ngừng theo dõi" + giữ nguyên dữ liệu; `addColumn` có default là migration an toàn nhất (bám nhánh v4 của `transactions`). Không cần mốc thời gian lưu trữ vì đợt này **chưa có nơi xem lại** và chưa có phục hồi.
- **Phương án khác**:
  - *Bảng `budget_archives` riêng* — thêm bảng + join chỉ để lưu 1 bit.
  - *`archived_at` DateTime nullable* — thừa cột chưa ai đọc; thêm khi có màn "Đã lưu trữ" (PBI sau).
  - *Xóa cứng* — doc §4.7 loại trừ (ngân sách có lịch sử nhiều kỳ), và FR-017 cấm mất dữ liệu.

## R4 — Module thuần mới `core/budget/budget_detail.dart`, không nhồi vào `budget_view.dart`

- **Quyết định**: tách file mới cho toàn bộ số liệu màn `03`: `budgetPeriodOptions`, `budgetPeriodSummary`, `budgetComparisonSeries`, `budgetDaysLeft`, `budgetElapsedPercent`, `budgetPaceWarning`, `class BudgetDetail`.
- **Lý do**: `budget_view.dart` đã 236 dòng và chỉ phục vụ màn `01`; đây là **một màn khác** với bộ hàm khác (kỳ đang xem, chuỗi so sánh, nhịp thời gian). Tách file giữ mỗi module một trách nhiệm, test độc lập — bám nếp `transaction_list.dart` vs `transaction_filter.dart`.
- **Phương án khác**: nhồi chung `budget_view.dart` — file ~450 dòng trộn 2 màn, sửa màn `01` dễ chạm màn `03`.

## R5 — Kỳ đang xem & danh sách kỳ: **từ kỳ chứa `startDate` đến kỳ chứa `now`**, không lặp lại thì dừng ở kỳ `startDate`

- **Quyết định**: mặc định kỳ đang xem = kỳ chứa `now`; với ngân sách **không lặp lại** = kỳ chứa `startDate` (FR-020). Bộ chọn kỳ sinh theo bước chu kỳ từ kỳ chứa `startDate` tới **cận trên** = kỳ hiện tại, nhưng nếu `!isRecurring` thì cận trên = kỳ chứa `startDate` (đúng 1 lựa chọn).
- **Lý do**: FR-023 + kịch bản 3 chốt "không có kỳ nào trước khi ngân sách bắt đầu". Với ngân sách không lặp lại đã kết thúc, FR-020 đòi mở đúng kỳ đã kết thúc ⇒ liệt kê thêm kỳ hiện tại (nơi ngân sách không còn hiệu lực) là vô nghĩa; chặn ở kỳ `startDate` làm kịch bản 17 và 3 cùng đúng.
- **Phương án khác**: luôn liệt kê tới kỳ hiện tại — ngân sách kết thúc tháng 8 vẫn cho chọn tháng 9 với số liệu 0%, dễ hiểu nhầm là ngân sách còn hiệu lực.

## R6 — "Số ngày còn lại" và "% ngày đã qua": **tính cả hôm nay**

- **Quyết định**: `totalDays = range.end − range.start` (nửa mở); `elapsedDays = clamp(today − range.start + 1, 0, totalDays)`; `daysLeft = totalDays − elapsedDays` (sàn 0); `elapsedPercent = elapsedDays / totalDays × 100`. VD tháng 9, hôm nay 12/09: `totalDays 30`, `elapsed 12` (40%), `daysLeft 18` — **khớp mockup `03` ("18 ngày còn lại")**.
- **Lý do**: công thức tự nhất quán (`elapsed + left = total`), không bao giờ âm, ngày cuối kỳ ra 0 (đúng biên spec), và tái hiện được đúng con số của mockup.
- **Phương án khác**: `range.end − today` (không tính hôm nay) như màn `01` đang làm ⇒ tháng 9 ngày 12 ra 19. **Không sửa màn `01`** trong PBI này (ngoài phạm vi, có test riêng) — xem mục Rủi ro 2.

## R7 — Cảnh báo tốc độ chi tiêu: `% đã dùng > % ngày đã qua` **và kỳ chưa kết thúc**

- **Quyết định**: `budgetPaceWarning(usedPercent, elapsedPercent, ended)` → `!ended && usedPercent > elapsedPercent`. Chỉ có **một** băng duy nhất (chi nhanh hơn); không làm băng "chi chậm hơn".
- **Lý do**: FR-007 + giả định spec (mockup không vẽ trường hợp chi chậm); biên "kỳ đã kết thúc" ẩn băng được chốt 2026-09-12.
- **Phương án khác**: dự đoán tuyến tính ra số tiền cụ thể tới hết kỳ — spec đưa vào "Ngoài phạm vi".

## R8 — Huy hiệu trạng thái: "Bình thường / Sắp đạt / Vượt {…}%" theo **3 dải của PBI 20**

- **Quyết định**: `< 80%` → `'Bình thường @p%'`; `80–99%` → `'Sắp đạt @p%'`; `>= 100%` → `'Vượt @p%'`. Dùng lại `budgetProgressLevel` (3 dải) cho màu chữ/thanh — **không** phát minh ngưỡng mới.
- **Lý do**: FR-005 chốt cách diễn đạt; FR-004 chốt màu theo đúng 3 dải đã có ⇒ một nguồn duy nhất cho cả màu lẫn chữ.
- **Phương án khác**: nhãn riêng cho mốc đúng 100% ("Đạt giới hạn") — FR-005 nói "từ 100% trở lên" dùng "Vượt"; đúng 100% hiển thị "Vượt 100%" (số tiền vượt = 0), ghi nhận ở mục Rủi ro 3.

## R9 — Biểu đồ: dùng **`fl_chart`** (đã khai báo trong `pubspec.yaml`, chưa dùng ở đâu)

- **Quyết định**: `BarChart` với `BarChartGroupData` (2 `BarChartRodData`: Dự kiến màu trung tính `#D6D2C4`-tương đương token, Thực tế teal/coral), `ExtraLinesData.horizontalLines` + `dashArray` cho đường mốc giới hạn, `FlTitlesData` cho nhãn kỳ dưới trục, `FlGridData(show: false)`/`FlBorderData(show: false)`.
- **Lý do**: rung 5 của thang "lazy" — thư viện **đã nằm trong stack đã chốt** (`docs/tinh-nang…md §Stack`: biểu đồ dùng `fl_chart`) và đã resolve trong `.dart_tool/package_config.json`. Tự vẽ cột đôi + đường nét đứt phải thêm `CustomPaint` và tự tính scale.
- **Phương án khác**: tự dựng `Row`/`Container` chiều cao theo tỉ lệ + `CustomPaint` cho nét đứt (~60 dòng code tự chịu, không nhãn trục). Giữ làm phương án lùi nếu API 1.2.0 vỡ (Rủi ro 1).
- **Phạm vi dùng**: chỉ trong `budget_detail_screen.dart`; tab Báo cáo (biểu đồ thu/chi) vẫn thuộc PBI sau.

## R10 — "Xem tất cả": **đặt bộ lọc PBI 12 rồi đổi sang tab Giao dịch**, không tạo màn thứ hai

- **Quyết định**: dựng `TxnSearchFilter(now: now, type: TxnTypeFilter.expense, datePreset: DatePreset.custom, dateStart: range.start, dateEnd: ngày cuối của kỳ, categoryIds: phạm vi ngân sách, sort: SortOption.dateNewest)` → `ensureTransactionController().setFilter(f)` → `Navigator.popUntil(isFirst)` → `onSelectTab?.call(1)` (AppShell đổi tab + `load()`; `load()` dựng lại view lọc từ bộ lọc vừa đặt).
- **Lý do**: màn Giao dịch đã có sẵn toàn bộ hạ tầng lọc + thanh "N kết quả · Tổng" + nút Bỏ lọc (PBI 12) và đã gộp danh mục con (`_effectiveCategoryIds`) ⇒ SC-005 khớp số với thẻ tiến độ. `dateEnd` của bộ lọc là **ngày cuối kỳ** (bộ lọc tự hiểu là hết ngày) nên phải trừ 1 ngày từ `range.end` nửa mở.
- **Phương án khác**: đẩy `TransactionScreen` như một màn con có nút back — màn đó là màn cấp tab (không có back), và sẽ phải nhân bản logic controller.

## R11 — Danh sách "Giao dịch trong kỳ" và "đã dùng" **dùng chung một phép lọc**

- **Quyết định**: thêm `List<Transaction> budgetPeriodTransactions({categoryIds, transactions, range})` (lọc Chi + phạm vi danh mục + khoảng ngày, sắp **mới nhất trước**) vào `budget_view.dart`; `budgetSpent` **gọi lại** hàm này rồi cộng `-amount`. Màn `03` hiển thị `take(5)` của chính danh sách đó.
- **Lý do**: SC-005/FR-014 đòi tổng danh sách **khớp 100%** với số đã dùng — một phép lọc duy nhất thì không thể lệch. Sửa `budgetSpent` thành fold của hàm mới là refactor thuần, không đổi hành vi (test PBI 20 vẫn xanh).
- **Phương án khác**: viết bộ lọc riêng cho danh sách — hai predicate song song, chính là chỗ dễ lệch số mà spec lo.

## R12 — Dòng giao dịch trong kỳ: tiêu đề = **ghi chú** (rỗng thì tên danh mục), dòng phụ = **thời gian**

- **Quyết định**: `title = note.isEmpty ? (category.isEmpty ? typeLabel : category) : note`; `subtitle = '${relativeDayLabel(date, now: now)}, ${formatTimeLabel(date)}'` (VD "Hôm nay, 12:30" — đúng mockup `03`). Thêm `formatTimeLabel(DateTime)` → `HH:mm` vào `core/date_label.dart` (hàm `_two` đang private).
- **Lý do**: FR-012 đòi **tên giao dịch + thời gian**; trong ngữ cảnh ngân sách một danh mục, hiển thị lặp tên danh mục ở mọi dòng là vô ích, còn mockup vẽ tên người bán (trong app = `note`). Dùng `formatMoney`/`formatSignedMoney` sẵn có cho số tiền (âm, màu coral).
- **Phương án khác**: dùng lại `buildDisplayRows` (title = tên danh mục, subtitle = "Ví · ghi chú") — không có thời gian ⇒ trượt FR-012 và lệch mockup.
- **Không** làm: chạm dòng mở Chi tiết giao dịch (FR không đòi, mockup không có mũi tên) — bổ sung sau nếu người dùng cần.

## R13 — Không thêm dependency; i18n đầy đủ

- **Quyết định**: `pubspec.yaml` **không đổi** (chart dùng `fl_chart` đã có). Thêm ~25 khóa EN vào `sora_translations.dart`; chuỗi động dùng `trParams`.
- **Lý do**: đúng ràng buộc stack; SC-009 đòi 0 nhãn tiếng Việt sót khi ở English, và `sora_translations_test` tự quét literal `.tr` nên thiếu khóa là test đỏ.
- **Giới hạn đã biết**: test chỉ bắt "gắn `.tr` mà thiếu khóa", **không** bắt "quên gắn `.tr`" ⇒ QA tay nhóm English là bắt buộc.

## R14 — Nút đổi kỳ: **bottom sheet** liệt kê kỳ, mới nhất trên cùng

- **Quyết định**: chạm nút lịch ở góc phải app bar → `showModalBottomSheet` + `ListView` các kỳ (giảm dần), kỳ đang xem có dấu chọn + màu teal; chọn → `setState` đổi kỳ đang xem và tính lại toàn màn.
- **Lý do**: FR-023 chỉ đòi "chọn được kỳ"; bottom sheet là pattern sẵn có của app (bộ chọn ví/danh mục) và không cần thêm màn mới. Danh sách giảm dần để kỳ hiện tại (thường dùng nhất) nằm trên cùng.
- **Phương án khác**: `PopupMenuButton` — chật khi ngân sách chạy nhiều kỳ (Năm: 3–5 mục, Tuần: hàng chục mục).

## Tổng hợp `NEEDS CLARIFICATION`

Không còn mục nào. Các điểm spec để mở đều đã được người dùng chốt ngày 2026-09-12 (xem spec §"Quyết định đã chốt"); các quyết định trên là chi tiết triển khai, không đổi hành vi nghiệp vụ.
