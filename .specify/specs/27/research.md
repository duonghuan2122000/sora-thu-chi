# Nghiên cứu kỹ thuật: Xuất báo cáo (màn 04 Báo cáo)

**Mã PBI**: 27
**Liên kết spec**: [spec.md](./spec.md)
**Ngày tạo**: 2026-09-13

Spec đã ở trạng thái **"Đã làm rõ"** (4 quyết định chốt 2026-09-13, ghi ở mục
"Quyết định đã chốt" của spec) ⇒ **không còn `NEEDS CLARIFICATION`**. Các mục
dưới đây là quyết định **triển khai** — chốt trước khi thi công để `tasks.md`
không phải mở lại.

---

## R1 — Điểm vào: icon **thứ hai** trên vùng tiêu đề màn 01

- **Quyết định**: `ScreenHeader.trailing` của màn Tổng quan đổi từ 1 widget thành
  `Row(mainAxisSize: min, children: [_CompareButton, _ExportButton])`; nút xuất là
  nút tròn 48 px, icon `Icons.ios_share`, chữ trắng, đặt **cạnh** nút so sánh.
  Nút **luôn bấm được** (kể cả khi kỳ rỗng — FR-001 + chốt 2026-09-13), không có
  trạng thái mờ/SnackBar như nút so sánh.
- **Lý do**: FR-001 chốt "biểu tượng trên vùng tiêu đề (cùng hàng tiêu đề 'Báo
  cáo', cạnh lối vào So sánh kỳ)"; mockup `01` không vẽ icon này nên vị trí lấy
  theo cách đã chốt ở PBI 26. `ScreenHeader.trailing` là slot **đã có** ⇒ không
  sửa `ScreenHeader`, không thêm widget dùng chung mới.
- **Phương án khác**: hàng điều hướng kiểu mục "Ngân sách" (spec đã loại ở PBI
  26); nhét chung vào nút so sánh dạng menu (thêm 1 lần chạm — FR-001 cấm).

## R2 — Nguồn dữ liệu: màn 04 **tự đọc một lần** khi mở, không dùng RAM `ReportController`

- **Quyết định**: `ReportExportScreen` là `StatefulWidget`; `initState` gọi **một
  lần** `ensureWalletRepository()` để lấy đúng 4 thứ, rồi giữ **bản chụp** trong
  state: `allTransactions()`, `loadAll()` (ví), `categories(type: income)`,
  `categories(type: expense)` (danh mục **đang hoạt động** — chip lọc không hiện
  danh mục ẩn, biên "danh mục đã bị ẩn" của spec). Đổi bộ lọc **không** đọc lại
  (FR-026). Có nhánh loading/error + nút "Thử lại" (khuôn PBI 21 — màn 01/02/03
  không có nhánh này).
- **Lý do**: `ReportController` (PBI 22) chỉ giữ giao dịch + **danh mục chi kể cả
  ẩn**: thiếu **danh mục thu** (bộ lọc danh mục phải lọc được cả giao dịch thu) và
  thiếu **danh sách ví** (chip VÍ + cột ví trong tệp). FR-026 lại yêu cầu số liệu
  tính **tại thời điểm màn đang mở** từ dữ liệu hiện có ⇒ một lần đọc ở `initState`
  đúng ngữ nghĩa đó.
- **Phương án khác**: (a) mở rộng `ReportController.load` đọc thêm danh mục thu +
  ví — đụng controller đã QA của PBI 22/23/26 và vẫn thiếu danh mục **ẩn lọc khác
  hoạt động**; (b) tái dùng `ensureWalletController().wallets` cho ví — phụ thuộc
  việc tab Tổng quan đã nạp hay chưa, state phân tán hai nơi.
- **Hệ quả**: 4 lời gọi repository (sqlite local, ms) cho mỗi lần mở màn; đổi lại
  màn 04 **độc lập** với 3 màn Báo cáo kia (FR-027: bộ lọc chỉ thuộc màn này).

## R3 — Lọc: module thuần **mới**, nhưng **tái dùng** hai luật đã có

- **Quyết định**: viết `filterForExport(...)` trong module thuần mới
  `lib/core/report/report_export.dart`; **tái dùng**:
  `normalizeSearch` (bỏ dấu — PBI 12) và nâng `_effectiveCategoryIds` của
  `transaction_filter.dart` thành **public** `effectiveCategoryIds` để dùng chung
  luật "chọn cha ⇒ gồm con" (FR-006: "cùng cách gộp với bộ lọc ở màn Giao dịch").
