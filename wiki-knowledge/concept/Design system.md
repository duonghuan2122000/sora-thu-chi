---
title: "Design system"
date: 2026-09-03
tags: [concept, ui, design]
sources:
  - ../docs/design-system-app-thu-chi.md
  - ../docs/transaction/nghiep-vu-thiet-ke-quan-ly-giao-dich.md
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

⚠ QUYẾT ĐỊNH MỞ: mốc tiến độ budget 80–99% chưa có màu trong hệ — gợi ý coral nhạt (opacity) để giữ 2 màu gốc. Xem [[Ngân sách]] và [[Lộ trình phát triển]].

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

## Liên kết
- [[Ví & Tài khoản]] [[Giao dịch]] [[Danh mục]] [[Ngân sách]] — màn hình cụ thể mỗi module.
- [[Hồ sơ & Bảo mật]] — màn khóa PIN tách shell, numpad.
- [[Nguyên tắc nghiệp vụ]] — quy tắc màu thu/chi.
