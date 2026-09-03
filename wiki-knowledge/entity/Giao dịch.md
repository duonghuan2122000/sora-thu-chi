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

## Tìm / lọc / sắp xếp
- Tìm từ khóa (ghi chú, tên danh mục, tag) — debounce.
- Lọc kết hợp: loại, khoảng thời gian (preset/tùy chỉnh), danh mục (multi), ví, khoảng tiền, tag.
- Sắp xếp: ngày / số tiền. Hiển thị số kết quả + tổng tiền khớp bộ lọc.

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
