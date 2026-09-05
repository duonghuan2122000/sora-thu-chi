---
title: "Giao dịch"
date: 2026-09-03
tags: [module, transaction, entity]
sources:
  - ../docs/transaction/nghiep-vu-thiet-ke-quan-ly-giao-dich.md
  - ../docs/wallet/nghiep-vu-vi-tai-khoan.md
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
---

# Giao dịch

Nhóm nghiệp vụ **trung tâm thao tác** (tần suất cao nhất) → gắn FAB giữa bottom nav ([[Design system]]). Ghi nhận Thu / Chi / Chuyển khoản nội bộ.

## Mô hình (drift — đặc tả trong wallet doc)
`transactions`: `id, wallet_id, type(income/expense/transfer/adjustment), amount, category_id, note, tags, receipt_image, location, transaction_date, transfer_group_id(null), exchange_rate(null)`.
- `type` gồm cả `adjustment` (điều chỉnh số dư — sinh từ nghiệp vụ ví, xem [[Ví & Tài khoản]]), không nằm trong 3 loại giao diện.
- `transfer_group_id` liên kết 2 dòng của 1 lần transfer (xóa/sửa đồng bộ).
- `exchange_rate` lưu tỷ giá khi transfer/đa tiền tệ tại thời điểm gd.

## Thêm giao dịch
- Segmented tab `Chi | Thu | Chuyển khoản`, **mặc định mở "Chi"**.
- Bắt buộc: Số tiền (>0, numpad có phân cách nghìn tự động), Danh mục, Ví, Ngày giờ (default = now). Tùy chọn: ghi chú, tag, ảnh hóa đơn, vị trí GPS.
- Transfer: thay Danh mục bằng cặp Ví nguồn → đích; không tính thu/chi; validate nguồn ≠ đích + cảnh báo mềm âm quỹ.
- **Quick Add**: chỉ Số tiền + Danh mục + Ví (default = lần nhập gần nhất); gọi từ widget/notification.
- "Lưu & tiếp tục" (snackbar "Thêm giao dịch khác") — nhập chuỗi nhiều khoản.
- Danh mục phải **cùng type** với giao dịch; transfer **không gắn danh mục** ([[Danh mục]]).

## Sửa / xóa / nhân bản
- Sửa: mở lại màn Thêm với data điền sẵn, tiêu đề "Sửa giao dịch".
- Xóa: dialog xác nhận → snackbar **Undo ~5s** trước xóa vĩnh viễn.
- Sửa/xóa trong chuỗi định kỳ → hỏi phạm vi "Chỉ giao dịch này" / "Toàn bộ chuỗi từ đây".
- **Nhân bản** (Duplicate): bản sao ngày = now, mở màn sửa trước khi lưu — cho khoản chi lặp không đều đặn (khác recurring).

## Định kỳ (Recurring — GĐ2)
- Cấu hình: loại, số tiền (có thể trống nếu đổi mỗi kỳ), danh mục, ví, chu kỳ (ngày/tuần/tháng/năm + mốc, VD "ngày 25 hằng tháng"), ngày bắt đầu/kết thúc, nhắc trước N ngày.
- Tự sinh giao dịch đúng chu kỳ; gd sinh ra đánh dấu nguồn gốc "định kỳ" (icon riêng).
- Nhắc push trước hạn N ngày + xác nhận nhanh "Đã thu/chi" từ notification.
- Danh sách chuỗi có toggle Bật/Tắt nhanh (không xóa config).

## Tìm / lọc / sắp xếp — **đã triển khai (PBI 12)**

Màn con **"Tìm kiếm & Lọc"** (`05-tim-kiem-loc.svg`), toàn màn hình đè shell (không bottom nav): app bar teal = back + **ô tìm kiếm pill** trắng. Là **form trên bản nháp**: **Áp dụng** → trả bộ lọc về màn danh sách, **back/X** → giữ tập cũ; "Đặt lại" reset nháp về mặc định **Tháng này** (không pop).

