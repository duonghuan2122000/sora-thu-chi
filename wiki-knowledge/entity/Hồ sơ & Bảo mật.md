---
title: "Hồ sơ & Bảo mật"
date: 2026-09-03
tags: [module, auth, security, pin, entity]
sources:
  - ../docs/auth/chi-tiet-quan-ly-tai-khoan-nguoi-dung.md
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md
  - ../../.specify/specs/3/spec.md
  - ../../.specify/specs/3/data-model.md
  - ../../.specify/specs/17/spec.md
  - ../../.specify/specs/17/data-model.md
  - ../../.specify/specs/18/spec.md
  - ../../.specify/specs/18/data-model.md
---

# Hồ sơ & Bảo mật

Không phải "tài khoản" server — là **device profile** lưu local. App offline: không đăng ký/đăng nhập/đồng bộ. Gồm: vận hành offline, khóa app (PIN/vân tay/Face ID), hồ sơ cá nhân, đổi/quên PIN.

## Vận hành offline
- Dữ liệu gắn **1 bản cài đặt trên 1 thiết bị**.
- Hệ quả: gỡ app/mất máy = mất dữ liệu nếu không backup thủ công → backup JSON là "van an toàn" duy nhất (xem [[Lộ trình phát triển]] GĐ3); **quên PIN không có email/SMS reset** vì không có server.
- ⚠ Onboarding hoàn chỉnh (chọn tiền tệ, tạo ví đầu tiên...) **chưa tồn tại**; khi có, sẽ gắn quanh luồng thiết lập PIN (xem chốt bên dưới).

## Khóa app (App Lock)
> **Chốt PBI 3 (2026-09-03, đã triển khai)** — quyết định user, **lệch `docs/auth §2.1`** (vốn "bật/tắt tùy chọn"): khóa app = mã PIN **bắt buộc ngay lần đầu mở app**, luôn có hiệu lực đợt này (không có luồng tắt). `docs/auth` chưa đồng bộ → nguồn thô cần cập nhật theo sau.

**Thiết lập lần đầu (bắt buộc):**
- Lần đầu mở app trên thiết bị chưa có PIN → màn thiết lập đứng **độc lập trước mọi nội dung** (chưa có Onboarding hoàn chỉnh); không nút bỏ qua/back.
- Nhập PIN rồi **xác nhận lại lần 2**; chỉ kích hoạt khi khớp (FR-002). Lệch → báo lỗi, nhập lại từ đầu, **chưa ghi gì**; thoát app giữa chừng chưa khớp → lần sau vẫn bắt thiết lập (SC-006).
- Vừa thiết lập xong trong phiên → **không hỏi lại ngay**; khóa có hiệu lực từ lần vào app sau.

**Quy tắc PIN:**
- **4 số cố định** đợt này, mỗi ký tự hiện **chấm tròn, không lộ chữ số** (FR-003). Chọn độ dài 4/6 = đợt sau.
- Chuỗi dễ đoán (`0000`, `1111`, `1234`, `4321`) → **cảnh báo** nhưng cho dùng nếu user xác nhận "Tiếp tục" (không chặn cứng).
- Lưu: **hash SHA-256 có muối** (salt 16B ngẫu nhiên, gói `crypto`) — chuỗi `"{saltB64}.{hashB64}"` ở key `pin_salt_hash` của `flutter_secure_storage` (Keychain/Keystore); **không lưu PIN đọc được** (FR-011). Trạng thái chống dò lưu key riêng `lock_state` (JSON: `streak`, `lockUntilEpochMs`), **độc lập dữ liệu tài chính** (không phải entity drift).

**Luồng mở khóa (khi đã có PIN):**
- Mỗi lần **khởi động app** và mỗi lần **trở về từ nền** → màn khóa **toàn màn hình** chặn trước mọi nội dung (không app bar/bottom nav — [[Design system]]), không lộ nội dung tài chính phía sau (SC-002).
- Nhập đúng → vào **đúng màn đang đứng trước khi khóa**, không reset về màn đầu (FR-007).
- Nhập sai → báo chung **"mã PIN không đúng"** (không tiết lộ ký tự nào đúng/sai), xóa ký tự vừa nhập, cho nhập lại (FR-008).
- Back/back-gesture tại màn khóa & màn thiết lập **không thoát được** (FR-010); ngoài phạm vi luồng này: đổi PIN, quên PIN, tắt khóa, tự khóa theo timeout.

**Chống brute-force (chốt):**
- Chỉ tính khi gõ **đủ 4 số** rồi sai; sửa giữa chừng bằng backspace không tính.
- Sai **5 lần liên tiếp** → chặn **30s**; tái phạm (chưa có lần đúng xen giữa) tăng bậc **30s → 1p → 5p → 15p (trần)**; nhập đúng → đếm về 0 (FR-009/SC-004).
- Thời gian chặn còn lại **giữ nguyên khi thoát app** (lưu `lock_state`); hết chặn chỉ mở lại nhập, **không tự mở khóa**.
- Không bật mặc định "xóa trắng dữ liệu sau N lần sai" (rủi ro mất dữ liệu tài chính) — ngoài đợt.
- Rủi ro "đổi giờ hệ thống né chặn": chấp nhận (offline 1 thiết bị, không phải đối thủ chủ động).

