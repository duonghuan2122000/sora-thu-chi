# Kế hoạch triển khai: So sánh kỳ (màn 03 Báo cáo)

**Mã PBI**: 26
**Liên kết spec**: [.specify/specs/26/spec.md](./spec.md)
**Ngày tạo**: 2026-09-13

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter (Android + iOS), app **offline hoàn toàn** |
| Framework / Thư viện chính | GetX `^4.7.3` (điều hướng + DI + i18n), Material; biểu đồ dùng **`fl_chart ^1.2.0`** đã có trong `pubspec.yaml` — `BarChart`/`PieChart` đã chạy thật ở PBI 21/22, đợt này **dùng thật lần đầu** `LineChart` (`LineChartBarData.dashArray` cho đường kỳ đối chiếu) ⇒ **không sửa `pubspec.yaml`**, **không** thêm dependency |
| Lưu trữ dữ liệu | drift `^2.34.4` + sqlite local — **schema giữ nguyên v8** (PBI 24): **không** thêm bảng/cột, **không** migration, **không** chạy `build_runner`; màn 03 **không** đọc DB (R1) |
| Kiểm thử | `flutter_test` — mốc trước PBI: **835 pass + 1 test đỏ có sẵn** (`transactions_dao_test`); bổ sung **1 file test mới**, sửa **3 file test** (module thuần, màn 01, controller); mục tiêu **không tăng số test đỏ** |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build) — không server, không CI đặc thù |
| Ràng buộc hiệu năng | Màn 03 dựng số liệu từ **bản chụp RAM** của `ReportController` (đã nạp khi mở tab Báo cáo) ⇒ **không** phát sinh phép đọc DB nào; chi phí mới duy nhất là 2 vòng lặp tính chuỗi chi-theo-ngày (`O(số giao dịch)` mỗi kỳ) ⇒ SC-010 (< 1 giây) không đổi so với PBI 22 |
| Ràng buộc khác | Ngôn ngữ giao diện/tài liệu/commit: **tiếng Việt có dấu**; bám Design System (teal `#0F6E56` = hành động/trạng thái chọn; coral `#D85A30` **chỉ** cho ngữ cảnh chi tiêu/cảnh báo); mọi màu đi qua token `AppColors`/`SoraColors` để chạy đúng dark mode (PBI 18); mọi nhãn tĩnh + **câu Nhận xét tự động** phải có bản dịch EN (PBI 19) |
| Nguồn chân lý nghiệp vụ | `docs/report/bao-cao-thong-ke-giai-phap.md` (§3.3 so sánh giữa các kỳ, §3.4 xu hướng, §4 luồng "chạm icon So sánh (app bar) → Màn So sánh kỳ", §5 danh sách màn hình, §6 `LineChart` + `dashArray`) + mockup `docs/report/man-hinh-03-so-sanh-ky.svg`; kế thừa `research.md` PBI 22 (mốc kỳ, `reportTotals`, `_breakdown`, `reportBarLabel`) và PBI 23 (màn con `SubPageScaffold`, `reportPeriodChipLabel`, nếp "màn 02 đọc bản chụp RAM") |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ" (3 quyết định chốt
2026-09-13, ghi ở mục "Quyết định đã chốt"); các quyết định còn lại là chi tiết
triển khai — xem [research.md](./research.md) (R1…R15).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** (repo chưa tạo hiến pháp) ⇒
đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ✅ | Không đọc mạng; số liệu lấy từ RAM đã nạp từ sqlite local |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Mọi nhãn, tài liệu, comment, commit của PBI này bằng tiếng Việt |
| Stack đã chốt (drift + GetX + fl_chart) | ✅ | Không thêm dependency, không sửa `pubspec.yaml`; đường so sánh dùng `LineChart` **đã có** (doc §6 chốt sẵn) |
| Design system: 1 màu thương hiệu teal, coral chỉ cho chi/cảnh báo, không hex cứng trong widget | ✅ | Chỉ **đọc** token `SoraColors`/`AppColors` đã có; **không** sửa `sora_colors.dart`; chip kỳ chính dùng fill thương hiệu `AppColors.teal` (đúng "trạng thái chọn") |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Màn chỉ **đọc**; không ghi bất kỳ bảng nào |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | Dùng lại **đúng** phép lọc `reportTotals` + `_breakdown` của màn 01 (đã loại transfer/adjustment) ⇒ ba màn Báo cáo không thể lệch số |
| Màn cấp tab có bottom nav, **màn con không** | ✅ | Màn 03 là route đè shell qua `SubPageScaffold` (app bar teal + back, không bottom nav, không FAB); **không** đụng `AppShell`/`AppBottomNavBar` |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ đọc `transactions` + `categories`; không đụng `wallets`/`budgets`/`app_settings` |
| Không phá vỡ hành vi PBI trước | ✅ | Màn 01 chỉ **thêm** `trailing` cho `ScreenHeader`; `ReportView`/`buildReportView`/`reportBreakdown`/`reportTopCategories`/`reportCategoryDetail` giữ nguyên chữ ký; `WalletRepository` không đổi |
| YAGNI / không abstraction sớm | ✅ | 4 hàm thuần + 2 method controller + 1 màn mới; **không** controller/thực thể/repository mới, **không** widget dùng chung mới, **không** cache/bảng tổng hợp, **không** token màu mới |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **Nguồn dữ liệu (R1)** — **Quyết định**: màn 03 **không** đọc DB, dựng số liệu
  từ bản chụp RAM của `ReportController` qua method mới `comparison(...)`.
  **Lý do**: màn chỉ mở được từ màn 01 đang có dữ liệu ⇒ không cần nhánh
  loading/error thứ hai, và ba màn Báo cáo **không thể lệch số**. **Phương án
  khác**: `StatefulWidget` đọc DB trong `initState` (khuôn PBI 21 — thêm ~40 dòng,
  dữ liệu đọc ở thời điểm khác ⇒ rủi ro lệch số).
