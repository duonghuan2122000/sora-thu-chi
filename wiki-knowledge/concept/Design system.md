---
title: "Design system"
date: 2026-09-13
tags: [concept, ui, design]
sources:
  - ../docs/design-system-app-thu-chi.md
  - ../docs/transaction/nghiep-vu-thiet-ke-quan-ly-giao-dich.md
  - ../docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md
  - ../docs/ai/tinh-nang-quet-hoa-don-ai-local.md
  - ../docs/logo/logo-concepts-sora-thu-chi.md
  - ../../.specify/specs/18/spec.md
  - ../../.specify/specs/24/spec.md
  - ../../.specify/specs/25/spec.md
  - ../docs/notification/03-trung-tam-thong-bao.svg
  - ../../.specify/specs/30/spec.md
---

# Design system

Material phẳng, app Flutter mobile quản lý thu chi. **Bảng đầy đủ (mọi hex/typography) nằm trong `../docs/design-system-app-thu-chi.md`** — page này là kernel + rule, mockup `.svg` trong `docs/` là chuẩn màn hình cụ thể.

## Nguyên tắc
- Phẳng, không đổ bóng nặng/gradient; mỗi màn hình **1 tác vụ chính**; ưu tiên dễ đọc số tài chính.
- **1 màu thương hiệu duy nhất (teal)** cho hành động chính + trạng thái chọn/bật. Coral **chỉ** chi tiêu/cảnh báo. Nền teal luôn đi kèm chữ trắng.
- Thu = teal, Chi = coral, Transfer = trung tính ([[Nguyên tắc nghiệp vụ]]).
- Bo góc: card `10px`, nút chính `8px` cao `44px`, FAB tròn `48–52px`, khung màn hình `24–28px`, nút tròn/avatar `50%`.
- Padding ngang màn `20–24px`; số tiền **căn phải**, phân tách nghìn dấu chấm + đơn vị `đ` (VD `42.500.000 đ`).

## Màu cốt lõi
| Vai trò | Mã |
|---|---|
| Teal thương hiệu (chính) | `#0F6E56` |
| Teal nhạt (nền nhấn/icon tròn) | `#E1F5EE` |
| Teal trung (avatar) | `#3D8C77` |
| Coral (chi tiêu/cảnh báo) | `#D85A30` |
| Chữ chính | `#1A1A1A` |
| Chữ phụ | `#5F5E5A` / `#6B6B6B` |
| Chữ mờ / tab chưa chọn / tiêu đề section | `#9B9B9B` |
| Viền / dot chưa nhập | `#B4B2A9` |
| Nền card thống kê nhanh | `#F1EFE8` |
| Đường kẻ phân cách | `#E0E0E0` / `#EFEFEF` |

**Mốc tiến độ ngân sách 80–99% — ĐÃ CHỐT (PBI 20)**: giữ hệ **2 màu gốc**, không thêm màu thứ ba — thanh tiến độ dùng **coral nhạt `#D85A30` ở `alpha 0.6`**, còn **%** vẫn coral đậm. Dưới 80%: thanh + % teal. Từ 100%: thanh coral đậm + % coral (màn `01` chỉ hiện %, màn `03` hiện thêm **số tiền vượt**). Chi tiết ở [[Ngân sách]].

**Biểu đồ ngân sách (PBI 21)** — không thêm token màu mới, tái dùng token hiện có:
- **Cột "Dự kiến"**: một **màu trung tính** cho **mọi** kỳ — `dotEmpty` (`#B4B2A9` light / `#6E6D66` dark) ở `alpha 0.5`. Cố ý **không** dùng teal/coral (2 màu đó đã mang nghĩa thu/chi).
- **Đường mốc giới hạn**: **nét đứt** `dashArray [3,3]` màu `dotEmpty`, nhãn "Dự kiến {giới hạn}" cỡ 9px.
- **Cột "Thực tế"**: **teal** khi kỳ đó không vượt, **coral** khi vượt (đúng quy tắc thu/chi). Chú giải (legend) vẽ 2 ô màu Dự kiến/Thực tế với ô "Thực tế" **coral** theo mockup `03`.
- Nhãn kỳ dưới trục `9–10px`, **kỳ đang xem in đậm + màu chữ chính**, kỳ khác chữ phụ.

