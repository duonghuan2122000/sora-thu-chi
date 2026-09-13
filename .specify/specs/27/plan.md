# Kế hoạch triển khai: Xuất báo cáo (màn 04 Báo cáo)

**Mã PBI**: 27
**Liên kết spec**: [.specify/specs/27/spec.md](./spec.md)
**Ngày tạo**: 2026-09-13

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12 / Flutter (Android + iOS), app **offline hoàn toàn** (không đăng nhập, không server) |
| Framework / Thư viện chính | GetX `^4.7.3` (điều hướng + DI + i18n), Material. **Thêm 3 dependency** (lần đầu PBI này phải sửa `pubspec.yaml`): `pdf ^3.13.0` (sinh PDF, thuần Dart), `excel_community ^2.4.0` (sinh `.xlsx`; bản fork của `excel` mở `archive >=4.0.9` — `excel 4.0.6` **xung đột** với `image ^4.9.2` của PBI 25, đã kiểm bằng `flutter pub add --dry-run`), `share_plus ^13.3.0` (bảng chia sẻ hệ thống). **Không** thêm `csv` (tự viết RFC 4180 + BOM, ~30 dòng), **không** thêm `printing` (cả 3 định dạng đi chung một đường chia sẻ) |
| Lưu trữ dữ liệu | drift `^2.34.4` + sqlite local — **schema giữ nguyên v8** (PBI 24): **không** bảng/cột/migration, **không** `build_runner`; màn 04 chỉ **đọc**: `allTransactions()`, `loadAll()`, `categories(type: income)`, `categories(type: expense)` |
| Kiểm thử | `flutter_test` — mốc trước PBI: **883 pass + 1 test đỏ có sẵn** (`transactions_dao_test`); thêm **3 file test mới**, sửa **1 file test cũ**; mục tiêu **không tăng** số test đỏ. Phần lớn luật kiểm ở **tầng thuần**; màn 04 test bằng repo giả + seam chia sẻ giả |
| Nền tảng triển khai | Build local (`flutter build apk` / iOS build) — không server, không CI đặc biệt; `share_plus` mở bảng chia sẻ của hệ điều hành (không gửi tệp đi đâu) |
| Ràng buộc hiệu năng | FR-022/SC-007: đổi bộ lọc → hộp tóm tắt **< 1 giây**, tính từ **bản chụp RAM** (không đọc lại kho — FR-026). SC-008: dựng tệp **< 5 giây**, UI **không đứng hình** ⇒ dựng bytes trong `compute()` (isolate), font nạp sẵn ở main isolate (R11) |
| Ràng buộc khác | Ngôn ngữ giao diện/tài liệu/commit: **tiếng Việt có dấu**; bám Design System (teal `#0F6E56` = hành động/trạng thái chọn; coral `#D85A30` **chỉ** cho cảnh báo/chi tiêu — dòng cảnh báo FR-028 dùng coralLightBg); mọi màu đi qua token `SoraColors`/`AppColors`; mọi nhãn tĩnh + thông báo mới phải có bản dịch EN (PBI 19) |
| Nguồn chân lý nghiệp vụ | `docs/report/bao-cao-thong-ke-giai-phap.md` (§3.7 xuất báo cáo, §3.8 bộ lọc, §4 luồng "chạm icon Xuất báo cáo (app bar) → Màn Xuất báo cáo → Share sheet", §6 thư viện đề xuất, §8 biên "bộ lọc rỗng" + "file ra ngoài app không còn được Privacy mode bảo vệ") + mockup `docs/report/man-hinh-04-xuat-bao-cao.svg`; kế thừa PBI 22 (`reportTotals`, `reportBreakdown`, `reportPeriodRange`), PBI 12 (`normalizeSearch`, luật gộp cha→con), PBI 21 (`SubPageScaffold` + khuôn màn đọc dữ liệu có nhánh loading/error) |

*Không còn mục `NEEDS CLARIFICATION`: spec đã "Đã làm rõ" (4 quyết định chốt
2026-09-13, ghi ở mục "Quyết định đã chốt"); các quyết định còn lại là chi tiết
triển khai — xem [research.md](./research.md) (R1…R19).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** (repo chưa tạo hiến pháp) ⇒
đối chiếu theo `CLAUDE.md` của repo và các quyết định đã chốt trong `docs/`.

