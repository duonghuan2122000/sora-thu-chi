# Index Wiki Knowledge — Sora Thu Chi

Wiki tri thức nghiệp vụ + thiết kế app **Sora Thu Chi** (Flutter, offline, quản lý thu chi cá nhân). Biên soạn từ `docs/` (raw). Cập nhật theo `log.md`.

## Entities
- [[Ví & Tài khoản]] — loại ví, số dư suy ra, transfer nội bộ, ẩn/xóa
- [[Giao dịch]] — thu/chi/chuyển khoản, định kỳ, tìm/lọc, undo, màn hình; **quét hóa đơn AI chặng 1 + 2 (PBI 24)**: điểm vào bottom sheet FAB, nguồn `aiScan` + ảnh đính kèm + bảng phiên quét `scan_sessions`, schema **v8**, **chọn engine theo tier + fallback AI→bộ luật**
- [[Danh mục]] — 2 cấp cha-con, schema drift v4, seed, màn quản lý `01` (PBI 13) + thêm/sửa `02` (PBI 14), luật gắn giao dịch, **dịch tên mặc định theo ngôn ngữ** (PBI 19)
- [[Ngân sách]] — **2a + màn `03` Chi tiết + 2c mức tối thiểu (PBI 20/21)**: `budgets` schema **v7** (`is_archived`), tính lại khi nạp màn (không snapshot), màn `01` Tổng quan + `02` Thêm/Sửa + `03` Chi tiết (huy hiệu, cảnh báo nhịp, biểu đồ `fl_chart` 3 kỳ, đổi kỳ xem, lưu trữ)
- [[Báo cáo]] — **màn `01` Tổng quan (PBI 22) + màn `02` Chi tiết theo danh mục (PBI 23)**: kỳ Ngày/Tuần/Tháng/Năm (tuần bắt đầu Thứ Hai), 6 đơn vị trên biểu đồ, gộp danh mục cha + nhóm "Khác", top 5 → "Xem tất cả" mở màn `02` liệt kê **đầy đủ** danh mục (màu định tính **lặp chu kỳ** theo hạng), drill-down sang màn Giao dịch đã lọc, không schema riêng/không cache
- [[Hồ sơ & Bảo mật]] — device profile, khóa app = mã PIN bắt buộc lần đầu (PBI 3 đã triển khai) + chống dò, đổi/quên PIN; màn Tiện ích & Cá nhân hóa `01` (PBI 17) + màn con `02` "Giao diện" (PBI 18) + màn con `03` "Ngôn ngữ" vi/en (PBI 19, bảng `AppSettings` schema v5) + **mục Cài đặt "Quét hóa đơn AI" & màn kiểm tra cấu hình máy (PBI 24 chặng 1 + chặng 2: kích hoạt Tier A / tải–xoá model Tier B)**

## Concepts
- [[Nguyên tắc nghiệp vụ]] — các rule xuyên module (số dư suy ra, ẩn-vs-xóa, không hồi tố lịch sử...)
- [[Lộ trình phát triển]] — MVP/GĐ2/GĐ3, phụ thuộc module, **quyết định mở** (nhóm Tiện ích: `01`–`03` đã xong; ngân sách: 2c đóng ở mức tối thiểu — PBI 21; báo cáo: màn `01` + `02` xong — PBI 22/23; **quét hóa đơn AI: chặng 1 + chặng 2 Tier A/B đã thi công — PBI 24; còn ⚠ quyết định mở nguồn phân phối model Tier B + QA tay nhóm M/N trên thiết bị thật**; **nhận diện thương hiệu logo + splash đã thi công — PBI 25, còn ⚠ QA mắt độ rõ icon ở cỡ nhỏ trên máy thật**)
- [[Stack kỹ thuật]] — drift (**schema v8**), GetX (state + i18n Translations đã thi công PBI 19), fl_chart (**đã dùng thật PBI 21/22: `BarChart` + `PieChart`**), notifications, secure storage, local_auth; **quét hóa đơn: `google_mlkit_text_recognition` + `camera` + `image_picker` + `image` + `device_info_plus`, kênh native `sora_thu_chi/device_probe`, iOS 15.5; chặng 2 thêm `com.google.mlkit:genai-prompt` (Tier A) + `flutter_gemma`/`flutter_gemma_litertlm` (Tier B), Android minSdk 26 (PBI 24)**
- [[Design system]] — màu teal/coral, app shell FAB, typography, component, **token light/dark** (ThemeExtension `SoraColors`) + **2 ngoại lệ cố ý không theo theme**, biểu đồ ngân sách + **bảng màu định tính `chartPalette`** cho vòng tròn báo cáo, **luồng quét hóa đơn** (bottom sheet, màn chụp **nền tối cố định**, chỉ báo độ tin cậy teal/xám/coral), **nhận diện thương hiệu**: logo Concept A (biến thể **vòng viền trắng** + **nền icon teal**) dùng cho **cả icon launcher lẫn splash**, splash 2 tầng cỡ logo `140dp` (PBI 25)

## Raw sources
Nguồn gốc tại `../docs/` (không copy vào wiki):
- `docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md` — toàn cảnh tính năng + roadmap + stack
- `docs/wallet/` `docs/transaction/` `docs/category/` `docs/budget/` `docs/report/` `docs/auth/` — đặc tả nghiệp vụ từng module (+ mockup `.svg`)
- `docs/ai/tinh-nang-quet-hoa-don-ai-local.md` + `docs/ai/scan-01…11*.svg` — quét hóa đơn bằng AI local (OCR + LLM on-device) + mockup luồng quét
- `docs/design-system-app-thu-chi.md` — bảng màu/typography/component chuẩn