- **Từ khóa** (ghi chú/tên danh mục/tag): **bỏ dấu tiếng Việt** tự viết (không thêm package) — "an uong" ↔ "Ăn uống", substring, debounce ~250ms.
- **Chip loại 4 nút** Tất cả / Thu / Chi / Chuyển khoản (không có chip "Điều chỉnh" — `adjustment` chỉ xuất hiện dưới Tất cả).
- **Lọc nâng cao** (5 dòng, mỗi dòng mở bottom sheet): **Khoảng thời gian** preset Hôm nay/Tuần này (thứ Hai đầu tuần)/Tháng này/Toàn bộ + "Tùy chọn…" (2 date picker chặn start>end); **Danh mục** multi chọn theo **loại chip** (Tất cả → thu+chi, Thu/Chi → đúng loại; chip Chuyển khoản → dòng **vô hiệu**), chọn cha **tự gộp con**; **Ví** một hoặc "Tất cả các ví" (gồm ví ẩn — xem lịch sử); **Khoảng số tiền** Từ–Đến theo `abs(amount)` **bao biên**, mỗi ô mở keypad (`AmountKeypad`), trống một đầu = bỏ giới hạn đầu đó, **min > max → báo đỏ + vô hiệu Áp dụng**; **Sắp xếp** 4 option Ngày mới nhất (mặc định)/Ngày cũ nhất/Số tiền tăng/giảm dần.
- **Tổng hợp điều kiện = AND**; mọi tổ hợp không tạo/mất/sửa giao dịch (chỉ đọc, không đổi schema).

**2 lựa chọn hiển thị do user chốt (đã triển khai, ghi PBI 12):**
- **R4 — sort tiền thì danh sách phẳng** (không header ngày), xếp theo `abs(amount)`; sort ngày thì giữ nhóm ngày như list thường (đảo nhóm & dòng cho "Ngày cũ nhất").
- **R5 — khi đang lọc, card "Thu/Chi tháng này" ẩn**, thay bằng thanh `N kết quả · Tổng: X đ` + nút **"Bỏ lọc"** (về toàn bộ). Hết lọc → card tháng hiện lại.

**Dòng tóm tắt `N kết quả · Tổng: X đ`** (live khi gõ/chip; thống kê cả form lẫn thanh danh sách dùng chung 1 hàm thuần): `N` = số dòng **sau gộp transfer**; `Tổng` = Σ thu − Σ chi (transfer/adjustment có trong N nhưng **không vào Tổng**). Giao dịch transfer cùng `transfer_group_id`: tiêu chí khớp 1 vế → **giữ cả 2 vế** (để gộp 1 dòng, không tách cặp khi lọc Ví). Tập rỗng → "0 kết quả"; danh sách sau Áp dụng hiện "Không có giao dịch khớp bộ lọc." (khác empty "Chưa có giao dịch nào." khi không lọc).

**Kỹ thuật**: bộ lọc sống trong `TransactionController` (`activeFilter` + view đã lọc), **bền qua ra/vào tab**; màn lọc là Stateful với repository inject (seam PBI 11) + `now` anchor. Lọc **trong bộ nhớ** trên tập `allTransactions` cache (mỗi `load()` 1 lần), không SQL pushdown — giữ đúng gộp transfer. Không đổi schema/repository; không `build_runner`. Dòng giao dịch cũ chưa có `category_id` vẫn lọc được theo **tên danh mục** (fallback — giữ lịch sử, xem [[Danh mục]]).

## Import / OCR (ngoài lộ trình chính)
- Import CSV/Excel: chọn file → map cột → preview → xác nhận → báo cáo lỗi. Danh mục chưa có → tạo mới hoặc map "Khác".
- OCR quét hóa đơn: điền sẵn form để người dùng xác nhận — **không tự lưu** (tránh sai sót OCR). Xem [[Lộ trình phát triển]].

## Màu theo loại (ràng buộc thiết kế riêng)
| Loại | Màu |
|---|---|
| Thu | Teal `#0F6E56` (số tiền + mũi tên lên) |
| Chi | Coral `#D85A30` (số tiền + mũi tên xuống) |
| Transfer | Trung tính (chữ chính + icon 2 mũi tên xám) — tránh nhầm với thu/chi |

## Màn hình
| File | Loại |
|---|---|
| `01-danh-sach-giao-dich.svg` | Màn chính (header teal + bottom nav) — card thu/chi tháng này |
| `02-them-giao-dich.svg` | Full-screen modal (segmented + numpad) |
| `03-chon-danh-muc.svg` | Sub-page — lưới 4 cột icon tròn |
| `04-chi-tiet-giao-dich.svg` | Sub-page — tóm tắt + menu Sửa/Xóa/Nhân bản |
| `05-tim-kiem-loc.svg` | Sub-page — ô search + chip lọc nhanh |
| `06-giao-dich-dinh-ky.svg` | Sub-page — form + DS chuỗi toggle |

## Liên kết
- [[Ví & Tài khoản]] — Transfer, adjustment, phí transfer.
- [[Danh mục]] — gắn 1 danh mục cùng type; transfer không danh mục.
- [[Ngân sách]] — gd Chi tính vào budget theo categoryId/subcategory + ví.
