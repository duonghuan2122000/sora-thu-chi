# Khởi động nhanh & kiểm thử tay: Xuất báo cáo (màn 04 Báo cáo)

**Mã PBI**: 27
**Liên kết**: [spec.md](./spec.md) · [plan.md](./plan.md) · [data-model.md](./data-model.md) · [research.md](./research.md)
**Ngày tạo**: 2026-09-13

---

## 1. Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get            # 3 dependency mới (pdf, excel_community, share_plus) + assets/fonts
flutter analyze            # phải sạch
flutter test               # mốc trước PBI: 883 pass + 1 test đỏ CÓ SẴN (xem §5)
flutter run                # chọn emulator/máy thật
```

**Dữ liệu mẫu để QA tay** (nhập trong app):

| Thứ cần có | Giá trị gợi ý | Dùng cho nhóm |
|---|---|---|
| ≥ **4 ví** (VD Tiền mặt, Vietcombank, Momo, Sổ tiết kiệm) | — | D (chọn nhiều ví) |
| ≥ **5 danh mục cha** đang hoạt động (VD Ăn uống, Nhà ở, Đi lại, Mua sắm, Sức khỏe) + 1 danh mục **con** (Cà phê ∈ Ăn uống) | — | E (chip "+N khác", cha→con) |
| Giao dịch **tháng 9/2026** ở **nhiều ví**, có **tag** (VD `dulich`, `congviec`) | ~20 dòng | A, B, C, D, E, F, G |
| **1 cặp chuyển khoản nội bộ** trong T9 (5.000.000 đ ví A → ví B) | — | J |
| **1 giao dịch điều chỉnh số dư** trong T9 | — | J |
| 1 giao dịch **danh mục con** (Cà phê) | 45.000 đ | E, J |
| Giao dịch ở **tháng 8/2026** và **tháng 10/2026** | vài dòng | C (biên ngày) |
| 1 giao dịch có **ghi chú chứa dấu `,` `"` và xuống dòng** | — | I |

Đặt đồng hồ emulator về **tháng 9/2026** trước khi QA (màn lấy kỳ đang xem từ
màn 01, mà màn 01 lấy "hôm nay" từ giờ hệ thống).

> **Lệch có lý do so với FR-012** (research R10): PDF chứa **biểu đồ vẽ lại** từ
> đúng dữ liệu của màn 01 (cột Thu/Chi + thanh ngang phân bổ) chứ **không phải ảnh
> chụp** hai biểu đồ của màn 01 — dạng donut không vẽ được bằng widget của `pdf`.
> Nhóm H kiểm **sự có mặt + số liệu khớp**, không kiểm dạng biểu đồ. Muốn đúng
> "ảnh" thì nói trước khi thi công (research R10 ghi phương án thay thế).

---

## 2. Kịch bản kiểm thử tay

### Nhóm A — Điểm vào & khung màn (FR-001, FR-002, SC-002)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| A1 | Mở tab **Báo cáo**, kỳ Tháng 9/2026 | Cùng hàng tiêu đề có **2 biểu tượng**: So sánh + **Xuất báo cáo** (nút tròn 48 px, màu trắng) |
| A2 | Chạm biểu tượng **Xuất báo cáo** đúng **1 lần** | Màn **Xuất báo cáo** mở ra: app bar teal + nút back + tiêu đề "Xuất báo cáo"; **không** bottom nav, **không** nút thêm giao dịch |
| A3 | Chạm **back** | Về màn Tổng quan Báo cáo, kỳ vẫn **Tháng 9/2026** |
| A4 | Đổi kỳ màn 01 sang **Năm 2026** → mở màn 04 | Hai trường ngày là `01/01/2026` – `31/12/2026` (FR-003) |
| A5 | Đổi kỳ màn 01 sang **Tuần** và **Ngày** → mở lại màn 04 mỗi lần | Tuần: **Thứ Hai → Chủ Nhật** của tuần đó; Ngày: **cùng một ngày** ở cả hai trường |
| A6 | Xoá **hết** giao dịch trong app rồi mở màn 04 (kỳ rỗng) | Màn **vẫn mở được**, giải thích rõ không có dữ liệu; **không** màn trắng, **không** thông báo lỗi; lối vào ở màn 01 **không** bị vô hiệu hoá (FR-018) |

