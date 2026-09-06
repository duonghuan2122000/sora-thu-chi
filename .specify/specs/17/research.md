# Nghiên cứu — PBI 17 (Tiện ích & Cá nhân hóa — màn danh sách)

Ngày: 2026-09-06

## R1 — Lưu trạng thái 2 công tắc (Ẩn số dư, Máy tính khi nhập số tiền) ở đâu?

- **Quyết định**: Lưu trong **drift** — thêm bảng `AppSettings` dạng **key-value**
  (`key` TEXT PK, `value` TEXT), nâng schema `v4 → v5`, thêm nhánh migration
  `if (from < 5) await m.createTable(appSettings);`. Không seed — key vắng mặt =
  giá trị mặc định do tầng domain quyết định (Ẩn số dư = `false`, Máy tính = `true`).
- **Lý do**: (a) App đã dùng drift làm tầng lưu local duy nhất (ví, giao dịch, danh
  mục) — không thêm nguồn lưu trữ mới, không thêm dependency; (b) key-value → các
  PBI sau (02–07 thêm nhiều cài đặt: giao diện, ngôn ngữ, định dạng...) chỉ thêm
  *row*, **không thêm migration** nữa — trả một lần chi phí nâng schema; (c) mọi
  màn tiêu thụ về sau (che số dư ở Tổng quan, đổi bàn phím nhập tiền) đọc cùng
  store qua GetX singleton như pattern repo hiện có.
- **Phương án khác**:
  - `shared_preferences` (thêm package, không migration): reject — thêm dependency
    mới trong khi app đã có DB local; đúng chuẩn Flutter nhưng lệch "mọi thứ local
    trong drift" của dự án, và nhiều cài đặt sắp tới sẽ cần chung một nguồn.
  - `flutter_secure_storage` (đã cài): reject — đây không phải dữ liệu bí mật; dùng
    secure store cho cờ bật/tắt là sai ngữ nghĩa, truy xuất chậm/hay lỗi hơn.
  - Bảng rộng (1 dòng N cột bool): reject — mỗi PBI cài đặt mới = 1 migration thêm
    cột; key-value tiện hơn về dài hạn.

## R2 — Hàng "Giao diện" / "Ngôn ngữ": giá trị hiển thị có lưu không?

- **Quyết định**: Không lưu — đợt này hiển thị **giá trị mặc định tĩnh** "Hệ thống"
  / "Tiếng Việt" (hằng UI). Màn con 02/03 (PBI sau) mới đổi và cập nhật về đây.
- **Lý do**: spec Giả định — "khi màn con cho phép đổi, giá trị sẽ do cài đặt thật
  cung cấp; đợt này hiển thị giá trị mặc định". Lưu sớm = dữ liệu chưa ai tiêu thụ.
- **Phương án khác**: đưa 2 giá trị vào `AppSettings` ngay — reject (YAGNI, spec nói
  rõ không phát sinh).

## R3 — 5 hàng điều hướng (Giao diện, Ngôn ngữ, Định dạng & Tiền tệ, Tìm kiếm toàn cục, Quản lý Tag)

- **Quyết định**: Hàng đầy đủ (icon + tên + dòng phụ + chevron) nhưng `onTap` = no-op
  — **không** đẩy màn nào, không lỗi. Nhất quán pattern "điểm vào chưa kích hoạt"
  PBI 13.
- **Lý do**: các màn con 02–07 chưa tồn tại; giữ nguyên bố cục mockup để đợt sau chỉ
  gắn điểm vào.
- **Phương án khác**: bỏ hàng — reject (spec FR-005 yêu cầu đủ 8 hàng).

## R4 — Dòng phụ & dữ liệu minh họa trong mockup 01

- **Quyết định**: Đối chiếu mockup `01`: giữ dòng phụ thật — "Giao diện" có dòng phụ
  "Sáng / Tối / Theo hệ thống" + trailing "Hệ thống"; "Ngôn ngữ" trailing "Tiếng
  Việt"; "Widget màn hình chính" dòng phụ "Hiện số dư & chi tiêu hôm nay". Riêng
  "Quản lý Tag": **thay** dòng phụ minh họa `#dulich, #congty…` và số "12 tag" bằng
  **dòng phụ mô tả** không chứa tag/số giả (VD "Gắn nhãn cho giao dịch") — spec
  SC-008/FR-009 cấm con số giả.
- **Lý do**: FR-003 đòi dòng phụ "những hàng mockup có", nhưng SC-008 cấm dữ liệu
  minh họa; mô tả sạch dung hòa cả hai, tránh hiểu nhầm "đã có N tag".
- **Phương án khác**: hiện đúng `#dulich…` — reject (vi phạm SC-008).

## R5 — Hàng "Widget màn hình chính": không phải công tắc thật

- **Quyết định**: Trailing là `Switch(value: true, onChanged: null)` — hiển thị trạng
  thái "bật" theo mockup, **không đảo** khi chạm (spec FR-008/§3.4). Chạm **toàn
  hàng** (kể cả vùng công tắc) mở **AlertDialog hướng dẫn ghim widget** theo nền
  tảng (`defaultTargetPlatform`): giải thích việc ghim do hệ điều hành quản lý + các
  bước ghim cơ bản (Android: chạm-giữ màn hình chính → Widgets → kéo widget app;
  iOS: chạm-giữ → nút "+" → chọn app). Trạng thái switch không lưu.
- **Lý do**: chưa có tính năng widget thật; hàng mang tính nhắc/hướng dẫn như spec.
- **Lưu ý thi công**: vùng `Switch` tắt chức năng phải không nuốt chạm → bọc hàng
  trong `InkWell` để chạm đâu cũng mở dialog; test assert switch giữ `true`.

## R6 — State của màn & nhu cầu broadcast

- **Quyết định**: Màn là `StatefulWidget` (như `CategoryListScreen`), `initState` đọc
  store 1 lần; bật/tắt → `setState` + ghi-through store. Chưa cần GetX controller
  reactive lan toả.
- **Lý do**: FR-007 — đợt này chưa màn nào khác tiêu thụ; chỉ cần nhớ lại khi mở
  màn. Khi PBI sau đọc settings xuyên màn → bọc GetX/broadcast lúc đó (YAGNI).
- **Phương án khác**: dựng `UtilitiesController` GetX ngay — reject (thừa tới khi có
  consumer).

## R7 — Seam kiểm thử & điểm vào từ Cài đặt

- **Quyết định**: Theo pattern PBI 13: `SettingsScreen` thêm hàng **"Tiện ích & Cá
  nhân hóa"** ngay dưới "Danh mục" trong nhóm KHÁC, kèm seam `onManageUtilitiesTap`
  (test bơm callback → không push) và mặc định push `UtilitiesScreen`. `UtilitiesScreen`
  nhận seam `store` (mặc định `null` → `ensureUtilitiesStore()` qua GetX); test bơm
  `FakeUtilitiesStore`.
- **Lý do**: giữ màn test được không khởi tạo sqlite native; đúng pattern đã dùng.

## R8 — Lưu ý dữ liệu mẫu/seed

- **Quyết định**: Không thêm dòng mẫu vào `AppSettings`; giá trị mặc định xử lý ở
  domain khi key vắng mặt. Nâng schema v5 không làm đụng seed ví/danh mục/giao dịch
  hiện có (nhánh migration cũ giữ nguyên, chỉ thêm nhánh tạo bảng).
- **Lý do**: 2 công tắc mặc định đã do mockup quy định; row chỉ ghi khi người dùng
  bật/tắt.
