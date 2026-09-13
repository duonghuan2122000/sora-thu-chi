# Danh sách Task: Mở khóa bằng sinh trắc học

**Mã PBI**: 34
**Nguồn**: plan.md, spec.md, data-model.md, research.md, quickstart.md

## Pha 1: Setup

- [X] T001 Rà `app/sora_thu_chi/android/app/src/main/AndroidManifest.xml` và `app/sora_thu_chi/ios/Runner/Info.plist`: thêm khai báo còn thiếu cho `local_auth` (Android `USE_BIOMETRIC` nếu chưa ngầm định; iOS `NSFaceIDUsageDescription` — bắt buộc khai báo tay theo `plan.md`).

## Pha 2: Foundational

- [X] T002 [P] Thêm `BiometricState` (`enabled`, `enrolledTypes`) và 2 phương thức `readBiometricState()`/`saveBiometricState()` vào `abstract class PinStore` tại `app/sora_thu_chi/lib/core/security/pin_store.dart` (theo `data-model.md`).
- [X] T003 [P] Tạo `app/sora_thu_chi/lib/core/security/biometric_gateway.dart`: seam mỏng bọc `local_auth` (`BiometricGateway` abstract + `BiometricGatewayLocalAuth` implement) với `canUse()` (gộp `canCheckBiometrics && isDeviceSupported()`), `availableTypes()` (bọc `getAvailableBiometrics()` trả `List<String>`), `authenticate({required String reason})` (gọi `authenticate(biometricOnly: true)`), `stopAuthentication()`.
- [X] T004 Cài đặt `readBiometricState()`/`saveBiometricState()` trong `PinStoreSecure` (`app/sora_thu_chi/lib/core/security/pin_store_secure.dart`) — key `biometric_state`, JSON `{enabled, enrolledTypes}`, đọc tolerant (JSON hỏng/thiếu key → mặc định `BiometricState()`), cùng khuôn try/catch của `readLockState`.
- [X] T005 Thêm field `BiometricState` in-memory vào `app/sora_thu_chi/test/fakes/pin_store_fake.dart` (đọc/ghi trực tiếp, mặc định `enabled=false, enrolledTypes=[]`).
- [X] T006 Tạo `app/sora_thu_chi/test/fakes/biometric_gateway_fake.dart`: fake `BiometricGateway` cho phép bơm kết quả `canUse`, `availableTypes`, kết quả `authenticate` (thành công/thất bại/ném lỗi) qua field/callback gán tay trong test.
- [X] T007 Mở rộng `PinController` (`app/sora_thu_chi/lib/core/security/pin_controller.dart`): nhận thêm `BiometricGateway gateway` qua constructor; thêm field `biometricEnabled`; nạp `biometricEnabled` từ `_store.readBiometricState()` trong `init()`.
- [X] T008 [US-nền] Thêm `PinController.enableBiometric()`: gọi `gateway.authenticate(...)`, thành công → `saveBiometricState(enabled: true, enrolledTypes: await gateway.availableTypes())` + set `biometricEnabled = true`; thất bại/huỷ → giữ nguyên `false`, không ghi (theo `research.md` R7, bảng chuyển trạng thái `data-model.md`).
- [X] T009 Thêm `PinController.disableBiometric()`: ghi `saveBiometricState(enabled: false, enrolledTypes: [])` + set `biometricEnabled = false` ngay, không cần xác thực gì thêm (FR-009).
- [X] T010 Thêm `PinController.canOfferBiometric` (getter/method async): trả `false` ngay nếu `!biometricEnabled`; nếu bật, gọi `gateway.canUse()` — `false` → tự gọi `disableBiometric()` rồi trả `false` (FR-007); nếu `true`, so khớp `gateway.availableTypes()` hiện tại với `enrolledTypes` đã lưu (đọc lại `_store.readBiometricState()`) — khác tập hợp → tự gọi `disableBiometric()` rồi trả `false` (FR-008); mọi kiểm tra khớp → trả `true`.

## Pha 3: User Story — Bật/tắt công tắc trong Cài đặt (Ưu tiên: P1)

**Mục tiêu**: Người dùng bật được công tắc "Mở khóa sinh trắc học" trong Cài đặt (chỉ khi thiết bị hỗ trợ + đã đăng ký), yêu cầu xác thực sinh trắc học ngay khi bật; tắt thì có hiệu lực ngay không cần xác thực.
**Tiêu chí kiểm thử độc lập**: Bật công tắc trên thiết bị có vân tay ảo → xác thực đúng → công tắc bật, persist qua khởi động lại; bật rồi huỷ xác thực → công tắc vẫn tắt; tắt công tắc đang bật → tắt ngay không hỏi gì.

