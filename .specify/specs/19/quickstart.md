# Kịch bản kiểm thử nhanh: PBI 19 — Chọn ngôn ngữ hiển thị

**Ngày tạo**: 2026-09-10
**Liên kết**: [spec.md](./spec.md) · [plan.md](./plan.md)

Dành cho người kiểm thử tay trên emulator/thiết bị thật. Chạy từ `app/sora_thu_chi/`.

## 0. Chuẩn bị

```bash
flutter pub get
flutter analyze          # phải sạch
flutter test             # toàn bộ test phải xanh
flutter run              # chọn emulator/thiết bị
```

Nên chạy trên **DB đã có dữ liệu** (mở app, để seed 5 ví + 11 giao dịch mẫu có sẵn) để kiểm được mục G/H.
Kịch bản này không cần PIN; nếu máy đang bật khóa app, mở khóa trước.

---

## A. Vào màn `03` từ màn Tiện ích (FR-001, SC-001)

1. Cài đặt → **Tiện ích & Cá nhân hóa**.
2. Chạm hàng **Ngôn ngữ**.
3. ✅ Mở màn con "Ngôn ngữ": app bar thương hiệu teal có nút back, tiêu đề `Ngôn ngữ`, **không** có thanh điều hướng đáy. Mở trong ≤ 1 giây.

## B. Bố cục đúng mockup `docs/tool/03-ngon-ngu.svg` (FR-002, SC-002)

1. Đặt màn `03` cạnh ảnh `docs/tool/03-ngon-ngu.svg`.
2. ✅ Đúng **2 hàng theo thứ tự** Tiếng Việt → English.
3. ✅ Mỗi hàng: vòng tròn trái chứa mã `VI`/`EN` (hàng đang chọn: chữ trắng trên nền teal; hàng kia: chữ xám trên nền nhạt) → tên đậm → dòng phụ xám → radio phải.
4. ✅ Nội dung: `Tiếng Việt` / `Vietnamese` và `English` / `Tiếng Anh`.
5. ✅ Cuối màn có ghi chú 2 dòng về áp dụng ngay + định dạng ngày/số giữ theo "Định dạng & Tiền tệ".

## C. Mặc định Tiếng Việt (FR-003, FR-004, SC-003)

Trên máy **chưa từng đổi ngôn ngữ** (hoặc xoá dữ liệu app rồi cài lại):

1. Mở màn `03`.
2. ✅ Radio **Tiếng Việt** đã chọn sẵn (chấm teal), radio English trống.
3. ✅ Không có 2 hàng cùng chọn.

## D. Đổi sang English — đổi ngay, không khởi động lại (FR-005, SC-004)

1. Đang đứng ở màn `03` (giao diện tiếng Việt), chạm hàng **English**.
2. ✅ Ngay trong lần chạm đó: radio chuyển sang English, radio Tiếng Việt bỏ chọn.
3. ✅ **Đồng thời** tiêu đề app bar của chính màn đang mở đổi thành `Language`, ghi chú cuối màn đổi sang tiếng Anh — không cần thoát app.
4. ✅ Nhấn back về màn Tiện ích: tiêu đề app bar, 3 nhãn nhóm (`DISPLAY` / `EXPERIENCE` / `DATA & SEARCH`), tên hàng và dòng phụ của **toàn bộ 8 hàng** đều tiếng Anh.
5. ✅ Về Cài đặt → thanh điều hướng đáy 4 nhãn đổi: `Overview` / `Transactions` / `Reports` / `Settings`.

## E. Hàng "Ngôn ngữ" màn `01` phản ánh lựa chọn (FR-007)

1. Sau bước D, nhìn hàng **Ngôn ngữ** ở màn Tiện ích.
2. ✅ Phần cuối hàng hiển thị `English` (không còn cố định `Tiếng Việt`).
3. Vào lại màn `03`, chạm `Tiếng Việt` → quay lại màn `01`.
4. ✅ Phần cuối hàng hiển thị lại `Tiếng Việt`; tên hàng trở lại `Ngôn ngữ`.

## F. Nhớ lựa chọn qua lần mở app (FR-006, SC-005)

1. Chọn `English`, thoát màn `03` về Tiện ích.
2. **Tắt hẳn app** (vuốt khỏi đa nhiệm), mở lại.
3. ✅ Ngay màn đầu (Tổng quan) đã là tiếng Anh; nhãn điều hướng đáy tiếng Anh.
4. ✅ Vào Tiện ích → hàng Ngôn ngữ hiện `English`; vào màn `03` → radio `English` đang chọn.
5. Lặp lại bước 2 một lần nữa → kết quả không đổi (giữ đúng qua nhiều lần).

## G. Danh mục mặc định dịch, danh mục của người dùng thì không (FR-009, FR-010, SC-007)

Ở chế độ **English**:

1. Mở **Danh mục**.
2. ✅ 8 cha chi + 4 cha thu hiển thị tiếng Anh (`Food & Drink`, `Transport`, `Housing`, `Bills`, `Shopping`, `Entertainment`, `Health`, `Education`, `Salary`, `Bonus`, `Investment`, `Other`); 3 con của Ăn uống cũng tiếng Anh.
3. Vào màn danh mục con của một cha → tên con tiếng Anh.
4. Mở **Giao dịch**: dòng giao dịch mẫu (seed) hiển thị tên danh mục tiếng Anh.
5. Tạo một danh mục mới tên `Trà sữa` → ✅ ở chế độ English vẫn hiện `Trà sữa` (không bị dịch).
6. Đổi tên một danh mục mặc định (VD `Ăn uống` → `Ăn ngoài cùng team`) → ✅ giữ nguyên tên mới ở cả hai chế độ; đổi ngôn ngữ qua lại **không** khôi phục lại tên mặc định và **không** làm mất tên đã đặt.

