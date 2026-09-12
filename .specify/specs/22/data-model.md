# Mô hình dữ liệu: PBI 22 — Báo cáo tổng quan

**Mã PBI**: 22 · **Ngày**: 2026-09-12 · **Liên kết**: [spec.md](./spec.md) · [plan.md](./plan.md)

> **Không có thay đổi schema.** Màn Báo cáo tổng quan **chỉ đọc**: bảng
> `transactions` + bảng `categories` (schema **v7** giữ nguyên — v7 từ PBI 21).
> Mọi thực thể dưới đây là **đại lượng tính toán trong RAM** (giả định spec: không
> bảng tổng hợp, không cache — kế thừa PBI 20/21).

---

## 1. Kỳ báo cáo (`ReportPeriod` + `DateRange`)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `period` | `ReportPeriod` | `day` / `week` / `month` / `year` — lựa chọn trên segmented control (FR-002) |
| `anchor` | `DateTime` | mốc "hôm nay" của lần nạp (bơm được để test) |
| `range` | `DateRange` | kỳ **đang chọn** chứa `anchor`, nửa mở `[start, end)` |
| `series` | `List<DateRange>` | **6** kỳ liên tiếp kết thúc ở `range` (phần tử cuối = kỳ đang chọn) |

Đơn vị thời gian (FR-021, mốc **dương lịch**):

| `ReportPeriod` | `start` | `end` (độc quyền) |
|---|---|---|
| `day` | `00:00` ngày `anchor` | `+1 ngày` |
| `week` | **Thứ Hai** của tuần chứa `anchor` | `+7 ngày` |
| `month` | mùng 1 tháng của `anchor` | mùng 1 tháng sau |
| `year` | `1/1` năm của `anchor` | `1/1` năm sau |

**Luật**
1. Khoảng là **nửa mở**: `contains(m) = !m.isBefore(start) && m.isBefore(end)` ⇒
   giao dịch đúng ngày đầu/cuối kỳ đều thuộc kỳ; không giao dịch nào thuộc 2 kỳ
   liền kề (FR-021, biên spec).
2. Tuần bắt đầu **Thứ Hai**, kết thúc Chủ Nhật (kế thừa `resolveDatePreset`).
3. Không có kỳ tài chính lệch ngày (ngoài phạm vi).
4. `series` luôn đủ **6** phần tử kể cả khi các kỳ trước chưa có dữ liệu; kỳ đang
   chọn luôn là phần tử **cuối** (FR-006).
5. Bước lùi giữa các kỳ là **1 đơn vị lịch** (1 ngày / 7 ngày / 1 tháng / 1 năm),
   giải bằng số học ngày (không cộng `Duration` cho tháng/năm).

---

## 2. Thẻ "Dòng tiền 6 <đơn vị> gần đây" (`ReportBar`)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `range` | `DateRange` | kỳ của cột (1 trong 6) |
| `label` | `String` | nhãn trục: `dd/MM` (Ngày, Tuần) · `T@tháng` (Tháng) · `@năm` (Năm) |
| `income` | `int ≥ 0` | tổng tiền giao dịch **Thu** trong `range` |
| `expense` | `int ≥ 0` | tổng tiền giao dịch **Chi** trong `range` (giá trị tuyệt đối) |
| `isCurrent` | `bool` | `true` với phần tử cuối — nhãn đậm hơn |

**Luật**

6. `income`/`expense` tính theo **tổng của kỳ đang chọn** (2 số tổng khu đầu màn) và
   **cùng một phép lọc** dùng cho 6 cột — một nguồn duy nhất, không lệch số (SC-003).
7. Giao dịch **chuyển khoản nội bộ** (`TxnType.transfer`) và **điều chỉnh số dư**
   (`adjustment`) **bị loại** khỏi mọi con số (FR-004, SC-004).
8. `amount` trong DB **có dấu**: Thu `+`, Chi `−` ⇒ `income` cộng `+amount`,
   `expense` cộng `−amount` của giao dịch Chi.
9. Đơn vị **không có giao dịch** vẫn có mặt với `income = expense = 0` (FR-006).
10. Giao dịch có **ngày tương lai** nhưng nằm trong `range` vẫn được tính (FR-022).

---

## 3. Thẻ "Phân bổ chi tiêu theo danh mục" (`ReportSlice`)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `categoryId` | `int?` | id **danh mục cha** của nhóm; `null` = nhóm **"Khác"** |
| `name` | `String` | tên danh mục cha (`'Khác'.tr` cho nhóm gộp) |
| `icon` / `color` | `String` / `int` | icon + màu danh mục (để dòng chú giải có chấm/nhãn nếu cần) |
| `rank` | `int` | 0…4 = hạng; `-1` = "Khác" → chọn màu `chartPalette[rank]` (Khác ⇒ chỉ số 5) |
| `amount` | `int > 0` | tổng tiền **Chi** của nhóm trong kỳ |
| `percent` | `int` | % trên tổng chi, **đã chia để tổng = 100** |

**Luật**

11. Nguồn: giao dịch **Chi** trong `range`. Thu/transfer/adjustment **không** vào
    (FR-008, SC-004).
12. **Gộp theo danh mục cha** (FR-010): khóa nhóm = `category.parentId ?? category.id`;
    tiền của mọi danh mục con tính vào cha; tên/icon/màu lấy từ **cha**.
