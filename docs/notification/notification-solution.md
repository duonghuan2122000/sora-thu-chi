# GIẢI PHÁP NGHIỆP VỤ: THÔNG BÁO & NHẮC NHỞ
### App quản lý thu chi (Flutter, offline, local-first)

> Phạm vi: chi tiết hóa mục **9. Thông báo & Nhắc nhở** trong tài liệu tính năng nghiệp vụ, kèm màn hình thiết kế tương ứng, tuân theo Design System hiện có (Material flat, teal `#0F6E56`, coral `#D85A30`).

---

## 1. Tổng quan

Vì app hoạt động **hoàn toàn offline, không có server/backend**, toàn bộ logic thông báo phải chạy **local trên thiết bị**: tự tính toán điều kiện, tự lên lịch, tự hiển thị bằng `flutter_local_notifications`. Không có push notification từ server (FCM) — mọi thông báo trong tài liệu này đều là **local notification** được app tự lên lịch hoặc tự bắn ra khi có sự kiện nội bộ (thêm giao dịch, đến giờ hẹn...).

Nghiệp vụ thông báo gồm 2 phần:
1. **Notification Engine** — tầng kỹ thuật chịu trách nhiệm tính toán khi nào cần nhắc, và bắn local notification.
2. **Notification Center** — tầng UI trong app, lưu lại lịch sử thông báo để người dùng xem lại (kể cả khi họ bỏ lỡ hoặc đã tắt thông báo hệ thống), tương tự "hộp thư thông báo" như các app ngân hàng.

---

## 2. Phân loại thông báo & Business rule

| # | Loại thông báo | Điều kiện kích hoạt | Tần suất tối đa | Deep link khi tap |
|---|---|---|---|---|
| 1 | **Nhắc nhập giao dịch hàng ngày** | Đến giờ đã cấu hình (VD 20:30) **và** người dùng bật cờ "chỉ nhắc nếu chưa ghi giao dịch nào hôm nay" thì kiểm tra local DB trước khi bắn | 1 lần/ngày, theo các ngày trong tuần đã chọn | Màn hình Thêm giao dịch nhanh |
| 2 | **Cảnh báo ngân sách** | Tổng chi của danh mục/ví đạt ngưỡng "sớm" (mặc định 80%) hoặc vượt ngưỡng "vượt mức" (100%) — tính lại **ngay sau khi lưu một giao dịch chi tiêu** thuộc danh mục có ngân sách | Tối đa 1 lần/ngưỡng/danh mục/kỳ ngân sách (tránh spam khi thêm nhiều giao dịch liên tiếp) | Màn hình chi tiết ngân sách của danh mục đó |
| 3 | **Nhắc giao dịch định kỳ sắp đến hạn** | Ngày đến hạn của một giao dịch định kỳ (hóa đơn, trả nợ...) trừ đi số ngày nhắc trước (mặc định 3 ngày) = hôm nay | 1 lần/khoản định kỳ/chu kỳ, cộng thêm 1 lần đúng ngày đến hạn | Màn hình chi tiết giao dịch định kỳ (xác nhận đã thanh toán / tạo giao dịch) |
| 4 | **Nhắc mục tiêu tiết kiệm** | Đến lịch đóng góp định kỳ của mục tiêu (nếu người dùng đặt) hoặc mục tiêu đạt các mốc 50%/75%/100% | 1 lần/mốc, hoặc theo chu kỳ đóng góp đã đặt | Màn hình chi tiết mục tiêu tiết kiệm |
| 5 | **Tổng kết cuối tuần / cuối tháng** | Đến thời điểm đã cấu hình (VD Chủ nhật 20:00, hoặc ngày cuối tháng 20:00) | 1 lần/tuần và 1 lần/tháng | Màn hình Báo cáo, đã lọc sẵn theo kỳ vừa tổng kết |

**Nguyên tắc chung:**
- Mỗi loại thông báo có **switch bật/tắt độc lập** — người dùng toàn quyền kiểm soát, tránh gây phiền.
- Không bắn thông báo nếu app đang **mở và đang ở đúng màn hình liên quan** (VD đang xem báo cáo thì không cần tổng kết tuần) — tránh trùng lặp.
- Nội dung thông báo luôn **chứa số liệu cụ thể** (số tiền, phần trăm, số ngày còn lại) để có giá trị hành động ngay, không chỉ là nhắc chung chung.
- Do không có server, các thông báo dạng "đến giờ" (loại 1, 3, 5) được **lên lịch trước (schedule)** bằng `flutter_local_notifications` + `timezone` package; các thông báo dạng "theo sự kiện" (loại 2, một phần loại 4) được **bắn ngay (show)** tại thời điểm tính toán sau khi có giao dịch mới.

---

## 3. Kiến trúc kỹ thuật

### 3.1. Data model

```
NotificationRule
- id, type (daily_reminder | budget_alert | recurring_due | goal_reminder | period_summary)
- enabled (bool)
- config (JSON riêng theo type, VD: {"hour":20,"minute":30,"weekdays":[1,2,3,4,5,6],"onlyIfNoTxnToday":true})
- lastFiredAt (per key liên quan, VD per categoryId+period, để chống bắn trùng)

NotificationLog   // phục vụ Notification Center trong app
- id, type, title, body, payload (deep link data), createdAt, readAt (nullable)
- relatedEntityId (categoryId / recurringTxnId / goalId / period)
```

