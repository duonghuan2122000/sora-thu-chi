# Hợp đồng asset nhận diện — PBI 25

**Mã PBI**: 25
**Liên kết**: `.specify/specs/25/spec.md`, `.specify/specs/25/research.md` (R2–R4, R9)

Đây là "giao diện" giữa **script sinh asset** (`app/sora_thu_chi/tool/gen_brand_assets.dart`) và **hai nền tảng + app Flutter**. Task thi công và test phải khớp đúng bảng này; đổi tên/đường dẫn/kích thước ở đây thì phải sửa cả script lẫn test.

## 1. Nguồn chân lý

| Vai trò | Đường dẫn |
|---|---|
| Nguồn hình học **duy nhất** (sinh ra mọi asset) | `app/sora_thu_chi/tool/gen_brand_assets.dart` |
| Tham chiếu thiết kế (không đưa vào app, còn dòng chú thích concept) | `docs/logo/logo-concept-a-coin-flow.svg` |
| Lệnh sinh lại toàn bộ | `dart run tool/gen_brand_assets.dart` (chạy trong `app/sora_thu_chi/`) |

Script phải **ghi đè đúng tên file** đã có ⇒ không phải sửa `Contents.json`/`AndroidManifest.xml` cho phần asset.

## 2. Hằng số bắt buộc

| Tên | Giá trị | Ghi chú |
|---|---|---|
| `brandTeal` | `#0F6E56` | nền splash, nửa Thu, nền icon |
| `brandCoral` | `#D85A30` | nửa Chi |
| `brandWhite` | `#FFFFFF` | mũi tên, đường phân tách, vòng viền |
| Đường kính coin / cạnh icon | `0.68` | nằm trong vùng an toàn của adaptive icon |
| Coin / cạnh khung splash logo | `0.88` | lề 6% mỗi cạnh |
| Dày đường phân tách | `0.021 × D` | D = đường kính coin |
| Dày mũi tên | `0.05 × D` | |
| Dày vòng viền trắng | `0.03 × D` | phần thêm của PBI 25 (R3) |

Không gradient, không đổ bóng, không alpha từng phần (FR-008).

## 3. Asset Android

| File | Nội dung | Ghi chú |
|---|---|---|
| `android/app/src/main/res/drawable/ic_launcher_foreground.xml` | VectorDrawable 108×108: coin 2 nửa + đường phân tách + 2 mũi tên + vòng trắng | sinh bởi script |
| `android/app/src/main/res/values/ic_launcher_background.xml` | `<color name="ic_launcher_background">#FF0F6E56</color>` | sinh bởi script |
| `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` | `<adaptive-icon>` trỏ foreground + background trên | sinh bởi script |
| `android/app/src/main/res/drawable/splash_logo.xml` | VectorDrawable coin + vòng trắng, viewport 144×144, coin `0.88` khung | sinh bởi script — dùng cho `launch_background` (API < 31) |
| `android/app/src/main/res/drawable/splash_logo_masked.xml` | như trên nhưng coin `0.44` khung | sinh bởi script — dùng cho `windowSplashScreenAnimatedIcon` (xem §7) |
| `android/app/src/main/res/values/colors.xml` | `brand_teal = #FF0F6E56` | dùng cho `windowSplashScreenBackground` |
| `android/app/src/main/res/drawable/launch_background.xml` | `layer-list`: teal + `splash_logo` căn giữa `140dp` | sửa tay |
| `android/app/src/main/res/drawable-v21/launch_background.xml` | như trên (đang là `?android:colorBackground`) | sửa tay |
| `android/app/src/main/res/values-v31/styles.xml` | `LaunchTheme`: `windowSplashScreenBackground` + `windowSplashScreenAnimatedIcon` (`@drawable/splash_logo_masked`) + `windowSplashScreenIconBackgroundColor` | tạo mới. **Không** có `postSplashScreenTheme` (thuộc `androidx.core:core-splashscreen` — PBI không thêm dependency; vai trò đó do meta-data `NormalTheme` trong manifest đảm nhiệm) |
| `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` | **XOÁ** | minSdk 26 ⇒ adaptive icon là đường duy nhất (R1) |

`AndroidManifest.xml`: giữ `android:icon="@mipmap/ic_launcher"` và `android:label="Sora Thu Chi"` (**đã đúng**, FR-003 — chỉ xác nhận, không sửa).

## 4. Asset iOS

