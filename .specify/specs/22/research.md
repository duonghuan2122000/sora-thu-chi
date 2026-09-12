# Nghiên cứu kỹ thuật: PBI 22 — Báo cáo tổng quan (tab Báo cáo)

**Mã PBI**: 22 · **Ngày**: 2026-09-12 · **Liên kết**: [spec.md](./spec.md) · [plan.md](./plan.md)

Đặc tả đã ở trạng thái "Đã làm rõ" (3 quyết định chốt 2026-09-12). Dưới đây là các
quyết định **triển khai** — không còn `NEEDS CLARIFICATION`.

---

## R1 — Cách nạp dữ liệu khi mở tab Báo cáo

**Quyết định**: thêm `ReportController` (GetX, khuôn `TransactionController`) tại
`lib/core/report/report_controller.dart` + seam `lib/data/report_deps.dart`
(`ensureReportController()`); `AppShell._onTabSelected` gọi `load()` khi
`index == 2`.

**Lý do**: `ReportScreen` nằm trong `IndexedStack` của shell ⇒ **được build từ lúc
boot** và **không bao giờ chạy lại `initState`** khi người dùng đổi tab. FR-016 +
kịch bản 12 đòi số liệu tính lại **tại thời điểm mở màn**; nạp trong `initState`
sẽ chỉ chạy một lần lúc boot ⇒ số liệu cũ sau khi thêm/sửa giao dịch. Đây đúng
bài toán `TransactionController` đã giải (R6/PBI 9): màn cấp tab, nạp khi chọn tab.

**Phương án khác đã xem xét**:
- *`StatefulWidget` + `GlobalKey` để shell gọi `reload()`*: ít file hơn (~5 dòng)
  nhưng phá vỡ nếp duy nhất đang có cho màn cấp tab, và shell phải biết kiểu state
  của màn con.
- *Nạp trong `initState`*: không đạt FR-016/kịch bản 12 (đã loại).
- *Nạp lại ở `_openAddTransaction` của shell*: chỉ phủ đường FAB, không phủ
  sửa/xóa giao dịch từ màn Giao dịch (đã loại).

Kỳ đang chọn (`ReportPeriod`) sống **trong controller** để sống sót qua đổi tab
(SC: kịch bản 17 — quay lại vẫn giữ kỳ đã chọn) và để `setPeriod` tính lại từ dữ
liệu đã nạp trong RAM, **không đọc DB** (SC-007: < 1 giây).

---

## R2 — Mô hình kỳ báo cáo

**Quyết định**: module **thuần** `lib/core/report/report_view.dart` chứa
`enum ReportPeriod { day, week, month, year }` và toàn bộ hàm tính. Kỳ xác định
theo **mốc dương lịch**, khoảng nửa mở `[start, end)`:
Ngày `[d, d+1)` · Tuần `[thứ Hai, +7 ngày)` · Tháng `[mùng 1, mùng 1 tháng sau)`
· Năm `[1/1, 1/1 năm sau)`. Biểu đồ = **6 đơn vị liên tiếp kết thúc ở kỳ đang chọn**
(kỳ đang chọn là phần tử cuối).

**Lý do**: FR-021 + giả định spec. Tuần bắt đầu **Thứ Hai** là quy ước sẵn có của
app (`resolveDatePreset` — `transaction_filter.dart`, `budgetPeriodRange` —
`budget_view.dart`) ⇒ kế thừa, không phát minh. Khoảng nửa mở làm phép so
`contains` không thể tính trùng/hụt ở biên (FR-021: giao dịch đúng ngày cuối kỳ
vẫn thuộc kỳ đó).

**Phương án khác đã xem xét**: dùng lại `DatePreset` của màn lọc (`today/thisWeek/
thisMonth`) — thiếu "Năm" và trả `null` cho `all` ⇒ không đủ; tự giải preset là
đường vòng.

---

## R3 — Chỗ ở của `DateRange`

**Quyết định**: tách `DateRange` khỏi `core/budget/budget_view.dart` sang file
mới **`lib/core/date_range.dart`**; `budget_view.dart` **re-export**
(`export '../date_range.dart' show DateRange;`) để mọi import cũ
(`budget_detail.dart`, `budget_detail_screen.dart`) **không phải sửa**;
`report_view.dart` import thẳng file mới.

**Lý do**: `DateRange` là kiểu giá trị trung tính (khoảng nửa mở) nay dùng ở **2
module**. Để `report` import `budget_view.dart` chỉ vì `DateRange` tạo phụ thuộc
sai hướng (báo cáo ∉ ngân sách) và kéo cả cây import của ngân sách. Re-export giữ
thay đổi ở mức 1 lớp mới + 2 dòng sửa, không chạm file test nào.

