# Kịch bản khởi động nhanh: Màn hình chi tiết ví

**Mã PBI**: 6

Chạy app (`flutter run` trong `app/sora_thu_chi/`), chọn Android emulator. Vào **Cài đặt → Quản lý ví** (PBI 5) để có màn danh sách ví, rồi chạm từng ví.

Bộ mẫu (khớp `WalletSource` PBI 5 + `TransactionSource` PBI 6):

| Ví | Số dư hiển thị | Giao dịch mẫu |
|---|---|---|
| Tiền mặt (id 1, mặc định) | 3.200.000 đ | 1–2 khoản chi |
| **Vietcombank** (id 2) | **14.800.000 đ** | 3 thu + 2 chi + 1 chuyển khoản đi (màu/ngày đủ dạng) |
| Thẻ tín dụng VIB (id 3) | Đã dùng 6.500.000 / 20.000.000 đ — 32% | 1–2 khoản chi |
| Momo (id 4) | 1.450.000 đ | 1 dòng chuyển khoản **đến** (vế đích) |
| Sổ tiết kiệm (id 5, **đã ẩn**) | 9.000.000 đ | **rỗng** → empty state |

## Nhóm QA đối chiếu tiêu chí

**A. Mở & hero đúng ví — SC-001/002/003/004, FR-002/003/004**
- Từ danh sách, chạm hàng **Vietcombank** → màn chi tiết mở ≤ 1 chạm. App bar teal: nút back + tên "Vietcombank"; không có bottom nav.
- Vùng teal hero: tròn icon ví, số dư **trắng cỡ lớn "14.800.000 đ"** khớp 100% con số ở hàng danh sách, dòng phụ "Tài khoản ngân hàng".
- Đối chiếu thủ công SC-003: `nền 1.200.000 + Σ signed(3 thu 2 chi 1 chuyển) = 14.800.000` — con số hero khớp phép cộng/trừ tay trên các dòng giao dịch bên dưới. *(Số nền chính xác chốt theo bộ mẫu khi thi công; ghi tại `data-model.md`/tasks.)*

**B. Dòng giao dịch — màu, dấu, định dạng, thứ tự — SC-003/004, FR-008/009/010**
- Nhóm "GIAO DỊCH GẦN ĐÂY" chỉ liệt kê giao dịch **Vietcombank**, ngày mới nhất lên đầu.
- Thu: số **teal dấu `+`**, mũi tên lên teal trên tròn teal nhạt. Chi: số **coral dấu `-`**, mũi tên xuống coral trên tròn coral nhạt.
- Một dòng chi có ghi chú (VD "Siêu thị Coopmart") → tiêu đề là ghi chú; dòng phụ `Ăn uống · Hôm nay` (danh mục · ngày thân thiện); số tiền **căn phải**, phân tách nghìn `.` + `đ`, không làm tròn sai.
- Dòng chuyển khoản đi: màu **trung tính** `-1.000.000 đ`, không lẫn thu/chi. Đủ dạng nhãn ngày: "Hôm nay" / "Hôm qua" / "dd/MM".

**C. Thẻ tín dụng — FR-005**
- Mở **Thẻ tín dụng VIB** → hero hiển thị dạng sử dụng: "Đã dùng 6.500.000 / 20.000.000 đ" + phần trăm 32% — **không** hiển thị số dư dương. Các dòng chi dùng thẻ liệt kê bình thường.

**D. Ví ẩn & empty state — SC-006, edge "ví ẩn", FR-012**
- Từ danh sách chạm **Sổ tiết kiệm** (mờ, "(đã ẩn)") → vẫn mở được, hero đầy đủ, nhóm giao dịch hiện empty state rõ ràng ("Chưa có giao dịch nào.") không lỗi không vỡ.

**E. Hành động nhanh & dòng giao dịch treo — SC-005/008, FR-006/007/011**
- Trên Vietcombank, chạm lần lượt **Chuyển tiền / Sửa ví / Ẩn ví** và từng dòng giao dịch → không mở màn nào, không lỗi (bấm liên tục cũng không).
- Màn **chỉ xem**: không thao tác nào làm đổi dữ liệu ví/giao dịch.

**F. Back & trạng thái danh sách — SC-001, acceptance 9**
- Chạm back (app bar hoặc phím hệ thống) → trở về danh sách ví **đúng vị trí cuộn/trạng thái như lúc rời đi**.

**G. Khóa PIN — FR-016**
- Đưa app xuống nền rồi mở lại (đang mở khóa PIN) → màn chi tiết chỉ thấy sau khi mở khóa; không lộ nội dung qua màn hình khóa.

**H. Cỡ chữ lớn & vùng an toàn — SC-007, FR-014/015**
- Bật cỡ chữ lớn nhất của hệ thống (hoặc fontScale trong emulator) + mở Vietcombank → mọi thành phần (hero, 3 nút, nhóm giao dịch) hiển thị đủ, không tràn/vỡ; cuộn mượt. (Trên thiết bị có notch/xoay ngang xem nhanh không vỡ.)

> Ghi chú: các trường hợp **số dư âm / giao dịch rất nhiều** không tạo được bằng tay ở đợt này (chưa có luồng ghi) → phủ bằng widget test (xem `tasks.md`). "Nền 1.200.000" là số quy ước cho việc đối chiếu thủ công, không hiển thị trên app.
