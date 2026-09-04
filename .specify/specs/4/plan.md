# Kế hoạch triển khai: Màn hình Cài đặt (trung tâm cài đặt)

**Mã PBI**: 4
**Liên kết spec**: .specify/specs/4/spec.md
**Ngày tạo**: 2026-09-04

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x (Flutter stable — máy Windows, theo PBI 1/2/3) |
| Framework / Thư viện chính | Flutter Material, UI thuần widget + model thuần Dart; GetX 4.7.3 đã dùng (PIN PBI 3) — **đợt này không cần controller mới** (màn đọc tĩnh); drift 2.34.4 đã khai báo nhưng chưa dùng (không cần ở đây) |
| Lưu trữ dữ liệu | **Không thêm** — hồ sơ hiển thị từ model hằng `DeviceProfile.initial`; không đọc/ghi storage (xem `research.md` Quyết định 1) |
| Kiểm thử | `flutter analyze` sạch + `flutter test` (unit `initialsOf`/default + widget test màn Cài đặt; shell/PIN PBI 2/3 phải giữ xanh) + QA thủ công emulator theo `quickstart.md` |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS (code thuần widget, rủi ro thấp — verify khi có máy macOS) |
| Ràng buộc hiệu năng | Không đặc thù; dựng 1 lần, shell `IndexedStack` giữ tab sống |
| Ràng buộc khác | App offline; màn Cài đặt chỉ hiển thị sau khi mở khóa (PBI 3 đã đảm bảo — không làm gì thêm); design system đúng 1 màu teal (coral chỉ chi/cảnh báo); avatar teal trung `#3D8C77`; style tập trung token, widget không hex cứng; **cấm dùng persona mockup "Huân Anh" làm dữ liệu hiển thị**; tài liệu & commit tiếng Việt có dấu |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + tài liệu auth §3:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | Hồ sơ thiết bị lưu local (đợt này chỉ model); không gọi mạng |
| Đúng stack đã chốt | ✅ | Không thêm dependency; GetX/drift không cần thêm ở đây (research Q8) |
| Design system (1 màu teal; section viết hoa xám; avatar tròn teal trung; kẻ mảnh) | ✅ | Đối chiếu design doc §2.3/§3/§5 + mockup `04-ho-so-ca-nhan.svg`; coral không dùng |
| Style tập trung 1 nơi | ✅ | Thêm token `avatarBg`/`listLabel`/`listDivider` vào `app_colors.dart`; widget không hex cứng |
| Cấm fake data / số liệu minh họa giả | ✅ | Không số liệu giả; **không** hiển thị "Huân Anh" (persona mockup); tên default "Người dùng" là placeholder nghiệp vụ hợp lệ |
| Màn Cài đặt trong shell, không lộ qua màn khóa | ✅ | FR-011 vốn đã thỏa bởi luồng boot/lock PBI 3 (shell chỉ tới sau unlock) |
| Các hàng chưa có chức năng = điểm vào treo, không lỗi | ✅ | Không gắn onTap/luồng; chỉ hiển thị (FR-006/007) |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Tóm tắt quyết định chính:
- **Không bền hoá profile đợt này** — hiển thị từ `DeviceProfile.initial`; seam = constructor param để test bơm profile bất kỳ; thêm `DeviceProfileStore` khi PBI sửa hồ sơ/đổi tiền tệ đến (Q1).
- **Tên mặc định "Người dùng"**; avatar viết tắt = hàm thuần `initialsOf` (chữ cái đầu tối đa 2 từ, in hoa) — "Người dùng" → "ND" (Q2).
- **Tái dùng `ScreenHeader`** thêm slot `bottom` cho khối hồ sơ nằm trong header teal; 3 màn chính khác không đổi (Q3).
- **Công tắc sinh trắc = `Switch` native `value:false, onChanged:null`** (tắt, không bật) — mockup vẽ ON nhưng spec FR-007 thắng (Q4).
- **Bố cục**: header cố định + `ListView` cuộn; giữ trạng thái/scroll sẵn có từ `IndexedStack` shell PBI 2 (Q5).
- **Tiền tệ hiển thị mã `VND`** (không format số tiền, không `đ`) (Q6); **bổ sung 3 token màu** mới, không hex cứng (Q7); **không thêm dependency/config nền tảng** (Q8).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — thực thể "Hồ sơ thiết bị" (`DeviceProfile`: `displayName` nullable + `currencyCode` default `'VND'`; avatar/tên hiển thị là giá trị suy dẫn), đợt này không bền hoá.
- **Hợp đồng giao diện**: **không tạo** — app nội bộ, offline, không API/CLI công khai.
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–F đối chiếu SC-001..006 + FR-011.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Không store/controller/service thừa; 1 model thuần + widget hiển thị + token mới |
| Không vi phạm mới phát sinh | ✅ | Ngoại lệ duy nhất = "không bền hoá hồ sơ" là lệch đọc *kỹ thuật* so với câu chữ FR (profile "lấy từ hồ sơ thiết bị"/"tạo lần đầu") — không phải vi phạm nghiệp vụ: không luồng ghi nào để phân biệt default được lưu hay không (xem Rủi ro, user duyệt) |
| Test không phụ thuộc thiết bị/lưu trữ | ✅ | UI pure widget; bơm profile qua constructor; unit hàm `initialsOf` |
| Shell & luồng PIN cũ không vỡ | ✅ | Thêm slot optional vào `ScreenHeader` (không đổi hành vi default); nội dung mới của Settings không trùng chuỗi test shell |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── theme/app_colors.dart                    # [SỬA] thêm avatarBg #3D8C77, listLabel #5F5E5A, listDivider #EFEFEF
│   ├── core/
│   │   ├── widgets/screen_header.dart           # [SỬA] thêm slot optional `bottom` (title + khối hồ sơ trong vùng teal)
│   │   └── profile/device_profile.dart          # [TẠO] DeviceProfile (displayName?, currencyCode, default + resolved) + initialsOf()
│   └── screens/settings_screen.dart             # [SỬA] khung → màn Cài đặt: profile header + 2 section (TÀI KHOẢN/KHÁC)
│                                                #        + các private widget (khối hồ sơ, section, hàng cài đặt)
└── test/
    ├── device_profile_test.dart                 # [TẠO] unit: default/resolved/initialsOf (1 từ, 2 từ, diacritics, rỗng)
    └── settings_screen_test.dart                # [TẠO] widget: màn hiển thị đủ 2 nhóm/4 hàng/giá trị VND + avatar "ND";
                                                 #        tap hàng không mở màn; Switch tắt & không bật; cỡ chữ lớn & tên dài không vỡ