- **Trạng thái cặp kỳ (R2)** — **Quyết định**: state **cục bộ** trong
  `ReportComparisonScreen` (`_left`, `_right`, `_mode`). **Lý do**: trạng thái chỉ
  sống trong phiên mở màn (spec "Giả định"), không ai chia sẻ ⇒ không cần DI/vòng
  đời GetX. **Phương án khác**: `ComparisonController extends GetxController`
  (phải đăng ký + quyết định xoá khi pop, lợi ích bằng 0).
- **Điểm vào (R3)** — **Quyết định**: dùng slot **đã có** `ScreenHeader.trailing`
  (màn Giao dịch đã dùng cho nút lọc) — icon `Icons.compare_arrows` trắng, nút
  tròn 48 px; vô hiệu hoá + `SnackBar` giải thích khi người dùng **chưa từng** có
  giao dịch Thu/Chi trước kỳ đang xem (FR-017). **Lý do**: FR-001 chốt "biểu tượng
  trên vùng tiêu đề"; không phải sửa `ScreenHeader`. **Phương án khác**: hàng điều
  hướng kiểu mục "Ngân sách" (spec đã loại).
- **"Cùng kỳ năm trước" (R4)** — **Quyết định**: dời **mốc kỳ** lùi 1 năm (kẹp
  29/02 → 28/02) rồi `reportPeriodRange`. **Lý do**: một luật chạy đúng cho cả 4
  loại kỳ, Tuần tự bắt Thứ Hai, Tháng/Năm giải bằng số học ngày (SC-009).
  **Phương án khác**: trừ `Duration(days: 365)` (sai năm nhuận, lệch thứ);
  4 nhánh riêng (lặp code).
- **Chênh lệch & màu badge (R5)** — **Quyết định**: một hàm thuần
  `compareDelta({main, ref, higherIsGood})`; `ref == 0` ⇒ không có % (không chia
  0); `0%` ⇒ không mũi tên/không tô màu; màu theo **ý nghĩa** (Thu tăng / Chi giảm
  = tốt). **Lý do**: quy tắc màu nằm **một chỗ**. **Phương án khác**: tính % ở
  widget (hai nơi, dễ lệch).
- **Chuỗi chi-theo-ngày (R6)** — **Quyết định**: `reportDailyExpense` trả
  `List<int>` dài đúng bằng số ngày của kỳ, **không** luỹ kế; đường kỳ ngắn hơn
  **tự dừng** vì hết điểm. **Phương án khác**: cắt theo `min(len)` (thêm phép biến
  đổi vô ích).
