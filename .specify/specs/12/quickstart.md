# Kịch bản khởi động nhanh — PBI 12: Tìm kiếm & lọc giao dịch

Ngày: 2026-09-05

## Chuẩn bị dữ liệu mẫu

App tự seed lần đầu (onCreate, schema v4): 5 ví mẫu + bảng danh mục mặc định + 11 giao dịch mẫu. Ngày dòng mẫu **tương đối so với giờ chạy** (cách nay 0/1/2/3/5 ngày) — nên QA vào **đầu tháng** (hoặc tự so khớp số với danh sách, không tin con số tuyệt đối) vì mặc định màn lọc = "Tháng này" chỉ tính giao dịch trong tháng hiện tại.

Vài dòng mẫu dùng cho QA: chi **"Ăn uống −85.000 đ"** ghi chú **"Ăn trưa"** (hôm nay); thu **Lương +12.000.000 đ**; chuyển khoản **Vietcombank → Momo 700.000 đ** (gộp 1 dòng).

## Cách chạy

```bash
cd app/sora_thu_chi
flutter pub get
flutter analyze        # phải sạch
flutter test           # toàn bộ (gồm transaction_filter / search_filter_screen mới)
flutter run            # chọn Android emulator
```

PBI 12 **không đổi schema** → không cần `build_runner`. App khởi động → mở khóa PIN (PBI 3) → tab **Giao dịch** → chạm **icon lọc** (góc phải header) để mở màn "Tìm kiếm & Lọc".

## Nhóm QA

### A. Mở màn lọc — bố cục & mặc định (acceptance 1, FR-001/017, SC-009/011)
Tab Giao dịch → chạm icon lọc → màn con toàn màn hình (**không** bottom nav): app bar teal, **back** trái, **ô tìm kiếm pill** trắng (kính lúp + placeholder "Tìm kiếm giao dịch..."); chip **"Tất cả"** đang chọn (teal), Thu/Chi/Chuyển khoản trắng viền; nhãn **"BỘ LỌC NÂNG CAO"**; dòng **Khoảng thời gian** hiển thị tháng hiện tại (VD `01/09/2026 - 30/09/2026`); **Ví** = "Tất cả các ví"; **Sắp xếp theo** = "Ngày mới nhất"; chân màn nút **Đặt lại** (trắng viền) + **Áp dụng** (teal). Đối chiếu `05-tim-kiem-loc.svg`.

### B. Tìm kiếm tức thời + bỏ dấu (acceptance 2, FR-002/003, SC-003/004)
Gõ **"ăn trưa"** → dòng tóm tắt `N kết quả · Tổng: X đ` cập nhật **khi gõ** (không cần nút) chỉ sau ~250ms, không treo. Thử **"an uong"** không dấu → vẫn tìm thấy giao dịch "Ăn uống" (bỏ dấu). Xóa hết từ khóa → tóm tắt về theo chip/range hiện tại.

### C. Chip loại + kết hợp AND (acceptance 3, FR-004/010, SC-002)
Chọn chip **Chi** + **Khoảng số tiền Từ `0` Đến `100.000`** + gõ **"ăn"** → tóm tắt chỉ tính giao dịch **đồng thời** đủ: loại chi, `abs` tiền trong 0–100.000 đ, khớp từ khóa. Đối chiếu thủ công từng tiêu chí và theo tổ hợp (không thừa/thiếu). Chuyển về chip "Tất cả" → mở rộng lại. Chip **Chuyển khoản** → chọn **Toàn bộ** thời gian để thấy dòng transfer; dòng Danh mục bị vô hiệu (transfer không danh mục).

### D. Khoảng thời gian preset & tùy chỉnh (FR-005, SC-005)
Chạm dòng Khoảng thời gian → sheet **Hôm nay / Tuần này / Tháng này / Toàn bộ / Tùy chọn…**. Chọn "Hôm nay" → chỉ còn giao dịch hôm nay; "Tháng này" (mặc định) → cả tháng hiện tại; "Toàn bộ" → không giới hạn (thấy đủ 11 dòng mẫu trải vài ngày); "Tùy chọn…" → 2 date picker; picker **không cho** chọn ngày bắt đầu sau ngày kết thúc.