**Bảng màu ĐỊNH TÍNH cho vòng tròn báo cáo (PBI 22) — token `SoraColors.chartPalette`** (6 phần tử, **đổi theo theme**):
- Light `[#0F6E56, #3D8C77, #E3B341, #6B7FD7, #B4B2A9, #5F5E5A]` · Dark `[#3FA98A, #4FB694, #E3B341, #8B9DEE, #A8A8A3, #C9C7BE]`. Phần tử **cuối** dành riêng cho nhóm "Khác" (`rank == -1` → chỉ số 5), 5 phần tử đầu theo **thứ hạng** danh mục.
- Doc §5 chốt bộ màu định tính (teal, teal đậm nhạt, hổ phách, xanh lam nhạt, xám) vì vòng tròn cần nhiều màu phân biệt; **tuyệt đối KHÔNG dùng coral** — coral đã mang nghĩa "chi tiêu/cảnh báo", dùng làm màu trang trí danh mục sẽ phá quy tắc.
- Màu gán **cố định theo hạng**, **không** lấy `Category.color` (nếu không, 2 danh mục cùng màu sẽ không phân biệt được và màu sẽ nhảy khi đổi kỳ).
- **Màn `02` Chi tiết theo danh mục (PBI 23) dùng CÙNG bảng màu nhưng lặp chu kỳ**: `chartPalette[rank % 5]` ⇒ danh mục thứ 6 trở đi **trùng màu** hạng 2, 3… (chốt 2026-09-12 — bảng màu vẫn 6 phần tử, **không** thêm màu mới, **không** coral); "Khác" vẫn là `chartPalette[5]`. Phân biệt các hạng trùng màu bằng **tên + thứ tự**. Chấm màu và thanh tiến độ của một dòng lấy từ **một** biến `rank` ⇒ luôn trùng màu lát cắt.
- Là **token theme** (không hex cứng trong widget) để đạt tương phản ở dark mode; `copyWith`/`lerp` lerp từng phần tử theo chỉ số (độ dài cố định 6).
- **Cột biểu đồ dòng tiền + 2 số tổng** thì ngược lại: vẫn dùng token teal/coral sẵn có (đúng nghĩa thu/chi), tô bằng `tealOnNeutral`/`coralOnNeutral`.

## Nhận diện thương hiệu — logo & splash (PBI 25)
> Nguồn: `docs/logo/logo-concepts-sora-thu-chi.md` (⚠ doc gợi ý Concept C cho icon — **quyết định thực tế khác**, xem dưới), `.specify/specs/25`. Sinh asset: `app/sora_thu_chi/tool/gen_brand_assets.dart`.

- **Một logo duy nhất cho mọi ngữ cảnh: Concept A "Coin Flow"** (đồng xu chia đôi — nửa trên teal + mũi tên lên = Thu, nửa dưới coral + mũi tên xuống = Chi, đường phân tách + 2 mũi tên trắng) dùng cho **cả icon launcher lẫn splash**, **thay** gợi ý "Concept C cho icon" trong doc gốc. Lý do: tránh nhảy hình icon → splash và giữ đúng thông điệp lõi Thu/Chi. Hệ quả chấp nhận: rủi ro 2 màu nhoè ở icon nhỏ là **rủi ro đã biết**, phải kiểm bằng mắt. Concept B/C không dùng.
- **Biến thể đưa vào sản phẩm** (2 thay đổi so với SVG concept):
  - **Vòng viền trắng quanh đồng xu**, dày `0.03 × D` — nếu không có, **nửa teal chìm vào nền teal** của splash/icon (mất cảm giác "đồng xu chia đôi").
  - **Nền icon teal đặc `#0F6E56`** — iOS cấm PNG icon trong suốt, và mask bo góc của Android sẽ lộ nền launcher nếu để trong suốt.
- **Tỉ lệ chốt** (D = đường kính coin): coin/icon = `0.68` (vùng an toàn adaptive icon) · coin/khung splash = `0.88` (lề 6% mỗi cạnh) · đường phân tách `0.021 × D` · mũi tên `0.05 × D` · vòng trắng `0.03 × D`. Không gradient/đổ bóng.
- **Splash 2 tầng, cùng nền teal + cùng cỡ logo `140dp`** để không "nhảy hình": tầng **native** (Android `launch_background.xml` + `values-v31` SplashScreen API cho Android 12+; iOS `LaunchScreen.storyboard`) rồi tầng **Flutter** (`PinGate` trong `lib/core/boot_gate.dart`).
  - **Ràng buộc Android 12+ (phát hiện khi QA emulator)**: `windowSplashScreenAnimatedIcon` bị hệ thống scale drawable lên (~277dp) rồi **cắt theo đường tròn** (~192dp) và **không** vẽ được path đường tròn viết dạng rút gọn (`a … 0 1 0 … Z` → ra rỗng). Hệ quả nếu dùng chung một drawable: **mất vòng viền trắng** (nửa teal chìm vào nền — đúng thứ FR-016 cấm) và logo to hơn tầng Flutter ⇒ nhảy hình. Vì vậy: vector **chỉ dùng cung tuyệt đối `A`**, và Android 12+ dùng **drawable riêng** (`splash_logo_masked.xml`, coin `0.44` khung) để logo hiện ra ≈ `123dp` khớp tầng Flutter.
