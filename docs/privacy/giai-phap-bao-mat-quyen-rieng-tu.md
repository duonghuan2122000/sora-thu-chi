# GIẢI PHÁP NGHIỆP VỤ: BẢO MẬT & QUYỀN RIÊNG TƯ
## App Quản Lý Thu Chi (Flutter Mobile — Offline)

> Tài liệu chi tiết hóa mục 1 (Authentication) và mục 13 (Security & Privacy) trong bản đặc tả tính năng nghiệp vụ, kèm mục 12 (Privacy mode). Dùng làm căn cứ triển khai code và thiết kế UI.

---

## 1. Mục tiêu & phạm vi

Vì ứng dụng **hoàn toàn offline, không tài khoản, không server**, toàn bộ trách nhiệm bảo vệ dữ liệu tài chính cá nhân nằm ở tầng thiết bị. Giải pháp cần đạt:

1. **Ngăn truy cập trái phép** khi thiết bị bị người khác cầm/mất — thông qua khóa PIN + sinh trắc học.
2. **Bảo vệ dữ liệu tại chỗ (data-at-rest)** — mã hóa toàn bộ database local, không lưu bất kỳ thông tin thẻ/tài khoản ngân hàng thật nào.
3. **Bảo vệ quyền riêng tư khi dùng ở nơi công cộng** — Privacy mode che số tiền.
4. **Xác thực lại (re-auth)** trước các thao tác nhạy cảm: xuất/khôi phục dữ liệu, tắt khóa app, đổi PIN.
5. **Xử lý hợp lý tình huống không có server**: quên PIN, nhập sai nhiều lần, mất thiết bị.

---

## 2. Kiến trúc bảo mật tổng thể

```
┌─────────────────────────────────────────────────────────┐
│                     APP LAYER (UI)                        │
│   Lock Screen · Security Settings · Privacy Mode Toggle   │
└───────────────┬─────────────────────────────┬────────────┘
                │                              │
                ▼                              ▼
   ┌─────────────────────────┐    ┌─────────────────────────┐
   │   AUTH SERVICE           │    │   PRIVACY SERVICE        │
   │  - Xác minh PIN (hash)   │    │  - Trạng thái ẩn số dư   │
   │  - local_auth (sinh trắc)│    │  - Re-auth cho hành động │
   │  - Đếm số lần sai/lockout│    │    nhạy cảm              │
   └───────────┬──────────────┘    └───────────┬─────────────┘
               │                                │
               ▼                                ▼
   ┌─────────────────────────────────────────────────────────┐
   │              SECURE STORAGE (flutter_secure_storage)      │
   │  Keystore (Android) / Keychain (iOS)                       │
   │  - pin_hash, pin_salt        - db_encryption_key            │
   │  - biometric_enabled         - failed_attempts, lock_until  │
   └───────────────────────────┬─────────────────────────────┘
                                │ cấp key giải mã
                                ▼
   ┌─────────────────────────────────────────────────────────┐
   │        ENCRYPTED LOCAL DATABASE (drift + SQLCipher)        │
   │        Giao dịch · Ví · Danh mục · Ngân sách · Mục tiêu    │
   └─────────────────────────────────────────────────────────┘
```

**Nguyên tắc tách lớp quan trọng:** mã PIN **không** được dùng trực tiếp làm khóa mã hóa database. Lý do: nếu người dùng đổi PIN, không cần giải mã/mã hóa lại toàn bộ DB. Thay vào đó:

- `db_encryption_key`: chuỗi ngẫu nhiên 256-bit sinh một lần khi cài đặt lần đầu, lưu trong `flutter_secure_storage` (được hệ điều hành bảo vệ bằng Keystore/Keychain, không thể đọc được kể cả khi root/jailbreak ở mức cơ bản).
- `pin_hash` + `pin_salt`: PIN người dùng nhập được băm bằng **PBKDF2/Argon2** với salt ngẫu nhiên trước khi lưu — không bao giờ lưu PIN dạng plain text.
- Sinh trắc học chỉ là **lớp xác thực thay thế** cho PIN (do OS quản lý qua `local_auth`), không thay thế cơ chế mã hóa.

---

## 3. Luồng nghiệp vụ chi tiết

### 3.1. Thiết lập bảo mật lần đầu (Onboarding)
1. Sau khi hoàn tất thiết lập hồ sơ cá nhân (tên, tiền tệ), app **bắt buộc** yêu cầu tạo mã PIN (6 chữ số) — không cho phép bỏ qua, vì đây là lớp bảo vệ duy nhất.
2. Màn hình **"Tạo mã PIN"** → nhập 6 số → chuyển sang **"Xác nhận mã PIN"** → nhập lại.
   - Nếu khớp: lưu `pin_hash`, sinh `db_encryption_key`, khởi tạo DB mã hóa, vào app.
   - Nếu không khớp: hiện lỗi "Mã PIN không khớp", xóa nhập liệu, yêu cầu nhập lại từ bước 1 (không lộ mã đã nhập).
