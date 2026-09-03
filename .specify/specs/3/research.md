# Nghiên cứu & quyết định kỹ thuật: Khóa ứng dụng bằng mã PIN

**Mã PBI**: 3 — tài liệu đối chiếu: `docs/auth/chi-tiet-quan-ly-tai-khoan-nguoi-dung.md` §2, mockup `docs/auth/02-khoa-pin.svg`, `docs/design-system-app-thu-chi.md` §2.4/§3/§5.

## Quyết định 1 — Lưu mã PIN & bộ đếm chống dò qua `flutter_secure_storage`

- **Quyết định**: mã PIN không lưu plaintext; lưu **hash có muối** (SHA-256, `crypto`), 1 key: `pin_salt_hash` = `base64(salt) + "." + base64(sha256(salt + pin))`. Dữ liệu chống dò (số lần sai liên tiếp `streak`, mốc hết chặn `lockUntilEpochMs`) lưu 1 JSON riêng key `lock_state`. Cả hai trong `flutter_secure_storage` (Keychain/Keystore).
- **Lý do**: tài liệu auth §2.2 yêu cầu "hash + lưu qua flutter_secure_storage", không lưu plaintext trong DB (FR-011). Stack đã chốt `flutter_secure_storage`. Thời gian chặn phải sống sót khi thoát app (FR-009) → bắt buộc persist; đưa vào cùng store bảo mật, không tách sang cơ chế khác (tránh mất đồng bộ streak/lockUntil). Muối chặn tra cứu bảng 10.000 tổ hợp sẵn có.
- **Phương án khác đã xem xét**: (a) lưu PIN plaintext trong secure storage — đơn giản nhưng trái auth doc; (b) lưu `lock_state` trong drift/DB — drift đã có nhưng chưa có service/schema, thêm chi phí migration cho dữ liệu phi-giao-dịch thay đổi thường xuyên; không cần.
- **Ghi chú bảo mật thực tế**: PIN 4 số chỉ 10.000 tổ hợp — hash không chống nổi kẻ đọc được trực tiếp secure storage; lớp bảo vệ chính là Keystore/Keychain (chỉ thiết bị đọc) + khóa tạm thời khi nhập sai. Đủ cho mô hình app offline 1 thiết bị. Muối + hash là phòng vệ theo yêu cầu tài liệu.

## Quyết định 2 — Kiến trúc hiển thị khóa: route phủ trên navigator gốc

- **Quyết định**: app chuyển `MaterialApp` → `GetMaterialApp` (GetX đã chốt trong stack; mô-đun đầu tiên có controller). `home` = `BootGate` tĩnh (Scaffold nền trắng, **không nội dung tài chính**) giữ cả phiên. Luồng điều hướng qua `navigatorKey`:
  - Boot đọc store xong: chưa có PIN → `pushAndRemoveUntil` `PinSetupScreen`; đã có PIN → `pushAndRemoveUntil` `PinLockScreen`. Sau khi hoàn tất thiết lập / mở khóa đúng ở màn gốc → `pushAndRemoveUntil(AppShell)`.
  - Resume giữa phiên (đang ở nội dung, có thể đang ở sub-page): push `PinLockScreen` **dạng route phủ** lên đỉnh stack; mở khóa đúng → pop về đúng màn đang đứng (FR-007). AppShell + các sub-page nằm dưới route khóa nên giữ nguyên trạng thái.
- **Lý do**: yêu cầu "về đúng màn trước khi khóa" buộc khóa phải nằm **trên** stack hiện tại (route phủ), không được đổi nội dung `home` (đổi home chỉ chạm route gốc, các route con như màn phụ không bị che → lộ nội dung, vi phạm FR-005). BootGate nền trắng làm `home` giúp lần mở nguội không vẽ bất kỳ nội dung nào dưới màn khóa (SC-002 10/10).
- **Phương án khác đã xem xét**: (a) `home` là widget điều kiện đổi PIN-Lock/AppShell — không che được sub-page mở chồng, loại; (b) overlay bằng `Overlay` thủ công — tái phát minh cơ chế route, dùng route chuẩn.

