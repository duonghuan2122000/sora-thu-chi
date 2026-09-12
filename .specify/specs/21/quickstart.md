# Kịch bản kiểm thử nhanh: PBI 21 — Chi tiết Ngân sách

**Mã PBI**: 21 · **Ngày**: 2026-09-12 · **Liên kết spec**: [spec.md](./spec.md) · **Kế hoạch**: [plan.md](./plan.md)

## 0. Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # sinh lại app_database.g.dart (cột is_archived, schema v7)
flutter analyze
flutter test
flutter run          # emulator Android, cỡ chữ mặc định
```

- Dữ liệu nền: app mới cài có ví mẫu + 11 giao dịch mẫu + danh mục mặc định; **phải tạo ngân sách trước** (PBI 20, màn `01` → nút `+`) vì bảng `budgets` không seed.
- Chuẩn bị **3 ngân sách thử** để phủ các nhánh:
  - **N1** — "Mua sắm", chu kỳ **Tháng**, giới hạn **nhỏ hơn** tổng Chi đã có trong tháng (⇒ đã vượt giới hạn, có băng cảnh báo tốc độ).
  - **N2** — "Cà phê", chu kỳ **Tuần**, giới hạn lớn (⇒ chưa vượt).
  - **N3** — "Đi lại", chu kỳ **Tháng**, **tắt** "Lặp lại tự động mỗi kỳ" (⇒ kiểm nhánh kết thúc/kỳ duy nhất).
- Ghi lại **tháng/năm hiện tại** khi bắt đầu; mọi số "tính tay" dưới đây lấy từ sổ giao dịch thật trên máy.

## A. Điểm vào & bố cục màn Chi tiết (FR-001, FR-002, SC-001, SC-002)

1. Màn Tổng quan Ngân sách → chạm dòng **N1** (**1 lần chạm** — SC-001) → màn **Chi tiết Ngân sách** mở ra (thay vì mở thẳng màn Sửa như PBI 20).
2. Đối chiếu mockup `docs/budget/man-hinh-03-chi-tiet-ngan-sach.svg`:
   - app bar teal: nút **quay lại** trái, tiêu đề = **tên danh mục**, dòng phụ **"Ngân sách tháng • Tháng 9, 2026"**, nút **đổi kỳ** (icon lịch) góc phải;
   - **không** có thanh điều hướng đáy;
   - thứ tự thân màn: **thẻ tiến độ** → **băng cảnh báo tốc độ** → **SO SÁNH DỰ KIẾN • THỰC TẾ** → **GIAO DỊCH TRONG KỲ** + "Xem tất cả" → **2 nút** Chỉnh sửa / Lưu trữ ngân sách ở cuối.
3. Mặc định mở ở **kỳ hiện tại** của ngân sách.

## B. Thẻ tiến độ — chưa vượt & đã vượt (FR-003, FR-004, FR-005, FR-006)

1. Mở **N2** (chưa vượt): nhãn "Đã dùng" + số tiền đã chi cỡ lớn theo **dải màu** (teal nếu < 80%, coral nếu ≥ 80%), dòng phụ **"trên {giới hạn} giới hạn"**, nhãn "Trạng thái" + huy hiệu **"Bình thường {…}%"** (hoặc **"Sắp đạt {…}%"** ở dải 80–99% — **không** có chữ "Vượt"), thanh tiến độ, dòng cuối trái = **số tiền còn lại**, phải = **số ngày còn lại**.
2. Mở **N1** (đã vượt): số tiền đã dùng **màu coral**, huy hiệu **"Vượt {…}%"** nền coral nhạt, thanh tiến độ **đầy màu coral**, dòng cuối trái = **số tiền vượt**, phải = **số ngày còn lại**.
3. **Kiểm chốt SC-003**: tính tay từ sổ giao dịch (chỉ giao dịch **Chi**, gồm cả **danh mục con**, trong kỳ) → "đã dùng" và "vượt" phải khớp **0 đ**; "ngày còn lại" khớp theo lịch (tháng 30 ngày, hôm nay ngày 12 ⇒ **18 ngày**).
4. Giao dịch **Thu** và **chuyển khoản nội bộ** trong kỳ **không** làm thay đổi bất kỳ số nào ở đây.

## C. Băng cảnh báo tốc độ chi tiêu (FR-007, SC-004)

1. **N1** (đã dùng 107% khi mới qua ~40% số ngày) → băng **hiện**: tiêu đề **"Tốc độ chi tiêu nhanh hơn dự kiến"**, dòng phụ nêu **% số ngày đã qua** và **% ngân sách đã dùng**.
2. Tạo ngân sách **N4** giới hạn rất lớn (đã dùng ~10% khi đã qua ~40% ngày) → băng **không hiện** (SC-004 nhánh ngược).
3. **N3** không lặp lại, kỳ đã kết thúc → băng **không hiện** (cảnh báo nhịp chỉ có nghĩa với kỳ đang diễn ra).

## D. Đổi kỳ đang xem (FR-023, FR-024, SC-012)

1. Chạm nút **đổi kỳ** ở góc phải app bar → danh sách kỳ mở ra, **chỉ** gồm các kỳ từ **kỳ bắt đầu áp dụng** đến **kỳ hiện tại** (không có kỳ nào trước khi ngân sách bắt đầu — kịch bản 3); kỳ đang xem được đánh dấu.
2. Chọn **"Tháng 8, 2026"** → **toàn bộ** màn chuyển sang kỳ đó: dòng phụ app bar, thẻ tiến độ, số tiền vượt/còn lại, huy hiệu trạng thái, biểu đồ và danh sách giao dịch đều tính lại.
3. Vì kỳ đã kết thúc: **không** có băng cảnh báo tốc độ và vị trí "… ngày còn lại" hiển thị **"Đã kết thúc"**.
4. **Kiểm chốt SC-012**: mọi số ở kỳ đã chọn khớp **0 đ / 0 giao dịch** so với tính tay từ sổ giao dịch **của riêng kỳ đó**.
5. Hai nút **"Chỉnh sửa"** và **"Lưu trữ ngân sách"** vẫn hiện và bấm được ở **mọi** kỳ (FR-024).
6. Ngân sách **Tuần** (N2): dòng phụ nêu **chu kỳ tuần + kỳ tuần đang xem**, bộ chọn kỳ liệt kê các **tuần**, biểu đồ lấy **3 tuần gần nhất** (kịch bản 18).

## E. Khối so sánh Dự kiến • Thực tế (FR-008, FR-009, FR-010, SC-006)

1. Thấy **chú giải** Dự kiến / Thực tế, **đường mốc nét đứt** kèm số tiền giới hạn ("Dự kiến {giới hạn}"), và **cột đôi cho 3 kỳ gần nhất** — kỳ đang xem là **cột cuối cùng**, mỗi kỳ có **nhãn kỳ** dưới trục (VD `T7`, `T8`, `T9`), nhãn kỳ đang xem **đậm hơn**.
2. Cột **"Thực tế"** của kỳ vượt giới hạn = **coral**, của kỳ chưa vượt = **teal**; cột **"Dự kiến"** của mọi kỳ **cùng một màu trung tính** (SC-006).
3. Chọn một **kỳ đã qua** (nhóm D) → biểu đồ lấy 3 kỳ gần nhất **tính đến kỳ đang xem** (kỳ đang xem vẫn là cột cuối).
4. Ngân sách **mới tạo trong kỳ này** (kỳ đầu tiên) → biểu đồ vẫn hiển thị bình thường với **1 cặp cột**, không lỗi, không đòi tối thiểu 3 kỳ (kịch bản 19).
5. Sửa **giới hạn** của ngân sách (nhóm G) → đường mốc + cột "Dự kiến" **đổi theo giới hạn mới**, cột "Thực tế" của các kỳ trước **không đổi**.

## F. Danh sách "Giao dịch trong kỳ" (FR-011, FR-012, FR-013)

1. Nhóm hiện tiêu đề **"GIAO DỊCH TRONG KỲ"** + liên kết **"Xem tất cả"** bên phải; danh sách liệt kê các giao dịch **Chi** thuộc danh mục ngân sách (**kể cả danh mục con**) trong kỳ, **mới nhất trước**, tối đa **5 dòng**.
2. Mỗi dòng: biểu tượng danh mục, **tên giao dịch**, **thời gian** (VD "Hôm nay, 12:30"), số tiền **Chi màu coral**.
3. Giao dịch **Thu** và **chuyển khoản nội bộ** **không** xuất hiện trong danh sách.
4. Kỳ chưa có giao dịch Chi nào → nhóm hiển thị **trạng thái rỗng** dễ hiểu (không phải danh sách trống trơ).
5. Tạo ngân sách cho **danh mục cha** (nếu chọn được) rồi ghi Chi ở **danh mục con** → dòng đó **xuất hiện** trong danh sách và **cộng vào** số đã dùng.

## G. "Xem tất cả" mở màn Giao dịch đã lọc sẵn (FR-014, SC-005)

1. Từ màn Chi tiết chạm **"Xem tất cả"** → màn **Giao dịch** mở ra **đã lọc sẵn** theo danh mục ngân sách (gồm con) + **khoảng thời gian của kỳ đang xem**; thấy thanh "N kết quả · Tổng: …".
2. **Kiểm chốt SC-005**: tổng số tiền của danh sách trong màn Chi tiết **khớp 100%** với "đã dùng"; và tập giao dịch ở màn Giao dịch **đúng cùng tập đó** (0 sai lệch số lượng và tổng tiền).
3. Đang xem **kỳ cũ** rồi chạm "Xem tất cả" → màn Giao dịch lọc theo **khoảng của kỳ cũ đó**, không phải kỳ hiện tại.
4. Chạm **"Bỏ lọc"** ở màn Giao dịch → về danh sách đầy đủ như trước.

## H. Chỉnh sửa từ màn Chi tiết (FR-015, FR-024)

1. Chạm **"Chỉnh sửa"** → màn **Sửa ngân sách** (PBI 20) mở với giá trị **điền sẵn**; sửa số tiền giới hạn → Lưu → quay lại **màn Chi tiết**.
2. Thẻ tiến độ, huy hiệu trạng thái, biểu đồ và danh sách giao dịch **tính lại theo giới hạn mới**; số **thực tế** các kỳ trước trên biểu đồ **không** đổi.
3. Đang xem **kỳ cũ** rồi Chỉnh sửa + Lưu → màn vẫn ở **kỳ cũ đang xem** (không nhảy về kỳ hiện tại).
4. Đổi **chu kỳ** của ngân sách (VD Tháng → Tuần) rồi Lưu → màn Chi tiết **không lỗi**: bộ chọn kỳ dựng lại theo chu kỳ mới và về kỳ hiện tại của chu kỳ mới.

## I. Lưu trữ ngân sách (FR-016, FR-017, SC-007)

1. Chạm **"Lưu trữ ngân sách"** → hộp thoại **hỏi xác nhận**; chọn **Hủy** → không có gì thay đổi.
2. Chạm lại → xác nhận → màn Chi tiết **đóng**, quay về màn **Tổng quan Ngân sách**, dòng ngân sách đó **không còn** trong danh sách và **không** tính vào thẻ tổng.
3. **Kiểm chốt SC-007**: mở sổ giao dịch (tab Giao dịch) → **mọi giao dịch Chi đã ghi vẫn còn nguyên**; số dư các ví **không đổi** (so sánh trước/sau).
4. Gỡ app rồi cài lại (hoặc mở lại app) → ngân sách đã lưu trữ **vẫn không** quay lại danh sách (đã ghi `is_archived = true` trong DB).

## J. Kết thúc kỳ & ngân sách không lặp lại (FR-020)

1. **N3** (không lặp lại) có kỳ `startDate` = tháng hiện tại → mở Chi tiết: mặc định đúng **kỳ hiện tại**.
2. Với ngân sách **không lặp lại đã qua kỳ** (đổi ngày hệ thống sang tháng sau, hoặc phủ bằng test): màn mở đúng **kỳ đã kết thúc đó**, nêu rõ trạng thái đã kết thúc, **không** có băng cảnh báo tốc độ, bộ chọn kỳ **chỉ có 1 lựa chọn**.

## K. Ngân sách có danh mục bị xóa (FR-019)

1. (Module Danh mục chưa có xoá cứng ⇒ phủ bằng test tự động.) Màn Chi tiết hiển thị trạng thái **không còn hợp lệ** + nhắc gán lại danh mục khác, **không** hiện số liệu/biểu đồ sai lệch, ngân sách **không** bị tự xoá; hai nút Chỉnh sửa / Lưu trữ **vẫn hiện** để gán lại.

## L. Cập nhật khi giao dịch thay đổi (FR-018, SC-008)

1. Từ màn Chi tiết, ghi thêm 1 giao dịch Chi thuộc danh mục ngân sách (FAB → màn Thêm giao dịch) → mở lại màn Chi tiết → "đã dùng", số vượt/còn lại, huy hiệu, biểu đồ, danh sách **đều phản ánh số mới**.
2. Sửa **giảm** số tiền một giao dịch Chi trong kỳ → mở lại màn Chi tiết → số đã dùng **giảm theo** ngay trong lần mở đó.

## M. Ngôn ngữ & bố cục (FR-021, FR-022, SC-009, SC-010)

1. Cài đặt → Ngôn ngữ → **English** → mở lại màn Chi tiết: **0** nhãn tĩnh còn tiếng Việt — gạch đầu dòng từng nhãn: dòng phụ app bar, "Đã dùng", "trên … giới hạn", "Trạng thái", huy hiệu trạng thái (3 dạng), "… ngày còn lại" / "Đã kết thúc", nội dung **băng cảnh báo** (tiêu đề + dòng phụ), tiêu đề khối so sánh, chú giải, đường mốc, tiêu đề nhóm giao dịch, "Xem tất cả", **trạng thái rỗng**, 2 nút, **hộp thoại xác nhận lưu trữ**, tiêu đề bộ chọn kỳ. Số tiền vẫn đúng định dạng phân tách nghìn + đơn vị tiền tệ.
2. Về lại Tiếng Việt → đủ nhãn tiếng Việt như cũ.
3. Bật **cỡ chữ lớn nhất** (Cài đặt hệ thống) + màn hình nhỏ: màn Chi tiết **không vỡ bố cục**, không cắt chữ trong thẻ tiến độ và biểu đồ, **cuộn tới được 2 nút cuối màn** (SC-010).
4. Đổi giao diện **Tối** → nền/chữ/thanh tiến độ/biểu đồ đổi theo theme; teal = không vượt, coral = vượt/cảnh báo, nét đứt mốc giới hạn vẫn đọc được.

## N. Trường hợp biên khác

1. **Kỳ chưa có giao dịch Chi nào** → thẻ tiến độ hiện đã dùng `0 đ`, thanh tiến độ rỗng, **không** có số tiền vượt, nhóm giao dịch hiện trạng thái rỗng, **không** có băng cảnh báo.
2. **Vừa đúng 100%** (đã dùng = giới hạn) → huy hiệu hiện "Vượt 100%", **số tiền vượt = 0 đ**, thanh tiến độ đầy màu coral.
3. **Ngày cuối kỳ** → số ngày còn lại = `0` (không bao giờ âm).
4. **Số tiền lớn** (VD giới hạn `999.999.999`, đã chi hàng trăm triệu) → số hiển thị đúng định dạng phân nghìn, **không** tràn/cắt chữ trong thẻ tiến độ.
5. **Back hệ thống / vuốt back** ở màn Chi tiết → về màn Tổng quan Ngân sách; ở màn Sửa ngân sách → về màn Chi tiết, **giữ nguyên kỳ đang xem**.
6. **Ngân sách Tuần/Năm** → dòng phụ + bộ chọn kỳ + biểu đồ đều theo **đúng chu kỳ đó** (kịch bản 18).
7. **Không có mạng** → màn Chi tiết vẫn hiển thị đầy đủ (mọi số liệu tính từ dữ liệu trên thiết bị).

## Ghi nhận kết quả

**Lần 2** (2026-09-12 — **người dùng**, emulator Android): chạy trọn nhóm **A–N** ⇒ **ĐẠT toàn bộ**, gồm cả các nhóm Lần 1 chưa chạy (**H** Chỉnh sửa, **I** Lưu trữ, **L** giao dịch thay đổi, **M** English/cỡ chữ/dark mode, **K** danh mục bị xóa) và phần đối chiếu số tính tay **SC-003/SC-012**. **T033 hoàn tất.**

**Lần 1** (2026-09-12 — Claude, emulator `sdk gphone16k x86 64`, Android 17, dữ liệu sẵn từ QA PBI 20 gồm 3 ngân sách: *Mua sắm* Năm 260%, *Di chuyển* Tuần 84%, *Mua sắm* Tháng 65%). Đã xác minh **đường vàng + một số nhánh** (bảng dưới là bản ghi lần chạy đó).

| Nhóm | Kết quả | Ghi chú |
|---|---|---|
| A | ✅ phần chính | Chạm dòng *Mua sắm* → mở Chi tiết trong 1 lần chạm; app bar 2 dòng đúng mockup `03` ("Mua sắm" / "Ngân sách năm • Năm 2026") + nút đổi kỳ góc phải; **không** bottom nav; thứ tự thẻ tiến độ → băng cảnh báo → so sánh → giao dịch → 2 nút |
| B | ✅ phần chính | *Mua sắm* (260%): đã dùng **coral**, huy hiệu "Vượt 260%" nền coral nhạt, thanh đầy coral, "Vượt 800.000 đ" + "110 ngày còn lại". *Di chuyển* (84%): huy hiệu **"Sắp đạt 84%"** (không có chữ "Vượt"), "Còn lại 23.000 đ" + "1 ngày còn lại" (tuần 7–13/9, hôm nay 12/9 ⇒ đúng công thức gồm hôm nay — R6). **SC-003 (đối chiếu số tính tay): chưa chạy** |
| C | ✅ phần chính | *Mua sắm* Năm (70% ngày, 260% ngân sách) → băng **hiện** đúng "Đã dùng 70% ngày nhưng chi 260% ngân sách". *Di chuyển* (84% ngân sách < 85,7% ngày) → băng **ẩn** đúng nhịp. **N3/N4 (kỳ đã kết thúc, ngân sách chi chậm): chưa chạy** |
| D | ⚠ một phần | Mở bộ chọn kỳ thấy tiêu đề "Chọn kỳ", kỳ đang xem đánh dấu teal + dấu ✓. *Mua sắm* Năm chỉ có **1** lựa chọn ("Năm 2026") — đúng kịch bản 3 + biên "ngân sách mới trong kỳ hiện tại". **Chọn kỳ đã qua + SC-012: chưa chạy** (phủ bằng test tự động) |
| E | ✅ phần chính | Chú giải Dự kiến/Thực tế, đường mốc **nét đứt** "Dự kiến 500.000 đ"/"Dự kiến 143.000 đ", cột đôi có nhãn kỳ. Cột **Dự kiến** cùng màu trung tính ở mọi kỳ; cột **Thực tế** = coral khi vượt (*Mua sắm*) / **teal** khi chưa vượt (*Di chuyển*) — đúng FR-009. Nhãn trục theo chu kỳ: `T`-tháng vs `7/9` (Tuần) vs `2026` (Năm) — đúng kịch bản 18. Ngân sách 1 kỳ → **1 cặp cột**, không lỗi (kịch bản 19) |
| F | ✅ phần chính | Nhóm "GIAO DỊCH TRONG KỲ" + "Xem tất cả"; dòng có icon danh mục, tên (ghi chú / tên danh mục), thời gian dạng "Hôm nay, 15:08", số tiền coral. **Kỳ rỗng: chưa chạy** (phủ bằng test) |
| G | ✅ | Chạm "Xem tất cả" → sang tab **Giao dịch** đã lọc sẵn: thanh **"1 kết quả · Tổng: -120.000 đ"** khớp đúng "Đã dùng 120.000 đ" của thẻ tiến độ ⇒ **SC-005 đạt** (0 sai lệch). **Kỳ cũ + Bỏ lọc: chưa chạy** |
| H | ⚠ chưa chạy | Chỉnh sửa mở form điền sẵn / giữ kỳ đang xem — phủ bằng test tự động, **chưa thao tác tay** |
| I | ⚠ chưa chạy | **Lưu trữ làm thay đổi dữ liệu ngân sách trên emulator ⇒ không tự ý chạy**; cần người dùng xác nhận rồi QA (hủy/xác nhận, SC-007) |
| J | ✅ phần chính | *Mua sắm* Năm (đang chạy) mở đúng kỳ hiện tại. Nhánh "không lặp lại đã hết kỳ" phủ bằng test |
| K | ⚠ chưa chạy | Danh mục bị xóa — phủ bằng test tự động (module Danh mục chưa có xóa cứng) |
| L | ⚠ chưa chạy | Cập nhật khi giao dịch thay đổi — phủ bằng test tự động (FR-018/SC-008) |
| M | ⚠ chưa chạy | **Chưa đổi sang English trên máy.** Đã kiểm tra **tĩnh**: mọi literal tiếng Việt trong `budget_detail_screen.dart` đều gắn `.tr`/`.trParams` và `sora_translations_test` xanh ⇒ không có nhãn nào thiếu khóa EN. Cỡ chữ lớn / dark mode: chưa chạy |
| N | ⚠ chưa chạy | Biên kỳ rỗng / đúng 100% / số tiền lớn — phủ bằng test tự động + một phần qua *Di chuyển* 1 kỳ |

**Không còn việc QA nào tồn đọng** — Lần 2 đã phủ hết A–N.