| File | Kích thước | Nội dung |
|---|---|---|
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-{20,29,40,60,76,83.5}*` | đúng 15 mục trong `Contents.json` | **đục**, nền teal, coin + vòng trắng 68% |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,@2x,@3x}.png` | 120 / 240 / 360 px | trong suốt, coin + vòng trắng 88% khung |
| `ios/Runner/Base.lproj/LaunchScreen.storyboard` | — | `backgroundColor` → teal `#0F6E56`; `imageView` giữ `contentMode="center"`, khai báo `<image name="LaunchImage" width="120" height="120"/>`; thêm `UILabel` "Sora Thu Chi" trắng, đậm, canh giữa dưới logo |

`Info.plist`: `CFBundleDisplayName = "Sora Thu Chi"` (**đã đúng** — chỉ xác nhận).

## 5. Asset Flutter

| File | Nội dung |
|---|---|
| `app/sora_thu_chi/assets/brand/coin_flow_logo.png` | 1024 px, nền trong suốt, coin + vòng trắng 88% khung |
| `pubspec.yaml` | thêm khối `flutter: assets: - assets/brand/` |

Màn splash dùng: `AppColors.teal` (nền), `assets/brand/coin_flow_logo.png` (rộng `140dp`), `Text('Sora Thu Chi')` màu trắng — **không** dùng `SoraColors.of(context)` cho nền (nền splash bắt buộc giống nhau ở Sáng/Tối, FR-004/FR-008).

## 6. Bất biến kiểm được bằng máy (test)

1. Mọi file ở mục 3–5 **tồn tại** sau khi chạy generator.
2. `mipmap-*/ic_launcher.png` (bản mặc định của `flutter create`) **không còn**.
3. `Icon-App-1024x1024@1x.png`: mọi pixel có alpha `255` (đục — yêu cầu của iOS).
4. `coin_flow_logo.png`: có pixel alpha `0` ở 4 góc (nền trong suốt, không khung trắng) và có đủ 3 màu `#0F6E56`, `#D85A30`, `#FFFFFF`.
5. `ic_launcher_foreground.xml` chứa đủ 3 mã màu; `mipmap-anydpi-v26/ic_launcher.xml` chứa `adaptive-icon`.
6. `launch_background.xml` + `values-v31/styles.xml` + storyboard đều mang `#0F6E56` (không còn `white`/`colorBackground`).
7. Không file asset nào chứa chuỗi chú thích concept (`"Concept A"`, `"Coin Flow"`, `"Thu (teal)"`) — FR-011.

## 7. Ghi chú thi công: giới hạn của Android 12+ (phát hiện khi QA trên emulator)

Hai lỗi chỉ lộ ra khi **chạy thật** (không test nào bắt được):

1. **`VectorDrawable` bỏ qua path đường tròn viết dạng rút gọn** `M cx-r,cy a r,r 0 1 0 2r,0 a r,r 0 1 0 -2r,0 Z` — path ra **rỗng**, nên cả nửa teal lẫn vòng viền trắng biến mất khỏi vector (trên nền teal, nửa teal chìm hẳn ⇒ splash trông như "nửa hình tròn bị khuyết" — đúng thứ FR-016/SC-008 cấm). Cách viết **chạy được**: hai cung bán nguyệt tuyệt đối `M cx-r,cy A r,r 0 0 1 cx+r,cy A r,r 0 0 1 cx-r,cy Z`. Phần raster (PNG) **không** bị ảnh hưởng.
2. **`windowSplashScreenAnimatedIcon` bị hệ thống scale lên rồi cắt theo đường tròn** (~277dp rộng, mask ~192dp trên emulator 420dpi). Nội dung ở `0.88` khung (đường kính ngoài ~244dp) vượt mask ⇒ mất vòng viền trắng **và** logo to hơn hẳn tầng Flutter (nhảy hình, FR-010). Vì vậy dùng riêng `splash_logo_masked.xml` với coin `0.44` khung → coin hiện ra **122,7dp**, khớp tầng Flutter (`0.88 × 140dp = 123,2dp`).
   - `launch_background.xml` (đường API < 31) **không** bị mask ⇒ vẫn dùng `splash_logo.xml` ở `0.88` và đặt `140dp` trong `layer-list`.

Đổi tỉ lệ về sau: sửa `coinRatioSplashNative` trong `tool/gen_brand_assets.dart` rồi chạy lại generator — coin hiện ra ≈ `coinRatioSplashNative × 277dp`.
