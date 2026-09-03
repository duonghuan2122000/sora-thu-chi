---
title: "Stack kỹ thuật"
date: 2026-09-03
tags: [concept, stack, architecture]
sources:
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../docs/budget/nghiep-vu-ngan-sach.md
  - ../docs/wallet/nghiep-vu-vi-tai-khoan.md
---

# Stack kỹ thuật

Chốt trong doc tính năng tổng §Stack. App: **Flutter Mobile (Android/iOS), offline hoàn toàn** — không server, dữ liệu local.

## Thư viện chính
| Thư viện | Mục đích | Module dùng |
|---|---|---|
| `drift` | Local DB (SQLite) | Toàn app — bảng `wallets`, `transactions`, `categories`, `budgets`, `budget_period_snapshots` |
| `GetX` | State management | Toàn app — VD `BudgetController` quản DS budget active + snapshot (budget doc §9) |
| `fl_chart` | Biểu đồ | Báo cáo (pie/bar/line); so sánh dự kiến–thực tế budget (cột đôi/line chồng) |
| `flutter_local_notifications` | Thông báo local push | Nhắc gd định kỳ, cảnh báo budget, nhắc mục tiêu, tổng kết |
| `flutter_secure_storage` | Lưu **mã PIN hash + khóa mã hóa** (Keychain/Keystore) | Khóa app, mã hóa dữ liệu — [[Hồ sơ & Bảo mật]] |
| `local_auth` | Sinh trắc học (vân tay/FaceID) | Lớp mở khóa tiện lợi + xác thực data nhạy cảm |
| JSON file | Backup/restore (GĐ3) | Export/import toàn bộ dữ liệu |

## Quyết định kiến trúc ghi nhận
- **Offline, không API**: tỷ giá quy đổi đa tiền tệ dùng bảng tỷ giá lưu sẵn/nhập tay — **không** real-time API ([[Ví & Tài khoản]]).
- **Mã hóa local**: SQLite/Hive mã hóa; không lưu số thẻ/ngân hàng thật.
- **Số liệu tính toán/cache**: `current_balance` ví, `budget_period_snapshots` — drift cache để khỏi tính lại toàn bộ lịch sử mỗi lần mở màn (budget doc §9). Snapshot vẫn **recompute** khi gd trong phạm vi đổi ([[Ngân sách]], [[Nguyên tắc nghiệp vụ]]).
- **Transfer 2 dòng liên kết** bằng `transfer_group_id` → xóa/sửa đồng bộ.
- Widget "% dùng hạn mức thẻ tín dụng" nên tách widget dùng chung → tái dùng cho thanh tiến độ ngân sách.

## Liên kết
- [[Lộ trình phát triển]] — giai đoạn gắn tech (notification là GĐ2, backup GĐ3).
- [[Nguyên tắc nghiệp vụ]] — constraint thiết kế DB.
