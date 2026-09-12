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
- **Tiện ích & Cá nhân hóa — màn danh sách `01` đã triển khai (PBI 17)** — điểm vào Cài đặt nhóm KHÁC → "Tiện ích & Cá nhân hóa" (chi tiết tại [[Hồ sơ & Bảo mật]]): 3 nhóm/8 hàng mockup; **2 công tắc thật** (Ẩn số dư tắt, Máy tính bật) nhớ trạng thái bằng bảng drift key-value **`AppSettings` schema v5**; hàng Widget = switch câm + dialog hướng dẫn ghim (không lưu); 5 hàng điều hướng no-op.
- **Màn con `02` "Giao diện" (Sáng/Tối/Theo hệ thống) — đã triển khai (PBI 18)** — hàng "Giao diện" màn `01` đã kích hoạt (bỏ no-op); **dark mode áp toàn app ngay, không restart**, nhớ qua restart bằng row `themeMode` trong `AppSettings` v5 (không migration). Chi tiết màn + cơ chế tại [[Hồ sơ & Bảo mật]], bảng token tại [[Design system]].
- **Màn con `03` "Ngôn ngữ" (Tiếng Việt / English) — đã triển khai (PBI 19)** — hàng "Ngôn ngữ" màn `01` đã kích hoạt (bỏ no-op); **đổi ngôn ngữ áp toàn app ngay, không restart** (dịch **toàn bộ** nhãn tĩnh của mọi màn hiện có), nhớ qua restart bằng row `locale` trong `AppSettings` v5 (không migration); **định dạng ngày/số và tên ví KHÔNG đổi**. Chi tiết màn + cơ chế tại [[Hồ sơ & Bảo mật]], cơ chế kỹ thuật tại [[Stack kỹ thuật]], quy tắc tên danh mục mặc định tại [[Danh mục]].
- Còn lại trong nhóm Tiện ích (PBI sau): màn con `04`–`07` (định dạng & tiền tệ, máy tính nhập tiền, tìm kiếm toàn cục, quản lý tag), **hiệu ứng 2 công tắc** (che số dư thật, đổi bàn phím nhập tiền), theme màu tùy biến, tablet, thêm ngôn ngữ thứ ba / gói ngôn ngữ tải từ ngoài.
- **Backup/Restore GĐ3 nhưng là "van an toàn"** cho mất PIN/gỡ app ([[Hồ sơ & Bảo mật]]) — cân nhắc sớm hơn; khuyến nghị nhắc user backup định kỳ từ sớm.
- **Import CSV/Excel + OCR**: mô tả "tùy chọn mở rộng/nâng cao", **chưa gắn GĐ cụ thể** trong roadmap chính (transaction doc §1) — ⚠ cần định vị (GĐ2 hay GĐ3).
- **Ngân sách GĐ2 chia nhỏ:** 2a (budget danh mục + tiến độ, chưa push) → 2b (budget tổng/theo ví, push, copy) → 2c (so sánh dự kiến–thực tế, tốc độ tiêu — cần ≥2 kỳ lịch sử). Xem [[Ngân sách]].
- **Ngân sách — phạm vi 2a + 2 màn đầu đã triển khai (PBI 20)** — điểm vào Cài đặt? **không**: điểm vào là tab **Báo cáo** → hàng "Ngân sách" → màn `01` Tổng quan Ngân sách (màn cấp tab, có bottom nav) + màn `02` Thêm/Sửa ngân sách. Bảng drift **`budgets` schema v6** (6 cột, **không seed**, mở rộng `WalletRepository` +3 method); **bỏ bảng snapshot** — "đã chi/%/còn lại" tính lại mỗi lần nạp màn. Chi tiết + rule tại [[Ngân sách]].
- **Ngân sách — màn `03` Chi tiết + phần 2c mức tối thiểu đã triển khai (PBI 21)** — màn `03` **là điểm vào mới**: chạm một dòng ở màn `01` mở Chi tiết (trước đây mở thẳng form `02`; form nay vào từ nút "Chỉnh sửa"). Có: số tiền **vượt**/còn lại, **ngày còn lại** (tính **gồm hôm nay** — lệch 1 ngày so với màn `01`, cố ý), **huy hiệu trạng thái**, **băng cảnh báo tốc độ chi tiêu** (`%dùng > %ngày`), **biểu đồ cột đôi 3 kỳ gần nhất** dự kiến–thực tế (`fl_chart` dùng thật lần đầu), **đổi kỳ đang xem** (kể cả các kỳ đã qua), **lưu trữ ngân sách**. Schema **v7** (`addColumn budgets.is_archived`). Chi tiết tại [[Ngân sách]].
  - **2c đóng ở mức tối thiểu** (theo đúng phạm vi đã chốt trong spec): so sánh dự kiến–thực tế + tốc độ tiêu **tính lại từ dữ liệu giao dịch đã có**, **không** cần thêm dữ liệu người dùng nhập, **không** lưu snapshot. Phần **còn lại của 2c** (chưa gắn PBI): **dự báo số tiền tới hết kỳ**, băng **"chi chậm hơn dự kiến"**, ngưỡng cảnh báo tuỳ chỉnh.
  - **Lưu trữ là một chiều và chưa có nơi xem lại** (chốt 2026-09-12): dữ liệu giữ nguyên trong máy để phục vụ báo cáo sau này, nhưng **chưa** có màn/danh sách mở lại, **chưa** có phục hồi; màn `01` giữ nguyên mockup `01`, không thêm nhóm "Đã lưu trữ". Cần một PBI riêng khi muốn dùng lại dữ liệu đã lưu trữ.
  - Còn lại: **2b** (ngân sách tổng, theo ví, cảnh báo push, cộng dồn/sao chép) + phần còn lại của **2c** ở trên.
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
2. ~~**Màu thanh tiến độ ngân sách 80–99%**~~ — **ĐÃ ĐÓNG (PBI 20)**: giữ 2 màu gốc, thanh coral `#D85A30` ở `alpha 0.6` + % coral; <80 teal, ≥100 coral đậm. Xem [[Design system]] + [[Ngân sách]].
3. **Seed danh mục thiếu "Phí giao dịch"** (wallet §4 vs category §3) — transfer có phí cần danh mục này; chưa có trong seed. Bổ sung vào seed hay để user tự tạo?
4. **Đổi múi giờ → tính lại chuỗi recurring?** (auth §3) — ảnh hưởng thời điểm sinh gd định kỳ tiếp theo.
5. **Tỷ giá quy đổi offline từ đâu** — "bảng tỷ giá lưu sẵn" chưa nói rõ nguồn (nhập tay? seed?) — [[Ví & Tài khoản]].
6. **Quick Add từ widget/notification** — widget màn hình chính (§12 Tiện ích) & gọi từ notification: hàng "Widget màn hình chính" nay chỉ là switch câm + **hướng dẫn ghim** (PBI 17, chưa lưu); widget quick-add thật nằm GĐ nào chưa định vị.
7. **Nhóm Tiện ích & Cá nhân hóa (§12)**: màn danh sách `01` (gom điểm vào) **đã MVP (PBI 17)**; màn con `02` **Light/Dark mode đã xong (PBI 18)** — quyết định mặc định khi chưa từng chọn là **"Theo hệ thống"** (khớp "System" của Android 13+); màn con `03` **đa ngôn ngữ đã xong (PBI 19)** — **danh sách ngôn ngữ đã chốt: `vi` (mặc định, không có nhánh bản đồ riêng) + `en`**; *không* có lựa chọn "theo ngôn ngữ hệ thống". Còn **màn con `04`–`07`** (định dạng ngày/tiền/kỳ tài chính, máy tính, tìm kiếm, tag) và **hiệu ứng 2 công tắc** — chưa gắn GĐ.

## Liên kết
- [[Stack kỹ thuật]] — tech theo từng tính năng.
- [[Nguyên tắc nghiệp vụ]] — rule nền mà roadmap xây lên.
