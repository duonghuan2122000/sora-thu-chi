# Mô hình dữ liệu: Xuất báo cáo (màn 04 Báo cáo)

**Mã PBI**: 27
**Liên kết spec**: [spec.md](./spec.md) · **Nghiên cứu**: [research.md](./research.md)
**Ngày tạo**: 2026-09-13

> Đợt này **không đổi schema drift** (giữ **v8**, PBI 24): không bảng, không cột,
> không migration, **không** chạy `build_runner`. Mọi thực thể dưới đây là **thực
> thể logic trong RAM** — đại lượng **tính toán**, không ghi xuống đâu.

---

## 1. Thực thể

### 1.1. `ExportFormat` — định dạng xuất (FR-009, enum)

| Giá trị | Nhãn | Dòng chú thích | Đuôi tệp | MIME |
|---|---|---|---|---|
| `pdf` | `PDF` | `Có biểu đồ` | `.pdf` | `application/pdf` |
| `excel` | `Excel` | `Bảng dữ liệu` | `.xlsx` | `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` |
| `csv` | `CSV` | `Dữ liệu thô` | `.csv` | `text/csv` |

Định dạng **không dịch nhãn** (tên định dạng/ký hiệu — R17); dòng chú thích **có**
bản dịch. Mặc định `ExportFormat.pdf` (spec "Giả định" + chốt 2026-09-13).

### 1.2. `ReportExportFilter` — bộ lọc của màn (FR-003…FR-008), **bất biến**

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `start` | `DateTime` | 00:00 **ngày đầu** khoảng (bao gồm) |
| `end` | `DateTime` | 00:00 **ngày sau ngày cuối** (loại trừ) — quy ước `DateRange` (R4) |
| `walletIds` | `Set<int>` | ví đã chọn; **rỗng = không giới hạn** |
| `categoryIds` | `Set<int>` | id danh mục **cha** đã chọn; rỗng = không giới hạn; chọn cha ⇒ gồm con (R3) |
| `tag` | `String` | chuỗi tag thô người dùng gõ (có thể kèm `#`); rỗng = không lọc tag |

Phương thức bất biến: `ReportExportFilter.fromRange(DateRange)` (mặc định kế thừa
kỳ đang xem), `withStart(DateTime)`, `withEnd(DateTime)`, `toggleWallet(int)`,
`toggleCategory(int)`, `clearWallets()`, `clearCategories()`, `withTag(String)`.
Không có `copyWith` tổng quát (mỗi thao tác UI là một luật rõ — như
`TxnSearchFilter` của PBI 12).

### 1.3. `ExportTxn` — **một dòng** trong mọi tệp (FR-014/FR-015)

| Trường | Kiểu | Nguồn |
|---|---|---|
| `date` | `DateTime` | `Transaction.date` |
| `typeLabel` | `String` | `TxnType.label` (`Thu`/`Chi`/`Chuyển khoản`/`Điều chỉnh số dư`) — **đã dịch** |
| `category` | `String` | tên danh mục snapshot; transfer/adjustment ⇒ **chuỗi rỗng** |
| `wallet` | `String` | tên ví tra từ `Map<int, String>`; ví không còn ⇒ chuỗi rỗng |
| `amount` | `int` | **có dấu** đúng như giao dịch (thu `+`, chi `−`, 2 vế transfer `∓`, adjustment `±`) |
| `note` | `String` | `Transaction.note` |
| `tags` | `String` | `Transaction.tags` (thô, không `#`) |

### 1.4. `ReportExportData` — kết quả dựng cho một bộ lọc (bất biến)

| Trường | Kiểu | Ý nghĩa |
|---|---|---|
| `filter` | `ReportExportFilter` | bộ lọc đã áp |
| `range` | `DateRange` | `DateRange(start: filter.start, end: filter.end)` — đưa thẳng vào `reportTotals`/`reportBreakdown` |
| `transactions` | `List<Transaction>` | giao dịch khớp (đủ mọi loại), sắp **tăng dần theo ngày** rồi `id` (R7) |
| `rows` | `List<ExportTxn>` | bản chiếu 1-1 của `transactions` cho tệp (cùng thứ tự) |
| `income` / `expense` | `int` | từ `reportTotals` — **đã loại** transfer + adjustment (R6) |
| `allocation` | `List<ReportSlice>` | từ `reportBreakdown` — top 5 danh mục cha + "Khác", % cộng = 100 (R6) |
| `fileName` | `String` | theo định dạng đang chọn (1.5) |

