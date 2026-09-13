# Nghiên cứu kỹ thuật: So sánh kỳ (màn 03 Báo cáo)

**Mã PBI**: 26
**Liên kết spec**: [spec.md](./spec.md)
**Ngày tạo**: 2026-09-13

Spec đã ở trạng thái **"Đã làm rõ"** (3 quyết định chốt 2026-09-13) ⇒ **không còn
`NEEDS CLARIFICATION`**. Các mục dưới đây là quyết định **triển khai** — chốt
trước khi thi công để `tasks.md` không phải mở lại.

---

## R1 — Nguồn dữ liệu: màn 03 **không** đọc DB

- **Quyết định**: màn So sánh kỳ dựng số liệu từ **bản chụp RAM** của
  `ReportController` (đã nạp khi chọn tab Báo cáo) qua method mới
  `comparison({leftAnchor, rightAnchor})`, bám đúng khuôn `categoryDetail()`
  của PBI 23.
- **Lý do**: màn 03 chỉ mở được từ màn Tổng quan **đang có dữ liệu** ⇒ không
  phát sinh nhánh loading/error thứ hai; màn 01 và màn 03 **không thể lệch số**
  (SC-003); SC-010 (< 1 giây) không đổi so với PBI 22 vì không thêm phép đọc DB.
- **Phương án khác**: `StatefulWidget` tự đọc DB trong `initState` (khuôn PBI 21)
  — thêm ~40 dòng, thêm nhánh loading/error, dữ liệu đọc ở thời điểm khác màn 01
  ⇒ rủi ro lệch số giữa hai màn.

## R2 — Trạng thái cặp kỳ: state cục bộ trong màn, **không** controller mới

- **Quyết định**: `ReportComparisonScreen` là `StatefulWidget` giữ **3 field**:
  `_left` (mốc kỳ chính), `_right` (mốc kỳ đối chiếu), `_mode`
  (`CompareMode.previous` | `CompareMode.lastYear`).
- **Lý do**: trạng thái chỉ sống trong **phiên mở màn** (spec "Giả định": không
  lưu lại cặp kỳ); không màn nào khác đọc; đóng màn là mất — đúng ngữ nghĩa.
  `StatefulWidget` không cần đăng ký/huỷ DI, không cần `Get.put`, test dựng màn
  là có state.
- **Phương án khác**: `ComparisonController extends GetxController` — phải đăng
  ký, phải quyết định vòng đời (xoá khi pop?), `ensureXController()` thứ ba; lợi
  ích bằng 0 vì không ai chia sẻ state này.

## R3 — Điểm vào: `ScreenHeader.trailing` + vô hiệu hoá theo FR-017

- **Quyết định**: dùng slot **đã có** `ScreenHeader.trailing` (màn Giao dịch đã
  dùng cho nút lọc) — nút tròn 48 px, icon `Icons.compare_arrows`, màu trắng,
  cùng hàng tiêu đề "Báo cáo". Khi người dùng **chưa từng có** giao dịch Thu/Chi
  nào **trước** kỳ đang xem ⇒ icon mờ (`tealLightText`) và chạm vào hiện
  `SnackBar` giải thích thay vì mở màn.
- **Lý do**: FR-001 chốt "biểu tượng trên vùng tiêu đề"; slot `trailing` đã tồn
  tại ⇒ **không** sửa `ScreenHeader`, không thêm widget dùng chung mới.
- **Phương án khác**: hàng điều hướng kiểu mục "Ngân sách" (spec đã loại);
  `MaterialBanner`/dialog cho phần giải thích (nặng hơn `SnackBar`).
- **Hệ quả**: cần seam đọc **một** thông tin ngoài `ReportView` —
  `ReportController.hasAnyTxnBefore(DateTime)` (hàm thuần, một vòng lặp).

## R4 — "Cùng kỳ năm trước": dời mốc lùi 1 năm rồi giải kỳ

