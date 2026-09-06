# Kế hoạch triển khai: Tiện ích & Cá nhân hóa — màn danh sách

**Mã PBI**: 17
**Liên kết spec**: .specify/specs/17/spec.md
**Ngày tạo**: 2026-09-06

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart / Flutter (Mobile Android + iOS) |
| Framework / Thư viện chính | Material 3, `get` (GetX — DI singleton), drift (local DB) |
| Lưu trữ dữ liệu | SQLite qua **drift** (file `sora_thu_chi.sqlite`), schema hiện **v4** → nâng **v5** |
| Kiểm thử | `flutter_test` + drift in-memory; seam store fake; widget test màn |
| Nền tảng triển khai | Android/iOS, offline hoàn toàn |
| Ràng buộc hiệu năng | Không áp (màn tĩnh 8 hàng); SC-001 mở trong ≤1s |
| Ràng buộc khác | Design system: 1 màu teal `#0F6E56`, icon trong vòng nền nhạt; màn con shell: app bar thương hiệu + back, không bottom nav; tiếng Việt có dấu |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu constraint trong `docs/` +
`CLAUDE.md`:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline, không server, lưu local | ✅ | Công tắc lưu drift local (R1) |
| Stack chốt: drift + GetX (không thêm dependency) | ✅ | Không thêm package; tái dùng drift |
| Màn con từ Cài đặt: SubPageScaffold + back, không bottom nav | ✅ | Tái dùng `SubPageScaffold` như màn danh mục |
| Design system: teal cho trạng thái chọn/bật, số tiền không xuất hiện | ✅ | Icon teal trong vòng nhạt; màn không chứa số tiền |
| Điểm vào chưa kích hoạt = no-op (pattern PBI 13) | ✅ | 5 hàng điều hướng chạm không mở gì |
| Ngôn ngữ/tài liệu tiếng Việt có dấu | ✅ | |

## Giai đoạn 0 — Nghiên cứu

Xem `research.md`. Quyết định chính:

- **R1**: Lưu 2 công tắc bằng **drift key-value** (bảng `AppSettings`, schema v5, migration
  `from < 5`). *Lý do*: giữ "mọi local trong drift", không thêm dependency; cài đặt PBI sau chỉ
  thêm row. *Phương án khác*: `shared_preferences` / `flutter_secure_storage` / bảng rộng — reject.
- **R5**: Hàng Widget màn hình chính = switch hiển thị "bật" `onChanged: null`, chạm toàn hàng →
  AlertDialog hướng dẫn ghim widget theo nền tảng; trạng thái không lưu.
- **R6**: Màn `StatefulWidget`, đọc store 1 lần, bật/tắt write-through; chưa cần GetX broadcast.
- **R7**: `SettingsScreen` thêm hàng "Tiện ích & Cá nhân hóa" dưới "Danh mục" (nhóm KHÁC) + seam
  `onManageUtilitiesTap`; `UtilitiesScreen` seam `store` mặc định `ensureUtilitiesStore()`.
- **R4**: Dòng phụ "Quản lý Tag" thay bằng mô tả sạch (không `#…`, không "12 tag") — dung hòa
  FR-003/SC-008.

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — bảng `AppSettings` (key-value) + domain
  `UtilitiesPrefs` (`hideBalance=false`, `amountCalculatorEnabled=true`); key vắng = mặc định.