| Nguyên tắc (nguồn: CLAUDE.md + docs) | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn, không server/không auth | ⚠️ | Toàn bộ luật/tệp sinh tại máy, **không** gọi mạng lúc chạy. Ngoại lệ đã kiểm: font PDF **gói kèm** repo (không dùng `PdfGoogleFonts` tải lúc chạy — research R9); `share_plus` mở bảng chia sẻ **của hệ điều hành**, app không tự gửi tệp đi đâu (FR-011) |
| Ngôn ngữ giao diện/tài liệu/commit: tiếng Việt có dấu | ✅ | Mọi nhãn, tài liệu, comment, commit bằng tiếng Việt; tên định dạng (`PDF`/`Excel`/`CSV`) và định dạng ngày/số giữ nguyên theo ngôn ngữ (FR-020) |
| Stack đã chốt (drift + GetX + fl_chart) | ⚠️ | **Có thêm 3 dependency** — bắt buộc để sinh tệp PDF/XLSX và mở bảng chia sẻ (`docs` §6 đề xuất đúng `pdf`/`excel`/`share_plus`). Không thay stack hiện có; `fl_chart` **không** dùng thêm (biểu đồ trong tệp vẽ bằng widget của `pdf` — R10). Ngoại lệ có lý do, ghi ở mục cuối |
| Design system: 1 màu thương hiệu teal, coral chỉ cho chi/cảnh báo, không hex cứng trong widget | ✅ | Chỉ **đọc** token `SoraColors`/`AppColors` đã có; **không** sửa `sora_colors.dart`; chip đang chọn dùng fill `AppColors.teal`; dòng cảnh báo dùng `coralLightBg` + icon coral — đúng ngữ nghĩa "cảnh báo" |
| Số dư ví là đại lượng suy ra, không sửa tay | ✅ | Màn 04 **chỉ đọc**; không ghi bất kỳ bảng nào |
| Thu/chi/chuyển khoản: transfer không tính là thu/chi | ✅ | Con số tổng hợp đi qua **đúng** `reportTotals`/`reportBreakdown` của màn 01 (đã loại transfer + adjustment, gộp cha) ⇒ không thể lệch số (SC-004); **danh sách** trong tệp vẫn đủ mọi loại giao dịch (FR-015) |
| Màn cấp tab có bottom nav, **màn con không** | ✅ | Màn 04 là route đè shell qua `SubPageScaffold` (app bar teal + back, không bottom nav, không FAB); **không** đụng `AppShell`/`AppBottomNavBar` |
| Không sửa dữ liệu người dùng ngoài phạm vi | ✅ | Chỉ đọc `transactions`/`wallets`/`categories`; không đụng `budgets`/`app_settings`/`scan_*` |
| Không phá vỡ hành vi PBI trước | ✅ | Màn 01 chỉ **thêm** 1 icon vào `ScreenHeader.trailing`; `ReportController`/`TransactionController`/`WalletRepository` **không đổi chữ ký**; `report_view.dart` **không sửa** (chỉ gọi hàm đã có); `transaction_filter.dart` chỉ đổi tên **private** → public, 1 call site nội bộ |
| YAGNI / không abstraction sớm | ✅ | 2 file thuần + 1 seam chia sẻ + 1 màn mới + 1 icon; **không** controller mới, **không** repository mới, **không** cache/bảng tổng hợp, **không** token màu mới, **không** mẫu bố cục tuỳ chỉnh |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; `tasks.md` sinh ở bước sau |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại [research.md](./research.md). Tóm tắt các quyết định chính:

- **Điểm vào (R1)** — **Quyết định**: `ScreenHeader.trailing` của màn 01 thành
  `Row` 2 nút — So sánh + **Xuất báo cáo** (`Icons.ios_share`), nút xuất **luôn
  bấm được**. **Phương án khác**: hàng điều hướng kiểu mục "Ngân sách" (spec loại);
  gộp vào menu (thêm 1 lần chạm — FR-001 cấm).