**Phương án khác đã xem xét**: import `'../budget/budget_view.dart' show DateRange`
(0 file sửa, nhưng phụ thuộc chéo module); tự định nghĩa `ReportRange` trùng lặp
(2 bản cùng nghĩa).

---

## R4 — Bộ màu vòng tròn phân bổ

**Quyết định**: bảng màu **định tính cố định theo thứ hạng** (FR-011), khai báo
là token **đổi theo theme** trong `SoraColors` dưới dạng `List<Color> chartPalette`
**6 phần tử**: 5 phần tử đầu cho hạng 1…5, phần tử cuối dành riêng cho nhóm
**"Khác"**.

| Hạng | Sáng | Tối |
|---|---|---|
| 1 | `#0F6E56` (teal thương hiệu) | `#3FA98A` |
| 2 | `#3D8C77` (teal đậm nhạt) | `#4FB694` |
| 3 | `#E3B341` (hổ phách) | `#E3B341` |
| 4 | `#6B7FD7` (xanh lam nhạt) | `#8B9DEE` |
| 5 | `#B4B2A9` (xám) | `#A8A8A3` |
| Khác | `#5F5E5A` (xám đậm) | `#C9C7BE` |

**Lý do**: 4 màu đầu lấy **đúng token mockup** (`docs/report/man-hinh-01-bao-cao-
tong-quan.svg`: `#0F6E56`, `#3D8C77`, `#E3B341`, `#6B7FD7`) + xám `#B4B2A9` của
mockup (trùng token `SoraColors.light.dotEmpty`) — khớp doc nghiệp vụ §5: *teal,
teal đậm nhạt, hổ phách, xanh lam nhạt, xám*; **không** dùng coral (coral chỉ dành
cho chi tiêu/cảnh báo). Vì vòng tròn có thể tới **6 lát** (5 danh mục + "Khác") mà
bảng tên chỉ có 5 màu, **"Khác" được cấp màu riêng cố định** (xám đậm) thay vì
tái dùng màu hạng 5. Gán **theo thứ hạng** (không theo danh mục) ⇒ mở lại màn không
đổi màu (FR-011). Bản tối là biến thể sáng hơn để đạt tương phản trên nền
`#121212` (FR-019/SC-011).

**Phương án khác đã xem xét**:
- *Dùng `category.color` của từng danh mục*: trái FR-011 (màu phải cố định theo
  thứ hạng) và màu danh mục do người dùng chọn ⇒ hai lát có thể trùng màu.
- *Để bảng màu ở `AppColors` (bất biến như bảng màu ví/danh mục)*: không đạt
  SC-011 — teal `#0F6E56` trên nền tối chỉ ~2.5:1.

---

## R5 — Tổng % trên vòng tròn phải bằng đúng 100%

**Quyết định**: hàm thuần `percentSplit(List<int> amounts, int total)` chia % theo
**phần dư lớn nhất** (largest remainder / Hamilton); hàm trả `List<int>` cộng đúng
bằng 100 khi `total > 0`.

**Lý do**: FR-009/SC-005 đòi tổng % hiển thị **bằng 100%** và từng dòng khớp tỉ lệ
thật. Làm tròn độc lập từng lát (5–6 lát) có thể ra 99% hoặc 101%.

**Phương án khác đã xem xét**: lát cuối/"Khác" hấp thụ toàn bộ phần dư (2 dòng,
nhưng đẩy sai số tới ±3% vào một dòng bất kỳ); làm tròn mỗi lát rồi bỏ qua lệch
(trượt SC-005).

---

## R6 — Gộp danh mục con & nhóm "Khác"

**Quyết định**: gom theo **danh mục cha** (FR-010): khóa nhóm = `parentId ?? id`;
tên/icon/màu lấy từ danh mục **cha**. Nhóm **"Khác"** = phần tiền chi **ngoài top
5** cộng phần tiền chi **không gắn danh mục** (`categoryId == null`); chỉ xuất hiện
khi có phần dư đó. Danh sách chú giải + lát cắt sắp **giảm dần theo số tiền**,
đồng hạng → **tên tăng dần** (biên: thứ tự ổn định, SC).

