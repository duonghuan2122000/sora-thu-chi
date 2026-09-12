# Kịch bản kiểm thử nhanh: PBI 20 — Tổng quan Ngân sách (ngân sách theo danh mục)

**Mã PBI**: 20 · **Ngày**: 2026-09-12 · **Liên kết spec**: [spec.md](./spec.md) · **Kế hoạch**: [plan.md](./plan.md)

## 0. Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # sinh lại app_database.g.dart (bảng budgets)
flutter analyze
flutter test
flutter run          # emulator Android, cỡ chữ mặc định
```

- Dữ liệu nền: app mới cài có sẵn ví mẫu + 11 giao dịch mẫu + danh mục mặc định ⇒ đủ để thấy "tạo ngân sách giữa kỳ" (kịch bản D).
- Ghi lại **tháng/năm hiện tại** khi bắt đầu (bộ chọn kỳ mặc định là kỳ chứa hôm nay).
- Đặt lại DB giữa các nhóm nếu cần: gỡ app rồi cài lại (`flutter run` lại).

## A. Điểm vào từ tab Báo cáo (FR-001, SC-001, SC-002)

1. Mở app → tab **Báo cáo** → thấy hàng điểm vào **"Ngân sách"**.
2. Chạm hàng đó (**1 lần chạm** — đạt SC-001) → màn Tổng quan mở ra.
3. Đối chiếu mockup `docs/budget/man-hinh-01-tong-quan-ngan-sach.svg`:
   - vùng teal: tiêu đề **"Ngân sách"** bên trái, **nút `+` tròn** góc phải, bộ chọn kỳ **"Tháng 9, 2026"** kèm 2 mũi tên ở giữa (đúng tháng hiện tại);
   - **thanh điều hướng đáy hiện, tab "Báo cáo" đang sáng**;
   - **không có nút back** trên cùng (đúng mockup).

## B. Trạng thái rỗng (FR-019, SC-002)

1. DB chưa có ngân sách nào → thân màn hiện **lời nhắc + nút "Thêm ngân sách"**, **không** có thẻ tổng rỗng, không danh sách trống trơ.
2. Chạm nút trong trạng thái rỗng → mở màn Thêm ngân sách (như nhóm C).

## C. Màn Thêm ngân sách — bố cục & mặc định (FR-008, FR-009, FR-012, FR-014, SC-003)

1. Chạm `+` ở màn Tổng quan → màn Thêm ngân sách: app bar teal **có nút quay lại**, tiêu đề "Thêm ngân sách", **không có bottom nav**.
2. Kiểm từng nhóm theo mockup `docs/budget/man-hinh-02-them-ngan-sach.svg`:
   - **"PHẠM VI NGÂN SÁCH"**: "Theo danh mục" đang chọn (nền teal), "Tổng cộng" hiện nhưng **không có hiệu lực** (chạm không đổi gì);
   - hàng **"DANH MỤC"** trống, có mũi tên;
   - ô **"SỐ TIỀN GIỚI HẠN"** trống, đơn vị `đ` bên phải;
   - **"CHU KỲ"**: 3 lựa chọn Tuần / Tháng / Năm, **"Tháng" đang chọn**;
   - **"Ví áp dụng" = "Tất cả ví"**, **"Ngưỡng cảnh báo" = "80% và 100%"** (hiển thị, chạm không có gì xảy ra);
   - công tắc **"Lặp lại tự động mỗi kỳ" đang BẬT**, công tắc **"Cộng dồn phần chưa dùng hết" đang TẮT và không bấm được**;
   - nút **"Lưu ngân sách"** teal cao 44px ở chân màn.

## D. Tạo ngân sách giữa kỳ cho danh mục đã có chi tiêu (FR-006, FR-007, SC-005, SC-006)

1. Ghi nhớ một danh mục Chi đã có giao dịch trong **tháng hiện tại** (VD "Ăn uống") — nếu chưa có, thêm 1 giao dịch Chi thuộc danh mục đó trước.
2. Màn Thêm ngân sách → chạm hàng Danh mục → chọn **"Ăn uống"** → hàng hiển thị **icon + tên "Ăn uống"**.
3. Nhập số tiền `3000000` → ô hiển thị **`3.000.000`** kèm `đ` (FR-011).
4. Chạm **"Lưu ngân sách"** → quay về màn Tổng quan.
5. **Kiểm chốt**: dòng "Ăn uống" hiện **đã chi = tổng giao dịch Chi của danh mục trong tháng** (không phải 0), % và màu thanh đúng theo số đó; thẻ tổng = tổng đã chi / 3.000.000.

## E. Giao dịch Thu / chuyển khoản không ảnh hưởng (FR-006, SC-005)

1. Thêm 1 giao dịch **Thu** thuộc "Ăn uống" trong tháng → quay lại màn Tổng quan → số đã chi **không đổi**.
2. Thực hiện 1 **chuyển khoản nội bộ** → số đã chi **không đổi**.

## F. Giao dịch Chi của **danh mục con** cộng vào ngân sách cha (FR-006, SC-005)

1. Chọn một danh mục **cha** có danh mục con (VD cha "Ăn uống" với con "Cà phê"), tạo ngân sách cho **cha**.
2. Thêm 1 giao dịch Chi thuộc **danh mục con** trong tháng → dòng ngân sách của cha **tăng đúng số đó**.
3. Tạo ngân sách cho **danh mục con** → chỉ tính giao dịch của con, không tính của cha.

## G. Cập nhật sau khi thêm / sửa / xoá giao dịch (FR-007, SC-009)

1. Từ màn Tổng quan, thêm 1 giao dịch Chi thuộc danh mục có ngân sách → quay lại màn Tổng quan → dòng + thẻ tổng **đã cập nhật ngay**.
2. Sửa số tiền giao dịch đó (giảm) rồi mở lại màn Tổng quan → số đã chi **giảm theo** (kể cả % giảm xuống).

## H. Màu 3 dải ngưỡng (FR-005, SC-008)

Tạo ngân sách với số tiền sao cho % đã dùng rơi vào 4 mốc đại diện **45% / 84% / 96% / 107%** (điều chỉnh `amount` cho vừa):

| % | Thanh tiến độ | Màu % |
|---|---|---|
| 45% | teal | teal |
| 84% | **coral nhạt** (coral alpha ~0.6) | coral |
| 96% | coral nhạt | coral |
| 107% | **coral đậm** | coral |

Thêm: dòng vượt giới hạn **chỉ hiện %**, **không hiện số tiền vượt** (FR-005, kịch bản 18).

## I. Đổi kỳ tháng & ngân sách chu kỳ khác (FR-002, FR-013, FR-022, SC-013)

1. Ở màn Tổng quan chạm mũi tên **trái** → bộ chọn đổi sang **tháng trước**, thẻ tổng + các dòng **chu kỳ Tháng** tính lại theo tháng đó; chạm mũi tên **phải** → về tháng hiện tại.
2. Tạo thêm 1 ngân sách chu kỳ **Tuần** (VD "Cà phê"): dòng này hiển thị **nhãn chu kỳ "Tuần"** và tiến độ **tuần hiện tại**; khi đổi kỳ tháng đang xem, **dòng Tuần giữ nguyên**, dòng Tháng đổi theo (SC-013).
3. Kiểm thứ tự: các dòng sắp **giảm dần theo %** (dòng căng nhất lên đầu).

## J. Chồng lấn (FR-016, SC-007)

1. Tạo ngân sách "Ăn uống" chu kỳ **Tháng** (đã có ở nhóm D) → thử tạo **lần nữa** cùng danh mục + cùng chu kỳ → **không lưu được**, báo "Đã có ngân sách cho danh mục này trong kỳ. Hãy sửa ngân sách đang có."
2. Tạo cùng danh mục nhưng chu kỳ **Năm** → **lưu thành công**, hiện thành **2 dòng riêng**.
3. Mở chế độ sửa một ngân sách rồi **bấm Lưu mà không đổi gì** → lưu được (không tự chặn chính nó).

## K. Sửa ngân sách (FR-017, FR-018, SC-010)

1. Chạm một dòng ngân sách ở màn Tổng quan → màn **"Sửa ngân sách"**, các trường **điền sẵn** giá trị hiện tại (danh mục, số tiền, chu kỳ, lặp lại).
2. Sửa số tiền → lưu → màn Tổng quan **cập nhật theo giá trị mới**; % các dòng khác không đổi.
3. Sửa **danh mục** sang danh mục khác → đã chi **tính lại theo danh mục mới** (kể cả con của nó); nếu danh mục mới đã có ngân sách cùng chu kỳ → bị chặn như nhóm J.
4. Xác nhận **không có màn/hành vi xoá ngân sách** nào trong đợt này.

## L. Kết thúc kỳ & dòng không hợp lệ (FR-020, FR-021)

1. Tạo 1 ngân sách và **tắt** "Lặp lại tự động mỗi kỳ" → lùi bộ chọn sang tháng sau (hoặc đổi ngày hệ thống sang kỳ sau) → dòng đó hiển thị **"Đã kết thúc"** và **không** cộng vào thẻ tổng.
2. Danh mục bị xoá: hiện tại module Danh mục **chưa có xoá cứng** ⇒ kiểm bằng test tự động (`budget_view_test`: ngân sách trỏ danh mục không tồn tại → dòng **không hợp lệ**, không tự xoá, không tính vào thẻ tổng).

## M. Ngôn ngữ & bố cục (FR-023, FR-024, SC-011, SC-012)

1. Cài đặt → Ngôn ngữ → **English** → mở lại 2 màn Ngân sách: **không còn nhãn tĩnh tiếng Việt** (kể cả chuỗi trạng thái rỗng, thông báo lỗi validate, nhãn chu kỳ, nhãn "Đã kết thúc"); bộ chọn kỳ hiện dạng `9/2026`.
2. Về lại Tiếng Việt → đủ nhãn tiếng Việt như cũ.
3. Bật **cỡ chữ lớn nhất** (Cài đặt hệ thống) + màn hình nhỏ: 2 màn **không vỡ bố cục**, không cắt chữ, cuộn tới được phần tử cuối (nút Lưu / dòng cuối danh sách).
4. Đổi giao diện **Tối** → nền/chữ/thanh tiến độ đổi theo theme, coral vẫn đúng vai trò cảnh báo.

## N. Trường hợp biên khác

1. **Chưa có danh mục Chi**: (dữ liệu đã seed nên khó tái hiện) — kiểm bằng test: màn Thêm ngân sách không lưu được khi chưa chọn danh mục, và picker hiện "Chưa có danh mục cho loại này." khi rỗng.
2. **Số tiền không hợp lệ**: gõ chữ/ký tự đặc biệt vào ô tiền → ô chỉ nhận chữ số; để trống hoặc `0` → bấm Lưu báo **"Vui lòng nhập số tiền lớn hơn 0."**.
3. **Chưa chọn danh mục** → bấm Lưu báo **"Vui lòng chọn danh mục."**.
4. **Ví đang ẩn** (module Ví): không ảnh hưởng — ngân sách áp dụng **tất cả ví**.
5. **Nút back hệ thống / vuốt back** ở màn Tổng quan → quay về khung tab Báo cáo; ở màn Thêm/Sửa ngân sách → quay về màn Tổng quan **không lưu** gì.
6. **Chạm tab khác ở bottom nav của màn Tổng quan** → đóng màn Ngân sách và chuyển đúng tab vừa chạm.

## Ghi nhận kết quả

Chạy ngày **2026-09-12** trên emulator `sdk gphone16k x86 64` (Android 17/API 37), dữ liệu seed mặc định (5 ví + 11 giao dịch + 15 danh mục), cỡ chữ mặc định; tháng hệ thống = **9/2026**.

| Nhóm | Kết quả | Ghi chú |
|---|---|---|
| A | ✅ ĐẠT | Tab Báo cáo → hàng "Ngân sách" → **1 lần chạm** mở màn `01`; tiêu đề "Ngân sách" trái + nút `+` phải + bộ chọn "Tháng 9, 2026" giữa 2 mũi tên; **không nút back**; bottom nav hiện, tab Báo cáo sáng |
| B | ✅ ĐẠT | Không có ngân sách → lời nhắc + nút "Thêm ngân sách", **không** thẻ tổng/danh sách trơ |
| C | ✅ ĐẠT | Đúng mockup `02`: back + tiêu đề, **không** bottom nav; "Theo danh mục" chọn sẵn (Tổng cộng mờ, chạm không đổi); DANH MỤC trống; ô tiền có hậu tố `đ`; CHU KỲ Tháng chọn sẵn; "Ví áp dụng" = Tất cả ví; "Lặp lại" BẬT (bấm được); "Cộng dồn" TẮT + không bấm được; "Ngưỡng cảnh báo" = 80% và 100%; nút Lưu teal 44px |
| D | ✅ ĐẠT | Chọn "Mua sắm" → hàng hiện icon + tên; gõ `1000000` → ô hiện `1.000.000` + `đ`; lưu → dòng "Mua sắm" **1.200.000 đ / 1.000.000 đ = 120%** (chi tiêu có sẵn trong tháng, **không** bắt đầu từ 0) + thẻ tổng khớp |
| E | ⚠ một phần | UI không gắn được giao dịch **Thu** vào danh mục Chi (repo buộc `category.type` khớp loại) và transfer không có danh mục ⇒ không tái hiện được trên emulator; luật loại Thu/transfer phủ bằng test tự động (`budget_view_test`) |
| F | ⚠ một phần | **Phát hiện**: picker danh mục tái dùng (PBI 11) **không chọn được danh mục cha có con** — chạm cha là khoan xuống con ⇒ chưa tạo được ngân sách cho cha từ UI. Gộp chi tiêu của con vào cha + ngân sách con chỉ tính con: phủ bằng test tự động |
| G | ✅ ĐẠT | Từ màn Tổng quan bấm FAB ghi Chi 100.000 cho "Mua sắm" → về màn: dòng **1.300.000 đ / 2.000.000 đ = 65%** + thẻ tổng cập nhật **ngay** (SC-009) |
| H | ✅ ĐẠT | 0% teal; **84%** thanh coral **nhạt** + % coral; **120%/260%** thanh coral đậm + % coral; dòng vượt giới hạn **chỉ hiện %**, không hiện số tiền vượt. Mốc 96% cùng dải với 84% ⇒ phủ bằng test (4 mốc 45/84/96/107) |
| I | ✅ ĐẠT | Mũi tên trái → "Tháng 8, 2026", thẻ tổng + dòng Tháng tính lại (Mua sắm 0%), "0 ngày còn lại"; dòng **Tuần giữ nguyên** (84%, 120.000/143.000) khi đổi kỳ tháng (SC-013); danh sách **giảm dần theo %** (260 → 84 → 65 → 0) |
| J | ✅ ĐẠT | Lưu trùng "Mua sắm" + chu kỳ Tháng → **chặn**, SnackBar đúng câu "Đã có ngân sách cho danh mục này trong kỳ. Hãy sửa ngân sách đang có."; đổi sang chu kỳ **Năm** → lưu được, hiện **2 dòng riêng** |
| K | ✅ ĐẠT | Chạm dòng → "Sửa ngân sách" điền sẵn (danh mục/số tiền/chu kỳ/lặp lại); sửa 1.000.000 → 2.000.000 → màn Tổng quan cập nhật, dòng khác không đổi; **không** có hành vi xoá ngân sách nào |
| L | ⚠ một phần | "Đã kết thúc" cần thời gian trôi qua kỳ (không đổi ngày hệ thống) và "danh mục đã bị xoá" cần xoá cứng danh mục (module Danh mục chưa có) ⇒ **phủ bằng test tự động** (`budget_view_test` dòng ended/invalid; `budget_overview_screen_test` nhãn "Đã kết thúc" + loại khỏi thẻ tổng) |
| M | ✅ ĐẠT (đã sửa 1 lỗi) | English: "Budgets", bộ chọn kỳ `9/2026`, "This month's total budget", "… days left", `CATEGORIES`, "Copy last month", nhãn chu kỳ Year/Week, tên danh mục dịch — không sót tiếng Việt **sau khi sửa** (xem dưới). Giao diện **Tối**: nền/chữ/thanh tiến độ đổi theo theme, coral vẫn đúng vai trò cảnh báo, bố cục không vỡ. M3 (cỡ chữ lớn nhất + màn nhỏ) **chưa chạy** |
| N | ⚠ một phần | N2 ✅ gõ `abc12x3` → ô chỉ nhận `123`; N3 ✅ lưu không có danh mục → SnackBar "Vui lòng chọn danh mục."; N5 ✅ back hệ thống ở màn Tổng quan → về khung tab Báo cáo; N6 ✅ chạm tab khác ở bottom nav → đóng màn Ngân sách + chuyển đúng tab. N1 (chưa có danh mục Chi) và N4 (ví đang ẩn) không tái hiện được với dữ liệu seed ⇒ phủ bằng test |

### Lỗi phát hiện trong QA và đã sửa

1. **Nhãn EN sót tiếng Việt ở màn `02`** — hàng "Ngưỡng cảnh báo" in `'80% và 100%'` **thiếu `.tr`** ⇒ ở English hiện "80% và 100%". Đã thêm `.tr` (`budget_form_screen.dart`) + thêm khẳng định chống hồi quy trong `budget_form_screen_test` (EN phải thấy `80% and 100%`, không thấy `80% và 100%`).

### Ghi nhận thiết kế (không phải lỗi đợt này)

- **Không chọn được danh mục cha có con** làm phạm vi ngân sách: `CategoryPickerScreen` (PBI 11) khoan xuống con khi chạm cha. Kế hoạch PBI 20 chốt **tái dùng nguyên vẹn** picker nên hành vi này giữ nguyên; muốn tạo ngân sách theo cha cần đổi picker (PBI sau).
- **"Còn lại" âm** hiển thị `-200.000 đ` khi vượt giới hạn (mockup chỉ vẽ trường hợp dương; spec không chốt) — giữ nguyên số âm để người dùng biết đã vượt bao nhiêu.
