# Kịch bản kiểm thử nhanh: PBI 22 — Báo cáo tổng quan

**Mã PBI**: 22 · **Ngày**: 2026-09-12 · **Liên kết spec**: [spec.md](./spec.md) · **Kế hoạch**: [plan.md](./plan.md)

## 0. Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get
flutter analyze
flutter test
flutter run          # emulator Android, cỡ chữ mặc định
```

- **Không cần `build_runner`**: PBI này **không** đổi schema (giữ v7) và không
  thêm dependency.
- Dữ liệu nền: app mới cài có ví mẫu + 11 giao dịch mẫu + danh mục mặc định
  (**có sẵn Thu và Chi trong tháng hiện tại** ⇒ màn Tổng quan có số liệu ngay).
- Chuẩn bị thêm để phủ nhánh:
  - **G1** — 1 giao dịch **Thu** và 1 giao dịch **Chi** trong **hôm nay** (kiểm kỳ Ngày).
  - **G2** — 1 giao dịch **Chi** ở **danh mục con** (VD Ăn uống → Cà phê) (kiểm gộp cha).
  - **G3** — 1 giao dịch **chuyển khoản nội bộ** giữa 2 ví (kiểm loại trừ).
  - **G4** — 1 danh mục **Chi mới** rồi **ẩn** nó, ghi 1 giao dịch Chi vào nó (kiểm danh mục ẩn).
- Ghi lại **ngày hôm nay** khi bắt đầu; mọi số "tính tay" lấy từ sổ giao dịch thật.

## A. Điểm vào & bố cục (FR-001, FR-002, FR-017, SC-001, SC-002)

1. Mở app → chạm tab **Báo cáo** ở thanh điều hướng đáy → màn **Tổng quan Báo cáo**
   mở ra; **vẫn có** thanh điều hướng đáy với tab **Báo cáo** đang chọn.
2. Đối chiếu mockup `docs/report/man-hinh-01-bao-cao-tong-quan.svg`:
   - khu đầu màn **màu teal**: tiêu đề **"Báo cáo"**, **segmented control 4 lựa chọn**
     (Ngày | Tuần | **Tháng** | Năm — mặc định **Tháng**), **2 số tổng** "Tổng thu"
     (mũi tên tăng) / "Tổng chi" (mũi tên giảm) chữ trắng;
   - **không** có nút biểu tượng **lịch** ở góc phải;
   - ngay dưới khu đầu màn: hàng điều hướng **"Ngân sách"** (icon + tên + dòng phụ + mũi tên);
   - rồi tới 3 thẻ theo thứ tự: **Dòng tiền 6 tháng gần đây** → **Phân bổ chi tiêu
     theo danh mục** → **Top danh mục chi tiêu**.
3. **SC-001**: ngay sau khi chạm tab (không chạm gì thêm) đã thấy **tổng thu, tổng
   chi và biểu đồ dòng tiền**.
4. Chạm hàng **"Ngân sách"** → màn **Tổng quan Ngân sách** mở ra như trước PBI này;
   **quay lại** → màn Tổng quan Báo cáo vẫn giữ **kỳ đang chọn** (FR-017, kịch bản 17).

## B. 2 số tổng & loại trừ chuyển khoản (FR-004, SC-003, SC-004)

1. Ở kỳ **Tháng**: "Tổng thu" = tổng tiền các giao dịch **Thu** trong tháng (cộng tay
   từ sổ, gồm cả giao dịch ngày tương lai nếu có) → khớp **0 đ**; "Tổng chi" tương tự
   với các giao dịch **Chi**.
2. Thêm **G3** (chuyển khoản) → **không** con số nào đổi (2 số tổng, biểu đồ, phân bổ, top).

## C. Biểu đồ cột ghép đôi (FR-005, FR-006, FR-007, SC-002)

1. Thẻ "Dòng tiền 6 tháng gần đây": chú giải **Thu** (teal) / **Chi** (coral); **6
   nhóm cột**, mỗi nhóm 2 cột (thu teal, chi coral); dưới trục có **nhãn tháng**
   (VD `T4 … T9`, tháng hiện tại là nhãn **cuối** và **đậm hơn**).
2. Đổi sang kỳ **Tuần** → tiêu đề thành **"Dòng tiền 6 tuần gần đây"**, nhãn trục là
   `ngày/tháng` với tuần **bắt đầu Thứ Hai**; kỳ **Ngày** → **"6 ngày gần đây"**;
   **Năm** → **"6 năm gần đây"**, nhãn là năm.
3. Tháng/kỳ không có giao dịch vẫn hiện **cột 0** + nhãn (trục liên tục — FR-006).
4. **FR-007**: chạm vào một cột → hiện **số tiền chính xác** của cột đó; chạm ra
   ngoài → ẩn; **không** điều hướng sang màn khác.

## D. Vòng tròn phân bổ theo danh mục (FR-008, FR-009, FR-010, FR-011, SC-005)

1. Thẻ "Phân bổ chi tiêu theo danh mục": **vòng tròn** chia theo các danh mục chi
   nhiều nhất trong kỳ; **giữa vòng tròn** ghi **"Tổng chi"** + **số tiền khớp
   "Tổng chi" ở khu đầu màn** (khớp 0 đ).
2. Bên phải là **danh sách chú giải**: chấm màu + tên danh mục + **%**, sắp **giảm dần**.
3. **Kiểm chốt SC-005**: cộng các **%** hiển thị = **100%**; cộng **tiền** các lát
   (suy ra từ % hoặc bằng cách chạm để lọc) = **đúng tổng chi của kỳ**.
4. **FR-010/G2**: giao dịch ở **danh mục con** được gộp vào **danh mục cha** — chỉ
   thấy **một** dòng mang tên cha, tiền gồm cả con.
5. **Không có "Khác"** khi kỳ chỉ có **≤ 5** danh mục chi; **có "Khác"** khi > 5 danh
   mục hoặc có tiền chi không gắn danh mục; "Khác" luôn xếp **cuối**.
6. **FR-011**: màu các lát là bộ **định tính** (teal, teal đậm nhạt, hổ phách, xanh
   lam nhạt, xám) — **không** lát nào màu coral; đổi kỳ rồi quay lại → **màu không đổi chỗ**.
7. **G4**: giao dịch Chi của **danh mục đã ẩn** vẫn được tính và hiện **tên bình thường**.

## E. Chạm danh mục → màn Giao dịch đã lọc sẵn (FR-012, SC-006)

1. Chạm **một lát cắt** (hoặc **một dòng chú giải**) → màn **Giao dịch** mở ra, đã
   **lọc sẵn**: chip **Chi**, khoảng ngày = kỳ đang chọn, danh mục = danh mục đó.
2. **Kiểm chốt SC-006**: thanh "N kết quả · Tổng" ở màn Giao dịch có tổng tiền **khớp
   100%** với số tiền của danh mục đó trên thẻ phân bổ (cả khi danh mục có con).
3. Quay lại tab Báo cáo (chạm tab) → bộ lọc cũ ở màn Giao dịch vẫn còn (bấm **Bỏ lọc**
   để xem toàn bộ).
4. Chạm nhóm **"Khác"** → **không** điều hướng (nhóm gộp, không có bộ lọc danh mục
   tương ứng).

## F. Top danh mục chi tiêu (FR-013)

1. Thẻ "Top danh mục chi tiêu": **tối đa 5 dòng**, mỗi dòng có **icon danh mục**,
   **tên**, **số tiền**, **thanh tiến độ** tỉ lệ trên tổng chi của kỳ; thứ tự **giảm dần**.
2. Số tiền dòng top **khớp** số tiền lát cắt cùng danh mục ở thẻ phân bổ.
3. Kỳ có ≤ 5 danh mục chi → số dòng = số danh mục; kỳ có nhiều hơn → đúng **5** dòng
   (**không** có dòng "Khác").

## G. Đổi kỳ (FR-003, SC-007)

1. Lần lượt chọn **Ngày → Tuần → Tháng → Năm**, lặp **10 lần**: mỗi lần **toàn bộ**
   màn tính lại (2 số tổng, biểu đồ, phân bổ, top) và **không** lẫn số của kỳ cũ;
   không treo, không màn trắng.
2. Với dữ liệu vài năm, mỗi lần đổi kỳ cập nhật **< 1 giây** (SC-007).
3. Kỳ **Năm** khi app mới dùng vài tháng: biểu đồ vẫn đủ **6 cột năm** (các năm chưa
   có dữ liệu = 0), 2 số tổng + phân bổ chỉ tính dữ liệu thực có.
4. Kỳ **Tuần** đang xem là tuần **chứa hôm nay**, bắt đầu **Thứ Hai**.
5. Giao dịch đúng **ngày đầu/cuối kỳ** được tính vào kỳ đó và **không** xuất hiện ở
   kỳ liền kề.

## H. Trạng thái rỗng (FR-014, FR-015, SC-009)

1. Chọn kỳ **Ngày** ở một ngày **không có giao dịch Thu/Chi** → 2 số tổng hiện **0 đ**
   và **cả 3 thẻ** hiện thông điệp rỗng dễ hiểu ("Chưa có giao dịch nào trong kỳ
   này") — **không** biểu đồ trống, **không** màn hình trắng.
2. Chọn kỳ có **chỉ Thu** (không Chi) → "Tổng chi" = 0; biểu đồ **vẫn vẽ đủ 6 đơn vị**
   (cột chi = 0); **riêng** thẻ phân bổ + thẻ top hiện trạng thái rỗng ("Chưa có chi
   tiêu nào trong kỳ này").
3. Kỳ **chỉ có chuyển khoản nội bộ** → coi như không có Thu/Chi: 2 số tổng = 0 và cả
   3 thẻ rỗng.

## I. Dữ liệu đổi → số liệu đổi (FR-016, SC-008)

1. Ở màn **Giao dịch**: thêm một giao dịch **Chi** mới trong tháng → chạm tab **Báo
   cáo** → 2 số tổng, biểu đồ, phân bổ, top đều phản ánh **số mới ngay lần mở đó**.
2. Làm lại với **sửa** số tiền và **xóa** một giao dịch → số liệu đổi tương ứng.
3. Đứng ở tab **Báo cáo**, bấm **FAB** ghi một giao dịch Chi → quay lại → số liệu đã
   cập nhật (không phải đổi tab rồi quay lại).

## J. Ngôn ngữ & giao diện (FR-018, FR-019, SC-010, SC-011)

1. Cài đặt → Ngôn ngữ → **English** → mở lại tab Báo cáo: **0** nhãn tĩnh tiếng Việt
   còn sót — kiểm từng nhãn: tiêu đề màn, 4 lựa chọn kỳ, "Tổng thu"/"Tổng chi",
   tiêu đề 3 thẻ + nhãn **Thu/Chi** ở chú giải, nhãn **"Tổng chi"** giữa vòng tròn,
   thông điệp rỗng, nhãn đơn vị thời gian trên trục biểu đồ. Số tiền vẫn định dạng
   `42.500.000 đ`.
2. Cài đặt → Giao diện → **Tối**: nền, chữ, thẻ và **màu các lát vòng tròn + màu 2
   cột** dùng bộ màu tối, chữ/số vẫn đọc được (SC-011); kiểm nhanh 2 số tổng trên nền
   teal vẫn tương phản.
3. Màn hình nhỏ + **cỡ chữ lớn nhất**: bố cục không vỡ, không cắt chữ, số tiền không
   tràn khỏi thẻ, cuộn tới được hết **thẻ cuối** (FR-020/SC-012).

## K. Biên về số tiền & thời gian

1. Ghi một giao dịch **hàng tỉ** (VD `5.000.000.000`) trong kỳ → 2 số tổng + nhãn
   biểu đồ hiển thị đúng định dạng phân tách nghìn, **không** tràn/cắt chữ.
2. Ghi giao dịch có **ngày tương lai** trong kỳ đang chọn → vẫn được tính.
3. Đổi kỳ **liên tục** (bấm nhanh 4 lựa chọn nhiều lần) → không treo, không hiển thị
   lẫn số của kỳ cũ.
4. Hai danh mục **cùng số tiền** → thứ tự hiển thị ổn định (xếp theo tên), đóng/mở lại
   màn không đổi chỗ.
5. **Tắt mạng** (airplane mode) → màn Tổng quan vẫn hiển thị đầy đủ (offline hoàn toàn).

## L. Đối chiếu tự động (chạy trước QA tay)

```bash
flutter analyze
flutter test test/report_view_test.dart test/report_controller_test.dart test/report_screen_test.dart
flutter test        # toàn bộ — không đỏ test cũ
```

- `report_view_test` phủ: kỳ Ngày/Tuần/Tháng/Năm + tuần bắt đầu Thứ Hai; 6 đơn vị liên
  tiếp; loại transfer/adjustment; gộp danh mục con; top 5 + "Khác" (đủ 3 nhánh: ≤5,
  >5, có tiền không gắn danh mục); tổng % = 100; thứ tự ổn định; cờ rỗng.
- `report_controller_test` phủ: `load` → có `data`; `setPeriod` → tính lại **không** đọc
  DB lần nữa; lỗi đọc → `error` + giữ `data` cũ.
- `report_screen_test` phủ: render đủ thành phần; đổi kỳ đổi số; chạm danh mục → bộ lọc
  đúng (Chi + khoảng kỳ + danh mục cha) + `onSelectTab(1)`; chạm "Khác" → không điều
  hướng; trạng thái rỗng 2 loại; English không còn nhãn tiếng Việt.

---

## Kết quả QA tay (2026-09-12)

Người dùng chạy trọn **nhóm A–K** trên emulator Android — **ĐẠT toàn bộ**, gồm các
nhóm Claude không tự chạy: C (chạm cột hiện số tiền), E (drill-down sang màn Giao dịch
đã lọc), G (đổi kỳ), H (3 thẻ trạng thái rỗng), I (dữ liệu đổi → số liệu đổi),
J (English không sót nhãn tiếng Việt, chế độ Tối) và K (cỡ chữ lớn nhất, màn hình nhỏ,
số tiền hàng tỉ, tắt mạng). **Không phát hiện lệch** cần sửa. ⇒ T039/T040 hoàn tất,
PBI 22 xong trọn **42/42**.
