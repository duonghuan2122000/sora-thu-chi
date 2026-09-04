# Danh sách Task: Màn hình Cài đặt (trung tâm cài đặt)

**Mã PBI**: 4
**Nguồn**: plan.md, spec.md, data-model.md, research.md, quickstart.md

> spec.md **không** gán mức ưu tiên P1/P2/P3 cho kịch bản — đây là một màn hiển thị đơn khối, không có story nào tách rời giao được trước. Toàn bộ yêu cầu thuộc **một User Story duy nhất** = US1 "Màn trung tâm Cài đặt (chỉ hiển thị)" (P1, MVP) — đóng FR-001..011 + SC-001..006. Khối hồ sơ (`DeviceProfile`) và token màu là **leaf nền** không phụ thuộc widget nào → để Pha 2 Foundational chạy song song; màn chỉ lắp ráp sau.

## Pha 1: Setup

- [X] T001 Xác minh baseline trong `app/sora_thu_chi/`: chạy `flutter pub get` rồi `flutter analyze` → sạch; xác nhận hiện trạng trước khi sửa: `lib/theme/app_colors.dart` có 9 token (teal, white, tealLightText, tabInactive, divider, textPrimary, textSecondary, dotEmpty, coral), `lib/core/widgets/screen_header.dart` hiện là `ScreenHeader(title)` thuần (Container teal + SafeArea + Text), `lib/screens/settings_screen.dart` là khung trống (`ScreenHeader(title: 'Cài đặt')` + `Expanded(SizedBox)`), shell `IndexedStack` PBI 2 đang giữ tab sống. **Không thêm dependency, không đổi `pubspec.yaml`, `android/`, `ios/`, `main.dart`, `app.dart`, `boot_gate.dart`, `app_shell.dart`, luồng PIN PBI 3** (research Quyết định 8).

## Pha 2: Foundational

*(Các leaf dùng chung — phải xong trước khi dựng màn Cài đặt; khác file, chạy song song được)*

- [X] T002 [P] Tạo `app/sora_thu_chi/lib/core/profile/device_profile.dart`: model thuần immutable `DeviceProfile` — trường `String? displayName` (mặc định `null` = chưa đặt tên), `String currencyCode` (mặc định `'VND'`); hằng `defaultDisplayName = 'Người dùng'`, `defaultCurrencyCode = 'VND'`; `static const initial = DeviceProfile()`; getter `resolvedDisplayName => displayName ?? defaultDisplayName` (không bao giờ rỗng — FR-002). Kèm hàm top-level thuần `String initialsOf(String name)`: lấy chữ cái đầu của **tối đa 2 từ** tách theo khoảng trắng, `toUpperCase`, nối lại; chuỗi rỗng → `''`; "Người dùng" → "ND", "Lan" → "L", "Huân Anh" → "HA" (research Quyết định 2, data-model §Giá trị suy dẫn). Không đọc/ghi storage, không trường nào khác (data-model — hồ sơ chưa bền hoá đợt này).
- [X] T003 [P] Thêm token màu vào `app/sora_thu_chi/lib/theme/app_colors.dart`: `avatarBg = Color(0xFF3D8C77)` (nền avatar teal trung), `listLabel = Color(0xFF5F5E5A)` (chữ phụ/label hàng), `listDivider = Color(0xFFEFEFEF)` (kẻ giữa hàng). Chỉ thêm 3 màu mới có vai trò riêng; các màu còn lại của màn Cài đặt **tái dùng token có sẵn** — section label viết hoa dùng `tabInactive #9B9B9B`, chevron dùng `tabInactive`, tên trắng `white`, dòng phụ `tealLightText #CDE9DF`, giá trị tiền tệ đậm `textPrimary`, header/section nền `teal` (research Quyết định 7).
- [X] T004 [P] Sửa `app/sora_thu_chi/lib/core/widgets/screen_header.dart`: thêm tham số tuỳ chọn `Widget? bottom` (mặc định null); khi có → `Padding` con thành `Column(crossAxisAlignment: start)` gồm `Text(title)` như cũ + khoảng cách + widget `bottom`, giữ nguyên Container teal + `SafeArea(bottom: false)` + padding hiện có; khi **không** truyền → giữ nguyên hành vi/layout cũ y hệt (3 màn Tổng quan/Giao dịch/Báo cáo không đổi — không hồi quy shell test PBI 2). `title` vẫn bắt buộc. Không nhúng kiến thức profile/avatar vào đây — `bottom` là widget thô do caller dựng (research Quyết định 3).
- [X] T005 Tạo `app/sora_thu_chi/test/device_profile_test.dart`: unit test model (không cần emulator, thuần Dart): `initial` → `resolvedDisplayName == 'Người dùng'`, `currencyCode == 'VND'`; `DeviceProfile(displayName: 'Lan')` → resolved là `'Lan'`; `initialsOf('Người dùng') == 'ND'`, `initialsOf('Lan') == 'L'`, `initialsOf('Huân Anh') == 'HA'` (kiểm `đ→Đ` qua `toUpperCase`), `initialsOf('') == ''`; gọi `flutter test test/device_profile_test.dart` → pass. Đổi tên default sau này chỉ sửa 1 hằng — không đụng test khác.

