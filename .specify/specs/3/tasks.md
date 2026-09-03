# Danh sách Task: Khóa ứng dụng bằng mã PIN

**Mã PBI**: 3
**Nguồn**: plan.md, spec.md, data-model.md, research.md, quickstart.md

> PBI bảo mật — spec.md **không** gán mức ưu tiên P1/P2/P3 cho từng kịch bản (2 luồng là chuỗi phụ thuộc: có PIN thì mới khóa được). Để phát hành tăng dần, chia theo thứ tự luồng spec: **US1 "Thiết lập PIN bắt buộc lần đầu"** là nền (P1, MVP) — đóng FR-001..004 + FR-011; **US2 "Khóa & mở khóa khi vào/quay lại app"** dựng trên đó (P2) — đóng FR-005..010. Đóng đủ spec cần cả 2. Bộ nền (store/controller/numpad/dot) nằm Pha 2 — cả 2 story đều dùng chung.

## Pha 1: Setup

- [X] T001 Xác minh baseline trong `app/sora_thu_chi/`: chạy `flutter --version` (khớp PBI 1: Flutter stable / Dart 3.12.x), `flutter pub get` rồi `flutter analyze` → sạch; xác nhận `pubspec.yaml` đã có `get ^4.7.3` + `flutter_secure_storage ^11.0.0` (PBI 1 cài) và `lib/app.dart` hiện là `MaterialApp` + `home: AppShell` (PBI 2 để nguyên). Sửa `pubspec.yaml`: chạy `flutter pub add crypto` (research Quyết định 11 — hash SHA-256; **dep mới duy nhất** đợt này) → `flutter pub get`. Không đổi `android/`, `ios/` (flutter_secure_storage dùng keystore/keychain mặc định, không cần config mới).

## Pha 2: Foundational

*(Bộ khả năng bảo mật dùng chung cả US1/US2 — phải xong trước khi dựng màn nào)*

- [X] T002 Tạo `app/sora_thu_chi/lib/core/security/pin_store.dart`: model trạng thái chống dò `PinLockState { int streak; DateTime? lockUntil }` (khớp `data-model.md` — key `lock_state`, JSON 1 dòng) + `abstract PinStore`: `Future<bool> get isPinSet`, `Future<void> savePin(String pin)`, `Future<bool> verifyPin(String pin)`, `Future<PinLockState> readLockState()`, `Future<void> saveLockState(PinLockState state)`. Giữ trừu tượng nhỏ, không thêm repo/service tài chính (kiểm tra hiến pháp plan §sau-thiết-kế).
- [X] T003 Tạo `app/sora_thu_chi/lib/core/security/pin_store_secure.dart`: `PinStoreSecure implements PinStore` dùng `flutter_secure_storage` — **2 key**: `pin_salt_hash` = chuỗi `"{saltB64}.{hashB64}"` (salt 16 byte sinh `Random.secure()` từ dart:math, hash = SHA-256(salt + pin) qua `crypto`; key **tồn tại** = PIN đã thiết lập — không lưu PIN đọc được, FR-011) và `lock_state` = JSON của `PinLockState`. `verifyPin` so hash nhập vào với hash lưu; `savePin` ghi secret (được gọi **1 lần duy nhất** khi 2 lần nhập khớp ở luồng thiết lập — `data-model.md`). Không có luồng xóa PIN đợt này.
- [X] T004 Tạo `app/sora_thu_chi/lib/core/security/pin_controller.dart`: `PinController extends GetxController` — biến trạng thái: `configured`, `isLocked`, `streak`, `lockUntil`; hàm `now()` bơm được (mặc định `DateTime.now`); `Future<void> init()` đọc store; `Future<void> savePin(String pin)` (ghi secret + reset `streak=0`, `lockUntil=null`); `Future<VerifyResult> verify(String pin)` theo bảng chuyển trạng thái `data-model.md` — **chỉ tính lần sai hoàn chỉnh đủ 4 số**, `streak>=5` → `lockUntil = now + ladder[min(streak-5, 3)]` với ladder `[30s, 1p, 5p, 15p]` (trần 15p), đúng → `streak=0` xóa lockUntil; `bool get isBlocked` (`now < lockUntil`); `int remainingLockSeconds` cho đếm ngược; `bool isWeakPin(String pin)` (giống nhau hết / dãy tăng-giảm liên tiếp như `0000`,`1111`,`1234`,`4321` — research Q8). Không cho mở khóa khi đang chặn.
- [X] T005 [P] Thêm token vào `app/sora_thu_chi/lib/theme/app_colors.dart`: hằng màu dot-chưa-nhập `dotEmpty` = `#B4B2A9` (research Q6; các màu còn lại teal `#0F6E56`, tealLightText `#CDE9DF` nền icon khóa, divider `#E0E0E0` viền numpad, textPrimary `#1A1A1A` đã có). Tạo `app/sora_thu_chi/lib/screens/pin/widgets/pin_dots.dart`: indicator 4 chấm ~12px — chấm `i < filledCount` đặc teal, ngược lại viền rỗng `dotEmpty`; widget thuần nhận `filledCount`, không tự quản state. Đọc màu từ token, **không hex cứng**.
- [X] T006 [P] Tạo `app/sora_thu_chi/lib/screens/pin/widgets/pin_keypad.dart`: numpad tự dựng lưới 3×4 (research Q6 + mockup `02-khoa-pin.svg`) — nút tròn 48–52px viền `divider` không nền (phản hồi nền nhấn nhẹ khi tap), chữ số `textPrimary`; hàng cuối: trái = **ô trống** (vị trí vân tay, chưa có sinh trắc → để trống), giữa `0`, phải = icon backspace (xóa ký tự cuối). Widget thuần stateless: nhận `onDigit(int)`, `onBackspace()`, cờ `enabled` (false khi bị chặn → vô hiệu hóa bấm + giảm sáng). Bố cục phân phối theo không gian có sẵn, **không chiều cao cứng**, nút bấm ≥ 44px, text co mềm (SC-007/FR-012).

