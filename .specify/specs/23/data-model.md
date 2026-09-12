# Mô hình dữ liệu: Chi tiết theo danh mục (màn 02 Báo cáo)

**Mã PBI**: 23
**Liên kết spec**: [spec.md](./spec.md) · **Kế hoạch**: [plan.md](./plan.md)
**Ngày tạo**: 2026-09-12

PBI này **không đổi schema drift** (giữ **v7**) và không thêm bảng/cột. Mọi thứ dưới đây là **thực thể logic** dựng trong RAM bằng hàm thuần, cạnh các thực thể đã có ở `core/report/report_view.dart` (PBI 22).

---

## 1. Thực thể mới

### 1.1 `ReportCategoryRow` — một dòng danh mục (và một lát cắt) của màn 02

| Thuộc tính | Kiểu | Ý nghĩa |
|---|---|---|
| `categoryId` | `int?` | id danh mục **cha**; `null` = dòng gộp **"Khác"** |
| `name` | `String` | Tên hiển thị (tên danh mục cha, hoặc `'Khác'.tr`) |
| `amount` | `int` | Tiền chi của nhóm trong kỳ (> 0) |
| `percent` | `int` | % trên tổng chi, **đã chia để tổng mọi dòng = 100** |
| `rank` | `int` | `0…n-1` = hạng (chọn `chartPalette[rank % 5]`); `-1` = "Khác" (`chartPalette[5]`) |

Không mang `icon`/`color` của danh mục: màn 02 cố ý dùng **màu theo thứ hạng** (FR-007), khác bubble thẻ top màn 01 (giả định đã chốt của spec).

### 1.2 `ReportCategoryDetail` — kết quả dựng màn 02 (bất biến)

| Thuộc tính | Kiểu | Ý nghĩa |
|---|---|---|
| `period` | `ReportPeriod` | Loại kỳ kế thừa từ màn 01 |
| `range` | `DateRange` | Khoảng **nửa mở** `[start, end)` của kỳ đang xem |
| `total` | `int` | Tổng **chi** của kỳ = Σ `rows[i].amount` (0 = không có chi tiêu) |
| `hasAnyTxn` | `bool` | Kỳ có ít nhất 1 giao dịch **Thu/Chi** (transfer/adjustment không tính) |
| `rows` | `List<ReportCategoryRow>` | **Toàn bộ** danh mục chi của kỳ, sắp giảm dần, + "Khác" cuối; rỗng khi `total == 0` |

Suy ra (getter, không lưu): `isEmpty => total == 0`.

### 1.3 Hàm dựng

```dart
ReportCategoryDetail reportCategoryDetail({
  required List<Transaction> transactions,
  required List<Category> categories,
  required ReportPeriod period,
  required DateTime now,
});

String reportPeriodChipLabel(ReportPeriod period, DateRange range); // "Tháng 9/2026"
String reportExpenseCenterLabel(ReportPeriod period);               // "Tổng chi tháng"
```

Nguồn số liệu: **đúng** hàm `_breakdown` mà `reportBreakdown`/`reportTopCategories` (màn 01) đang dùng, chỉ khác ở chỗ lấy toàn bộ nhóm thay vì `.take(5)`.

---

## 2. Luật bất biến (kiểm bằng test)

