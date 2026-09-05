# GIẢI PHÁP CHI TIẾT: TIỆN ÍCH & CÁ NHÂN HÓA
### App Quản Lý Thu Chi (Flutter Mobile)

> Tài liệu này triển khai chi tiết mục **"12. Tiện ích & Cá nhân hóa"** trong tài liệu tính năng nghiệp vụ, dựa trên bộ Design System đã thống nhất (Material Design, teal `#0F6E56`, coral `#D85A30`). Bao gồm: kiến trúc dữ liệu, luồng xử lý, tác động lên các module khác, và mockup màn hình dạng SVG.

---

## 0. Phạm vi

| # | Hạng mục | Mức độ ưu tiên |
|---|---|---|
| 1 | Light/Dark mode | Cao — nền tảng UI |
| 2 | Đa ngôn ngữ (Việt/Anh) | Cao |
| 3 | Widget màn hình chính | Trung bình |
| 4 | Định dạng ngày, tiền tệ, đầu tuần, kỳ tài chính | Cao — ảnh hưởng Báo cáo & Ngân sách |
| 5 | Máy tính bỏ túi khi nhập số tiền | Cao — trải nghiệm nhập liệu cốt lõi |
| 6 | Tìm kiếm toàn cục | Trung bình |
| 7 | Tag tùy chỉnh | Trung bình |

Toàn bộ cài đặt nằm trong nhóm **Cài đặt > Tiện ích & Cá nhân hóa**, là sub-page dùng chung mẫu app bar teal + nút back theo Design System (mục 2.2, 2.3).

---

## 1. Giao diện Light / Dark / System

### 1.1. Mô hình dữ liệu
```dart
enum AppThemeMode { light, dark, system }

class AppSettings {
  AppThemeMode themeMode; // lưu tại local (GetStorage/Hive key: 'theme_mode')
}
```

### 1.2. Kỹ thuật triển khai
- Dùng `GetX` với `Get.changeThemeMode()` — áp dụng **ngay lập tức**, không cần khởi động lại app.
- Định nghĩa 2 bộ `ThemeData` (Light/Dark) kế thừa toàn bộ token màu ở mục 3 Design System:
  - **Light theme**: giữ nguyên bảng màu gốc (nền trắng `#FFFFFF`, chữ `#1A1A1A`).
  - **Dark theme**: nền `#121212`/`#1E1E1E`, card nền `#242420` (thay cho `#F1EFE8`), chữ chính `#F2F2F0`, chữ phụ `#A8A8A3`. **Giữ nguyên teal `#0F6E56`** làm màu thương hiệu (có thể sáng hơn nhẹ — `#3FA98A` — để đủ tương phản trên nền tối), coral `#D85A30` giữ nguyên hoặc tăng sáng `#E8734C`.
  - Đường kẻ phân cách tối: `#3A3A36`.
- Chế độ "Theo hệ thống": lắng nghe `WidgetsBindingObserver.didChangePlatformBrightness` để tự đổi theme khi hệ điều hành đổi (không cần mở lại app).

### 1.3. Lưu ý thiết kế
- Biểu đồ (`fl_chart`) cần override màu lưới/label riêng cho Dark mode để không bị "chìm" trên nền tối.
- Ảnh hóa đơn đính kèm và avatar không đổi theo theme.

**Màn hình:** `02-giao-dien.svg`

---

## 2. Đa ngôn ngữ (Việt / Anh)

### 2.1. Kỹ thuật triển khai
- Dùng cơ chế i18n tích hợp của `GetX` (`GetMaterialApp` + `translations`), file dịch dạng map `Map<String, Map<String, String>>` hoặc tách theo file `vi_VN.dart`, `en_US.dart`.
- Đổi ngôn ngữ bằng `Get.updateLocale()` — áp dụng ngay, không restart app.
- **Phạm vi dịch:** toàn bộ label giao diện tĩnh, tên **danh mục mặc định** (khi người dùng chưa đổi tên tùy chỉnh), thông báo push, insight tự động ("Bạn chi nhiều hơn tháng trước 15%").
- **Không dịch:** dữ liệu người dùng tự nhập (tên giao dịch, ghi chú, tag, tên ví tùy chỉnh).

### 2.2. Tác động cross-module
- Danh mục tùy chỉnh do người dùng tạo giữ nguyên tên gốc khi đổi ngôn ngữ.
- Định dạng ngày/số **không** tự đổi theo ngôn ngữ — tách biệt hoàn toàn với cài đặt ở mục 4 (một người có thể dùng English UI nhưng vẫn muốn định dạng ngày kiểu Việt Nam).