- **Nguồn dữ liệu (R2)** — **Quyết định**: màn 04 tự đọc **một lần** khi mở
  (transactions + ví + danh mục **thu & chi đang hoạt động**), giữ bản chụp trong
  state; đổi bộ lọc không đọc lại (FR-026). **Lý do**: `ReportController` không giữ
  danh mục thu lẫn danh sách ví. **Phương án khác**: mở rộng `ReportController.load`
  (đụng controller đã QA của PBI 22/23/26, vẫn thiếu danh mục ẩn↔hoạt động).
- **Lọc (R3)** — **Quyết định**: module thuần mới `report_export.dart`; **tái
  dùng** `normalizeSearch` + nâng `_effectiveCategoryIds` → `effectiveCategoryIds`.
  **Không** tái dùng `filterTransactions` vì (a) 1 ví, (b) keyword khớp cả
  note/danh mục, (c) **group-keep transfer** kéo giao dịch ví không chọn vào tệp —
  vi phạm SC-010.
- **Khoảng ngày (R4)** — nửa mở `[start, end)` theo ngày lịch, "Đến ngày" =
  `end − 1 ngày`; bộ chọn ngày tự chặn (`firstDate`/`lastDate`) ⇒ không có nhánh
  lỗi.
- **Tag (R5)** — bỏ `#`, `normalizeSearch`, khớp **chứa** trên cột `tags`.
- **Số tổng hợp (R6)** — tái dùng **nguyên** `reportTotals` + `reportBreakdown`
  (top 5 + "Khác") ⇒ SC-004 sai lệch **0 đ** so với màn 01.
- **Danh sách trong tệp (R7)** — đủ mọi loại giao dịch, **không** group-keep, sắp
  **tăng dần theo ngày** rồi `id`.
- **Thư viện (R8)** — `pdf` + `excel_community` + `share_plus`; CSV tự viết; bỏ
  `printing`, bỏ `csv`, bỏ `syncfusion` (giấy phép), bỏ tự-viết-XLSX (rủi ro
  SC-005). **Lý do loại `excel`**: xung đột `archive` với `image ^4.9.2` (PBI 25).
- **Font PDF (R9)** — gói kèm `Roboto-Regular/Bold.ttf` (Apache-2.0, ~1 MB), khai
  báo trong `pubspec.yaml`; **không** tải font lúc chạy (offline).
- **Biểu đồ trong PDF (R10)** — vẽ bằng **widget của `pdf`** (cột Thu/Chi cho ≤ 6
  khoảng con + thanh ngang phân bổ), **không** chụp màn hình ⇒ thuần Dart, test
  được, chạy được trong isolate. **Lệch có lý do so với FR-012** (ghi ở mục cuối).
- **Tiến trình (R11)** — dựng bytes trong `compute()`; **asset nạp ở main
  isolate** rồi truyền bytes vào (bẫy `rootBundle` trong isolate).
- **Chia sẻ (R12)** — **một** seam `ShareExport` (`XFile.fromData`, không tệp tạm);
  test bơm fake.
- **Tệp & cột (R13/R14)** — PDF 2 phần (tổng hợp + biểu đồ + danh sách phân trang);
  Excel 2 sheet ("Tổng hợp", "Giao dịch"); CSV chỉ danh sách + **BOM UTF-8**; số
  tiền trong danh sách ghi **số có dấu**, không đơn vị; tên tệp
  `bao-cao-thu-chi_<yyyyMMdd>-<yyyyMMdd>.<ext>`.
- **Chip & "+N khác" (R15)** — tối đa **3** chip danh mục cha (hằng số), phần vượt
  vào chip "+N khác" mở `showModalBottomSheet`; danh mục **ẩn** không vào chip.
- **Cảnh báo & rỗng (R16)** — dòng cảnh báo hiển thị sẵn ngay trên nút xuất (không
  hộp thoại); 0 giao dịch ⇒ nút mờ + thông báo, màn vẫn mở đủ 5 mục.
