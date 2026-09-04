# Nghiên cứu & quyết định kỹ thuật: Màn hình Cài đặt

**Mã PBI**: 4 — tài liệu đối chiếu: mockup `docs/auth/04-ho-so-ca-nhan.svg`, `docs/auth/chi-tiet-quan-ly-tai-khoan-nguoi-dung.md` §3, `docs/design-system-app-thu-chi.md` §2.3/§3/§4/§5; bám khung shell PBI 2 (`AppShell` + `IndexedStack`), màn Cài đặt hiện tại là khung trống (`settings_screen.dart`).

## Quyết định 1 — Đợt này KHÔNG bền hoá hồ sơ thiết bị; hiển thị từ model hằng

- **Quyết định**: hồ sơ thiết bị = model immutable `DeviceProfile` với giá trị mặc định (`DeviceProfile.initial`); `SettingsScreen` nhận `profile` (mặc định `initial`). Không đọc/ghi storage nào trong đợt này.
- **Lý do**: toàn bộ luồng sửa hồ sơ (đặt/đổi tên, đổi tiền tệ mặc định, ảnh đại diện) nằm ngoài phạm vi (spec §Ngoài phạm vi, §Giả định). Không có thao tác nào **ghi** profile → không có khác biệt quan sát được giữa "lưu default xuống storage" và "hiển thị hằng số default" (SC-006 xác nhận màn chỉ hiển thị). Thêm backend lúc này = code chết/đường code không bao giờ chạy được với dữ liệu khác default. Constructor param là seam để widget test bơm profile bất kỳ (kiểm layout tên dài, avatar...) mà không cần storage.
- **Phương án khác đã xem xét**: (a) seed default xuống `flutter_secure_storage` (pattern PIN PBI 3) rồi đọc lại — data không phải secret, phình keystore, đường "đọc được dữ liệu khác default" không tồn tại tới khi có luồng ghi → loại; (b) dựng bảng drift ngay — drift đã khai báo pubspec nhưng chưa có service/schema/migration, nặng cho 1 bản ghi cấu hình chưa ai ghi → loại.
- **Điểm bám cho PBI sau**: khi PBI sửa hồ sơ / đổi tiền tệ (hoặc module Ví cần đọc tiền tệ mặc định thật) đến → thêm `DeviceProfileStore` (chốt backend tại PBI đó: drift singleton hoặc shared_preferences/secure storage), `SettingsScreen` đổi sang đọc store + nạp lại khi quay về. Riêng avatar/tên là pure-function nên tách khỏi nguồn dữ liệu từ trước.

## Quyết định 2 — Tên hiển thị mặc định & thuật toán chữ viết tắt

- **Quyết định**: tên mặc định = **"Người dùng"** (hằng `DeviceProfile.defaultDisplayName`). Chữ viết tắt avatar = hàm thuần `initialsOf(name)`: lấy chữ cái đầu của **tối đa 2 từ** (tách theo khoảng trắng), in hoa (`toUpperCase` xử lý được `đ→Đ`), nối lại; name rỗng → chuỗi rỗng. Tên mặc định → viết tắt "ND".
- **Lý do**: spec §Giả định giao "chuỗi cụ thể chốt khi lập kế hoạch" cho tên mặc định — không có nguồn nào khác quy định (docs chỉ nói "tên tự do, dùng chào mừng"). "Người dùng" trung tính, không gán nhận dạng sai. Viết tắt "chữ cái đầu tối đa 2 từ" khớp persona mockup "Huân Anh" → "HA", xử lý cả tên 1 từ ("Lan" → "L") lẫn 2 từ.
- **Phương án khác đã xem xét**: (a) dùng tên persona trong mockup "Huân Anh" — là người minh họa (mockup là gợi ý, không phải đặc tả), đặt làm default sẽ hiển thị sai tên người thật của user → loại; (b) "Khách"/"Bạn" — sắc thái khác, chưa đủ căn cứ. Đổi chỉ cần sửa 1 hằng, không đụng cấu trúc.

## Quyết định 3 — Đầu trang hồ sơ nằm trong header teal; tái dùng `ScreenHeader`

- **Quyết định**: mở rộng `ScreenHeader` (dùng chung 4 màn chính, PBI 2) bằng slot `bottom` tuỳ chọn: khi có → render `Column` gồm tiêu đề + khối hồ sơ (avatar tròn + tên + dòng phụ) trong cùng vùng teal; khi **không** có → giữ nguyên hành vi hiện tại. Settings truyền khối hồ sơ, 3 màn kia không truyền.
- **Lý do**: khớp mockup — tiêu đề "Cài đặt" **và** khối hồ sơ (chữ trắng, dòng phụ `#CDE9DF`) cùng nằm trên nền teal trong 1 vùng; mockup vùng teal cao 130 là minh họa, ta để header tự cao theo nội dung (an toàn cỡ chữ lớn, SC-005). Tái dùng 1 widget header giữ 1 nguồn style teal/SafeArea/typography, tránh nhân đôi.
- **Phương án khác đã xem xét**: dựng header riêng trong `settings_screen.dart` — nhân đôi style teal + SafeArea + tiêu đề đã có ở `ScreenHeader`; widget dùng chung cũng tái dụng được cho sub-page Cài đặt sau → loại.

## Quyết định 4 — Công tắc sinh trắc học: `Switch` native, tắt + không bật được