**Màn hình:** `03-ngon-ngu.svg`

---

## 3. Widget màn hình chính

### 3.1. Ràng buộc kỹ thuật (Flutter)
Flutter không tự có API tạo Home Screen Widget — cần dùng package cầu nối gốc:
- **Android**: `home_widget` (Flutter) + `AppWidgetProvider` (Kotlin) — cấu hình `RemoteViews`.
- **iOS**: `home_widget` kết hợp **WidgetKit** (Swift, iOS 14+) — bắt buộc phải viết thêm code native Swift cho Widget Extension, Flutter không thể tự render UI widget trên iOS.

### 3.2. Nội dung widget
| Thành phần | Nguồn dữ liệu |
|---|---|
| Tổng số dư tất cả ví | Tổng hợp từ module Ví (mục 2) |
| Chi tiêu hôm nay | Tổng giao dịch Chi trong ngày |
| Nút "+" mở nhanh màn Thêm giao dịch | Deep link (`app://add-transaction`) |

### 3.3. Cơ chế đồng bộ dữ liệu
1. Mỗi khi có giao dịch mới/sửa/xóa → gọi `HomeWidget.saveWidgetData()` để ghi số dư + chi tiêu hôm nay vào `SharedPreferences`/`UserDefaults` dùng chung giữa app và widget.
2. Gọi `HomeWidget.updateWidget()` để yêu cầu hệ điều hành vẽ lại widget ngay.
3. Tôn trọng cài đặt **"Ẩn số dư" (Privacy mode)**, mục 13 tài liệu nghiệp vụ — nếu bật, widget chỉ hiển thị `••••••• đ`.

### 3.4. Bật/tắt
- Toggle "Widget màn hình chính" trong màn hình danh sách Tiện ích chỉ mang tính **thông tin/nhắc nhở** (mở hướng dẫn cách ghim widget), vì việc thêm widget vào home screen do hệ điều hành quản lý, ứng dụng không thể tự động ghim.

*(Không có mockup SVG riêng do đây là thành phần UI của hệ điều hành, nằm ngoài phạm vi Flutter — xem hướng dẫn ghim widget được minh họa ở trạng thái toggle trong màn hình 01.)*

---

## 4. Định dạng ngày, tiền tệ, đầu tuần & kỳ tài chính

### 4.1. Mô hình dữ liệu
```dart
class LocaleSettings {
  String dateFormatPattern;   // 'dd/MM/yyyy' | 'MM/dd/yyyy' | 'yyyy-MM-dd'
  String currencyCode;        // 'VND', 'USD'...
  int weekStartDay;           // 1 = Thứ Hai, 7 = Chủ Nhật
  int financialPeriodStartDay; // 1–28, mặc định = 1
}
```

### 4.2. Định dạng ngày & tiền tệ
- Dùng package `intl`: `DateFormat(pattern, locale)` và `NumberFormat.currency()`.
- Tiền tệ áp dụng đúng quy tắc Design System (mục 4): phân cách nghìn bằng dấu chấm, đơn vị `đ` đặt sau đối với VND; với USD hiển thị `$` đặt trước theo chuẩn quốc tế.
- Đa tiền tệ theo ví (đã nêu ở mục 2 tài liệu nghiệp vụ) **độc lập** với "tiền tệ mặc định" — tiền tệ mặc định chỉ dùng khi tạo ví mới hoặc hiển thị tổng hợp toàn app.

### 4.3. Đầu tuần
- Ảnh hưởng: cách nhóm "tuần này/tuần trước" ở Báo cáo, và lịch chọn ngày (`DatePicker`) trong toàn app.

### 4.4. Kỳ tài chính tùy chỉnh (điểm phức tạp nhất)
- Cho phép chọn ngày bắt đầu kỳ (1–28) thay vì mặc định ngày 1.
- **Công thức xác định kỳ tài chính chứa ngày `d`:**
  - Nếu `d.day >= startDay` → kỳ tài chính = `[startDay tháng d, (startDay-1) tháng d+1)`
  - Nếu `d.day < startDay` → kỳ tài chính = `[startDay tháng d-1, (startDay-1) tháng d)`
- **Module bị ảnh hưởng trực tiếp:**
  - Báo cáo & Thống kê (mục 8): biểu đồ "theo tháng" phải nhóm theo kỳ tài chính, không phải theo tháng dương lịch.
  - Ngân sách theo tháng (mục 5): tiến độ ngân sách reset vào đúng `financialPeriodStartDay`, không phải ngày 1.
  - Thông báo tổng kết cuối tháng (mục 9): gửi vào ngày cuối kỳ tài chính, không phải ngày cuối tháng dương lịch.