## Pha 3: User Story 1 — Màn trung tâm Cài đặt, chế độ chỉ hiển thị (Ưu tiên: P1) 🎯 MVP

**Mục tiêu**: Tab Cài đặt (shell PBI 2) hiển thị màn Cài đặt đúng mockup `04-ho-so-ca-nhan.svg`: header teal chứa tiêu đề "Cài đặt" + khối hồ sơ (avatar tròn chữ viết tắt + tên hiển thị + dòng phụ "Chạm để đổi ảnh đại diện"), vùng danh sách cuộn gồm 2 nhóm TÀI KHOẢN (Tiền tệ mặc định / Đổi mã PIN / Mở khóa sinh trắc học) và KHÁC (Quản lý ví). Mọi hàng chưa có chức năng là điểm vào **treo** — chạm không mở luồng, không lỗi; công tắc sinh trắc tắt & không bật được; không thao tác nào ghi dữ liệu. FR-001..011.
**Tiêu chí kiểm thử độc lập**: Pump `SettingsScreen(profile: ...)` độc lập (bơm qua constructor — không cần storage) → hiện đủ 2 nhóm/4 hàng đúng tên-thứ tự, giá trị "VND", avatar "ND"; chạm từng hàng/công tắc → không có route mới (stack không đổi), Switch giữ tắt; bơm tên dài + `textScale` lớn → không overflow. Shell/PIN test PBI 2/3 giữ xanh (xác nhận `ScreenHeader` không hồi quy).

