# Kế hoạch triển khai: Logo ứng dụng & màn hình Splash

**Mã PBI**: 25
**Liên kết spec**: `.specify/specs/25/spec.md`
**Ngày tạo**: 2026-09-13
**Trạng thái**: Sẵn sàng phân rã task (`/sora-task 25`)

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3 (`sdk: ^3.12.2`), Flutter; script sinh asset chạy bằng `dart run` (pure Dart, không `dart:ui`) |
| Framework / Thư viện chính | Flutter + GetX (đã dùng). **Không thêm dependency nào**: sinh ảnh bằng `image: ^4.9.2` (đã có trong `dependencies`); không dùng `flutter_launcher_icons` / `flutter_native_splash` / `flutter_svg` |
| Lưu trữ dữ liệu | Không đụng. Drift giữ **v8**; PBI thuần trình bày (R7) |
| Kiểm thử | `flutter_test` (widget test splash + test asset đọc PNG/XML — không cần emulator), `flutter analyze`, `flutter build apk --release` để xác nhận cấu hình icon |
| Nền tảng triển khai | Android (`minSdk = maxOf(flutter.minSdkVersion, 26)`, `compileSdk 37`) và iOS. Web/desktop **ngoài phạm vi** (spec §Giả định) |
| Ràng buộc hiệu năng | Logo xuất hiện ≤ 1 giây sau khi chạm icon (FR-015, SC-002); splash tự kết thúc ≤ 5 giây (FR-006, SC-003) |
| Ràng buộc khác | Offline hoàn toàn (FR-014 — asset nhúng trong app); nền splash giống nhau ở Sáng/Tối (FR-004/008); bảng màu teal `#0F6E56` / coral `#D85A30` / trắng, không gradient/đổ bóng (FR-008); tên app giữ "Sora Thu Chi" (FR-003) |
| Điểm chạm mã nguồn | `lib/core/boot_gate.dart` (splash + nhóm chờ nạp), `lib/app.dart` (chuyển `load()` theme/locale vào nhóm chờ), `pubspec.yaml` (asset), cấu hình native Android/iOS, `tool/gen_brand_assets.dart` (mới) |

*Không còn mục `NEEDS CLARIFICATION` — mọi điểm mở đã chốt ở `research.md` (R1–R10).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

`.specify/memory/constitution.md` **không tồn tại** trong repo ⇒ đối chiếu theo ràng buộc dự án đã chốt ở `CLAUDE.md` + `docs/` (design system, kiến trúc, offline, quy trình PBI).

| Nguyên tắc dự án | Tuân thủ? | Ghi chú |
|---|---|---|
| `docs/` là nguồn chân lý nghiệp vụ/thiết kế | ⚠️ | PBI chốt **Concept A cho cả icon launcher**, trong khi `docs/logo/logo-concepts-sora-thu-chi.md` khuyến nghị Concept C cho icon (lý do rõ nét ở cỡ nhỏ). Spec đã ghi nhận đây là quyết định của người dùng (spec §Giả định) ⇒ cần **append** mục "Phương án chốt triển khai" vào doc logo để docs không mâu thuẫn thực tế. Không vi phạm design system. |
| Design system: đúng **1** màu thương hiệu teal cho hành động chính, coral **chỉ** cho ngữ cảnh chi tiêu | ✅ | Logo dùng teal cho nửa Thu, coral cho nửa Chi — coral đang nằm đúng ngữ cảnh "chi". Không phát sinh màu mới, không gradient/đổ bóng (FR-008). |
| App offline hoàn toàn, không phụ thuộc mạng | ✅ | Asset nhúng trong app, không tải từ xa (FR-014). |
| Hạn chế tối đa dependency bên thứ ba | ✅ | **0 gói mới** — sinh ảnh bằng package `image` đã có (R2), phần Android dùng vector XML do script sinh (R1). |
| Không đụng nghiệp vụ/dữ liệu ngoài phạm vi PBI | ✅ | Không bảng/cột/migration nào; không sửa luồng khóa app, không thêm logo vào nội dung app (FR-010, spec §Ngoài phạm vi). |
| Giữ nguyên hành vi đã chốt của PBI trước (khóa app là màn toàn màn hình, boot không lộ nội dung tài chính) | ✅ | Splash **nằm trước** màn khóa, chỉ chứa logo + tên app, không nội dung tài chính, không app bar/bottom nav (FR-007). |
| Ngôn ngữ tài liệu & commit: tiếng Việt có dấu | ✅ | Mọi file sinh ra trong PBI này viết tiếng Việt. |
| Quy trình PBI: spec → plan → task → implement | ✅ | Đang ở bước plan; spec đã ở trạng thái "Sẵn sàng lập kế hoạch". |
| Wiki là bản biên soạn của `docs/`, phải sync khi nghiệp vụ/thiết kế đổi | ⚠️ | PBI thêm **quy tắc nhận diện thương hiệu** (biến thể logo có vòng trắng, nền icon teal) — cần cập nhật wiki sau khi thi công (page concept design system + `log.md`), như các PBI trước. Đưa vào task cuối. |