Getter: `count` = `rows.length`; `isEmpty` = `transactions.isEmpty`;
`balance` = `income − expense` (chênh lệch).

### 1.5. Tên tệp (FR-024, R14)

```
bao-cao-thu-chi_<yyyyMMdd>-<yyyyMMdd>.<ext>
```

`<yyyyMMdd>` = ngày **đầu** và ngày **cuối** (đã trừ 1 ngày khỏi `range.end`);
`<ext>` theo `ExportFormat`. ASCII thuần ⇒ không ký tự cấm, nêu rõ khoảng + định dạng.

### 1.6. Seam chia sẻ `ShareExport` (R12)

```
ShareExport({fileName, bytes, mimeType}) -> Future<void>
```

Mặc định: `SharePlus.instance.share(ShareParams(files: [XFile.fromData(...)]))`.
Màn 04 nhận seam này qua tham số tùy chọn ⇒ test bơm fake, **không** đụng plugin.

---

## 2. Hàm thuần (module `report_export.dart`)

| Hàm | Chữ ký rút gọn | Vai trò |
|---|---|---|
| `filterForExport` | `(List<Transaction>, ReportExportFilter, List<Category>) → List<Transaction>` | luật 1–8 |
| `buildReportExport` | `({transactions, categories, wallets, filter, format}) → ReportExportData` | dựng cả màn/tệp |
| `exportFileName` | `(DateTime start, DateTime end, ExportFormat) → String` | luật 24–25 |
| `buildCsvBytes` | `(List<ExportTxn>) → Uint8List` | luật 26–29 |
| `exportCashflowBuckets` | `(List<Transaction>, DateRange) → List<({DateRange range, int income, int expense})>` | ≤ 6 khoảng con cho biểu đồ PDF (R10) |
| `buildPdfBytes` / `buildXlsxBytes` | `(data: ReportExportData, fontRegular: ByteData, fontBold: ByteData) → Uint8List` | module `report_export_writers.dart` |

---

## 3. Luật bất biến

**Bộ lọc — kết hợp nhóm (FR-008)**

1. Một giao dịch **vào** tập khi thoả **tất cả** nhóm đang có điều kiện: khoảng
   ngày ∧ ví ∧ danh mục ∧ tag (**VÀ** giữa các nhóm).
2. Trong **cùng một nhóm**, nhiều lựa chọn là **HOẶC** (ví A **hoặc** ví B; danh
   mục X **hoặc** Y).
3. Nhóm **rỗng = không giới hạn** nhóm đó (rỗng ví ⇒ mọi ví; rỗng danh mục ⇒ mọi
   danh mục; tag rỗng/chỉ khoảng trắng ⇒ không lọc tag).

**Khoảng ngày (FR-004, R4)**

4. Giao dịch vào tập khi `!date.isBefore(start) && date.isBefore(end)` —
   **bao gồm** ngày đầu và ngày cuối (`end` là 00:00 ngày sau ngày cuối).
5. `end` luôn **sau** `start` (ít nhất 1 ngày): UI chặn ngay ở bộ chọn ngày nên
   không tồn tại khoảng âm/rỗng — không có nhánh lỗi.

**Danh mục (FR-006, R3)**

6. Chọn danh mục **cha** ⇒ mọi **con cháu** của nó cũng khớp (dùng chung
   `effectiveCategoryIds` với bộ lọc màn Giao dịch).
7. Giao dịch không có `categoryId` (dữ liệu cũ) khớp theo **tên danh mục** đã bỏ
   dấu — cùng cách xử lý của `filterTransactions` (PBI 12).
8. Giao dịch `transfer`/`adjustment` **không** bị nhóm danh mục loại: chúng không
   có danh mục nên chỉ khớp khi nhóm danh mục **không** được chọn.

