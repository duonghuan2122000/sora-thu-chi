# GIẢI PHÁP NGHIỆP VỤ: BÁO CÁO & THỐNG KÊ (REPORTS & ANALYTICS)

> Chi tiết hoá mục "8. Báo cáo & Thống kê" trong tài liệu tính năng nghiệp vụ, kèm thiết kế màn hình theo Design System hiện có (Material, teal `#0F6E56`, coral `#D85A30`).

---

## 1. Mục tiêu & phạm vi

Module Báo cáo giúp người dùng **hiểu được bức tranh tài chính cá nhân** mà không cần tự cộng trừ thủ công: biết mình thu/chi bao nhiêu, tiền đi đâu (danh mục nào), xu hướng đang tốt lên hay xấu đi, và có thể xuất dữ liệu ra ngoài khi cần (kế toán, chia sẻ, lưu trữ).

Phạm vi (bám theo mục 8 của tài liệu nghiệp vụ):
1. Tổng quan thu/chi theo ngày/tuần/tháng/năm
2. Phân bổ chi tiêu theo danh mục (pie chart)
3. So sánh thu chi giữa các kỳ
4. Xu hướng chi tiêu theo thời gian
5. Top danh mục chi tiêu nhiều nhất
6. Báo cáo dòng tiền theo từng ví
7. Xuất báo cáo PDF/Excel/CSV
8. Bộ lọc báo cáo (thời gian, ví, danh mục, tag)

---

## 2. Mô hình dữ liệu phục vụ báo cáo

### 2.1. Nguồn dữ liệu (từ các module đã có)
- `Transaction`: amount, type (income/expense/transfer), categoryId, walletId, date, tags, currency
- `Wallet`: id, name, currency, isDefault
- `Category`: id, name, parentId, color, icon
- `Tag`: id, name

### 2.2. Nguyên tắc tính toán
- **Loại trừ Transfer**: giao dịch chuyển khoản nội bộ giữa các ví **không** được tính vào Thu hoặc Chi, chỉ xuất hiện trong "Báo cáo dòng tiền theo ví" như dòng chuyển đi/chuyển đến.
- **Đa tiền tệ**: nếu ví có tiền tệ khác tiền tệ mặc định, quy đổi theo tỷ giá tại **thời điểm giao dịch** (lưu snapshot tỷ giá ngay lúc tạo giao dịch) để báo cáo lịch sử không bị lệch khi tỷ giá thay đổi sau này. Báo cáo hiển thị ghi chú nhỏ "*Đã quy đổi theo tỷ giá tại thời điểm giao dịch*" nếu có ví ngoại tệ.
- **Bảng tổng hợp (aggregate cache)**: với `drift`, tạo thêm 1 bảng `report_monthly_summary (year, month, categoryId, walletId, totalIncome, totalExpense)` được cập nhật (upsert) mỗi khi có giao dịch thêm/sửa/xóa trong tháng tương ứng, thay vì quét lại toàn bộ bảng `transactions` mỗi lần mở màn Báo cáo. Giúp báo cáo mở tức thời kể cả khi dữ liệu nhiều năm.
- **Kỳ tài chính tuỳ chỉnh**: nếu người dùng đặt "đầu tháng tài chính" khác ngày 1 (mục 12 tài liệu nghiệp vụ), toàn bộ truy vấn theo "tháng" trong report phải dùng mốc này thay vì ngày dương lịch 1–31.

---

## 3. Chi tiết các loại báo cáo

### 3.1. Tổng quan thu/chi theo kỳ
- **Input**: kỳ đang chọn (Ngày/Tuần/Tháng/Năm) qua segmented control.
- **Hiển thị**: 2 số tổng (Tổng thu, Tổng chi) + biểu đồ cột ghép đôi (grouped bar) — mỗi nhóm là 1 đơn vị thời gian con (VD: chọn "Tháng" → 6 tháng gần nhất, mỗi tháng 2 cột thu/chi).
- **Tương tác**: chạm vào 1 cột → tooltip hiện số tiền chính xác; chạm giữ để kéo xem nhiều kỳ hơn (infinite scroll trái/phải).

### 3.2. Phân bổ chi tiêu theo danh mục
- **Hiển thị**: donut chart + danh sách chú thích (màu, tên, %, số tiền), sắp xếp giảm dần theo số tiền.
- **Drill-down**: chạm vào 1 lát cắt hoặc 1 dòng danh mục → điều hướng sang danh sách giao dịch đã lọc theo danh mục đó trong đúng khoảng thời gian đang xem.
- **Danh mục cha-con**: mặc định gộp theo danh mục cha; có toggle "Xem theo danh mục con" để tách nhỏ (VD: Ăn uống → Cà phê / Ăn ngoài / Đi chợ).

