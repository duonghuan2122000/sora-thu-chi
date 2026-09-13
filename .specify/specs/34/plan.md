# Kế hoạch triển khai: Mở khóa bằng sinh trắc học

**Mã PBI**: 34
**Liên kết spec**: .specify/specs/34/spec.md
**Ngày tạo**: 2026-09-13

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x (Flutter stable) |
| Framework / Thư viện chính | Flutter Material; GetX (mở rộng `PinController` hiện có — không controller mới); **`local_auth` 3.0.2 đã có sẵn trong `pubspec.yaml`, chưa dùng** — không thêm dependency mới |
| Lưu trữ dữ liệu | `flutter_secure_storage` — mở rộng `PinStore`/`PinStoreSecure` (PBI 3) thêm 1 key `biometric_state`; **không** đụng drift/`AppSettings` (xem `research.md` R2) |
| Kiểm thử | `flutter analyze` sạch + `flutter test` (mở rộng `PinStoreFake`, test mới cho luồng biometric trong `PinController`/`PinLockScreen`/`SettingsScreen`) + QA thủ công emulator có cấu hình vân tay ảo theo `quickstart.md` |
| Nền tảng triển khai | Android (kiểm chứng chính, có Extended controls giả lập vân tay); iOS (code thuần `local_auth`, rủi ro thấp — verify khi có máy macOS, theo tiền lệ PBI 3) |
| Ràng buộc hiệu năng | Mở khóa bằng sinh trắc học thành công → vào nội dung dưới 2 giây thao tác (SC-001) |
| Ràng buộc khác | PIN luôn là lớp gốc, không bị thay thế (FR-010); màn mời sinh trắc học vẫn thuộc cụm màn bảo mật tách biệt shell, `PopScope(canPop:false)` như PBI 3; design theo mockup `03-sinh-trac-hoc.svg` (icon vân tay minh hoạ vẽ tay, không icon Material) + hàng công tắc đã có sẵn (no-op) trong `settings_screen.dart` theo mockup `04-ho-so-ca-nhan.svg`; tài liệu & commit tiếng Việt có dấu |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + wiki [[Hồ sơ & Bảo mật]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | `local_auth` chỉ gọi API hệ điều hành cục bộ, 0 lời gọi mạng |
| Đúng stack đã chốt | ✅ | `local_auth` đúng gói đã ghi trong `CLAUDE.md` §Kiến trúc & đã có sẵn trong `pubspec.yaml` |
| PIN là lớp bảo mật gốc, sinh trắc học là lớp tiện lợi thay thế (docs/auth §2.1/§2.5) | ✅ | FR-002/FR-004/FR-010; không luồng nào bỏ qua được PIN hoàn toàn |
| Màn hình bảo mật tách hoàn toàn khỏi shell | ✅ | Vẫn trong cụm `PinLockScreen`/`PinGate`, không app bar/bottom nav |
| Design system (1 màu teal cho hành động chính; đúng mockup) | ✅ | Nút "Dùng mã PIN thay thế" nền teal, "Hủy" viền theo đúng mockup `03` |
| Style tập trung 1 nơi (theme/token) | ✅ | Dùng lại `SoraColors`/`AppColors`, không hex cứng mới |
| Cấm fake data & giữ đúng nghiệp vụ | ✅ | Không dữ liệu giả; giới hạn kỹ thuật FR-008 đã ghi rõ, không che giấu |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file/commit tiếng Việt |

Không phát sinh vi phạm/ngoại lệ hiến pháp nào cần xin phép.

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Tóm tắt quyết định chính:

- **R1**: Dùng `local_auth` đã có sẵn — không thêm dependency.
- **R2**: Trạng thái bật/tắt + snapshot loại sinh trắc học lưu trong `flutter_secure_storage` (mở rộng `PinStore`), không phải `AppSettings` — để tự nhiên loại khỏi backup JSON tương lai (FR-011).
- **R3**: `PinLockScreen` gộp 2 chế độ nội bộ (`biometric`/`pin`) trong cùng 1 route, không route riêng — không đổi 2 điểm gọi hiện có (`PinGate` cold-start, `app.dart` resume).
- **R4**: Phát hiện quyền bị thu hồi (FR-007) bằng cách hỏi lại `canCheckBiometrics`/`isDeviceSupported()` mỗi lần chuẩn bị mời, không polling nền.
- **R5**: Phát hiện đổi sinh trắc học đăng ký (FR-008) bằng so khớp tập `getAvailableBiometrics()` với snapshot lúc bật — **giới hạn đã biết**: chỉ bắt được đổi *loại*, không bắt được đổi vân tay cùng loại (giới hạn của `local_auth`, đã ghi ⚠ ceiling + hướng nâng cấp native sau này).
- **R6**: Nút "Hủy" chỉ huỷ lượt xác thực hiện tại, ở lại màn biometric (không điều hướng).
- **R7**: Bật công tắc gọi thẳng `authenticate()`, đúng thành công mới ghi `enabled=true` (chốt phương án A).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — mở rộng `PinStore` + entity "Trạng thái sinh trắc học (thiết bị)" (key `biometric_state`) + bảng chuyển trạng thái.
- **Hợp đồng giao diện**: **không tạo** — app nội bộ, offline, không API/CLI công khai (đúng tiền lệ PBI 3 và mọi PBI trước).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A (bật/tắt), B (mời tự động), C (fallback/Hủy), D (thu hồi quyền), E (đổi đăng ký), F (không hỗ trợ), G (hồi quy ngôn ngữ/theme).

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Mở rộng `PinController`/`PinStore` có sẵn, không controller/repo mới |
| Không vi phạm mới phát sinh | ✅ | Mọi quyết định research nhất quán hiến pháp; giới hạn FR-008 là giới hạn kỹ thuật đã ghi công khai, không phải bỏ sót |
| Test không phụ thuộc thiết bị/keystore | ✅ | `PinStoreFake` mở rộng in-memory; `local_auth` thật chỉ chạy trên device — cần seam gọi `LocalAuthentication` qua interface nhỏ để test bơm kết quả giả (xem cấu trúc dưới) |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/security/
│   │   ├── pin_store.dart              # [SỬA] + BiometricState + 2 phương thức mới trong PinStore
│   │   ├── pin_store_secure.dart       # [SỬA] cài đặt đọc/ghi key `biometric_state`
│   │   ├── biometric_gateway.dart      # [TẠO] seam mỏng bọc `local_auth`: canUse()/availableTypes()/
│   │   │                               #        authenticate()/stopAuthentication() — test bơm fake
│   │   └── pin_controller.dart         # [SỬA] thêm biometricEnabled, enableBiometric()/
│   │                                   #        disableBiometric(), kiểm tra "còn khả dụng?" cho
│   │                                   #        PinLockScreen dùng trước khi vào chế độ biometric
│   └── screens/
│       ├── pin/
│       │   ├── pin_lock_screen.dart    # [SỬA] thêm _Mode{biometric,pin}; khởi tạo theo
│       │   │                           #        controller.shouldOfferBiometric(); UI mockup `03`
│       │   └── widgets/
│       │       └── biometric_prompt.dart # [TẠO] icon vân tay + text + 2 nút (mockup 03), tách khỏi
│       │                                 #        pin_lock_screen.dart cho gọn (widget thuần, test dễ)
│       └── settings_screen.dart        # [SỬA] hàng "Mở khóa sinh trắc học" từ Switch(value:false,
│                                        #        onChanged:null) → Switch thật đọc/gọi PinController
└── test/
    ├── fakes/
    │   ├── pin_store_fake.dart         # [SỬA] thêm field BiometricState in-memory
    │   └── biometric_gateway_fake.dart # [TẠO] fake seam local_auth (canUse/authenticate bơm kết quả)
    ├── pin_controller_test.dart        # [SỬA] thêm ca bật/tắt, phát hiện thu hồi quyền, đổi đăng ký
    ├── pin_flow_test.dart              # [SỬA] thêm ca màn khóa mời biometric → fallback PIN → Hủy
    └── settings_screen_test.dart       # [SỬA] thêm ca hàng công tắc thật (bật/tắt/không hỗ trợ)
```

Không đổi config nền tảng (`android/`, `ios/`) — `local_auth` dùng quyền/API mặc định của Android `BiometricPrompt`/iOS `LocalAuthentication`; cần rà `AndroidManifest.xml`/`Info.plist` xem đã có khai báo `USE_BIOMETRIC` (Android, thường ngầm định) và `NSFaceIDUsageDescription` (iOS, bắt buộc khai báo tay) hay chưa — nếu thiếu, thêm ở bước thi công (không phải quyết định kiến trúc, để `tasks.md` liệt kê cụ thể).

## Rủi ro & ngoại lệ có lý do

- **Giới hạn phát hiện đổi vân tay cùng loại (FR-008)**: đã ghi rõ ở `research.md` R5 — chấp nhận làm mức tối thiểu khả thi với `local_auth`, không phải bỏ sót yêu cầu; nâng cấp native để ngoài phạm vi.
- **`local_auth` cần seam để test được**: gói gọi thẳng platform channel, không mock được nếu dùng trực tiếp trong widget — bọc `BiometricGateway` mỏng (R3/cấu trúc trên) để `PinController`/`PinLockScreen` test bằng fake, không phụ thuộc thiết bị thật (đúng tiền lệ `PinStore` PBI 3).
- **iOS chưa verify** (máy Windows) — rủi ro thấp vì `local_auth` là plugin chính thức đa nền tảng; cần khai báo `NSFaceIDUsageDescription` trong `Info.plist`, verify khi có máy macOS (giống PBI 3).
- **Emulator không có vân tay đăng ký mặc định**: nhóm QA D/E cần cấu hình vân tay ảo qua Extended controls trước — đã ghi rõ trong `quickstart.md`, không phải lỗi app nếu nhóm F kích hoạt nhầm trên máy chưa cấu hình.
- **Đổi thiết bị/restore JSON**: theo FR-011, công tắc luôn về tắt trên máy mới — không có logic "khôi phục trạng thái sinh trắc học" nào cần viết, vì tính năng backup/restore (GĐ3) còn chưa tồn tại.

## File đã tạo

- `.specify/specs/34/research.md`
- `.specify/specs/34/data-model.md`
- `.specify/specs/34/quickstart.md`
- `.specify/specs/34/plan.md`

Bước tiếp theo: chạy `/sora-task 34` để phân rã thành `tasks.md`.
