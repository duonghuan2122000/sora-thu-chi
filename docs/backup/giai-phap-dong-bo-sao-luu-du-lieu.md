# GIẢI PHÁP: ĐỒNG BỘ & SAO LƯU DỮ LIỆU (SYNC & BACKUP)
### App Quản lý Thu Chi — Flutter Mobile (Offline-first)

> Tài liệu này cụ thể hóa mục "10. Đồng bộ & Sao lưu dữ liệu" trong tài liệu tính năng nghiệp vụ, kèm theo bộ màn hình thiết kế tham chiếu (SVG), tuân thủ Design System hiện có (Material Design, màu thương hiệu Teal `#0F6E56`, Coral `#D85A30`).

---

## 1. Mục tiêu & phạm vi

- App **hoàn toàn offline**, không có backend/cloud riêng → "đồng bộ" ở đây được hiểu là **đồng bộ thủ công qua file** (export/import), không phải đồng bộ real-time nhiều thiết bị.
- Người dùng cần: (1) sao lưu dữ liệu định kỳ để tránh mất dữ liệu khi đổi máy/mất máy/lỗi app, (2) khôi phục lại toàn bộ dữ liệu từ file backup.
- Giai đoạn hiện tại (theo roadmap = Giai đoạn 3) **không** làm: đồng bộ cloud (Google Drive/iCloud API tự động), merge dữ liệu hai chiều, chia sẻ nhiều người dùng. Các phần này để ngỏ cho "Tích hợp nâng cao" sau này.

---

## 2. Kiến trúc tổng thể

```
[Local DB: drift/SQLite] --export--> [Backup Package] --share/save--> Thiết bị khác / Cloud cá nhân (Drive, Zalo, Email...)
        ^                                                                      |
        |-------------------------- import/restore <--------------------------|
```

- **Backup Package** là 1 trong 2 định dạng, chọn tự động theo dữ liệu:
  - Không có ảnh hóa đơn đính kèm → xuất **file `.json`** đơn thuần (đơn giản, nhẹ, dễ đọc).
  - Có ảnh hóa đơn/chứng từ → đóng gói **file `.zip`** gồm `data.json` + thư mục `/images/` (ảnh được giữ nguyên, `data.json` chỉ lưu tên file ảnh tương đối).
  - Đuôi file thống nhất: `thuchi_backup_YYYYMMDD_HHmmss.json` hoặc `.zip`.
- Việc "chia sẻ" file backup dùng **share sheet của hệ điều hệ** (`share_plus`) → người dùng tự quyết định lưu vào Drive, gửi email, Zalo, AirDrop... App không tự tích hợp API cloud nào ở giai đoạn này (tránh phức tạp + tránh yêu cầu quyền OAuth).
- Backup tự động (nếu bật) được lưu vào **thư mục nội bộ app** (app-scoped storage), giữ tối đa N bản gần nhất (mặc định N = 5, xoay vòng FIFO) để không phình dung lượng máy.

---

## 3. Cấu trúc dữ liệu backup (JSON Schema)

```jsonc
{
  "meta": {
    "schema_version": 1,          // tăng dần khi đổi cấu trúc, dùng để kiểm tra tương thích khi restore
    "app_version": "1.4.0",
    "exported_at": "2026-09-03T12:30:00+07:00",
    "currency_default": "VND",
    "counts": {                    // dùng để hiển thị nhanh ở màn xác nhận, không cần parse toàn bộ file
      "wallets": 4,
      "categories": 18,
      "transactions": 342,
      "budgets": 6,
      "savings_goals": 2,
      "debts": 1
    },
    "has_attachments": false,      // true nếu backup là .zip có ảnh
    "checksum": "sha256:..."       // hash của phần "data" để phát hiện file bị hỏng/sửa tay
  },
  "data": {
    "wallets": [ { "id", "name", "type", "currency", "initial_balance", "is_hidden", "is_default", "icon", "color" } ],
    "categories": [ { "id", "name", "type" /*thu/chi*/, "parent_id", "icon", "color", "sort_order", "is_hidden" } ],
    "transactions": [ { "id", "type", "amount", "currency", "wallet_id", "to_wallet_id" /*transfer*/, "category_id", "datetime", "note", "tags", "attachment_ref", "location", "recurring_id" } ],
    "recurring_rules": [ { "id", "template_transaction", "frequency", "next_run", "reminder_offset" } ],
    "budgets": [ { "id", "category_id", "wallet_id", "period", "amount", "start_date" } ],
    "savings_goals": [ { "id", "name", "target_amount", "current_amount", "deadline", "contributions": [...] } ],
    "debts": [ { "id", "direction" /*vay/cho_vay*/, "counterparty", "amount", "paid_amount", "due_date", "status" } ],
    "settings": { "language", "theme", "date_format", "financial_month_start_day", "privacy_mode" }
  }
}
```