3. Sau khi tạo PIN thành công, hỏi **"Bật mở khóa bằng vân tay/Face ID?"** (nếu thiết bị hỗ trợ) — tùy chọn, mặc định tắt để tôn trọng quyền riêng tư, người dùng tự bật.
4. Hiển thị cảnh báo một lần: *"Vì ứng dụng hoạt động offline, chúng tôi không thể khôi phục mã PIN nếu bạn quên. Hãy sao lưu dữ liệu định kỳ."*

### 3.2. Khóa / Mở khóa ứng dụng (App Lock)
- **Thời điểm kích hoạt khóa:**
  - Mỗi lần mở app từ trạng thái đã tắt hẳn (cold start).
  - Khi app quay lại từ **background** sau khoảng thời gian không hoạt động vượt ngưỡng cấu hình (mặc định: ngay lập tức; tùy chọn: 30s / 1 phút / 5 phút / không bao giờ).
- **Luồng mở khóa:**
  1. Hiện màn hình khóa toàn màn hình (không app bar, không bottom nav).
  2. Nếu sinh trắc học đang bật → tự động trigger prompt sinh trắc học ngay khi vào màn hình.
     - Thành công → vào thẳng app.
     - Thất bại/hủy → rơi về nhập PIN, vẫn cho phép bấm icon vân tay để thử lại.
  3. Nếu sinh trắc học tắt hoặc không khả dụng → chỉ hiện numpad nhập PIN.
  4. Nhập đúng 6 số khớp `pin_hash` → mở khóa, giải mã DB bằng `db_encryption_key`, vào Dashboard.
  5. Nhập sai → rung nhẹ (haptic), dot indicator đỏ, xóa nhập liệu, tăng bộ đếm `failed_attempts`.

### 3.3. Giới hạn số lần nhập sai & khóa tạm thời (Lockout)
Do không có server để rate-limit, xử lý hoàn toàn local:

| Số lần sai liên tiếp | Hành động |
|---|---|
| 1–4 lần | Cho nhập lại ngay, chỉ cảnh báo bằng rung + dot đỏ |
| 5 lần | Khóa nhập trong **30 giây**, hiện đếm ngược, numpad vô hiệu hóa |
| 6–9 lần | Mỗi lần sai thêm → tăng thời gian khóa (1 phút → 5 phút) |
| 10 lần | Khóa **5 phút**, hiện nút phụ "Quên mã PIN?" dẫn tới luồng 3.5 |

- Thời điểm hết khóa (`lock_until`) lưu trong secure storage kèm timestamp, để nếu người dùng tắt app/khởi động lại vẫn duy trì hình phạt (chống bypass bằng cách force-close).
- **Không xóa dữ liệu tự động** dù sai nhiều lần — tránh mất dữ liệu do trẻ em/người khác nghịch máy; việc xóa dữ liệu chỉ xảy ra khi người dùng **chủ động xác nhận** ở luồng "Quên mã PIN".

### 3.4. Đổi mã PIN
Truy cập từ **Cài đặt → Bảo mật → Đổi mã PIN**:
1. Yêu cầu xác thực lại — nhập PIN hiện tại (hoặc sinh trắc học nếu đang bật).
2. Nhập PIN mới (6 số) → xác nhận PIN mới (nhập lại lần 2).
3. Validate: PIN mới không được trùng PIN cũ; khuyến nghị (không bắt buộc) không dùng dãy số liên tiếp (123456) hoặc lặp (111111) — hiện cảnh báo mềm, vẫn cho phép nếu người dùng cố tình chọn.
4. Lưu `pin_hash` mới — **không** đụng đến `db_encryption_key`, nên không cần giải mã/mã hóa lại DB.
5. Thông báo thành công, quay về màn hình Bảo mật.

### 3.5. Quên mã PIN (Forgot PIN) — xử lý khi không có server
Vì offline, không thể gửi OTP hay reset qua email. Hai lựa chọn được thiết kế song song:

**A. Khôi phục từ bản sao lưu (khuyến nghị, không mất dữ liệu):**
- Nếu người dùng có file backup JSON đã xuất trước đó (mục 10 — Sync & Backup), có thể: gỡ app → cài lại → chọn "Khôi phục từ file backup" ngay ở màn hình onboarding → import dữ liệu → **đặt PIN mới** trong lúc khôi phục.

