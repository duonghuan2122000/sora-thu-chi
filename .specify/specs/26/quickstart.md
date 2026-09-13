# Khởi động nhanh & kiểm thử tay: So sánh kỳ (màn 03 Báo cáo)

**Mã PBI**: 26
**Liên kết**: [spec.md](./spec.md) · [plan.md](./plan.md) · [data-model.md](./data-model.md) · [research.md](./research.md)
**Ngày tạo**: 2026-09-13

---

## 1. Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get
flutter analyze          # phải sạch
flutter test             # mốc trước PBI: 835 pass + 1 test đỏ CÓ SẴN (xem §5)
flutter run              # chọn emulator/máy thật
```

**Dữ liệu mẫu để QA tay** (tạo trong app, đủ để so sánh "Tháng 9/2026 vs Tháng 8/2026"):

| Kỳ | Thu | Chi | Ghi chú |
|---|---|---|---|
| Tháng 9/2026 | 18.500.000 đ | 12.300.000 đ | chi Ăn uống tăng mạnh so với T8 |
| Tháng 8/2026 | 17.100.000 đ | 10.700.000 đ | |
| Tháng 9/2025 | 15.000.000 đ | 9.000.000 đ | cho nhóm F (cùng kỳ năm trước) |

Thêm nữa: **1 cặp chuyển khoản nội bộ** trong T9 (VD 5.000.000 đ ví A → ví B) và
**1 giao dịch điều chỉnh số dư** trong T9 — cả hai **phải không xuất hiện** ở bất
kỳ con số nào của màn 03.

Đặt đồng hồ máy/emulator về **tháng 9/2026** trước khi QA (màn lấy "hôm nay" từ
giờ hệ thống).

---

## 2. Kịch bản kiểm thử tay

### Nhóm A — Điểm vào & trạng thái vô hiệu hoá (FR-001, FR-017, SC-002)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| A1 | Mở tab **Báo cáo**, kỳ Tháng | Cùng hàng tiêu đề "Báo cáo" có **biểu tượng so sánh** bên phải, nút tròn 48 px màu trắng |
| A2 | Chạm biểu tượng **1 lần** | Màn **So sánh kỳ** mở ra: app bar teal + nút back + tiêu đề "So sánh kỳ"; **không** có bottom nav, **không** có FAB |
| A3 | Chạm **back** | Về màn Tổng quan Báo cáo, kỳ vẫn là **Tháng** như trước (FR-020) |
| A4 | Xoá sạch giao dịch thu/chi (hoặc cài app mới, chưa nhập gì), mở tab Báo cáo | Biểu tượng so sánh **mờ đi**; chạm vào hiện `SnackBar` giải thích, **không** mở màn |
| A5 | Nhập 1 giao dịch chi ở **tháng 7/2026** (trước kỳ đang xem), đang xem tháng 9 | Biểu tượng **sáng lại**, chạm mở được màn 03 (đã có dữ liệu ở kỳ trước đó — FR-017 chỉ chặn trường hợp **chưa từng** có) |

### Nhóm B — Bố cục & nội dung theo mockup `03` (FR-002…FR-004, FR-007, FR-008, SC-001)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| B1 | Đối chiếu `docs/report/man-hinh-03-so-sanh-ky.svg` | Đủ 5 khối đúng thứ tự: **cặp chip + nút hoán đổi** → thẻ **Thu nhập** → thẻ **Chi tiêu** → thẻ **Xu hướng chi tiêu theo ngày** → thẻ **Nhận xét** |
| B2 | Xem cặp chip | Trái `Tháng 9/2026` **nền teal chữ trắng**; giữa là **nút hoán đổi** (icon hai mũi tên); phải `Tháng 8/2026` **nền nhạt chữ xám** |
| B3 | Chạm chip **trái** | **Không** có phản hồi (nhãn tĩnh — FR-005) |
| B4 | Xem chip **phải** | Có **chỉ báo thị giác** cho biết bấm được (khác biệt cố ý với mockup — FR-005) |
| B5 | Xem thẻ Thu nhập | Badge `▲ 8%` **teal** ở góc phải hàng tiêu đề; **hai cột** cạnh nhau (cột T8 nhạt–thấp, cột T9 teal–cao); hai dòng số `T8: 17.100.000 đ` (mờ) / `T9: 18.500.000 đ` (đậm) |
| B6 | Xem thẻ Chi tiêu | Badge `▲ 15%` **coral**; cột T9 **coral**; hai dòng số `T8: 10.700.000 đ` / `T9: 12.300.000 đ` |
| B7 | Xem thẻ Nhận xét | Nền **cam rất nhạt**, icon cảnh báo **coral**, tiêu đề "Nhận xét" đậm + câu nhận xét |
| B8 | Xem thẻ xu hướng | Tiêu đề "Xu hướng chi tiêu theo ngày"; **chú giải 2 mục** khớp nhãn hai chip; trục hoành đánh số ngày `1 … 30` (không phải ngày dương lịch) |

### Nhóm C — Số liệu & màu badge (FR-009, FR-010, SC-003, SC-005)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| C1 | Cộng tay từ sổ giao dịch tháng 9 và tháng 8 | Hai dòng số mỗi thẻ khớp **0 đ**; % badge khớp chênh lệch thật (sai số ≤ 1 điểm % do làm tròn) |
| C2 | Đo chiều cao hai cột mỗi thẻ | Tỉ lệ đúng với hai số tiền (cột lớn hơn = 64 px) |
| C3 | Xem badge Thu | Thu **tăng** ⇒ **teal** (tốt) |
| C4 | Xem badge Chi | Chi **tăng** ⇒ **coral** (xấu) |
| C5 | Sửa dữ liệu để Thu **giảm** so với kỳ trước | Badge `▼` **coral** (xấu) |
| C6 | Sửa dữ liệu để Chi **giảm** | Badge `▼` **teal** (tốt) |
| C7 | Làm hai kỳ **bằng nhau** (cùng số chi) | Badge `0%`, **không** mũi tên, **không** tô teal/coral (FR-010) |

### Nhóm D — Kỳ đối chiếu rỗng / cả hai rỗng (FR-011, FR-016, FR-017, SC-006, SC-012)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| D1 | Đang xem tháng 9 (có dữ liệu), xoá hết giao dịch **tháng 8** | Màn **vẫn mở được**; thẻ số liệu **không** hiện badge `%`, thay bằng ghi chú "Kỳ đối chiếu không có dữ liệu để so sánh"; cột kỳ đối chiếu cao **0** |
| D2 | Kiểm tra chuỗi ký tự | **Không** có `NaN`, `∞`, `-∞`, `▲ 0%`, `▼ 0%` hay `%` vô nghĩa |
| D3 | Chỉ để lại **1 giao dịch chuyển khoản nội bộ** trong tháng 8, xoá hết thu/chi tháng 8 | Tháng 8 được coi là **kỳ rỗng** (transfer không phải thu/chi) ⇒ xử như D1 |
| D4 | Xoá hết giao dịch của **cả** tháng 9 và tháng 8 (chỉ còn transfer) | Màn hiện **trạng thái rỗng** "Chưa có giao dịch nào trong hai kỳ này"; **không** vẽ cột 0, biểu đồ rỗng hay thẻ Nhận xét rỗng; **vẫn** thấy cặp chip + nút hoán đổi |
| D5 | Từ D4 chạm chip kỳ đối chiếu sang "cùng kỳ năm trước" (T9/2025 có dữ liệu) | Cặp kỳ mới có dữ liệu ⇒ màn vẽ đầy đủ trở lại (đường thoát khỏi trạng thái rỗng) |
| D6 | Đang xem một kỳ **chỉ có Thu** (không có chi) cả hai vế | Thẻ Thu nhập có badge bình thường; thẻ Chi tiêu hiện ghi chú; thẻ xu hướng hiện ghi chú thay vì hai đường phẳng 0 (không có "hai đường 0" gây hiểu lầm) |

### Nhóm E — Nút hoán đổi (FR-006, SC-007)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| E1 | Chạm nút hoán đổi | Chip **đổi chỗ**: trái thành `Tháng 8/2026` (teal), phải thành `Tháng 9/2026` (nhạt) |
| E2 | Xem lại hai thẻ số liệu | Cặp cột, hai dòng số, badge % và **màu cột** cập nhật theo chiều mới (kỳ **trái** là kỳ chính) |
| E3 | Xem biểu đồ + chú giải + câu Nhận xét | Đường **liền teal** giờ là đường của T8, đường **đứt xám** là T9; chú giải khớp; câu Nhận xét đổi chiều và **đổi chữ** sang "kỳ sau" (không còn "kỳ trước") |
| E4 | Chạm nút hoán đổi **lần hai** | Màn về **đúng** trạng thái ban đầu: mọi con số và màu badge trùng khớp (SC-007) |
| E5 | Hoán đổi, rồi chạm chip kỳ đối chiếu | Kỳ đối chiếu tính lại theo **kỳ chính đang ở bên trái**; kỳ chính không đổi |

### Nhóm F — Chip kỳ đối chiếu: cùng kỳ năm trước (FR-005, SC-016)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| F1 | Ở trạng thái mặc định (T9/2026 vs T8/2026), chạm chip **phải** | Chip phải đổi thành `Tháng 9/2025`; **mọi** số liệu (cặp cột, hai dòng số, badge %, hai đường biểu đồ, chú giải, câu Nhận xét) cập nhật theo cặp mới |
| F2 | Xem chip **trái** và kỳ màn 01 | Không đổi (FR-005/FR-020, KB-21) |
| F3 | Chạm chip phải **lần nữa** | Quay về `Tháng 8/2026` với số liệu trùng khớp trạng thái ban đầu |
| F4 | Lặp F1–F3 với kỳ **Ngày**, **Tuần**, **Năm** | Mỗi loại ra đúng kỳ tương ứng (hôm trước/năm trước, tuần trước/năm trước cùng tuần Thứ Hai, tháng/năm, năm/năm trước) — SC-016 |

### Nhóm G — Biểu đồ xu hướng theo ngày (FR-012, SC-009)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| G1 | Xem biểu đồ khi so **tháng 9 (30 ngày)** với **tháng 8 (31 ngày)** | Trục hoành chạy `1 … 31`; đường tháng 9 **dừng ở ngày 30**, **không** kéo dài giả sang ngày 31 |
| G2 | So **tháng 2/2026 (28 ngày)** với **tháng 1/2026 (31 ngày)** | Trục `1 … 31`; đường tháng 2 dừng ở ngày 28 |
| G3 | So **tháng 2/2024 (nhuận, 29 ngày)** với **tháng 1/2024** | Đường tháng 2 có **29** điểm (không phải 28, không phải 30) |
| G4 | Kiểm 1 ngày bất kỳ có nhiều giao dịch chi | Điểm trên đường = **tổng chi của riêng ngày đó**, không phải luỹ kế (so với cộng tay) |
| G5 | Đổi kỳ chính sang **Ngày** | Biểu đồ vẫn vẽ được (mỗi kỳ 1 điểm) |

### Nhóm H — Câu Nhận xét (FR-013, FR-014, SC-008)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| H1 | Chi T9 > T8, có danh mục tăng | Câu nêu **chiều + %** và **tên danh mục cha tăng mạnh nhất** (VD "Bạn chi nhiều hơn kỳ trước 15%. Chủ yếu do danh mục Ăn uống tăng mạnh.") |
| H2 | Chi T9 < T8 | Câu nêu chiều "chi ít hơn" + %; nếu vẫn có danh mục tăng thì nêu tên |
| H3 | Tăng chi **rải đều** nhiều danh mục | Câu chỉ nêu %, **không** nêu tên danh mục nào sai lệch |
| H4 | Toàn bộ tiền chi **không gắn danh mục** | Câu chỉ nêu %, không nêu danh mục |
| H5 | Danh mục tăng mạnh nhất là **danh mục con** (VD "Cà phê" thuộc "Ăn uống") | Câu nêu tên **danh mục cha** ("Ăn uống"), không nêu tên con |
| H6 | **Ẩn** danh mục đang tăng mạnh nhất (màn Danh mục → ẩn) rồi mở lại màn 03 | Danh mục đó **vẫn được nêu tên** (FR-014) |
| H7 | Kỳ đối chiếu **không có chi tiêu**, kỳ chính có | Câu nêu **số tiền chi của kỳ chính** + "kỳ đối chiếu chưa có chi tiêu để so sánh"; **không** hiện % (FR-013) |
| H8 | Cả hai kỳ đều không có chi tiêu (nhưng có Thu) | Câu là biến thể "Hai kỳ đều chưa có chi tiêu." — không hiện `%` vô nghĩa |
| H9 | Hai kỳ chi **bằng nhau** | Câu "Bạn chi tiêu bằng kỳ trước." (không hiện `0%` khô khan) |

### Nhóm I — Loại giao dịch bị loại khỏi mọi con số (FR-015, SC-004)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| I1 | Thêm 1 cặp chuyển khoản nội bộ (5.000.000 đ) trong T9 | **Không** con số nào của màn đổi: hai dòng số, cặp cột, badge %, hai đường biểu đồ, câu Nhận xét |
| I2 | Thêm 1 giao dịch **điều chỉnh số dư** trong T9 | Như I1 — không đổi con số nào |
| I3 | Kỳ chỉ toàn chuyển khoản + điều chỉnh | Kỳ đó coi là **kỳ rỗng** ⇒ xử theo nhóm D (D1/D4) |
| I4 | Cộng tay sổ giao dịch (đã loại transfer/adjustment) | Khớp **0 đ** với mọi con số trên màn (SC-003/SC-004) |

### Nhóm J — Bốn loại kỳ & biên lịch (FR-018, SC-009)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| J1 | Ở màn 01 chọn **Tuần** → mở màn 03 | Hai kỳ là **hai tuần liền kề**, mỗi tuần **bắt đầu Thứ Hai**; cách ghi mốc kỳ giống màn Chi tiết theo danh mục (`Tuần 07/09–13/09/2026`) |
| J2 | Màn 01 chọn **Ngày** → mở màn 03 | Kỳ đối chiếu là **ngày hôm trước** |
| J3 | Màn 01 chọn **Năm** → mở màn 03 | Kỳ đối chiếu là **năm trước** |
| J4 | Đứng ở mùng 1 của một tháng → xem kỳ "Tháng" | Kỳ chính là **tháng hiện tại**, kỳ đối chiếu là **tháng trước** (không dùng "30 ngày trước") |
| J5 | Giao dịch có **ngày tương lai** nhưng thuộc kỳ đang xem | Vẫn được tính (kế thừa PBI 22) |

### Nhóm K — Vòng đời & cập nhật dữ liệu (FR-019, FR-020, SC-011)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| K1 | Mở màn 03 → back → thêm 1 giao dịch chi lớn → quay lại tab Báo cáo → mở màn 03 | Số liệu **đã cập nhật** theo dữ liệu mới ngay lần mở đó |
| K2 | Mở màn 03 → back → mở lại | Kỳ chính = **kỳ đang chọn của màn 01**; kỳ đối chiếu về **liền trước** (chế độ mặc định, không nhớ lần trước) |
| K3 | Ở màn 03 hoán đổi sang chế độ "cùng kỳ năm trước" rồi back, mở lại | Về đúng mặc định "kỳ liền trước" |
| K4 | Đổi kỳ ở màn 01 sang Năm rồi mở màn 03 | Kỳ chính là **năm** đang chọn (không phải tháng cũ) |

### Nhóm L — Chế độ Tối (FR-022, SC-014)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| L1 | Cài đặt → Giao diện → **Tối** → mở màn 03 | Nền, chữ, app bar, hai cột, thẻ Nhận xét, đường phân cách đúng bộ màu tối |
| L2 | Chụp màn hình, đo tương phản | Mọi chữ/số đạt ngưỡng đọc được — **kể cả đường nét đứt xám của kỳ đối chiếu** trên nền tối |
| L3 | Đổi sang **Theo hệ thống**, đổi theme máy | Màn đổi theo ngay, không cần mở lại |

### Nhóm M — English (FR-021, SC-013)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| M1 | Cài đặt → Ngôn ngữ → **English** → mở màn 03 | Tiêu đề app bar, nhãn chip, tiêu đề 3 thẻ + "Nhận xét", chú giải, **câu nhận xét tự động**, ghi chú không có dữ liệu, thông điệp rỗng — **hết tiếng Việt** |
| M2 | Chuyển sang chế độ cùng kỳ năm trước, đổi chiều tăng/giảm | Câu tiếng Anh vẫn đúng ngữ pháp với `@ref` (previous period / following period) và `@percent` |
| M3 | Xem số tiền | Vẫn định dạng phân tách nghìn + đơn vị tiền tệ (không dịch `đ`) |

### Nhóm N — Bố cục & dữ liệu cực trị (FR-023, SC-015)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| N1 | Cỡ chữ **lớn nhất** + màn hình nhỏ | Chip kỳ **không tràn** ra ngoài; không cắt chữ; cuộn tới được **thẻ Nhận xét** (thẻ cuối) |
| N2 | Số tiền **hàng tỉ** (VD `12.345.678.900 đ`) | Hai dòng số và nhãn cột không tràn khỏi dòng/cột; badge % vẫn hiện đủ |
| N3 | Tên danh mục **rất dài** trong câu Nhận xét | Câu xuống dòng gọn, không đẩy tràn màn hình |
| N4 | Chú giải với nhãn Tuần dài (`Tuần 07/09–13/09/2026` × 2) | Chú giải xuống dòng gọn, không cắt chữ |
| N5 | Xoay ngang / tablet (nếu có) | Bố cục không vỡ; nội dung cuộn được |

### Nhóm O — Hiệu năng (SC-010)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| O1 | Nhập/thêm dữ liệu **vài năm** giao dịch (hoặc restore file backup lớn) | Mở màn 03 hiển thị nội dung **dưới 1 giây** |
| O2 | Chuyển kỳ chính sang **Năm** (trục 365 ngày) | Vẫn mở dưới 1 giây, biểu đồ vẽ trôi chảy khi cuộn |

---

## 3. Kiểm thử tự động

```bash
flutter test test/report_view_test.dart                  # hàm thuần mới (%, màu badge, chuỗi ngày, chọn danh mục, câu Nhận xét)
flutter test test/report_screen_test.dart                # điểm vào + trạng thái vô hiệu hoá
flutter test test/report_comparison_screen_test.dart     # file MỚI — màn 03
flutter test test/report_controller_test.dart            # seam controller (comparison/hasAnyTxnBefore)
flutter test                                             # toàn bộ
flutter analyze
```

---

## 4. Đối chiếu truy vết (tóm tắt)

| Nhóm | Phủ yêu cầu | Phủ tiêu chí |
|---|---|---|
| A | FR-001, FR-017, FR-020 | SC-002 |
| B | FR-002…FR-004, FR-007, FR-008 | SC-001 |
| C | FR-009, FR-010 | SC-003, SC-005 |
| D | FR-011, FR-016, FR-017 | SC-006, SC-012 |
| E | FR-006 | SC-007 |
| F | FR-005 | SC-016 |
| G | FR-012, FR-018 | SC-009 |
| H | FR-013, FR-014 | SC-008 |
| I | FR-015 | SC-004 |
| J | FR-003, FR-018 | SC-009 |
| K | FR-019, FR-020 | SC-011 |
| L | FR-022 | SC-014 |
| M | FR-021 | SC-013 |
| N | FR-023 | SC-015 |
| O | — | SC-010 |

---

## 5. Ghi chú

- **Test đỏ có sẵn**: `test/transactions_dao_test.dart` → "Transactions drift —
  schema v4: categories seed + category_id (PBI 11, R1/R2/R4) …" **đỏ từ trước
  PBI 26** (mốc baseline: **835 pass / 1 fail**). PBI này **không** sửa test đó —
  chỉ cần **không làm tăng** số test đỏ.
- **iOS chưa QA** ở các PBI trước (PBI 25); PBI này không đụng native nên chỉ QA
  Android là đủ, ghi rõ nếu bỏ qua iOS.