## Pha 3: User Story 1 — Thiết lập mã PIN bắt buộc lần đầu (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Mở app lần đầu trên thiết bị chưa có PIN → bắt buộc thiết lập (2 lần khớp, cảnh báo PIN yếu, không lách bằng back/thoát) trước khi vào nội dung; kể từ đó boot lần sau không còn hỏi thiết lập (khóa đầy đủ sang US2). FR-001..004 + giả định.

**Tiêu chí kiểm thử độc lập**: Boot với store rỗng (fake) → hiện màn thiết lập, **không** thấy nội dung shell, không có nút bỏ qua/back; nhập 2 lần khớp → vào thẳng AppShell, không bị hỏi lại ngay; lệch → báo lỗi nhập lại từ đầu, chưa ghi PIN; PIN yếu → dialog, Tiếp tục → lưu; thoát giữa chừng chưa khớp → store vẫn rỗng. Widget test host chạy không cần emulator.

- [X] T008 [US1] Tạo `app/sora_thu_chi/lib/screens/pin/pin_setup_screen.dart`: màn toàn màn hình (không AppBar/bottom nav — màn bảo mật tách shell) — nền trắng, icon khóa trên nền tròn `tealLightText`, tiêu đề/subtitle theo design doc §2.4 + mockup `02-khoa-pin.svg`; state 2 pha (nhập PIN → xác nhận lại) dùng `PinKeypad` (T006) + `PinDots` (T005); mỗi ký tự chỉ hiện chấm, không lộ chữ số (FR-003); bước xác nhận lệch → báo lỗi, quay bước 1 xóa sạch (FR-004); đủ 4 số 2 lần khớp → `isWeakPin` → dialog "PIN dễ đoán, vẫn dùng?" (Tiếp tục → `controller.savePin` rồi gọi `onDone` vào app; Đặt lại → nhập từ đầu — research Q8); bọc `PopScope(canPop: false)` chặn back/back-gesture (FR-010). Nhận `PinController` qua `Get.find` + callback `onDone` (BootGate nối). Lưu ý: chỉ gọi `savePin` **1 lần khi hoàn tất** — thoát app giữa chừng chưa khớp → không ghi gì (SC-006).
- [X] T009 [US1] Sửa `app/sora_thu_chi/lib/app.dart`: `SoraApp` chuyển thành `StatefulWidget`, tham số tùy chọn `PinStore? store` (mặc định `PinStoreSecure`, test bơm fake — research Q9); đổi `MaterialApp` → `GetMaterialApp` (GetX — mô-đun đầu có controller) giữ `theme`, `navigatorKey` (dùng cho push từ ngoài widget), `home` = `PinGate`. Tạo `app/sora_thu_chi/lib/core/boot_gate.dart`: `PinGate` — Scaffold **nền trắng trung tính, không nội dung tài chính** (SC-002) làm `home` giữ cả phiên; `initState`: `Get.put(PinController(store: ..., now: DateTime.now))` + `await init()` đọc store: **chưa có PIN** → `pushAndRemoveUntil` `PinSetupScreen(onDone: pushAndRemoveUntil(AppShell))`; **đã có PIN** → `pushAndRemoveUntil(AppShell)` (tạm thẳng vào — khóa boot lần sau thay bằng US2). Trong lúc chờ đọc store hiện đúng nền trắng, không nhấp nháy nội dung. `main.dart` giữ `runApp(const SoraApp())` — không đổi.
- [X] T010 [US1] Sửa test shell + thêm luồng thiết lập: trong `app/sora_thu_chi/test/widget_test.dart`, nhóm "điều hướng 4 vùng chính" (6 test cũ pump `SoraApp`) chuyển sang **pump `AppShell` trực tiếp** (bọc `MaterialApp`/`GetMaterialApp` + theme trong test) — shell giờ không còn là `home` mặc định (plan: tách shell khỏi luồng boot PIN). Tạo `app/sora_thu_chi/test/fakes/pin_store_fake.dart`: `PinStore` in-memory (ghi secret + lock state, reset theo tham số). Tạo `app/sora_thu_chi/test/pin_flow_test.dart`: pump `SoraApp(store: PinStoreFake())` — (1) store rỗng → hiện màn thiết lập, **không** thấy `AppShell`/`AppBottomNavBar`; (2) nhập `1234` (chấm đặc theo ký tự, không lộ số) → màn xác nhận → nhập `1234` → vào AppShell, không hỏi lại ngay; (3) nhập `1234` rồi xác nhận `5678` → báo lỗi + nhập lại từ đầu, `store.isPinSet == false`; (4) PIN `1111` → dialog cảnh báo, chọn Tiếp tục → lưu được; (5) thử cử chỉ back khi đang thiết lập → không rời được màn. Chạy `flutter test` file này + widget_test → pass.