- **Quyết định**: `reportRefRange(period, mainRange, mode)`:
  - `previous` → dùng lại `_previousStart(period, mainRange.start)` (đã có ở
    PBI 22) rồi `reportPeriodRange`.
  - `lastYear` → **dời mốc `mainRange.start` lùi 1 năm** (kẹp 29/02 → 28/02) rồi
    `reportPeriodRange(period, shifted)`.
- **Lý do**: **một** luật duy nhất chạy đúng cho cả 4 loại kỳ, không viết 4
  nhánh; Tuần tự bắt **Thứ Hai** vì `reportPeriodRange` đã lo; Tháng/Năm giải
  bằng số học ngày nên tháng 2/năm nhuận đúng (SC-009).
- **Phương án khác**: trừ `Duration(days: 365)` — sai với năm nhuận và lệch
  ngày trong tuần; viết riêng 4 nhánh cho `lastYear` — lặp code.

## R5 — Công thức chênh lệch & quy tắc màu badge

- **Quyết định**: với mỗi chỉ số (Thu, Chi):
  `percent = ((main − ref) / ref * 100).round()`; `ref == 0` ⇒ `percent = null`
  (**không** chia 0, không hiện badge — FR-011); `percent == 0` ⇒ **không** mũi
  tên, **không** tô màu (biên "chênh lệch bằng 0"); ngược lại mũi tên theo dấu
  (▲ tăng / ▼ giảm). Màu theo **ý nghĩa**, không theo chiều:
  `isGood = higherIsGood ? diff > 0 : diff < 0` với `higherIsGood = true` cho Thu
  và `false` cho Chi (FR-010/SC-005).
- **Lý do**: một hàm thuần `compareDelta({main, ref, higherIsGood})` dùng chung
  cho cả 2 thẻ ⇒ quy tắc màu chỉ nằm **một chỗ**; `ref == 0` là mẫu số duy nhất
  có thể bằng 0.
- **Phương án khác**: tính % ở widget (hai nơi, dễ lệch); coi `ref == 0` là
  `+100%` (vô nghĩa — SC-006 cấm).
- **Lưu ý cách đọc FR-011**: áp **theo từng chỉ số**, không theo cả kỳ. Kỳ đối
  chiếu có Thu nhưng không có Chi ⇒ thẻ Thu nhập **vẫn** có badge, thẻ Chi tiêu
  hiện ghi chú. Cách đọc ngược lại sẽ cho thẻ Chi tiêu badge "chia cho 0".

## R6 — Chuỗi xu hướng theo ngày

- **Quyết định**: `reportDailyExpense(transactions, range) -> List<int>`, một
  phần tử cho **mỗi ngày** của `range` (index 0 = ngày đầu kỳ), chỉ cộng giao
  dịch **Chi** (transfer/adjustment đã bị loại từ trước), **không** luỹ kế.
- **Lý do**: FR-012 chốt "mỗi điểm là tổng chi của ngày đó"; độ dài mảng chính là
  số ngày của kỳ nên trục hoành `1 … max(len_trái, len_phải)` suy ra trực tiếp;
  đường của kỳ ngắn hơn **tự dừng** vì hết điểm (không nội suy, không kéo dài).
- **Phương án khác**: dựng danh sách `(ngày, tiền)` rồi cắt theo `min(len)` —
  thêm một phép biến đổi vô ích.

## R7 — Vẽ biểu đồ đường: `fl_chart` `LineChart` (dùng thật lần đầu)

- **Quyết định**: `LineChart` với `LineChartBarData` cho mỗi kỳ — kỳ **trái
  (chính)** nét **liền** `colors.tealOnNeutral`, kỳ **phải (đối chiếu)** nét
  **đứt** (`dashArray: [4, 3]`) màu `colors.tabInactive`; `dotData` ẩn, không
  `isCurved`; chỉ bật **trục hoành** (3 nhãn: `1`, giữa kỳ, ngày cuối — bám
  mockup `1 / 15 / 30`; `interval: 1` + hàm nhãn tự ẩn mọi mốc khác), **không**
  trục tung, không lưới; đường đáy `colors.divider`.