- Giới hạn chọn tối đa **28** để tránh lỗi với tháng 2 (28/29 ngày).

**Màn hình:** `04-dinh-dang-tien-te.svg`

---

## 5. Máy tính bỏ túi tích hợp khi nhập số tiền

### 5.1. Luồng xử lý
1. Người dùng chạm ô "Số tiền" ở màn Thêm giao dịch → hệ thống **không** bật bàn phím hệ thống, thay vào đó hiện **bàn phím số tùy chỉnh** (custom keypad) với các phím: `0–9`, `.`, `+`, `−`, `×`, `÷`, xóa (backspace), và nút xác nhận biểu thức.
2. Người dùng có thể gõ liên tiếp biểu thức, ví dụ `500000 + 750000`.
3. Biểu thức hiển thị dạng chữ nhỏ phía trên (màu coral để phân biệt là "đang tính"), kết quả cuối cùng hiển thị lớn bên dưới, cập nhật realtime mỗi khi có phép toán hợp lệ.
4. Khi rời khỏi ô nhập hoặc bấm "Lưu giao dịch", biểu thức được **rút gọn thành giá trị cuối cùng** trước khi lưu vào CSDL (trường `amount` trong bảng Transaction luôn là số, không lưu biểu thức).

### 5.2. Kỹ thuật triển khai
- Custom `Widget` bàn phím (không dùng `TextInputType.number` mặc định) để kiểm soát hoàn toàn layout theo Design System (numpad tròn, viền `#E0E0E0`, mục 2.4).
- Dùng package tính biểu thức an toàn (ví dụ `math_expressions` hoặc tự viết parser rút gọn) để tránh injection và xử lý độ ưu tiên phép toán (`×÷` trước `+−`).
- Giới hạn: tối đa 1 dấu `.` trong mỗi số hạng; số âm không hợp lệ cho số tiền (chặn nhập `−` ở đầu biểu thức).
- Bật/tắt tính năng này qua toggle "Máy tính khi nhập số tiền" (mục 12 tài liệu nghiệp vụ) — nếu tắt, quay lại numpad nhập số thuần (không phép toán), phù hợp người dùng muốn nhập nhanh, gọn.

**Màn hình:** `05-may-tinh-nhap-tien.svg`

---

## 6. Tìm kiếm toàn cục

### 6.1. Phạm vi tìm kiếm
| Nguồn | Trường tìm |
|---|---|
| Giao dịch | Ghi chú, tag, số tiền (khớp gần đúng), tên danh mục |
| Danh mục | Tên danh mục, danh mục con |
| Ví | Tên ví |

### 6.2. Kỹ thuật triển khai
- Query trực tiếp trên `drift` (SQL) với `LIKE` full-text đơn giản cho MVP; có thể nâng cấp FTS5 (SQLite full-text search) nếu dữ liệu lớn.
- **Debounce 300ms** sau khi người dùng ngừng gõ mới truy vấn, tránh query liên tục.
- Lưu tối đa 5 **tìm kiếm gần đây** (local, không đồng bộ), hiển thị dạng chip có thể chạm lại.
- Kết quả nhóm theo loại (Giao dịch / Danh mục / Ví), mỗi nhóm hiển thị tối đa 5 kết quả kèm số lượng, chạm "Xem thêm" để vào danh sách đầy đủ có filter sẵn.
- Hỗ trợ tìm theo cú pháp `#tag` để lọc nhanh theo tag ngay trong ô tìm kiếm.

**Màn hình:** `06-tim-kiem-toan-cuc.svg`

---

## 7. Tag tùy chỉnh cho giao dịch

### 7.1. Mô hình dữ liệu
```dart
class Tag {
  String id;
  String name;   // ví dụ: "dulich" (không chứa dấu #, tự thêm khi hiển thị)
  String colorHex; // màu chip, mặc định random trong palette phụ trợ
}

// Quan hệ nhiều-nhiều
class TransactionTag {
  String transactionId;
  String tagId;
}
```

