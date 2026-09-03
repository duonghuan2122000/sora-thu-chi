# Kế hoạch triển khai: Khóa ứng dụng bằng mã PIN

**Mã PBI**: 3
**Liên kết spec**: .specify/specs/3/spec.md
**Ngày tạo**: 2026-09-03

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x (Flutter stable — máy Windows, theo PBI 1/2) |
| Framework / Thư viện chính | Flutter Material; **GetX 4.7.3** (mô-đun đầu có controller → chuyển `GetMaterialApp`); `flutter_secure_storage` 11 (lưu PIN + bộ đếm chống dò); **thêm `crypto`** (SHA-256 cho hash PIN) |
| Lưu trữ dữ liệu | Không dùng drift — trạng thái khóa PIN lưu `flutter_secure_storage` (2 key: `pin_salt_hash`, `lock_state`), độc lập dữ liệu tài chính (xem `data-model.md`) |
| Kiểm thử | `flutter analyze` sạch + `flutter test` (sửa test shell cũ + test mới luồng PIN với `PinStore` fake in-memory & `now()` bơm được) + QA thủ công emulator theo `quickstart.md` |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS (code thuần Flutter + Keychain, rủi ro thấp — verify khi có máy macOS) |
| Ràng buộc hiệu năng | Mở khóa nhập đúng → vào nội dung < 3 giây (SC-003); thao tác secure storage chỉ vài lần mỗi sự kiện (không tạo bậc độ trễ) |
| Ràng buộc khác | App offline, khóa = PIN màn bảo mật toàn màn hình (không app bar/bottom nav), không phải đăng nhập; màn bảo mật tách biệt shell; design system: numpad/dot theo mockup `02-khoa-pin.svg` + design doc §2.4/§3/§5; style tập trung token, widget không hex cứng; tài liệu & commit tiếng Việt có dấu |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + tài liệu nghiệp vụ/design system:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | Khóa app = PIN local; không auth server |
| Đúng stack đã chốt | ✅ | Dùng GetX (đúng lúc có controller), flutter_secure_storage; chỉ thêm `crypto` (doc auth §2.2 yêu cầu hash) |
| PIN hash + lưu qua flutter_secure_storage, không plaintext | ✅ | SHA-256 có muối (Quyết định 1) |
| Màn hình bảo mật tách hoàn toàn khỏi shell | ✅ | Setup/lock toàn màn hình, không app bar/bottom nav |
| Design system (1 màu teal cho hành động chính; numpad/dot đúng mockup) | ✅ | Numpad tròn viền xám, dot teal/xám, số ẩn; coral chỉ dùng cho thông báo cảnh báo/lỗi nhập |
| Style tập trung 1 nơi (theme/token) | ✅ | Bổ sung token vào `app_colors.dart`, widget không hex cứng |
| Cấm fake data & giữ đúng nghiệp vụ | ✅ | Không số liệu giả; PIN yếu cảnh báo nhưng cho phép (đúng giả định spec) |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file/commit tiếng Việt |