- **i18n (R17)** — 31 khóa mới + tái dùng 14 khóa đã có.
- **Kiểm thử (R18)** — 3 file test mới + sửa `report_screen_test.dart`.
- **Ràng buộc kế thừa (R19)** — schema v8, không `contracts/`, không đổi chữ ký
  seam nào; **có** sửa `pubspec.yaml` + 1 lần đổi tên private→public ở PBI 12.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem [data-model.md](./data-model.md) — **không đổi schema**;
  6 thực thể logic (`ExportFormat`, `ReportExportFilter`, `ExportTxn`,
  `ReportExportData`, tên tệp, seam `ShareExport`) + 6 hàm thuần + **36 luật bất
  biến** + bảng vòng đời "khi nào số liệu đổi" + bảng truy vết FR → luật.
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app thuần nội bộ, không
  API/CLI/endpoint lộ ra ngoài (đồng nhất PBI 19–26). Hợp đồng nội bộ duy nhất là
  `WalletRepository` — **không đổi chữ ký**; hợp đồng mới duy nhất là seam
  `ShareExport` (một typedef, mô tả ở data-model §1.6).
- **Kịch bản khởi động nhanh**: xem [quickstart.md](./quickstart.md) — **16 nhóm
  kiểm thử tay A–P**, phủ FR-001…FR-028 và SC-001…SC-014.

### Kiến trúc chi tiết

**1. Hạ tầng — `app/sora_thu_chi/pubspec.yaml` (sửa)**

```yaml
dependencies:
  pdf: ^3.13.0              # sinh PDF (thuần Dart)
  excel_community: ^2.4.0   # sinh .xlsx (fork của `excel`, hợp archive ^4)
  share_plus: ^13.3.0       # bảng chia sẻ hệ thống
flutter:
  assets:
    - assets/brand/
    - assets/fonts/         # THÊM — Roboto cho PDF (R9)
```

Thêm `assets/fonts/Roboto-Regular.ttf` + `Roboto-Bold.ttf` (Apache-2.0, tải một
lần lúc thi công từ `googlefonts/roboto-2/src/hinted/`).

**2. Tầng nghiệp vụ thuần — `lib/core/report/report_export.dart` (MỚI, ~260 dòng)**

| Thành phần | Vai trò |
|---|---|
| `enum ExportFormat { pdf, excel, csv }` + extension | `label`, `hint` (`Có biểu đồ`/`Bảng dữ liệu`/`Dữ liệu thô`), `extension` (`pdf`/`xlsx`/`csv`), `mimeType` |
| `class ReportExportFilter` | `start`, `end`, `walletIds`, `categoryIds`, `tag` + `fromRange`, `withStart`, `withEnd`, `toggleWallet`, `toggleCategory`, `clearWallets`, `clearCategories`, `withTag` (bất biến) |
| `class ExportTxn` | một dòng tệp: `date`, `typeLabel`, `category`, `wallet`, `amount`, `note`, `tags` |
| `class ReportExportData` | `filter`, `range`, `transactions`, `rows`, `income`, `expense`, `allocation`, `fileName`; getter `count`, `isEmpty`, `balance` |
| `List<Transaction> filterForExport(all, filter, categories)` | luật 1–13 (ngày ∧ ví ∧ danh mục(+con) ∧ tag) |
| `ReportExportData buildReportExport({...})` | luật 14–16 + 23: gọi `reportTotals` + `reportBreakdown` của `report_view.dart`, tra tên ví từ `Map<int,String>`, sắp dòng |
| `String exportFileName(start, end, format)` | luật 24–25 |
| `Uint8List buildCsvBytes(List<ExportTxn>)` | luật 17–21 (tiêu đề + BOM + escape) |
| `List<CashflowBucket> exportCashflowBuckets(transactions, range)` | ≤ 6 khoảng con cho biểu đồ PDF (R10) |

Không sửa `report_view.dart` (chỉ **gọi** `reportTotals`/`reportBreakdown` — hai
hàm đã public), không sửa `report_controller.dart`.

**3. Tầng sinh tệp — `lib/core/report/report_export_writers.dart` (MỚI, ~200 dòng)**

