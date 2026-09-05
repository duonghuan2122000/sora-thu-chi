# Log cập nhật wiki

## [2026-09-05] implement | Màn danh sách danh mục (PBI 13) + sync schema v4 Danh mục (backlog PBI 11) — nguồn .specify/specs/13, /11
- Cập nhật [[Danh mục]] §Mô hình: sửa claim lệch (wiki cũ ghi `id(UUID)/created_at/updated_at`) → đúng drift schema **v4**: `categories` `id(int autoincrement), name(≤30), type(income|expense), icon, color(ARGB), parent_id(null=cha), sort_order, is_system, is_hidden`; giao dịch tham chiếu `transactions.category_id` (nullable) + `category` text **snapshot** tên. **Backlog PBI 11 chưa sync giờ đã ghi** (trước PBI 13 mới chạm bảng này).
- Cập nhật §Seed data: sửa thiếu "Khác" (nay đủ **4 cha thu** gồm Khác + 8 cha chi + 3 con Ăn uống), khớp `CategorySource.all`.
- Thêm §Màn `01` + đổi bảng Màn hình sang trạng thái: `01` ✅ **đã triển khai** (PBI 13 `CategoryListScreen`), `02/03/04` ⏳ PBI sau. Mô tả: entry Cài đặt nhóm KHÁC sau "Quản lý ví"; StatefulWidget nạp **2 loại 1 lúc** + chuyển tab lọc local (không GetX); hiện **cả danh mục ẩn** + nhãn "Đã ẩn"/mờ; "N danh mục con" **gồm con ẩn**; empty thật vs **ẩn-toàn-bộ không empty giả**; FAB/dòng/icon "Sắp xếp" no-op có ripple chờ `02/03/04`; mỗi lần vào reload.
- Ghi 2 seam đọc phân vai: `categories({type})` (đang hoạt động, picker PBI 11) vs `categoriesIncludingHidden({type})` (gồm ẩn, màn quản lý PBI 13) + module thuần `category_list.dart` (`topLevelParents`/`childrenOf` sort ổn định).
- Cập nhật [[Lộ trình phát triển]] ghi chú MVP: module Danh mục màn `01` xong, còn `02/03/04`. Không đổi schema drift v4 (PBI 13 chỉ đọc, không `build_runner`); 314 test pass; QA emulator A–F pass (G qua widget test — chưa tạo ẩn bằng UI).

## [2026-09-05] implement | Tìm kiếm & Lọc giao dịch (PBI 12) — nguồn .specify/specs/12
- Cập nhật [[Giao dịch]] §Tìm/lọc/sắp xếp: mô tả **đã triển khai** màn `05` (chip 4 loại, 5 bộ lọc nâng cao, bản nháp + Áp dụng/back giữ tập cũ, bỏ dấu tiếng Việt tự viết, AND, summary `N/Tổng` với transfer/adjustment ngoài tổng, group-keep transfer khi lọc ví).
- Ghi 2 lựa chọn hiển thị **user đã chốt** (R4 sort tiền → list phẳng; R5 đang lọc → ẩn card tháng, thay thanh `N kết quả · Tổng` + Bỏ lọc) + kỹ thuật: lọc trong bộ nhớ (cache mỗi load), filter sống `TransactionController` bền qua tab, không đổi schema.
- ⚠ `docs/transaction` chưa chép phần triển khai này (raw chỉ đọc — nghiệp vụ tinh chỉnh từ mô tả đặc tả); PBI 12 vẫn còn T011 QA emulator thủ công.

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