### Nhóm B — Bố cục theo mockup `04` (FR-003, FR-009, FR-010, FR-028, SC-001)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| B1 | Đối chiếu `docs/report/man-hinh-04-xuat-bao-cao.svg` | Đủ 6 khối đúng thứ tự: **KHOẢNG THỜI GIAN** (2 trường) → **VÍ** → **DANH MỤC** → **TAG** → **ĐỊNH DẠNG XUẤT** (3 thẻ) → **hộp tóm tắt** → nút **Xuất báo cáo** |
| B2 | Xem mục ĐỊNH DẠNG XUẤT | 3 thẻ ngang hàng, mỗi thẻ có biểu tượng + tên + dòng chú thích: `PDF / Có biểu đồ`, `Excel / Bảng dữ liệu`, `CSV / Dữ liệu thô`; thẻ **PDF** đang chọn: **viền teal + dấu chọn**, hai thẻ kia viền xám |
| B3 | Chạm thẻ **Excel** | Chỉ **một** định dạng được chọn; viền/dấu chọn chuyển sang Excel; dòng 2 hộp tóm tắt đổi thành `Định dạng: Excel (Bảng dữ liệu)` |
| B4 | Xem ô TAG khi trống | Có **gợi ý** `Nhập tag để lọc (VD: #dulich)` |
| B5 | Xem hộp tóm tắt | Dòng 1: **số giao dịch** + khoảng ngày (`128 giao dịch • 01/09/2026 – 30/09/2026`); dòng 2: định dạng đang chọn kèm chú thích |
| B6 | Tìm **dòng cảnh báo** | Có dòng chú thích **hiển thị sẵn** (đọc được **trước** khi bấm xuất) nói rằng tệp ra khỏi app **không còn được bảo vệ**; **không** có hộp thoại xác nhận khi bấm xuất (FR-028) |
| B7 | Xem màu sắc | Không có hex cứng ngoài token; app bar/nút chính màu thương hiệu teal; **không** dùng coral cho thứ không phải cảnh báo/chi tiêu |

### Nhóm C — Bộ lọc khoảng thời gian (FR-003, FR-004, SC-009)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| C1 | Chạm trường **Từ ngày** | Mở bộ chọn ngày; **không cho** chọn ngày **sau** "Đến ngày" (ô đó mờ/không bấm được) |
| C2 | Chạm trường **Đến ngày** | **Không cho** chọn ngày **trước** "Từ ngày" |
| C3 | Đổi "Từ ngày" = **05/09/2026** | Hộp tóm tắt cập nhật **ngay** (số giao dịch + khoảng ngày); dòng tệp sau này chỉ có giao dịch từ 05/09 |
| C4 | Đổi "Đến ngày" = **05/09/2026** (bằng Từ ngày) | Khoảng **1 ngày** hợp lệ: tệp chỉ chứa giao dịch **đúng ngày 05/09** (biên hai đầu đều tính) |
| C5 | Đặt khoảng bao trọn giao dịch ngày **01/09** và ngày **30/09** | Cả hai giao dịch biên **có mặt** trong tệp (FR-004 — không mất ngày cuối) |
| C6 | Đặt khoảng **không có** giao dịch nào | Hộp tóm tắt `0 giao dịch`; nút **mờ** + thông báo (xem K1) |

### Nhóm D — Bộ lọc VÍ (FR-005, SC-010)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| D1 | Mở màn 04 | Chip **"Tất cả"** đang chọn (nền teal, chữ trắng); mỗi ví một chip nền nhạt |
| D2 | Chạm ví **Tiền mặt** | Hộp tóm tắt đổi số ngay; chip Tiền mặt **nền teal**; "Tất cả" **bỏ chọn** |
| D3 | Chạm thêm ví **Momo** | **Cả hai** chip đang chọn (nhiều ví cùng lúc — kiểu HOẶC) |
| D4 | Xuất tệp (bất kỳ định dạng) | Mọi dòng trong tệp thuộc **Tiền mặt hoặc Momo**; **không** có dòng nào của ví khác (SC-010) |
| D5 | Chạm chip **"Tất cả"** | **Xoá hết** lựa chọn ví; hộp tóm tắt về số của mọi ví |

