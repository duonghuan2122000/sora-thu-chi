# Kế hoạch triển khai: Màn hình danh sách danh mục

**Mã PBI**: 13
**Liên kết spec**: .specify/specs/13/spec.md
**Ngày tạo**: 2026-09-05

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x / Flutter stable (máy Windows — theo PBI 1–12) |
| Framework / Thư viện chính | Flutter Material; GetX **chỉ** cho DI repository (`ensureWalletRepository`); màn `StatefulWidget` nạp 1 lần + seam repository inject (pattern PBI 11 `CategoryPickerScreen` / PBI 12 `SearchFilterScreen`); tái dùng `SubPageScaffold`, `AppColors`, `categoryIcon`, widget tab/row theo mockup |
| Lưu trữ dữ liệu | **Không đổi schema** (drift schema v4 giữ nguyên, không chạy `build_runner`); tính năng **chỉ đọc**; thêm 1 method đọc `categoriesIncludingHidden({type})` (interface + `DriftWalletRepository` + fake) — `categories({type})` hiện có giữ nguyên cho picker PBI 11 |
| Kiểm thử | `flutter analyze` sạch + `flutter test`: unit thuần (`category_list`: tách cha cấp 1 + đếm con gồm ẩn + sort ổn định), widget (`category_list_screen`: bố cục mockup 01 + tab Chi tiêu/Thu nhập + dòng icon/tên/dòng phụ/chevron + ẩn + empty + no-op 3 điểm vào + cỡ chữ lớn & safe area; `settings_screen` sửa: thêm hàng "Danh mục" + điều hướng), fake repository (seed danh mục tùy chọn + method mới) |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS widget thuần + không đổi plugin — rủi ro thấp |
| Ràng buộc hiệu năng | SC-001: danh sách hiển thị < 1s với vài trăm danh mục → nạp 2 loại 1 lần khi mở, chuyển tab lọc local (không đọc DB lại, không giật); không cần phân trang |
| Ràng buộc khác | App offline; chỉ sau mở khóa (PBI 3 — không làm thêm). Design system: teal `#0F6E56` tab chọn/hành động, coral chỉ chi tiêu (màn này không tiền); card/dòng theo design doc; màu danh mục là **dữ liệu** `category.color`; app bar teal + back tự động + actions (icon sắp xếp). Màn không số tiền. Tài liệu & commit tiếng Việt có dấu |