**B. Reset toàn bộ ứng dụng (mất dữ liệu, không có backup):**
1. Tại màn hình khóa, sau khi bị lockout (mục 3.3) hoặc bất kỳ lúc nào, có link nhỏ "Quên mã PIN?".
2. Hiện màn hình cảnh báo rõ ràng, màu cảnh báo (coral): *"Vì lý do bảo mật, ứng dụng không thể khôi phục mã PIN. Tiếp tục sẽ XÓA TOÀN BỘ dữ liệu giao dịch, ví, ngân sách trên thiết bị này."*
3. Yêu cầu người dùng gõ chính xác một cụm xác nhận (VD: "XÓA DỮ LIỆU") vào ô nhập để tránh bấm nhầm — tương tự cơ chế xác nhận hành động phá hủy không thể hoàn tác.
4. Nếu xác nhận: xóa `pin_hash`, `db_encryption_key` cũ, xóa toàn bộ file database mã hóa → app quay về trạng thái onboarding lần đầu.
5. Nếu hủy: quay lại màn hình khóa, bộ đếm lockout giữ nguyên.

### 3.6. Xác thực sinh trắc học (Biometric)
- Dùng package `local_auth`, hỗ trợ Fingerprint (Android) và Face ID/Touch ID (iOS).
- Bật/tắt tại **Cài đặt → Bảo mật → Mở khóa bằng vân tay/Face ID** (toggle).
- Khi bật lần đầu: gọi `local_auth` yêu cầu xác thực ngay để xác nhận thiết bị có sinh trắc học hợp lệ trước khi lưu `biometric_enabled = true`.
- Nếu người dùng xóa hết vân tay/Face ID đã đăng ký trên hệ điều hành sau khi đã bật trong app → `local_auth` trả lỗi → app tự động tắt cờ `biometric_enabled` và fallback về PIN, đồng thời báo cho người dùng.
- Sinh trắc học **không thay thế** việc phải có PIN — luôn tồn tại PIN làm phương án dự phòng.

### 3.7. Tự động khóa (Auto-lock) khi rời khỏi app
- Cấu hình tại **Cài đặt → Bảo mật → Tự động khóa**: Ngay lập tức / Sau 30 giây / Sau 1 phút / Sau 5 phút.
- Cơ chế: lắng nghe `AppLifecycleState` — khi app chuyển sang `paused`/`inactive`, ghi lại timestamp; khi quay lại `resumed`, so sánh với ngưỡng cấu hình để quyết định có yêu cầu xác thực lại hay không.
- Ngoài ra, khi app ở trạng thái `inactive` (VD: đang chuyển sang app switcher trên iOS), phủ một lớp che (privacy overlay) lên toàn bộ nội dung để tránh lộ số liệu tài chính trong ảnh xem trước đa nhiệm (task switcher screenshot).

### 3.8. Chế độ riêng tư — Ẩn số dư (Privacy Mode)
- Toggle nhanh tại Dashboard (icon con mắt cạnh số dư tổng) **và** tại Cài đặt → Bảo mật.
- Khi bật: mọi số tiền hiển thị trên Dashboard, card thống kê nhanh, danh sách ví được thay bằng `••••••` (giữ nguyên định dạng độ dài tương đối để không lộ số chữ số).
- Chạm vào icon con mắt để **tạm thời hiện lại** — có thể yêu cầu xác thực sinh trắc học/PIN nếu người dùng bật thêm tùy chọn "Xác thực khi xem dữ liệu nhạy cảm" (mục 3.9), hoặc hiện ngay không cần xác thực nếu không bật tùy chọn đó (mặc định: hiện ngay, xác thực là tùy chọn nâng cao).
- Trạng thái Privacy mode được lưu bền (persist) qua các lần mở app, không tự tắt.

### 3.9. Xác thực lại cho hành động nhạy cảm (Sensitive Action Re-auth)
Bật/tắt tại Cài đặt → Bảo mật (toggle "Xác thực khi thao tác nhạy cảm"). Khi bật, các hành động sau yêu cầu nhập lại PIN/sinh trắc học ngay trước khi thực hiện, kể cả khi app đang trong phiên đã mở khóa:

- Xuất dữ liệu / tạo file backup JSON.
- Khôi phục (import) từ file backup — **luôn bắt buộc xác thực** dù toggle này tắt, vì đây là hành động ghi đè dữ liệu không thể hoàn tác.
- Tắt hoàn toàn khóa PIN (không dùng App Lock nữa).
- Xóa toàn bộ dữ liệu / Reset app.
- Hiện lại số dư khi đang ở Privacy mode (nếu người dùng chọn mức bảo mật cao).