- [X] T011 [US1] Sửa hàng "Mở khóa sinh trắc học" tại `app/sora_thu_chi/lib/screens/settings_screen.dart` (dòng ~122-125): thay `Switch(value: false, onChanged: null)` bằng `Switch` đọc `PinController.biometricEnabled` thật, `onChanged` gọi `enableBiometric()`/`disableBiometric()` tương ứng; khi thiết bị không hỗ trợ (`gateway.canUse() == false`, kiểm tra async lúc build/init) → `Switch` tắt + `onChanged: null` + dòng phụ giải thích (kịch bản chấp nhận #1, FR-001) — cần mở rộng `_SettingsRow` thêm `subtitle` tuỳ chọn nếu chưa có.
- [X] T012 [US1] Thêm ca test trong `app/sora_thu_chi/test/pin_controller_test.dart`: bật công tắc xác thực thành công → `biometricEnabled=true` + `enrolledTypes` lưu đúng; bật xác thực thất bại/huỷ → giữ `false`, store không ghi; tắt công tắc đang bật → `false` ngay không gọi `gateway.authenticate`.
- [X] T013 [US1] Thêm ca test trong `app/sora_thu_chi/test/settings_screen_test.dart`: hàng công tắc phản ánh đúng `biometricEnabled`; thiết bị không hỗ trợ → công tắc tắt + không bật được + hiện dòng giải thích; chạm bật → gọi đúng `enableBiometric` qua `PinController`.

## Pha 4: User Story — Mời sinh trắc học tự động khi vào màn khóa + fallback PIN (Ưu tiên: P1)

**Mục tiêu**: Khi công tắc đang bật và còn khả dụng, màn khóa tự mời sinh trắc học trước bàn phím PIN; luôn có lối thoát "Dùng mã PIN thay thế"; thất bại/huỷ tự chuyển PIN; thành công vào đúng màn đang đứng.
**Tiêu chí kiểm thử độc lập**: Kill app rồi mở lại (hoặc resume từ nền) với công tắc bật → hiện màn mời biometric trước; xác thực đúng → vào đúng màn cũ; xác thực sai/huỷ → tự chuyển bàn phím PIN; bấm "Dùng mã PIN thay thế" → chuyển ngay; bấm "Hủy" → ở lại màn mời.

- [X] T014 [US2] Tạo `app/sora_thu_chi/lib/screens/pin/widgets/biometric_prompt.dart`: widget thuần (icon vân tay vẽ tay theo mockup `03-sinh-trac-hoc.svg`, text "Chạm để xác thực", nút "Dùng mã PIN thay thế" (teal, theo design system) + nút "Hủy" (viền)), nhận callback `onRetry`/`onUsePin`/`onCancel`, dùng `SoraColors`.
- [X] T015 [US2] Sửa `app/sora_thu_chi/lib/screens/pin/pin_lock_screen.dart`: thêm `enum _Mode { biometric, pin }`; `initState` gọi `_controller.canOfferBiometric` (async, `FutureBuilder`/`WidgetsBinding.addPostFrameCallback` + `setState`) để chọn mode khởi tạo — `true` → `_Mode.biometric` (gọi luôn `_tryBiometric()`), ngược lại → `_Mode.pin` (hành vi cũ, không đổi).
- [X] T016 [US2] Trong `pin_lock_screen.dart`: thêm `_tryBiometric()` gọi `gateway.authenticate(reason: 'Mở khóa Sora Thu Chi')` qua `PinController`/gateway — thành công → `widget.onUnlocked()` (FR-006, giữ nguyên màn cũ vì route không đổi); thất bại/lỗi → `setState(() => _mode = _Mode.pin)` (FR-005, không tính vào streak PIN); nút "Dùng mã PIN thay thế" → `setState` chuyển `_Mode.pin` ngay; nút "Hủy" → gọi `gateway.stopAuthentication()`, không đổi mode (R6).
- [X] T017 [US2] `build()` trong `pin_lock_screen.dart`: khi `_mode == _Mode.biometric` render `BiometricPrompt` (T014) thay khối PIN dots/keypad; khi `_Mode.pin` giữ nguyên UI hiện có không đổi.
- [X] T018 [US2] Thêm ca test trong `app/sora_thu_chi/test/pin_flow_test.dart`: công tắc bật + `canOfferBiometric=true` → màn khóa khởi tạo ở mode biometric; xác thực thành công → gọi `onUnlocked`; xác thực thất bại → tự chuyển hiện bàn phím PIN, PIN vẫn nhập được và không tính streak; bấm "Dùng mã PIN thay thế" → chuyển ngay PIN; bấm "Hủy" → vẫn ở màn biometric; công tắc tắt hoặc `canOfferBiometric=false` → khởi tạo thẳng `_Mode.pin` như hành vi PBI 3 cũ.

## Pha 5: User Story — Tự phát hiện quyền/đăng ký sinh trắc học thay đổi (Ưu tiên: P2)

**Mục tiêu**: Quyền bị thu hồi hoặc tập vân tay/khuôn mặt đăng ký đổi → tự tắt công tắc, màn khóa lần kế tiếp không mời sinh trắc học mất hiệu lực nữa, bắt xác thực lại bằng PIN.
**Tiêu chí kiểm thử độc lập**: Giả lập `gateway.canUse()` trả `false` hoặc `availableTypes()` khác `enrolledTypes` đã lưu → `canOfferBiometric` tự tắt công tắc và trả `false`; Cài đặt sau đó hiện công tắc tắt.

- [X] T019 [US3] Thêm ca test trong `app/sora_thu_chi/test/pin_controller_test.dart`: `biometricEnabled=true` sẵn, `gateway.canUse()` giả lập trả `false` → gọi `canOfferBiometric` tự set `biometricEnabled=false` + ghi store (FR-007).
- [X] T020 [US3] Thêm ca test trong `app/sora_thu_chi/test/pin_controller_test.dart`: `biometricEnabled=true`, `enrolledTypes` lưu `['fingerprint']`, `gateway.availableTypes()` giả lập trả `['fingerprint', 'face']` → `canOfferBiometric` tự tắt công tắc (FR-008), bật lại sau đó phải qua lại `enableBiometric()` đầy đủ (không có đường tắt).
- [X] T021 [US3] Thêm ca test trong `app/sora_thu_chi/test/pin_flow_test.dart`: màn khóa khởi tạo với `canOfferBiometric` trả `false` do quyền/đăng ký đổi → vào thẳng `_Mode.pin`, không gọi `gateway.authenticate` lần nào.

## Pha cuối: Polish & Cross-cutting

- [X] T022 [P] Bổ sung khoá dịch tiếng Việt/English (PBI 19) cho toàn bộ chuỗi mới: "Mở khóa sinh trắc học", "Chạm để xác thực", "Dùng mã PIN thay thế", "Hủy", dòng phụ giải thích khi không hỗ trợ — rà `app/sora_thu_chi/lib/l10n/` hoặc file khoá dịch hiện có theo đúng khuôn PBI 19.
- [X] T023 Kiểm tra `BiometricPrompt` (T014) và hàng Cài đặt (T011) đọc đúng `SoraColors`/`AppColors` ở giao diện Tối (PBI 18), không hex cứng.
- [X] T024 Chạy `flutter analyze` (thư mục `app/sora_thu_chi/`) và `flutter test`, xác nhận sạch/không tăng số ca đỏ so với baseline hiện tại (1202 test + các ca đỏ có sẵn theo memory), cập nhật số liệu vào phần báo cáo cuối task.
- [ ] T025 QA thủ công trên emulator theo toàn bộ nhóm A–G trong `quickstart.md` (cần cấu hình vân tay ảo qua Extended controls trước nhóm D/E).

## Sơ đồ phụ thuộc

- Pha 1 (Setup) không phụ thuộc gì, làm trước hoặc song song Pha 2.
- Pha 2 (Foundational: `PinStore`/`BiometricGateway`/`PinController` lõi) phải xong trước mọi User Story — cả US1/US2/US3 đều gọi `PinController.enableBiometric/disableBiometric/canOfferBiometric`.
- US1 (Pha 3) và US2 (Pha 4) độc lập nhau về code chạm (US1 sửa `settings_screen.dart`, US2 sửa `pin_lock_screen.dart` + widget mới) — có thể làm song song sau Pha 2, nhưng US2 cần `canOfferBiometric` (T010) nên vẫn phụ thuộc Pha 2 hoàn tất.
- US3 (Pha 5) chỉ là test bổ sung cho logic đã có sẵn trong T010 (Pha 2) — làm sau Pha 2, không phụ thuộc US1/US2.
- Polish (Pha cuối) làm sau khi US1+US2 xong (cần UI thật để kiểm dịch/theme); T024 chạy sau cùng.

## Ví dụ chạy song song

- Trong Pha 2: T002 và T003 độc lập (2 file khác nhau) → chạy song song; T004–T010 tuần tự (phụ thuộc T002/T003).
- Sau khi Pha 2 xong: 1 người làm Pha 3 (US1, `settings_screen.dart`), 1 người làm Pha 4 (US2, `pin_lock_screen.dart` + `biometric_prompt.dart`) — không đụng file nhau.
- T022 (Pha cuối) có thể làm song song với T023 (file khác nhau).

## Chiến lược triển khai

- **MVP đề xuất**: Pha 1 + Pha 2 + User Story 1 (Pha 3) — bật/tắt công tắc hoạt động đúng, đã có xác thực sinh trắc học khi bật, nhưng màn khóa vẫn chỉ hiện PIN (chưa mời tự động). Đủ để demo cơ chế lưu trạng thái + xác thực.
- **Thứ tự giao hàng tăng dần**: Setup + Foundational → US1 (bật/tắt) → US2 (mời tự động + fallback, giá trị chính của PBI) → US3 (tự phát hiện thu hồi/đổi đăng ký, phòng vệ) → Polish (i18n/theme/QA).