**Lý do**: FR-009/FR-010 + các biên spec ("Kỳ chỉ có 1–5 danh mục chi → không có
nhóm Khác"; "Có tiền chi nhưng không gắn danh mục → gộp vào Khác"). Danh mục **ẩn**
vẫn được tính và hiện tên bình thường (nguyên tắc xuyên module) ⇒ nạp bằng
`categoriesIncludingHidden(expense)`, không dùng `categories(type:)`.

**Phương án khác đã xem xét**: tách theo danh mục con (có toggle trong doc §3.2 —
ngoài phạm vi đợt này); loại giao dịch `categoryId == null` khỏi mọi con số (khi đó
tổng lát cắt ≠ tổng chi, trượt FR-009/SC-005).

**Nhánh hiếm**: con trỏ tới cha không còn trong bảng ⇒ nhóm theo **chính con đó**
(còn tên/icon để hiển thị), không rơi vào "Khác".

---

## R7 — Chạm danh mục → màn Giao dịch đã lọc sẵn

**Quyết định**: chạm lát cắt/dòng chú giải → dựng
`TxnSearchFilter(now, type: expense, datePreset: custom, dateStart: range.start,
dateEnd: range.end − 1 ngày, categoryIds: {id danh mục cha}, sort: dateNewest)` →
`ensureTransactionController().setFilter(f)` → `onSelectTab?.call(1)` (màn Báo cáo
**là** tab của shell nên **không** có `popUntil`).

**Lý do**: màn Giao dịch đã có sẵn hạ tầng lọc + **tự mở rộng cha → con cháu**
(`_effectiveCategoryIds`, PBI 12) ⇒ chỉ cần đưa id **cha** là tập kết quả khớp đúng
phần tiền đã gộp ở vòng tròn (SC-006). `dateEnd` của bộ lọc hiểu là **hết ngày**
(`_matches` cộng 1 ngày) ⇒ lùi 1 ngày từ mốc cuối nửa mở (đúng mẹo PBI 21 R10).

**Phương án khác đã xem xét**: tự đẩy `TransactionScreen` thứ hai (nhân bản
controller); tính sẵn tập id cha+con rồi truyền (`categoryIds` đã tự mở rộng ⇒
thừa, và dễ lệch nếu cây sâu hơn 2 cấp).

**Nhóm "Khác"**: **không** có đích điều hướng (không phải một danh mục — gồm nhiều
danh mục + tiền không gắn danh mục nên không bộ lọc danh mục nào tái lập đúng
100%). Chạm vào lát "Khác"/dòng "Khác" **không** làm gì; đặc tả không nói tới
trường hợp này — chọn "không hành động" thay vì mở danh sách sai số (SC-006).

---

## R8 — Biểu đồ: cột ghép đôi + vòng tròn

**Quyết định**: dùng `fl_chart ^1.2.0` (**đã có trong `pubspec.yaml`**, đã dùng
thật ở PBI 21):
- Cột: `BarChart` + `BarChartGroupData` 2 `BarChartRodData` (thu `tealOnNeutral`,
  chi `coralOnNeutral`), `barTouchData: BarTouchData(enabled: true, …tooltip…)` để
  **chạm một cột hiện số tiền chính xác** (FR-007) và tự ẩn khi chạm ra ngoài.
- Vòng tròn: `PieChart` + `PieChartSectionData` (không nhãn trên lát),
  `centerSpaceRadius` tạo lỗ; nhãn **"Tổng chi" + số tiền** giữa vòng tròn vẽ bằng
  `Stack` (fl_chart không tự vẽ chữ giữa); `PieTouchData` cho chạm lát cắt.

**Lý do**: rung "dependency đã cài" — `fl_chart` là stack đã chốt trong
`docs/tinh-nang…md §Stack`, PBI 21 đã dùng `BarChart` thành công ⇒ **không thêm
dependency mới**, không tự dựng `CustomPaint` + tự tính scale/nhãn trục.

**Phương án khác đã xem xét**: tự vẽ cột/vòng bằng `CustomPaint` (~80 dòng, không
nhãn trục) — chỉ dùng nếu API vỡ (xem Rủi ro 1).

---

## R9 — Không đụng tầng dữ liệu

**Quyết định**: **không** thêm bảng/cột/migration (schema giữ **v7**), **không**
thêm method `WalletRepository`, **không** thêm dependency. Màn chỉ **đọc**
`allTransactions()` + `categoriesIncludingHidden(CategoryType.expense)`.

**Lý do**: mọi số liệu là **đại lượng tính toán** (giả định spec: kế thừa PBI 20/21
— không bảng tổng hợp, không cache; doc §2.2 đề xuất `report_monthly_summary` là
tối ưu kỹ thuật, **ngoài phạm vi**). Danh mục cha-con nằm cùng bảng `categories` ⇒
một lần đọc là đủ để gộp. SC-007 đặt ngưỡng < 1 giây; vài nghìn dòng trên máy đọc
tức thời.

**Phương án khác đã xem xét**: bảng tổng hợp `report_monthly_summary` + upsert khi
ghi giao dịch (doc §2.2/§7) — đúng bài toán nhưng là **tối ưu sớm**: chưa đo được
chậm, và đụng migration + mọi đường ghi giao dịch.

---

## R10 — Trạng thái rỗng

**Quyết định**: xét theo **kỳ đang chọn**, không theo cửa sổ 6 đơn vị:
- Kỳ **không có Thu/Chi nào** → 2 số tổng `0 đ` + **cả 3 thẻ** hiện trạng thái rỗng
  (`Chưa có giao dịch nào trong kỳ này`) — FR-014/SC-009.
- Kỳ **chỉ có Thu** → biểu đồ vẫn vẽ (cột chi = 0); riêng thẻ phân bổ + thẻ top
  hiện trạng thái rỗng riêng (`Chưa có chi tiêu nào trong kỳ này`) — FR-015.
- Kỳ **chỉ có chuyển khoản nội bộ** → như "không có Thu/Chi" (biên spec).

**Lý do**: FR-014 nói rõ "kỳ đang chọn không có giao dịch Thu/Chi nào"; FR-006 vẫn
đòi đủ 6 cột kể cả đơn vị 0 ⇒ hai luật không mâu thuẫn nếu trạng thái rỗng xét theo
**kỳ đang xem**. Thông điệp phân biệt "không có giao dịch" vs "không có chi tiêu"
để hai thẻ chỉ-nói-về-chi không gây hiểu nhầm.

**Phương án khác đã xem xét**: xét rỗng theo cả cửa sổ 6 đơn vị (che mất biểu đồ
thật khi kỳ này trống nhưng các kỳ trước có dữ liệu — trái FR-006 và vô nghĩa về
nghiệp vụ).

---

## R11 — Làm mới sau khi ghi giao dịch

**Quyết định**: `AppShell._openAddTransaction` giữ nguyên `TransactionController.
load()`, **thêm** nạp lại controller báo cáo **khi tab đang chọn là tab Báo cáo**
(`_selectedIndex == 2`).

**Lý do**: FAB thuộc shell, hiện trên **mọi** tab. Đứng ở tab Báo cáo ghi một giao
dịch rồi quay lại ⇒ nếu không nạp lại, số liệu vẫn là bản cũ cho tới lần đổi tab
sau. Một dòng, đúng tinh thần FR-016.

**Phương án khác đã xem xét**: chỉ dựa vào nạp-khi-chọn-tab (phủ kịch bản 12 nhưng
hở đúng đường FAB-ngay-trên-tab); dựng cơ chế lắng nghe dữ liệu (ngoài phạm vi —
giả định spec nói màn không tự cập nhật liên tục).

---

## R12 — Widget dùng chung: có gì thì dùng nấy

**Quyết định**: tái dùng `ScreenHeader` (tham số `bottom` **đã có sẵn** — dùng cho
vùng teal chứa segmented control + 2 số tổng), `AddTransactionFab` +
`AppBottomNavBar` (chỉ dùng khi cần), `categoryIcon`, `formatMoney`/`formatAmount`,
`relativeDayLabel`. **Không** tái dùng được: segmented control 4 lựa chọn (repo
chưa có widget này) và thanh tiến độ của thẻ top (bản của màn ngân sách là widget
**riêng tư**, gắn ngữ nghĩa 3 dải ngưỡng) ⇒ dựng cục bộ trong `report_screen.dart`
(~15 dòng mỗi cái, thanh tiến độ ở đây **một màu** vì tỉ lệ trên tổng chi luôn < 100%).

**Lý do**: `ScreenHeader.bottom` sinh ra đúng cho việc này (PBI 20 dùng cho bộ chọn
tháng) ⇒ không sửa khung. Tách `_RowProgressBar` của ngân sách ra `core/widgets/`
sẽ chạm 2 màn + 2 bộ test để tiết kiệm 12 dòng — không đáng (Ponytail: rẻ hơn thì
chép 12 dòng).

**Phương án khác đã xem xét**: đưa thanh tiến độ vào `core/widgets/` ngay từ đầu
"cho tương lai" (thêm abstraction cho 2 ca dùng khác ngữ nghĩa).