- **Splash là NGOẠI LỆ thứ 2 về theme (cùng loại với màn chụp `scan-02`)**: nền/chữ dùng **màu bất biến** `AppColors.teal` / `AppColors.white`, **không** đọc `SoraColors.of(context)` ⇒ hiển thị **giống hệt** ở Sáng và Tối.
- **Nội dung splash chỉ có logo + tên "Sora Thu Chi" trắng**: không app bar, không bottom nav, không nút, không chỉ báo tải, không chữ phụ. Tên app là **tên thương hiệu, không dịch** theo ngôn ngữ.
- **Vòng đời**: splash hiện ở mỗi **cold start**, chờ song song PIN + giao diện + ngôn ngữ rồi **tự tắt** (trần **5 giây**); **không hiện lại khi resume** (`PinGate` bị gỡ khỏi stack). Kết thúc → màn khóa PIN nếu đã đặt, ngược lại màn thiết lập PIN (khóa app **bắt buộc lần đầu** — PBI 3, không phải Tổng quan).
- **Logo không xuất hiện trong nội dung app** (header, màn giới thiệu, trạng thái rỗng…) — nhận diện chỉ ở icon + splash.

## Luồng quét hóa đơn (PBI 24 — chặng 1)
> Mockup `docs/ai/scan-01…04`, `scan-10`, `scan-11`. Điểm vào: bottom sheet từ FAB.

- **Bottom sheet "Thêm giao dịch" (`scan-01`)** — thay điểm vào cũ (push thẳng form): 4 hàng *Khoản Thu / Khoản Chi / Chuyển khoản / Quét hóa đơn (AI)*, mỗi hàng có dòng mô tả; hàng quét mang **nhãn "MỚI"** và **chỉ hiện khi** tính năng đang bật.
- **Màn chụp `scan-02` — NGOẠI LỆ: nền TỐI CỐ ĐỊNH, không theo theme** (cố ý không đọc `SoraColors`) ⇒ ở giao diện Sáng vẫn là nền đen. Overlay **khung ngắm nét đứt 4 góc**; nút back / đèn flash / **Thư viện** / nút chụp tròn; dòng gợi ý *"Đặt hóa đơn vừa khung, tránh bóng đổ"*. **Không** hiển thị nút "Quét nhiều" của mockup (quét hàng loạt = GĐ2, khác biệt **đã chốt**).
- **Màn xử lý `scan-03`** — ảnh thu nhỏ + vệt quét, **4 bước** với 3 trạng thái (xong / đang chạy / chưa tới), dòng cam kết *"Không gửi dữ liệu lên bất kỳ máy chủ nào"*. Không đọc được chữ ⇒ thông báo + **"Chụp lại"** / **"Nhập tay"**.
- **Màn xác nhận `scan-04`** — `SubPageScaffold` app bar teal, **không** bottom nav; nút **"Lưu giao dịch"** cố định ở `bottomNavigationBar` + `SafeArea` (teal, bo `8px`, cao `44px`, **vô hiệu khi số tiền rỗng/≤ 0**). Ảnh gốc trong `InteractiveViewer`; chạm một trường ⇒ **khoanh vùng coral** trên ảnh (không xác định được vùng thì không khoanh).
- **Chỉ báo độ tin cậy (rule màu, đúng ngữ nghĩa cảnh báo)**: **cao → `tealOnNeutral`** · **trung bình → `textSecondary`** (xám) · **thấp/rỗng → `coralOnNeutral` + chữ "Kiểm tra lại"**. Banner cảnh báo trùng (cùng số tiền ±24h) dùng `coralLightBg` + chữ coral, **không chặn lưu**.

## Giao diện Sáng / Tối / Theo hệ thống — đã triển khai PBI 18
> Bộ đôi theme qua **`ThemeExtension<SoraColors>`** (không thêm dependency). Nguồn: `.specify/specs/18`, `docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md §1.2`.