Không có vi phạm nào **không thể tránh** ⇒ không cần mục "Ngoại lệ có lý do".

## Giai đoạn 0 — Nghiên cứu

Xem chi tiết tại `research.md`. Tóm tắt các quyết định chính:

- **R1 — Icon Android**: adaptive icon (`mipmap-anydpi-v26` + VectorDrawable foreground + color background), **xoá** 5 PNG `mipmap-*` mặc định. *Vì* `minSdk ≥ 26` nên mọi máy đọc được `anydpi-v26`; vector sắc nét mọi mật độ (FR-002/009). *Khác*: sinh PNG theo density; thêm `flutter_launcher_icons` (vẫn thiếu ảnh nguồn).
- **R2 — Nguồn ảnh**: một script Dart `tool/gen_brand_assets.dart` dùng `image` (đã có) vẽ lại Concept A và sinh **toàn bộ** asset Android (vector XML) + iOS (PNG) + Flutter (PNG splash). *Vì* repo chỉ có SVG concept, `image` đã có sẵn, kết quả tái lập — 0 gói mới. *Khác*: 2 gói splash/launcher (vẫn cần script vẽ), công cụ ngoài (không tái lập), `flutter_svg` (không dùng được cho launcher icon).
- **R3 — Biến thể logo**: Concept A **+ vòng viền trắng** quanh đồng xu. *Vì* FR-016 (nửa teal không được chìm vào nền teal) và icon launcher cần nền đặc ⇒ một hình dùng chung cho cả hai ngữ cảnh. *Khác*: nền splash trắng (vi phạm FR-004); teal nhạt (lệch bảng màu).
- **R4 — Nền icon launcher**: teal đặc `#0F6E56`. *Vì* iOS cấm PNG icon trong suốt, Android mask bo góc sẽ lộ nền launcher nếu để trong suốt (SC-001). *Khác*: nền trắng (lệch nhận diện, mất tác dụng đường phân tách trắng); coin full-bleed (bị mask cắt).
- **R5 — Splash hai tầng**: tầng native (Android `launch_background` + `values-v31` SplashScreen API; iOS `LaunchScreen.storyboard`) + tầng Flutter (`PinGate`), cùng nền teal, cùng cỡ logo 140dp. *Vì* FR-010 (không khung trống/nhảy hình) và FR-015 (≤1s). *Khác*: chỉ tầng Flutter (còn khung trắng lúc engine khởi động); thêm `flutter_native_splash`.
- **R6 — Kết thúc splash**: `PinGate` chờ song song `PinController.init()` + `ThemeController.load()` + `LocaleController.load()`, trần 5 giây bằng `Timer` **huỷ được** (tránh *"A Timer is still pending"* trong test). *Vì* FR-006 + FR-013. *Khác*: `Future.any` + `delay` (rò timer); delay cứng (vi phạm giả định không giữ người dùng thêm).
- **R7/R8**: không đụng drift (schema v8); `ensureScanController().load()` giữ fire-and-forget.
- **R9**: hợp đồng asset (kích thước/màu/tỉ lệ) — chi tiết ở `contracts/brand-assets.md`.
- **R10**: hai file test không cần thiết bị (`splash_screen_test`, `brand_assets_test`); không golden test.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: **không có** `data-model.md` — PBI không thêm thực thể/bảng/cột nào (R7). Trạng thái duy nhất "đang boot" là cục bộ trong widget, không lưu trữ.
- **Hợp đồng giao diện**: `contracts/brand-assets.md` — bảng file asset bắt buộc, hằng số màu/tỉ lệ, các bất biến kiểm được bằng máy (đây là "API" giữa script sinh asset, hai nền tảng và test).
- **Kịch bản khởi động nhanh**: `quickstart.md` — lệnh sinh asset, lệnh test, và checklist QA mắt A–O truy vết từng FR/SC.