### E. Danh mục chọn nhiều — cha gộp con (acceptance 9, FR-006, SC-008)
Chọn chip **Chi** → chạm **"+ Thêm"** dòng Danh mục → sheet danh mục **chỉ chi** (không thấy Lương/Thưởng). Chọn **Ăn uống** (cha) → chip "Ăn uống" hiện trên dòng; Áp dụng → danh sách gồm cả giao dịch các con (Cà phê/Ăn ngoài/Đi chợ) nếu có. Chọn đơn **con** (VD Cà phê) → chỉ đúng con đó. Đổi chip sang **Thu** → danh sách chọn đổi sang danh mục thu; chip **Chuyển khoản** → dòng Danh mục vô hiệu & bỏ chọn cũ. X trên chip → bỏ một mục.

### F. Ví (FR-007)
Dòng Ví mặc định "Tất cả các ví". Chọn **Vietcombank** → Áp dụng → danh sách chỉ giao dịch ví đó, khoản chuyển Vietcombank→Momo vẫn hiện **1 dòng** trung tính (gộp cả 2 vế). Sheet có dòng "Tất cả các ví" trở lại; ví đã ẩn nếu có vẫn chọn được (có nhãn "(đã ẩn)") để xem lịch sử.

### G. Khoảng số tiền — trống biên & min > max (FR-008)
Chạm ô "Từ" → sheet numpad nhập số; để **trống một đầu** (bỏ giới hạn đầu đó). Nhập min `100.000` max `50.000` → dòng báo lỗi đỏ "Số tiền tối thiểu không được lớn hơn tối đa" và **nút Áp dụng bị vô hiệu** (không trả kết quả sai).

### H. Áp dụng → danh sách lọc; chỉ báo; Bỏ lọc; sắp xếp (acceptance 5–8, FR-012/013/014/015/016)
1. Đặt Chi + danh mục Ăn uống + khoảng tiền 0–1.000.000 + từ khóa, chạm **Áp dụng** → về màn Giao dịch: **card "Thu/Chi tháng này" ẩn**, thay bằng thanh chỉ báo lọc `N kết quả · Tổng: X đ` + **"Bỏ lọc"**; danh sách chỉ còn tập khớp, dòng giữ nguyên cấu trúc/màu, cuộn được, chạm dòng vẫn mở chi tiết, FAB "+" vẫn ghi giao dịch mới (xong → quay về, tập lọc làm mới).
2. Đổi **Sắp xếp theo = Số tiền giảm dần** → Áp dụng → danh sách **phẳng** (không header ngày) xếp khoản tiền lớn trước. Chọn **Ngày cũ nhất** → nhóm ngày cũ nhất lên đầu.
3. Chạm **"Bỏ lọc"** → về toàn bộ (card tháng hiện lại).
4. Rời tab sang màn khác rồi quay lại tab Giao dịch → bộ lọc **còn nguyên** (SC-007). Mở lại màn lọc → hiện đúng điều kiện đang áp dụng.
5. Mở màn lọc, thay đổi rồi **back không Áp dụng** → danh sách giữ nguyên tập cũ.
6. **"Đặt lại"** → mọi điều kiện về mặc định (từ khóa trống, chip Tất cả, Tháng này, Ví tất cả, tiền trống, Ngày mới nhất).
7. Đặt lọc khiến **0 kết quả** → màn lọc "0 kết quả"; sau Áp dụng danh sách trống hiện "Không có giao dịch khớp bộ lọc." + hint Bỏ lọc — không báo lỗi.

### I. Cỡ chữ lớn & vùng an toàn (acceptance 10, FR-017, SC-011)
Bật cỡ chữ lớn nhất (cài đặt hệ thống) hoặc màn hình notch → mở màn lọc: app bar, ô tìm, chip, từng dòng, tóm tắt, hai nút Đặt lại/Áp dụng hiển thị đầy đủ, cuộn được, nút chân không bị cắt.