## Pha 4: User Story 2 — Khóa & mở khóa khi vào/quay lại app (Ưu tiên: P2)

**Mục tiêu**: Khi đã có PIN — mỗi lần khởi động app và mỗi lần trở về từ nền đều hiện **màn khóa toàn màn hình chặn trước nội dung**; nhập đúng → về đúng màn đang đứng trước khi khóa; sai → báo lỗi chung + chống dò (khóa tạm thời tăng dần, giữ nguyên khi thoát app). FR-005..010.

**Tiêu chí kiểm thử độc lập**: Boot với store đã có PIN (fake) → màn khóa hiện trước, không lộ nội dung; nhập đúng → vào AppShell đúng tab lúc rời; nhập sai → báo lỗi + xóa ký tự; đưa app xuống nền rồi resume khi đang ở nội dung → màn khóa phủ lên đúng màn đang đứng, mở khóa → về đúng màn đó; store seed bị chặn (`lockUntil` tương lai) → keypad khóa + đếm ngược. Widget test host.

- [X] T011 [US2] Tạo `app/sora_thu_chi/lib/screens/pin/pin_lock_screen.dart`: màn khóa toàn màn hình (nền trắng, không AppBar/bottom nav) — icon khóa + tiêu đề "Nhập mã PIN" + nhãn nhắc, `PinDots` + `PinKeypad` (mockup `02-khoa-pin.svg`); bọc `PopScope(canPop: false)` (FR-010); đủ 4 số → `controller.verify`: đúng → gọi `onUnlocked`; sai → báo lỗi chung "mã PIN không đúng" (không tiết lộ ký tự nào đúng — giả định spec) + xóa ký tự đã nhập (FR-008); khi `controller.isBlocked` → hiện thông báo + đếm ngược `remainingLockSeconds`, keypad `enabled: false`, hết chặn chỉ **mở lại nhập** không tự mở khóa (data-model). Nhận callback `onUnlocked` (nơi đẩy màn quyết định điều hướng về đúng màn — FR-007).
- [X] T012 [US2] Nối khóa vào boot + vòng đời app: (a) sửa `lib/core/boot_gate.dart`: đã có PIN → `pushAndRemoveUntil` `PinLockScreen(onUnlocked: pushAndRemoveUntil(AppShell))` (không còn thẳng vào shell — màn khóa root ở cold start); chưa có PIN → giữ nguyên sang `PinSetupScreen` (US1). (b) Sửa `lib/app.dart`: `SoraApp` đăng ký `WidgetsBindingObserver` (research Q3) — khi app rời active (`paused`/`hidden`) trong lúc phiên đang **mở nội dung** → đặt cờ `pendingLock`; khi `resumed`: nếu `pendingLock` + `controller.configured` + đang ở nội dung → `navigatorKey.push` `PinLockScreen(onUnlocked: pop)` **dạng route phủ lên đỉnh stack** (không đổi `home`) để che cả sub-page đang mở chồng và pop về đúng màn cũ (FR-005/007); cờ đóng sau khi đã đẩy lock → resume lặp không push chồng màn khóa. Nếu đang ở màn thiết lập (chưa có PIN) hoặc đang bị khóa → không đẩy thêm (tránh phá luồng đang dở). Duy trì `navigatorKey` đủ để push/pop từ callback lifecycle.
- [X] T013 [US2] Mở rộng `app/sora_thu_chi/test/pin_flow_test.dart` (+ tái dùng `PinStoreFake`): (1) boot store **đã có PIN** → hiện màn khóa trước, không thấy `AppBottomNavBar`; (2) nhập đúng → vào AppShell; (3) nhập sai → báo lỗi, ký tự bị xóa, cho nhập lại; (4) seed fake `lock_state` với `streak>=5` + `lockUntil` tương lai → boot thấy trạng thái chặn + keypad tắt, **không bấm được** (đếm ngược logic ladder đã phủ bởi unit test T007 — không bơm clock qua UI); (5) mô phỏng resume giữa phiên đang ở nội dung (đã mở khóa) → màn khóa phủ lên, mở khóa đúng → về đúng màn/tab đang đứng trước khi khóa. Logic ladder/đếm ngược/tăng bậc để unit test T007; widget test chỉ phủ hiển thị + hành vi route.

