# Danh sách Task: Logo ứng dụng & màn hình Splash

**Mã PBI**: 25
**Nguồn**: `spec.md`, `plan.md`, `research.md` (R1–R10), `contracts/brand-assets.md`, `quickstart.md`
**Ngày tạo**: 2026-09-13
**Mốc xuất phát**: PBI 24 — 809 test, drift v8, analyze sạch (riêng `test/transactions_dao_test.dart` đã đỏ sẵn từ trước, không tính).

## Định dạng task

`- [ ] [MãTask] [P?] [Story?] Mô tả kèm đường dẫn file`

- `[P]`: chạy song song được (khác file, không phụ thuộc task chưa xong)
- `[Story]`: chỉ ở pha User Story (`[US1]`, `[US2]`, `[US3]`)
- Spec không chia user story P1/P2/P3 ⇒ chia theo **3 lát cắt giao được độc lập** (mỗi lát có tiêu chí kiểm thử riêng), giữ đúng thứ tự ưu tiên rủi ro trong `research.md`

## Pha 1: Setup

- [X] T001 [P] Chốt mốc nền trước khi sửa: chạy `flutter analyze` + `flutter test` trong `app/sora_thu_chi/`, ghi lại số test và danh sách test đỏ sẵn (`test/transactions_dao_test.dart`) để đối chiếu ở T028
- [X] T002 [P] Trích hằng số hình học từ `docs/logo/logo-concept-a-coin-flow.svg` (viewBox, tâm coin, bán kính `r`, toạ độ + bề dày 2 mũi tên, bề dày đường phân tách ngang) làm số liệu đầu vào cho `app/sora_thu_chi/tool/gen_brand_assets.dart`; đối chiếu tỉ lệ đã chốt ở `contracts/brand-assets.md` §2

## Pha 2: Foundational

*(Bắt buộc xong trước mọi user story — cả 3 story đều sinh asset từ script này)*

- [X] T003 Tạo khung `app/sora_thu_chi/tool/gen_brand_assets.dart` (chạy bằng `dart run`, dùng package `image` đã có — **không thêm dependency**): hằng số màu `brandTeal #0F6E56` / `brandCoral #D85A30` / `brandWhite #FFFFFF`, hằng số tỉ lệ theo `contracts/brand-assets.md` §2 (`0.68`, `0.88`, `0.021`, `0.05`, `0.03`), hàm hình học dùng chung (đường tròn coin, đường phân tách, 2 mũi tên, vòng viền trắng)
- [X] T004 Thêm vào `app/sora_thu_chi/tool/gen_brand_assets.dart` hàm render raster bằng `image`: vẽ coin 2 nửa + đường phân tách + 2 mũi tên + vòng viền trắng; tham số hoá đường kính khung, tỉ lệ coin/khung, nền đục hay trong suốt; **không** gradient/đổ bóng/alpha từng phần (FR-008)
- [X] T005 Thêm vào `app/sora_thu_chi/tool/gen_brand_assets.dart` hàm phát cùng hình học sang SVG path và xuất VectorDrawable XML (viewport, `<path android:fillColor>`, 3 mã màu) để phần Android không lệch hình so với phần raster (R2)

## Pha 3: User Story 1 — Icon trên màn hình chính (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: app cài lên máy (Android + iOS) hiện logo Concept A thay icon mặc định của `flutter create`; tên app dưới icon vẫn "Sora Thu Chi".

**Tiêu chí kiểm thử độc lập**: `flutter build apk --release` xanh + `test/brand_assets_test.dart` xanh + nhìn màn hình chính của emulator thấy đồng xu hai nửa màu (QA `quickstart.md` bước A/B) — không cần splash đã xong.