**Tag (FR-007, R5)**

9. Tag so khớp: bỏ `#` đầu + `normalizeSearch` hai vế rồi kiểm **chứa** ⇒ không
   phân biệt hoa/thường, không phân biệt dấu (`dulich` **khớp** `#dulich`,
   `Du lịch`).
10. Giao dịch `tags` rỗng **không** khớp khi ô tag có nội dung (0 giao dịch ⇒
    khoá nút xuất — FR-017).

**Tập giao dịch trong tệp (FR-015)**

11. Tập giao dịch giữ **mọi** loại: `income`, `expense`, `transfer`, `adjustment`
    — tệp là bản sao sổ giao dịch theo bộ lọc.
12. **Không** group-keep hai vế chuyển khoản: vế thuộc ví **không** được chọn
    **không** vào tệp (SC-010) — khác `filterTransactions` (R3).
13. Thứ tự: `date` **tăng dần**, đồng ngày thì `id` tăng dần ⇒ tất định, test/QA
    đối chiếu được từng dòng.

**Số liệu tổng hợp trong tệp (FR-016, SC-004)**

14. `income`/`expense` lấy **nguyên** từ `reportTotals(range)` ⇒ transfer +
    adjustment bị loại khỏi mọi con số tổng hợp.
15. `allocation` lấy **nguyên** từ `reportBreakdown(range)` ⇒ gộp danh mục con vào
    cha, top 5 + "Khác", % cộng = 100 — **khớp đúng** thẻ màn Tổng quan Báo cáo.
16. Chênh lệch = `income − expense`. Kỳ chỉ có chuyển khoản ⇒ danh sách vẫn có
    dòng, nhưng `income = expense = 0` và chênh lệch 0.

**Cột & số tiền trong tệp (FR-014, FR-019, FR-024, R13)**

17. Bộ cột danh sách giống nhau ở **cả 3** định dạng: ngày, loại, danh mục, ví,
    số tiền, ghi chú, tag — có **dòng tiêu đề**.
18. Ngày ghi `dd/MM/yyyy` (không đổi theo ngôn ngữ — FR-020).
19. Cột "số tiền" ghi **số có dấu**, không phân tách nghìn, không đơn vị ⇒ bảng
    tính đọc được thành số.
20. Những chỗ **hiển thị cho người đọc** (màn hình, mục tổng hợp PDF/Excel) dùng
    `formatMoney` (`42.500.000 đ`).
21. CSV: bọc `"…"` khi ô chứa `,`/`"`/xuống dòng, nhân đôi `"` bên trong; ghi
    **BOM UTF-8** ở đầu tệp (chữ tiếng Việt không lỗi font — FR-024).
22. PDF/Excel giữ **đúng** chữ có dấu; PDF dùng font nhúng (R9) ⇒ không vỡ chữ.
23. Danh mục của giao dịch đã bị **xoá** (không còn trong bảng) ⇒ cột danh mục ghi
    giá trị snapshot còn lưu; giao dịch **vẫn** vào tệp.
24. Tên tệp: ASCII, đúng mẫu 1.5, đuôi tệp theo định dạng đang chọn (FR-024).
25. Tên ví/danh mục **rất dài** không ảnh hưởng tên tệp (tên tệp chỉ mang ngày).

**Định dạng (FR-012/FR-013/FR-014, R13)**

26. **PDF**: tổng hợp + 2 biểu đồ (dòng tiền theo ≤ 6 khoảng con, phân bổ theo danh
    mục) + bảng top danh mục + **danh sách giao dịch** (phân trang).
27. **Excel**: 2 sheet — "Tổng hợp" (3 số + phân bổ) và "Giao dịch" (đúng bộ cột).
28. **CSV**: chỉ danh sách giao dịch — **không** tổng hợp, **không** hình ảnh.
29. Khoảng lọc **rất dài** (nhiều năm) vẫn xuất được; số cột biểu đồ dòng tiền
    **luôn ≤ 6** (R10) ⇒ chi phí vẽ không tăng theo số ngày.