```dart
Uint8List buildPdfBytes({
  required ReportExportData data,
  required ByteData fontRegular,
  required ByteData fontBold,
});                       // pw.Document + pw.MultiPage + ThemeData.withFont + MemoryImage-free

Uint8List buildXlsxBytes(ReportExportData data);   // excel_community: 2 sheet
```

- **PDF**: trang tổng hợp (tiêu đề + khoảng + 3 số dùng `formatMoney` + 2 biểu đồ
  vẽ bằng `pw.Container`/`pw.Row` + bảng top danh mục) → danh sách giao dịch
  (`pw.Table`/`pw.TableHelper`, phân trang tự động của `MultiPage`).
- **XLSX**: sheet `'Tổng hợp'` (3 số + bảng phân bổ) và sheet `'Giao dịch'` (bộ
  cột R13). Số tiền ghi **ô số**, nhãn mang đơn vị.
- Cả hai hàm **thuần** (không `Widget`/`BuildContext`, không asset) ⇒ gọi được
  trong `compute()` sau khi main isolate đã nạp font.

**4. Seam chia sẻ — `lib/core/report/export_share.dart` (MỚI, ~30 dòng)**

```dart
typedef ShareExport = Future<void> Function({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
});

ShareExport defaultShareExport = ({fileName, bytes, mimeType}) async {
  await SharePlus.instance.share(
    ShareParams(files: [XFile.fromData(bytes, name: fileName, mimeType: mimeType)]),
  );
};
```

**5. Màn mới — `lib/screens/report_export_screen.dart` (MỚI, ~520 dòng)**

```
ReportExportScreen (StatefulWidget, nhận ShareExport? share)
  initState → 1 lần đọc: allTransactions / loadAll / categories(income+expense)
  _filter (ReportExportFilter) · _format (ExportFormat) · _busy · _error
  SubPageScaffold(title: 'Xuất báo cáo'.tr)
    └ ListView (cuộn tới được nút xuất — FR-022)
        ├ _SectionTitle('KHOẢNG THỜI GIAN') + _DateFields (2 trường, showDatePicker có chặn)
        ├ _SectionTitle('VÍ')               + _ChipRow (Tất cả + mỗi ví, multi)
        ├ _SectionTitle('DANH MỤC')         + _ChipRow (Tất cả + ≤3 cha + "+N khác")
        ├ _SectionTitle('TAG')              + TextField (hint R17)
        ├ _SectionTitle('ĐỊNH DẠNG XUẤT')   + 3 × _FormatCard (viền teal + dấu chọn)
        ├ _SummaryBox  (số giao dịch + khoảng ngày · định dạng + chú thích)
        ├ _EmptyFilterNotice   (chỉ khi count == 0 — FR-017)
        ├ _PrivacyWarning      (coralLightBg + icon coral — FR-028)
        └ _ExportButton        (teal, cao 44+, "Đang tạo tệp…" khi _busy; null khi count == 0)
```

| Widget con | Ghi chú |
|---|---|
| `_DateFields` | Hai `InkWell` nền `softCardBg` bo 8, nhãn `Từ ngày`/`Đến ngày` + giá trị `dd/MM/yyyy`; chạm → `showDatePicker(firstDate:, lastDate:)` chặn chéo |
| `_ChipRow` | `Wrap` chip bo 15 cao 30; chọn = `AppColors.teal` + chữ trắng (đúng "trạng thái chọn") |
| `_FormatCard` | 3 thẻ ngang hàng (`Row` + `Expanded`), viền 2 px teal (chọn) / 1 px `divider`, dấu chọn tròn góc phải trên, icon trong bubble `tealLightBg`/`softCardBg` |
| `_SummaryBox` | Nền `softCardBg` bo 10, 2 dòng |
| `_PrivacyWarning` | `coralLightBg` bo 10 + `Icons.warning_amber_rounded` coral |
| `_busy` | Chặn bấm lặp; phần còn lại của màn vẫn phản hồi (FR-023) |