**Nguyên tắc thiết kế schema:**
- `meta.counts` tách riêng để màn hình xác nhận đọc nhanh mà **không cần parse toàn bộ `data`** (file có thể vài MB nếu nhiều giao dịch/ảnh).
- `checksum` giúp phát hiện file bị chỉnh sửa tay/hỏng khi truyền qua ứng dụng thứ 3 (nén lại, gửi email...).
- Mọi bản ghi giữ nguyên `id` gốc (UUID) để khi restore, các quan hệ khóa ngoại (giao dịch ↔ ví ↔ danh mục) không bị đứt gãy.

---

## 4. Luồng nghiệp vụ

### 4.1. Sao lưu thủ công (Manual Backup)
1. Người dùng vào **Cài đặt → Sao lưu & Khôi phục → Tạo bản sao lưu mới**.
2. App tổng hợp số liệu (`counts`) và hiển thị **bottom sheet xác nhận**: số ví/danh mục/giao dịch, dung lượng ước tính.
3. Tùy chọn: **đặt mật khẩu bảo vệ file** (xem mục 4.4).
4. Nhấn **"Tạo & Chia sẻ"** → app ghi file vào bộ nhớ tạm → mở **share sheet** hệ thống để người dùng chọn nơi lưu/gửi.
5. Hiển thị màn hình **thành công**, lưu lại thời điểm backup gần nhất để hiển thị ở màn chính (mục "Sao lưu gần nhất").

### 4.2. Tự động sao lưu (Auto Backup)
- Toggle bật/tắt trong màn "Sao lưu & Khôi phục", chọn tần suất: **Hàng ngày / Hàng tuần / Hàng tháng**.
- Thực thi ngầm bằng `WorkManager`/`flutter_local_notifications`-scheduled task (Android) hoặc `BackgroundFetch` (iOS, giới hạn theo hệ điều hệ).
- File tự động lưu vào thư mục nội bộ app (`app_documents/backups/`), **không** tự động share ra ngoài (tránh phiền người dùng).
- Giữ tối đa 5 bản gần nhất → bản cũ nhất tự xóa khi tạo bản mới (FIFO).
- Sau khi backup tự động thành công, gửi **thông báo local nhẹ nhàng** (không bắt buộc mở app): "Đã tự động sao lưu dữ liệu · 342 giao dịch".

### 4.3. Khôi phục dữ liệu (Restore)
1. Người dùng chọn **"Chọn file khôi phục"** → mở file picker hệ thống, chọn file `.json`/`.zip`, hoặc chọn 1 bản trong danh sách **"Các bản sao lưu"** có sẵn trên máy.
2. App đọc `meta` của file (không load toàn bộ `data` ngay) để kiểm tra:
   - File có đúng định dạng/`checksum` hợp lệ không → nếu hỏng, báo lỗi ngay, dừng lại.
   - `schema_version` của file có ≤ phiên bản app hỗ trợ không → nếu file mới hơn app (từ bản app tương lai), cảnh báo "không tương thích", chặn restore.
