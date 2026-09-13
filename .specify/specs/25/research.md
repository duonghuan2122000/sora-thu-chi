# Nghiên cứu kỹ thuật (Giai đoạn 0) — PBI 25: Logo ứng dụng & màn hình Splash

**Mã PBI**: 25
**Liên kết spec**: `.specify/specs/25/spec.md`
**Ngày tạo**: 2026-09-13

Mọi mục `NEEDS CLARIFICATION` trong Ngữ cảnh kỹ thuật (xem `plan.md`) đã được giải quyết dưới đây.

---

## R1 — Cách dựng icon launcher trên Android

**Quyết định**: Dùng **adaptive icon** (`mipmap-anydpi-v26/ic_launcher.xml` + `ic_launcher_foreground` là **VectorDrawable** + background là **color resource**), **xoá 5 file `mipmap-*/ic_launcher.png`** do `flutter create` sinh ra.

**Lý do**:
- `android/app/build.gradle.kts` đã đặt `minSdk = maxOf(flutter.minSdkVersion, 26)` (yêu cầu của ML Kit GenAI, PBI 24) ⇒ **mọi máy app hỗ trợ đều đọc được `anydpi-v26`**, không cần bộ PNG legacy cho API < 26.
- Vector nét sắc ở **mọi mật độ** (FR-002, FR-009) mà không phải sinh 5–6 bộ PNG theo density.
- Nếu giữ lại PNG mặc định thì icon cũ vẫn còn trong APK ⇒ vi phạm SC-001.

**Phương án khác đã xem xét**:
- *Sinh PNG cho 5 density (`mipmap-mdpi`…`xxxhdpi`)*: nhiều file, mờ khi launcher phóng to, và vẫn phải có nhánh vector cho adaptive icon ⇒ thừa.
- *Thêm dev dependency `flutter_launcher_icons`*: vẫn **không giải quyết** vấn đề gốc (chưa có ảnh PNG nguồn 1024×1024), lại thêm 1 gói cho việc chỉ vài file XML nắm đúng đường dẫn.

**Rủi ro còn lại**: `aapt2` có thể cảnh báo "resource has no default config" khi `@mipmap/ic_launcher` chỉ có cấu hình `anydpi-v26`. Nếu build đỏ → phương án lùi: cho generator xuất thêm `mipmap-mdpi…xxxhdpi/ic_launcher.png` (cùng nền teal + coin), không đổi kiến trúc.

---

## R2 — Nguồn ảnh nhận diện (không có file PNG thiết kế sẵn)

**Quyết định**: Viết **một script Dart** `app/sora_thu_chi/tool/gen_brand_assets.dart` chạy bằng `dart run`, dùng package **`image` đã có sẵn** (`image: ^4.9.2`, pure Dart, không cần Flutter engine), vẽ lại Concept A từ hằng số hình học và **sinh toàn bộ asset** cho cả hai nền tảng:
- Android: `drawable/ic_launcher_foreground.xml` (VectorDrawable), `mipmap-anydpi-v26/ic_launcher.xml`, `drawable/splash_logo.xml`, `values/ic_launcher_background.xml`, `values/colors.xml` (brand teal).
- iOS: 15 PNG trong `AppIcon.appiconset` (ghi đè **đúng tên file cũ** ⇒ không phải sửa `Contents.json`) + 3 PNG `LaunchImage{,@2x,@3x}.png`.
- Flutter: `assets/brand/coin_flow_logo.png` (1024 px, nền trong suốt) cho màn splash.

**Lý do**:
- Repo chỉ có **SVG concept** (`docs/logo/`), không có PNG sản xuất; SVG lại chứa cả dòng chú thích concept (FR-011) và không dùng được cho launcher icon (OS cần raster).
- `image` là dependency **đã có** ⇒ 0 gói mới, chạy offline, kết quả **tái lập được** (deterministic), commit được cả script lẫn asset.
- Script là **một nguồn hình học duy nhất**: Android (vector) và iOS (raster) sinh từ cùng bộ số ⇒ không lệch hình giữa hai nền tảng.