### Nhóm E — Bộ lọc DANH MỤC + chip "+N khác" (FR-006, SC-010)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| E1 | Xem hàng chip DANH MỤC (đang có ≥ 5 danh mục cha) | Chip **"Tất cả"** + tối đa **3** chip danh mục + chip **"+N khác"** (N = số còn lại) |
| E2 | Chạm chip **"+N khác"** | Mở danh sách **đầy đủ** danh mục cha (chọn nhiều được); chọn 1 danh mục trong đó rồi đóng | 
| E3 | Chọn danh mục **Ăn uống** (có con "Cà phê") | Hộp tóm tắt tính **cả** giao dịch của Ăn uống **lẫn** Cà phê; tệp xuất ra có dòng của cả hai |
| E4 | Chọn thêm **Nhà ở** | Hai danh mục cùng chọn (HOẶC trong nhóm); tệp chỉ có giao dịch thuộc 2 danh mục đó (+ con của chúng) |
| E5 | Ẩn một danh mục ở Cài đặt → Danh mục → mở lại màn 04 | Danh mục **ẩn không có** chip; giao dịch của nó **vẫn** nằm trong tệp khi **không** lọc theo danh mục (biên "danh mục đã bị ẩn") |
| E6 | Chạm **"Tất cả"** | Xoá hết lựa chọn danh mục |
| E7 | Xoá hẳn một danh mục có giao dịch cũ rồi xuất tệp | Giao dịch **vẫn** trong tệp; cột danh mục ghi tên snapshot (hoặc trống), **không** lỗi |

### Nhóm F — Bộ lọc TAG (FR-007, SC-009)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| F1 | Gõ `dulich` (giao dịch có tag `dulich`) | Khớp — hộp tóm tắt cập nhật |
| F2 | Gõ `#dulich` | **Cùng kết quả** F1 (bỏ `#`) |
| F3 | Gõ `DULICH` hoặc `du lịch` | **Cùng kết quả** F1 (không phân biệt hoa/thường và dấu) |
| F4 | Gõ `khongtontai` | Hộp tóm tắt `0 giao dịch`; nút xuất **mờ** + thông báo; **không** báo lỗi đỏ |
| F5 | Xoá ô tag | Nút xuất **bật lại**, hộp tóm tắt về số thật |
| F6 | Tag khớp chỉ nằm trong **ghi chú**/tên danh mục (không phải tag) | **Không** khớp (lọc theo tag chỉ soi cột tag — khác bộ lọc màn Giao dịch) |

### Nhóm G — Kết hợp nhóm & hộp tóm tắt (FR-008, FR-010, SC-003, SC-007)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| G1 | Đặt ví **Tiền mặt** + danh mục **Ăn uống** + tag `dulich` + khoảng 01–15/09 | Tệp chỉ có giao dịch thoả **tất cả** 4 nhóm (VÀ giữa các nhóm) |
| G2 | Cùng lúc chọn **2 ví** và **2 danh mục** | Trong mỗi nhóm là **HOẶC**; giữa hai nhóm là **VÀ** |
| G3 | Bỏ hết lựa chọn một nhóm (VD chạm "Tất cả" ở ví) | Nhóm đó **không** giới hạn nữa, các nhóm khác giữ nguyên |
| G4 | Đổi bất kỳ thành phần bộ lọc | Hộp tóm tắt cập nhật **dưới 1 giây** (SC-007) |
| G5 | Đếm tay số giao dịch khớp rồi so với hộp tóm tắt | Khớp **chính xác** (SC-003) |

### Nhóm H — Tệp PDF (FR-012, FR-019, FR-024, SC-005)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| H1 | Chọn **PDF**, bấm **Xuất báo cáo** | Có trạng thái đang xử lý; xong thì **bảng chia sẻ của hệ thống** mở ra với tệp PDF |
| H2 | Tên tệp trong bảng chia sẻ | Dạng `bao-cao-thu-chi_20260901-20260930.pdf` — có khoảng thời gian + định dạng, **không** ký tự cấm |
| H3 | Lưu tệp rồi mở bằng trình đọc PDF | Mở được; trang đầu có **tiêu đề + khoảng thời gian + tổng thu + tổng chi + chênh lệch**; có **biểu đồ dòng tiền** và **biểu đồ phân bổ chi theo danh mục** + bảng top danh mục |
| H4 | Xem chữ trong PDF | Tiếng Việt **có dấu hiển thị đúng**, không ô vuông/không mất dấu; số tiền dạng `42.500.000 đ` |
| H5 | Cuộn xuống | Có **danh sách giao dịch** dạng bảng, phân trang khi dài (FR-012) |
| H6 | Đối chiếu số tổng hợp trong PDF với màn 01 cùng khoảng | **Khớp 0 đ** (SC-004) |
| H7 | Xuất PDF với khoảng **nhiều năm** | Tệp vẫn tạo được; biểu đồ dòng tiền **không** phình theo số ngày (≤ 6 cột) |