| # | Luật | Nguồn |
|---|---|---|
| 1 | Chỉ giao dịch `type == expense` được tính; `income`, `transfer`, `adjustment` bị loại khỏi mọi con số | FR-013/014, SC-005 |
| 2 | Giao dịch vào kỳ theo **ngày giao dịch**, khoảng `[start, end)` **bao gồm cả ngày đầu và ngày cuối** | FR-016 |
| 3 | Giao dịch có ngày **tương lai** nhưng nằm trong kỳ vẫn được tính | biên spec |
| 4 | Tiền chi của **danh mục con** gộp vào **danh mục cha** (cây 2 cấp); không có chế độ xem tách con | FR-009 |
| 5 | Danh mục **bị ẩn** vẫn được tính và hiển thị tên bình thường | biên spec |
| 6 | Danh mục con trỏ tới cha **không còn tồn tại** → nhóm theo chính nó (không dồn vào "Khác") | biên spec |
| 7 | Giao dịch `categoryId == null` **không** khớp danh mục nào → dồn vào **"Khác"** | FR-010 |
| 8 | Dòng "Khác" **chỉ** chứa phần tiền chi không gắn danh mục; **không** nuốt phần ngoài top 5 (khác màn 01) | FR-010 (chốt 2026-09-12) |
| 9 | "Khác" luôn **xếp cuối** danh sách, kể cả khi số tiền lớn hơn một danh mục thật | FR-010, mockup 02 |
| 10 | Sắp xếp **giảm dần theo số tiền**; **đồng hạng → tên tăng dần** theo thứ tự chữ Việt (bỏ dấu) ⇒ mở lại màn không đổi chỗ | biên spec, FR-006 |
| 11 | `Σ rows[i].percent == 100`; `Σ rows[i].amount == total`; % tính trên tổng chi của kỳ, chia theo **phần dư lớn nhất** (`percentSplit`) | FR-008, SC-004 |
| 12 | Kỳ chỉ có **1 danh mục** → 1 dòng `100%`, vòng tròn một màu khép kín (không coi là lỗi) | biên spec |
| 13 | `rank` = chỉ số sau khi sắp xếp; màu = `chartPalette[rank % 5]`; "Khác" = `chartPalette[5]` ⇒ **lặp chu kỳ** khi > 5 danh mục, **không** dùng coral, **không** dùng `Category.color` | FR-007, SC-007/SC-014 |
| 14 | **Mọi** danh mục có chi tiêu đều có dòng riêng và lát cắt riêng — không cắt ở 5, không gộp | FR-006, SC-014 |
| 15 | `hasAnyTxn == false` (kỳ rỗng **hoặc** chỉ transfer) → `total == 0` | FR-013 |
| 16 | `total == 0` ⇒ `rows` rỗng ⇒ màn hiện trạng thái rỗng toàn màn, **không** vẽ vòng tròn/tiêu đề nhóm | FR-013/FR-014, SC-010 |
| 17 | Chip kỳ và nhãn giữa vòng tròn dẫn xuất **từ `period` + `range`** của kỳ đang xem (không có trạng thái kỳ riêng ở màn 02) | FR-003/FR-004, FR-017 |
| 18 | Dòng "Khác" **không** tạo bộ lọc khi chạm (không danh mục để lọc) | FR-012 |
| 19 | Số liệu dựng lại **mỗi lần build** từ bản chụp RAM; không lưu cache, không cập nhật đẩy | FR-015, giả định spec |

---

## 3. Vòng đời dữ liệu — khi nào số liệu đổi

| Sự kiện | Bản chụp RAM (ReportController) | Màn 02 đang mở |
|---|---|---|
| Chọn tab Báo cáo ở shell | nạp lại (PBI 22 R1) | — (màn 02 đã đóng) |
| Lưu giao dịch qua FAB khi đang ở tab Báo cáo | nạp lại (PBI 22 R11) | — (FAB không hiện trên màn 02) |
| Chạm "Xem tất cả" | giữ nguyên | dựng `ReportCategoryDetail` mới từ bản chụp |
| Đổi kỳ ở màn 01 | dựng lại `data` | — (màn 02 không đổi kỳ được) |
| Chạm một dòng danh mục ở màn 02 | giữ nguyên | `popUntil` về shell + đổi tab Giao dịch |
| Đứng trong màn 02, dữ liệu đổi ở nơi khác | **không** nạp lại | **không** tự đổi số (kế thừa hành vi PBI 22) |

---

## 4. Ánh xạ sang UI (màn 02)

| Thành phần mockup | Nguồn dữ liệu |
|---|---|
| App bar teal + back + "Chi tiêu theo danh mục" | hằng + khóa dịch |
| Chip kỳ (`Tháng 9/2026`) | `reportPeriodChipLabel(detail.period, detail.range)` — nhãn tĩnh |
| Vòng tròn + nhãn giữa | `detail.rows` (giá trị = `amount`, màu theo `rank`) + `reportExpenseCenterLabel` + `formatMoney(detail.total)` |
| Tiêu đề nhóm `DANH MỤC (n)` | `n = detail.rows.length` |
| Dòng danh mục | `detail.rows[i]`: chấm màu (`rank`), tên, `formatMoney(amount)`, `percent%`, thanh tiến độ `percent/100` |
| Dòng gợi ý cuối màn | khóa dịch, chữ tĩnh |
| Trạng thái rỗng | `detail.total == 0` + `detail.hasAnyTxn` |