*Không còn `NEEDS CLARIFICATION` — spec đã chốt hiển thị & phạm vi đợt này; vị trí hàng Cài đặt chốt trong plan (R9).*

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Danh mục]]/[[Nguyên tắc nghiệp vụ]]/[[Stack kỹ thuật]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | drift SQLite local; không gọi mạng; không thêm dependency |
| Đúng stack đã chốt (drift + GetX), không thêm thư viện | ✅ | Chỉ đọc drift + widget; GetX chỉ DI repo; không package mới |
| Số dư ví là đại lượng suy ra | ✅ | Tính năng **chỉ đọc danh mục** — không đụng `wallets.balance`, không ghi DB |
| Tái dùng hơn viết mới | ✅ | Tái dùng `Category`, `categoryIcon`, `SubPageScaffold`, `ensureWalletRepository`, seam pattern; chỉ thêm module thuần `category_list` + 1 màn + 1 method đọc + 1 hàng Cài đặt |
| Danh mục: 2 cấp cha-con, ẩn giữ lịch sử | ✅ | Màn quản lý hiện **cả ẩn** (không loại khỏi màn quản lý — FR-006); ẩn chỉ rút khỏi picker giao dịch mới (đã đúng ở `categories()`); con ẩn vẫn đếm |
| Danh mục hệ thống không xóa được | ✅ | `is_system` không dùng đợt này (chỉ thể hiện khi xóa — ngoài phạm vi); hiển thị bình thường |
| Mỗi PBI một màn; điểm vào no-op kích hoạt khi tới PBI | ✅ | Màn `01` dựng hiển thị; FAB/dòng/icon sắp xếp no-op — màn đích (thêm/sửa `02`, danh mục con `03`, sắp xếp `04`) PBI sau |
| Design system (teal, bo, không hex cứng, token) | ✅ | Tab chọn teal `AppColors.teal`, tab lặp `AppColors.tabInactive`; FAB `AppColors.teal`; màu danh mục là dữ liệu `category.color` |
| Không số liệu minh họa giả | ✅ | Không thêm seed; "N danh mục con"/tên lấy từ dữ liệu thiết bị (mockup chỉ minh họa) |
| Test không phụ thuộc sqlite native | ✅ | Unit/widget bơm fake `FakeWalletRepository`; repository method mới có test qua widget (không DAO test mới cần drift? cân nhắc — xem Rủi ro) |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **Seam đọc gồm cả ẩn** — thêm `categoriesIncludingHidden({type})` (interface + drift + fake) vì `categories({type})` chỉ trả đang hoạt động (pickers PBI 11) (R1).
- **Không controller** — `CategoryListScreen` StatefulWidget nạp 1 lần trong `initState`, seam `repository` inject như `CategoryPickerScreen`/`SearchFilterScreen`; mỗi lần vào từ Cài đặt push route mới → reload (FR-008) (R2).
- **Nạp cả 2 loại 1 lúc**, chuyển tab lọc local trong memory → thứ tự ổn định, không giật, không đọc DB lại (R3).
- **FAB** = thêm param `floatingActionButton` cho `SubPageScaffold` (cộng thêm 1 dòng, màn phụ tái dùng); FAB `AppColors.teal` icon `+` (R4).
- **Bubble dòng** = nền nhạt phái sinh từ `category.color` (alpha ~0.14 trên trắng) + icon màu đầy đủ `category.color` — bám mockup 01; ẩn → làm mờ + nhãn "Đã ẩn" (R5).
- **Hàng tab tự dựng** (2 nhãn trái + gạch chân teal 3px + vạch chia) thay Material `TabBar` — khớp mockup, dễ test (R6).
- **Đếm con / tách cấp 1** = module thuần `core/category/category_list.dart` + unit test; đếm gồm con ẩn (R7).
- **Điểm vào no-op** — FAB/dòng/icon sắp xếp `onTap`/`onPressed` no-op có ripple, không crash/treo (R8).
- **Cài đặt** — hàng "Danh mục" nhóm KHÁC sau "Quản lý ví" + seam `onManageCategoryTap` (R9).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — **không đổi schema** (v4); domain `Category` dùng lại; seam đọc mới `categoriesIncludingHidden({type})`; projection màn (cấp 1 theo `sortOrder`, "N danh mục con" gồm ẩn, empty thật vs ẩn-toàn-bộ).
- **Hợp đồng giao diện**: **không tạo** `contracts/` — app nội bộ offline, không API/CLI (bám PBI 7–12).
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–G đối chiếu acceptance/FR/SC; QA tay emulator (ẩn chỉ verify qua widget test — chưa tạo ẩn bằng UI).

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Thêm đúng 1 module thuần (`category_list.dart`) + 1 màn (`category_list_screen.dart`) + 1 method đọc + 1 param `SubPageScaffold` + 1 hàng Cài đặt; không service/event bus/controller; **không đổi schema/repository cũ** |
| Đúng seam cho test | ✅ | `CategoryListScreen` nhận `repository` (mặc định `ensureWalletRepository`) — test bơm `FakeWalletRepository` trực tiếp (như `CategoryPickerScreen`); `SettingsScreen` seam `onManageCategoryTap` |
| Không hồi quy PBI 5/6/8/11/12 | ✅ | `categories({type})`, `CategoryPickerScreen`, picker & filter PBI 12 giữ nguyên (không đụng); `SettingsScreen` **thêm** hàng (cập nhật test row-order hiện có + thêm case mới); `SubPageScaffold` chỉ **thêm** param optional — màn cũ không đổi. Chạy lại toàn bộ test xác minh |
| Tái dùng > viết mới | ✅ | `Category`/`categoryIcon`/`SubPageScaffold` (+FAB param)/`ensureWalletRepository`/token màu; pattern row/empty/loading/error bám màn ví & picker |
| "Ẩn giữ lịch sử" / màn quản lý hiện cấu trúc đầy đủ | ✅ | Danh mục ẩn vẫn hiện đúng vị trí (không loại khỏi màn quản lý); con ẩn vẫn đếm; ẩn-toàn-bộ không ra empty giả |
| Chỉ đọc — không làm hỏng dữ liệu | ✅ | Không method ghi, không đổi `Category`; không tạo/mất/sửa danh mục (SC-008) |
| Khóa app không lộ thông tin | ✅ | Màn route trong shell sau boot-gate (PBI 3), không số tiền — không làm thêm |
| Danh mục hệ thống hiển thị bình thường | ✅ | Không đặc quyền ẩn/đổi gì ở đợt này (chỉ khi xóa — ngoài phạm vi) |
| Cập nhật wiki | ⚠️ | PBI 13 chạm entity [[Danh mục]] + concept ẩn/seed — **PBI 11 schema v4 danh mục chưa sync wiki** (memo). Sau implement xong sync wiki (entity `Danh mục`: schema v4, màn quản lý list `01` + điểm vào từ Cài đặt) qua skill `sora-wiki` + `log.md` |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── core/
│   │   ├── category/
│   │   │   └── category_list.dart              # [TẠO] thuần: topLevelParents (isParent, sort sortOrder),
│   │   │                                        #        childrenOf(parent) → đếm gồm con ẩn (R7)
│   │   └── widgets/sub_page_scaffold.dart      # [SỬA] + Widget? floatingActionButton → Scaffold.floatingActionButton
│   ├── data/
│   │   ├── wallet_repository.dart              # [SỬA] + categoriesIncludingHidden({type}) (R1)
│   │   └── wallet_repository_drift.dart        # [SỬA] + impl drift: select categories không lọc is_hidden,
│   │                                             #        lọc type Dart + sort sortOrder (bám categories() hiện có)
│   └── screens/
│       ├── settings_screen.dart                # [SỬA] + hàng "Danh mục" (KHÁC, sau "Quản lý ví") + seam
│       │                                        #        onManageCategoryTap → push CategoryListScreen (R9)
│       └── category_list_screen.dart           # [TẠO] StatefulWidget: repository inject (R2); initState load 2 loại
│                                                 #        (Future.wait expense+income — R3); SubPageScaffold('Danh mục',
│                                                 #        actions: [icon sort no-op]) + floatingActionButton (FAB "+" no-op R8)
│                                                 #        + SafeArea(top:false): loading spinner / error+Thử lại /
│                                                 #        Column [tabs Chi tiêu/Thu nhập (R6) → Expanded(ListView rows) /
│                                                 #        empty state (FR-009) nếu topLevel rỗng]; row: bubble alpha
│                                                 #        + icon màu category.color, tên, dòng phụ "N danh mục con"
│                                                 #        (trống khi không con), chevron; ẩn → nhãn "Đã ẩn" + mờ
│                                                 #        (R5/R7); onTap dòng no-op (R8)
│   └── (không đổi) core/category/category.dart, category_icon.dart, app_database*.dart, wallet_* screens/controller,
│                    transaction_*, add_transaction_screen.dart, category_picker_screen.dart, app_shell.dart
└── test/
    ├── fakes/fake_wallet_repository.dart       # [SỬA] + categoriesIncludingHidden (trả seed không lọc ẩn, sort)
    │                                             #        + optional named List<Category>? categoriesSeed (mặc định
    │                                             #        CategorySource.all) — additive, test cũ không đổi
    ├── category_list_test.dart                 # [TẠO] unit thuần: topLevel chỉ isParent + sort sortOrder; childrenOf
    │                                             #        đếm con (kể cả con ẩn) / không con → 0; không lọc cha ẩn
    ├── category_list_screen_test.dart          # [TẠO] widget fake repo (+seed): bố cục mockup 01 (app bar teal title
    │                                             #        + back + icon sort; tab Chi tiêu chọn teal + underline; không
    │                                             #        bottom nav) (a); mặc định tab Chi tiêu 8 dòng cha + dòng phụ
    │                                             #        "3 danh mục con" của Ăn uống + trống cho không con + chevron (b);
    │                                             #        chuyển tab Thu nhập → chỉ 4 danh mục thu, về lại Chi tiêu giữ
    │                                             #        danh sách (c); danh mục ẩn hiện + nhãn "Đã ẩn"/mờ, ẩn-toàn-bộ
    │                                             #        không empty giả, con ẩn vẫn đếm (d); tab rỗng thật → empty
    │                                             #        hướng dẫn (e); no-op dòng/FAB/icon sort không crash/rời màn (f);
    │                                             #        cỡ chữ lớn + safe area cuộn tới cuối không overflow (g)
    ├── settings_screen_test.dart                # [SỬA] cập nhật số hàng/thứ tự (thêm "Danh mục" sau "Quản lý ví");
    │                                             #        + tap "Danh mục" → push CategoryListScreen (register fake repo
    │                                             #        Get.put) + back; + bơm onManageCategoryTap → callback không push
    └── (không đổi) wallet_*/transaction_*/category_picker_*/add_form/dao/money_format/date_label/pin tests — chạy lại
```

Không đổi: `core/category/category.dart`, `category_source.dart`, `category_icon.dart`, `data/db/app_database.dart` (+`.g.dart`), `wallet_*` screens/controller, màn PIN/boot, `category_picker_screen.dart`, `add_transaction_screen.dart`, `transaction_*`, `app_shell.dart`, `wallet_deps.dart`/`transaction_deps.dart`.

## Rủi ro & ngoại lệ có lý do

- **Nạp 2 loại cả cha-con 1 lần mỗi lần mở (không phân trang)** — cố ý: bảng danh mục nhỏ local (vài trăm), SC-001 < 1s; giữ cache trong vòng đời màn cho chuyển tab ổn định. Ceiling: nếu danh mục phình lớn bất thường → lazy-load/tab; chưa cần (`ponytail:` — thêm khi vượt ~vài nghìn).
- **Chưa QA tay được trạng thái ẩn** (acceptance 4/SC-004) — app chưa có chức năng ẩn danh mục (thuộc PBI thêm/sửa `02`, sau); ẩn chỉ cover bằng widget test (seed fake). Không phải rào cản PBI 13; ghi rõ quickstart G.
- **Hai dòng phụ "Đã ẩn" + "N danh mục con"** — ẩn cha có con sẽ hiển thị gộp trên dòng phụ; composition cụ thể tinh chỉnh lúc thi công, QA visual khi có màn ẩn. Không đổi logic đếm.
- **`SettingsScreen` test hiện có giả định 4 hàng** — thêm hàng → cập nhật test row-order (chủ đích, additive). Không ảnh hưởng màn khác (`widget_test` không liệt kê hàng Cài đặt).
- **`SubPageScaffold` + param mới** — optional, các màn hiện dùng (wallet list/form/transfer, add txn?) không đổi; test chạy lại xác nhận.
- **Fake category seed additive** — mặc định giữ `CategorySource.all` → mọi test cũ (picker PBI 11, filter PBI 12) không đổi hành vi; chỉ case cần ẩn/con lạ bơm seed riêng.
- **iOS chưa verify** (máy Windows): widget thuần + không đổi plugin/native — rủi ro thấp, giữ trạng thái.
- **Wiki chưa sync PBI 11** (schema v4 `Categories`) — tích hợp vào mục sync wiki sau implement PBI 13, không làm trước (spec chỉ đọc, không đổi nghiệp vụ mới ngoài màn quản lý).

## File đã tạo

- `.specify/specs/13/research.md`
- `.specify/specs/13/data-model.md`
- `.specify/specs/13/plan.md`
- `.specify/specs/13/quickstart.md`

Bước tiếp theo: chạy `/sora-task 13` để phân rã thành tasks.md.