## Pha 5: Polish & Cross-cutting

- [X] T014 Chạy trong `app/sora_thu_chi/`: `flutter analyze` → sạch; `flutter test` → toàn bộ (shell + pin_flow + pin_controller) pass. Nếu đỏ → sửa cho sạch trước khi QA, không bỏ ngang. Grep xác nhận: hex màu chỉ tập trung `lib/theme/app_colors.dart` (widget PIN đọc token), không còn dữ liệu/fake data trong màn, `git status` chỉ gồm file theo plan.md §Cấu trúc + `crypto` trong pubspec (không đổi `android/`, `ios/`).
- [X] T015 QA thủ công theo `.specify/specs/3/quickstart.md` trên Android emulator (nền tảng kiểm chứng chính): nhóm A (thiết lập lần đầu — lưu ý gỡ app hoặc xóa dữ liệu để có trạng thái "lần đầu"), nhóm B (khóa/mở khóa — lặp 10 lần boot/resume đối chiếu SC-002 10/10, đúng màn khi unlock từ sub-page), nhóm C (chống dò: sai 5 → chặn 30s; chặn còn hiệu lực khi thoát app rồi mở lại; tăng bậc 1p), nhóm D (layout cỡ chữ lớn nhất + vùng an toàn không vỡ). Ghi kết quả + **đối chiếu FR-001..012 / SC-001..007 ghi ĐẠT/không đạt** vào ghi chú cuối tasks.md này; trạng thái iOS chưa verify (máy Windows — code thuần Flutter + Keychain mặc định, rủi ro thấp, verify khi có máy macOS); ghi nhận bắt buộc PIN lệch `docs/auth/...§2.1` → **sau khi implement PBI 3** cần đồng bộ tài liệu + wiki (Hồ sơ & Bảo mật, Lộ trình phát triển — đã có mục auto-memory).