**Phương án khác đã xem xét**:
- *Thêm `flutter_launcher_icons` + `flutter_native_splash`*: 2 gói mới, và **vẫn cần** script vẽ PNG nguồn ⇒ tổng thể nhiều máy móc hơn, không ít hơn. (PBI 19 cũng đã chọn hướng "không thêm gói bên thứ ba" cho việc SDK Flutter làm được.)
- *Gọi công cụ ngoài (Inkscape / ImageMagick / rsvg-convert)*: không đảm bảo có trên máy dev & CI, không tái lập.
- *`flutter_svg` render SVG lúc chạy cho splash*: thêm gói chỉ để vẽ splash, mà launcher icon vẫn phải raster ⇒ không giải quyết phần khó.
- *CustomPainter cho splash (khỏi cần asset)*: hình học bị **lặp ở 2 nơi** (painter + generator) ⇒ dễ trôi lệch; 1 file PNG + 2 dòng `pubspec` rẻ hơn.

---

## R3 — Biến thể logo đưa vào sản phẩm: Concept A + **vòng viền trắng**

**Quyết định**: Logo sản xuất = Concept A **giữ nguyên hình học** (đồng xu chia đôi: nửa trên teal `#0F6E56` + mũi tên lên, nửa dưới coral `#D85A30` + mũi tên xuống, đường phân tách trắng) **cộng thêm một vòng viền trắng mảnh** bao quanh đồng xu.

**Lý do**:
- FR-016 yêu cầu nửa teal **không chìm vào nền teal** của splash ⇒ cần nét trắng phân tách khỏi nền, và đường phân tách ngang (đã có trong concept) **không đủ** vì nó chỉ tách hai nửa, không tách coin khỏi nền.
- Cùng một biến thể dùng luôn cho **icon launcher có nền teal** (R4) ⇒ chỉ một hình, một quy tắc, không cần bộ asset riêng theo ngữ cảnh.
- Giữ đúng tinh thần Material phẳng: nét đặc, không gradient/đổ bóng (FR-008).

**Phương án khác đã xem xét**:
- *Giữ nguyên concept, nền splash sáng (trắng)*: vi phạm FR-004 (nền teal thương hiệu đặc).
- *Đổi nửa trên sang màu teal nhạt hơn trên splash*: lệch bảng màu đã chốt (FR-008), và icon launcher lại phải khác ⇒ hai biến thể.
- *Bỏ nền teal ở icon launcher, để coin trên nền trong suốt*: xem R4.

---

## R4 — Nền của icon launcher

**Quyết định**: Nền **teal đặc `#0F6E56`** cho icon: Android = `ic_launcher_background` (color resource) của adaptive icon; iOS = PNG **đục** (không alpha) nền teal, coin nằm trong vùng an toàn (~68% cạnh icon).

**Lý do**:
- iOS **không chấp nhận** PNG icon có kênh trong suốt ⇒ buộc phải có nền đục.
- Android mask (tròn / vuông bo góc / mềm) cắt phần ngoài vùng an toàn: nếu để coin full-bleed, mask bo góc sẽ **cắt mất mép coin** và góc lộ **nền của launcher** (đúng thứ SC-001 cấm: "không có viền/nền lạ bao quanh").
- Nền teal là **màu thương hiệu** ⇒ không phải "nền lạ", và giữ được tương phản nhờ vòng trắng (R3).

**Phương án khác đã xem xét**:
- *Nền trắng*: lệch nhận diện (splash teal, icon trắng), và đường phân tách trắng mất tác dụng trên nền trắng.
- *Nền trong suốt + coin full-bleed*: góc lộ nền launcher trên mask bo góc; coin bị cắt mép.