**Sinh trắc học (vân tay/FaceID):**
- **Đợt sau (PBI riêng)** — lớp "tiện lợi" thay thế trên nền PIN (PIN vẫn là lớp gốc). Numpad hiện **để trống** vị trí vân tay (hàng cuối trái).
- Khi có: thu hồi quyền (OS) → tự tắt toggle, yêu cầu bật lại bằng PIN; đổi vân tay đăng ký → vô hiệu hóa sinh trắc tạm thời, xác thực lại bằng PIN.

## Màn Tiện ích & Cá nhân hóa (danh sách) — đã triển khai PBI 17
> **PBI 17 (2026-09-06)**: dựng **màn danh sách** gom điểm vào tùy chỉnh theo mockup `docs/tool/01-danh-sach-tien-ich.svg`. Entry: Cài đặt nhóm **KHÁC → "Tiện ích & Cá nhân hóa"** (ngay dưới "Danh mục"), `SubPageScaffold` app bar teal + back + tiêu đề, không bottom nav. Nguồn đặc tả `.specify/specs/17`.

**Bố cục — 3 nhóm / 8 hàng**, mỗi hàng vòng nền nhạt (`tealLightBg`) + icon **teal** + tên + dòng phụ + phần cuối:
- **HIỂN THỊ** — Giao diện (dòng phụ "Sáng / Tối / Theo hệ thống", trailing "Hệ thống" ▸), Ngôn ngữ (trailing "Tiếng Việt" ▸), Định dạng & Tiền tệ ▸.
- **TRẢI NGHIỆM** — Widget màn hình chính (switch hiển thị **"bật" câm**, chạm toàn hàng → **dialog hướng dẫn ghim widget theo nền tảng** — ghim do OS quản lý, trạng thái **không lưu**); **Ẩn số dư (Privacy mode)** switch thật (mặc định **tắt**); **Máy tính khi nhập số tiền** switch thật (mặc định **bật**).
- **DỮ LIỆU & TÌM KIẾM** — Tìm kiếm toàn cục ▸, Quản lý Tag ▸ (dòng phụ **mô tả** "Gắn nhãn cho giao dịch", **không** `#…`/số "12 tag" giả — SC-008).

**2 công tắc thật nhớ trạng thái** qua bảng drift key-value **`AppSettings` (schema v5)** — key `hideBalance` / `amountCalculatorEnabled`; **key vắng = mặc định domain**, row chỉ ghi khi bật/tắt (write-through). Hiệu ứng chức năng **chưa kéo** (che số dư `••••••`, đổi bàn phím nhập tiền = PBI sau — xem [[Ví & Tài khoản]]). Cấu trúc: domain thuần `UtilitiesPrefs` (`toSettings`/`fromSettings` an toàn, không ném) + hằng khóa + seam `UtilitiesStore` (load/save) + `DriftUtilitiesStore` + `ensureUtilitiesStore()` (GetX singleton, bám `ensureWalletRepository`); test bơm `FakeUtilitiesStore`. ~~**5 hàng điều hướng no-op**~~ → **còn 4 hàng no-op** (`Ngôn ngữ`, `Định dạng & Tiền tệ`, `Tìm kiếm toàn cục`, `Quản lý Tag`) chờ màn con `03–07`; hàng **"Giao diện" đã kích hoạt ở PBI 18** (xem mục dưới). PBI cài đặt sau **chỉ thêm row**, không thêm migration.

## Màn "Giao diện" (02) — đã triển khai PBI 18
> **PBI 18 (2026-09-06)**: hàng "Giao diện" màn `01` bỏ no-op → **push màn con `02`**; chọn sáng/tối/theo hệ thống áp **ngay toàn app**, nhớ qua restart. Nguồn đặc tả `.specify/specs/18`, mockup `docs/tool/02-giao-dien.svg`.

**Màn `02`** (`ThemeScreen`, màn con shell): `SubPageScaffold` app bar teal + back + tiêu đề "Giao diện", **không** bottom nav. Thân `ListView` gồm **3 card đúng thứ tự Sáng – Tối – Theo hệ thống** (mockup): mỗi hàng = vòng nền nhạt + icon minh họa (mặt trời / mặt trăng / thiết bị), tên đậm + dòng phụ mô tả (`Nền trắng, chữ tối` / `Nền tối, chữ sáng, đỡ mỏi mắt ban đêm` / `Tự đổi theo cài đặt điện thoại`), cuối hàng **radio tự dựng** (không `RadioListTile`). Hàng đang chọn **tô nền nhạt** + vòng icon **viền teal**; chân màn ghi chú "Thay đổi được áp dụng ngay lập tức, không cần khởi động lại ứng dụng.".