- **Biểu đồ (R7)** — **Quyết định**: `LineChart` — kỳ chính nét **liền** teal, kỳ
  đối chiếu nét **đứt** xám; chỉ trục hoành, 3 nhãn (`1`/giữa/cuối). **Lý do**:
  doc §6 chốt sẵn `LineChart` + `dashArray`; `fl_chart` đã có. **Phương án khác**:
  `CustomPaint` (tốn công canh trục/chú giải); thêm package (YAGNI).
- **Danh mục tăng mạnh nhất (R8)** — **Quyết định**: tái dùng `_breakdown` (đã gộp
  cha, đã gồm danh mục ẩn) cho cả hai kỳ rồi lấy max chênh lệch dương. **Lý do**:
  cùng nguồn nhóm với màn 01/02 ⇒ không lệch số/tên. **Phương án khác**: hàm gộp
  riêng cho màn 03 (lặp logic).
- **Câu Nhận xét (R9)** — **Quyết định**: ghép **mệnh đề chính + mệnh đề danh
  mục** ⇒ **7 khóa dịch** thay vì 16 câu rời; chữ `@ref` **suy từ so sánh ngày**
  ("kỳ trước"/"kỳ sau"), **không** lấy từ `mode` (sau hoán đổi chữ phải đổi theo).
  **Phương án khác**: 16 khóa (không dịch nổi); hard-code tiếng Việt (vi phạm
  FR-021/SC-013).
- **Nền thẻ & token màu (R10)** — **Quyết định**: dùng token đã có
  (`softCardBg`, `coralLightBg`, `dotEmpty` alpha .5, `tealOnNeutral`,
  `coralOnNeutral`, `tabInactive`) thay vì bám cặp trắng-viền `#EFEFEF` của mockup.
  **Lý do**: repo không có token cho cặp đó, SC-001 chỉ ràng buộc vị trí/nội
  dung/màu **ngữ nghĩa**; token ⇒ dark mode đúng mà không thêm token.
  **Phương án khác**: thêm 1–2 token mới cho một màn (lệch look với thẻ màn 01).
- **i18n (R11)** — **Quyết định**: tái dùng `'Thu nhập'`, `'Chi tiêu'`, 4 danh từ
  kỳ, `'Khác'`, `'Thử lại'`, `'Chưa có giao dịch nào trong kỳ này'`; thêm **14
  khóa** (chi tiết ở research R11).
- **Trạng thái rỗng (R12)** — **Quyết định**: hai mức — cả hai vế rỗng ⇒ rỗng toàn
  màn nhưng **vẫn** hiện cặp chip + nút hoán đổi (để còn đường đổi chế độ); từng
  thẻ vẫn có nhánh rỗng riêng. **Phương án khác**: ẩn luôn chip (màn thành ngõ
  cụt).
- **Chiều cao cột (R13)** — **Quyết định**: `Container` + tỉ lệ `64 * v / max`,
  không dùng `BarChart` cho 2 cột tĩnh (mockup cũng vẽ bằng `rect` thường).
- **Kiểm thử (R14)** — 1 file test màn mới + mở rộng 2–3 file test cũ; phần lớn
  luật kiểm ở **tầng thuần**.
- **Ràng buộc kế thừa (R15)** — không schema, không migration, không dependency,
  không `contracts/`, không đụng `AppShell`.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — **không đổi schema**;
  4 thực thể logic (`CompareMode`, `CompareSide`, `CompareDelta`,
  `ReportComparison`) + 4 hàm thuần + **28 luật bất biến** + bảng vòng đời "khi
  nào số liệu đổi".
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không
  API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19/20/21/22/23). Hợp đồng nội bộ duy
  nhất là `WalletRepository` — **không đổi chữ ký**.
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — **15 nhóm
  kiểm thử tay A–O**, phủ FR-001…FR-023 và SC-001…SC-016.

### Kiến trúc chi tiết

**1. Tầng nghiệp vụ thuần — `lib/core/report/report_view.dart` (sửa, +~200 dòng)**

