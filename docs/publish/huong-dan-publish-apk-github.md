# Hướng dẫn Publish APK qua GitHub Releases

Phân phối app Android dưới dạng file APK thông qua GitHub Releases — không cần qua Google Play, **hoàn toàn miễn phí**, phù hợp cho app cá nhân, thử nghiệm, hoặc chia sẻ nội bộ/bạn bè.

---

## Bước 1: Build file APK release

```bash
flutter build apk --release
```

Hoặc để có file nhỏ hơn, tách riêng theo từng kiến trúc CPU:

```bash
flutter build apk --release --split-per-abi
```

- File APK sau khi build nằm ở:
  ```
  build/app/outputs/flutter-apk/app-release.apk
  ```
- ⚠️ **Lưu ý quan trọng**: cần cấu hình **signing key (keystore)** trước khi build release. Nếu không, APK sẽ dùng debug key mặc định, và một số thiết bị Android có thể chặn cài đặt vì lý do bảo mật.

### Cấu hình signing key (nếu chưa có)

1. Tạo keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Tạo file `android/key.properties`:
   ```
   storePassword=<mật khẩu keystore>
   keyPassword=<mật khẩu key>
   keyAlias=upload
   storeFile=<đường dẫn tới file .jks>
   ```
3. Cấu hình `android/app/build.gradle` để đọc `key.properties` và dùng cho signing config `release`.

---

## Bước 2: Tạo Release trên GitHub

1. Vào repo trên GitHub → tab **Releases** → **"Draft a new release"**
2. Đặt **tag version**, ví dụ: `v1.0.0`
3. Viết **tiêu đề** và **changelog** — mô tả những gì mới/sửa trong bản này

---

## Bước 3: Upload file APK vào Release

- Kéo thả file `.apk` vào phần **"Attach binaries"** của release
- GitHub cho phép file tới 2GB (APK thường chỉ vài chục MB nên thoải mái)
- Sau khi bấm **Publish release**, sẽ có link tải trực tiếp dạng:
  ```
  https://github.com/<user>/<repo>/releases/download/v1.0.0/app-release.apk
  ```

---

## Bước 4: Chia sẻ link cho người dùng

- Gửi link Release (trang release đầy đủ) hoặc link tải trực tiếp file APK
- Có thể tạo thêm **QR code** trỏ tới link tải để tiện quét bằng điện thoại

---

## Bước 5: Hướng dẫn người dùng cài đặt

Vì không phân phối qua Play Store, Android sẽ **chặn cài đặt mặc định**. Người dùng cần:

1. Vào **Settings → Bảo mật (Security)** → bật **"Install unknown apps"** (Cho phép cài đặt ứng dụng từ nguồn không xác định) cho trình duyệt hoặc file manager dùng để tải file
2. Mở file APK vừa tải để tiến hành cài đặt
3. Nếu xuất hiện cảnh báo "Ứng dụng có thể gây hại" (thường gặp trên Xiaomi/MIUI, Samsung), người dùng cần chọn **"Cài đặt dù sao"** hoặc tắt tạm Google Play Protect

---

## Bước 6 (Tùy chọn): Tự động hoá bằng GitHub Actions

Thiết lập workflow CI/CD để tự động build APK và tạo Release mỗi khi push tag mới, tránh phải build tay mỗi lần:

```yaml
# .github/workflows/release.yml
name: Build and Release APK

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: softprops/action-gh-release@v2
        with:
          files: build/app/outputs/flutter-apk/app-release.apk
```

Sau khi có workflow này, chỉ cần:

```bash
git tag v1.0.1
git push --tags
```

→ GitHub Actions sẽ tự build và tạo release kèm APK.

---

## Ưu điểm

- Hoàn toàn miễn phí, không tốn phí $25 như Google Play
- Không cần qua quy trình review/closed testing 14 ngày của Google
- Publish và update ngay lập tức, chủ động 100%

## Nhược điểm cần lưu ý

- Người dùng phải tự bật "Install unknown apps" — gây bất tiện, một số người ngại vì lo bảo mật
- Không có auto-update như Play Store (trừ khi tự code tính năng check version mới và tải về trong app)
- Không tiếp cận được người dùng qua tìm kiếm — chỉ ai có link mới cài được
- Một số dòng máy (Xiaomi/MIUI, Samsung) có cảnh báo "ứng dụng độc hại" mặc định với APK cài ngoài Play Store

---

## Tổng kết

GitHub Releases là lựa chọn phù hợp cho giai đoạn **dùng thử nội bộ**, **chia sẻ với bạn bè**, hoặc **beta test** trước khi (nếu cần) đẩy app lên Google Play Store chính thức.
