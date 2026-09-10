# Index Wiki Knowledge — Sora Thu Chi

Wiki tri thức nghiệp vụ + thiết kế app **Sora Thu Chi** (Flutter, offline, quản lý thu chi cá nhân). Biên soạn từ `docs/` (raw). Cập nhật theo `log.md`.

## Entities
- [[Ví & Tài khoản]] — loại ví, số dư suy ra, transfer nội bộ, ẩn/xóa
- [[Giao dịch]] — thu/chi/chuyển khoản, định kỳ, tìm/lọc, undo, màn hình
- [[Danh mục]] — 2 cấp cha-con, schema drift v4, seed, màn quản lý `01` (PBI 13) + thêm/sửa `02` (PBI 14), luật gắn giao dịch, **dịch tên mặc định theo ngôn ngữ** (PBI 19)
- [[Ngân sách]] — budget + snapshot từng kỳ, cảnh báo, vòng đời
- [[Hồ sơ & Bảo mật]] — device profile, khóa app = mã PIN bắt buộc lần đầu (PBI 3 đã triển khai) + chống dò, đổi/quên PIN; màn Tiện ích & Cá nhân hóa `01` (PBI 17) + màn con `02` "Giao diện" (PBI 18) + màn con `03` "Ngôn ngữ" vi/en (PBI 19, bảng `AppSettings` schema v5)

## Concepts
- [[Nguyên tắc nghiệp vụ]] — các rule xuyên module (số dư suy ra, ẩn-vs-xóa, không hồi tố lịch sử...)
- [[Lộ trình phát triển]] — MVP/GĐ2/GĐ3, phụ thuộc module, **quyết định mở** (nhóm Tiện ích: `01`–`03` đã xong)
- [[Stack kỹ thuật]] — drift, GetX (state + i18n Translations đã thi công PBI 19), fl_chart, notifications, secure storage, local_auth
- [[Design system]] — màu teal/coral, app shell FAB, typography, component, **token light/dark** (ThemeExtension `SoraColors`)

## Raw sources
Nguồn gốc tại `../docs/` (không copy vào wiki):
- `docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md` — toàn cảnh tính năng + roadmap + stack
- `docs/wallet/` `docs/transaction/` `docs/category/` `docs/budget/` `docs/auth/` — đặc tả nghiệp vụ từng module (+ mockup `.svg`)
- `docs/design-system-app-thu-chi.md` — bảng màu/typography/component chuẩn