### 3.10. Mã hóa dữ liệu local
- Toàn bộ database `drift` chạy trên nền **SQLCipher** (gói `sqlcipher_flutter_libs` + `drift/native` với factory mã hóa) — mã hóa AES-256 toàn bộ file `.sqlite` trên đĩa.
- `db_encryption_key` sinh bằng CSPRNG (Cryptographically Secure Random), không bao giờ hard-code, không bao giờ log ra console/crash report.
- Ảnh hóa đơn/chứng từ đính kèm giao dịch (mục 3 — Transactions) lưu trong thư mục sandbox riêng của app (`ApplicationDocumentsDirectory`), không lưu vào thư viện ảnh chung của thiết bị, để tránh app khác truy cập.
- **Không lưu số thẻ/tài khoản ngân hàng thật** — trường "Ví ngân hàng/thẻ tín dụng" chỉ là nhãn tham chiếu do người dùng tự đặt tên (VD: "Vietcombank - chi tiêu"), không có input riêng cho số thẻ/CVV.

---

## 4. Đề xuất khóa lưu trữ (Secure Storage Keys)

| Key | Nội dung | Ghi chú |
|---|---|---|
| `auth.pin_hash` | Hash PIN (Argon2/PBKDF2) | Không bao giờ đọc ngược |
| `auth.pin_salt` | Salt ngẫu nhiên | Riêng theo thiết bị |
| `auth.biometric_enabled` | `true`/`false` | |
| `auth.failed_attempts` | Số nguyên | Reset về 0 khi nhập đúng |
| `auth.lock_until` | Timestamp | Dùng cho cơ chế lockout |
| `auth.auto_lock_duration` | Enum (immediate/30s/1m/5m) | |
| `auth.require_reauth_sensitive` | `true`/`false` | |
| `privacy.hide_balance` | `true`/`false` | Trạng thái Privacy mode |
| `db.encryption_key` | Chuỗi 256-bit | Cấp cho SQLCipher khi mở DB |

---

## 5. Danh sách màn hình thiết kế (đính kèm SVG)

| # | Tên màn hình | File SVG | Loại màn hình (theo Design System §2.2) |
|---|---|---|---|
| 1 | Màn hình khóa (Mở khóa PIN + vân tay) | `01-man-hinh-khoa.svg` | Bảo mật — toàn màn hình |
| 2 | Tạo mã PIN (lần đầu) | `02-tao-ma-pin.svg` | Bảo mật — toàn màn hình |
| 3 | Xác nhận mã PIN | `03-xac-nhan-pin.svg` | Bảo mật — toàn màn hình |
| 4 | Cài đặt → Bảo mật (danh sách) | `04-cai-dat-bao-mat.svg` | Sub-page |
| 5 | Khóa tạm thời (Lockout) | `05-khoa-tam-thoi.svg` | Bảo mật — toàn màn hình |
| 6 | Dashboard ở chế độ Privacy mode | `06-privacy-mode-dashboard.svg` | Màn hình chính |
| 7 | Quên mã PIN — Xác nhận xóa dữ liệu | `07-quen-pin-reset.svg` | Bảo mật — toàn màn hình (dialog cảnh báo) |

Tất cả màn hình tuân thủ đúng bảng màu, typography, bo góc trong `design-system-app-thu-chi.md` (teal `#0F6E56`, coral `#D85A30` chỉ dùng cho cảnh báo/chi tiêu, bo góc card `10px`, khung màn hình `24–28px`).

---

## 6. Ghi chú triển khai kỹ thuật (Flutter packages)

| Nhu cầu | Package |
|---|---|
| Lưu khóa/hash an toàn (Keystore/Keychain) | `flutter_secure_storage` |
| Sinh trắc học | `local_auth` |
| Database mã hóa | `drift` + `sqlcipher_flutter_libs` |
| Hash PIN | `pointycastle` (Argon2/PBKDF2) hoặc `crypto` (PBKDF2 tối thiểu) |
| Che nội dung khi vào task switcher | `flutter_windowmanager` (Android FLAG_SECURE) + xử lý `didChangeAppLifecycleState` (iOS overlay) |
| Quản lý trạng thái auth/privacy | `GetX` (đồng bộ với state management đã chọn) |

---

## 7. Tóm tắt quyết định UX quan trọng

1. PIN 6 chữ số, bắt buộc thiết lập, không cho bỏ qua.
2. Sinh trắc học là lớp **tùy chọn cộng thêm**, PIN luôn là phương án dự phòng bắt buộc.
3. Không tự xóa dữ liệu khi sai PIN nhiều lần — chỉ khóa tạm thời tăng dần; xóa dữ liệu chỉ khi người dùng **chủ động xác nhận** ở luồng Quên PIN.
4. Đổi PIN không đụng đến khóa mã hóa DB (tách lớp PIN ≠ khóa mã hóa).
5. Privacy mode và Auto-lock là hai cơ chế độc lập, có thể bật riêng lẻ.
6. Toàn bộ hành vi khóa/mở khóa xử lý 100% on-device, không phụ thuộc mạng.