3. Hiển thị **bottom sheet xác nhận khôi phục**: tên file, ngày tạo, số ví/giao dịch/danh mục, kèm **banner cảnh báo màu coral**: dữ liệu hiện tại sẽ bị **ghi đè hoàn toàn** (chiến lược **Replace-only**, không merge — xem lý do ở mục 4.5).
4. Bắt buộc tick checkbox **"Tôi hiểu và muốn tiếp tục"** mới bật được nút khôi phục (hành động phá hủy, cần chủ đích rõ ràng).
5. Khi xác nhận: app tạo **1 bản backup an toàn tạm thời** của dữ liệu hiện tại trước khi ghi đè (auto-safety-snapshot, lưu tạm, tự xóa sau 24h) → phòng trường hợp người dùng chọn nhầm file.
6. Ghi dữ liệu mới vào DB trong 1 **transaction DB duy nhất** (all-or-nothing): nếu lỗi giữa chừng, rollback về trạng thái trước đó, không để DB ở trạng thái nửa vời.
7. Hiển thị màn **thành công**, điều hướng về Tổng quan (Dashboard).

### 4.4. Bảo mật file backup
- File backup chứa dữ liệu tài chính nhạy cảm → mặc định **khuyến nghị đặt mật khẩu**, nhưng không bắt buộc (để không cản trở người dùng phổ thông).
- Khi bật "Đặt mật khẩu bảo vệ file": mã hóa **AES-256-GCM**, khóa dẫn xuất từ mật khẩu người dùng qua **PBKDF2** (≥100.000 vòng lặp) + salt ngẫu nhiên lưu trong header file.
- Mật khẩu backup **độc lập** với mã PIN mở khóa app (2 lớp khác nhau — quên PIN không đồng nghĩa mất khả năng khôi phục, và ngược lại).
- Khi restore file có mật khẩu, yêu cầu nhập mật khẩu trước khi cho xem `meta`/số liệu tổng quan (tránh lộ thông tin dù chỉ là số lượng bản ghi).
- Dữ liệu trong DB local vẫn được mã hóa độc lập theo mục "13. Bảo mật & Quyền riêng tư" hiện có (`flutter_secure_storage` cho khóa mã hóa Hive/SQLCipher) — đây là lớp bảo vệ **cho file khi rời khỏi máy**, khác với lớp bảo vệ DB tại chỗ.

### 4.5. Vì sao chọn chiến lược "Replace-only" thay vì Merge
- Merge 2 chiều (gộp dữ liệu backup + dữ liệu hiện tại) đòi hỏi xử lý xung đột ID, trùng lặp giao dịch, đồng bộ thời gian sửa đổi (`updated_at`) — độ phức tạp cao, dễ sinh lỗi dữ liệu tài chính (sai số dư là lỗi nghiêm trọng với app tiền bạc).
- Ở giai đoạn hiện tại (app 1 thiết bị, không cloud), tình huống chính là "khôi phục sau khi mất máy/cài lại app" → **ghi đè toàn bộ** là đủ và an toàn hơn nhiều so với merge sai.
- Merge thông minh có thể cân nhắc bổ sung ở giai đoạn "Tích hợp nâng cao" nếu sau này hỗ trợ nhiều thiết bị.

---

## 5. Xử lý lỗi & edge case

| Tình huống | Xử lý |
|---|---|
| File backup bị hỏng/sai checksum | Chặn ngay ở bước đọc `meta`, thông báo lỗi rõ ràng, gợi ý chọn file khác |
| File từ phiên bản app mới hơn (`schema_version` cao hơn) | Cảnh báo "không tương thích phiên bản", chặn restore, gợi ý cập nhật app |
| Nhập sai mật khẩu file backup | Cho thử lại tối đa (không giới hạn cứng, nhưng có delay tăng dần chống brute-force cơ bản) |
| Bộ nhớ máy không đủ khi tạo backup (đặc biệt file `.zip` có ảnh) | Kiểm tra dung lượng trống trước khi ghi file, báo lỗi sớm thay vì ghi dở |
| Mất kết nối/app bị kill giữa lúc đang restore | Nhờ transaction DB + safety-snapshot tạm ở bước 4.3.5 → mở lại app vẫn ở trạng thái cũ, có thể thử restore lại |
| Người dùng chọn nhầm file backup rất cũ (schema_version thấp) | App tự chạy **migration script** nội bộ để nâng cấp cấu trúc dữ liệu cũ lên schema hiện tại trước khi ghi vào DB |
| Ảnh hóa đơn trong `.zip` bị thiếu/sai tên | Bỏ qua ảnh lỗi, vẫn phục hồi phần dữ liệu giao dịch, ghi log cảnh báo hiển thị sau khi restore xong ("12/342 giao dịch thiếu ảnh đính kèm") |