- **Không** tái dùng `filterTransactions` (PBI 12) — 3 lý do cụ thể:
  1. `TxnSearchFilter.walletId` là **một** ví (spec cần multi-select — FR-005);
  2. `keyword` khớp cả `note` + `category` + `tags`, còn FR-007 yêu cầu **chỉ tag**;
  3. **group-keep transfer**: khi một vế chuyển khoản khớp, PBI 12 giữ **cả hai
     vế** — với xuất báo cáo điều đó **kéo giao dịch của ví không được chọn** vào
     tệp ⇒ vi phạm thẳng SC-010.
- **Hệ quả**: 1 hàm thuần ~40 dòng + 1 lần đổi tên private→public ở file PBI 12
  (không đổi hành vi; chỉ 1 call site nội bộ).

## R4 — Khoảng ngày: nửa mở `[start, end + 1 ngày)`, luôn hợp lệ

- **Quyết định**: bộ lọc giữ `start` (00:00 ngày đầu) và `end` (00:00 ngày **sau**
  ngày cuối) — đúng quy ước `DateRange` + `reportPeriodRange`; "Đến ngày" hiển
  thị = `end − 1 ngày`. Bộ chọn ngày chặn ngay từ đầu: chọn **Đến ngày** truyền
  `firstDate = từ ngày`, chọn **Từ ngày** truyền `lastDate = đến ngày`
  (`showDatePicker` đã hỗ trợ) ⇒ không có nhánh validate/lỗi (FR-004 + chốt).
- **Lý do**: cùng quy ước với màn Giao dịch/Báo cáo ⇒ không lệch một ngày ở biên;
  "không cho chọn" rẻ hơn "cho chọn rồi báo lỗi".
- **Phương án khác**: cho chọn tự do rồi hiện thông báo lỗi (spec đã loại).

## R5 — Khớp tag: bỏ `#`, bỏ dấu, không phân biệt hoa/thường

- **Quyết định**: chuỗi nhập được `trim`, bỏ `#` ở đầu, `normalizeSearch` rồi kiểm
  **chứa** trong `normalizeSearch(t.tags)`. Giao dịch không có tag ⇒ chuỗi rỗng ⇒
  chỉ khớp khi ô tag trống (tức không lọc).
- **Lý do**: `Transaction.tags` là chuỗi thô phân tách `,` **không có** `#`
  (data-model PBI 10) ⇒ phải bỏ `#` người dùng gõ; `normalizeSearch` đã là hàm bỏ
  dấu dùng chung của repo (không thêm bảng ánh xạ thứ hai).
- **Phương án khác**: tách tag bằng `parseTags` rồi so **bằng** — chặt hơn spec
  ("gõ `dulich` khớp `#dulich`") nhưng gõ thiếu/thừa ký tự ra 0 giao dịch khó hiểu;
  khớp chứa là hành vi người dùng mong đợi khi gõ dở.

## R6 — Số liệu tổng hợp: tái dùng **nguyên** `reportTotals` + `reportBreakdown`

- **Quyết định**: tổng thu/tổng chi/chênh lệch lấy từ `reportTotals(transactions,
  range)` (đã loại transfer + adjustment); "phân bổ chi theo danh mục" lấy từ
  `reportBreakdown({transactions, categories, range})` — **top 5 danh mục cha +
  "Khác"** với % cộng = 100, đúng bằng thứ màn Tổng quan đang vẽ.
- **Lý do**: SC-004 đòi **sai lệch 0đ** so với màn 01 với cùng khoảng thời gian —
  chỉ có thể bảo đảm nếu dùng **đúng** hai hàm đó (cùng `_breakdown`, cùng định
  nghĩa "Khác" = ngoài top 5 + không gắn danh mục). Bản phân bổ **đầy đủ** mọi danh
  mục sẽ cho "Khác" khác màn 01 ⇒ QA đối chiếu sẽ thấy lệch.
- **Phương án khác**: xuất **toàn bộ** danh mục (như màn 02) — file "đẹp" hơn
  nhưng số "Khác" lệch màn 01 ⇒ rủi ro SC-004 không có lợi ích bù.

## R7 — Danh sách giao dịch trong tệp: **đủ mọi loại**, sắp tăng dần theo ngày