Không đổi: pubspec.yaml (không thêm dependency), main.dart, app.dart, shell/boot/PIN, android/, ios/.
```

## Rủi ro & ngoại lệ có lý do

- **Không bền hoá hồ sơ (quyết định lớn cần user duyệt)**: câu chữ FR-002/FR-004 ("lấy từ hồ sơ thiết bị", "lần đầu tạo hồ sơ... VND") đọc literal gợi ý có một bản ghi được tạo/lưu. Đợt này **không có luồng ghi nào** (sửa hồ sơ/đổi tiền tệ đều ngoài phạm vi) nên giữa "lưu default" và "hằng default" không có khác biệt người dùng thấy được (SC-006). Chọn hiển thị từ model hằng để không thêm code chết; khi PBI ghi đầu tiên đến → thêm `DeviceProfileStore` (điểm bám đã ghi research Q1). Nếu muốn khởi tạo bản ghi default ngay (bền hoá) → tăng scope, báo để điều chỉnh.
- **Tên mặc định "Người dùng" / avatar "ND"** là quyết định lập kế hoạch (spec giao). Muốn tên khác chỉ đổi 1 hằng — không đụng cấu trúc. Không dùng "Huân Anh" (persona mockup) để tránh hiển thị nhận dạng người khác.
- **Mockup vẽ toggle sinh trắc ở trạng thái BẬT** nhưng spec FR-007 bắt **tắt & không bật** → thi công theo spec; ghi chú lệch mockup ở research Q4.
- **Header cao hơn mockup vài px** (header tự cao theo nội dung thay vì cố định 130) — có chủ đích để an toàn cỡ chữ lớn & vùng an toàn (SC-005); sai khác nhỏ chấp nhận (mockup gợi ý, không phải đặc tả tuyệt đối). Kiểm chứng QA nhóm A/D.
- **`ScreenHeader` là widget dùng chung 4 màn**: chỉ thêm slot optional, không đổi hành vi khi không truyền — shell test PBI 2 xác nhận không hồi quy. Nếu sau này thấy nhiều màn con tái dùng style hàng danh sách → tách `SettingsRow` thành widget dùng chung ở PBI sub-page, không làm sớm.
- **Cỡ chữ lớn / tên dài tràn khối hồ sơ** (SC-005 + edge): tên/dòng phụ bó `Expanded` + 1 dòng + ellipsis, không chiều cao cố định; widget test bơm profile tên dài + textScale lớn kiểm không overflow. Nếu vẫn tràn trên thiết bị thật → điều chỉnh rồi ghi trạng thái sau thi công, không bỏ ngang.
- **iOS chưa verify** (máy Windows): code thuần widget/material, rủi ro thấp; giữ trạng thái, verify khi có máy macOS.

## File đã tạo

- `.specify/specs/4/research.md`
- `.specify/specs/4/data-model.md`
- `.specify/specs/4/quickstart.md`
- `.specify/specs/4/plan.md`

Bước tiếp theo: chạy `/sora-task 4` để phân rã thành tasks.md.