- [X] T006 [US1] Viết lại `app/sora_thu_chi/lib/screens/settings_screen.dart`: `SettingsScreen` thành widget nhận `DeviceProfile profile` (mặc định `DeviceProfile.initial` — seam test, research Quyết định 1) + `const SettingsScreen` giữ khả năng dùng trong shell. Bố cục `Column`: (1) `ScreenHeader(title: 'Cài đặt', bottom: ...khối hồ sơ...)` cố định; (2) `Expanded` → `ListView` chứa 2 nhóm. Dựng các widget private trong cùng file: khối hồ sơ (avatar tròn nền `avatarBg` chữ viết tắt `initialsOf(profile.resolvedDisplayName)` màu trắng; tên `profile.resolvedDisplayName` trắng — bó `Expanded` + `maxLines: 1` + ellipsis; dòng phụ "Chạm để đổi ảnh đại diện" màu `tealLightText`, chạm không phản hồi — FR-006), section (label viết hoa — TÀI KHOẢN / KHÁC — màu `tabInactive`), hàng cài đặt (kẻ mảnh `listDivider` ngăn hàng). Hàng theo đúng thứ tự: nhóm TÀI KHOẢN — "Tiền tệ mặc định" (trailing = giá trị `profile.currencyCode` → "VND", đậm `textPrimary`, **không** chevron, không format số tiền/không `đ` — research Quyết định 6), "Đổi mã PIN" (chevron `tabInactive`), "Mở khóa sinh trắc học" (trailing = `Switch(value: false, onChanged: null)` disabled — mockup vẽ ON nhưng **spec FR-007 thắng**, research Quyết định 4); nhóm KHÁC — đúng 1 hàng "Quản lý ví" (chevron). **Không gắn `onTap`/navigation cho bất kỳ hàng/khối hồ sơ nào** (FR-006/007 — chạm không mở màn, không lỗi; SC-003); label hàng màu `listLabel`, tiêu đề hàng bó chống tràn cỡ chữ lớn (SC-005). Không dùng GetX controller/drift — UI thuần + model hằng (research Quyết định 8); không nhúng hex cứng — đọc hết token `AppColors`.
- [X] T007 [US1] Tạo `app/sora_thu_chi/test/settings_screen_test.dart`: widget test pump `SettingsScreen` trong `MaterialApp(theme: AppTheme.themeData)` (bọc Scaffold; `ScreenHeader` tự có `SafeArea` — test dùng viewport test mặc định): (1) profile mặc định → thấy "Cài đặt" (header), avatar chữ "ND", tên "Người dùng", dòng phụ "Chạm để đổi ảnh đại diện", 2 nhóm TÀI KHOẢN/KHÁC + đủ 4 hàng đúng thứ tự, trailing "VND", `Switch` tồn tại & `value == false`; (2) tap từng hàng "Tiền tệ mặc định"/"Đổi mã PIN"/"Quản lý ví" + tap Switch → `find.byType(Navigator)` stack/route không đổi (không màn mới), không exception, Switch vẫn tắt (FR-006/007, SC-003); (3) bơm `DeviceProfile(displayName: 'Một cái tên cực kỳ dài để kiểm tra chống tràn layout ...')` + bọc `MediaQuery(textScaler: TextScaler.linear(2.0))` (hoặc `tester.platformDispatcher.textScaleFactorTestValue`) → pump → không có `FlutterError` overflow, tên bị cắt ellipsis không vỡ (SC-005). Dùng `tester.takeException()` kiểm không exception khi tap nhanh. Chạy `flutter test test/settings_screen_test.dart` → pass.
- [X] T008 [US1] Kiểm tích hợp + hồi quy trong `app/sora_thu_chi/`: chạy `flutter analyze` → sạch; `flutter test` → toàn bộ pass (shell `widget_test.dart` PBI 2 — nhất là test tap tab Cài đặt `findsNWidgets(2)` không vỡ vì vẫn đúng 1 header "Cài đặt"; `pin_flow_test.dart`/`pin_controller_test.dart` PBI 3; `device_profile_test.dart`; `settings_screen_test.dart`). Nếu đỏ → sửa cho sạch trước khi QA, không bỏ ngang. Grep xác nhận không hex màu cứng ngoài `app_colors.dart` trong các file màn/widget mới của PBI 4.

## Pha cuối: Polish & Cross-cutting