**Nguyên tắc phân đôi token:**
- **Bất biến theo theme** (ở lại `AppColors`): teal thương hiệu `#0F6E56` (fill app bar/nút/FAB), **trắng on-brand** (icon/chữ đặt *trên* nền teal), coral `#D85A30` (fill chi/cảnh báo), bảng màu nhận diện danh mục/ví, avatar `#3D8C77`. Nền teal **luôn** đi kèm chữ trắng ở cả 2 giao diện.
- **Đổi theo theme** (chuyển vào `SoraColors`, đọc qua `SoraColors.of(context)`): nền màn/card, chữ chính/phụ, nhãn mờ, kẻ ngang, chấm rỗng radio, vòng nền nhạt icon, và **glyph** teal/coral khi nằm trên nền trung tính. Bản `SoraColors.light` **giữ nguyên giá trị cũ** — nhờ vậy giao diện sáng không đổi một ly và toàn bộ test widget so màu hằng cũ vẫn xanh.

| Vai trò | Light (= token cũ) | Dark |
|---|---|---|
| Nền màn / bottom nav | `#FFFFFF` | `#121212` |
| Card surface | `#FFFFFF` | `#1E1E1E` |
| Card beige / panel / ô nhập | `#F1EFE8` | `#242420` |
| Chữ chính | `#1A1A1A` | `#F2F2F0` |
| Chữ phụ | `#6B6B6B` | `#A8A8A3` |
| Nhãn mờ / tab chưa chọn | `#9B9B9B` | `#A8A8A3` |
| Label danh sách | `#5F5E5A` | `#B4B4AE` |
| Kẻ ngang | `#E0E0E0` / `#EFEFEF` | `#3A3A36` / `#2E2E2A` |
| Dot rỗng radio | `#B4B2A9` | `#6E6D66` |
| Vòng nền icon teal nhạt | `#E1F5EE` | `#17332C` |
| Vòng nền icon coral nhạt | `#FAECE7` | `#3A2518` |
| **Glyph** teal trên nền trung tính | `#0F6E56` | `#3FA98A` (sáng hơn) |
| **Glyph/chữ** coral trên nền trung tính | `#D85A30` | `#E8734C` (sáng hơn) |
| Fill teal / trắng on-brand / coral fill | (giữ) | (giữ nguyên) |

**Rule quan trọng — `white` có 2 vai trò** phải phân loại theo từng chỗ dùng, **không đổi tên máy móc**: làm **nền** → token nền (đổi ở dark); đặt **trên** teal/nền màu → giữ trắng. Ô tìm kiếm pill trên app bar teal (màn `05`) là "đảo sáng cố định" — giữ token light ở cả 2 giao diện.

**Phạm vi:** mọi màn/chrome sau mở khóa **và** màn khóa PIN đều đọc `SoraColors.of(context)` (SC-007: không vùng "chìm"), trừ: ảnh hóa đơn/avatar, nội dung người dùng nhập, bảng màu nhận diện danh mục/ví — **không đổi theo theme**. Màn `02` "Giao diện" chi tiết ở [[Hồ sơ & Bảo mật]].

**Ngoại lệ cố ý (cập nhật PBI 25)** — 2 màn **không** đọc `SoraColors`, giữ một bộ màu cố định ở cả 2 giao diện:
1. **Splash khởi động** (`PinGate`) — nền teal đặc + chữ trắng, xem §Nhận diện thương hiệu.
2. **Màn chụp hóa đơn `scan-02`** — nền tối cố định (PBI 24).

## So sánh kỳ — màn `03` Báo cáo (PBI 26)
- **Cặp chip kỳ**: chip **kỳ chính (trái)** = fill thương hiệu `AppColors.teal` + chữ trắng (đúng nghĩa "trạng thái chọn"); chip **kỳ đối chiếu (phải)** = `SoraColors.softCardBg` + chữ `listLabel` + **mũi tên nhỏ `Icons.expand_more`** làm chỉ báo bấm được — **khác biệt cố ý** so với mockup `03` (mockup vẽ chip phải như nhãn tĩnh). Nút hoán đổi ở giữa: tròn `28px`, icon `swap_horiz` màu `tabInactive`.
- **Cặp cột so sánh** (thẻ Thu nhập / Chi tiêu): `Container` rộng `36`, cao `64 × giá_trị / max` (cột lớn chiếm trọn `64`; cả hai `0` ⇒ **không** vẽ cột) — **không** dùng `BarChart` cho 2 cột tĩnh (mockup cũng vẽ bằng `rect` thường). Cột kỳ chính tô màu **loại giao dịch** (`tealOnNeutral` cho Thu / `coralOnNeutral` cho Chi); cột kỳ đối chiếu `dotEmpty` alpha `0.5`.
- **Badge %**: chữ `w700`, màu theo **ý nghĩa tốt/xấu** (Thu tăng / Chi giảm = `tealOnNeutral`; ngược lại = `coralOnNeutral`); `0%` để màu `textSecondary`, **không** mũi tên; kỳ đối chiếu rỗng ⇒ **ghi chú chữ** thay badge (không chia 0).
- **Nền thẻ**: `softCardBg` bo `10` (giống thẻ màn `01`), thẻ Nhận xét `coralLightBg` + icon `error_outline` coral. **Khác biệt cố ý** với mockup `03` (vẽ thẻ nền trắng + viền `#EFEFEF`): repo **không có token** cho cặp trắng-viền đó, dùng token sẵn có để dark mode đúng mà **không** thêm token mới.
- **Biểu đồ xu hướng**: `fl_chart` **`LineChart`** — kỳ trái nét **liền** `tealOnNeutral`, kỳ phải nét **đứt** `dashArray: [4, 3]` màu `tabInactive`; chỉ bật **trục hoành** (3 nhãn: `1` / giữa kỳ / ngày cuối — `interval: 1` + hàm nhãn tự ẩn mọi mốc khác), **không** trục tung, **không** lưới, đường đáy `divider`; chấm (`FlDotData`) **ẩn**, không `isCurved`.

