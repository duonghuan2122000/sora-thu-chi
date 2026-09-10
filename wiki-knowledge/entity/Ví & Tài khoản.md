---
title: "Ví & Tài khoản"
date: 2026-09-03
tags: [module, wallet, entity]
sources:
  - ../docs/wallet/nghiep-vu-vi-tai-khoan.md
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
---

# Ví & Tài khoản

Thùng chứa tiền; mỗi ví gắn **1 loại** + **1 tiền tệ**. Giao dịch (thu/chi/chuyển) ghi nhận trên ví; số dư ví là đại lượng **suy ra**, không sửa tay (xem [[Nguyên tắc nghiệp vụ]]).

## Loại ví & đặc thù xử lý
| Loại | Đặc thù |
|---|---|
| Tiền mặt | Số dư điều chỉnh tự do (có thể âm tạm) |
| Tài khoản ngân hàng | Nhãn ngân hàng tham chiếu, chỉ hiển thị số cuối (không lưu số thật) |
| Thẻ tín dụng | Thêm: hạn mức, ngày sao kê, ngày đến hạn → hiển thị "Đã dùng / Hạn mức" + % sử dụng, cảnh báo gần chạm hạn mức |
| Ví điện tử (Momo, ZaloPay...) | Như ngân hàng + icon thương hiệu |
| Sổ tiết kiệm | Thêm: kỳ hạn, ngày đáo hạn, lãi suất (tùy chọn); chỉ theo dõi, không chi tiêu trực tiếp |

## Trường dữ liệu & mô hình (drift)
`wallets`: `id, name, wallet_type(enum), icon, color, initial_balance, currency, is_default, is_hidden, sort_order, credit_limit/statement_date/due_date (thẻ tín dụng), term_months/maturity_date (sổ tiết kiệm), created_at, updated_at`.
- `initial_balance` **bắt buộc khi tạo, bất biến sau đó** — điều chỉnh phải qua giao dịch "Điều chỉnh số dư" (type `adjustment`), có ghi chú lý do.
- `is_default`: chỉ **1 ví** mặc định tại một thời điểm.
- `is_hidden`: ẩn = giữ lịch sử, loại khỏi chọn nhanh/tổng số dư (bật/tắt option), vẫn hiện báo cáo.

## Transfer (chuyển khoản nội bộ)
- Là loại giao dịch riêng — **không** tính vào tổng thu/chi, chỉ đổi số dư 2 ví.
- Sinh **2 bút toán liên kết** (`transfer_group_id`) → sửa/xóa đồng bộ cả hai vế.
- Ràng buộc ví nguồn ≠ ví đích; khác tiền tệ → nhập tỷ giá tại thời điểm chuyển và **lưu lại** (`exchange_rate`), không tính lại sau.
- Không chặn chuyển khi nguồn thiếu (tiền mặt âm tạm được) — chỉ cảnh báo mềm.
- Có phí chuyển khoản → phí = 1 khoản **Chi riêng**, danh mục "Phí giao dịch". ⚠ QUYẾT ĐỊNH MỞ: danh mục này chưa có trong seed data — xem [[Danh mục]].

## Số dư & tổng hợp
- Số dư ví = `initial_balance + Σ(thu) − Σ(chi) ± Σ(transfer)`, tính lại real-time khi giao dịch đổi (xem [[Nguyên tắc nghiệp vụ]] rule số liệu-suy-ra).
- Tổng toàn ví = tổng ví **đang hoạt động** (không ẩn), quy đổi về tiền tệ mặc định theo tỷ giá lưu sẵn (offline, **không** API real-time).
- Privacy mode ("ẩn số dư"): số tiền hiển thị `••••••`.

## Xóa / ẩn ví
- Xóa cứng chỉ khi ví **chưa từng có giao dịch**; đã có → chỉ ẩn, cảnh báo + gợi ý ẩn.
- Xóa/ẩn ví đang default → auto chuyển default sang ví khác (ưu tiên ví dương gần nhất được dùng).
- Sort thủ công kéo-thả (`sort_order`); ví default pre-select khi nhập nhanh.

## Ngôn ngữ hiển thị (rule, PBI 19)
**Tên ví KHÔNG dịch** theo ngôn ngữ giao diện — kể cả **ví mẫu do app seed** (`Tiền mặt`, `Vietcombank`, `Thẻ tín dụng VIB`, `Momo`, `Sổ tiết kiệm`): coi là **dữ liệu người dùng**, giữ nguyên văn (chốt PBI 19, khác cách xử lý tên **danh mục** mặc định — xem [[Danh mục]]; bảng ví không có cờ "do app tạo" và bộ ví mẫu sẽ bị gỡ khi có dữ liệu thật). Nhãn **loại ví** (`Tiền mặt`/`Tài khoản ngân hàng`/`Thẻ tín dụng`/`Ví điện tử`/`Sổ tiết kiệm`) là chuỗi hệ thống ⇒ **có** dịch. Hậu tố `(đã ẩn)` cũng dịch riêng rồi ghép với tên ví giữ nguyên. Định dạng số dư `42.500.000 đ` **không đổi** theo ngôn ngữ.

## Màn hình (sub-page từ Cài đặt — xem [[Design system]])
| File | Mô tả |
|---|---|
| `wallet-list-screen.svg` | DS ví: card tổng số dư + ListTile từng ví |
| `wallet-add-edit-form.svg` | Form: chọn loại chip, số dư ban đầu, icon/màu, toggle mặc định |
| `wallet-detail-screen.svg` | Chi tiết ví: số dư lớn + giao dịch gần đây |
| `wallet-transfer-screen.svg` | Transfer: nguồn → đích, số dư sau chuyển |

## Liên kết
- [[Giao dịch]] — ghi nhận lên ví; Transfer thuộc cả 2 module.
- [[Ngân sách]] — lọc theo `walletIds`; ví bị xóa → gỡ khỏi ngân sách.
- [[Hồ sơ & Bảo mật]] — tiền tệ mặc định cấp ví khi tạo; Privacy mode; màn chọn ngôn ngữ (PBI 19).
- [[Stack kỹ thuật]] — cơ chế i18n (khóa = chuỗi tiếng Việt, `.tr`), rule tên ví không dịch.