- **Quyết định**: hàng "Mở khóa sinh trắc học" dùng `Switch` native Material với `value: false`, `onChanged: null` (disabled) → track xám tắt, chạm không đổi trạng thái, không lỗi.
- **Lý do**: FR-007 + giả định spec "sinh trắc chưa hỗ trợ trong giai đoạn này → chạm công tắc KHÔNG được làm nó bật". Mockup vẽ toggle ở trạng thái **bật** (track teal) nhưng đó là minh họa generic — **spec thắng** (mâu thuẫn mockup/spec ghi rõ ở đây). Khi PBI sinh trắc đến → gắn `onChanged` + xử lý trạng thái/đồng bộ OS (đã ghi ở wiki Hồ sơ & Bảo mật).
- **Phương án khác**: Switch tắt nhưng bắt tap hiện snackbar "chưa hỗ trợ" — thêm hành vi ngoài SC (SC-003 chỉ cần "không bật, không lỗi"), loại.

## Quyết định 5 — Bố cục: header cố định + `ListView` cuộn vùng danh sách; giữ trạng thái bằng `IndexedStack`

- **Quyết định**: `SettingsScreen` = `Column`: (1) `ScreenHeader`(title + profile) cố định phía trên; (2) `Expanded` → `ListView` chứa 2 section (TÀI KHOẢN, KHÁC) với các hàng. Cuộn chỉ xảy ra ở vùng danh sách khi nội dung dài (FR-008). Giữ vị trí cuộn & trạng thái khi rời/quay lại tab = sẵn có từ `IndexedStack` của shell PBI 2 (các tab giữ nguyên element) — không cần code thêm (FR-009/SC-004).
- **Lý do**: mockup cho thấy header hồ sơ teal đứng yên phía trên, chỉ danh sách cuộn; ListView trong `Expanded` dưới header có sẵn khả năng cuộn & nhớ scroll offset, kết hợp IndexedStack giữ nguyên trạng thái. Không cần controller/scrollcontroller riêng.
- **Phương án khác**: cuộn cả vùng header (CustomScrollView + SliverAppBar) — profile biến mất khi cuộn, lệch mockup; thêm cơ chế nhớ trạng thái thủ công, loại.

## Quyết định 6 — Hiển thị tiền tệ mặc định là mã tiền tệ (không format số tiền)

- **Quyết định**: hàng "Tiền tệ mặc định" hiện **mã** `VND` (lấy `profile.currencyCode`, mặc định `'VND'`), chữ đậm `#1A1A1A` căn phải; **không** có dấu chấm nghìn hay hậu tố `đ`. Không chevron (mockup không vẽ), không mở luồng (đổi tiền tệ ngoài phạm vi).
- **Lý do**: đây là mã tiền tệ của hồ sơ, không phải số tiền → quy tắc format số tiền (design doc §4 "phân tách nghìn + đơn vị `đ`") không áp dụng. Khớp mockup "VND".
- **Phương án khác**: format dạng tiền tệ locale (`₫`, `42.500.000 ₫`) — sai ngữ nghĩa ô này & chưa có luồng quy đổi, loại.

## Quyết định 7 — Bổ sung token màu mới; style tập trung

- **Quyết định**: thêm vào `app_colors.dart` đúng các màu mới có vai trò riêng (đã có trong design doc nhưng chưa có token): `avatarBg #3D8C77` (teal trung — nền avatar), `listLabel #5F5E5A` (chữ phụ — label hàng danh sách), `listDivider #EFEFEF` (kẻ giữa hàng). Tái dùng token có sẵn: teal (header/section), `white`, `tealLightText #CDE9DF` (dòng phụ profile), `#9B9B9B` (label section viết hoa + chevron — cùng mã `tabInactive`, design doc quy 1 mã cho "chữ mờ/tab chưa chọn/tiêu đề section"). Không có widget nào nhúng hex cứng.
- **Lý do**: quy ước style tập trung 1 nơi (CLAUDE.md) — màu mới chỉ khai khi tiêu thụ; tránh trùng token cùng giá trị.
- **Phương án khác**: nhúng hex trực tiếp trong widget — vi phạm quy ước, loại.

## Quyết định 8 — Không thêm dependency / không đổi config nền tảng

- **Quyết định**: đợt này không thêm package; không đổi pubspec, `android/`, `ios/`. Không dùng drift/GetX controller mới (màn đọc tĩnh, không state mềm; GetX đã dùng cho PIN PBI 3).
- **Lý do**: UI thuần widget + model thuần Dart; không có async/lưu trữ/navigation nghiệp vụ mới. Tất cả yêu cầu đạt bằng widget Material + token có sẵn/mới.
- **Phương án khác**: controller GetX cho Settings — chưa cần reactive (chưa ai sửa profile), loại (YAGNI).

## Kết luận

Không còn điểm `NEEDS CLARIFICATION`. Mọi lựa chọn nhất quán: stack đã chốt (không thêm dependency), design system (1 màu teal; avatar teal trung; section viết hoa xám; kẻ mảnh), cấu trúc shell PBI 2 (IndexedStack giữ trạng thái), và phạm vi spec (chỉ hiển thị; các hàng là điểm vào chưa kích hoạt; sinh trắc tắt; không sửa hồ sơ). Mâu thuẫn duy nhất mockup↔spec (toggle sinh trắc ON trong svg vs tắt theo FR-007) giải quyết theo spec, ghi chú rõ.