## Xuất báo cáo — màn `04` Báo cáo (PBI 27)
- **Hai icon trên vùng tiêu đề màn `01`**: nút tròn `48px`, icon trắng (`Icons.ios_share` cho xuất, `Icons.compare_arrows` cho so sánh) cạnh nhau trong `ScreenHeader.trailing`. Ô `trailing` của `ScreenHeader` nay **rộng theo nội dung** (trước đây cố định `48px`) để chứa 2 nút mà tiêu đề tự co lại — một nút vẫn ra đúng bề rộng cũ.
- **Chip chọn lọc** (ví/danh mục, cả màn `04`): `Container` bo `15`, cao `30`, đệm ngang `14`; **đang chọn = fill `AppColors.teal` chữ trắng `w600`**, chưa chọn = `softCardBg` chữ `listLabel`; tên dài cắt ellipsis (tối đa `140`). Chip `Tất cả` là trạng thái "không giới hạn"; phần danh mục vượt 3 chip gộp vào chip `+N khác` mở bottom sheet.
- **Thẻ định dạng xuất** (3 thẻ ngang hàng, `Row` + `Expanded`): nền `surface` bo `10`; **đang chọn viền `2px` `AppColors.teal` + `Icons.check_circle` teal góc phải trên**, chưa chọn viền `1px` `divider`; bên trong là bubble icon `32px` (`tealLightBg` khi chọn / `softCardBg` khi không) + nhãn định dạng (**không** dịch) + dòng chú thích (**có** dịch).
- **Ô ngày** (`Từ ngày`/`Đến ngày`): nền `softCardBg` bo `8`, nhãn nhỏ `10` + giá trị `dd/MM/yyyy` `w600`; **ô tag** dùng cùng nền `softCardBg` bo `8`, viền `none`.
- **Hộp tóm tắt**: nền `softCardBg` bo `10`, 2 dòng (số giao dịch + khoảng ngày; định dạng + chú thích).
- **Dòng cảnh báo** (FR-028): nền `coralLightBg` bo `10` + `Icons.warning_amber_rounded` **coral** — dùng coral đúng ngữ nghĩa "cảnh báo" (không phải chi tiêu); **hiển thị sẵn**, **không** hộp thoại xác nhận. Thông báo "bộ lọc rỗng" dùng chữ `coralOnNeutral`.
- **Nút `Xuất báo cáo`**: teal đặc bo `8` cao `46`, chữ trắng; trạng thái vô hiệu hoá = teal alpha `0.4` (`onPressed: null` khi 0 giao dịch hoặc đang dựng tệp).