Luồng xuất: `_export()` → chuyển bản chụp sang `ReportExportData` (hàm thuần) →
`compute(_buildBytes, payload)` (`_buildBytes` **top-level**, payload chứa
`ReportExportData` + `Uint8List` font) → `share(fileName:, bytes:, mimeType:)` →
lỗi/plugin chặn ⇒ `SnackBar` `'Không tạo được tệp báo cáo'`, **giữ nguyên** state.

**6. Điểm vào — `lib/screens/report_screen.dart` (sửa, +~25 dòng)**

```dart
ScreenHeader(
  title: 'Báo cáo'.tr,
  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
    _CompareButton(...),                 // giữ nguyên
    _ExportButton(onTap: () => _openExport(context)),
  ]),
  ...
)
```

`_openExport` → `Navigator.push(MaterialPageRoute(builder: (_) => const ReportExportScreen()))`.
Nút xuất **luôn** enabled (khác nút so sánh — FR-001 + chốt).

**7. Nâng 1 hàm dùng chung — `lib/core/transaction/transaction_filter.dart` (sửa 2 dòng)**

`_effectiveCategoryIds` → `effectiveCategoryIds` (public) + cập nhật 1 call site
trong `filterTransactions`. Không đổi hành vi, không đổi API nào đang dùng.

**8. i18n — `lib/core/locale/sora_translations.dart` (sửa, +31 khóa)**

Danh sách khóa ở research R17. Tất cả là **khóa mới**, thêm vào nhánh `_en`; mặc
định tiếng Việt không cần bản đồ (khóa = chính chuỗi tiếng Việt).

**9. Kiểm thử**

| File | Việc |
|---|---|
| `test/report_export_test.dart` | **MỚI** — 36 luật: lọc (biên ngày, nhiều ví, cha→con, tag bỏ dấu/hoa-thường, VÀ/HOẶC), giữ transfer/adjustment, thứ tự dòng, tổng hợp khớp `reportTotals`/`reportBreakdown`, tên tệp, CSV (BOM, escape, số có dấu), `exportCashflowBuckets` (≤ 6, không mất ngày) |
| `test/report_export_writers_test.dart` | **MỚI** — PDF bắt đầu `%PDF`; XLSX giải nén bằng `archive` → có `xl/workbook.xml` + 2 sheet + ô tiếng Việt đọc lại đúng; `buildCsvBytes` không có BOM lặp |
| `test/report_export_screen_test.dart` | **MỚI** — màn 04 với `FakeWalletRepository` + `ShareExport` giả: kế thừa kỳ đang xem, hộp tóm tắt cập nhật, chip ví/danh mục + "+N khác", nút vô hiệu khi 0 giao dịch, dòng cảnh báo hiện sẵn, đổi định dạng, gọi seam đúng 1 lần với tên tệp + mime đúng, huỷ/lỗi giữ nguyên state |
| `test/report_screen_test.dart` | **SỬA** — có icon xuất trên vùng tiêu đề; chạm mở màn 04 **kể cả khi kỳ rỗng** (khác nút so sánh) |

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| App offline hoàn toàn | ✅ | Font nhúng từ asset; không có lời gọi mạng nào trong mã mới; `share_plus` chỉ mở bảng chia sẻ của HĐH |
| Tiếng Việt có dấu | ✅ | 31 khóa dịch thêm vào nhánh `_en`; không có chuỗi tiếng Anh trần ngoài nhánh đó |
| Stack đã chốt | ⚠️ | +3 dependency (ngoại lệ có lý do — mục cuối); không đổi stack hiện có, không dùng thêm `fl_chart` |
| Design system & token màu | ✅ | Không sửa `sora_colors.dart`/`app_colors.dart`; mọi màu từ token |
| Transfer không tính là thu/chi | ✅ | Con số tổng hợp đi qua `reportTotals`/`reportBreakdown`; **danh sách** giữ đủ loại (FR-015) |
| Màn con không bottom nav | ✅ | `SubPageScaffold`; không đụng `AppShell` |
| Không phá vỡ PBI trước | ✅ | Chỉ **thêm**: 1 màn, 6 hàm thuần, 1 seam, 1 icon, 31 khóa; 1 lần đổi tên private→public (không đổi hành vi); không đổi chữ ký nào đang dùng |
| YAGNI | ✅ | Không controller/repository mới, không cache, không token mới, không widget dùng chung mới, không tệp cấu hình |
| Đa tiền tệ / kỳ tài chính lệch ngày / Ẩn số dư | ✅ | Đều **ngoài phạm vi** (spec); thiết kế không tạo đường nào cho chúng lọt vào (số tiền ghi đúng như giao dịch, ngày dương lịch, không che số) |
| Không ghi dữ liệu người dùng | ✅ | Màn 04 chỉ đọc 3 bảng; tệp sinh ra nằm ngoài DB, app không tự lưu vào thư mục cố định (FR-011) |