13. Nhóm gồm **tối đa 5 danh mục chi nhiều nhất**, phần còn lại gộp **"Khác"**;
    **"Khác"** cũng nhận phần tiền chi có `categoryId == null` (FR-009, biên spec).
14. **"Khác" chỉ xuất hiện khi** có phần dư: > 5 danh mục, **hoặc** có tiền chi
    không gắn danh mục. Kỳ có ≤ 5 danh mục và không có tiền trống danh mục ⇒ **không**
    có "Khác"; các lát chiếm trọn 100%.
15. "Khác" luôn xếp **cuối** danh sách; các nhóm còn lại sắp **giảm dần theo `amount`**,
    đồng hạng → **tên tăng dần** (thứ tự ổn định — biên spec).
16. `Σ amount` các lát **= tổng chi của kỳ** (`ReportView.expense`) và `Σ percent = 100`
    khi `expense > 0` (FR-009/SC-005). Chia % theo **phần dư lớn nhất** (R5).
17. Danh mục **ẩn** vẫn được tính và hiện tên bình thường (nguyên tắc xuyên module).
18. Con trỏ tới cha **không còn tồn tại** ⇒ nhóm theo chính con đó (không vào "Khác");
    `category` rỗng/không khớp thì dựa hoàn toàn vào `categoryId`.
19. Kỳ **không có giao dịch Chi** ⇒ danh sách rỗng (thẻ hiện trạng thái rỗng —
    FR-015).

---

## 4. Thẻ "Top danh mục chi tiêu" (`ReportTopCategory`)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `categoryId` | `int` | id danh mục **cha** |
| `name` / `icon` / `color` | `String`/`String`/`int` | hiển thị bubble icon + tên |
| `amount` | `int > 0` | tiền Chi của nhóm trong kỳ |
| `percent` | `double` | `amount / expense × 100` — bề rộng thanh tiến độ |

**Luật**

20. **Tối đa 5** dòng (FR-013) — **không** có dòng "Khác" (khác vòng tròn: top là
    danh sách danh mục thật).
21. Cùng nguồn nhóm với [ReportSlice] (luật 12–15) ⇒ số tiền top khớp số tiền lát
    cắt cùng danh mục.
22. `percent` không cần cộng đúng 100 (chỉ là tỉ lệ trên tổng chi để vẽ thanh).

---

## 5. `ReportView` — kết quả dựng màn (bất biến)

| Trường | Kiểu | Ghi chú |
|---|---|---|
| `period` | `ReportPeriod` | kỳ đang chọn |
| `range` | `DateRange` | khoảng ngày của kỳ đang chọn (dùng cho drill-down, FR-012) |
| `income` / `expense` | `int` | 2 số tổng khu đầu màn |
| `bars` | `List<ReportBar>` | đúng 6 phần tử |
| `slices` | `List<ReportSlice>` | 0…6 phần tử |
| `top` | `List<ReportTopCategory>` | 0…5 phần tử |

**Cờ trạng thái (suy ra, luật 23–25)**

23. `hasAnyTxn = income > 0 || expense > 0` — xét **trong `range` của kỳ đang chọn**,
    không xét cả cửa sổ 6 đơn vị (R10). `false` ⇒ cả 3 thẻ hiện trạng thái rỗng
    "Chưa có giao dịch nào trong kỳ này" (FR-014/SC-009).
24. `hasExpense = expense > 0` — `false` (kỳ chỉ có Thu) ⇒ **chỉ** thẻ phân bổ + thẻ
    top rỗng, biểu đồ vẫn vẽ đủ 6 cột (FR-015).
25. Kỳ chỉ có chuyển khoản nội bộ ⇒ `hasAnyTxn = false` (transfer không là thu/chi —
    biên spec).

**Vòng đời (bất biến dữ liệu)**

| Sự kiện | Kết quả |
|---|---|
| Mở/kéo lại tab Báo cáo | `ReportController.load()` — đọc lại `transactions` + `categories`, dựng lại `ReportView` (FR-016) |
| Đổi lựa chọn kỳ | Dựng lại `ReportView` từ dữ liệu **đã nạp trong RAM**, **không** đọc DB (SC-007) |
| Ghi giao dịch qua FAB khi đang ở tab Báo cáo | Nạp lại (R11) |
| Sửa/xóa giao dịch ở màn Giao dịch rồi quay lại tab | Nạp lại theo lần chọn tab (kịch bản 12, FR-016) |
| Không có mạng | Không ảnh hưởng — toàn bộ số liệu tính từ dữ liệu trên thiết bị |

---

## 6. Thực thể **không** thuộc PBI này

- **Bộ lọc báo cáo nâng cao** (khoảng ngày tuỳ chỉnh, ví, danh mục, tag) — PBI sau;
  đợt này kỳ chỉ đến từ segmented control 4 lựa chọn (FR-002).
- **Bảng tổng hợp / cache số liệu** (`report_monthly_summary`) — ngoài phạm vi;
  sẽ cân nhắc nếu đo thấy chậm (SC-007 đặt ngưỡng < 1 giây).
- **Đa tiền tệ / quy đổi tỷ giá**, **kỳ tài chính lệch ngày**, **toggle xem theo
  danh mục con**, **xuất PDF/Excel/CSV**, **so sánh kỳ**, **xu hướng (line)** — ngoài phạm vi.