- **Hợp đồng giao diện**: `contracts/` — **bỏ qua** (app nội bộ, offline, không API/CLI bên ngoài).
- **Kịch bản khởi động nhanh**: xem `quickstart.md`.

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline, lưu local | ✅ | Chỉ drift, không server |
| Không thêm dependency | ✅ | Đề xuất không thêm package |
| Migration drift an toàn | ✅ | Thêm nhánh `from < 5` tạo bảng; không đụng seed hiện có (R8) |
| Màn con + back, không bottom nav | ✅ | SubPageScaffold |
| Nghiệp vụ: "Widget" & "Tag" chưa dựng = không công tắc thật/không số giả | ✅ | R4/R5 |
| FR-007: công tắc không đổi hành vi màn khác | ✅ | State local, không broadcast (R6) |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   └── utilities/                    # module mới (domain + seam)
│   │       ├── utilities.dart            #   UtilitiesPrefs + hằng khóa + parse/mặc định
│   │       └── utilities_store.dart      #   abstract UtilitiesStore (load/save)
│   ├── data/
│   │   ├── db/app_database.dart          # SỬA: + bảng AppSettings, schemaVersion 5, onUpgrade
│   │   ├── db/app_database.g.dart        #   build_runner sinh lại
│   │   ├── utilities_deps.dart           # ensureUtilitiesStore() (GetX singleton)
│   │   └── utilities_store_drift.dart    # DriftUtilitiesStore(AppDatabase)
│   └── screens/
│       ├── settings_screen.dart          # SỬA: + hàng "Tiện ích & Cá nhân hóa" + seam
│       └── utilities_screen.dart         # MÀN 01: 3 nhóm / 8 hàng + dialog ghim widget
├── test/
│   ├── fakes/fake_utilities_store.dart   # fake ghi/đọc trong bộ nhớ
│   ├── utilities_test.dart               # domain: mặc định + parse + to/from
│   ├── utilities_store_drift_test.dart   # drift in-memory: load mặc định + round-trip
│   ├── utilities_screen_test.dart        # 8 hàng, toggle + persist, dialog widget, no-op nav, cỡ chữ
│   └── settings_screen_test.dart         # SỬA: assert hàng mới + mở màn
```

Bố cục màn `utilities_screen.dart` (8 hàng, 3 nhóm, theo mockup 01):

| Nhóm | Hàng | Dòng phụ / phần cuối | Hành vi |
|---|---|---|---|
| HIỂN THỊ | Giao diện | "Sáng / Tối / Theo hệ thống" → "Hệ thống" ▸ | no-op |
| HIỂN THỊ | Ngôn ngữ | → "Tiếng Việt" ▸ | no-op |
| HIỂN THỊ | Định dạng & Tiền tệ | "Ngày, tiền tệ, tuần, kỳ tài chính" ▸ | no-op |
| TRẢI NGHIỆM | Widget màn hình chính | "Hiện số dư & chi tiêu hôm nay" · switch bật (câm) | chạm hàng → dialog ghim widget (R5) |
| TRẢI NGHIỆM | Ẩn số dư (Privacy mode) | "Che số tiền trên màn hình chính" · switch | toggle thật, lưu (mặc định tắt) |
| TRẢI NGHIỆM | Máy tính khi nhập số tiền | "Cho phép +, -, x, / khi nhập" · switch | toggle thật, lưu (mặc định bật) |
| DỮ LIỆU & TÌM KIẾM | Tìm kiếm toàn cục | "Giao dịch, danh mục, ví" ▸ | no-op |
| DỮ LIỆU & TÌM KIẾM | Quản lý Tag | dòng phụ mô tả (không `#…`, không "12 tag") ▸ | no-op |

Mỗi hàng: vòng nền nhạt + icon teal (icon material đúng nghĩa mục — đối chiếu mockup khi thi
công) + tên + dòng phụ (nếu có) + phần cuối. Kỹ thuật chống tràn cỡ chữ lớn theo pattern hàng
Cài đặt hiện có (label chống tràn, ListView cuộn).

## Rủi ro & ngoại lệ có lý do

- **Tiêu đề dài "Tiện ích & Cá nhân hóa" trên app bar nhỏ**: dùng `AppBar(title: Text(...))`
  mặc định; nếu tràn trên màn hẹp → giới hạn với ellipsis. Không ngoại lệ kiến trúc.
- **Subtitle "Quản lý Tag" lệch mockup (`#dulich…`)**: cố ý thay mô tả sạch — bắt buộc bởi
  SC-008 (cấm số liệu minh họa); đây là **ngoại lệ có lý do** so với đối chiếu mockup (R4).
- **Vùng `Switch` tắt chức năng (Widget row)**: cần chạm được mở dialog — test bơm tay xác nhận
  switch không đảo và dialog hiện; xử lý bằng bọc InkWell toàn hàng.
- **Bật/tắt nhanh liên tục**: ghi-through không await-giữa-chạm là đủ (spec chỉ cần trạng thái
  cuối đúng); không thêm debounce/queue.
- **Nâng schema v5**: phải chạy `dart run build_runner build` sinh lại `.g.dart`; migration v5
  thuần tạo bảng, không tương tác seed cũ → rủi ro thấp; kiểm tra test `wallets_dao`/
  `transactions_dao` hiện hữu vẫn xanh.