- [X] T006 [US1] Thêm phần sinh icon Android vào `app/sora_thu_chi/tool/gen_brand_assets.dart`: `android/app/src/main/res/drawable/ic_launcher_foreground.xml` (VectorDrawable 108×108), `android/app/src/main/res/values/ic_launcher_background.xml` (`#FF0F6E56`), `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (`<adaptive-icon>` trỏ 2 file trên)
- [X] T007 [P] [US1] Xoá 5 file icon mặc định `app/sora_thu_chi/android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` (minSdk 26 ⇒ `anydpi-v26` là đường duy nhất — R1, SC-001)
- [X] T008 [US1] Thêm phần sinh icon iOS vào `app/sora_thu_chi/tool/gen_brand_assets.dart`: ghi đè **đúng 15 tên file** trong `app/sora_thu_chi/ios/Runner/Assets.xcassets/AppIcon.appiconset/` (khớp `Contents.json`, coin + vòng trắng 68% cạnh, **nền teal đục, không alpha** — R4)
- [X] T009 [P] [US1] Xác nhận không phải sửa: `app/sora_thu_chi/android/app/src/main/AndroidManifest.xml` giữ `android:icon="@mipmap/ic_launcher"` + `android:label="Sora Thu Chi"`, và `app/sora_thu_chi/ios/Runner/Info.plist` giữ `CFBundleDisplayName = "Sora Thu Chi"` (FR-003)
- [X] T010 [US1] Viết `app/sora_thu_chi/test/brand_assets_test.dart` (đọc asset bằng package `image`, không cần emulator): đủ file Android/iOS tồn tại; **không còn** `mipmap-*/ic_launcher.png`; `ic_launcher.xml` chứa `adaptive-icon`; `ic_launcher_foreground.xml` chứa đủ 3 mã màu; `Icon-App-1024x1024@1x.png` mọi pixel alpha `255`; không asset nào chứa chuỗi `"Concept A"` / `"Coin Flow"` (contracts §6.1–3, 5, 7 — FR-011)
- [X] T011 [US1] Chạy `dart run tool/gen_brand_assets.dart` rồi `flutter test test/brand_assets_test.dart`, sau đó `flutter build apk --release` để xác nhận R1 (không vướng cảnh báo `aapt2` vì thiếu mipmap mặc định); **nếu build đỏ** → cho generator xuất thêm 5 PNG `mipmap-*/ic_launcher.png` theo phương án lùi R1, không đổi kiến trúc

## Pha 4: User Story 2 — Splash tầng Flutter (Ưu tiên: P2)

**Mục tiêu**: mỗi lần cold start, người dùng thấy splash nền teal đặc + logo + tên app trắng, tự biến mất khi app sẵn sàng (trần 5 giây), rồi vào đúng màn khóa / Tổng quan với đúng ngôn ngữ + giao diện đã chọn.

**Tiêu chí kiểm thử độc lập**: `test/splash_screen_test.dart` xanh + chạy `flutter run` và cold start thấy splash đúng (QA bước C–F, H, I) — không cần tầng native đã xong.

- [X] T012 [P] [US2] Thêm phần sinh PNG splash Flutter vào `app/sora_thu_chi/tool/gen_brand_assets.dart`: `app/sora_thu_chi/assets/brand/coin_flow_logo.png` (1024 px, nền trong suốt, coin + vòng trắng 88% khung, lề 6% mỗi cạnh)
- [X] T013 [P] [US2] Khai báo asset trong `app/sora_thu_chi/pubspec.yaml`: khối `flutter: assets: - assets/brand/` (không thêm dependency nào)
- [X] T014 [US2] Sửa `app/sora_thu_chi/lib/core/boot_gate.dart`: `PinGate` render splash — nền `AppColors.teal` (**không** dùng `SoraColors.of(context)` để nền không đổi theo Sáng/Tối), `Image.asset('assets/brand/coin_flow_logo.png')` rộng `140dp` căn giữa, `Text('Sora Thu Chi')` màu trắng (tên thương hiệu, **không** dịch); **không** app bar, bottom nav, nút bấm, chỉ báo tải, chữ phụ (FR-004/007/008/016)
- [X] T015 [US2] Sửa `app/sora_thu_chi/lib/core/boot_gate.dart`: `_bootstrap` await **song song** `PinController.init()` + `ThemeController.load()` + `LocaleController.load()`, trần **5 giây** bằng `Timer` **huỷ được** (`timer.cancel()` trong `whenComplete` — tránh *"A Timer is still pending"* khi test), rồi mới cho splash kết thúc (FR-006/FR-012/FR-013, R6)
- [X] T016 [P] [US2] Sửa `app/sora_thu_chi/lib/app.dart`: bỏ lời gọi **fire-and-forget** `ThemeController.load()` / `LocaleController.load()` trong `SoraApp.initState` (đã chuyển vào nhóm chờ ở T015); **giữ nguyên** `Get.put(...)` để `Obx`/`themeMode` có nguồn ngay frame đầu, và giữ `ensureScanController().load()` fire-and-forget (R8)
- [X] T017 [US2] Viết `app/sora_thu_chi/test/splash_screen_test.dart` (widget test, không cần thiết bị): splash là màn đầu tiên; có nền teal + logo + `Text('Sora Thu Chi')` trắng; **không** app bar / bottom nav / nút bấm; hiển thị **giống nhau** ở giao diện Sáng và Tối; tự biến mất khi app sẵn sàng (không cần chạm) → màn khóa nếu có PIN / Tổng quan nếu không; kết thúc trong 5 giây khi store **không bao giờ xong**; tên app không tràn khi `textScaler` lớn (FR-004…FR-013, FR-016)
- [X] T018 [US2] Thêm vào `app/sora_thu_chi/test/splash_screen_test.dart` test chốt FR-005: sau khi app vào trong, `PinGate` đã bị gỡ khỏi stack (`pushAndRemoveUntil((_) => false)`) ⇒ **resume không hiện lại splash** — chỉ thêm test, **không** sửa luồng (kế hoạch §Giai đoạn 1 mục 2)
- [X] T019 [US2] Chạy `dart run tool/gen_brand_assets.dart` + `flutter test` toàn bộ, xử lý rủi ro plan #5: `test/pin_flow_test.dart` và `test/widget_test.dart` có thể đỏ vì nay có thêm nhóm chờ + splash (kỳ vọng: `load()` idempotent + fake store trả về ngay ⇒ splash tự kết thúc trong `pumpAndSettle`)

## Pha 5: User Story 3 — Splash native liền mạch (Ưu tiên: P3)

**Mục tiêu**: từ lúc chạm icon tới lúc tầng Flutter vẽ splash **không có khung nền trắng/đen kéo dài** và **không nhảy hình** giữa tầng hệ điều hành và tầng app (Android 12+ và iOS).

**Tiêu chí kiểm thử độc lập**: cold start trên emulator Android 12+ (và máy thật/Mac cho iOS) thấy logo hiện gần như tức thì, cùng nền cùng cỡ logo với tầng Flutter (QA bước C) — không cần icon launcher đã xong.

- [X] T020 [US3] Thêm phần sinh `app/sora_thu_chi/android/app/src/main/res/drawable/splash_logo.xml` vào `tool/gen_brand_assets.dart`: VectorDrawable coin + vòng trắng, viewport 144×144, **có lề trong suốt** để không bị cắt khi tầng native hiển thị ở cỡ khác (R5, R9)
- [X] T021 [P] [US3] Sửa `app/sora_thu_chi/android/app/src/main/res/drawable/launch_background.xml`: `layer-list` = nền teal (`@color/brand_teal`) + `@drawable/splash_logo` căn giữa `android:width/height="140dp"` — **cùng cỡ 140dp với tầng Flutter** để không nhảy hình (FR-010, rủi ro plan #3)
- [X] T022 [P] [US3] Sửa `app/sora_thu_chi/android/app/src/main/res/drawable-v21/launch_background.xml`: nội dung như T021, bỏ `?android:colorBackground` hiện tại
- [X] T023 [P] [US3] Tạo `app/sora_thu_chi/android/app/src/main/res/values/colors.xml` (`brand_teal = #FF0F6E56`) và `app/sora_thu_chi/android/app/src/main/res/values-v31/styles.xml` với `windowSplashScreenBackground` / `windowSplashScreenAnimatedIcon` / `postSplashScreenTheme` cho `LaunchTheme` (Android 12+ SplashScreen API)
- [X] T024 [P] [US3] Ghi đè `app/sora_thu_chi/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,@2x,@3x}.png` = 120 / 240 / 360 px, nền **trong suốt** (đặt trên nền teal của storyboard), coin + vòng trắng 88% khung
- [X] T025 [US3] Sửa `app/sora_thu_chi/ios/Runner/Base.lproj/LaunchScreen.storyboard` với thay đổi **tối thiểu** (rủi ro plan #2 — repo không có Mac để mở Interface Builder): `backgroundColor` → teal `#0F6E56`; `imageView` giữ `contentMode="center"`, khai báo lại `<image name="LaunchImage" width="120" height="120"/>`; thêm **1** `UILabel` "Sora Thu Chi" trắng đậm canh giữa dưới logo. **Nếu không kiểm được trên máy thật** → hạ xuống chỉ đổi màu nền + logo, bỏ label
- [X] T026 [US3] Mở rộng `app/sora_thu_chi/test/brand_assets_test.dart`: `launch_background.xml` + `values-v31/styles.xml` + `LaunchScreen.storyboard` đều mang `#0F6E56` và **không còn** `white` / `colorBackground`; `LaunchImage*.png` có pixel alpha `0` ở góc (contracts §6.4, 6.6)

## Pha cuối: Polish & Cross-cutting

- [X] T027 Cập nhật `docs/logo/logo-concepts-sora-thu-chi.md`: append mục **"Phương án chốt triển khai"** ghi rõ Concept A dùng cho **cả icon launcher và splash** (dù doc khuyến nghị Concept C cho icon), kèm biến thể **vòng viền trắng** và **nền icon teal** — để `docs/` không mâu thuẫn với sản phẩm (plan §Kiểm tra hiến pháp)
- [X] T028 Chạy `flutter analyze` + `flutter test` toàn bộ trong `app/sora_thu_chi/`; đối chiếu mốc T001: không cảnh báo mới, không test cũ nào đỏ thêm ngoài `test/transactions_dao_test.dart` đã đỏ sẵn
- [X] T029 QA mắt trên emulator/thiết bị theo checklist **A–O** ở `quickstart.md` §3 (kèm nhánh iOS nếu có Mac), ghi lại kết quả từng bước vào cuối file này — đặc biệt bước B (SC-004: icon nhỏ nhất còn rõ 2 nửa + 2 mũi tên) và bước C (FR-010: không nhảy hình)
- [X] T030 Sync wiki bằng skill `sora-wiki`: cập nhật page concept design system + `wiki-knowledge/log.md` với quy tắc nhận diện mới (biến thể logo vòng viền trắng, nền icon teal, splash dùng màu bất biến không theo theme)

## Sơ đồ phụ thuộc

```text
Setup (T001, T002)
   ↓
Foundational (T003 → T004 → T005)          # script + hình học dùng chung cho cả 3 story
   ↓
US1 Icon launcher (T006 → T008,T010 → T011)   🎯 MVP
   ↓
US2 Splash Flutter (T012,T013 → T014 → T015 → T017 → T018 → T019)
   ↓
US3 Splash native (T020 → T021..T025 → T026)
   ↓
Polish (T027, T028, T029, T030)
```

Chi tiết phụ thuộc:

- T004 cần T003; T005 cần T003 (không cần T004 — phần vector độc lập với phần raster)
- T006, T008, T012, T020 đều sửa **cùng file** `tool/gen_brand_assets.dart` ⇒ **tuần tự**, không chạy song song dù khác story
- T010 tạo `test/brand_assets_test.dart`; T026 mở rộng cùng file ⇒ T026 **sau** T010
- T014 → T015 sửa cùng `lib/core/boot_gate.dart` ⇒ tuần tự
- T021/T022 hai file khác nhau nhưng cùng nội dung ⇒ làm xong T020 là chạy song song được
- US1, US2, US3 giao được độc lập: mỗi story là một bản release được (icon trước, splash sau, liền mạch cuối)

## Ví dụ chạy song song

```text
# Setup
T001 [P] chốt mốc test        ‖  T002 [P] trích hằng số hình học từ SVG

# US1 — sau khi T006 xong
T007 [P] xoá 5 PNG mipmap mặc định  ‖  T009 [P] xác nhận manifest/Info.plist
(T008 chờ T006; T010 sau T007+T008+T009; T011 sau T010)

# US2 — các file khác nhau
T012 [P] sinh PNG splash Flutter  ‖  T013 [P] khai báo asset pubspec  ‖  T016 [P] bỏ load() fire-and-forget ở app.dart
(T014 → T015 tuần tự trên boot_gate.dart; T017 → T018 tuần tự trên splash_screen_test.dart)

# US3 — sau khi T020 xong
T021 [P] launch_background.xml  ‖  T022 [P] drawable-v21  ‖  T023 [P] colors.xml + values-v31  ‖  T024 [P] LaunchImage 3 cỡ
(T025 storyboard độc lập; T026 sau khi T010 + T025 xong)
```

## Chiến lược triển khai

- **MVP đề xuất**: **US1 — Icon trên màn hình chính**. Đây là phần nhận diện thấy được ngay khi cài app, tự đứng một mình (không phụ thuộc splash), và là chỗ rủi ro cao nhất (R1 — adaptive icon không PNG mặc định; SC-004 — icon 2 màu ở cỡ nhỏ) nên cần xác nhận sớm bằng `flutter build apk --release`.
- **Giao hàng tăng dần**:
  1. **US1** → cài lên máy đã thấy logo mới (đóng SC-001/SC-004).
  2. **US2** → cold start có splash đầy đủ và vào đúng luồng (đóng FR-004…FR-013, FR-016; SC-003, SC-005, SC-006).
  3. **US3** → hết khung trắng và nhảy hình lúc khởi động (đóng FR-010, FR-015; SC-002). Có thể lùi lại nếu chưa có máy Mac — US2 vẫn đứng vững một mình.
- **Thứ tự thi công bắt buộc trong từng story**: sinh asset (generator) → cấu hình nền tảng → mã Flutter → test → QA mắt.
- **Nghiệm thu cuối**: `flutter analyze` sạch, `flutter test` ≥ 809 + không đỏ thêm, `flutter build apk --release` xanh, checklist QA A–O đạt.
- **Ngoài phạm vi, không làm**: onboarding, favicon/marketing, đổi tên app/tên gói, logo trong nội dung app, Concept B/C, thiết kế lại màu/typography (spec §Ngoài phạm vi).

## Kết quả QA (T029) — chạy trên emulator `sdk_gphone16k_x86_64` (Android 16, 420dpi), 2026-09-13

Bản cài: `app-release.apk` (release, cài đè bằng `adb install -r`).

| # | Bước | Kết quả |
|---|---|---|
| A | Icon trên màn hình chính | ✅ đồng xu 2 nửa màu + 2 mũi tên trắng, tên "Sora Thu Chi"; **phải cài lại** mới thấy (bản cài cũ giữ icon mặc định của Flutter) |
| B | Kiểu icon tròn | ✅ mask tròn: coin + 2 mũi tên + **vòng viền trắng** đều rõ, không lộ nền lạ |
| C | Chạm icon → logo hiện, không khung trắng, không nhảy hình | ✅ nền đã là teal ngay từ frame đầu; logo tầng native **122,7dp** ≈ tầng Flutter **123,2dp** ⇒ không nhảy |
| D | Nội dung splash | ✅ nửa native: chỉ logo trên nền teal, không app bar/bottom nav/nút/chữ chú thích |
| E | Nhìn kỹ logo — đủ hai nửa | ✅ vòng trắng tách nửa teal khỏi nền (xem ghi chú dưới — bản đầu **trượt** bước này) |
| F | Splash tự tắt, tối đa 5 giây | ✅ |
| G | Sau splash vào đúng màn (khóa PIN / Tổng quan) | ✅ |
| H | Giao diện Tối rồi cold start — splash giống hệt lúc Sáng, màn kế tiếp đúng Tối | ✅ |
| I | Ngôn ngữ English rồi cold start — màn kế tiếp đúng ngôn ngữ | ✅ |
| J | Chế độ máy bay rồi cold start — splash + icon y hệt | ✅ |
| K | Xoay ngang / màn nhỏ / màn dài | ✅ |
| L | Cỡ chữ hệ thống lớn nhất — tên app không tràn | ✅ |
| M | Về nền rồi mở lại — không hiện lại splash | ✅ |
| N | Các tab không có logo trong nội dung app | ✅ |
| O | Cài đè bản cũ — icon đổi thành logo mới | ✅ |

**2 lỗi thật phát hiện ở bước B/E — đã sửa (chi tiết `contracts/brand-assets.md` §7):**

1. Path đường tròn viết dạng rút gọn `a r,r 0 1 0 2r,0 ... Z` bị `VectorDrawable` bỏ qua (vector ra rỗng) ⇒ **mất nửa teal + vòng viền trắng** ở cả icon launcher lẫn splash native. Sửa: dùng hai cung bán nguyệt tuyệt đối `A`.
2. `windowSplashScreenAnimatedIcon` bị hệ thống scale lên ~277dp rồi cắt theo đường tròn ~192dp ⇒ bản `0.88` mất vòng viền và **to hơn tầng Flutter ~1,6 lần** (nhảy hình). Sửa: thêm `splash_logo_masked.xml` với coin `0.44` khung (đo lại: 122,7dp ≈ 123,2dp của tầng Flutter).

**Ghi chú:** bước D/E chỉ xác nhận được **tầng native** — tầng Flutter (`PinGate`) tắt trong < ~250ms trên emulator nên không chụp kịp frame có logo + chữ "Sora Thu Chi"; tầng đó được phủ bằng `test/splash_screen_test.dart`.

**F–O:** người dùng chạy tay và xác nhận **đạt toàn bộ** (2026-09-13) — không ghi lại giá trị đo riêng cho từng bước. Nhánh **iOS chưa chạy** (không có máy Mac); phần iOS được phủ ở mức tĩnh bằng `test/brand_assets_test.dart` (màu teal trong `LaunchScreen.storyboard`, `LaunchImage*.png` nền trong suốt).