**Trade-off ghi nhận**: coin nhỏ hơn icon ~1/3 (vùng an toàn) ⇒ có viền teal quanh coin. Chấp nhận; nếu QA mắt thấy khó ưu → đổi **một hằng số nền + chạy lại generator**, không đụng mã app.

---

## R5 — Hai tầng splash (native + Flutter)

**Quyết định**: Làm **cả hai tầng**, cùng nền teal và cùng cỡ logo:

| Tầng | Android | iOS |
|---|---|---|
| Native (trước frame Flutter đầu tiên) | `drawable/launch_background.xml` (+ `drawable-v21`) = teal + `splash_logo` căn giữa; **Android 12+**: `values-v31/styles.xml` với `windowSplashScreenBackground` / `windowSplashScreenAnimatedIcon` / `postSplashScreenTheme` | `LaunchScreen.storyboard`: nền teal + `LaunchImage` (coin) căn giữa + nhãn "Sora Thu Chi" trắng |
| Flutter (từ frame đầu tới khi app sẵn sàng) | `PinGate` (đang là `home`) render splash: nền teal + logo + tên app | như Android (dùng chung mã Dart) |

**Lý do**: FR-010 cấm "khung nền trống kéo dài" và "nhảy hình"; FR-015 đòi logo xuất hiện ≤ 1 giây. Chỉ có tầng Flutter thì trong lúc engine khởi động người dùng vẫn thấy `windowBackground` mặc định (trắng/đen) ⇒ vi phạm.

**Phương án khác đã xem xét**:
- *Chỉ tầng Flutter*: vi phạm FR-010 (khung trắng) và FR-015 trên máy yếu.
- *Thêm gói `flutter_native_splash`*: vẫn phải tự cấu hình `values-v31` + storyboard cho đúng, mà sinh asset bằng công cụ ngoài (xem R2).

**Rủi ro ghi nhận**: Android 12 bó icon splash trong vùng ~240dp (nội dung nên nằm trong đường tròn 160dp) còn tầng Flutter đặt logo ~140dp ⇒ sai khác cỡ nhỏ khi chuyển tầng. Xử lý: chọn cỡ logo **hai tầng bằng nhau** (140dp) và để `splash_logo` có lề trong suốt; QA mắt kiểm "không nhảy hình" trên máy Android 12+.

---

## R6 — Điểm kết thúc splash & trần 5 giây

**Quyết định**: Ở `PinGate._bootstrap` (đang là màn boot), chờ **song song** `PinController.init()` + `ThemeController.load()` + `LocaleController.load()`, **có trần 5 giây** bằng `Timer` **huỷ được**:

```dart
final done = Completer<void>();
final timer = Timer(cap, () { if (!done.isCompleted) done.complete(); });
Future.wait([...]).whenComplete(() {
  timer.cancel();                       // không để timer treo trong test widget
  if (!done.isCompleted) done.complete();
});
await done.future;
```

**Lý do**:
- FR-006 (tự kết thúc, muộn nhất 5 giây) + FR-013 (ngôn ngữ & giao diện phải áp **trước** khi màn kế tiếp hiện). Hiện `ThemeController.load()`/`LocaleController.load()` được gọi **fire-and-forget** trong `SoraApp.initState` ⇒ phải đưa vào nhóm chờ.
- `Timer` **phải `cancel()`** khi việc nạp xong: dùng `Future.any([work, Future.delayed(5s)])` sẽ để lại timer treo ⇒ `flutter test` báo *"A Timer is still pending"*.
- `load()` của cả hai controller là **idempotent** (đọc store rồi gán `Rx`) ⇒ an toàn khi bỏ lời gọi fire-and-forget ở `app.dart` và chuyển sang nhóm chờ.