### Hành vi chốt trong thiết kế

1. **Thứ tự màn hình cold start**: native splash (teal + logo) → tầng Flutter `PinGate` (splash teal, logo 140dp + "Sora Thu Chi" trắng) → *khi app sẵn sàng* → màn **khóa app** (nếu đã bật PIN) hoặc **Tổng quan**. Splash **không** nằm trong `AppShell`; không có route riêng cho splash (dùng luôn `home` hiện có ⇒ ít file, không đổi điều hướng).
2. **Resume không hiện splash**: `PinGate` bị gỡ khỏi stack bằng `pushAndRemoveUntil((_) => false)` khi vào app ⇒ cơ chế hiện có đã thoả FR-005; PBI chỉ **thêm test chốt hành vi**, không sửa luồng.
3. **Splash không đổi theo giao diện**: dùng hằng `AppColors.teal` (màu bất biến) chứ **không** `SoraColors.of(context)` cho nền/chữ ⇒ FR-004/FR-008 đúng ở cả Sáng và Tối, không cần asset theo theme.
4. **Nạp trước khi hiện màn kế tiếp**: nhóm chờ chuyển từ `SoraApp.initState` (fire-and-forget) sang `PinGate._bootstrap` (await, trần 5s) ⇒ FR-013. `Get.put` controller vẫn ở `initState` để `Obx`/`themeMode` có nguồn ngay từ frame đầu.
5. **Tên app**: chuỗi `"Sora Thu Chi"` trên splash là **tên thương hiệu**, không dịch theo ngôn ngữ (khớp `GetMaterialApp.title` đang hardcode).

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc dự án | Tuân thủ? | Ghi chú |
|---|---|---|
| `docs/` là nguồn chân lý | ⚠️ → ✅ sau task docs | Thiết kế chốt dùng Concept A cho cả icon (spec §Giả định, FR-001). Kế hoạch có task **append** mục "Phương án chốt triển khai" + biến thể vòng trắng vào `docs/logo/logo-concepts-sora-thu-chi.md` để doc phản ánh đúng thực tế. |
| Design system (1 màu thương hiệu, coral chỉ cho chi, phẳng) | ✅ | Chỉ dùng 3 màu đã chốt; hình học lấy nguyên từ SVG concept, chỉ thêm nét trắng (R3). |
| Offline hoàn toàn | ✅ | Asset nhúng; không gọi mạng ở bất kỳ tầng nào. |
| Tối thiểu dependency | ✅ | 0 gói mới; phần việc lặp lại (sinh ảnh nhiều kích cỡ) làm bằng script nội bộ dùng package đã có. |
| Không đụng nghiệp vụ/dữ liệu ngoài phạm vi | ✅ | Không migration; không sửa luồng khóa/quét/ngân sách; không thêm logo vào nội dung app. |
| Giữ hành vi PBI trước | ✅ | Boot vẫn không lộ nội dung tài chính (splash chỉ logo + tên); khóa app vẫn là màn toàn màn hình đứng trước; resume vẫn khóa như PBI 3. |
| Tiếng Việt trong tài liệu/commit | ✅ | Kế hoạch, test name, comment đều tiếng Việt. |
| Tối thiểu bề mặt thay đổi | ✅ | Mã app chỉ đụng **2 file** (`boot_gate.dart`, `app.dart`) + `pubspec.yaml`; phần còn lại là asset/cấu hình nền tảng. |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── pubspec.yaml                                   # SỬA: khai báo assets/brand/
├── assets/brand/coin_flow_logo.png                # MỚI (sinh bởi script) — logo splash 1024px trong suốt
├── tool/gen_brand_assets.dart                     # MỚI — nguồn hình học duy nhất, sinh mọi asset
├── lib/
│   ├── app.dart                                   # SỬA: bỏ load() fire-and-forget của theme/locale (chuyển vào nhóm chờ)
│   └── core/boot_gate.dart                        # SỬA: PinGate render splash + await nhóm nạp (trần 5s, Timer huỷ được)
├── test/
│   ├── splash_screen_test.dart                    # MỚI — hành vi splash (FR-004…FR-016)
│   └── brand_assets_test.dart                     # MỚI — bất biến asset (contracts §6)
├── android/app/src/main/res/
│   ├── mipmap-anydpi-v26/ic_launcher.xml          # MỚI (sinh) — adaptive-icon
│   ├── drawable/ic_launcher_foreground.xml        # MỚI (sinh) — vector coin + vòng trắng
│   ├── drawable/splash_logo.xml                   # MỚI (sinh) — vector logo splash
│   ├── values/ic_launcher_background.xml          # MỚI (sinh) — teal background
│   ├── values/colors.xml                          # MỚI (sinh) — brand_teal
│   ├── values-v31/styles.xml                      # MỚI — SplashScreen API Android 12+
│   ├── drawable/launch_background.xml             # SỬA — teal + splash_logo căn giữa
│   ├── drawable-v21/launch_background.xml         # SỬA — như trên
│   └── mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png   # XOÁ (5 file icon mặc định)
├── ios/Runner/Assets.xcassets/
│   ├── AppIcon.appiconset/*.png                   # GHI ĐÈ (sinh) — 15 cỡ, nền teal đục
│   └── LaunchImage.imageset/LaunchImage{,@2x,@3x}.png  # GHI ĐÈ (sinh)
└── ios/Runner/Base.lproj/LaunchScreen.storyboard  # SỬA — nền teal + logo + tên app

docs/logo/logo-concepts-sora-thu-chi.md            # SỬA — ghi lại phương án chốt (A cho icon + splash, biến thể vòng trắng)
wiki-knowledge/                                    # SỬA (sau thi công) — page design system + log.md
```

## Rủi ro & ngoại lệ có lý do

| # | Rủi ro | Ảnh hưởng | Xử lý |
|---|---|---|---|
| 1 | `aapt2`/lint cảnh báo vì `@mipmap/ic_launcher` chỉ có cấu hình `anydpi-v26` (đã xoá PNG mặc định) | Build APK | Xác nhận ngay ở task Android bằng `flutter build apk --release`. Nếu đỏ → phương án lùi R1: cho generator xuất thêm 5 PNG `mipmap-*` (nền teal + coin), không đổi kiến trúc. |
| 2 | Sửa `LaunchScreen.storyboard` bằng tay (thêm `UILabel` + đổi màu nền) — repo không có máy Mac để mở Interface Builder kiểm | Splash iOS hỏng/hiển thị sai | Giữ thay đổi tối thiểu (chỉ đổi `backgroundColor`, khai báo lại `image`, thêm 1 label + 1 constraint). QA trên thiết bị/Mac thật là bước bắt buộc (quickstart §3 ghi rõ). Nếu không kiểm được → hạ xuống chỉ đổi màu nền + logo, bỏ label. |
| 3 | Android 12 bó icon splash trong vùng ~240dp trong khi tầng Flutter đặt logo 140dp | "Nhảy hình" nhẹ giữa hai tầng (FR-010) | Chọn cùng cỡ 140dp cho cả hai tầng, `splash_logo` có lề trong suốt; QA mắt bước C trên máy Android 12+. |
| 4 | Icon Concept A hai màu ở cỡ nhỏ nhất có thể nhoè thành khối màu (SC-004) — rủi ro đã biết của quyết định chọn A cho icon | SC-004 | Sinh PNG icon ở đúng kích cỡ từng mục (không scale mờ), nét mũi tên/vòng trắng tính theo **tỉ lệ đường kính** (contracts §2) nên không biến mất ở cỡ nhỏ; QA mắt bước B ở mức thu nhỏ nhất trong launcher. |
| 5 | Ảnh hưởng test cũ: `test/pin_flow_test.dart` và `widget_test.dart` pump cả app, nay có thêm nhóm chờ + màn splash | Test đỏ dây chuyền | `load()` idempotent + fake store sẵn có trả về ngay ⇒ splash tự kết thúc trong `pumpAndSettle`; chạy `flutter test` toàn bộ ở task cuối. Nếu vướng timer treo, đã có sẵn cách xử lý ở R6 (huỷ timer). |
| 6 | Ảnh nền icon teal quanh coin bị đánh giá là "nền lạ" (SC-001) | Nghiệm thu thị giác | Ghi nhận là **trade-off đã cân nhắc** (R4): teal là màu thương hiệu, và phương án không nền sẽ lộ nền launcher. Đổi được bằng **một hằng số** trong generator + chạy lại, không đụng mã app. |
| 7 | Bản dịch/brand name: tên app trên splash hardcode (không dịch) | Không có | Cố ý (kế hoạch §Giai đoạn 1 mục 5) — là tên thương hiệu, khớp `GetMaterialApp.title`. |