- [X] T009 QA thủ công theo `.specify/specs/4/quickstart.md` trên Android emulator (nền tảng kiểm chứng chính): do PBI 3 bắt buộc PIN lần đầu → bản cài sạch hoặc gỡ app, đặt PIN rồi vào tab Cài đặt kiểm: nhóm A (bố cục & dữ liệu hiển thị lần đầu: header teal + avatar "ND" + tên "Người dùng" + dòng phụ, 2 nhóm/4 hàng đúng tên-thứ tự, "VND", công tắc tắt, tab Cài đặt tô teal — SC-001/002), nhóm B (chạm lần lượt hàng PIN/Quản lý ví/vùng ảnh → không mở màn, không lỗi; chạm công tắc nhiều lần kể cả nhanh → giữ tắt — SC-003), nhóm C (cuộn xuống, chuyển tab qua lại ≥ 5 lần → về đúng vị trí cuộn — SC-004; nhờ `IndexedStack` shell giữ trạng thái — không thêm code), nhóm D (cỡ chữ lớn nhất + màn có vùng an toàn → không vỡ/tràn/che, thanh đáy không che hàng cuối — SC-005), nhóm E (rời/quay lại → giá trị không đổi, xác nhận chế độ chỉ hiển thị — SC-006), nhóm F (đang ở tab Cài đặt → đưa xuống nền/mở lại → màn khóa PIN che toàn bộ, nhập đúng PIN → về đúng tab Cài đặt — FR-011). Ghi kết quả + đối chiếu FR-001..011/SC-001..006 ghi ĐẠT/không đạt vào ghi chú cuối tasks.md này; trạng thái iOS chưa verify (máy Windows — code thuần widget/material, rủi ro thấp, verify khi có máy macOS). Lưu ý lệch mockup đã chốt: toggle sinh trắc hiển thị TẮT (mockup vẽ ON) — thi công theo spec FR-007, research Quyết định 4.

---

## Sơ đồ phụ thuộc

```text
T001 (Setup)
  → Pha 2 (Foundational, song song): T002 (model) · T003 (token) · T004 (ScreenHeader bottom)
      → T005 (unit test model — cần T002)
          → T006 [US1] dựng màn (cần T002+T003+T004)
              → T007 [US1] widget test (cần T006)
              → T008 [US1] analyze + full test hồi quy (cần T007)
                  → T009 Polish: QA thủ công quickstart
```

US1 là story duy nhất — không có phụ thuộc chéo giữa các story.

## Ví dụ chạy song song

```text
# Pha 2 — 3 leaf khác file, độc lập, chạy cùng lúc:
T002 [P] device_profile.dart (model + initialsOf)
T003 [P] app_colors.dart (token avatarBg/listLabel/listDivider)
T004 [P] screen_header.dart (slot bottom tuỳ chọn)
```

## Chiến lược triển khai

- **MVP**: User Story 1 (toàn bộ — đây là PBI một màn duy nhất, không cắt nhỏ thêm).
- **Giao hàng**: Foundational (model + token + header slot, không thay đổi hành vi màn cũ) → US1 dựng màn → unit/widget test → hồi quy full suite → QA thủ công. Bước tiếp theo: chạy `/sora-implement 4`.

---

## Ghi chú QA (T009) — 2026-09-04

Kết quả QA thủ công trên Android emulator (người dùng xác nhận **ok**):

- **Nhóm A** (bố cục & dữ liệu lần đầu, SC-001/002): ĐẠT — header teal + avatar "ND" + tên "Người dùng" + dòng phụ; 2 nhóm TÀI KHOẢN/KHÁC + 4 hàng đúng tên-thứ tự; giá trị "VND"; công tắc sinh trắc tắt.
- **Nhóm B** (SC-003, FR-006/007): ĐẠT — chạm hàng Đổi mã PIN/Quản lý ví/vùng ảnh không mở màn, không lỗi; công tắc giữ tắt khi chạm nhiều lần.
- **Nhóm C** (giữ vị trí cuộn, SC-004): ĐẠT — `IndexedStack` shell giữ trạng thái, không thêm code.
- **Nhóm D** (cỡ chữ lớn/vùng an toàn, SC-005): ĐẠT — không vỡ/tràn.
- **Nhóm E** (chế độ chỉ hiển thị, SC-006): ĐẠT — giá trị không đổi khi rời/quay lại.
- **Nhóm F** (FR-011): ĐẠT — màn khóa PIN che toàn bộ khi đưa xuống nền; mở đúng PIN về đúng tab.

Đối chiếu FR-001..011 / SC-001..006: **đạt toàn bộ**. Lệch mockup đã chốt: toggle sinh trắc hiển thị TẮT (theo spec FR-007, research Quyết định 4). iOS chưa verify (máy Windows).
