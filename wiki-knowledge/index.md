# Index Wiki Knowledge — Sora Thu Chi

Wiki tri thức nghiệp vụ + thiết kế app **Sora Thu Chi** (Flutter, offline, quản lý thu chi cá nhân). Biên soạn từ `docs/` (raw). Cập nhật theo `log.md`.

## Entities
- [[Ví & Tài khoản]] — loại ví, số dư suy ra, transfer nội bộ, ẩn/xóa
- [[Giao dịch]] — thu/chi/chuyển khoản, định kỳ, tìm/lọc, undo, màn hình
- [[Danh mục]] — 2 cấp cha-con, seed data, luật gắn giao dịch
- [[Ngân sách]] — budget + snapshot từng kỳ, cảnh báo, vòng đời
- [[Hồ sơ & Bảo mật]] — device profile, khóa app PIN/sinh trắc, đổi/quên PIN

## Concepts
- [[Nguyên tắc nghiệp vụ]] — các rule xuyên module (số dư suy ra, ẩn-vs-xóa, không hồi tố lịch sử...)
- [[Lộ trình phát triển]] — MVP/GĐ2/GĐ3, phụ thuộc module, **quyết định mở**
- [[Stack kỹ thuật]] — drift, GetX, fl_chart, notifications, secure storage, local_auth
- [[Design system]] — màu teal/coral, app shell FAB, typography, component

## Raw sources
Nguồn gốc tại `../docs/` (không copy vào wiki):
- `docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md` — toàn cảnh tính năng + roadmap + stack
- `docs/wallet/` `docs/transaction/` `docs/category/` `docs/budget/` `docs/auth/` — đặc tả nghiệp vụ từng module (+ mockup `.svg`)
- `docs/design-system-app-thu-chi.md` — bảng màu/typography/component chuẩn
