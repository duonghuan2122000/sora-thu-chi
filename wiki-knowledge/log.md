# Log cập nhật wiki

## [2026-09-03] bootstrap | Dựng wiki từ toàn bộ docs/ (7 doc markdown + mockup SVG)
- Tạo schema CLAUDE.md + index + 9 page (5 entity, 4 concept).
- Raw = `../docs/` trỏ thẳng, không copy.
- Gom các quyết định mở vào [[Lộ trình phát triển]].

## [2026-09-03] rule | Cấu hình style tập trung 1 nơi khi triển khai app
- Thêm mục "Triển khai trong code (rule)" vào [[Design system]]: màu/size/typography config tại 1 nơi (AppTheme + token), widget không nhúng hex/số cứng rải rác. Quyết định của user (chưa nằm trong `docs/`).

## [2026-09-03] rule | Đa ngôn ngữ dùng GetX Translations
- Thêm mục "Đa ngôn ngữ (i18n) — rule" vào [[Stack kỹ thuật]]: chuỗi UI qua key i18n từ lúc dựng UI, cấu hình root `GetMaterialApp(translations/locale/fallbackLocale)`, mặc định + fallback tiếng Việt, không dịch data user, tách i18n khỏi format số tiền/ngày.
- Mở quyết định #7 trong [[Lộ trình phát triển]]: nhóm §12 Tiện ích chưa gắn GĐ; đa ngôn ngữ cần chốt danh sách ngôn ngữ. Quyết định của user (cơ chế GetX Translations) + nguồn gốc doc §12.