- **Quyết định**: `filterForExport` giữ **mọi** giao dịch khớp bộ lọc — kể cả
  `transfer` và `adjustment` (FR-015/SC-003), **không** group-keep; sắp **tăng dần
  theo `date`**, đồng ngày thì `id` tăng dần.
- **Lý do**: tệp là **bản đối chiếu sổ** — thứ tự thời gian là cách đọc sổ chuẩn,
  và tất định nên test/QA đối chiếu được từng dòng. SC-003 so **số dòng**, không
  ràng buộc thứ tự.
- **Phương án khác**: mới nhất trước (theo thói quen màn Giao dịch) — cũng hợp lệ
  nhưng khi in/đối chiếu kế toán khó theo dõi; chọn một luật, ghi rõ ở data-model.

## R8 — Thư viện xuất: `pdf` + `excel_community` + `share_plus`; **không** `csv`, **không** `printing`

- **Quyết định** (đã kiểm bằng `flutter pub add --dry-run` trên SDK hiện tại):
  - `pdf ^3.13.0` — sinh bytes PDF, thuần Dart (chạy được cả trong isolate).
  - `excel_community ^2.4.0` — bản **fork của `excel`** dùng `archive >=4.0.9`.
  - `share_plus ^13.3.0` — mở bảng chia sẻ hệ thống.
  - **CSV tự viết** (~30 dòng: escape `"`/`,`/xuống dòng + BOM UTF-8 để bảng tính
    không lỗi font tiếng Việt — FR-024) thay vì thêm package `csv`.
  - **Không** `printing`: cả 3 định dạng đi **cùng một** đường chia sẻ (`share_plus`)
    nên `printing` (nặng, có native view) là thừa.