### Nhóm I — Tệp Excel & CSV, mở bằng bảng tính (FR-013, FR-014, FR-019, SC-005)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| I1 | Chọn **Excel** → xuất → mở bằng Google Sheets/WPS/Excel | Mở được, **2 sheet**: "Tổng hợp" (tổng thu/chi/chênh lệch + phân bổ chi theo danh mục) và "Giao dịch" |
| I2 | Sheet "Giao dịch" | Có **dòng tiêu đề**: ngày, loại, danh mục, ví, số tiền, ghi chú, tag; mỗi dòng một giao dịch |
| I3 | Cột số tiền (Excel/CSV) | Là **số** (bảng tính cộng được), **không** kèm `đ`, không phân tách nghìn |
| I4 | Chọn **CSV** → xuất → mở bằng bảng tính | Mở được, **chỉ** danh sách giao dịch (không có phần tổng hợp/hình ảnh) |
| I5 | Xem chữ trong CSV/Excel | Tiếng Việt có dấu **không lỗi font** (CSV có BOM UTF-8) |
| I6 | Giao dịch có ghi chú chứa `,` `"` và xuống dòng | Bảng tính mở ra **không lệch cột**; nội dung ô đúng nguyên văn |
| I7 | Số tiền **hàng tỉ** | Ghi đủ chữ số, không mất số |
| I8 | Nhãn loại giao dịch | `Thu`/`Chi`/`Chuyển khoản`/`Điều chỉnh số dư` — **đúng** theo loại giao dịch (không gán sai) |

### Nhóm J — Đủ dòng & loại transfer/adjustment khỏi con số (FR-015, FR-016, SC-003, SC-004, SC-013)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| J1 | Xuất CSV cho khoảng chứa **cặp chuyển khoản** và **điều chỉnh số dư** | Cả 3 dòng đó **có mặt** trong tệp (tệp khớp sổ giao dịch) |
| J2 | Cùng tệp, xem mục tổng hợp (Excel sheet "Tổng hợp" hoặc PDF) | Tổng thu/tổng chi **không** tính transfer/adjustment; chênh lệch khớp màn 01 (**0 đ** sai lệch) |
| J3 | Khoảng chỉ có **chuyển khoản** (xoá hết thu/chi) | Tệp **vẫn có** 2 dòng chuyển khoản; phần tổng hợp ghi tổng thu = tổng chi = **0** |
| J4 | Chọn danh mục **cha** trong tệp | 100% giao dịch của cha **và** con có mặt; phần phân bổ gộp con vào cha |
| J5 | Chọn **nhiều ví** | Tệp chứa giao dịch của **tất cả** ví đã chọn, **không** chứa ví không chọn — kể cả **vế kia của chuyển khoản** (SC-010) |
| J6 | Lấy ngẫu nhiên **100 dòng** trong tệp đối chiếu app | **0** dòng nằm ngoài bộ lọc (SC-013) |

### Nhóm K — Bộ lọc rỗng / nút vô hiệu (FR-017, FR-018, SC-006)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| K1 | Đặt bộ lọc ra **0 giao dịch** | Nút "Xuất báo cáo" **vô hiệu hoá** + thông báo cho biết bộ lọc không có giao dịch nào |
| K2 | Bấm thử nút khi đang vô hiệu | **Không** có phản hồi, **không** tạo tệp rỗng, **không** tạo tệp chỉ có dòng tiêu đề (SC-006) |
| K3 | Bỏ điều kiện lọc để ra ≥ 1 giao dịch | Nút **bật lại** |
| K4 | Mở màn 04 khi **cả app** chưa có giao dịch | Màn vẫn mở, đủ 5 mục, giải thích không có dữ liệu (như A6) |