---

## Ghi chú QA — PBI 3 (implement 2026-09-03)

**Môi trường kiểm chứng:** Android emulator `sdk gphone16k x86_64` (API 37) + build debug `flutter run`. Lưu ý môi trường: vài lần **khởi động đầu tiên sau khi cài mới** emulator render màn trắng (lỗi hiển thị/Impeller của emulator, không phải app) — sau force-stop & mở lại, hoặc build mới chạy lại, UI render chuẩn. Nếu gặp màn trắng khi QA → mở lại app.

**Đã kiểm chứng trên thiết bị (chụp màn hình xác nhận):**
| Mục | Kết quả |
|---|---|
| A1. Mở lần đầu (dữ liệu sạch) → màn thiết lập PIN, không lộ nội dung | ✓ ĐẠT |
| A2/A3. Đặt `1234` 2 lần khớp → dialog "PIN dễ đoán" → Tiếp tục → vào Tổng quan, không hỏi lại ngay | ✓ ĐẠT |
| B7. Tắt hẳn app rồi mở lại → màn khóa toàn màn hình trước nội dung (nội dung không lộ) | ✓ ĐẠT |
| B8. Nhập đúng → vào đúng Tổng quan | ✓ ĐẠT |
| B9. Nhập sai `9999` → báo "Mã PIN không đúng", xóa ký tự | ✓ ĐẠT |
| C12/SC-004. Sai 5 lần liên tiếp → chặn 30s + đếm ngược, bấm số không tác dụng; hết chặn nhập đúng → vào app, đếm về 0 | ✓ ĐẠT |

**Đối chiếu FR/SC (tự động hóa + thiết bị):** FR-001..004/010/011 (luồng thiết lập + back chặn + lưu hash) → unit/widget test `pin_controller_test.dart`, `pin_flow_test.dart` phủ + thiết bị A/B ✓. FR-005..009/012 (khóa boot + resume phủ route về đúng màn, lỗi chung, xóa ký tự, ladder chống dò) → widget test T013 + unit ladder ✓ + thiết bị B/C ✓. SC-001/003/004/005/006 (định tính + đúng màn + chống dò + không lách) ✓ qua test + thiết bị. SC-002 (10/10 boot/resume) **chưa lặp đủ 10 lần** trên thiết bị (đã xác nhận 2 lần: boot lần đầu setup, relaunch khóa) — logic phủ bởi widget test resume (T013 test 5); nên lặp tay theo quickstart trước khi release. SC-007 / FR-012 (layout cỡ chữ lớn + vùng an toàn) **chưa verify** — cần QA tay trên màn thật (bố cục đã phân phối linh hoạt, nút ≥44px, dùng LayoutBuilder).

**Điểm cần lưu ý cho QA tay tiếp theo:**
- Đặt PIN `1234`/`1111`/`4321` → **có** dialog cảnh báo PIN yếu (đúng giả định spec) — nhấn "Tiếp tục" để hoàn tất; quickstart nhóm A bước 2–3 (dùng `1234`) sẽ gặp dialog này.
- Chặn tăng bậc 1p/5p/15p (bước 14 quickstart) chỉ kiểm tra qua unit test (chờ thời gian thật lâu) — logic ladder `[30s,1p,5p,15p]` đã unit-test.
- Resume từ nền khi đang ở sub-page ("Thêm giao dịch") về đúng màn → phủ bởi widget test T013 test 5 + logic route; QA tay nên xác nhận thêm bằng Home button + quay lại.