## Cấu trúc dự án dự kiến

```text
.specify/specs/27/
├── spec.md          (đã có)
├── checklists/      (đã có)
├── research.md      (MỚI — R1…R19)
├── data-model.md    (MỚI — 6 thực thể + 36 luật + truy vết FR)
├── quickstart.md    (MỚI — QA tay A–P)
├── plan.md          (MỚI — file này)
└── tasks.md         (bước sau: /sora-task 27)

app/sora_thu_chi/
├── pubspec.yaml                      (SỬA: +pdf, +excel_community, +share_plus, +assets/fonts)
├── assets/fonts/
│   ├── Roboto-Regular.ttf            (MỚI — Apache-2.0)
│   └── Roboto-Bold.ttf               (MỚI — Apache-2.0)
├── lib/core/report/
│   ├── report_export.dart            (MỚI: bộ lọc + tổng hợp + tên tệp + CSV + bucket)
│   ├── report_export_writers.dart    (MỚI: bytes PDF + XLSX)
│   └── export_share.dart             (MỚI: seam ShareExport + bản mặc định share_plus)
├── lib/core/transaction/
│   └── transaction_filter.dart        (SỬA: `_effectiveCategoryIds` → public)
├── lib/screens/
│   ├── report_screen.dart             (SỬA: +nút xuất cạnh nút so sánh, +_openExport)
│   └── report_export_screen.dart      (MỚI: màn 04)
├── lib/core/locale/
│   └── sora_translations.dart         (SỬA: +31 khóa en)
└── test/
    ├── report_export_test.dart             (MỚI)
    ├── report_export_writers_test.dart     (MỚI)
    ├── report_export_screen_test.dart      (MỚI)
    └── report_screen_test.dart             (SỬA)

KHÔNG đụng: lib/data/ (schema drift v8), lib/core/report/report_view.dart,
            lib/core/report/report_controller.dart, lib/theme/*,
            lib/screens/app_shell* | AppBottomNavBar, lib/core/widgets/*,
            docs/, wiki-knowledge/ (wiki cập nhật ở bước sau — skill sora-wiki)
```

## Rủi ro & ngoại lệ có lý do

### Ngoại lệ có lý do

| # | Ngoại lệ | Lý do |
|---|---|---|
| 1 | **`pubspec.yaml` có 3 dependency mới** (`pdf`, `excel_community`, `share_plus`) — khác PBI 22/23/26 (không sửa pubspec) | Đợt này lần đầu **sinh tệp** (PDF/XLSX) và **mở bảng chia sẻ** — không thể làm bằng những gì repo đang có; `docs` §6 đề xuất đúng bộ này. `share_plus` buộc phải có vì cả 3 định dạng đi chung một đường chia sẻ |
| 2 | **PDF chứa biểu đồ vẽ lại, không phải "ảnh" chụp biểu đồ màn 01** (lệch chữ của FR-012) | Hai widget biểu đồ màn 01 là **private**; chụp ảnh cần dựng lại bản sao + `RepaintBoundary.toImage()` offscreen (khó test, dễ flaky). Vẽ bằng widget `pdf` là thuần Dart ⇒ test được, chạy được trong isolate, và **số liệu/định nghĩa nhóm y hệt** màn 01 (SC-004 vẫn 0 đ). Dạng biểu đồ phân bổ là **thanh ngang** thay vì donut (donut không vẽ được bằng widget `pdf`). Muốn đúng "ảnh": research R10 ghi phương án thay thế (~1 buổi thi công, không đổi số liệu) |
| 3 | **Chip DANH MỤC hiện tối đa 3 chip + "+N khác"** (mockup `04` chia theo chỗ trống thực tế) | Ngưỡng hằng số là luật tất định, không phụ thuộc cỡ chữ/font; SC-001 chỉ đòi **có** chip "Tất cả" + chip "+N khác", không ràng buộc số chip hiện ra |
| 4 | **Lọc tag chỉ soi cột `tags`** (bộ lọc màn Giao dịch soi cả ghi chú + tên danh mục) | FR-007 nói rõ "lọc theo **tag** của giao dịch"; dùng chung `keyword` của PBI 12 sẽ ra kết quả thừa khó hiểu (khớp cả ghi chú) |
| 5 | **Thêm ~1 MB asset font** vào app | Điều kiện bắt buộc để PDF có chữ tiếng Việt (font mặc định của `pdf` không hỗ trợ); dùng font hệ thống/tải lúc chạy đều không khả thi (R9) |

