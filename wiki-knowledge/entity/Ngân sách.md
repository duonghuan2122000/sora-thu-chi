---
title: "Ngân sách"
date: 2026-09-03
tags: [module, budget, entity]
sources:
  - ../docs/budget/nghiep-vu-ngan-sach.md
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
---

# Ngân sách

Đặt giới hạn chi cho một kỳ (theo danh mục / tổng thể), theo dõi mức dùng real-time, cảnh báo gần/vượt ngưỡng → kiểm soát tài chính **chủ động** thay vì ghi chép thụ động. Thuộc **GĐ2** (xem [[Lộ trình phát triển]]).

## Mô hình dữ liệu (drift)
`budgets`: `id, name, scope(category|total), categoryId(null nếu total), walletIds(mảng, rỗng=toàn bộ ví), amount, currency(= tiền tệ mặc định người dùng, không chọn khác — tránh sai lệch quy đổi), period(weekly|monthly|yearly), periodStartRule(ngày trong tháng, default 1 — kỳ tài chính lệch VD 25), startDate, endDate(null=vô hạn), isRecurring, alertThresholds(default [80,100]), rolloverUnused(default false), status(active|archived|deleted), createdAt/updatedAt`.

`budget_period_snapshots` (dữ liệu **tính toán/cache**, từng kỳ): `budgetId, periodStart/End, plannedAmount(gồm rollover), actualSpent, remaining, usagePercent, lastAlertTriggered`. Recompute khi có gd Chi đổi trong phạm vi hoặc mở màn Ngân sách (lazy).

## Quy tắc nghiệp vụ
1. **Chỉ giao dịch Chi** tính vào ngân sách (thu/transfer không).
2. `scope=category`: khớp khi `categoryId == gd.categoryId` **hoặc thuộc subcategory** của nó ([[Danh mục]]).
3. `scope=total`: mọi gd Chi, trừ danh mục người dùng đánh dấu "loại trừ" (tùy chọn nâng cao, mặc định không có).
4. `walletIds` chỉ định → chỉ tính gd trên các ví đó. Ngày tính = `transaction.date` nằm trong `[periodStart, periodEnd]`.
5. **Không chồng lấn**: không 2 budget cùng `categoryId` + `period` chồng thời gian hiệu lực. Cho phép song song 1 budget tổng + nhiều budget danh mục (2 góc nhìn, không loại trừ — 1 gd trừ vào cả hai).

## Vòng đời kỳ
- `isRecurring=true` + qua `periodEnd` → tự sinh kỳ mới, giữ `plannedAmount` gốc.
- `rolloverUnused=true`: plannedAmount kỳ mới = amount gốc + **remaining dương** kỳ trước; remaining **âm không trừ ngược** vào kỳ mới (tránh phạt kép người dùng).
- Không recurring / quá `endDate` → kỳ kết thúc, hiển thị "Đã kết thúc", giữ lịch sử.
- **Sao chép cuối kỳ** (khi không bật recurring): nhân bản các budget active sang kỳ mới, `actualSpent` về 0, cho chỉnh sửa từng khoản trước khi xác nhận hàng loạt.

## Cảnh báo & hiển thị
- So `usagePercent` với từng ngưỡng `alertThresholds`; mỗi ngưỡng bắn **1 lần/kỳ** (`lastAlertTriggered`) — chống spam khi nhiều gd nhỏ đẩy % lên từ từ.
- `>=100%`: trạng thái "Đã vượt" + số tiền vượt, màu **coral**. `<80%`: teal.
- ⚠ QUYẾT ĐỊNH MỞ: mốc **80–99%** cần màu trung gian — doc đề xuất coral nhạt (opacity) để không phá hệ 2 màu của [[Design system]]; chưa chốt (budget doc §6).
- "Tốc độ tiêu": dự đoán tuyến tính theo % thời gian kỳ đã qua — cảnh báo sớm kể cả khi `usagePercent` chưa chạm ngưỡng.
- So sánh dự kiến vs thực tế: cột đôi/thanh chồng cho kỳ active; xu hướng `actualSpent` nhiều kỳ vs đường `plannedAmount` cho kỳ đã kết thúc.

## Xóa / ví bị xóa
- Xóa budget **không xóa** gd liên quan — chỉ ngừng theo dõi.
- Budget có nhiều kỳ lịch sử → ưu tiên **archive** hơn xóa cứng; xóa cứng chỉ khi chưa có kỳ ghi nhận chi tiêu.
- Ví trong `walletIds` bị xóa → tự gỡ khỏi ngân sách; rỗng hết → budget về áp dụng toàn bộ ví + thông báo.
- Danh mục gắn budget bị xóa/gộp → budget `invalid`, nhắc gán lại ([[Danh mục]]).

## Đề xuất triển khai trong GĐ2
- **2a:** budget theo danh mục + theo dõi tiến độ cơ bản (chưa push).
- **2b:** budget tổng, theo ví, cảnh báo push, sao chép.
- **2c:** so sánh dự kiến–thực tế nhiều kỳ, tốc độ tiêu (cần ≥2 kỳ dữ liệu).

## Edge cases đáng chú ý
- Tạo giữa kỳ: `actualSpent` khởi tạo = tổng chi đã có từ `periodStart` (không phải 0).
- Sửa `amount` giữa kỳ: áp dụng kỳ hiện tại, không hồi tố kỳ trước.
- Gd chi bị sửa/xóa sau khi đã bắn cảnh báo: tính lại snapshot; không thu hồi thông báo, chỉ cảnh báo chiều tăng.
- `periodStartRule` chỉ áp dụng chu kỳ tháng/năm; tuần luôn theo đầu tuần tài chính chung.
- Đa tiền tệ: gd ví khác currency quy đổi tỷ giá **tại thời điểm gd** trước khi cộng `actualSpent`.

## Liên kết
- [[Giao dịch]] — nguồn `actualSpent`.
- [[Danh mục]] — phạm vi category + subcategory.
- [[Ví & Tài khoản]] — lọc theo ví, quy đổi tiền tệ.
- [[Hồ sơ & Bảo mật]] — tiền tệ mặc định & kỳ tài chính lệch từ hồ sơ cá nhân.