- **Lý do**: doc §6 đã chốt sẵn `fl_chart → LineChart` + `dashArray` cho "đường
  kỳ trước khi so sánh"; `fl_chart ^1.2.0` **đã có trong `pubspec.yaml`** ⇒
  **không** thêm dependency (khác với `PieChart`/`BarChart` của PBI 21/22, đây
  là lần đầu app vẽ đường).
- **Phương án khác**: tự vẽ `CustomPaint` (sai tinh thần "dùng thư viện đã
  chốt", tốn công canh trục/chú giải); thêm package vẽ chart mới (YAGNI).

## R8 — Danh mục tăng mạnh nhất: tái dùng `_breakdown`

- **Quyết định**: gọi `_breakdown(...)` (**hàm private đã có** trong
  `report_view.dart`, đã gộp danh mục con vào cha, đã sắp giảm dần, đã lấy
  `categoriesIncludingHidden`) cho **cả hai** kỳ, rồi so từng danh mục cha:
  chênh lệch `tăng = chi_trái − chi_phải`; chọn **max dương**; không có danh mục
  nào tăng ⇒ câu Nhận xét không nêu danh mục (FR-013/FR-014).
- **Lý do**: cùng nguồn nhóm với màn 01/02 ⇒ số tiền và tên danh mục không thể
  lệch; danh mục **đã ẩn** tự được nêu tên vì `_breakdown` lấy từ
  `categoriesIncludingHidden` (FR-014, biên "danh mục gây tăng đã bị ẩn").
- **Phương án khác**: viết hàm gộp riêng cho màn 03 — lặp logic gộp cha + sắp
  hạng, dễ lệch với màn 01.
- **Đồng hạng**: giữ nguyên nếp `_breakdown` (chênh lệch bằng nhau → tên tăng dần
  theo `normalizeSearch`) ⇒ kết quả **tất định**, test không bị flaky.

## R9 — Câu Nhận xét: ghép 2 mệnh đề, không bùng nổ khóa dịch

- **Quyết định**: câu = **mệnh đề chính** + **mệnh đề danh mục** (tùy chọn).
  Mệnh đề chính có 4 biến thể, chọn theo thứ tự ưu tiên:
  1. cả hai kỳ đều không có chi tiêu → `'Hai kỳ đều chưa có chi tiêu.'`
  2. kỳ **phải** không có chi tiêu → `'Kỳ này bạn chi @amount, kỳ đối chiếu chưa có chi tiêu để so sánh.'`
  3. chênh lệch `0%` → `'Bạn chi tiêu bằng @ref.'`
  4. còn lại → `'Bạn chi nhiều hơn @ref @percent%.'` / `'Bạn chi ít hơn @ref @percent%.'`
  Mệnh đề danh mục (chỉ khi có danh mục tăng): `' Chủ yếu do danh mục @category tăng mạnh.'`
- **`@ref`** = `'kỳ trước'` nếu `right.range.start < left.range.start`, ngược lại
  `'kỳ sau'` — **suy từ ngày**, không lấy từ `mode`. Lý do: sau khi **hoán đổi**,
  kỳ bên phải có thể là kỳ **sau**; nếu lấy chữ theo `mode` thì câu sẽ nói sai
  chiều ("chi ít hơn kỳ trước" trong khi đang so với kỳ sau). Ở trạng thái mặc
  định (kỳ chính = kỳ đang xem, đối chiếu = kỳ liền trước) câu ra đúng như mockup
  `03` và KB-13.
- **Lý do**: 4 mệnh đề chính × có/không mệnh đề danh mục × 2 chế độ = **16 câu**
  nếu viết rời; ghép mệnh đề chỉ cần **7 khóa**. Tiếng Anh dịch được vì `@ref`,
  `@percent`, `@amount`, `@category` đều là **tham số có tên** (thứ tự từ trong
  câu EN khác VI vẫn đúng).
- **Phương án khác**: 16 khóa dịch đầy đủ (không dịch nổi, dễ sót); hard-code
  chữ tiếng Việt trong widget (vi phạm FR-021/SC-013).

## R10 — Nền thẻ & màu: token, không bám hex của mockup

- **Quyết định**: thẻ dùng `colors.softCardBg` + bo góc `10` (giống `_Card` màn
  01); thẻ Nhận xét dùng `colors.coralLightBg` (mockup `#FFF3EE`), icon cảnh báo
  `colors.coralOnNeutral` (mockup `#D85A30`); cột kỳ chính theo loại giao dịch
  (`tealOnNeutral` / `coralOnNeutral`), cột kỳ đối chiếu `colors.dotEmpty` với
  alpha `0.5` (mockup `#B4B2A9` opacity .5); chip kỳ chính nền `AppColors.teal`
  chữ trắng, chip đối chiếu nền `colors.softCardBg` chữ `colors.listLabel`.
- **Lý do**: mockup `03` vẽ thẻ **nền trắng + viền `#EFEFEF`**, nhưng repo
  **không có token** nào cho cặp trắng-viền đó, và SC-001 chỉ ràng buộc *vị trí,
  nội dung, màu ngữ nghĩa* — không ràng buộc nền thẻ. Dùng token ⇒ dark mode
  (FR-022/SC-014) chạy đúng mà không phải thêm token mới.
- **Phương án khác**: bám đúng trắng + viền của mockup — phải thêm 1–2 token mới
  vào `SoraColors` (`light`/`dark`/`lerp`/`copyWith`) cho một màn, và lệch look
  với thẻ màn 01 cùng module.

## R11 — i18n: khóa mới, tái dùng tối đa

- **Quyết định**: **tái dùng** các khóa **đã có**: `'Thu nhập'`, `'Chi tiêu'`,
  `'Tháng'`/`'Tuần'`/`'Ngày'`/`'Năm'` (dựng nhãn chip qua
  `reportPeriodChipLabel` đã có từ PBI 23), `'Khác'`, `'Thử lại'`, `'Chưa có giao
  dịch nào trong kỳ này'`. **Thêm mới** (nhánh `en` trong `sora_translations.dart`):
  1. `'So sánh kỳ'`
  2. `'So sánh'` (nhãn ngữ nghĩa cho icon vùng tiêu đề)
  3. `'Xu hướng chi tiêu theo ngày'`
  4. `'Nhận xét'`
  5. `'Kỳ đối chiếu không có dữ liệu để so sánh'`
  6. `'Chưa có giao dịch nào trong hai kỳ này'`
  7. `'Chưa có dữ liệu để so sánh'` (SnackBar khi icon bị vô hiệu hoá)
  8. `'Hai kỳ đều chưa có chi tiêu.'`
  9. `'Kỳ này bạn chi @amount, kỳ đối chiếu chưa có chi tiêu để so sánh.'`
  10. `'Bạn chi nhiều hơn @ref @percent%.'`
  11. `'Bạn chi ít hơn @ref @percent%.'`
  12. `'Bạn chi tiêu bằng @ref.'`
  13. `' Chủ yếu do danh mục @category tăng mạnh.'`
  14. `'kỳ trước'` / `'kỳ sau'`
- **Lý do**: khóa dịch = **chính chuỗi tiếng Việt** (R1 của PBI 19) ⇒ mặc định
  tiếng Việt không cần bản đồ; test cũ pump `MaterialApp` thường giữ nguyên kết
  quả.
- **Phương án khác**: gộp 10/11 thành một khóa có `@direction` — tiếng Anh phải
  đổi cả cấu trúc câu, tham số không đủ.

## R12 — Trạng thái rỗng: hai mức, không vẽ rỗng

- **Quyết định**: `ReportComparison.isEmpty` = **cả hai** vế không có Thu/Chi
  (transfer/adjustment không tính — FR-015) ⇒ màn hiện **trạng thái rỗng toàn
  màn** (không chip? — **vẫn hiện** cặp chip + nút hoán đổi để người dùng đổi
  chế độ đối chiếu, chỉ **không** vẽ 3 thẻ); riêng **từng thẻ** vẫn có nhánh rỗng:
  thẻ số liệu khi **kỳ đối chiếu** chỉ số đó `= 0` → thay badge bằng ghi chú
  (R5), vẫn vẽ cặp cột (cột kỳ đối chiếu cao 0 — KB-9); thẻ xu hướng khi **cả
  hai** vế không có chi tiêu → ghi chú thay vì hai đường phẳng 0.
- **Lý do**: FR-016 cấm "cột 0, biểu đồ rỗng hay thẻ Nhận xét rỗng gây hiểu lầm
  là lỗi"; giữ chip lại để người dùng còn lối thoát (đổi sang "cùng kỳ năm
  trước" có thể có dữ liệu) — đúng FR-017 "không chặn người dùng bằng màn trắng".
- **Phương án khác**: ẩn luôn cặp chip khi rỗng — người dùng hết đường đổi kỳ đối
  chiếu, màn thành ngõ cụt.

## R13 — Chiều cao cột so sánh

- **Quyết định**: `maxBarHeight = 64`; cột cao nhất (trong 2 vế) chiếm trọn 64;
  cột còn lại `64 * value / max` (số nguyên); `max == 0` không xảy ra (đã có nhánh
  rỗng R12). Không dùng `maxY` của chart — cột vẽ bằng `Container` thường, không
  phải `BarChart`.
- **Lý do**: mockup `03` vẽ cột bằng `rect` thường (36×46 và 36×58) chứ không
  phải chart; dựng bằng `Container` cho chiều cao **tỉ lệ thật** (FR-007) và
  không phải cấu hình `BarChart` 2 nhóm 1 cột.
- **Phương án khác**: `BarChart` 2 nhóm — thêm cấu hình trục/tooltip không cần
  thiết cho 2 cột tĩnh.

## R14 — Kiểm thử

- **Quyết định**: **1 file test mới** (`report_comparison_screen_test.dart`) +
  **mở rộng 2 file test cũ**: `report_view_test.dart` (hàm thuần mới) và
  `report_screen_test.dart` (điểm vào + trạng thái vô hiệu hoá).
- **Lý do**: bám nếp PBI 23 (1 file màn mới + mở rộng test cũ); phần lớn luật
  nghiệp vụ (%, màu badge, chọn danh mục, biến thể câu) kiểm được ở **tầng thuần**
  — nhanh, không cần pump widget.
- **Phương án khác**: test riêng cho từng widget con — chậm, dễ vỡ khi đổi layout.

## R15 — Ràng buộc kế thừa (không làm gì)

- **Quyết định**: **không** đổi schema drift (giữ **v8**, PBI 24) — không bảng,
  không cột, không migration, không `build_runner`; **không** thêm dependency,
  **không** sửa `pubspec.yaml`; **không** đổi chữ ký `WalletRepository`; **không**
  tạo `contracts/` (app thuần nội bộ, không API/CLI/endpoint lộ ra ngoài — đồng
  nhất PBI 19/20/21/22/23); **không** đụng `AppShell`/`AppBottomNavBar` (màn con
  đẩy qua `SubPageScaffold`); **không** sửa `buildReportView`/`ReportView`/
  `reportBreakdown`/`reportTopCategories`/`reportCategoryDetail` (màn 01/02 và
  test PBI 22/23 giữ nguyên).
- **Lý do**: PBI này chỉ **đọc** dữ liệu đã có và **thêm** một màn con.