---

## 6. Thiết kế màn hình (UI Flow)

Tuân thủ Design System: App bar/nút chính màu Teal `#0F6E56`, cảnh báo/hành động phá hủy dùng Coral `#D85A30`, card phụ nền `#F1EFE8`, bo góc card `10px`, nút bấm `8px`/cao `44px`.

| # | Màn hình | File SVG | Mô tả |
|---|---|---|---|
| 1 | Sao lưu & Khôi phục (sub-page) | `svg/01-man-hinh-sao-luu-khoi-phuc.svg` | Màn chính của tính năng, truy cập từ Cài đặt. Gồm khối "Tạo bản sao lưu mới", toggle tự động sao lưu, thẻ thống kê "sao lưu gần nhất", danh sách các bản sao lưu cục bộ, và khối "Chọn file khôi phục" kèm cảnh báo. |
| 2 | Bottom sheet – Xác nhận tạo sao lưu | `svg/02-bottom-sheet-tao-sao-luu.svg` | Hiện khi bấm "Tạo bản sao lưu mới": tóm tắt số liệu, tùy chọn đặt mật khẩu, nút Hủy/Tạo & Chia sẻ. |
| 3 | Bottom sheet – Xác nhận khôi phục | `svg/03-bottom-sheet-xac-nhan-khoi-phuc.svg` | Hiện sau khi chọn file hợp lệ: thông tin file, banner cảnh báo coral, checkbox xác nhận bắt buộc, nút khôi phục chỉ bật khi đã tick. |
| 4 | Màn hình thành công | `svg/04-man-hinh-thanh-cong.svg` | Hiện sau khi tạo backup thành công: icon check, thông tin file, nút Chia sẻ file / Xong. |

> Cùng mẫu này có thể tái sử dụng (đổi icon + text) cho màn "Khôi phục thành công".

---

## 7. Thư viện Flutter đề xuất (bổ sung stack hiện có)

| Nhu cầu | Package |
|---|---|
| Chọn file khi restore | `file_picker` |
| Mở share sheet khi backup | `share_plus` |
| Đường dẫn thư mục lưu trữ nội bộ | `path_provider` |
| Nén/giải nén `.zip` (khi có ảnh đính kèm) | `archive` |
| Mã hóa AES + PBKDF2 cho file backup | `cryptography` (hoặc `encrypt` + `pointycastle`) |
| Kiểm tra dung lượng trống trước khi ghi file | `disk_space` (hoặc kênh native tối giản) |
| Lịch chạy backup tự động nền | `workmanager` |
| Băm checksum | `crypto` (sha256) |

---

## 8. Việc cần làm tiếp theo

- [ ] Thiết kế màn hình chi tiết cho trạng thái lỗi (file hỏng, sai mật khẩu, không tương thích) — hiện đang xử lý bằng dialog/snackbar đơn giản, có thể cần màn riêng nếu UX team thấy cần.
- [ ] Quyết định vị trí lưu backup tự động trên iOS (giới hạn `BackgroundFetch` khắt khe hơn Android) — cần test thực tế trước khi cam kết tần suất "hàng ngày".
- [ ] Viết migration script mẫu cho `schema_version` 1 → tương lai, làm khung sẵn trước khi có thay đổi cấu trúc dữ liệu thật.
