# Log cập nhật wiki

## [2026-09-03] rule | Khóa app = mã PIN bắt buộc lần đầu (PBI 3 đã implement) — nguồn .specify/specs/3
- Cập nhật [[Hồ sơ & Bảo mật]] §Khóa app: chốt **PIN bắt buộc ngay lần đầu mở app** + luôn có hiệu lực (lệch `docs/auth §2.1` "bật/tắt tùy chọn" — quyết định user, đã chốt) — ghi chi tiết: thiết lập 2 lần khớp, PIN 4 số cố định, PIN yếu cảnh báo-cho phép, hash SHA-256 có muối (`crypto`) + `lock_state` JSON trong flutter_secure_storage, mở khóa mỗi boot/resume về đúng màn, chống dò ladder 30s→1p→5p→15p giữ khi thoát app, sinh trắc & đổi/quên PIN & độ dài 4/6 ngoài đợt. Numpad hàng cuối trái để trống (chưa sinh trắc).
- Cập nhật [[Lộ trình phát triển]]: ghi chú MVP — khóa PIN đã xong PBI 3 (sinh trắc để sau).
- Cập nhật [[Stack kỹ thuật]]: thêm `crypto` (SHA-256) + mô tả key secure storage của khóa PIN.
- ⚠ `docs/auth/chi-tiet-quan-ly-tai-khoan-nguoi-dung.md §2.1` (và doc tính năng tổng phần lần đầu/Onboarding) **chưa đồng bộ** với quyết định bắt buộc — cần cập nhật tài liệu nghiệp vụ theo (raw sources chỉ đọc, sửa tay ngoài wiki).

## [2026-09-03] bootstrap | Dựng wiki từ toàn bộ docs/ (7 doc markdown + mockup SVG)
- Tạo schema CLAUDE.md + index + 9 page (5 entity, 4 concept).
- Raw = `../docs/` trỏ thẳng, không copy.
- Gom các quyết định mở vào [[Lộ trình phát triển]].

## [2026-09-03] rule | Cấu hình style tập trung 1 nơi khi triển khai app
- Thêm mục "Triển khai trong code (rule)" vào [[Design system]]: màu/size/typography config tại 1 nơi (AppTheme + token), widget không nhúng hex/số cứng rải rác. Quyết định của user (chưa nằm trong `docs/`).

## [2026-09-03] rule | Đa ngôn ngữ dùng GetX Translations
- Thêm mục "Đa ngôn ngữ (i18n) — rule" vào [[Stack kỹ thuật]]: chuỗi UI qua key i18n từ lúc dựng UI, cấu hình root `GetMaterialApp(translations/locale/fallbackLocale)`, mặc định + fallback tiếng Việt, không dịch data user, tách i18n khỏi format số tiền/ngày.
- Mở quyết định #7 trong [[Lộ trình phát triển]]: nhóm §12 Tiện ích chưa gắn GĐ; đa ngôn ngữ cần chốt danh sách ngôn ngữ. Quyết định của user (cơ chế GetX Translations) + nguồn gốc doc §12.