| Thành phần | Vai trò |
|---|---|
| `enum CompareMode { previous, lastYear }` | Chế độ chọn kỳ đối chiếu (FR-003/FR-005) |
| `class CompareSide` | Một vế: `range`, `income`, `expense`, `dailyExpense`; getter `hasAnyTxn` |
| `class CompareDelta` | `percent (int?)`, `direction`, `isGood (bool?)` |
| `class ReportComparison` | `period`, `left`, `right`, `incomeDelta`, `expenseDelta`, `insight`; getter `isEmpty`, `hasExpense`, `dayCount` |
| `DateRange reportRefRange(period, main, mode)` | Kỳ đối chiếu: `previous` (tái dùng `_previousStart`) hoặc `lastYear` (dời mốc lùi 1 năm, kẹp 29/02) |
| `List<int> reportDailyExpense(transactions, range)` | Tổng **chi** từng ngày của kỳ — `O(số giao dịch)`, không luỹ kế |
| `CompareDelta compareDelta({main, ref, higherIsGood})` | % chênh lệch + chiều + tốt/xấu (luật 5–9) |
| `ReportComparison reportComparison({transactions, categories, period, leftAnchor, rightAnchor})` | Dựng toàn màn: 2 vế, 2 delta, câu Nhận xét |

Câu Nhận xét dựng bằng **hàm private** `_insightSentence(...)` trong cùng file —
gọi `_breakdown` cho 2 kỳ, chọn danh mục tăng mạnh nhất, ghép mệnh đề (R9).

Không sửa `ReportView` / `buildReportView` / `reportBreakdown` /
`reportTopCategories` / `reportCategoryDetail` / `reportPeriodRange` /
`reportTotals` / `reportBarSeries` / `reportBarLabel` / `reportPeriodChipLabel` /
`_breakdown` ⇒ màn 01/02 và test PBI 22/23 không đổi.

**2. Trạng thái màn — `lib/core/report/report_controller.dart` (sửa, +2 method)**

```dart
/// Số liệu màn So sánh kỳ (PBI 26) — dựng lại từ bản chụp RAM mỗi lần gọi;
/// màn 03 chỉ mở được từ màn Tổng quan đã có dữ liệu (research R1).
ReportComparison? comparison({
  required DateTime leftAnchor,
  required DateTime rightAnchor,
}) {
  if (!_loaded) return null;
  return reportComparison(
    transactions: _transactions,
    categories: _categories,
    period: period.value,
    leftAnchor: leftAnchor,
    rightAnchor: rightAnchor,
  );
}

/// Người dùng đã từng có giao dịch Thu/Chi **trước** [start] chưa — điều kiện
/// bật lối vào màn 03 (FR-017). Transfer/adjustment không tính.
bool hasAnyTxnBefore(DateTime start) { ... }
```

**3. Màn mới — `lib/screens/report_comparison_screen.dart` (file mới, ~430 dòng)**

```
ReportComparisonScreen (StatefulWidget)
  _left/_right/_mode  ← initState đọc ensureReportController().now
  SubPageScaffold(title: 'So sánh kỳ'.tr)
    └ Obx → controller.comparison(leftAnchor: _left, rightAnchor: _right)
        ├ null            → SizedBox.shrink()   (chỉ xảy ra ở test)
        ├ comparison.isEmpty → thông điệp rỗng  (vẫn giữ _PeriodChips)
        └ ListView
            ├ _PeriodChips   (chip chính · nút hoán đổi · chip đối chiếu)
            ├ _CompareStatCard('Thu nhập', incomeDelta, cột teal)
            ├ _CompareStatCard('Chi tiêu', expenseDelta, cột coral)
            ├ _TrendCard     (LineChart 2 đường + chú giải)
            └ _InsightCard   (nền coralLightBg + icon cảnh báo + câu)
```

