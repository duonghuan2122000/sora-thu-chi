# Quickstart — kiểm thử tay màn Chi tiết theo danh mục (PBI 23)

**Mã PBI**: 23
**Liên kết**: [spec.md](./spec.md) · [plan.md](./plan.md)

## Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get
flutter analyze
flutter test                      # kỳ vọng: 657 test cũ + test mới, 0 đỏ
flutter run                       # chọn emulator/device
```

Chuẩn bị dữ liệu trên app (đủ để phủ các nhánh số liệu):

1. **≥ 7 danh mục chi có phát sinh** trong **tháng hiện tại** — nhiều hơn bảng màu (5 màu định tính) để thấy màu **lặp chu kỳ**; trong đó có **1 danh mục cha có giao dịch ở danh mục con**.
2. **1 giao dịch Chi không gắn danh mục** (dữ liệu cũ / nhập nhanh) trong tháng → phải hiện thành dòng **"Khác"**.
3. **1 cặp chuyển khoản nội bộ** trong tháng (không được ảnh hưởng bất kỳ con số nào).
4. **1 giao dịch Thu** trong tháng.
5. Một tháng khác: **chỉ có Thu**; một tháng khác nữa: **chỉ có chuyển khoản**; một tháng **trống** — dùng cho nhóm G.
6. Ít nhất 1 giao dịch có **ngày đúng ngày đầu kỳ** và 1 giao dịch **đúng ngày cuối kỳ** của tháng đang xem.

---

## A. Điểm vào, bố cục, quay về (FR-001, FR-002, FR-017 · SC-001, SC-002)

1. Tab **Báo cáo** → kỳ **Tháng** → thẻ "Top danh mục chi tiêu" có liên kết **"Xem tất cả"** ở bên phải tiêu đề thẻ.
2. Chạm "Xem tất cả" (**đúng 1 lần chạm**) → màn **Chi tiêu theo danh mục** mở ra: app bar **teal** + nút back + tiêu đề đúng mockup `02`; **không** có thanh điều hướng đáy; **không** có FAB.
3. Đối chiếu mockup `docs/report/man-hinh-02-chi-tiet-danh-muc.svg`: chip kỳ → vòng tròn có nhãn giữa → `DANH MỤC (n)` → các dòng danh mục → dòng gợi ý cuối màn. **Khác biệt cố ý**: chip kỳ **không** có mũi tên/menu.
4. Chạm **back** (**1 lần chạm**) → về màn Tổng quan Báo cáo, **vẫn ở kỳ Tháng** như trước khi mở.
5. Đổi kỳ màn 01 sang **Năm** rồi mở lại màn 02 → số liệu và chip đổi theo kỳ Năm (màn 02 **không** có cách tự đổi kỳ).

## B. Chip kỳ + nhãn giữa vòng tròn (FR-003, FR-004 · SC-001)

1. Với từng kỳ, chip ghi đúng **loại kỳ + mốc**: `Ngày 12/09/2026` · `Tuần 07/09–13/09/2026` · `Tháng 9/2026` · `Năm 2026`.
2. **Chạm vào chip → không có phản hồi nào** (không mở menu, không mở date picker).
3. Nhãn giữa vòng tròn đổi theo đơn vị kỳ: `Tổng chi ngày` / `Tổng chi tuần` / `Tổng chi tháng` / `Tổng chi năm`, kèm **tổng chi** của kỳ (định dạng `42.500.000 đ`).

## C. Danh sách đầy đủ + màu theo thứ hạng (FR-005, FR-006, FR-007 · SC-001, SC-007, SC-014)

1. Tiêu đề nhóm `DANH MỤC (n)` với **n = số dòng đang liệt kê** (số danh mục chi + "Khác" nếu có).
2. Với **7 danh mục chi** (bước chuẩn bị 1): **đủ 7 dòng** + "Khác" — **không** cắt còn 5 dòng như thẻ top màn 01.
3. Thứ tự **giảm dần theo số tiền**; hai danh mục cùng số tiền xếp theo tên (mở lại màn vài lần → **không** đổi chỗ).
4. Mỗi dòng: **chấm màu**, **tên**, **số tiền** (căn phải), **%** (căn phải, dưới số tiền), **thanh tiến độ** dưới tên — thanh chạy đúng độ dài bằng %.
5. **Chấm màu + thanh tiến độ của mỗi dòng trùng màu lát cắt tương ứng** trên vòng tròn; từ hạng thứ 6 trở đi **màu lặp lại** (trùng màu hạng 1) — phân biệt bằng tên và thứ tự.
6. Mở lại màn nhiều lần: **không** đổi màu.
7. Không có lát/dòng nào mang màu **coral**.

## D. Số khớp (FR-008 · SC-003, SC-004)

1. Cộng tay tiền chi của kỳ từ sổ giao dịch → khớp **0 đ** với số tiền giữa vòng tròn.
2. Cộng số tiền của mọi dòng trong danh sách → **bằng đúng** số giữa vòng tròn.
3. Cộng các **%** của mọi dòng → **đúng 100%**.
4. Lặp lại với kỳ có **1 danh mục** (1 dòng, 100%) và kỳ có **> 6 danh mục** (nhiều dòng, tổng vẫn 100%).

## E. Gộp danh mục con & dòng "Khác" (FR-009, FR-010, FR-012)

1. Danh mục cha có giao dịch ở cả cha lẫn con → danh sách chỉ có **1 dòng mang tên cha**, số tiền = tổng cha + con (khớp số ở thẻ top màn 01).
2. Khoản chi **không gắn danh mục** nằm ở dòng **"Khác"**, **luôn xếp cuối** danh sách.
3. **Chạm dòng "Khác" → không có phản hồi** (không mở màn Giao dịch).
4. Ẩn một danh mục đang có giao dịch (module Danh mục) rồi mở lại màn 02 → dòng đó **vẫn tính, vẫn hiện tên**.

## F. Drill-down sang màn Giao dịch (FR-011 · SC-006)

1. Chạm dòng **"Ăn uống"** → màn **Giao dịch** mở ra (đã ở đúng tab), danh sách **đã lọc sẵn**: chỉ Chi, đúng khoảng thời gian của kỳ đang xem, đúng danh mục (gồm cả giao dịch ở danh mục **con**).
2. **Số lượng và tổng tiền** giao dịch trong danh sách **khớp 0 sai lệch** với số tiền của dòng vừa chạm (đọc dòng tổng của thẻ "Thu/Chi tháng này" nếu có, hoặc cộng tay).
3. Bộ lọc điền sẵn hiện đúng ở màn Tìm kiếm & Lọc (chip **Chi**, khoảng ngày = kỳ đang xem, danh mục = cha).
4. Chạm **một lát cắt** trên vòng tròn → cùng kết quả như chạm dòng.
5. Back từ màn Giao dịch → về đúng nơi đã rời, không còn màn 02 nằm dưới.

## G. Trạng thái rỗng (FR-013, FR-014 · SC-010)

| Dữ liệu của kỳ | Kỳ vọng |
|---|---|
| Không có giao dịch nào | Thông điệp `Chưa có giao dịch nào trong kỳ này`; **không** vòng tròn rỗng, **không** tiêu đề nhóm rỗng, **không** màn trắng |
| Chỉ có giao dịch **Thu** | Thông điệp `Chưa có chi tiêu nào trong kỳ này` |
| Chỉ có **chuyển khoản nội bộ** | Như kỳ rỗng (`Chưa có giao dịch nào trong kỳ này`) |

## H. Làm mới số liệu (FR-015 · SC-009)

1. Từ màn 02, chạm một danh mục → sang tab Giao dịch → **thêm** một giao dịch Chi mới thuộc danh mục đó trong kỳ → quay lại tab Báo cáo → mở lại màn 02: tổng chi, vòng tròn, danh sách, số tiền và % đều **phản ánh số mới**.
2. Lặp lại với thao tác **sửa** và **xóa** một giao dịch.
3. Trong lúc màn 02 đang mở, **không** có số nào tự nhảy (kế thừa hành vi PBI 22).

## I. Chế độ Tối + English (FR-018, FR-019 · SC-011, SC-012)

1. Cài đặt → **Chế độ Tối** → mở màn 02: nền, chữ, app bar, màu vòng tròn, thanh tiến độ, đường phân cách dùng đúng bộ màu tối; chữ và số **đủ tương phản** để đọc (đo bằng công cụ đo tương phản trên ảnh chụp màn hình).
2. Cài đặt → **English** → màn 02: tiêu đề, chip kỳ, nhãn giữa vòng tròn, `CATEGORIES (n)`, `Other`, dòng gợi ý, thông điệp rỗng đều **tiếng Anh** — **0** nhãn tiếng Việt còn sót; số tiền vẫn đúng định dạng phân tách nghìn kèm đơn vị tiền tệ.
3. Kiểm lại nhãn tiếng Anh ở **cả 4 kỳ** (chip `Day/Week/Month/Year`, nhãn giữa `Day total/Week total/Month total/Year total`).

## J. Màn hình nhỏ, cỡ chữ lớn, số tiền lớn (FR-020 · SC-013)

1. Đặt cỡ chữ hệ thống **lớn nhất**, màn hình nhỏ: bố cục không vỡ, tên danh mục dài **cắt gọn bằng dấu ba chấm**, số tiền và % **không** bị đẩy ra ngoài, cuộn tới được **dòng cuối cùng** và dòng gợi ý.
2. Tạo giao dịch **hàng tỉ**: số giữa vòng tròn và số tiền từng dòng hiển thị đủ, không tràn/cắt chữ.

## K. Ngoại tuyến & hiệu năng (SC-008)

1. Bật **chế độ máy bay** → mở màn 02: hiển thị đầy đủ (mọi số liệu tính từ dữ liệu trên máy).
2. Với dữ liệu **vài năm** giao dịch: màn 02 hiển thị **dưới 1 giây**; danh sách hiện **đầy đủ** số danh mục của kỳ, không bị cắt bớt.

## L. Biên kỳ & ngày (FR-016)

1. Giao dịch đúng **ngày đầu kỳ** và **ngày cuối kỳ** đều được tính; giao dịch ngoài kỳ (ngày liền trước/liền sau) **không** bị tính.
2. Kỳ **Tuần** vắt qua hai tháng/năm (VD tuần 29/12–04/01): chip ghi đúng khoảng và năm của ngày cuối kỳ; số liệu vẫn khớp.
3. Giao dịch có **ngày trong tương lai** nhưng thuộc kỳ đang xem vẫn được tính.
