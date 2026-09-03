---
title: "Nguyên tắc nghiệp vụ"
date: 2026-09-03
tags: [concept, cross-cutting]
sources:
  - ../docs/wallet/nghiep-vu-vi-tai-khoan.md
  - ../docs/transaction/nghiep-vu-thiet-ke-quan-ly-giao-dich.md
  - ../docs/category/tinh-nang-nghiep-vu-quan-ly-danh-muc.md
  - ../docs/budget/nghiep-vu-ngan-sach.md
---

# Nguyên tắc nghiệp vụ

Các rule **xuyên module** — đọc trước khi thiết kế/triển khai bất kỳ entity nào. Nhiều ràng buộc quan trọng chỉ nằm trong `docs/`, không thấy ở scaffold code.

## Số liệu tài chính là đại lượng suy ra — không sửa tay
| Rule | Áp dụng |
|---|---|
| Số dư ví = `initial_balance + Σthu − Σchi ± Σtransfer`, tính real-time khi gd đổi, **không cho sửa trực tiếp** | [[Ví & Tài khoản]] |
| `initial_balance` bất biến sau khi phát sinh gd; muốn đổi → giao dịch "Điều chỉnh số dư" (`type=adjustment`, có ghi chú lý do) | [[Ví & Tài khoản]] |
| `actualSpent` ngân sách = snapshot tính lại (recompute) khi gd Chi trong phạm vi thay đổi | [[Ngân sách]] |
| Nhìn chung: lưu số "mốc ban đầu" + dữ liệu gốc (gd) → **tính** số hiện tại, không lưu số hiện tại sửa tay. | toàn app |

## Transfer nội bộ không phải thu/chi
- Chỉ đổi số dư 2 ví; không vào tổng thu/chi báo cáo, không gắn danh mục, không tính vào ngân sách.
- Sinh 2 bút toán liên kết (`transfer_group_id`) → sửa/xóa đồng bộ.
- Phí transfer = **khoản Chi riêng** (danh mục "Phí giao dịch") — ⚠ seed chưa có danh mục này ([[Danh mục]]).

## "Ẩn" thay vì "xóa" khi có lịch sử — pattern toàn app
- Xóa cứng **chỉ khi entity chưa từng có giao dịch**; đã có → ẩn/archive/gộp.
- **Ẩn** giữ lịch sử & báo cáo, chỉ loại khỏi chọn nhanh/tổng (có option).
- Lặp lại ở: ví (ẩn/xóa), danh mục (ẩn/gộp, hệ thống chỉ ẩn), ngân sách (archive > delete), ví trong `walletIds` ngân sách (gỡ chứ không xóa budget).
- Đi kèm màn hình undo: xóa/sửa gd → snackbar Undo ~5s ([[Giao dịch]]).

## Không hồi tố / khóa đổi khi đã có lịch sử
- Đổi `type` danh mục bị khóa khi đã gắn gd (tránh lệch báo cáo lịch sử).
- Đổi tiền tệ mặc định **không** đổi tiền tệ ví cũ; đổi `amount` budget giữa kỳ không hồi tố kỳ trước.
- Chung: dữ liệu lịch sử bất biến; thay đổi config chỉ ảnh hưởng dữ liệu mới.

## Tiền tệ & quy đổi (offline)
- Mỗi ví 1 currency (mặc định theo cài đặt, override riêng).
- Tổng hợp/báo cáo đa ví → quy đổi về tiền tệ mặc định theo tỷ giá **lưu sẵn/nhập tay** — offline, **không gọi API tỷ giá real-time**.
- Transfer khác currency: nhập tỷ giá tại thời điểm, **lưu lại** (`exchange_rate`), không tính lại sau.
- Gd chi ví khác currency → quy đổi tại thời điểm gd trước khi cộng `actualSpent` ngân sách.
- Ngân sách chỉ dùng tiền tệ mặc định người dùng (không chọn khác) — tránh sai lệch.

## Ràng buộc định danh & duy nhất
- Danh mục: 2 cấp, con cùng type cha, tên duy nhất trong nhóm `parent_id`+`type`.
- Ví mặc định: chỉ 1; xóa/ẩn → auto chuyển.
- Ngân sách: không chồng lấn 2 budget cùng `categoryId`+`period`; song song budget tổng + danh mục (2 góc nhìn) được phép.
- Gd gắn đúng 1 danh mục cùng type; transfer không danh mục.

## Giao diện ngữ nghĩa thu/chi
- Thu = **teal** `#0F6E56`, Chi = **coral** `#D85A30`, Transfer = **trung tính** — nhất quán mọi màn ([[Design system]]).
- Coral **chỉ** cho ngữ cảnh chi tiêu/cảnh báo, không trang trí — đảm bảo user liên tưởng thu/chi nhất quán.

## Liên kết
- [[Ví & Tài khoản]] [[Giao dịch]] [[Danh mục]] [[Ngân sách]] — nơi rule được áp dụng.
- [[Lộ trình phát triển]] — các quyết định mở nảy sinh từ mâu thuẫn giữa các rule trên.