| Widget con | Ghi chú |
|---|---|
| `_PeriodChips` | Cặp chip (trái = `AppColors.teal` + chữ trắng, phải = `softCardBg` + chữ `listLabel` + **chỉ báo bấm được**), giữa là nút hoán đổi tròn 28 px. Nhãn `reportPeriodChipLabel` (đã có), chữ co bằng `FittedBox` để không cắt (FR-023) |
| `_CompareStatCard` | Hàng tiêu đề + badge (hoặc ghi chú khi `percent == null`); hàng dưới: **2 cột** (`Container` cao `64 * v / max`) + **2 dòng số** (`reportBarLabel` làm nhãn cột, dòng kỳ chính đậm hơn) |
| `_TrendCard` | Chú giải `Wrap` nhãn 2 kỳ; `LineChart` — kỳ trái liền `tealOnNeutral`, kỳ phải đứt `tabInactive`; `interval: 1`, hàm nhãn chỉ vẽ ở `1`, giữa, `dayCount`; nhánh rỗng khi cả hai vế không có chi tiêu |
| `_InsightCard` | Nền `coralLightBg`, icon `Icons.error_outline` coral, tiêu đề "Nhận xét" + `comparison.insight` |

**4. Điểm vào — `lib/screens/report_screen.dart` (sửa, +~35 dòng)**

- `ScreenHeader(trailing: _CompareButton(...))` — nút tròn 48 px, icon
  `Icons.compare_arrows`; màu `AppColors.white` khi bật, `tealLightText` khi tắt.
- Bật/tắt theo `controller.hasAnyTxnBefore(view.range.start)`; chạm khi tắt →
  `SnackBar('Chưa có dữ liệu để so sánh'.tr)`.
- `_openComparison(context)` → `Navigator.push(MaterialPageRoute(...))` —
  **không** truyền `onSelectTab` (màn 03 không drill-down sang tab nào).

**5. i18n — `lib/core/locale/sora_translations.dart` (sửa, +14 khóa)**

Danh sách khóa ở research R11. Tất cả là **khóa mới**, thêm vào nhánh `_en`;
mặc định tiếng Việt không cần bản đồ (khóa = chính chuỗi tiếng Việt).

**6. Kiểm thử**

| File | Việc |
|---|---|
| `test/report_comparison_screen_test.dart` | **MỚI** — pump màn 03 với repo giả: bố cục, badge + màu, hoán đổi (2 lần về gốc), chip đối chiếu ⇄ năm trước, nhánh rỗng 2 mức, chú giải, trạng thái vô hiệu hoá ở màn 01 |
| `test/report_view_test.dart` | Thêm nhóm test cho `reportRefRange`, `reportDailyExpense`, `compareDelta`, `reportComparison`, câu Nhận xét (đủ 4 biến thể + mệnh đề danh mục + `@ref` sau hoán đổi) |
| `test/report_controller_test.dart` | `comparison(...)` (null khi chưa nạp; số liệu khớp hàm thuần) + `hasAnyTxnBefore` (transfer không tính; mốc biên `date == start`) |
| `test/report_screen_test.dart` | Icon so sánh có mặt; chạm mở màn 03; trạng thái tắt + `SnackBar` khi chưa từng có thu/chi |

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn | ✅ | Không thêm phụ thuộc mạng; `LineChart` vẽ từ RAM |
| Tiếng Việt có dấu | ✅ | Không có chuỗi tiếng Anh trần mới nào ngoài nhánh `_en` |
| Stack đã chốt, không dependency mới | ✅ | Thiết kế chỉ dùng `fl_chart` sẵn có; `pubspec.yaml` không đổi |
| Design system & token màu | ✅ | **Không** sửa `sora_colors.dart`/`app_colors.dart`; mọi màu lấy từ token (R10) |
| Transfer không tính là thu/chi | ✅ | Mọi đường tính đều đi qua `reportTotals`/`_breakdown` |
| Màn con không bottom nav | ✅ | `SubPageScaffold`; không đụng `AppShell` |
| Không phá vỡ PBI trước | ✅ | Chỉ **thêm**: 1 màn, 4 hàm thuần, 2 method controller, `trailing` ở màn 01, 14 khóa dịch; không đổi chữ ký nào đang dùng |
| YAGNI | ✅ | Không controller mới, không widget dùng chung mới, không cache, không token mới, không file cấu hình |
| Đa tiền tệ / kỳ tài chính lệch ngày / Ẩn số dư | ✅ | Đều **ngoài phạm vi** (spec); thiết kế không tạo đường nào cho chúng lọt vào |

## Cấu trúc dự án dự kiến