### Nhóm L — Tiến trình, lỗi, huỷ chia sẻ (FR-023, FR-025, SC-008, SC-014)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| L1 | Xuất với khoảng **nhiều năm** dữ liệu | Hiện trạng thái "đang xử lý"; màn **vẫn phản hồi** (cuộn/nút back bấm được); **không** đứng hình (SC-008) |
| L2 | Đo thời gian từ lúc bấm đến lúc bảng chia sẻ hiện | **< 5 giây** với dữ liệu hàng nghìn giao dịch |
| L3 | Bấm nút **2 lần liên tiếp** thật nhanh | Chỉ chạy **một** lần xuất (nút bị khoá trong lúc xử lý) |
| L4 | Huỷ bảng chia sẻ (vuốt xuống/chạm ra ngoài) | Quay lại màn 04 **nguyên trạng**: bộ lọc + định dạng đã chọn **còn nguyên**, không treo (FR-025) |
| L5 | Mô phỏng lỗi tạo tệp (VD hết dung lượng thiết bị) | Hiện **thông báo dễ hiểu** (SnackBar); màn vẫn dùng được, bộ lọc giữ nguyên (FR-025) |
| L6 | Ngắt mạng hoàn toàn rồi xuất | Vẫn xuất được đầy đủ (app offline — FR-026/FR-027 "Giả định") |

### Nhóm M — Vòng đời & cô lập bộ lọc (FR-026, FR-027)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| M1 | Ở màn 04 chọn ví + danh mục + tag rồi **back**, mở lại | Về **mặc định kế thừa kỳ đang xem** — bộ lọc cũ **không** được ghi nhớ |
| M2 | Đổi khoảng ngày ở màn 04 rồi back | Kỳ đang chọn ở màn Tổng quan **không** đổi |
| M3 | Mở màn 04 lọc lung tung rồi back, mở màn 02 (Chi tiết) và màn 03 (So sánh) | Hai màn kia **không** bị ảnh hưởng (ba màn Báo cáo giữ nguyên hành vi PBI 22/23/26) |
| M4 | Mở tab **Giao dịch** → màn lọc | Bộ lọc ở màn Giao dịch **không** bị đổi |
| M5 | Mở màn 04 → back → thêm 1 giao dịch mới → mở lại màn 04 | Số giao dịch ở hộp tóm tắt **đã tính** giao dịch vừa thêm (đọc lại lúc mở màn) |
| M6 | Đang mở màn 04, sửa dữ liệu ở nơi khác trong lúc màn mở | Số liệu **không** tự đổi (không cập nhật đẩy — kế thừa PBI 22/26) |

### Nhóm N — Chế độ Tối & English (FR-020, FR-021, SC-011)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| N1 | Cài đặt → Giao diện → **Tối** → mở màn 04 | Nền, chữ, app bar, chip, 3 thẻ định dạng, hộp tóm tắt, dòng cảnh báo, nút xuất đúng bộ màu tối |
| N2 | Chụp màn hình, đo tương phản | Mọi chữ/số đọc được (SC-011) |
| N3 | Cài đặt → Ngôn ngữ → **English** → mở màn 04 | Tiêu đề app bar, tiêu đề 5 mục, nhãn 2 trường ngày, 3 tên định dạng + dòng chú thích, hộp tóm tắt, nút, dòng cảnh báo, **mọi thông báo** — **hết tiếng Việt** |
| N4 | Ở English, mở sheet "+N khác" + trạng thái 0 giao dịch | Nhãn trong sheet + thông báo rỗng cũng bằng tiếng Anh |
| N5 | Xem định dạng ngày & số tiền ở English | **Không đổi** (`01/09/2026`, `42.500.000 đ`) |

### Nhóm O — Bố cục cực trị (FR-022, SC-012)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| O1 | Cỡ chữ **lớn nhất** + màn hình nhỏ | Bố cục không vỡ; hàng chip ví/danh mục **xuống dòng gọn**; cuộn tới được nút **Xuất báo cáo** |
| O2 | Tên ví/danh mục **rất dài** | Chip cắt gọn bằng ellipsis, **không** tràn hàng |
| O3 | Số giao dịch **hàng nghìn** ở hộp tóm tắt | Dòng 1 không tràn/cắt chữ |
| O4 | Xem 3 thẻ định dạng ở cỡ chữ lớn | Không **cắt chữ** nhãn/chú thích |
| O5 | Xoay ngang / tablet (nếu có) | Không vỡ; nội dung cuộn được |
| O6 | Màn có tai thỏ/thanh cử chỉ | Không bị che nút xuất ở đáy |