### 7.2. Luồng tạo & gán tag
- Khi nhập ghi chú giao dịch, gõ `#` sẽ kích hoạt **gợi ý autocomplete** danh sách tag đã có; nếu gõ tag chưa tồn tại và xác nhận, hệ thống tự tạo tag mới.
- Một giao dịch có thể gán **nhiều tag** cùng lúc (khác với Danh mục — chỉ 1 danh mục/giao dịch), cho phép lọc chéo danh mục (ví dụ giao dịch "Ăn uống" gắn tag `#dulich` vẫn được tính vào báo cáo chuyến du lịch).

### 7.3. Màn hình Quản lý Tag
- Liệt kê toàn bộ tag kèm số lượng giao dịch đang gắn.
- Chạm vào 1 tag → điều hướng sang danh sách giao dịch đã lọc sẵn theo tag đó.
- Cho phép đổi tên tag (áp dụng cho toàn bộ giao dịch đã gắn), đổi màu chip, hoặc xóa tag (chỉ gỡ liên kết, **không xóa giao dịch**).
- Nút "+" (FAB) để tạo tag mới thủ công.

**Màn hình:** `07-quan-ly-tag.svg`

---

## 8. Danh sách màn hình thiết kế (SVG)

| File | Mô tả |
|---|---|
| `mockups/01-danh-sach-tien-ich.svg` | Màn hình gốc "Tiện ích & Cá nhân hóa" trong Cài đặt — điểm vào tất cả mục con |
| `mockups/02-giao-dien.svg` | Chọn giao diện Sáng / Tối / Theo hệ thống |
| `mockups/03-ngon-ngu.svg` | Chọn ngôn ngữ Tiếng Việt / English |
| `mockups/04-dinh-dang-tien-te.svg` | Định dạng ngày, đơn vị tiền tệ, đầu tuần, kỳ tài chính |
| `mockups/05-may-tinh-nhap-tien.svg` | Nhập số tiền có máy tính bỏ túi tích hợp (màn Thêm giao dịch) |
| `mockups/06-tim-kiem-toan-cuc.svg` | Tìm kiếm toàn cục (giao dịch/danh mục/ví) |
| `mockups/07-quan-ly-tag.svg` | Quản lý Tag — danh sách, số giao dịch theo tag |

### 8.1. Xem trước

**Danh sách Tiện ích & Cá nhân hóa**
![Danh sách Tiện ích](mockups/01-danh-sach-tien-ich.svg)

**Giao diện Sáng/Tối/Hệ thống**
![Giao diện](mockups/02-giao-dien.svg)

**Ngôn ngữ**
![Ngôn ngữ](mockups/03-ngon-ngu.svg)

**Định dạng & Tiền tệ**
![Định dạng & Tiền tệ](mockups/04-dinh-dang-tien-te.svg)

**Máy tính khi nhập số tiền**
![Máy tính nhập tiền](mockups/05-may-tinh-nhap-tien.svg)

**Tìm kiếm toàn cục**
![Tìm kiếm toàn cục](mockups/06-tim-kiem-toan-cuc.svg)

**Quản lý Tag**
![Quản lý Tag](mockups/07-quan-ly-tag.svg)

---

## 9. Bảng tổng hợp Package Flutter cần dùng

| Nhu cầu | Package |
|---|---|
| Đổi theme runtime | `get` (GetX built-in) |
| Đa ngôn ngữ | `get` (GetX translations) hoặc `flutter_localizations` + `intl` |
| Widget màn hình chính | `home_widget` (+ code native Kotlin/Swift) |
| Định dạng ngày/tiền tệ | `intl` |
| Biểu thức máy tính | `math_expressions` |
| Tìm kiếm | `drift` (SQL `LIKE`/FTS5) |
| Lưu cài đặt cá nhân hóa | `get_storage` hoặc `flutter_secure_storage` (đã dùng sẵn cho PIN) |

---

## 10. Thứ tự triển khai đề xuất

1. **Định dạng & Tiền tệ** trước (vì Báo cáo/Ngân sách phụ thuộc kỳ tài chính ngay từ đầu, đổi sau sẽ phải migrate dữ liệu).
2. **Light/Dark mode** + **Đa ngôn ngữ** (nền tảng UI, nên làm sớm để mọi màn hình mới đều tuân thủ).
3. **Máy tính bỏ túi khi nhập số tiền** (cải thiện trải nghiệm nhập liệu cốt lõi).
4. **Tag tùy chỉnh** (phục vụ Tìm kiếm và Báo cáo lọc chéo).
5. **Tìm kiếm toàn cục** (cần dữ liệu tag đã có để tìm theo `#tag`).
6. **Widget màn hình chính** (làm sau cùng vì cần code native riêng cho từng nền tảng, độ ưu tiên trung bình).
