---
title: "Hồ sơ & Bảo mật"
date: 2026-09-03
tags: [module, auth, security, entity]
sources:
  - ../docs/auth/chi-tiet-quan-ly-tai-khoan-nguoi-dung.md
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
---

# Hồ sơ & Bảo mật

Không phải "tài khoản" server — là **device profile** lưu local. App offline: không đăng ký/đăng nhập/đồng bộ. Gồm: vận hành offline, khóa app (PIN/vân tay/Face ID), hồ sơ cá nhân, đổi/quên PIN.

## Vận hành offline
- Lần đầu mở → thẳng vào **Onboarding**: chọn tiền tệ mặc định, tạo ví đầu tiên, đặt PIN (tùy chọn).
- Dữ liệu gắn **1 bản cài đặt trên 1 thiết bị**.
- Hệ quả: gỡ app/mất máy = mất dữ liệu nếu không backup thủ công → backup JSON là "van an toàn" duy nhất (xem [[Lộ trình phát triển]] GĐ3); **quên PIN không có email/SMS reset** vì không có server.

## Khóa app (App Lock)
- Bật/tắt tùy chọn; bật → nhập PIN **2 lần** (nhập + xác nhận).
- PIN 4 hoặc 6 số (người dùng chọn trong Cài đặt). Cấm chuỗi dễ đoán (`0000`, `1234`) — cảnh báo nhưng cho phép nếu xác nhận.
- PIN **hash + lưu qua `flutter_secure_storage`** (Keychain/Keystore), không plaintext trong DB.
- Sinh trắc học (vân tay/FaceID) = lớp "tiện lợi" thay thế, **PIN vẫn là lớp gốc**.
- Luồng mở khóa: resume từ nền / sau timeout cấu hình → màn khóa **toàn màn hình** (không app bar/bottom nav — [[Design system]]); nếu bật sinh trắc → auto prompt + nút "Dùng mã PIN thay thế"; sinh trắc fail → fallback nhập PIN.
- **Chống brute-force:** sai liên tiếp (VD 5 lần) → khóa tạm thời tăng dần (30s/1p/5p...). Không nên có "xóa trắng dữ liệu sau N lần sai" trừ khi user tự bật (rủi ro mất dữ liệu tài chính quá lớn).
- Trạng thái đặc biệt: sinh trắc bị thu hồi quyền (OS) → tự tắt toggle, yêu cầu bật lại bằng PIN; đổi vân tay đăng ký → **vô hiệu hóa sinh trắc tạm thời**, xác thực lại bằng PIN.

## Hồ sơ cá nhân
| Trường | Chốt |
|---|---|
| Avatar | Ảnh từ thư viện/chụp, hoặc chữ viết tắt tên mặc định |
| Tên hiển thị | Tự do; chào mừng — không định danh/đăng nhập |
| Tiền tệ mặc định | Áp dụng ví mới + tổng hợp báo cáo đa ví; đổi **không hồi tố** tiền tệ ví đã tạo |
| Múi giờ | Gán ngày/giờ gd mới + mốc "đầu ngày/đầu tháng tài chính" |

⚠ QUYẾT ĐỊNH MỞ: đổi múi giờ khi đang có chuỗi định kỳ đã lên lịch → có tính lại thời điểm sinh gd tiếp theo không (auth doc §3).

## Đổi / quên PIN
- **Đổi** (còn nhớ): Cài đặt → Đổi mã PIN → xác thực PIN cũ (hoặc sinh trắc) → nhập/xác nhận PIN mới → lưu.
- **Quên PIN** — 2 hướng chưa chốt:
  - **A** (giữ dữ liệu): reset qua câu hỏi bảo mật đã đặt, hoặc khôi phục từ file JSON backup sau khi cài lại.
  - **B** (ưu tiên bảo mật): không đường vòng — mất PIN = xóa data + cài lại, khôi phục backup nếu có.
  - ⚠ QUYẾT ĐỊNH MỞ: doc nghiêng về **B** kèm khuyến khích backup định kỳ — cần chốt ở giai đoạn thiết kế.

## Bảo mật mở rộng (mục 13 tính năng tổng)
- Mã hóa dữ liệu local (SQLite/Hive mã hóa); không lưu số thẻ/ngân hàng thật (chỉ nhãn tham chiếu).
- Privacy mode: ẩn số dư màn chính (che `••••••`) — liên kết [[Ví & Tài khoản]].
- Yêu cầu sinh trắc trước khi xem/sửa dữ liệu nhạy cảm (tùy chọn).

## Màn hình bảo mật (khác biệt với shell)
- Khóa PIN / sinh trắc: **toàn màn hình, độc lập hoàn toàn** khỏi app shell — chạy trước khi vào app.
- Numpad: lưới `3×4`, nút tròn ~48–52px, viền mảnh `#E0E0E0`, không nền; hàng cuối: trái = icon vân tay (nếu khóa chính) / trống (nếu đổi PIN), giữa `0`, phải backspace. Dot indicator ~12px: đặc teal = đã nhập, rỗng xám = chưa.

## Liên kết
- [[Design system]] — màn bảo mật tách shell; numpad & dot PIN dùng lại cho màn nhập tiền ([[Giao dịch]]).
- [[Ví & Tài khoản]] — tiền tệ mặc định cấp ví mới; Privacy mode.
- [[Ngân sách]] — tiền tệ mặc định & kỳ tài chính lệch bắt nguồn từ hồ sơ.
- [[Lộ trình phát triển]] — phụ thuộc backup GĐ3; PIN khóa app thuộc MVP.
