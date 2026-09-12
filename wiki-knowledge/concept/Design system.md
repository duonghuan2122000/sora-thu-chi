---
title: "Design system"
date: 2026-09-03
tags: [concept, ui, design]
sources:
  - ../docs/design-system-app-thu-chi.md
  - ../docs/transaction/nghiep-vu-thiet-ke-quan-ly-giao-dich.md
  - ../docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md
  - ../../.specify/specs/18/spec.md
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

**Phạm vi:** mọi màn/chrome sau mở khóa **và** màn PIN/boot đều đọc `SoraColors.of(context)` (SC-007: không vùng "chìm"), trừ: ảnh hóa đơn/avatar, nội dung người dùng nhập, bảng màu nhận diện danh mục/ví — **không đổi theo theme**. Màn `02` "Giao diện" chi tiết ở [[Hồ sơ & Bảo mật]].

## App shell & layout
- **Bottom nav 5 vị trí**: Tổng quan | Giao dịch | **FAB "Thêm giao dịch" nổi giữa** (nhô lên, hình tròn teal, icon + trắng — hành động lõi) | Báo cáo | Cài đặt.
- Tab chọn: icon + label teal (in đậm); chưa chọn: xám `#9B9B9B`.
- Loại màn hình:
  - **Màn chính**: header/teal chứa tiêu đề + số liệu tổng + nội dung cuộn + bottom nav.
  - **Sub-page** (từ Cài đặt): app bar teal + nút back, tiêu đề trắng; **không** bottom nav.
  - **Màn bảo mật** (khóa PIN/sinh trắc): toàn màn hình, không app bar/bottom nav — độc lập, chạy trước khi vào app.
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