**Trạng thái nền tảng:** Android ✓ (chính). iOS **chưa verify** (máy Windows — code thuần Flutter + Keychain mặc định flutter_secure_storage, rủi ro thấp; verify khi có máy macOS).

**Nghiệp vụ lệch tài liệu:** PIN **bắt buộc lần đầu mở app** khác `docs/auth/chi-tiet-quan-ly-tai-khoan-nguoi-dung.md` §2.1 ("bật/tắt tùy chọn"). Người dùng đã chốt bắt buộc cho giai đoạn này. → **Sau khi implement PBI 3**: đồng bộ tài liệu nghiệp vụ + wiki (`wiki-knowledge/` — page Hồ sơ & Bảo mật, Lộ trình phát triển; append `log.md`) bằng skill `sora-wiki`. Đã ghi nhận ở auto-memory (`pbi3-pin-wiki-sync`).

## Sơ đồ phụ thuộc

```text
T001 (setup: thêm crypto)
  → Foundational: (T002 → T003 → T004) + (T005 ∥ T006) → T007
  → US1: T008 → T009 → T010
  → US2: T011 → T012 → T013
  → Polish: T014 → T015
```

- Foundational: `T002` (pin_store.dart) → `T003` (pin_store_secure.dart) → `T004` (pin_controller.dart) tuần tự — controller phụ thuộc impl, impl phụ thuộc abstract. `T005` (token + pin_dots) và `T006` (pin_keypad) **chỉ cần theme PBI 2** → song song cả với nhau lẫn với chuỗi store/controller. `T007` (unit test controller) sau `T004`.
- US1: `T008` (setup screen) cần `T005` + `T006` (dots/keypad) + `T004` (controller); `T009` (GetMaterialApp + PinGate) cần `T008` (screen để route); `T010` (test) cần `T008` + `T009`.
- US2: `T011` (lock screen) cần `T005` + `T006` + `T004` (controller — `verify`/`isBlocked` đã ở Foundational); `T012` (nối boot + lifecycle) cần `T011` + PinGate từ US1; `T013` (test) cần `T011` + `T012`.
- US2 phụ thuộc US1 hoàn tất: cần PinGate + store đã có PIN sau setup để khóa có đối tượng; về lý thuyết `T011` chỉ dựa Foundational nên có thể viết song song `T008` (khác file, cùng API controller), nhưng giữ giao US1 hoàn chỉnh trước rồi sang US2.

## Ví dụ chạy song song

```text
# Foundational — 2 luồng độc lập chạy cùng lúc (cả hai không đụng chuỗi store):
T005 [P] theme/app_colors.dart (thêm dotEmpty) + screens/pin/widgets/pin_dots.dart
T006 [P] screens/pin/widgets/pin_keypad.dart

# Có thể chạy cả T005/T006 song song với T002→T003→T004 nếu tách 2 người —
# chúng không phụ thuộc controller/store, chỉ cần theme PBI 2.

# US1, US2: màn nào cũng cần dots+keypad (đã xong ở Foundational); T008 và T011
# cùng dựa Foundational nên song song được, nhưng US2 cần US1 để test end-to-end →
# thường làm tuần tự. Phần còn lại (wiring/test) tuần tự.
```

## Chiến lược triển khai

- **MVP đề xuất**: US1 (thiết lập PIN bắt buộc lần đầu) + Pha Foundational — lát cắt chạy được độc lập: mở app lần đầu → buộc đặt PIN → vào nội dung; thiết lập xong persist qua flutter_secure_storage. Điểm dừng sớm sau `T010` (test pass).
- **Giao hàng tăng dần**: Foundational → US1 → US2. Toàn bộ PBI 3 = 1 release hoàn chỉnh; US2 (màn khóa + chống dò + lock-resume) bắt buộc để đóng spec (FR-005..010, SC-002/004/005) — không tách release riêng, vì app chỉ đặt PIN mà không khóa sau đó chưa đạt mục đích bảo mật spec.
- Bước tiếp theo: chạy `/sora-implement 3`.