### Rủi ro & ứng phó

| # | Rủi ro | Ứng phó |
|---|---|---|
| 1 | **`excel_community` là fork ít phổ biến hơn `excel`** — API có thể khác chút, hoặc tệp sinh ra không mở được bằng bảng tính (SC-005) | Thi công kiểm ngay: test mở lại zip đọc `xl/workbook.xml` + 2 sheet + ô tiếng Việt; QA tay nhóm I1/I2/I4/I6 mở bằng bảng tính thật. Nếu fork không đạt ⇒ phương án B: tự viết XLSX bằng `archive` (R8) |
| 2 | **`share_plus` bỏ qua `name` của `XFile.fromData`** trên một số nền tảng ⇒ tên tệp chia sẻ sai (FR-024) | QA nhóm H2 kiểm tên tệp; dự phòng: ghi tệp tạm bằng `path_provider` (đã có sẵn) rồi `XFile(path)` — vẫn **một** seam, không đổi chỗ khác |
| 3 | **`rootBundle` không dùng được trong isolate nền** ⇒ PDF mất font, chữ tiếng Việt vỡ | Bắt buộc: nạp 2 font ở main isolate (`initState`) rồi truyền `Uint8List` vào `compute`; QA nhóm H4 kiểm chữ có dấu |
| 4 | **`compute()` với payload lớn** (vài nghìn giao dịch + font 1 MB) tốn thời gian copy | Payload chỉ gồm `List<ExportTxn>` (record nhỏ) + 3 số + bảng phân bổ + font bytes; đo ở nhóm P2–P4 (< 5 giây). Nếu chậm ⇒ chuyển `Transaction`→`ExportTxn` **bên trong** isolate |
| 5 | **Bộ chọn ngày chặn chéo** dễ cài sai (chọn "Từ ngày" lại chặn nhầm chiều) | Luật 5 ở data-model + quickstart C1/C2/C4 kiểm cả hai chiều và trường hợp bằng nhau |
| 6 | **`toImage`/biểu đồ**: không áp dụng (đã chọn vẽ bằng widget `pdf`) | — |
| 7 | **Test đỏ có sẵn** `transactions_dao_test` (PBI 11) dễ bị nhầm là lỗi mới | Ghi rõ mốc baseline **883 pass / 1 fail** ở plan + quickstart §5; mục tiêu là **không tăng** số test đỏ |
| 8 | **File pubspec/font làm `flutter test` đỏ hàng loạt** nếu khai báo asset sai | Thêm asset + `flutter pub get` trước khi chạy test; QA nhóm H4 là chốt cuối |
| 9 | **Cấu hình native khi thêm `share_plus`** (Android `minSdk`, iOS Info.plist) có thể phải chỉnh | Thi công chạy `flutter build apk` ngay sau khi thêm dependency; ghi lại mọi thay đổi native vào `tasks.md` |
| 10 | **iOS chưa QA** ở các PBI trước; đợt này có plugin native mới | Nên chạy nhóm H1/H2/I1/I4 trên iOS nếu có máy; nếu bỏ qua phải ghi rõ trong `tasks.md` |