## Thông báo & nhắc nhở — màn cài đặt (PBI 28)
- **Hai sắc icon trong CÙNG một màn** (lần đầu áp quy tắc "coral chỉ cho ngữ cảnh cảnh báo/chi tiêu" ở cấp **hàng**, không phải cấp màn): hàng thuộc nhóm **NGÂN SÁCH** (2 hàng) dùng vòng tròn `coralLightBg` + glyph `coralOnNeutral`; **6 hàng còn lại** dùng `tealLightBg` + `tealOnNeutral`. **Không** thêm token màu nào — chỉ đọc token sẵn có của cả 2 theme.
- **Hàng danh sách**: khuôn màn Tiện ích — vòng tròn `36px` + glyph `20px`, cột giữa `Expanded` (tiêu đề `maxLines: 1` + ellipsis, dòng phụ `12px` **wrap tự nhiên**), `trailing` **ngoài** `Expanded`. Nhãn nhóm viết hoa `13 w600` màu `tabInactive`, padding `(20, 24, 20, 8)`.
- **Đường kẻ**: `Divider(color: listDivider, height: 1)` chỉ chèn **giữa các hàng trong nhóm** (không sau hàng cuối, không trước nhãn nhóm) — bám khuôn code, mockup `01` vẽ không nhất quán.
- **Công tắc**: `Switch` Material mặc định, màu từ `ColorScheme` seed teal — **không** thêm `switchTheme` (đồng nhất 2 công tắc PBI 17 + công tắc quét PBI 24); QA theme tối kiểm tương phản.
- **Icon theo nhóm** (Material sẵn có): `notifications_none` (nhắc hàng ngày) · `warning_amber_rounded` (2 hàng Ngân sách) · `event_outlined` (2 hàng định kỳ) · `track_changes` (mục tiêu) · `pie_chart_outline` (2 hàng tổng kết) · `chevron_right` (trailing 2 hàng điều hướng).
- **Giờ hiển thị `HH:mm` 24h** qua `formatClock(hour, minute)` trong `lib/core/date_label.dart` (tái dùng `_two`; `formatTimeLabel` nay gọi lại nó) — giờ/số/% **không** dịch theo ngôn ngữ.

## Nhắc nhập giao dịch — màn `02` (PBI 29)
- **Khối chọn giờ/phút tự dựng, KHÔNG trục cuộn**: `Container(softCardBg, bo 10)` chứa `Row` 2 `_TimeColumn` ngăn bởi `Text(':')` `24 w600`. Mỗi trục = `IconButton(▲/▼, màu listLabel)` + lân cận `15` `tabInactive` + **ô giá trị đang chọn** (`Container` bo `6`, nền `tealOnNeutral` alpha `0.10`, chữ `26 w600` màu `tealOnNeutral`) + lân cận. **Số pad 2 chữ số** (`_pad`), lân cận quay vòng theo miền. Chọn cách này thay mockup vẽ **một dải liền** chạy qua dấu `:` vì dải liền cần toạ độ cứng ⇒ vỡ ở cỡ chữ lớn.
- **`FittedBox(fit: scaleDown)` bọc khối thời gian** — bề rộng 2 trục cố định theo thiết kế; ở `textScaleFactor 2.0` nội dung là ~369px trong 280px khả dụng ⇒ tràn `89px`. Thu nhỏ cả khối (không cắt chữ) là cách duy nhất giữ nguyên hình mockup; ở cỡ chữ chuẩn `FittedBox` **không** phóng to nên hình không đổi.
- **Chip ngày tròn 36px tự vẽ, KHÔNG `ChoiceChip`** (mockup là vòng tròn **đặc** đổi màu; `ChoiceChip` có pill/checkmark/padding riêng ⇒ lệch hình): chọn = `AppColors.teal` + chữ `AppColors.white`; không chọn = `colors.surface` + viền `colors.divider` + chữ `colors.tabInactive`; nhãn `12 w600` bọc **`MediaQuery.withClampedTextScaling(maxScaleFactor: 1.4)`** để 7 chip vẫn đủ chỗ một hàng ở 360px (`7×36 + 6×10 = 312`); `Wrap(spacing: 10, runSpacing: 10)` cho phép xuống hàng ở màn hẹp. Chip đang chọn dùng **fill teal bất biến** (không đổi theo theme) — ngoại lệ có chủ ý, QA theme tối kiểm tương phản.
- **Thẻ "Xem trước thông báo"**: `Container` bo `10` **viền `divider`** (không phải `softCardBg` — đây là mô phỏng một thẻ thông báo hệ thống) + vòng `28px` `tealLightBg` chữ **`'S'`** `tealOnNeutral` (không dùng ảnh logo: logo PBI 25 thiết kế cho nền teal kèm vòng trắng ⇒ lệch hệ màu trên nền nhạt) + cột `Expanded` (tên app **không dịch** + câu nội dung dịch) + giờ `formatClock` `10` `tabInactive` căn phải.
- **Hai vùng chạm trên một hàng** (màn `01`, lần đầu trong app): vùng chạm = **cụm icon + khối tiêu đề/dòng phụ**, `trailing` (công tắc) **ngoài** mọi `InkWell` ⇒ chạm công tắc **không** mở màn. Đổi ở **`_itemRow` dùng chung** (một chỗ) nên 2 hàng chevron cũng mất phản hồi mực đúng ở icon chevron — **hành vi "chạm không mở gì" không đổi**.
- **Nút chính ghim đáy** giữ nguyên khuôn 5 màn form đã có: `SizedBox(height: 44)` + `ElevatedButton` `AppColors.teal` / chữ trắng / `elevation: 0` / bo `8` / chữ `15 w600`; `key: ValueKey('save-primary')`.
- **Nhãn màn `02`**: nhãn nhóm viết hoa `13 w600` `tabInactive` khuôn màn `01`; nhãn ngày **`T2`…`CN`** sinh từ `dayLabel(int)` (`switch` **literal trước `.tr`** để `sora_translations_test` ràng buộc được — gom vào `const List` sẽ **lọt lưới** test dịch); EN `Mon…Sun`, giờ `HH:mm` và tên app **không** dịch.