## Quyết định 3 — Thời điểm khóa: theo vòng đời app, không cần timer

- **Quyết định**: `SoraApp` (stateful) đăng ký `WidgetsBindingObserver`. Khi app rời trạng thái active (`paused`/`hidden`) và phiên đang mở → set cờ `pendingLock = true`. Khi `resumed`: nếu `pendingLock` và đã cấu hình PIN → đẩy `PinLockScreen` phủ, phiên chuyển locked. Cờ xóa khi đã khóa.
- **Lý do**: spec §Giả định — khóa mỗi lần khởi động & mỗi lần trở về từ nền, bất kể thời gian vắng mặt (không cần "tự khóa sau N giây không thao tác", để đợt sau). Chỉ khóa khi chủ động rời app để không làm gián đoạn nhập PIN giữa chừng.
- **Phương án khác**: tự khóa sau timeout khi đang mở — ngoài phạm vi (giả định spec), loại.

## Quyết định 4 — Bộ đếm & thang chặn (anti-brute-force)

- **Quyết định**: chỉ tính lần thử **sai hoàn chỉnh** (đủ 4 số). `streak` tăng 1 mỗi lần sai hoàn chỉnh; khi `streak >= 5` → `lockUntil = now + ladder[min(streak - 5, 3)]`, ladder = 30s → 1p → 5p → 15p (trần). Nhập đúng → `streak = 0`, xóa `lockUntil`. Mỗi lần sai sau khi hết chặn (chuỗi chưa mở khóa) tăng tiếp bậc.
- **Lý do**: khớp FR-009 + giả định spec: chặn 30s ở lần sai thứ 5, tái phạm tăng dần theo bậc, trần 15 phút, giữ nguyên khi thoát app. Bộ đếm chỉ chạy khi nhập xong 4 số (edge spec §Trường hợp biên).
- **Phương án khác**: chặn cứng vĩnh viễn sau N lần / xóa dữ liệu sau nhiều lần sai — ngoài phạm vi & rủi ro mất dữ liệu tài chính (spec §Ngoài phạm vi).

## Quyết định 5 — Giờ hệ thống làm nguồn thời gian chặn (kèm rủi ro chấp nhận)

- **Quyết định**: `lockUntil` lưu epoch millis theo giờ thiết bị; controller so sánh với `now()`. Controller nhận hàm `now()` bơm vào (mặc định `DateTime.now`) để test định thời xác định.
- **Lý do**: cần persist qua khởi động lại thiết bị nên không dùng đồng hồ monotonic. Chống dò offline không phải đối thủ chủ động đổi giờ hệ thống; chấp nhận rủi ro (ghi rõ — không đầu tư chống đổi giờ).
- **Phương án khác**: đồng hồ monotonic — mất mốc khi reboot, loại.

## Quyết định 6 — Bàn phím số tự dựng, không dùng bàn phím hệ thống

- **Quyết định**: widget `PinKeypad` tự dựng — lưới 3×4, nút tròn ~48–52px viền `#E0E0E0` không nền (nền nhấn khi tap), chữ `#1A1A1A`; hàng cuối: trái = **ô trống** (vị trí vân tay, đợt này chưa có sinh trắc → để trống theo giả định spec), giữa `0`, phải = backspace. Dot indicator: chấm ~12px, đã nhập = đặc teal, chưa = viền rỗng `#B4B2A9`.
- **Lý do**: khớp mockup `02-khoa-pin.svg` + design doc §2.4/§5. Không có nút vân tay (PBI sau). Bàn phím số hệ thống không cho kiểu dáng dot/chấm riêng và phá mockup.
- **Phương án khác**: `TextField` + keyboard số hệ thống — không khớp design & khó kiểm soát layout cỡ chữ lớn (SC-007), loại.

## Quyết định 7 — Kiểm soát nút back / cử chỉ hệ thống