**Trạng thái màn (FR-017/FR-018/FR-023/FR-025/FR-026/FR-027)**

30. `isEmpty` ⇒ nút "Xuất báo cáo" **vô hiệu hoá** + thông báo; **không** tạo tệp
    rỗng/chỉ có tiêu đề.
31. Màn **luôn mở được** kể cả khi kỳ rỗng: đủ 5 mục + hộp tóm tắt + dòng cảnh báo.
32. Bộ lọc/định dạng **chỉ sống trong phiên mở màn**: mở lại ⇒ về mặc định kế thừa
    kỳ đang xem; không ghi nhớ, không áp sang màn khác, không đổi kỳ màn Tổng quan.
33. Số liệu tính từ **bản chụp đọc một lần** khi mở màn; đổi bộ lọc **không** đọc
    lại kho dữ liệu (FR-026).
34. Đang tạo tệp ⇒ trạng thái "Đang tạo tệp…", chặn bấm lặp, phần còn lại của màn
    vẫn phản hồi; xong ⇒ mở bảng chia sẻ.
35. Tạo tệp lỗi hoặc người dùng huỷ bảng chia sẻ ⇒ màn **không treo**, bộ lọc và
    định dạng **giữ nguyên**, lỗi hiện thông báo dễ hiểu (SnackBar).
36. Dòng cảnh báo "tệp ra khỏi app không còn được bảo vệ" **luôn hiển thị sẵn**
    trước khi bấm xuất; số tiền trong tệp **không** bị che (FR-028).

---

## 4. Vòng đời — khi nào số liệu đổi

| Sự kiện | `count`/`income`/`expense`/`allocation` | Đọc lại kho dữ liệu? |
|---|---|---|
| Mở màn 04 (từ màn Tổng quan) | dựng theo khoảng = **kỳ đang xem** | **Có** — đúng 1 lần (`initState`) |
| Đổi "Từ ngày"/"Đến ngày" | dựng lại theo khoảng mới | Không |
| Chọn/bỏ ví, chọn/bỏ danh mục, gõ tag | dựng lại theo bộ lọc mới | Không |
| Đổi định dạng | chỉ đổi dòng 2 hộp tóm tắt + tên tệp | Không |
| Bấm "Xuất báo cáo" | không đổi số liệu; dựng bytes rồi mở bảng chia sẻ | Không |
| Back rồi mở lại màn | về **mặc định kế thừa kỳ đang xem** (bộ lọc cũ mất) | Có (lần mở mới) |
| Giao dịch thêm/sửa/xoá ở nơi khác **trong lúc màn đang mở** | **không** đổi (không cập nhật đẩy — kế thừa PBI 22/26) | Không |

---

## 5. Truy vết FR → luật

| FR | Luật |
|---|---|
| FR-001, FR-002 | điểm vào + khung màn (plan §Giai đoạn 1, không phải luật dữ liệu) |
| FR-003, FR-004 | 4, 5 |
| FR-005, FR-006, FR-007 | 1, 2, 3, 6, 7, 8, 9, 10 |
| FR-008 | 1, 2, 3 |
| FR-009, FR-010 | 1.1, 1.4, 26–29 |
| FR-011, FR-023, FR-025 | 34, 35 |
| FR-012, FR-013, FR-014 | 17, 26, 27, 28 |
| FR-015 | 11, 12, 13 |
| FR-016 | 14, 15, 16 |
| FR-017, FR-018 | 30, 31 |
| FR-019 | 19, 20, 21 |
| FR-020 | 18 (định dạng ngày/số **không** đổi theo ngôn ngữ) |
| FR-021, FR-022 | dùng token màu + `ListView` cuộn được (plan §Giai đoạn 1) |
| FR-024 | 21, 22, 24, 25 |
| FR-026 | 33 + bảng §4 |
| FR-027 | 32 + bảng §4 |
| FR-028 | 36 |
| SC-003, SC-004 | 11, 12, 14, 15 — số dòng tệp = `count`; tổng hợp không lệch màn 01 |
| SC-010, SC-013 | 6, 12 — không lọt giao dịch ngoài bộ lọc |