- **Lý do chọn `excel_community` chứ không `excel`**: `excel 4.0.6` buộc
  `archive ^3.6.1`, còn `image ^4.9.2` (PBI 25) buộc `archive ^4.0.9` ⇒ **xung đột
  phiên bản, resolver từ chối** (đã tái hiện: *"because sora_thu_chi depends on
  both image ^4.9.2 and excel any, version solving failed"*). `excel_community`
  giữ API của `excel` (cùng gốc) nhưng mở `archive >=4.0.9 <=5.0.0` ⇒ giải được.
- **Phương án khác đã xem xét**:
  - `syncfusion_flutter_xlsio` (34.2.7 — chỉ phụ thuộc `flutter`, không xung đột):
    **loại** vì giấy phép thương mại/đăng ký license key + gói rất nặng cho một
    tính năng.
  - **Tự viết XLSX** bằng `archive` (zip + XML SpreadsheetML): khả thi nhưng tự
    chịu trách nhiệm toàn bộ `[Content_Types].xml`/`_rels`/worksheet ⇒ rủi ro
    SC-005 ("mở được bằng bảng tính") cao hơn hẳn một package đã có người dùng.
  - `xlsxwriter`: dùng FFI + `native_toolchain_c` ⇒ thêm chuỗi build native. Loại.
- **Rủi ro còn lại**: `excel_community` là bản fork ít phổ biến hơn `excel` ⇒ thi
  công kiểm ngay bằng test mở lại zip (đọc `xl/workbook.xml` + 2 sheet) và QA tay
  mở tệp bằng bảng tính trên emulator (quickstart nhóm I).

## R9 — Font cho PDF: **gói kèm** Roboto (không tải lúc chạy)

- **Quyết định**: thêm `assets/fonts/Roboto-Regular.ttf` + `Roboto-Bold.ttf`
  (Apache-2.0, mỗi file ~515 KB, tải **một lần lúc thi công** từ
  `googlefonts/roboto-2/src/hinted/`) vào repo + khai báo `assets/fonts/` trong
  `pubspec.yaml`; trong mã nạp bằng `rootBundle.load(...)` + `pw.Font.ttf` rồi đặt
  làm font mặc định qua `pw.ThemeData.withFont(base:, bold:)`.
- **Lý do**: font mặc định của `pdf` (Helvetica, WinAnsi) **không có dấu tiếng
  Việt** ⇒ chữ "Ăn uống", "Chuyển khoản" sẽ vỡ (FR-024/SC-005). Roboto là font
  nền tảng của app (mockup dùng Roboto) nên tệp nhìn đồng bộ với app. Asset khai
  báo trong `pubspec.yaml` **có mặt trong `flutter test`** (tiền lệ:
  `brand_assets_test.dart` của PBI 25) ⇒ test được.
- **Phương án khác**: `PdfGoogleFonts` (của `printing`) — tải font **lúc chạy** từ
  mạng ⇒ phá "app offline hoàn toàn"; subset font (cần công cụ ngoài); dùng font
  hệ thống (đường dẫn `/system/fonts` chỉ có trên Android).
- **Tăng dung lượng app**: ~1 MB (2 file). Chấp nhận — đây là điều kiện bắt buộc
  để PDF có tiếng Việt.

## R10 — Biểu đồ trong PDF: vẽ bằng **widget của `pdf`**, không chụp màn hình

- **Quyết định**: hai biểu đồ trong PDF được **vẽ bằng primitive của `pdf`**
  (`pw.Container`/`pw.Row`/`pw.Align` + cột/thanh tỉ lệ, số liệu in kèm):
  1. **Dòng tiền**: cặp cột Thu (teal) / Chi (coral) cho **tối đa 6 khoảng con
     bằng nhau** của khoảng đã lọc (`n = min(6, số ngày)`, biên chia theo số học
     ngày, không mất ngày nào).
  2. **Phân bổ chi theo danh mục**: **thanh ngang tỉ lệ** cho từng dòng của
     `reportBreakdown` (top 5 + "Khác") kèm số tiền + %.
- **Lý do**: (a) hai widget biểu đồ của màn 01 (`_FlowChartCard`, `_BreakdownCard`)
  là **private** trong `report_screen.dart` — muốn chụp phải dựng lại bản sao
  ⇒ lặp code ~80 dòng; (b) `RepaintBoundary.toImage()` cần UI thread + chờ frame +
  dựng widget offscreen (mẹo `Stack`/`Positioned` âm), khó test và dễ flaky;
  (c) vẽ bằng widget của `pdf` là **thuần Dart** ⇒ test được và chạy được trong
  `compute()` cùng chỗ với phần còn lại của tệp.
- **Lệch có lý do so với FR-012** ("ảnh các biểu đồ đang có ở màn Tổng quan"):
  đợt này PDF chứa **biểu đồ vẽ lại từ đúng dữ liệu đó**, không phải ảnh chụp —
  dạng biểu đồ phân bổ là **thanh ngang** thay vì donut (donut vẽ bằng widget của
  `pdf` không khả thi). Con số/định nghĩa nhóm y hệt màn 01 (R6). Ghi ở plan mục
  "Rủi ro & ngoại lệ có lý do" + quickstart nhóm H để người dùng quyết định.
- **Phương án khác** (nếu muốn đúng "ảnh"): dựng lại 2 widget `fl_chart` trong một
  `RepaintBoundary` đặt offscreen (`Positioned` âm trong `Stack`, chỉ mount lúc
  xuất) → `toImage(pixelRatio: 3)` → PNG → `pw.MemoryImage`; thêm ~100 dòng + một
  seam thứ hai cho test. Chuyển hướng này tốn ~1 buổi thi công, không đổi số liệu.

## R11 — Tiến trình & phản hồi (FR-023/SC-008): dựng bytes trong `compute()`

- **Quyết định**: khi bấm "Xuất báo cáo": (1) chuyển bản chụp sang **dữ liệu thuần**
  (`List<ExportTxn>` + tổng hợp + bảng phân bổ + **bytes font đã nạp sẵn**), (2) gọi
  `compute(...)` (top-level function) để dựng bytes theo định dạng, (3) xong thì mở
  bảng chia sẻ. Trong lúc chạy: nút chuyển trạng thái "Đang tạo tệp…" + khoá bấm
  lặp; phần còn lại của màn vẫn cuộn/bấm back được.
- **Lý do**: `excel_community`/chuỗi CSV/`pdf` đều thuần Dart, đẩy sang isolate là
  cách duy nhất giữ UI phản hồi với dữ liệu nhiều năm (SC-008: < 5 giây, 0 lần
  đứng hình). `compute` là API sẵn của Flutter — không thêm dependency.
- **Bẫy đã biết**: `rootBundle` **không** dùng được trong isolate nền ⇒ **font và
  mọi asset phải nạp ở main isolate rồi truyền bytes vào** `compute`.
- **Phương án khác**: chạy hết trên main isolate rồi hiện spinner — với vài nghìn
  giao dịch sẽ giật/đứng hình (vi phạm SC-008); `Isolate.spawn` tự quản — nhiều
  code hơn `compute` mà không thêm gì.

## R12 — Chia sẻ: **một** seam, không ghi tệp tạm

- **Quyết định**: khai báo một typedef trong `lib/core/report/export_share.dart`:

  ```dart
  typedef ShareExport =
      Future<void> Function({
        required String fileName,
        required Uint8List bytes,
        required String mimeType,
      });
  ```

  mặc định = `SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes,
  name: fileName, mimeType: mimeType)]))`. `ReportExportScreen` nhận tham số tùy
  chọn `ShareExport? share` (mặc định dùng bản thật) ⇒ test bơm fake, không đụng
  plugin trong `flutter test`.
- **Lý do**: `XFile.fromData` bỏ hẳn `path_provider` + ghi tệp tạm + nhánh lỗi
  "hết dung lượng" của riêng app; plugin tự lo phần đệm. Một seam duy nhất ⇒ test
  màn 04 không cần mock 3 plugin.
- **Phương án khác**: ghi tệp tạm rồi `Share.shareXFiles([XFile(path)])` — thêm
  I/O, thêm đường lỗi, không lợi ích; mock `MethodChannel` của share_plus trực tiếp
  trong test — vỡ khi plugin đổi channel.
- **Rủi ro**: một số nền tảng có thể bỏ qua `name` của `XFile.fromData`. **Dự
  phòng**: nếu QA thấy tên tệp chia sẻ sai ⇒ đổi sang ghi tệp tạm bằng
  `path_provider` (đã có sẵn) + `XFile(path)`; vẫn **một** seam, không đổi chỗ khác.

## R13 — Một định dạng, một nội dung: hợp đồng tệp

| Định dạng | Nội dung (FR-012/013/014) |
|---|---|
| **PDF** | Trang đầu: tiêu đề + khoảng thời gian → 3 số tổng hợp (tổng thu, tổng chi, chênh lệch) → 2 biểu đồ (R10) → bảng top danh mục (top 5 + "Khác"); tiếp theo: **danh sách giao dịch** dạng bảng, phân trang bằng `pw.MultiPage` |
| **Excel** | Sheet **"Tổng hợp"**: 3 số tổng hợp + bảng phân bổ (R6); Sheet **"Giao dịch"**: đúng bộ cột CSV |
| **CSV** | Chỉ danh sách giao dịch: dòng tiêu đề + mỗi dòng một giao dịch; **BOM UTF-8**; không phần tổng hợp/hình ảnh |

- **Cột danh sách giao dịch** (giống nhau ở cả 3 định dạng — FR-014/015): ngày
  (`dd/MM/yyyy`), loại (Thu/Chi/Chuyển khoản/Điều chỉnh số dư), danh mục (tên
  snapshot; transfer/adjustment để trống), ví (tên), số tiền, ghi chú, tag.
- **Số tiền trong danh sách**: ghi **số có dấu đúng như giao dịch** (thu `+`, chi
  `−`, hai vế chuyển khoản `∓`, điều chỉnh `±`), **không** phân tách nghìn, **không**
  đơn vị (FR-019: bảng tính đọc thành số). Chỉ những chỗ **hiển thị cho người đọc**
  (màn hình, mục tổng hợp trong PDF/Excel) mới dùng `formatMoney` (`42.500.000 đ`).
- **Lý do ghi số có dấu**: `Transaction.amount` vốn có dấu và hai vế chuyển khoản
  chỉ phân biệt được bằng dấu ⇒ cột "số tiền" giữ đúng dữ liệu, cột "loại" nói
  hướng. Tổng của cột trong bảng tính = dòng tiền ròng (đối chiếu được).

## R14 — Tên tệp (FR-024)

- **Quyết định**: `bao-cao-thu-chi_<yyyyMMdd>-<yyyyMMdd>.<ext>` (VD
  `bao-cao-thu-chi_20260901-20260930.pdf`), phần mở rộng theo định dạng
  (`pdf`/`xlsx`/`csv`), **ASCII thuần** nên không có ký tự cấm của hệ điều hành,
  nêu rõ khoảng thời gian + định dạng.
- **Lý do**: `dd/MM/yyyy` trong tên tệp chứa `/` (ký tự cấm) ⇒ dùng `yyyyMMdd`
  không dấu phân cách; tên ASCII tránh rắc rối khi chia sẻ sang ứng dụng khác.
- **Phương án khác**: giữ dấu tiếng Việt trong tên (`bao-cao-thu-chi_01-09...`) —
  đẹp hơn nhưng rủi ro tùy ứng dụng nhận; không có lợi ích bù.

## R15 — Chip VÍ / DANH MỤC, chip "+N khác"

- **Quyết định**:
  - **VÍ**: chip `'Tất cả'` + một chip mỗi ví (`walletsByDisplayOrder`); chip đang
    chọn nền `AppColors.teal` chữ trắng, chưa chọn `softCardBg` chữ `listLabel`;
    chọn nhiều ví cùng lúc; chạm `'Tất cả'` **xoá hết** lựa chọn (FR-005).
  - **DANH MỤC**: chip `'Tất cả'` + **tối đa 3** chip danh mục **cha** đang hoạt
    động (cả thu lẫn chi, theo `sortOrder`); phần vượt hiển thị thành **chip
    "+N khác"** mở `showModalBottomSheet` liệt kê **toàn bộ** danh mục cha với ô
    chọn nhiều (FR-006). `'Tất cả'` xoá hết lựa chọn.
- **Lý do**: ngưỡng **hằng số 3** là luật tất định, không phải đo chiều rộng văn
  bản (đo ⇒ phức tạp + kết quả phụ thuộc cỡ chữ, khó test). Mockup `04` vẽ 2 chip
  + "+3 khác" trên tổng 5 danh mục — cách chia chính xác của mockup không nằm
  trong SC-001 (SC-001 chỉ đòi **có** chip "Tất cả" + chip "+N khác"), nên đây là
  lệch nhỏ được ghi nhận.
- **Phương án khác**: `LayoutBuilder` + đo chiều rộng từng chip rồi cắt theo chỗ
  trống — sát mockup hơn nhưng thêm ~40 dòng và làm test phụ thuộc font.
- **Danh mục ẩn**: không vào hàng chip (spec, biên "danh mục đã bị ẩn"); giao dịch
  của danh mục ẩn **vẫn** vào tệp khi không lọc theo danh mục (lọc không đụng tới
  chúng).

## R16 — Cảnh báo trước khi xuất (FR-028) & trạng thái rỗng (FR-017/FR-018)

- **Quyết định**: một dòng chú thích — icon `Icons.warning_amber_rounded` coral +
  chữ — đặt **ngay trên nút "Xuất báo cáo"** (đọc được trước khi bấm), nền
  `coralLightBg`, **không** hộp thoại xác nhận (chốt Q3). Bộ lọc ra **0 giao dịch**
  ⇒ nút mờ (`onPressed: null`) + dòng thông báo dưới hộp tóm tắt; màn **vẫn mở
  được** và vẫn hiện đủ 5 mục (không nhánh màn trắng).
- **Lý do**: FR-028 yêu cầu "hiển thị sẵn trong màn, đọc được trước khi bấm xuất";
  coral là màu **cảnh báo** theo design system — đúng ngữ nghĩa (không phải chi
  tiêu). Không hộp thoại ⇒ không thêm một lần chạm cho mọi lần xuất.

## R17 — i18n: khóa mới + tái dùng

- **Tái dùng** (đã có): `'Tất cả'`, `'Huỷ'`, `'Thử lại'`, `'Thu'`, `'Chi'`,
  `'Chuyển khoản'`, `'Điều chỉnh số dư'`, `'Khác'`, `'Tổng thu'`, `'Tổng chi'`,
  `'Ghi chú'`, `'Ngày'`, `'Ví'`, `'Danh mục'`.
- **Thêm mới** (nhánh `en` của `sora_translations.dart` — khóa = chuỗi tiếng Việt):
  1. `'Xuất báo cáo'` 2. `'Xuất'` (tooltip icon vùng tiêu đề)
  3. `'KHOẢNG THỜI GIAN'` 4. `'Từ ngày'` 5. `'Đến ngày'`
  6. `'VÍ'` 7. `'DANH MỤC'` 8. `'TAG'`
  9. `'Nhập tag để lọc (VD: #dulich)'`
  10. `'ĐỊNH DẠNG XUẤT'` 11. `'Có biểu đồ'` 12. `'Bảng dữ liệu'` 13. `'Dữ liệu thô'`
  14. `'@count giao dịch • @from – @to'` 15. `'Định dạng: @format (@hint)'`
  16. `'@count khác'` (chip "+N khác") 17. `'Chọn danh mục'` (tiêu đề sheet)
  18. `'Bộ lọc hiện không có giao dịch nào'`
  19. `'Tệp xuất ra không còn được app bảo vệ. Hãy cẩn thận khi chia sẻ.'`
  20. `'Đang tạo tệp…'` 21. `'Đã tạo tệp'` (SnackBar khi mở bảng chia sẻ)
  22. `'Không tạo được tệp báo cáo'` 23. `'Không đọc được dữ liệu để xuất báo cáo'`
  24. `'Báo cáo thu chi'` (tiêu đề trong tệp) 25. `'Chênh lệch'`
  26. `'Danh sách giao dịch'` 27. `'Tổng hợp'` 28. `'Phân bổ chi theo danh mục'`
  29. `'Dòng tiền'` 30. `'Số tiền'` 31. `'Loại'`
- **Không dịch**: `PDF`/`Excel`/`CSV` (tên định dạng), định dạng ngày/số tiền.
- **Lý do**: khóa dịch = chính chuỗi tiếng Việt (R1 của PBI 19) ⇒ tiếng Việt không
  cần bản đồ; test cũ pump `MaterialApp` thường giữ nguyên kết quả.

## R18 — Kiểm thử

- **Quyết định**: **3 file test mới** + **sửa 1 file test cũ**:
  | File | Nội dung |
  |---|---|
  | `test/report_export_test.dart` | **MỚI** — thuần: lọc (ngày biên, nhiều ví, cha→con, tag bỏ dấu/hoa-thường, AND giữa các nhóm), giữ transfer/adjustment, thứ tự dòng, tổng hợp khớp `reportTotals`/`reportBreakdown`, tên tệp, CSV (BOM, escape `"`/`,`/xuống dòng, số có dấu) |
  | `test/report_export_writers_test.dart` | **MỚI** — bytes: PDF bắt đầu `%PDF` + chứa chuỗi tiếng Việt khi giải nén (không assert layout), XLSX mở bằng `archive` → có `xl/workbook.xml` + 2 sheet + ô tiếng Việt |
  | `test/report_export_screen_test.dart` | **MỚI** — màn 04 với repo giả + `ShareExport` giả: mặc định kế thừa kỳ, cập nhật hộp tóm tắt, chip ví/danh mục + "+N khác", nút vô hiệu khi 0 giao dịch, dòng cảnh báo, đổi định dạng, gọi seam đúng 1 lần với tên tệp/mime đúng |
  | `test/report_screen_test.dart` | **SỬA** — có icon xuất trên vùng tiêu đề, chạm mở màn 04 (kể cả khi kỳ rỗng — khác nút so sánh) |
- **Lý do**: phần lớn luật (lọc/tổng hợp/tên tệp/CSV) kiểm ở **tầng thuần** — nhanh,
  không cần pump widget; phần "bytes mở được" kiểm bằng cấu trúc zip/`%PDF` vì
  không có Excel/trình đọc PDF trong CI.
- **Mốc trước PBI**: **883 pass + 1 test đỏ có sẵn** (`transactions_dao_test`, PBI 11)
  ⇒ mục tiêu **không tăng** số test đỏ.

## R19 — Ràng buộc kế thừa & thay đổi hạ tầng lần này

- **Không đổi**: schema drift giữ **v8** — không bảng/cột/migration/`build_runner`;
  không đổi chữ ký `WalletRepository`; không đụng `AppShell`/`AppBottomNavBar`
  (màn 04 đẩy qua `SubPageScaffold`); không sửa `buildReportView`/`reportTotals`/
  `reportBreakdown`/`reportTopCategories`/`reportCategoryDetail`/`reportComparison`
  (màn 01/02/03 + test PBI 22/23/26 giữ nguyên); **không** tạo `contracts/` (app
  thuần nội bộ — đồng nhất PBI 19–26).
- **Có đổi (khác các PBI 22/23/26)**: `pubspec.yaml` **bắt buộc** sửa — thêm 3
  dependency (R8) + khai báo `assets/fonts/` (R9); và **1 lần** nâng
  `_effectiveCategoryIds` → `effectiveCategoryIds` trong
  `lib/core/transaction/transaction_filter.dart` (đổi tên private, 1 call site nội
  bộ — không đổi hành vi, không đổi API công khai nào đang dùng).
- **Lý do**: đợt này lần đầu sinh **tệp** (PDF/XLSX/CSV) và mở bảng chia sẻ — không
  có cách nào làm bằng những gì repo đang có; phần còn lại vẫn chỉ **đọc** dữ liệu.