## H. Dữ liệu người dùng & định dạng không đổi (FR-010, FR-011, SC-008)

Ở chế độ **English**:

1. ✅ Tên ví vẫn như cũ: `Tiền mặt`, `Vietcombank`, `Thẻ tín dụng VIB`, `Momo`, `Sổ tiết kiệm` (chốt: ví là dữ liệu, không dịch).
2. ✅ Tên giao dịch tự nhập, ghi chú, tag hiển thị nguyên văn như đã nhập.
3. ✅ Số tiền vẫn `42.500.000 đ` (dấu chấm nghìn, đơn vị `đ` sau) — không thành `42,500,000` hay `₫`.
4. ✅ Ngày vẫn `dd/MM/yyyy` (`Hôm nay`/`Hôm qua` đổi thành `Today`/`Yesterday` — phần chữ dịch, phần ngày không đổi).
5. Đổi ngược về Tiếng Việt → ✅ không dòng dữ liệu nào bị đổi/mất.

## I. Độc lập với giao diện sáng/tối (FR-012, SC-009)

1. Chọn ngôn ngữ `English`, vào **Giao diện**, chọn `Dark`.
2. Thoát hẳn app, mở lại.
3. ✅ Giao diện tối **và** ngôn ngữ English đều được giữ.
4. Đổi ngôn ngữ về Tiếng Việt → ✅ giao diện vẫn `Tối`; giá trị hàng Giao diện hiển thị `Tối` (dịch đúng theo ngôn ngữ mới). Đổi theme lại → ngôn ngữ vẫn giữ.

## J. Bố cục với cỡ chữ lớn (FR-013, SC-010)

1. Bật cỡ chữ lớn nhất của hệ điều hành (Android: Cài đặt → Hiển thị → Cỡ chữ; iOS: Cỡ chữ lớn hơn). Nên thử cả trên màn hình nhỏ (~5 inch) nếu có.
2. Mở màn `03` ở chế độ English: ✅ đủ vòng tròn `VI`/`EN` + tên + dòng phụ + radio, không cắt chữ, không tràn ngang, cuộn tới được ghi chú cuối màn.
3. Đi qua các màn có nhãn tiếng Anh dài (Tiện ích, Giao dịch, form ví, form danh mục, bộ lọc): ✅ không vỡ bố cục, không cắt cụt giữa từ, không đẩy tràn ra ngoài màn.

## K. Quét sạch nhãn tĩnh tiếng Việt ở chế độ English (SC-006)

Ở chế độ **English**, lần lượt mở và cuộn hết từng màn — **không** còn nhãn giao diện tĩnh nào tiếng Việt (ngoại lệ hợp lệ: dữ liệu người dùng tự nhập, tên riêng/thương hiệu, tên ví mẫu, và 4 chuỗi cố định trên 2 hàng màn `03`):

- [ ] Cài đặt (danh sách mục) — Tiện ích & Cá nhân hóa — Giao diện — Ngôn ngữ
- [ ] Tổng quan (khung) — Báo cáo (khung)
- [ ] Ví: danh sách, chi tiết, form thêm/sửa, chuyển tiền (kể cả dialog/hộp thoại xác nhận)
- [ ] Giao dịch: danh sách, thêm giao dịch (nhãn trường, nút), chi tiết, tìm kiếm & lọc (chip, khoảng ngày, trạng thái rỗng)
- [ ] Danh mục: danh sách, thêm/sửa, danh mục con, sắp xếp, chọn danh mục
- [ ] Màn khóa app: đặt PIN, nhập PIN, thông báo sai mã / tạm khoá

## L. Trường hợp biên

1. Mở màn `03`, **không chạm gì**, nhấn back → ✅ về màn Tiện ích bình thường, không cảnh báo, ngôn ngữ không đổi.
2. Chạm nhanh liên tiếp `English` → `Tiếng Việt` → `English` → ✅ trạng thái cuối đúng lần chạm cuối, radio không nhảy loạn; thoát hẳn app mở lại → đúng ngôn ngữ của lần chạm cuối.
3. Chọn ngôn ngữ mới rồi **tắt hẳn app ngay** (chưa rời màn) → mở lại ✅ vẫn ở ngôn ngữ vừa chọn.
4. Đang bật khóa PIN → mở lại app ✅ màn khoá hiển thị đúng ngôn ngữ đã chọn; nội dung yêu cầu mở khoá hiểu được ở cả hai ngôn ngữ.
5. Chạm chính hàng đang chọn → ✅ không đổi gì (no-op), không ghi lại lung tung.

## Ghi nhận kết quả

Đối chiếu lại: A–F ⇒ FR-001…FR-007; G–H ⇒ FR-009…FR-011; I ⇒ FR-012; J ⇒ FR-013; K ⇒ SC-006; L ⇒ trường hợp biên.