### Nhóm P — Hiệu năng (SC-007, SC-008)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| P1 | Dữ liệu **vài năm** giao dịch; đổi liên tục ví/danh mục/tag | Hộp tóm tắt cập nhật **dưới 1 giây** mỗi lần, không giật |
| P2 | Xuất **CSV** với vài nghìn giao dịch | Xong trong **< 5 giây**, UI không đứng hình |
| P3 | Xuất **Excel** và **PDF** cùng dữ liệu | Mỗi lần **< 5 giây**, UI vẫn phản hồi |
| P4 | Khoảng **nhiều năm** (2019→2026) | Vẫn xuất được, không treo, không hết bộ nhớ |

---

## 3. Kiểm thử tự động

```bash
flutter test test/report_export_test.dart            # MỚI — lọc, tổng hợp, tên tệp, CSV
flutter test test/report_export_writers_test.dart    # MỚI — bytes PDF/XLSX
flutter test test/report_export_screen_test.dart     # MỚI — màn 04
flutter test test/report_screen_test.dart            # SỬA — lối vào thứ hai
flutter test                                         # toàn bộ
flutter analyze
```

---

## 4. Đối chiếu truy vết (tóm tắt)

| Nhóm | Phủ yêu cầu | Phủ tiêu chí |
|---|---|---|
| A | FR-001, FR-002, FR-003, FR-018 | SC-002 |
| B | FR-003, FR-009, FR-010, FR-028 | SC-001 |
| C | FR-003, FR-004 | SC-009 |
| D | FR-005 | SC-010 |
| E | FR-006 | SC-010 |
| F | FR-007 | SC-009 |
| G | FR-008, FR-010, FR-026 | SC-003, SC-007, SC-009 |
| H | FR-012, FR-019, FR-024 | SC-004, SC-005 |
| I | FR-013, FR-014, FR-019, FR-024 | SC-005 |
| J | FR-015, FR-016 | SC-003, SC-004, SC-010, SC-013 |
| K | FR-017, FR-018 | SC-006 |
| L | FR-023, FR-025 | SC-008, SC-014 |
| M | FR-026, FR-027 | — |
| N | FR-020, FR-021 | SC-011 |
| O | FR-022 | SC-012 |
| P | — | SC-007, SC-008 |

---

## 5. Ghi chú

- **Test đỏ có sẵn**: `test/transactions_dao_test.dart` → "Transactions drift —
  schema v4: categories seed + category_id (PBI 11, R1/R2/R4) …" **đỏ từ trước**
  PBI 27 (mốc baseline: **883 pass / 1 fail**). PBI này **không** sửa test đó —
  chỉ cần **không làm tăng** số test đỏ.
- **Kiểm thử tự động không mở được tệp thật**: CI không có Excel/trình đọc PDF ⇒
  test chỉ khẳng định **cấu trúc** (`%PDF`, zip có `xl/workbook.xml` + 2 sheet,
  ô tiếng Việt đọc lại được). Việc "mở bằng ứng dụng phổ thông" (SC-005) **chỉ**
  kiểm được ở nhóm H3/H4/I1/I4/I6 bằng tay trên emulator/máy thật.
- **PDF dùng font nhúng** (`assets/fonts/Roboto-*.ttf`): nếu QA thấy chữ vỡ/ô
  vuông ⇒ kiểm lại `pubspec.yaml` đã khai báo `assets/fonts/` và `flutter pub get`
  đã chạy sau khi thêm asset.
- **`share_plus` cần thiết bị/emulator thật** — trong `flutter test` nó không chạy
  (màn 04 nhận seam `ShareExport` để test bơm fake). Nhóm L (huỷ chia sẻ, tên tệp)
  **chỉ** QA được trên máy.
- **iOS chưa QA** ở các PBI trước. PBI này đụng plugin native
  (`share_plus`) ⇒ **nên** chạy thêm nhóm H1/H2/I1/I4 trên iOS nếu có máy; nếu bỏ
  qua phải ghi rõ trong `tasks.md`.