## Trung tâm thông báo — màn `03` + chuông Tổng quan (PBI 30)
- **Hàng 2 tab tự vẽ, KHÔNG `TabBar`/`TabController`** (mockup là **gạch chân**, không pill): `Row` 2 `GestureDetector(opaque)`; mỗi tab = `Container` có `border: Border(bottom: BorderSide(color: teal | transparent, width: 2))` ⇒ **gạch chân rộng đúng theo chữ** (mockup đo theo "Tất cả"), nhãn `13` (`AppColors.teal` w600 khi chọn / `colors.tabInactive` w500 khi không), cách nhau `24`; dưới cùng `Container(height: 1, color: listDivider)`. **Bọc `FittedBox(scaleDown)`** cả hàng tab — ở cỡ chữ 2.0 hàng tab tràn `52px` (khuôn `_HeaderSummary` màn Báo cáo).
- **Mục danh sách** = `Row(crossAxisAlignment: start)`: **chấm 8px** `AppColors.teal` **chỉ khi chưa đọc** (đã đọc vẫn chiếm đúng 8px ⇒ hàng không xô lệch; canh vào tâm vòng tròn bằng `padding top 14`) → `SizedBox(8)` → **vòng tròn `36px`** nền `tealLightBg`/`coralLightBg` + glyph `20px` `tealOnNeutral`/`coralOnNeutral` → `SizedBox(12)` → `Expanded`. Kẻ `Divider(listDivider, height: 1, indent/endIndent: 20)` sau **mỗi** mục.
- **Đọc vs chưa đọc khác nhau ở CẢ chấm LẪN chữ** (FR-005): chưa đọc = tiêu đề `textPrimary` w600 + mô tả `textSecondary`; đã đọc = tiêu đề `listLabel` w400 + mô tả `tabInactive`. Nhãn thời gian `11` `tabInactive` nằm **ngoài `Expanded`** (cùng hàng tiêu đề); dòng mô tả **wrap tự nhiên, không `maxLines`** (số liệu không bị cắt).
- **Coral vẫn chỉ ở ngữ cảnh cảnh báo** (FR-006/FR-015): trong 5 loại thông báo, **duy nhất** `budgetAlert` dùng vòng `coralLightBg` + glyph `coralOnNeutral`; 4 loại còn lại teal. Bộ icon bám màn `01` PBI 28 (`notifications_none` / `warning_amber_rounded` / `event_outlined` / `track_changes` / `pie_chart_outline`).
- **Nhãn thời gian 3 dạng** (không đổi theo ngôn ngữ, trừ tên thứ): cùng ngày → `HH:mm` (`formatClock`); 1…7 ngày → **tên thứ đầy đủ** `Thứ Hai`…`Chủ Nhật` (`weekdayName(int)` mới ở `date_label.dart`, `switch` **literal trước `.tr`** — EN `Monday`…`Sunday`); cũ hơn → `dd/MM`. Nhãn nhóm `HÔM NAY / TUẦN NÀY / TRƯỚC ĐÓ` viết hoa `11 w600` `tabInactive`, padding `(20, 20, 20, 8)`, **nhóm rỗng không vẽ**.
- **Trạng thái rỗng 2 câu khác nhau** (FR-011): icon `notifications_none` `44` `tabInactive` + câu chính `16 w600` `textPrimary` + câu phụ `13` `tabInactive`; lịch sử rỗng → "Chưa có thông báo nào"/"Thông báo và nhắc nhở sẽ hiện ở đây."; tab "Chưa đọc" rỗng → "Không có thông báo chưa đọc"/"Bạn đã đọc hết thông báo.".
- **Chuông màn Tổng quan** ở `ScreenHeader.trailing` (nút tròn `48px`, icon `notifications_none` `24` `AppColors.white`, `Tooltip('Thông báo')`) — **luôn bấm được** kể cả lịch sử rỗng/lỗi đọc. **Chấm chưa đọc = `AppColors.coral` viền trắng `2px`**, `9px`, `Positioned(top: 10, right: 10)` — **ngoại lệ cố ý**: spec viết "chấm đỏ" nhưng bảng màu dự án **không có token đỏ**, và chấm nằm **trên nền teal** nên viền trắng là bắt buộc để đủ tương phản (thêm token đỏ = mở rộng DS cho một chấm 9px). Muốn đỏ thật ⇒ thêm 1 hằng số, đổi 1 dòng.