- **Quyết định**: `PinSetupScreen` và `PinLockScreen` bọc `PopScope(canPop: false)`; không hiển thị nút back. Thoát app (task switcher / swipe-kill) trong lúc thiết lập chưa xong → chưa ghi PIN (ghi duy nhất khi 2 lần khớp) → lần mở sau vẫn bắt thiết lập (FR-004/FR-010).
- **Lý do**: spec edge: không được vượt qua màn khóa/thiết lập bằng nút/cử chỉ back. `PopScope` chặn cả back Android (kể cả predictive back) và cử chỉ back iOS.
- **Phương án khác**: `WillPopScope` — deprecated, loại.

## Quyết định 8 — PIN yếu: cảnh báo nhưng cho phép

- **Quyết định**: bộ nhận diện PIN yếu (tất cả chữ số giống nhau, dãy tăng/giảm liên tiếp như `1234`/`4321`, kèm `0000`). Khi người dùng xác nhận xong 2 lần khớp mà PIN yếu → dialog "PIN dễ đoán, vẫn dùng?"; **Tiếp tục** → lưu & vào app; **Đặt lại** → nhập từ đầu. Không chặn cứng.
- **Lý do**: giả định spec: nhắc cảnh báo nhưng cho phép nếu xác nhận (tài liệu auth §2.2 tránh ép buộc với app cá nhân offline).
- **Phương án khác**: chặn cứng PIN yếu — trái giả định, loại.

## Quyết định 9 — Chuẩn bị cho test: bơm `PinStore` (fake in-memory)

- **Quyết định**: định nghĩa `abstract PinStore` (đọc/ghi secret + lock state). Bản production `PinStoreSecure` dùng `flutter_secure_storage` + hash; test dùng `PinStoreFake` trong bộ nhớ. `SoraApp` nhận `PinStore?` (mặc định bản real); test bơm fake.
- **Lý do**: `flutter_secure_storage` chạy qua MethodChannel, không có sẵn trong widget test; boot app bây giờ phải đọc PIN → mọi test shell phải né store thật. Cần seam. Controller bơm thêm `now()` cho logic định thời.
- **Phương án khác**: `mocktail` cho class secure storage — thêm dependency dev, fake thuần đủ dùng.

## Quyết định 10 — Số lần "không ép nhập lại ngay sau thiết lập"

- **Quyết định**: hoàn tất thiết lập → phiên mở ngay, không hỏi PIN; nhưng **nếu người dùng rời app rồi quay lại trong chính phiên đó** → vẫn khóa theo FR-005 ("mỗi lần trở về từ nền → hiện màn khóa").
- **Lý do**: spec giả định chỉ loại trừ việc hỏi lại *ngay khi vừa thiết lập xong* (đang trong app); FR-005 áp dụng cho mọi lần trở về từ nền. Cách đọc nhất quán cả hai mệnh đề.
- **Phương án khác**: miễn khóa trọn phiên vừa thiết lập — trái FR-005, loại.

## Quyết định 11 — Thêm dependency `crypto` (SHA-256)

- **Quyết định**: thêm `crypto` (pub.dev) cho hash; salt 16 byte sinh bằng `Random.secure()` (dart:math, không thêm dep). Không có dependency mới khác; không đổi config nền tảng Android/iOS.
- **Lý do**: auth doc yêu cầu hash; `crypto` là thư viện chuẩn, thuần Dart, không có nền tảng config. `flutter_secure_storage` v11 đã cài (PBI 1) không cần entitlement/khai báo mới cho trường hợp 1 keychain mặc định.
- **Phương án khác**: `cryptography` (PBKDF2/Argon2) — nặng hơn cho mục tiêu này; không cần độ trễ kéo dài vì Keystore đã là lớp chặn chính.

## Kết luận

Không còn điểm `NEEDS CLARIFICATION`. Mọi lựa chọn nhất quán stack đã chốt (GetX, flutter_secure_storage), design system (numpad/dot/màu), và phạm vi spec (không sinh trắc, không đổi/tắt PIN, PIN 4 số cố định, không xóa dữ liệu khi sai nhiều).