### 3.3. So sánh giữa các kỳ
- **Cách chọn**: 2 chip kỳ (kỳ hiện tại vs kỳ liền trước, hoặc cùng kỳ năm trước) + nút hoán đổi.
- **Hiển thị**: cột so sánh song song cho Thu và cho Chi, kèm badge % chênh lệch (▲ tăng dùng coral nếu là chi tiêu tăng — xấu; ▼ giảm dùng teal — tốt. Với Thu thì ngược lại: tăng = tốt = teal).
- **Insight tự động**: câu tóm tắt dạng ngôn ngữ tự nhiên, tái sử dụng cho cả thông báo cuối tuần/cuối tháng ở mục 9 (VD: "Bạn chi nhiều hơn kỳ trước 15%").

### 3.4. Xu hướng chi tiêu theo thời gian
- **Hiển thị**: line chart chi tiêu theo từng kỳ nhỏ (ngày trong tháng / tháng trong năm), có thể bật thêm đường trung bình động (moving average) để làm mượt biến động.
- Dùng chung vùng biểu đồ với 3.1 nhưng chuyển sang chế độ "line" khi người dùng chọn tab phụ "Xu hướng".

### 3.5. Top danh mục chi tiêu nhiều nhất
- Danh sách rút gọn (3–5 dòng) đặt ngay dưới donut chart ở màn Tổng quan, mỗi dòng: icon danh mục, tên, số tiền, thanh progress % trên tổng chi kỳ đó.
- Có nút "Xem tất cả" → mở màn **Chi tiết theo danh mục** (liệt kê đầy đủ, không giới hạn 5 dòng).

### 3.6. Báo cáo dòng tiền theo từng ví
- Bảng/danh sách: mỗi ví 1 dòng gồm số dư đầu kỳ, tổng thu, tổng chi, chuyển vào, chuyển ra, số dư cuối kỳ.
- Hữu ích để đối chiếu vì đây là nơi duy nhất hiển thị dòng "chuyển khoản nội bộ" (transfer) vốn bị loại khỏi thu/chi.

### 3.7. Xuất báo cáo (PDF / Excel / CSV)
Xem chi tiết ở mục 6.

### 3.8. Bộ lọc báo cáo
Áp dụng xuyên suốt mọi màn hình con: khoảng thời gian tuỳ chỉnh, ví (multi-select), danh mục (multi-select), tag. Bộ lọc được lưu tạm trong session để khi chuyển qua lại giữa các tab báo cáo không bị mất lựa chọn.

---

## 4. Luồng người dùng (User Flow)

```
[Tab "Báo cáo"] 
   │
   ├─ chọn kỳ (Ngày/Tuần/Tháng/Năm) ──> cập nhật toàn bộ chart trên màn Tổng quan
   │
   ├─ chạm donut chart / "Xem tất cả" ──> [Màn Chi tiết theo danh mục]
   │        └─ chạm 1 danh mục ──> [Danh sách giao dịch đã lọc theo danh mục]
   │
   ├─ chạm icon So sánh (app bar) ──> [Màn So sánh kỳ]
   │
   └─ chạm icon Xuất báo cáo (app bar) ──> [Màn Xuất báo cáo]
            └─ chọn bộ lọc + định dạng ──> Xuất file ──> Share sheet hệ thống
```

---

## 5. Danh sách màn hình thiết kế

| # | Tên màn hình | Loại | File thiết kế |
|---|---|---|---|
| 1 | Tổng quan Báo cáo (tab chính) | Màn hình chính, có bottom nav | `man-hinh-01-bao-cao-tong-quan.svg` |
| 2 | Chi tiết theo Danh mục | Sub-page, app bar teal + back | `man-hinh-02-chi-tiet-danh-muc.svg` |
| 3 | So sánh Kỳ | Sub-page, app bar teal + back | `man-hinh-03-so-sanh-ky.svg` |
| 4 | Xuất Báo cáo | Sub-page, app bar teal + back | `man-hinh-04-xuat-bao-cao.svg` |

Cả 4 màn đều tuân thủ Design System đã có: bo góc card `10px`, teal `#0F6E56` cho hành động/trạng thái chọn, coral `#D85A30` **chỉ** dùng cho cảnh báo/chi tiêu tăng — không dùng làm màu trang trí cho biểu đồ danh mục (biểu đồ phân bổ dùng bộ màu định tính riêng: teal, teal đậm nhạt, hổ phách, xanh lam nhạt, xám — để tránh xung đột ngữ nghĩa với quy tắc "coral = cảnh báo chi tiêu" trong Design System).

