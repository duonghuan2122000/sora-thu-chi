---
title: "Ngân sách"
date: 2026-09-12
tags: [module, budget, entity]
sources:
  - ../docs/budget/nghiep-vu-ngan-sach.md
  - ../docs/budget/man-hinh-01-tong-quan-ngan-sach.svg
  - ../docs/budget/man-hinh-02-them-ngan-sach.svg
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../../.specify/specs/20/spec.md
---

# Ngân sách

Đặt giới hạn chi cho một danh mục theo kỳ, theo dõi mức dùng **real-time** → kiểm soát tài chính **chủ động** thay vì ghi chép thụ động. Thuộc **GĐ2**.

**Trạng thái:** phạm vi **2a** (ngân sách theo danh mục + theo dõi tiến độ, chưa push) **đã triển khai — PBI 20**, gồm màn `01` Tổng quan Ngân sách và màn `02` Thêm/Sửa ngân sách (bảng drift **schema v6**). 2b/2c + màn `03` Chi tiết ngân sách còn lại (xem [[Lộ trình phát triển]]).

## Mô hình dữ liệu (đã chốt cho 2a — schema v6)
Bảng `budgets` **6 cột**: `id, category_id, amount, period(weekly|monthly|yearly), is_recurring(default true), start_date`.

**Chưa có hiệu lực đợt này** (đừng giả định là đã có): `scope`, `name`, `wallet_ids`, `currency`, `period_start_rule`, `end_date`, `alert_thresholds`, `rollover_unused`, `status`, `created_at/updated_at`. Migration v5→v6 = **tạo bảng, không seed** (màn mở lần đầu phải rỗng, khác ví/giao dịch có dữ liệu mẫu).

**Không có bảng `budget_period_snapshots`.** Doc §9 cho phép tính runtime khi dữ liệu nhỏ; "đã chi / % / còn lại / ngày còn lại" là **đại lượng tính toán**, dựng lại mỗi lần nạp màn từ `budgets` + `transactions` + `categories`. Hệ quả tốt: sửa `amount` **không thể** hồi tố kỳ trước (không có bản ghi kỳ nào để hồi tố), và giao dịch Chi bị sửa/xoá sau đó tự khớp lại. Snapshot chỉ cần khi 2c (so sánh nhiều kỳ, tốc độ tiêu) hoặc khi dữ liệu lớn.

## Quy tắc nghiệp vụ (đã chốt)
1. **Chỉ giao dịch Chi** tính vào ngân sách; Thu và **chuyển khoản nội bộ** bị loại hoàn toàn.
2. Khớp phạm vi: `category_id` **bằng chính danh mục HOẶC là con trực tiếp** của nó (cây 2 cấp, không lấy cháu). Khớp theo `category_id` chứ không theo text tên — dòng cũ nâng cấp `< v4` có `category_id = null` **không** được suy đoán theo tên.
3. Ngày tính = `transaction_date ∈ [periodStart, periodEnd)` — **end độc quyền**.
4. **Đã chi = `-Σ amount`** (amount trong DB có dấu, Chi = âm).
5. **Mốc kỳ**: Tháng/Năm **dương lịch**; **Tuần bắt đầu Thứ Hai** (đúng quy ước sẵn có `resolveDatePreset.thisWeek`). `periodStartRule` (kỳ tài chính lệch ngày) ngoài phạm vi — thuộc màn "Định dạng & Tiền tệ" chưa dựng.
6. **Không chồng lấn**: chặn 2 ngân sách **cùng `category_id` + cùng `period`** có **khoảng hiệu lực** giao nhau. Khoảng hiệu lực = `start_date → ∞` nếu `is_recurring`, ngược lại = **đúng kỳ chứa `start_date`**. Cùng danh mục **khác chu kỳ** được song song (Tháng và Năm cùng tồn tại, hiện 2 dòng). Khi sửa, bỏ qua chính nó theo `id`.
7. **Tạo giữa kỳ** → đã chi khởi tạo bằng tổng Chi đã có **từ đầu kỳ** (không phải 0).
8. Sửa `amount` giữa kỳ → áp dụng kỳ hiện tại, không hồi tố kỳ đã qua (hệ quả tự nhiên của rule "tính lại", không cần cơ chế riêng).

## Vòng đời kỳ & trạng thái (suy ra, không lưu cột `status`)
| Trạng thái | Điều kiện | Kỳ dùng để tính "đã chi" | Vào thẻ tổng? |
|---|---|---|---|
| `active` | `is_recurring`, **hoặc** không lặp lại mà `now` nằm trong kỳ chứa `start_date` | Tháng → **tháng đang xem**; Tuần/Năm → kỳ chứa `now` | ✅ |
| `ended` | không lặp lại và `now` đã ra ngoài kỳ chứa `start_date` | kỳ chứa `start_date` (cố định) | ❌ — hiện "Đã kết thúc" |
| `invalid` | danh mục không còn trong bảng `categories` | (vô nghĩa) | ❌ — hiện "Danh mục đã bị xóa", **không** tự xoá ngân sách, nhắc gán lại |