## App shell & layout
- **Bottom nav 5 vị trí**: Tổng quan | Giao dịch | **FAB "Thêm giao dịch" nổi giữa** (nhô lên, hình tròn teal, icon + trắng — hành động lõi) | Báo cáo | Cài đặt.
- Tab chọn: icon + label teal (in đậm); chưa chọn: xám `#9B9B9B`.
- Loại màn hình:
  - **Màn chính**: header/teal chứa tiêu đề + số liệu tổng + nội dung cuộn + bottom nav.
  - **Sub-page** (từ Cài đặt): app bar teal + nút back, tiêu đề trắng; **không** bottom nav.
  - **Màn bảo mật** (khóa PIN/sinh trắc): toàn màn hình, không app bar/bottom nav — độc lập, chạy trước khi vào app.
  - **Màn chụp hóa đơn** (`scan-02`): nền **tối cố định** ngoài hệ theme (xem §Luồng quét hóa đơn).
- Settings list: nhóm section (tiêu đề nhỏ viết hoa xám nhạt), dòng `ListTile` + đường kẻ mảnh.
- Numpad (PIN): lưới `3×4`, nút tròn ~48–52px viền mảnh không nền; dot indicator ~12px (đặc teal / rỗng xám).

## Typography
| Cấp | Size | Độ đậm |
|---|---|---|
| Số liệu lớn / số tiền chính | 22–24px | 600 |
| App bar / tiêu đề màn | 15–16px | 600 |
| Nội dung chính / nút | 13–14px | 400–600 |
| Phụ đề / mô tả | 11–12px | 400 |
| Nhãn nhỏ / section header | 9–11px | 400–600, viết hoa |

Font sans-serif hệ thống (Roboto Android). Numpad nhập số tiền (màn thêm gd) tái dùng phong cách numpad khóa PIN + dấu thập phân & backspace.

## Component
| Thành phần | Style |
|---|---|
| Nút chính | Teal đặc, chữ trắng, bo `8px`, cao `44px` |
| Nút phụ | Trắng, viền `#E0E0E0`, chữ đen, bo `8px` |
| FAB | Tròn `48–52px`, teal, icon trắng, nổi trên nav |
| Toggle/Switch | Pill; teal khi bật + chấm tròn trắng phải; xám khi tắt |
| Avatar | Tròn, teal trung, chữ viết tắt trắng / ảnh thật |
| Card thống kê nhanh | Nền `#F1EFE8`, bo `10px`, icon + label + giá trị phải |
| Chips (lọc/tab segment) | Chọn = nền teal chữ trắng; chưa chọn viền `#E0E0E0` chữ `#5F5E5A` |

## Icon
Outline (line) mảnh, độ dày đồng nhất; màu ngữ cảnh (teal hành động / coral chi / xám trung tính). DS: ~15–16px; trong vòng tròn lớn: ~28–32px trong khối 44–64px.

## Triển khai trong code (rule)
- **Cấu hình style chung của app gom tại 1 nơi duy nhất** — file/class theme trung tâm (Flutter: `AppTheme` + `ThemeData`) + file hằng số token cho màu, kích thước (bo góc, cao nút, padding/spacing, cỡ icon, cỡ chữ), ánh xạ đúng bảng giá trị ở các mục trên (teal `#0F6E56` = token thương hiệu, nút cao `44px`/bo `8px` = token kích thước...).
- Widget **không nhúng hex hoặc số cứng** rải rác; chỉ đọc token từ nơi tập trung. Muốn đổi style toàn app → sửa đúng 1 chỗ, không quét tìm từng widget.
- **Token màu tách 2 file** (PBI 18): `AppColors` = màu **bất biến**; `SoraColors` (ThemeExtension, `.light`/`.dark` + `SoraColors.of(context)`) = màu **đổi theo theme**. `AppTheme.themeData`/`darkThemeData` đăng ký extension tương ứng.
- Theme/token độc lập layer nghiệp vụ — đọc thêm [[Stack kỹ thuật]].

## Liên kết
- [[Ví & Tài khoản]] [[Giao dịch]] [[Danh mục]] [[Ngân sách]] [[Báo cáo]] — màn hình cụ thể mỗi module.
- [[Hồ sơ & Bảo mật]] — màn khóa PIN tách shell, numpad.
- [[Nguyên tắc nghiệp vụ]] — quy tắc màu thu/chi.
