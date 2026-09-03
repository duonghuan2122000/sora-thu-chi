# CHI TIẾT NGHIỆP VỤ: QUẢN LÝ TÀI KHOẢN NGƯỜI DÙNG

> Thuộc app Quản lý Thu Chi (Flutter Mobile) — chi tiết hóa mục 1 trong tài liệu tổng quan tính năng nghiệp vụ.

Nhóm này gồm 4 nhánh chức năng chính:
1. Vận hành offline, không đăng ký/đăng nhập
2. Khóa ứng dụng (App Lock): PIN, vân tay, Face ID
3. Hồ sơ cá nhân (Profile)
4. Đặt lại / đổi mã PIN

---

## 1. Vận hành offline, không đăng ký/đăng nhập

**Bản chất nghiệp vụ:** đây không phải "tài khoản" theo nghĩa server-side, mà là một **hồ sơ thiết bị (device profile)** lưu local.

- Lần đầu mở app → không có màn hình đăng ký/đăng nhập, đi thẳng vào **Onboarding** (chọn tiền tệ mặc định, tạo ví đầu tiên, đặt PIN — tùy chọn).
- Toàn bộ dữ liệu (ví, giao dịch, danh mục, hồ sơ) gắn với **1 bản cài đặt app trên 1 thiết bị**. Không có khái niệm "tài khoản dùng chung nhiều máy" (khác với nhóm #11 Sharing đã bỏ qua).
- Hệ quả nghiệp vụ cần lưu ý:
  - Gỡ app / mất máy = mất toàn bộ dữ liệu nếu người dùng không backup thủ công (liên kết chặt với nhóm #10 Backup/Restore).
  - Không có "quên mật khẩu qua email/SMS" vì không có tài khoản server → việc **quên PIN** phải xử lý bằng cơ chế riêng (xem mục 4).
  - Không cần xử lý đồng bộ đa thiết bị, conflict resolution, hay session/token.

---

## 2. Khóa ứng dụng (App Lock): PIN, vân tay, Face ID

**Mục tiêu:** bảo vệ dữ liệu tài chính cá nhân khi máy bị người khác cầm.

### 2.1. Thiết lập lần đầu
- Trong Onboarding hoặc trong Cài đặt, người dùng **bật/tắt khóa app** (không bắt buộc).
- Nếu bật → bắt nhập PIN 2 lần (nhập + xác nhận) để tránh gõ nhầm khi tạo.
- Nếu thiết bị hỗ trợ sinh trắc học (có cảm biến vân tay/Face ID) → hỏi có muốn bật thêm mở khóa nhanh bằng sinh trắc học không (PIN vẫn là lớp bảo mật gốc, sinh trắc học là lớp "tiện lợi" thay thế).

### 2.2. Quy tắc PIN
- Độ dài PIN: thường 4 hoặc 6 số (nên cho người dùng chọn trong Cài đặt).
- Không cho đặt PIN toàn số giống nhau (`0000`, `1111`...) hoặc dãy tăng dần (`1234`) — cảnh báo nhưng có thể cho phép nếu người dùng vẫn xác nhận (tránh ép buộc quá mức với app cá nhân, offline).
- PIN được **hash + lưu qua `flutter_secure_storage`** (Keychain/Keystore), không lưu plaintext trong DB.

### 2.3. Luồng mở khóa
- Mỗi lần mở app từ nền (resume) hoặc sau khoảng thời gian không hoạt động (timeout cấu hình được, VD 30s/1 phút/luôn luôn) → hiện màn hình khóa.
- Nếu đã bật sinh trắc học → ưu tiên tự động trigger prompt sinh trắc học ngay khi vào màn khóa; có nút **"Dùng mã PIN thay thế"** để fallback.
- Nếu sinh trắc học thất bại (không nhận diện, người dùng hủy, thiết bị đổi vân tay đã đăng ký) → tự động rơi về màn nhập PIN, không tự thoát app.

### 2.4. Quy tắc chống brute-force (khuyến nghị dù app offline)
- Nhập sai PIN liên tiếp (VD 5 lần) → khóa tạm thời tăng dần (30s, 1 phút, 5 phút...) để chống dò PIN.
- Không nên có cơ chế **xóa trắng dữ liệu sau N lần sai** trừ khi người dùng chủ động bật tùy chọn "tự bảo vệ nâng cao" — vì rủi ro mất dữ liệu tài chính ngoài ý muốn là rất lớn đối với app cá nhân không có backup server.

### 2.5. Trạng thái đặc biệt
- Sinh trắc học bị **thu hồi quyền** (người dùng tắt trong Settings hệ điều hành) → app phát hiện và tự tắt toggle, yêu cầu bật lại bằng PIN.
- Đổi thiết bị vân tay đăng ký (thêm/xóa vân tay ở Cài đặt hệ điều hành) → theo khuyến nghị bảo mật, nên **vô hiệu hóa sinh trắc học tạm thời** và bắt xác thực lại bằng PIN trước khi cho bật lại.

---

## 3. Hồ sơ cá nhân (Profile)

**Mục tiêu:** cá nhân hóa trải nghiệm, không phải định danh pháp lý (vì không có tài khoản thật).

| Trường dữ liệu | Chi tiết nghiệp vụ |
|---|---|
| Avatar | Chọn ảnh từ thư viện hoặc chụp mới; có thể dùng chữ cái viết tắt tên làm avatar mặc định nếu không chọn ảnh |
| Tên hiển thị | Text tự do, dùng để hiển thị chào mừng, không dùng để định danh/đăng nhập |
| Tiền tệ mặc định | Áp dụng khi tạo ví mới, khi hiển thị tổng hợp báo cáo đa ví; đổi tiền tệ mặc định **không** tự đổi tiền tệ của các ví đã tạo trước đó (mỗi ví có tiền tệ riêng theo mục #2) |
| Múi giờ | Ảnh hưởng đến cách gán ngày/giờ cho giao dịch mới và mốc "đầu ngày/đầu tháng tài chính" (liên quan mục #12 — kỳ tài chính có thể bắt đầu từ ngày 25) |

### Ràng buộc nghiệp vụ cần làm rõ khi thiết kế
- Đổi tiền tệ mặc định **sau khi đã có giao dịch** → cần cảnh báo rõ đây chỉ là giá trị mặc định cho ví/giao dịch mới, không hồi tố dữ liệu cũ, tránh người dùng hiểu nhầm là quy đổi toàn bộ số liệu.
- Đổi múi giờ khi đang có giao dịch định kỳ (mục #3 tổng quan) đã lên lịch → cần xác định lại có tính toán lại thời điểm sinh giao dịch tiếp theo hay không.

---

## 4. Đặt lại / đổi mã PIN

Đây là nghiệp vụ **dễ bị bỏ sót** vì app không có server để "quên mật khẩu qua email".

### 4.1. Đổi PIN (khi còn nhớ PIN cũ)
- Vào Cài đặt → Đổi mã PIN → bắt xác thực PIN cũ (hoặc sinh trắc học) trước → nhập PIN mới → xác nhận lại PIN mới → lưu.

### 4.2. Quên PIN (không nhớ PIN cũ)
Cần định nghĩa rõ chính sách vì có 2 hướng:

- **Hướng A (đơn giản, chấp nhận mất bảo mật để giữ dữ liệu):** cho phép "Reset PIN" bằng cách xác nhận qua một câu hỏi bảo mật đã thiết lập trước, hoặc bắt buộc phải **khôi phục từ file JSON backup** (mục #10) sau khi gỡ/cài lại app.
- **Hướng B (ưu tiên bảo mật tuyệt đối):** không có đường vòng — mất PIN đồng nghĩa phải **xóa dữ liệu app và cài lại từ đầu**, khôi phục bằng file backup JSON nếu người dùng có.

> Cần chốt 1 trong 2 hướng ở giai đoạn thiết kế vì ảnh hưởng trực tiếp đến trải nghiệm và mức độ an toàn dữ liệu; hầu hết app quản lý thu chi offline nghiêng về **Hướng B** kèm khuyến khích mạnh việc backup định kỳ.

---

## Liên kết chéo với các nhóm nghiệp vụ khác

| Nhóm liên quan | Mối liên hệ |
|---|---|
| #10 Backup/Restore | Là "van an toàn" duy nhất khi mất PIN hoặc đổi máy |
| #13 Bảo mật & quyền riêng tư | Mã hóa DB local, ẩn số dư (Privacy mode) là phần mở rộng tự nhiên của nhóm này |
| #12 Tiện ích | Múi giờ, định dạng ngày, kỳ tài chính đều bắt nguồn từ hồ sơ cá nhân |
