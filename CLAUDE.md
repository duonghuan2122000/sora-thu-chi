# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Sora Thu Chi** — app quản lý thu chi cá nhân, Flutter Mobile (Android/iOS), **offline hoàn toàn** (không đăng nhập, không server; dữ liệu lưu local, backup/restore bằng file JSON). Ngôn ngữ giao diện, tài liệu và commit message: **tiếng Việt có dấu**.

Repo hiện đang ở giai đoạn **khởi tạo**: đã có bộ tài liệu nghiệp vụ/UI hoàn chỉnh trong `docs/`, còn `app/` mới chỉ là scaffold `flutter create` mặc định (widget counter demo) — chưa có module nghiệp vụ nào.

## Cấu trúc repo

- `docs/` — **Nguồn chân lý về nghiệp vụ & thiết kế**. Markdown (tiếng Việt) từng module: `wallet`, `transaction`, `category`, `budget`, `auth` (kèm mockup `.svg`); `design-system-app-thu-chi.md` (UI); `tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md` (toàn cảnh tính năng + roadmap MVP/GĐ2/GĐ3 + stack kỹ thuật). Trước khi làm việc trên module nào, đọc doc tương ứng — nhiều ràng buộc nghiệp vụ quan trọng chỉ nằm trong docs (VD: số dư ví là số **tính toán**, không sửa tay; cờ "ví mặc định" chỉ 1 ví; chuyển khoản nội bộ không tính là thu/chi; đổi tiền tệ...).
- `app/sora_thu_chi/` — package Flutter của app (khởi tạo bằng `flutter create`). Không có file README/rule đặc thù ở đây.
- `.claude/` — commands/skills nội bộ: quy trình `sora-spec/plan/task/implement` và skill `sora-wiki`.

## Workflow phát triển (Spec-Driven, qua các command trong repo)

Mọi tính năng mới đi theo quy trình PBI, đặc tả lưu tại `.specify/specs/<mã-pbi>/`:

1. `/sora-spec <mã-pbi> <mô tả>` → viết `spec.md` + checklist chất lượng (chỉ mô tả CÁI GÌ/TẠI SAO, cấm chi tiết kỹ thuật).
2. `/sora-plan <mã-pbi>` → viết `plan.md` (kế hoạch kỹ thuật, nhắc cả stack bên dưới).
3. `/sora-task <mã-pbi>` → phân rã thành `tasks.md` (task đủ nhỏ để thi công).
4. `/sora-implement <mã-pbi>` → thi công toàn bộ task trong `tasks.md`.

Khi user nhờ ghi nhớ/tổng hợp kiến thức từ tài liệu → dùng skill `sora-wiki`. Khi user nhờ commit → dùng skill `git-commit` (Conventional Commits, message tiếng Việt, **không** thêm trailer `Co-Authored-By`).

## Lệnh Flutter (chạy từ `app/sora_thu_chi/`)

```bash
flutter pub get           # cài dependency
flutter analyze           # lint (flutter_lints, analysis_options.yaml)
flutter test              # chạy toàn bộ test
flutter test test/widget_test.dart   # chạy 1 file test
flutter run               # chạy app (chọn device)
flutter build apk         # build release
```

## Kiến trúc & quyết định kỹ thuật (đã chốt trong docs, áp dụng khi triển khai)

- **Stack** (docs/tinh-nang...md §Stack): local DB `drift`; state management `GetX`; biểu đồ `fl_chart`; thông báo local `flutter_local_notifications`; bảo mật `flutter_secure_storage` (mã PIN + khóa mã hóa) + sinh trắc học `local_auth`; backup/restore JSON.
- **Ứng dụng offline, không auth**: "khóa app" = PIN/Fingerprint/FaceID (màn bảo mật toàn màn hình, không app bar/bottom nav), không phải đăng nhập.
- **App shell**: bottom nav 5 vị trí — Tổng quan | Giao dịch | **FAB "thêm giao dịch" nổi giữa** | Báo cáo | Cài đặt. Sub-page từ Cài đặt: app bar màu thương hiệu + nút back. Màn hình bảo mật (khóa PIN, sinh trắc học): tách biệt hoàn toàn khỏi shell.
- **Design system** (docs/design-system-app-thu-chi.md): Material phẳng; đúng **1** màu thương hiệu teal `#0F6E56` cho hành động chính/trạng thái chọn-bật; coral `#D85A30` **chỉ** cho ngữ cảnh chi tiêu/cảnh báo; thu = teal, chi = coral. Số tiền căn phải, phân tách nghìn bằng dấu chấm, đơn vị `đ` (VD `42.500.000 đ`). Card bo góc `10px`, nút chính bo `8px` cao `44px`, FAB tròn `48–52px`. Bảng màu/typography/component đầy đủ trong doc — đọc trước khi dựng UI.
- **Luồng nghiệp vụ cốt lõi**: số dư ví là đại lượng suy ra (số dư ban đầu + tổng thu − tổng chi ± chuyển khoản); giao dịch thu/chi/chuyển khoản (transfer là chuyển nội bộ, không tính thu/chi); danh mục cha-con; thu/chi liên hệ với ngân sách và mục tiêu.