**Trạng thái & lưu trữ:** 3 lựa chọn ánh xạ thẳng `ThemeMode` của Flutter (`light`/`dark`/`system`) — **không tạo enum riêng** (1 nguồn duy nhất xuyên suốt). Lưu **1 row `('themeMode', 'light'|'dark'|'system')`** trong bảng key-value **`AppSettings` v5** (không migration, không seed — row ghi write-through khi user chọn). **Key vắng = mặc định "Theo hệ thống"**; chuỗi ngoài 3 giá trị hợp lệ → cũng về `system` (parse an toàn, không ném). Tên hiển thị thống nhất: `light`→"Sáng", `dark`→"Tối", `system`→**"Theo hệ thống"** (màn `01` bỏ nhãn cũ "Hệ thống").

**Hàng "Giao diện" màn `01`:** phần cuối **reactive** đọc controller → hiện đúng "Sáng"/"Tối"/"Theo hệ thống", cập nhật ngay kể cả khi vừa đổi ở màn `02` rồi back (màn `01` vẫn mounted dưới route).

**Cơ chế dark mode toàn app:** `ThemeController` (GetX) giữ `Rx<ThemeMode>`, đăng ký ở gốc `SoraApp` (bám `PinController`) và nạp lựa chọn đã lưu lúc `initState`; `GetMaterialApp` nhận `theme` + `darkTheme` + `themeMode` → chọn một hàng là **cả cây rebuild tức thì**, không restart. Chi tiết token màu & rule light/dark ở [[Design system]]; seam/DI ở [[Stack kỹ thuật]]. "Theo hệ thống" tự đổi khi điện thoại đổi sáng/tối nhờ chính `ThemeMode.system` của Material (không tự viết observer `didChangePlatformBrightness` như doc §1.2 gợi ý).

## Hồ sơ cá nhân
| Trường | Chốt |
|---|---|
| Avatar | Ảnh từ thư viện/chụp, hoặc chữ viết tắt tên mặc định |
| Tên hiển thị | Tự do; chào mừng — không định danh/đăng nhập |
| Tiền tệ mặc định | Áp dụng ví mới + tổng hợp báo cáo đa ví; đổi **không hồi tố** tiền tệ ví đã tạo |
| Múi giờ | Gán ngày/giờ gd mới + mốc "đầu ngày/đầu tháng tài chính" |

⚠ QUYẾT ĐỊNH MỞ: đổi múi giờ khi đang có chuỗi định kỳ đã lên lịch → có tính lại thời điểm sinh gd tiếp theo không (auth doc §3).

## Đổi / quên PIN
- **Đổi** (còn nhớ): Cài đặt → Đổi mã PIN → xác thực PIN cũ (hoặc sinh trắc) → nhập/xác nhận PIN mới → lưu.
- **Quên PIN** — 2 hướng chưa chốt:
  - **A** (giữ dữ liệu): reset qua câu hỏi bảo mật đã đặt, hoặc khôi phục từ file JSON backup sau khi cài lại.
  - **B** (ưu tiên bảo mật): không đường vòng — mất PIN = xóa data + cài lại, khôi phục backup nếu có.
  - ⚠ QUYẾT ĐỊNH MỞ: doc nghiêng về **B** kèm khuyến khích backup định kỳ — cần chốt ở giai đoạn thiết kế.

## Bảo mật mở rộng (mục 13 tính năng tổng)
- Mã hóa dữ liệu local (SQLite/Hive mã hóa); không lưu số thẻ/ngân hàng thật (chỉ nhãn tham chiếu).
- Privacy mode: ẩn số dư màn chính (che `••••••`) — công tắc "Ẩn số dư" **đã lưu được** (PBI 17, `AppSettings` v5); hiệu ứng che ở các màn có số tiền là PBI sau — liên kết [[Ví & Tài khoản]].
- Yêu cầu sinh trắc trước khi xem/sửa dữ liệu nhạy cảm (tùy chọn).

## Màn hình bảo mật (khác biệt với shell)
- Khóa PIN / sinh trắc: **toàn màn hình, độc lập hoàn toàn** khỏi app shell — chạy trước khi vào app (PBI 3: cổng boot nền trung tính làm `home`, đẩy setup/lock trước nội dung để không flash data).
- Numpad: lưới `3×4`, nút tròn ~48–52px, viền mảnh `#E0E0E0`, không nền; hàng cuối: trái = **để trống** (vị trí vân tay, chưa có sinh trắc đợt này), giữa `0`, phải backspace. Dot indicator ~12px: đặc teal = đã nhập, rỗng xám = chưa.

## Liên kết
- [[Design system]] — màn bảo mật tách shell; numpad & dot PIN dùng lại cho màn nhập tiền ([[Giao dịch]]).
- [[Ví & Tài khoản]] — tiền tệ mặc định cấp ví mới; Privacy mode.
- [[Ngân sách]] — tiền tệ mặc định & kỳ tài chính lệch bắt nguồn từ hồ sơ.
- [[Lộ trình phát triển]] — phụ thuộc backup GĐ3; PIN khóa app thuộc MVP.
