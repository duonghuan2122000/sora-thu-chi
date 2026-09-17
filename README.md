# Sora Thu Chi

App quản lý thu chi cá nhân — Flutter Mobile (Android/iOS), **offline hoàn toàn**: không đăng ký/đăng nhập, không server, dữ liệu lưu local trên thiết bị; sao lưu/khôi phục bằng file JSON/ZIP thủ công.

## Tính năng chính

- **Ví/Tài khoản**: nhiều ví (tiền mặt, ngân hàng, thẻ, ví điện tử...), số dư là đại lượng **suy ra** (số dư ban đầu + tổng thu − tổng chi ± chuyển khoản), ẩn/xóa ví, đặt ví mặc định.
- **Giao dịch**: Thu/Chi/Chuyển khoản nội bộ (không tính thu/chi), tag, ảnh hóa đơn, tìm/lọc, sửa/xóa/nhân bản, **quét hóa đơn bằng AI on-device** (OCR + Gemini Nano, có nhật ký trích xuất).
- **Danh mục**: 2 cấp cha-con, icon/màu, sắp xếp, ẩn/xóa.
- **Ngân sách**: theo danh mục/kỳ, tiến độ, cảnh báo, biểu đồ so kỳ.
- **Báo cáo**: tổng quan, chi tiết theo danh mục, so sánh kỳ, xuất PDF/Excel/CSV.
- **Thông báo & nhắc nhở**: nhắc nhập giao dịch hàng ngày, cảnh báo ngân sách, tổng kết định kỳ, trung tâm thông báo trong app.
- **Bảo mật & cá nhân hóa**: khóa app bằng PIN/vân tay/Face ID (không phải đăng nhập), giao diện Sáng/Tối/Theo hệ thống, đa ngôn ngữ Việt/Anh.

## Stack kỹ thuật

Flutter · `drift` (local DB) · `GetX` (state) · `fl_chart` (biểu đồ) · `flutter_local_notifications` + `timezone` (thông báo local) · `flutter_secure_storage` + `local_auth` (bảo mật) · `google_mlkit_text_recognition` + `flutter_gemma` (quét hóa đơn AI) · `pdf`/`excel_community`/`share_plus` (xuất báo cáo).

## Cấu trúc repo

```
docs/               Nguồn chân lý nghiệp vụ & thiết kế (tiếng Việt), theo module: wallet, transaction,
                     category, budget, report, auth, ai...
wiki-knowledge/      Wiki tri thức biên soạn từ docs/ — đọc index.md trước khi làm việc trên module nào.
app/sora_thu_chi/    Ứng dụng Flutter.
.specify/specs/      Đặc tả từng PBI (spec.md, plan.md, tasks.md).
.claude/             Command/skill nội bộ cho quy trình phát triển.
```

## Bắt đầu

```bash
cd app/sora_thu_chi
flutter pub get
flutter analyze
flutter test
flutter run
```

## Quy trình phát triển

Mỗi tính năng đi theo quy trình spec-driven, đặc tả tại `.specify/specs/<mã-pbi>/`:

1. `/sora-spec <mã-pbi> <mô tả>` — viết `spec.md` (CÁI GÌ/TẠI SAO)
2. `/sora-plan <mã-pbi>` — viết `plan.md` (kế hoạch kỹ thuật)
3. `/sora-task <mã-pbi>` — phân rã `tasks.md`
4. `/sora-implement <mã-pbi>` — thi công

Chi tiết quy ước, kiến trúc, design system: xem [`CLAUDE.md`](CLAUDE.md), [`docs/`](docs/) và [`wiki-knowledge/index.md`](wiki-knowledge/index.md).
