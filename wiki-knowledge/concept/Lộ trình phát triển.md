---
title: "Lộ trình phát triển"
date: 2026-09-03
tags: [concept, roadmap]
sources:
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../docs/budget/nghiep-vu-ngan-sach.md
  - ../docs/transaction/nghiep-vu-thiet-ke-quan-ly-giao-dich.md
---

# Lộ trình phát triển

Phân nhóm tính năng theo giai đoạn (doc tính năng tổng §"Gợi ý nhóm" + đặc tả module). **Bỏ qua vĩnh viễn hiện tại:** Chia sẻ & Cộng tác (§11), Tích hợp nâng cao (§14) — chưa trong lộ trình.

## Theo giai đoạn
| Giai đoạn | Tính năng trọng tâm | Phụ thuộc |
|---|---|---|
| **MVP** | Khóa app (PIN/sinh trắc), Quản lý ví, Thêm/sửa/xóa giao dịch, Danh mục, Báo cáo cơ bản (pie/bar) | — |
| **GĐ2** | Ngân sách, Giao dịch định kỳ, Nhắc nhở, Xuất báo cáo Excel/PDF | Giao dịch + Danh mục (MVP); Ngân sách cần module Thông báo (cùng GĐ2) |
| **GĐ3** | Mục tiêu tiết kiệm, Quản lý nợ, **Backup/Restore JSON** | — |

### Ghi chú giai đoạn
- **Khóa app = mã PIN bắt buộc lần đầu mở app** — quyết định chốt (lệch `docs/auth §2.1` vốn tùy chọn) và **đã triển khai xong (PBI 3)**. Sinh trắc (vân tay/FaceID) là lớp tiện lợi để sau, chưa thuộc đợt này — chi tiết rule tại [[Hồ sơ & Bảo mật]]. `docs/auth` chưa đồng bộ theo.
- **Module Danh mục (MVP)** — màn danh sách `01` **đã triển khai (PBI 13)** + màn thêm/sửa `02` **đã triển khai (PBI 14)** + màn danh sách con `03` **đã triển khai (PBI 15)** + màn sắp xếp kéo-thả `04` **đã triển khai (PBI 16)** qua điểm vào Cài đặt → "Danh mục" (mô tả tại [[Danh mục]]); icon "Sắp xếp" màn `01` (no-op PBI 13) nay mở màn `04` theo tab đang mở. Còn lại: xóa/gộp danh mục (PBI sau) + sắp thứ tự con trong từng nhóm cha–con.
- **Backup/Restore GĐ3 nhưng là "van an toàn"** cho mất PIN/gỡ app ([[Hồ sơ & Bảo mật]]) — cân nhắc sớm hơn; khuyến nghị nhắc user backup định kỳ từ sớm.
- **Import CSV/Excel + OCR**: mô tả "tùy chọn mở rộng/nâng cao", **chưa gắn GĐ cụ thể** trong roadmap chính (transaction doc §1) — ⚠ cần định vị (GĐ2 hay GĐ3).
- **Ngân sách GĐ2 chia nhỏ:** 2a (budget danh mục + tiến độ, chưa push) → 2b (budget tổng/theo ví, push, copy) → 2c (so sánh dự kiến–thực tế, tốc độ tiêu — cần ≥2 kỳ lịch sử). Xem [[Ngân sách]].
- Mục tiêu tiết kiệm & quản lý nợ (GĐ3): chỉ liệt kê ở doc tính năng tổng, **chưa có đặc tả module riêng** — nguồn thiếu, cần bổ sung khi triển khai.

## Module & data dependency (từ đặc tả)
```
Danh mục (MVP) ─┐
Giao dịch (MVP)─┼─→ Ngân sách (GĐ2)
Ví (MVP) ───────┘        │
Thông báo (GĐ2) ─────────┘ (cảnh báo budget/recurring)
Hồ sơ cá nhân ─→ tiền tệ mặc định, múi giờ, kỳ tài chính (periodStartRule)
Backup/Restore (GĐ3) ── van an toàn cho mất PIN / đổi máy
```

## ⚠ Quyết định mở (mâu thuẫn / chưa chốt giữa nguồn)
Gom các điểm doc chưa chốt — đóng 1 điểm = 1 lần cập nhật wiki.
1. **Quên PIN hướng A hay B** (auth doc §4.2). A = giữ dữ liệu (security question / reset qua backup); B = bảo mật tuyệt đối (mất PIN = xóa data, restore backup). Nghiêng **B**.
2. **Màu thanh tiến độ ngân sách 80–99%** (budget doc §6). Design system chỉ 2 màu teal/coral; doc gợi ý **coral nhạt (opacity)** thay vì thêm màu thứ ba. → chưa chốt, ảnh hưởng [[Design system]].
3. **Seed danh mục thiếu "Phí giao dịch"** (wallet §4 vs category §3) — transfer có phí cần danh mục này; chưa có trong seed. Bổ sung vào seed hay để user tự tạo?
4. **Đổi múi giờ → tính lại chuỗi recurring?** (auth §3) — ảnh hưởng thời điểm sinh gd định kỳ tiếp theo.
5. **Tỷ giá quy đổi offline từ đâu** — "bảng tỷ giá lưu sẵn" chưa nói rõ nguồn (nhập tay? seed?) — [[Ví & Tài khoản]].
6. **Quick Add từ widget/notification** — widget màn hình chính (§12 Tiện ích) & gọi từ notification: thiết bị widget nằm GĐ nào chưa định vị.
7. **Nhóm Tiện ích & Cá nhân hóa (§12) chưa gắn GĐ**: Light/Dark mode, **đa ngôn ngữ (Việt/Anh...)**, tùy chỉnh format ngày/tiền/kỳ tài chính — đều ngoài bảng MVP/GĐ2/GĐ3 (như #6). Riêng đa ngôn ngữ: cơ chế chốt **GetX Translations** ([[Stack kỹ thuật]]), cần chốt luôn danh sách ngôn ngữ hỗ trợ.

## Liên kết
- [[Stack kỹ thuật]] — tech theo từng tính năng.
- [[Nguyên tắc nghiệp vụ]] — rule nền mà roadmap xây lên.