```text
.specify/specs/26/
├── spec.md          (đã có)
├── checklists/      (đã có)
├── research.md      (MỚI — R1…R15)
├── data-model.md    (MỚI — 4 thực thể + 28 luật)
├── quickstart.md    (MỚI — QA tay A–O)
├── plan.md          (MỚI — file này)
└── tasks.md         (bước sau: /sora-task 26)

app/sora_thu_chi/
├── lib/core/report/
│   ├── report_view.dart          (SỬA: +CompareMode, +CompareSide, +CompareDelta,
│   │                              +ReportComparison, +4 hàm thuần, +_insightSentence)
│   └── report_controller.dart     (SỬA: +comparison(), +hasAnyTxnBefore())
├── lib/screens/
│   ├── report_screen.dart         (SỬA: +trailing icon so sánh, +_openComparison)
│   └── report_comparison_screen.dart   (MỚI: màn 03)
├── lib/core/locale/
│   └── sora_translations.dart     (SỬA: +14 khóa en)
└── test/
    ├── report_comparison_screen_test.dart   (MỚI)
    ├── report_view_test.dart                (SỬA)
    ├── report_controller_test.dart          (SỬA)
    └── report_screen_test.dart              (SỬA)

KHÔNG đụng: lib/data/ (schema drift v8), pubspec.yaml, lib/theme/*,
            lib/screens/app_shell* | AppBottomNavBar, lib/core/widgets/*,
            docs/, wiki-knowledge/ (wiki cập nhật ở bước sau — skill sora-wiki)
```

## Rủi ro & ngoại lệ có lý do

| # | Rủi ro | Ứng phó |
|---|---|---|
| 1 | **Lần đầu dùng `LineChart`** trong repo (chưa có tiền lệ) — API `LineChartBarData`/`FlSpot`/`dashArray` của `fl_chart 1.x` có thể khác bản đã quen | Thi công thử một chart tối thiểu trước khi làm thẻ đầy đủ; chỉ dùng `LineChart`, `LineChartData`, `LineChartBarData`, `FlSpot`, `FlDotData`, `AxisTitles`/`SideTitles` (đã dùng ở `BarChart` màn 01 nên chắc chắn có); `flutter analyze` + test widget chặn lỗi API |
| 2 | **Kỳ "Năm" ⇒ 365 điểm × 2 đường** — chi phí dựng điểm và title | `reportDailyExpense` là 1 vòng lặp `O(số giao dịch)`; hàm nhãn trục hoành trả `SizedBox.shrink()` cho mọi mốc ngoài 3 mốc ⇒ chi phí không đáng kể; đo ở nhóm O của quickstart |
| 3 | **Hoán đổi làm câu Nhận xét sai chiều** nếu lấy chữ `@ref` theo `mode` | Đã chốt ở R9: chữ suy từ **so sánh ngày** `right.start` với `left.start` ⇒ luôn đúng chiều; có test riêng |
| 4 | **Ngộ nhận FR-011 theo cả kỳ** ⇒ thẻ Chi tiêu chia cho 0 khi kỳ đối chiếu chỉ có Thu | Đã chốt ở R5 + data-model luật 9: đánh giá **theo từng chỉ số**; quickstart D6 phủ |
| 5 | **Chip dài bị cắt** (nhãn Tuần `Tuần 07/09–13/09/2026`) khi cỡ chữ lớn | Chip dùng `Expanded` + `FittedBox(scaleDown)` + `maxLines: 1`; quickstart N1/N4 phủ |
| 6 | **Test đỏ có sẵn** `transactions_dao_test` (PBI 11) dễ bị nhầm là lỗi mới | Ghi rõ mốc baseline **835 pass / 1 fail** ở plan + quickstart §5; mục tiêu là **không tăng** số test đỏ |
| 7 | **Khác biệt cố ý với mockup** (chip kỳ chính là nhãn tĩnh, chip đối chiếu bấm được; thẻ nền `softCardBg` thay vì trắng-viền) | Đã ghi ở SC-001 + research R10; QA nhóm B xác nhận đúng danh sách khác biệt, không phát sinh khác biệt mới |
| 8 | **iOS chưa QA** ở các PBI trước | PBI này không đụng native/config ⇒ QA Android là đủ; nếu bỏ qua iOS phải ghi rõ trong `tasks.md` |