- `is_recurring = true` sang kỳ mới **tự tiếp tục** với cùng giới hạn (không sinh bản ghi mới — chỉ là cùng một dòng được tính theo kỳ mới).
- `rollover_unused` (cộng dồn) và "Sao chép tháng trước" **hiển thị theo mockup nhưng chưa hoạt động** — thuộc 2b.

## Cảnh báo & hiển thị tiến độ
- **3 dải màu** (chốt theo mockup `01`, xem [[Design system]]): `< 80%` → thanh + % **teal**; **`80–99%` → thanh coral nhạt (`alpha 0.6`), % coral**; `≥ 100%` → thanh **coral đậm**, % coral.
- Dòng vượt giới hạn ở màn `01` **chỉ hiện %**, **không** hiện số tiền vượt — số tiền vượt thuộc màn `03` Chi tiết ngân sách (PBI sau).
- Thẻ tổng: nhãn "Tổng ngân sách tháng này", cặp **tổng đã chi / tổng giới hạn**, thanh tiến độ tổng, "Còn lại … đ", "… ngày còn lại" của kỳ đang xem; tổng **chỉ cộng dòng `active`**.
- **Thứ tự danh sách**: `active` **giảm dần theo %** (căng nhất lên đầu); dòng `ended`/`invalid` xuống cuối, trong nhóm sắp theo tên.
- Bộ chọn kỳ ở màn `01` **chỉ điều khiển ngân sách chu kỳ Tháng**; dòng Tuần/Năm luôn hiện tiến độ kỳ hiện tại của chính nó + **nhãn chu kỳ**, không đổi khi người dùng đổi tháng đang xem.
- Trạng thái rỗng: không có dòng nào → lời nhắc + nút "Thêm ngân sách", **không** hiện thẻ tổng/danh sách trơ.

## Seam dữ liệu & màn hình
- `WalletRepository` mở rộng **3 method** `budgets() / insertBudget / updateBudget` (không thêm repository hay controller riêng; repository **không** tự validate chồng lấn — luật nằm ở module thuần + UI). Module thuần: `core/budget/{budget, budget_view, budget_rules}.dart`.
- Màn `01` **Tổng quan Ngân sách**: màn **cấp tab** đẩy từ tab Báo cáo (nút `+` riêng, **không** nút back) nên tự dựng `AppBottomNavBar` (tab Báo cáo sáng) + FAB thêm giao dịch **dùng chung**; chạm tab khác → `pop()` rồi đổi tab thật qua callback từ `AppShell`. Đây là **ngoại lệ có lý do** của quy tắc "màn con đè shell thì không bottom nav".
- Màn `02` Thêm/Sửa ngân sách: sub-page (`SubPageScaffold`, **không** bottom nav), nút "Lưu ngân sách" cao `44px`; ô số tiền chỉ nhận chữ số + **định dạng phân tách nghìn ngay khi gõ** (`3.000.000`, hậu tố `đ`); chế độ Sửa giữ nguyên `start_date`, điền sẵn danh mục/số tiền/chu kỳ/lặp lại.
- **Giới hạn đã biết**: picker danh mục tái dùng (PBI 11) **không chọn được danh mục cha có con** (chạm cha là khoan xuống con) ⇒ từ UI hiện chỉ tạo được ngân sách cho danh mục không con / danh mục con. Luật gộp con vào cha vẫn đúng ở tầng tính toán.
- Mọi nhãn tĩnh của 2 màn có bản dịch **vi/en** (PBI 19) — bộ chọn kỳ ở English hiện dạng `9/2026`.

## Ngoài phạm vi 2a
Ngân sách **tổng** (`scope = total`), ngân sách theo **ví**, cảnh báo **push** theo ngưỡng, cộng dồn phần chưa dùng, sao chép/rollover kỳ mới, lưu trữ/xóa ngân sách, kỳ tài chính lệch ngày, **đa tiền tệ**, so sánh dự kiến–thực tế nhiều kỳ & tốc độ tiêu (cần ≥2 kỳ dữ liệu), màn `03` Chi tiết ngân sách, biểu đồ (`fl_chart` chưa dùng).

## Liên kết
- [[Giao dịch]] — nguồn "đã chi" (chỉ Chi, đúng kỳ).
- [[Danh mục]] — phạm vi `category_id` + con; danh mục bị xoá → dòng `invalid`.
- [[Ví & Tài khoản]] — đợt này ngân sách áp dụng **tất cả ví** (ví ẩn không ảnh hưởng).
- [[Hồ sơ & Bảo mật]] — tiền tệ mặc định & kỳ tài chính lệch (2b+).
- [[Design system]] — dải coral nhạt 80–99%.
- [[Lộ trình phát triển]] — 2b/2c còn lại.