**Phương án khác đã xem xét**:
- *Delay cứng 1–2 giây*: vi phạm giả định "splash không cố tình giữ người dùng thêm".
- *`Future.any` + `Future.delayed`*: rò timer trong test (đã nêu trên).
- *Chờ luôn `ensureScanController().load()`*: đọc hồ sơ thiết bị (`device_info_plus`) có thể chậm, không thuộc FR-013 ⇒ giữ fire-and-forget như hiện tại (R8).

---

## R7 — Không đụng dữ liệu / drift

**Quyết định**: **Không** thêm bảng, cột, migration nào. Schema drift giữ **v8**.

**Lý do**: PBI thuần trình bày (spec §Mô tả tổng quan). Không có thực thể nghiệp vụ mới ⇒ không có `data-model.md` cho PBI này.

---

## R8 — Việc nạp không đưa vào nhóm chờ splash

**Quyết định**: `ensureScanController().load()` (PBI 24) tiếp tục fire-and-forget ở `SoraApp.initState`.

**Lý do**: FR-013 chỉ ràng buộc **ngôn ngữ** và **giao diện**; đưa thêm việc đọc hồ sơ thiết bị vào nhóm chờ làm splash lâu hơn trên máy yếu mà không đổi trải nghiệm (sheet quét hóa đơn chỉ mở khi người dùng bấm FAB).

---

## R9 — Hợp đồng asset (kích thước & màu)

Chi tiết bảng file ở `contracts/brand-assets.md`. Tóm tắt hằng số hình học dùng chung:

- Bảng màu: teal `#0F6E56`, coral `#D85A30`, trắng `#FFFFFF`. **Không** gradient/đổ bóng/alpha một phần (FR-008).
- Tỉ lệ hình học (theo viewBox gốc `docs/logo/logo-concept-a-coin-flow.svg`, coin `r=70` trên `viewBox 400`): đường phân tách dày ~2,1% đường kính; mũi tên dày ~5% đường kính; vòng viền trắng thêm mới dày ~3% đường kính.
- Splash logo: PNG 1024 px, nền trong suốt, coin chiếm 88% khung (lề 6% mỗi cạnh để không bị cắt khi bo/scale).
- Icon iOS: PNG **đục** nền teal, coin + vòng trắng chiếm ~68% cạnh.
- LaunchImage (iOS) 1x/2x/3x = 120/240/360 px, nền trong suốt (storyboard đặt trên nền teal).
- `splash_logo.xml` (Android vector): viewport 144×144, đặt trong `layer-list` với `android:width/height="140dp"`.

---

## R10 — Kiểm thử

**Quyết định**: Hai file test **không cần emulator/thiết bị**:
1. `test/splash_screen_test.dart` — widget test: splash là màn đầu; nền teal + logo + tên app trắng; không có app bar/bottom nav/nút; giống nhau ở cả Sáng và Tối; tự biến mất (không cần chạm) → màn khóa nếu có PIN / Tổng quan nếu không; trần 5 giây khi store không bao giờ xong; không hiện lại khi resume; không tràn khi `textScaler` lớn.
2. `test/brand_assets_test.dart` — đọc file asset bằng chính package `image` để khẳng định: PNG icon iOS 1024 là **đục** (alpha = 255 toàn ảnh); PNG splash có pixel trong suốt ở góc + có đủ 3 màu teal/coral/trắng; `ic_launcher.xml` là `adaptive-icon` và `ic_launcher_foreground.xml` chứa đủ 3 mã màu; không còn file `mipmap-*/ic_launcher.png` cũ.

**Lý do**: SC-004/SC-006/SC-007 là tiêu chí **thị giác** ⇒ phần máy kiểm được chỉ là "asset đúng và tồn tại"; phần mắt người để QA emulator/thiết bị thật (xem `quickstart.md`). Không dựng test so khớp ảnh (golden) — giòn, dễ đỏ vì khác phiên bản rasterizer.

**Phương án khác**: golden test ảnh splash (bỏ: giòn); test tích hợp trên emulator (để QA tay như các PBI trước).