⚠️ **Ngoại lệ nghiệp vụ (đã được người dùng chốt, ghi rõ trong spec §Giả định):** PIN **bắt buộc lần đầu mở app** — lệch `docs/auth/chi-tiet-quan-ly-tai-khoan-nguoi-dung.md` §2.1 (vốn "bật/tắt tùy chọn, không bắt buộc"). Khi nghiệp vụ chốt chính thức → cập nhật tài liệu + wiki (Hồ sơ & Bảo mật, Lộ trình) **sau khi implement PBI 3** (đã ghi nhận ở auto-memory). Không phải vi phạm kỹ thuật; kế hoạch theo spec.

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Tóm tắt quyết định chính:
- **PIN lưu hash có muối (SHA-256, `crypto`) trong flutter_secure_storage**; bộ đếm chống dò (`streak`, `lockUntilEpochMs`) lưu JSON cùng store để sống sót khi thoát app (FR-009).
- **Khóa hiển thị bằng route phủ trên navigator gốc** (`GetMaterialApp` + `navigatorKey`); `home` = `BootGate` nền trắng trung tính giữ cả phiên → cold start không lộ nội dung dưới màn khóa (SC-002), resume mở khóa → pop về đúng màn cũ (FR-007).
- **Thời điểm khóa theo vòng đời app** (`WidgetsBindingObserver`): rời active khi phiên đang mở → set cờ; resumed → đẩy màn khóa. Không tự khóa theo thời gian (ngoài phạm vi).
- **Thang chặn**: tính khi sai đủ 4 số; `streak>=5` → chặn ladder `[30s,1p,5p,15p]` tính theo `min(streak-5,3)`; đúng → về 0. Dùng epoch giờ thiết bị (persist qua reboot; chấp nhận rủi ro đổi giờ).
- **Numpad & dot tự dựng** đúng mockup/design doc; ô vị trí vân tay **để trống** (chưa có sinh trắc). Back/back-gesture chặn bằng `PopScope(canPop:false)`.
- **PIN yếu**: cảnh báo dialog, cho phép khi xác nhận tiếp.
- **Testable**: `abstract PinStore` + fake in-memory + `now()` bơm vào controller; `SoraApp` nhận store bơm (test), mặc định real.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — thực thể "Mã PIN thiết bị" (2 key secure storage) + bảng chuyển trạng thái chống dò.
- **Hợp đồng giao diện**: **không tạo** — app nội bộ, offline, không API/CLI công khai.
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A/B/C/D đối chiếu SC-001..007.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Một `PinController` (GetxController) gom logic trạng thái; store trừu tượng nhỏ để test; không thêm repo/service tài chính |
| Không vi phạm mới phát sinh | ✅ | Mọi quyết định research nhất quán hiến pháp; ngoại lệ duy nhất = bắt buộc PIN (nghiệp vụ, đã chốt) |
| Test không phụ thuộc thiết bị/keystore | ✅ | Seam fake store + clock bơm; secure storage thật chỉ chạy trên device |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── pubspec.yaml                                # [SỬA] thêm crypto
├── lib/
│   ├── main.dart                               # [GIỮ] runApp(SoraApp) — không đổi
│   ├── app.dart                                # [SỬA] SoraApp: GetMaterialApp + navigatorKey +
│   │                                           #        WidgetsBindingObserver(lifecycle) +
│   │                                           #        nhận PinStore? (mặc định real), home: BootGate
│   ├── core/
│   │   ├── app_shell.dart                      # [GIỮ] shell (PBI 2) — không đổi hành vi
│   │   ├── boot_gate.dart                      # [TẠO] màn gốc trung tính: đọc store → chuyển
│   │   │                                       #        setup/lock; là "home" giữ cả phiên
│   │   └── security/
│   │       ├── pin_store.dart                  # [TẠO] abstract PinStore + model lock state
│   │       ├── pin_store_secure.dart           # [TẠO] impl flutter_secure_storage + hash/salt
│   │       └── pin_controller.dart             # [TẠO] GetxController: configured/locked/streak/
│   │                                           #        lockUntil, ladder, verify, countdown, now()
│   └── screens/pin/
│       ├── widgets/
│       │   ├── pin_dots.dart                   # [TẠO] indicator 4 chấm (đặc teal / rỗng xám)
│       │   └── pin_keypad.dart                 # [TẠO] numpad 3×4 tròn; ô vân tay trống + backspace
│       ├── pin_setup_screen.dart               # [TẠO] 2 pha (nhập/xác nhận) + cảnh báo PIN yếu
│       └── pin_lock_screen.dart                # [TẠO] màn khóa + lỗi + đếm ngược chặn; PopScope
└── test/
    ├── widget_test.dart                        # [SỬA] tách: nhóm shell pump AppShell trực tiếp;
    │                                           #        nhóm boot SoraApp(store: fake)
    ├── fakes/pin_store_fake.dart               # [TẠO] PinStore in-memory cho test
    ├── pin_flow_test.dart                      # [TẠO] setup/lock/sai/chặn/back trên SoraApp+fake
    └── pin_controller_test.dart                # [TẠO] unit logic ladder/countdown (clock bơm)
```

Không đổi config nền tảng (android/, ios/) — flutter_secure_storage dùng keystore/keychain mặc định, không cần entitlement mới.

## Rủi ro & ngoại lệ có lý do

- **Boot đổi làm vỡ test shell cũ** (widget_test hiện pump `SoraApp` mong shell): xử lý bằng seam — test shell chuyển sang pump `AppShell`; luồng PIN test `SoraApp` với `PinStoreFake`. Kèm bơm `now()` để định thời test xác định (widget test không đẩy `DateTime.now()` bằng `pump`).
- **Flash nội dung khi cold start (SC-002)**: `BootGate` nền trắng là `home` + route đầu tiên luôn là setup/lock → không có nội dung dưới. Kiểm chứng 10/10 theo quickstart nhóm B.
- **Layout cỡ chữ lớn / màn thấp (SC-007)**: bố cục màn PIN phân phối theo không gian có sẵn (tránh chiều cao cứng), nút bấm ≥ 44px, text co mềm; nếu vẫn tràn trên thiết bị thật → điều chỉnh rồi ghi trạng thái sau thi công, không bỏ ngang.
- **Predictive back / cử chỉ back iOS**: `PopScope(canPop:false)`; kiểm chứng thủ công trên Android có cử chỉ điều hướng.
- **Đổi giờ hệ thống né chặn**: chấp nhận (offline 1 thiết bị, không phải đối thủ chủ động) — đã ghi rõ research Quyết định 5.
- **Sinh trắc chưa có** → ô vị trí vân tay trên numpad để trống theo design doc §2.4 (mockup hiển thị icon, spec giả định bỏ trống đợt này).
- **iOS chưa verify** (máy Windows): code thuần Flutter + Keychain mặc định → rủi ro thấp; giữ trạng thái, verify khi có máy macOS.
- **Ngoại lệ nghiệp vụ bắt buộc PIN**: theo spec, cần đồng bộ wiki/tài liệu sau khi implement (đã ghi nhận — không thuộc phạm vi plan này).

## File đã tạo

- `.specify/specs/3/research.md`
- `.specify/specs/3/data-model.md`
- `.specify/specs/3/quickstart.md`
- `.specify/specs/3/plan.md`

Bước tiếp theo: chạy `/sora-task 3` để phân rã thành tasks.md.