### 3.2. Cơ chế lên lịch & kiểm tra

- **Loại theo giờ cố định (1, 3, 5):** dùng `flutter_local_notifications` `zonedSchedule` với `matchDateTimeComponents` (`time` cho hàng ngày, `dayOfWeekAndTime` cho hàng tuần, `dayOfMonthAndTime` cho hàng tháng) — hệ điều hành tự bắn đúng giờ kể cả khi app bị kill, không cần app chạy nền liên tục.
- **Loại theo ngưỡng/sự kiện (2, một phần 4):** không thể "lên lịch trước" vì phụ thuộc dữ liệu người dùng nhập; được tính toán **ngay trong transaction lưu giao dịch** (sau khi insert/update vào `drift`), so sánh tổng chi lũy kế với ngưỡng ngân sách, nếu vượt mốc mới (so với `lastFiredAt`) thì gọi `flutter_local_notifications.show()` ngay lập tức.
- **Nhắc hóa đơn định kỳ (3):** một job chạy khi app mở (App start / resume) quét các `RecurringTransaction` có ngày đến hạn trong khoảng `[hôm nay, hôm nay + N ngày]` để **đăng ký lại lịch schedule** — vì ngày đến hạn của giao dịch định kỳ thay đổi theo chu kỳ, không thể lên lịch cố định một lần.
- **Trung tâm thông báo:** mỗi khi có `NotificationRule` được kích hoạt (dù là schedule hay show ngay), song song ghi một bản ghi vào bảng `NotificationLog` trong `drift` — đảm bảo người dùng luôn xem lại được lịch sử dù có bỏ lỡ thông báo hệ thống (do tắt quyền, do chế độ im lặng...).

### 3.3. Quyền & giới hạn nền tảng cần xử lý

- Xin quyền `POST_NOTIFICATIONS` (Android 13+) và quyền thông báo iOS ngay trong luồng onboarding, giải thích rõ lý do trước khi hệ thống hỏi (soft-ask).
- Với Android, dùng `exact alarm` (`SCHEDULE_EXACT_ALARM`) cho nhắc giờ cố định; cảnh báo người dùng nếu bị OS tối ưu pin chặn (Xiaomi/Oppo... hay giết nền) — hướng dẫn thêm app vào danh sách autostart nếu cần.
- Tách riêng **notification channel** theo loại (Android) để người dùng có thể tắt từng loại ngay từ Cài đặt hệ thống mà không ảnh hưởng loại khác.

---

## 4. Màn hình thiết kế

Tuân thủ Design System đã có: teal `#0F6E56` cho app bar/toggle bật, coral `#D85A30` chỉ dùng cho ngữ cảnh cảnh báo chi tiêu/ngân sách, bo góc card `10px`, sub-page dùng app bar teal + nút back, không có bottom nav.

| File | Màn hình | Mô tả |
|---|---|---|
| `01-cai-dat-thong-bao.svg` | **Cài đặt Thông báo & Nhắc nhở** (sub-page từ Cài đặt) | Danh sách theo nhóm: Nhắc hàng ngày, Ngân sách, Giao dịch định kỳ, Mục tiêu tiết kiệm, Tổng kết tự động — mỗi nhóm có toggle bật/tắt và dòng cấu hình chi tiết (chevron) |
| `02-cau-hinh-nhac-nhap-giao-dich.svg` | **Cấu hình chi tiết: Nhắc nhập giao dịch hàng ngày** | Time picker chọn giờ:phút, chọn lặp lại theo ngày trong tuần (chip tròn), toggle "chỉ nhắc nếu chưa ghi giao dịch", khối xem trước nội dung thông báo |
| `03-trung-tam-thong-bao.svg` | **Trung tâm thông báo trong app** | Danh sách thông báo nhóm theo "Hôm nay"/"Tuần này", chấm teal đánh dấu chưa đọc, icon theo loại (chuông = nhắc chung, cảnh báo = ngân sách, lịch = định kỳ, bullseye = mục tiêu, pie = tổng kết) |
| `04-mau-thong-bao-day.svg` | **Mẫu thông báo đẩy (push notification)** | Mô phỏng 4 mẫu thông báo hệ thống hiển thị trên màn hình khóa: cảnh báo ngân sách, nhắc nhập giao dịch, nhắc hóa đơn định kỳ, tổng kết tuần |

---

## 5. Luồng người dùng (tóm tắt)

1. Người dùng vào **Cài đặt → Thông báo & Nhắc nhở** → bật/tắt từng loại, bấm vào dòng cấu hình để chỉnh chi tiết (giờ, ngưỡng, số ngày nhắc trước).
2. Notification Engine lên lịch hoặc tính toán ngầm theo cấu hình đó.
3. Khi đủ điều kiện, hệ thống hiển thị **push notification** (mẫu ở màn hình 4) đồng thời ghi vào **Notification Center**.
4. Người dùng tap vào thông báo → điều hướng thẳng đến màn hình liên quan (ví dụ tap cảnh báo ngân sách → mở chi tiết ngân sách danh mục Ăn uống) để hành động ngay.
5. Nếu bỏ lỡ thông báo đẩy, người dùng vẫn có thể mở **Trung tâm thông báo** (biểu tượng chuông ở màn hình Tổng quan) để xem lại toàn bộ lịch sử.