---

## 6. Thư viện & Component đề xuất (Flutter)

| Nhu cầu | Package | Ghi chú |
|---|---|---|
| Bar chart (thu/chi theo kỳ, so sánh) | `fl_chart` → `BarChart` + `BarChartGroupData` | Mỗi kỳ 1 group, 2 `BarChartRodData` (teal/coral) |
| Line chart (xu hướng) | `fl_chart` → `LineChart` | `LineChartBarData` + `dashArray` cho đường trung bình động hoặc đường kỳ trước khi so sánh |
| Donut/Pie chart (phân bổ danh mục) | `fl_chart` → `PieChart` + `PieChartSectionData` | `centerSpaceRadius` để tạo khoảng trắng giữa hiển thị tổng tiền |
| Định dạng số tiền | `intl` (`NumberFormat`) | Theo chuẩn `42.500.000 đ` đã quy định trong Design System |
| Xuất PDF | `pdf` + `printing` | Chụp biểu đồ qua `RepaintBoundary.toImage()` rồi nhúng ảnh vào PDF cùng bảng số liệu |
| Xuất Excel | `excel` (hoặc `syncfusion_flutter_xlsio` nếu cần định dạng nâng cao) | Xuất bảng giao dịch chi tiết + sheet tổng hợp |
| Xuất CSV | `csv` | Xuất raw list giao dịch theo bộ lọc |
| Chia sẻ file sau khi xuất | `share_plus` | Mở share sheet hệ thống |
| Tính toán nặng không chặn UI | `compute()` / Isolate | Dùng khi tổng hợp nhiều năm dữ liệu hoặc so sánh nhiều kỳ cùng lúc |

---

## 7. Hiệu năng

- Luôn đọc từ bảng tổng hợp `report_monthly_summary` thay vì bảng `transactions` thô khi hiển thị biểu đồ theo tháng/năm; chỉ query trực tiếp `transactions` khi người dùng chọn kỳ "Ngày" (khoảng dữ liệu nhỏ) hoặc khi cần drill-down vào từng giao dịch.
- Cache kết quả donut chart theo `(kỳ, walletFilter, categoryFilter)` trong bộ nhớ (không cần lưu DB) để chuyển tab qua lại mượt.
- Debounce việc tính lại báo cáo khi người dùng thay đổi bộ lọc liên tục (300ms).

---

## 8. Trường hợp biên (Edge cases)

- **Không có giao dịch trong kỳ**: hiện empty state (icon + text "Chưa có giao dịch nào trong kỳ này") thay vì chart rỗng gây hiểu lầm lỗi.
- **Kỳ đầu tiên dùng app**: không có kỳ trước để so sánh → vô hiệu hoá (disable) icon So sánh kèm tooltip giải thích, thay vì cho vào màn so sánh rồi hiện số 0 gây hiểu lầm.
- **Trộn nhiều tiền tệ trong cùng kỳ**: quy đổi về tiền tệ mặc định của người dùng, hiển thị ghi chú tỷ giá đã dùng như ghi ở mục 2.2.
- **Chế độ ẩn số dư (Privacy mode)**: khi bật, mọi số tiền trong toàn bộ màn Báo cáo (kể cả trong PDF/Excel xuất ra) hiển thị dạng `••••••• đ`; **riêng file xuất** nên cảnh báo rõ cho người dùng trước khi xuất vì file ra ngoài app không còn bị Privacy mode bảo vệ.
- **Xuất báo cáo với bộ lọc rỗng kết quả**: chặn nút "Xuất báo cáo", hiện thông báo thay vì tạo file trống.

---

## 9. Gợi ý phân kỳ triển khai

| Giai đoạn | Việc cần làm |
|---|---|
| MVP báo cáo | Màn Tổng quan (bar chart thu/chi theo tháng, donut chart danh mục, top 5 danh mục) |
| Giai đoạn 2 | Xuất Excel/PDF/CSV, bộ lọc nâng cao (ví/tag) |
| Giai đoạn 3 | So sánh kỳ, xu hướng (trend + moving average), báo cáo dòng tiền theo ví, insight tự động |

Thứ tự này khớp với bảng phân kỳ MVP → Nâng cao đã có trong tài liệu tính năng nghiệp vụ tổng thể.
