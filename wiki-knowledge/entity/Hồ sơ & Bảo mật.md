---
title: "Hồ sơ & Bảo mật"
date: 2026-09-13
tags: [module, auth, security, pin, entity]
sources:
  - ../docs/auth/chi-tiet-quan-ly-tai-khoan-nguoi-dung.md
  - ../docs/tinh-nang-nghiep-vu-app-quan-ly-thu-chi.md
  - ../docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md
  - ../../.specify/specs/3/spec.md
  - ../../.specify/specs/3/data-model.md
  - ../../.specify/specs/17/spec.md
  - ../../.specify/specs/17/data-model.md
  - ../../.specify/specs/18/spec.md
  - ../../.specify/specs/18/data-model.md
  - ../../.specify/specs/19/spec.md
  - ../../.specify/specs/19/data-model.md
  - ../docs/ai/tinh-nang-quet-hoa-don-ai-local.md
  - ../../.specify/specs/24/spec.md
  - ../../.specify/specs/24/data-model.md
  - ../docs/notification/notification-solution.md
  - ../../.specify/specs/28/spec.md
  - ../../.specify/specs/28/data-model.md
  - ../../.specify/specs/29/spec.md
  - ../../.specify/specs/29/data-model.md
  - ../../.specify/specs/30/spec.md
  - ../../.specify/specs/30/data-model.md
---

# Hồ sơ & Bảo mật

Không phải "tài khoản" server — là **device profile** lưu local. App offline: không đăng ký/đăng nhập/đồng bộ. Gồm: vận hành offline, khóa app (PIN/vân tay/Face ID), hồ sơ cá nhân, đổi/quên PIN.

## Vận hành offline
- Dữ liệu gắn **1 bản cài đặt trên 1 thiết bị**.
- Hệ quả: gỡ app/mất máy = mất dữ liệu nếu không backup thủ công → backup JSON là "van an toàn" duy nhất (xem [[Sao lưu & Khôi phục]], [[Lộ trình phát triển]] GĐ3); **quên PIN không có email/SMS reset** vì không có server.
- ⚠ Onboarding hoàn chỉnh (chọn tiền tệ, tạo ví đầu tiên...) **chưa tồn tại**; khi có, sẽ gắn quanh luồng thiết lập PIN (xem chốt bên dưới).

## Khóa app (App Lock)
> **Chốt PBI 3 (2026-09-03, đã triển khai)** — quyết định user, **lệch `docs/auth §2.1`** (vốn "bật/tắt tùy chọn"): khóa app = mã PIN **bắt buộc ngay lần đầu mở app**, luôn có hiệu lực đợt này (không có luồng tắt). `docs/auth` chưa đồng bộ → nguồn thô cần cập nhật theo sau.

**Thiết lập lần đầu (bắt buộc):**
- Lần đầu mở app trên thiết bị chưa có PIN → màn thiết lập đứng **độc lập trước mọi nội dung** (chưa có Onboarding hoàn chỉnh); không nút bỏ qua/back.
- Nhập PIN rồi **xác nhận lại lần 2**; chỉ kích hoạt khi khớp (FR-002). Lệch → báo lỗi, nhập lại từ đầu, **chưa ghi gì**; thoát app giữa chừng chưa khớp → lần sau vẫn bắt thiết lập (SC-006).
- Vừa thiết lập xong trong phiên → **không hỏi lại ngay**; khóa có hiệu lực từ lần vào app sau.

**Quy tắc PIN:**
- **4 số cố định** đợt này, mỗi ký tự hiện **chấm tròn, không lộ chữ số** (FR-003). Chọn độ dài 4/6 = đợt sau.
- Chuỗi dễ đoán (`0000`, `1111`, `1234`, `4321`) → **cảnh báo** nhưng cho dùng nếu user xác nhận "Tiếp tục" (không chặn cứng).
- Lưu: **hash SHA-256 có muối** (salt 16B ngẫu nhiên, gói `crypto`) — chuỗi `"{saltB64}.{hashB64}"` ở key `pin_salt_hash` của `flutter_secure_storage` (Keychain/Keystore); **không lưu PIN đọc được** (FR-011). Trạng thái chống dò lưu key riêng `lock_state` (JSON: `streak`, `lockUntilEpochMs`), **độc lập dữ liệu tài chính** (không phải entity drift).

**Luồng mở khóa (khi đã có PIN):**
- Mỗi lần **khởi động app** và mỗi lần **trở về từ nền** → màn khóa **toàn màn hình** chặn trước mọi nội dung (không app bar/bottom nav — [[Design system]]), không lộ nội dung tài chính phía sau (SC-002).
- Nhập đúng → vào **đúng màn đang đứng trước khi khóa**, không reset về màn đầu (FR-007).
- Nhập sai → báo chung **"mã PIN không đúng"** (không tiết lộ ký tự nào đúng/sai), xóa ký tự vừa nhập, cho nhập lại (FR-008).
- Back/back-gesture tại màn khóa & màn thiết lập **không thoát được** (FR-010); ngoài phạm vi luồng này: đổi PIN, quên PIN, tắt khóa, tự khóa theo timeout.

**Chống brute-force (chốt):**
- Chỉ tính khi gõ **đủ 4 số** rồi sai; sửa giữa chừng bằng backspace không tính.
- Sai **5 lần liên tiếp** → chặn **30s**; tái phạm (chưa có lần đúng xen giữa) tăng bậc **30s → 1p → 5p → 15p (trần)**; nhập đúng → đếm về 0 (FR-009/SC-004).
- Thời gian chặn còn lại **giữ nguyên khi thoát app** (lưu `lock_state`); hết chặn chỉ mở lại nhập, **không tự mở khóa**.
- Không bật mặc định "xóa trắng dữ liệu sau N lần sai" (rủi ro mất dữ liệu tài chính) — ngoài đợt.
- Rủi ro "đổi giờ hệ thống né chặn": chấp nhận (offline 1 thiết bị, không phải đối thủ chủ động).

**Sinh trắc học (vân tay/FaceID):**
- **Đợt sau (PBI riêng)** — lớp "tiện lợi" thay thế trên nền PIN (PIN vẫn là lớp gốc). Numpad hiện **để trống** vị trí vân tay (hàng cuối trái).
- Khi có: thu hồi quyền (OS) → tự tắt toggle, yêu cầu bật lại bằng PIN; đổi vân tay đăng ký → vô hiệu hóa sinh trắc tạm thời, xác thực lại bằng PIN.

## Màn Tiện ích & Cá nhân hóa (danh sách) — đã triển khai PBI 17, dọn PBI 45
> **PBI 17 (2026-09-06)**: dựng **màn danh sách** gom điểm vào tùy chỉnh theo mockup `docs/tool/01-danh-sach-tien-ich.svg`. Entry: Cài đặt nhóm **KHÁC → "Tiện ích & Cá nhân hóa"** (ngay dưới "Danh mục"), `SubPageScaffold` app bar teal + back + tiêu đề, không bottom nav. Nguồn đặc tả `.specify/specs/17`.
> **PBI 45 (2026-09-17)**: ẩn hẳn 3 hàng chưa có tính năng thật (`Định dạng & Tiền tệ`, `Tìm kiếm toàn cục`, `Quản lý Tag`) khỏi màn — mockup gốc vẽ chevron cho cả 8 hàng nhưng 3 hàng này chạm vào không làm gì, gây cảm giác lộn xộn (rà soát `docs/ra-soat-nhat-quan-giao-dien.md` §2). Nguồn đặc tả `.specify/specs/45`.

**Bố cục hiện tại — 2 nhóm / 5 hàng** (nhóm DỮ LIỆU & TÌM KIẾM đã ẩn hoàn toàn vì rỗng), mỗi hàng vòng nền nhạt (`tealLightBg`) + icon **teal** + tên + dòng phụ + phần cuối:
- **HIỂN THỊ** — Giao diện (dòng phụ "Sáng / Tối / Theo hệ thống", trailing "Sáng/Tối/Theo hệ thống" ▸), Ngôn ngữ (trailing endonym hiện hành "Tiếng Việt"/"English" ▸).
- **TRẢI NGHIỆM** — Widget màn hình chính (switch hiển thị **"bật" câm**, chạm toàn hàng → **dialog hướng dẫn ghim widget theo nền tảng** — ghim do OS quản lý, trạng thái **không lưu**; coi là hành vi thật nên **giữ nguyên**, không thuộc diện ẩn PBI 45); **Ẩn số dư (Privacy mode)** switch thật (mặc định **tắt**); **Máy tính khi nhập số tiền** switch thật (mặc định **bật**).

**2 công tắc thật nhớ trạng thái** qua bảng drift key-value **`AppSettings` (schema v5)** — key `hideBalance` / `amountCalculatorEnabled`; **key vắng = mặc định domain**, row chỉ ghi khi bật/tắt (write-through). Hiệu ứng chức năng **chưa kéo** (che số dư `••••••`, đổi bàn phím nhập tiền = PBI sau — xem [[Ví & Tài khoản]]). Cấu trúc: domain thuần `UtilitiesPrefs` (`toSettings`/`fromSettings` an toàn, không ném) + hằng khóa + seam `UtilitiesStore` (load/save) + `DriftUtilitiesStore` + `ensureUtilitiesStore()` (GetX singleton, bám `ensureWalletRepository`); test bơm `FakeUtilitiesStore`. Hàng **"Giao diện" đã kích hoạt ở PBI 18** và hàng **"Ngôn ngữ" đã kích hoạt ở PBI 19** (xem 2 mục dưới). `Định dạng & Tiền tệ`, `Tìm kiếm toàn cục`, `Quản lý Tag` **ẩn khỏi UI từ PBI 45** — khi implement tính năng thật ở PBI sau, chỉ cần đưa hàng trở lại hiển thị (không đổi cấu trúc store/schema). PBI cài đặt sau **chỉ thêm row**, không thêm migration.

## Màn "Giao diện" (02) — đã triển khai PBI 18
> **PBI 18 (2026-09-06)**: hàng "Giao diện" màn `01` bỏ no-op → **push màn con `02`**; chọn sáng/tối/theo hệ thống áp **ngay toàn app**, nhớ qua restart. Nguồn đặc tả `.specify/specs/18`, mockup `docs/tool/02-giao-dien.svg`.

**Màn `02`** (`ThemeScreen`, màn con shell): `SubPageScaffold` app bar teal + back + tiêu đề "Giao diện", **không** bottom nav. Thân `ListView` gồm **3 card đúng thứ tự Sáng – Tối – Theo hệ thống** (mockup): mỗi hàng = vòng nền nhạt + icon minh họa (mặt trời / mặt trăng / thiết bị), tên đậm + dòng phụ mô tả (`Nền trắng, chữ tối` / `Nền tối, chữ sáng, đỡ mỏi mắt ban đêm` / `Tự đổi theo cài đặt điện thoại`), cuối hàng **radio tự dựng** (không `RadioListTile`). Hàng đang chọn **tô nền nhạt** + vòng icon **viền teal**; chân màn ghi chú "Thay đổi được áp dụng ngay lập tức, không cần khởi động lại ứng dụng.".

**Trạng thái & lưu trữ:** 3 lựa chọn ánh xạ thẳng `ThemeMode` của Flutter (`light`/`dark`/`system`) — **không tạo enum riêng** (1 nguồn duy nhất xuyên suốt). Lưu **1 row `('themeMode', 'light'|'dark'|'system')`** trong bảng key-value **`AppSettings` v5** (không migration, không seed — row ghi write-through khi user chọn). **Key vắng = mặc định "Theo hệ thống"**; chuỗi ngoài 3 giá trị hợp lệ → cũng về `system` (parse an toàn, không ném). Tên hiển thị thống nhất: `light`→"Sáng", `dark`→"Tối", `system`→**"Theo hệ thống"** (màn `01` bỏ nhãn cũ "Hệ thống").

**Hàng "Giao diện" màn `01`:** phần cuối **reactive** đọc controller → hiện đúng "Sáng"/"Tối"/"Theo hệ thống", cập nhật ngay kể cả khi vừa đổi ở màn `02` rồi back (màn `01` vẫn mounted dưới route).

**Cơ chế dark mode toàn app:** `ThemeController` (GetX) giữ `Rx<ThemeMode>`, đăng ký ở gốc `SoraApp` (bám `PinController`) và nạp lựa chọn đã lưu lúc `initState`; `GetMaterialApp` nhận `theme` + `darkTheme` + `themeMode` → chọn một hàng là **cả cây rebuild tức thì**, không restart. Chi tiết token màu & rule light/dark ở [[Design system]]; seam/DI ở [[Stack kỹ thuật]]. "Theo hệ thống" tự đổi khi điện thoại đổi sáng/tối nhờ chính `ThemeMode.system` của Material (không tự viết observer `didChangePlatformBrightness` như doc §1.2 gợi ý).

## Màn "Ngôn ngữ" (03) — đã triển khai PBI 19
> **PBI 19 (2026-09-10)**: hàng "Ngôn ngữ" màn `01` bỏ no-op → **push màn con `03`**; chọn ngôn ngữ áp **ngay toàn app** (không restart), nhớ qua lần mở sau. Nguồn đặc tả `.specify/specs/19`, mockup `docs/tool/03-ngon-ngu.svg`, tài liệu giải pháp `docs/tool/giai-phap-tien-ich-ca-nhan-hoa.md §2`.

**Phạm vi đợt này = dịch toàn bộ nhãn giao diện tĩnh của mọi màn hiện có** (không dịch dần từng đợt). 2 ngôn ngữ: **Tiếng Việt (mặc định)** và **English** — *không* có lựa chọn "theo ngôn ngữ hệ thống" (khác theme PBI 18).

**Màn `03`** (`LanguageScreen`, màn con shell): `SubPageScaffold` app bar teal + back + tiêu đề "Ngôn ngữ", **không** bottom nav. Thân `ListView` **2 card đúng thứ tự Tiếng Việt → English**: vòng tròn mã `VI`/`EN` + **tên ngôn ngữ (endonym)** đậm + **dòng phụ là tên ngôn ngữ kia** (`Tiếng Việt`/`Vietnamese`, `English`/`Tiếng Anh`) + **radio tự dựng**; hàng đang chọn nền nhạt + viền teal; chân màn ghi chú "Áp dụng ngay cho toàn bộ giao diện, nhãn danh mục mặc định và định dạng ngày/số vẫn giữ theo cài đặt Định dạng & Tiền tệ.". **4 chuỗi tên/dòng phụ là hằng số cố định** (tên riêng của ngôn ngữ, không đi qua bản đồ dịch — chốt theo mockup); chỉ tiêu đề app bar + ghi chú mới dịch.

**Hàng "Ngôn ngữ" màn `01`:** phần cuối **reactive** (Obx) hiện endonym đúng lựa chọn hiện hành, cập nhật ngay kể cả khi vừa đổi ở màn `03` rồi back (màn `01` vẫn mounted dưới route).

**Lưu trữ:** **1 row `('locale', 'vi'|'en')`** trong bảng key-value **`AppSettings` v5** (không migration, không seed — ghi write-through khi user chọn); **row vắng = mặc định `vi`**; chuỗi lạ → cũng về `vi` (parse an toàn, không ném). **Độc lập** với `themeMode`/2 công tắc: ghi chỉ upsert đúng key `locale`, không xoá row khác.

**Cơ chế i18n & đổi ngôn ngữ tức thì:** xem [[Stack kỹ thuật]] §Đa ngôn ngữ — tóm tắt: **khóa dịch = chính chuỗi tiếng Việt đang hiển thị**, bản đồ chỉ có nhánh `'en'`; thiếu nhánh/thiếu khóa/`Get.locale == null` ⇒ `.tr` trả lại khóa. **Chỉ đổi `locale:` trên `GetMaterialApp` là KHÔNG đủ** — route đang mở không tự rebuild (đo thực nghiệm), nên `LocaleController.setLocale` gọi thêm `Get.updateLocale()` (reassemble toàn cây, giữ state + stack điều hướng); chỉ gọi khi giá trị thật sự đổi. Thêm `flutter_localizations` (chỉ SDK, không package bên thứ ba) + 3 delegate chuẩn để hộp thoại/date picker hệ thống theo ngôn ngữ.

**Không đổi theo ngôn ngữ** (tách bạch, §2.2 tài liệu): **định dạng ngày (`dd/MM/yyyy`) và số tiền (`42.500.000 đ`)** — vẫn theo cài đặt Định dạng & Tiền tệ (PBI sau). **Không dịch dữ liệu người dùng**: tên giao dịch, ghi chú, tag, **tên ví** (kể cả ví mẫu `Tiền mặt`/`Vietcombank`/`Thẻ tín dụng VIB`/`Sổ tiết kiệm` — **chốt: coi là dữ liệu, KHÔNG dịch**), tên danh mục tự tạo/đã đổi tên. Riêng **tên danh mục mặc định chưa đổi tên** *có* dịch — quy tắc ở [[Danh mục]]. DB **không đổi** bất kỳ bản ghi nào khi đổi ngôn ngữ.

## Mục Cài đặt "QUÉT HÓA ĐƠN AI" + kiểm tra cấu hình máy (PBI 24 chặng 1 + chặng 2)
> **PBI 24 (2026-09-13)**: nhóm Cài đặt cho tính năng quét hóa đơn (mockup `docs/ai/scan-11-settings-ai-status.svg`) + màn kiểm tra cấu hình máy (`scan-10`). Nguồn đặc tả `.specify/specs/24/`. Chặng 1 = luồng quét + bộ luật + khối Cài đặt; **chặng 2 = AI nâng cao Tier A/B** (cùng ngày) — trạng thái trung gian "Chưa khả dụng trong bản này" đã **gỡ**.

**Nhóm Cài đặt `scan-11`** — đọc `ScanController` qua `Obx` nên **đổi công tắc ở đây phản ánh ngay vào sheet FAB** (cùng một `Rx`):
- **"Quét hóa đơn bằng AI"** — công tắc thật bật/tắt tính năng (mặc định **tắt**; tắt ⇒ sheet FAB **không hiện** hàng "Quét hóa đơn (AI)").
- **"Trạng thái AI"** — tier đã đo + model đang dùng (`Gemini Nano (Tier A)` / `Gemma 3n E2B (Tier B)` / **"Chế độ cơ bản"** khi chưa đo hoặc Tier C).
- **"Lần kiểm tra gần nhất"** — mốc thời gian, chưa đo ⇒ "Chưa kiểm tra".
- **"Dung lượng model"** *(chỉ hiện khi đã tải model Tier B)* — dung lượng thật đang chiếm (`1.8 GB`).
- **"Xoá model"** *(chỉ hiện khi đã tải model)* — xoá khỏi máy rồi tự về **Chế độ cơ bản**; **giao dịch đã lưu không bị ảnh hưởng**.
- **"Kiểm tra lại cấu hình máy"** và **"Kiểm tra cập nhật model"** — cùng đẩy sang màn `scan-10` (đo lại; nếu Tier B thiếu model thì cho tải lại).

**Lưu trữ — 4 row trong bảng key-value `AppSettings`** (PBI 17): `scanEnabled`, `scanEngineMode`, `scanModelBytes` (dung lượng model Tier B đã tải), `scanDeviceCheck` (JSON kết quả đo). Ghi write-through **chỉ 4 key của mình** — không xoá `themeMode`/`locale`/2 công tắc Tiện ích. **Key vắng = mặc định an toàn** (tắt / Chế độ cơ bản / 0 / chưa kiểm tra), chuỗi lạ hoặc JSON hỏng ⇒ về mặc định, **không ném**. `AppSettings` **vẫn schema v5, không migration** — schemaVersion **v8** của DB đến từ `transactions.source` + bảng `scan_sessions` ([[Giao dịch]]).

**Màn kiểm tra cấu hình máy `scan-10`** (`docs/ai/scan-10-device-check.svg`): app bar teal + back; **4 mục đo** — Bộ nhớ RAM · Dung lượng trống · Hỗ trợ AI trên máy (AICore) · Phiên bản hệ điều hành — mỗi mục hiện giá trị + **Đạt/Không đạt**; **đúng một thẻ kết quả** theo tier đo được (nêu rõ tiêu chí chưa đạt) + nút **"Kiểm tra lại"** chạy lại đo.

**Phân loại tier (ngưỡng đóng, doc §11.2)**: **A** = thiết bị có AICore/Gemini Nano của hệ thống (dùng ngay); **B** = RAM ≥ **4GB** **và** dung lượng trống ≥ **2GB** **và** chip có đường tăng tốc; **C** = còn lại ⇒ **Chế độ cơ bản**. Kết quả **chỉ để chọn chế độ**, không cam kết chất lượng; **Tier C không bao giờ chặn luồng quét** (emulator luôn Tier C).

**Thời điểm đo & tái sử dụng**: lần **vào luồng quét** gọi `needsDeviceCheck()` → chưa từng đo **hoặc** kết quả **quá 30 ngày** mới đẩy màn `scan-10`; mở luồng lần sau **không** chạy lại. Người dùng chọn dùng tiếp ở màn đó ⇒ vào màn chụp bình thường.

**Chọn chế độ ở thẻ kết quả (chặng 2)**:
- **Tier A** — nút **"Kích hoạt Gemini Nano"**: model do AICore hệ thống quản lý, **không tải gì** ⇒ bật là dùng được ngay.
- **Tier B** — nút **"Tải model (1.8GB) qua Wifi"** có **tiến trình %**, kèm lựa chọn **"Dùng chế độ cơ bản"** (huỷ tải). **Tải xong mới bật** Gemma 3n; tải **thất bại/bị huỷ ⇒ không bật AI**, người dùng ở lại Chế độ cơ bản (FR-012) — nút đổi thành "Thử lại" kèm thông báo.
- **Tier C** — nút "Dùng chế độ cơ bản".

**Chọn engine thật khi quét**: Tier B **chỉ chạy khi `modelBytes > 0`** (đã tải xong) — chưa tải thì tự rơi về Chế độ cơ bản thay vì gọi model không tồn tại. Chi tiết fallback + engine ghi vào phiên quét: [[Giao dịch]].

> **⚠ QUYẾT ĐỊNH MỞ — nguồn phân phối model Tier B**: repo HuggingFace đang trỏ tới (`kGemmaModelUrl`) là **gated**, cần token ⇒ lượt tải sẽ thất bại và người dùng ở lại Chế độ cơ bản (an toàn, không vỡ luồng). Phải chốt nguồn công khai (tự host / repo không gated) **trước khi phát hành** Tier B. Xem [[Lộ trình phát triển]].

## Màn "Thông báo & nhắc nhở" — đã triển khai PBI 28
> **PBI 28 (2026-09-13)**: dựng **màn cấu hình thông báo** theo mockup `docs/notification/01-cai-dat-thong-bao.svg`. Điểm vào: Cài đặt nhóm **KHÁC → "Thông báo & nhắc nhở"** (**ngay sau** "Tiện ích & Cá nhân hóa"), `SubPageScaffold` app bar teal + back, **không** bottom nav/FAB. Nguồn đặc tả `.specify/specs/28/`, nghiệp vụ gốc `docs/notification/notification-solution.md` (§2 bảng 5 loại). Đây là **màn cài đặt đầu tiên của module Nhắc nhở (GĐ2)**.

**Bố cục — 5 nhóm / 8 hàng**, mỗi hàng vòng tròn `36px` + icon + tiêu đề + **dòng phụ đọc từ cấu hình đã nạp** (không hằng cứng trong widget):
- **NHẮC NHỞ HÀNG NGÀY** — *Nhắc nhập giao dịch hằng ngày* (**công tắc**, mặc định **bật**).
- **NGÂN SÁCH** — *Cảnh báo vượt ngân sách* (**công tắc**, bật) + *Ngưỡng cảnh báo* (**chevron**).
- **GIAO DỊCH ĐỊNH KỲ** — *Nhắc hóa đơn sắp đến hạn* (**công tắc**, bật) + *Nhắc trước* (**chevron**).
- **MỤC TIÊU TIẾT KIỆM** — *Nhắc đóng góp mục tiêu* (**công tắc**, **tắt** — công tắc duy nhất mockup vẽ ở trạng thái tắt).
- **TỔNG KẾT TỰ ĐỘNG** — *Tổng kết cuối tuần* + *Tổng kết cuối tháng* (**2 công tắc**, bật).

Bất biến hàng: mỗi hàng có **đúng một** điều khiển — tổng **6 công tắc + 2 chevron**, không hàng nào có cả hai, không hàng nào trống.

**Mặc định (FR-008)**: nhắc hàng ngày **20:30** + cờ **"chỉ nhắc nếu chưa ghi"** bật; ngưỡng **80%/100%**; nhắc trước **3 ngày**; tổng kết tuần/tháng **Chủ nhật / ngày cuối tháng lúc 20:00**; mọi loại bật **trừ** nhắc đóng góp mục tiêu.

**Quyết định phạm vi đợt này — màn cài đặt KHÔNG kèm engine (chốt Q1/Q2/Q3 = 1A/2A/3A, 2026-09-13):**
- **Q1=A — không có engine bắn thông báo**: đợt này **chỉ ghi nhận cấu hình**. **Không** xin quyền thông báo, **không** bắn thông báo nào, không có channel/lịch/chống trùng. Việc bắn + quyền + màn `02`–`04` của doc + **Trung tâm thông báo** đều **ngoài phạm vi** — xem [[Lộ trình phát triển]].
- **Q2=A — 2 hàng chevron chạm không mở gì**: *Ngưỡng cảnh báo* và *Nhắc trước* có phản hồi mực nhưng **0** màn mới, **0** thông báo lỗi, **0** khung "sắp có". Đây là **điểm nối** cho PBI chỉnh tham số sau (tiền lệ "điểm vào no-op" PBI 13/17).
- **Q3=A — 2 nhóm chưa có module vẫn là công tắc thật**: MỤC TIÊU TIẾT KIỆM (module GĐ3 chưa tồn tại) và GIAO DỊCH ĐỊNH KỲ lưu được **y như mọi hàng**, **không** lộ "chưa hỗ trợ", **không** vô hiệu hoá công tắc.

**Lưu trữ — 1 row JSON `notificationPrefs` trong bảng key-value `AppSettings` v5** — **16 trường** (`dailyEnabled/dailyHour/dailyMinute/dailyOnlyIfNoTxnToday`; `budgetEnabled/budgetEarlyPercent/budgetOverPercent`; `recurringEnabled/recurringDaysBefore`; `goalEnabled`; `weeklyEnabled/weeklyHour/weeklyMinute`; `monthlyEnabled/monthlyHour/monthlyMinute`) gói **nguyên khối** bằng `jsonEncode` (tiền lệ `scanDeviceCheck` PBI 24). **Schema giữ v8** — không migration, không `build_runner`, **không thêm dependency**. Ghi **upsert đúng 1 row**, không xoá `themeMode`/`locale`/2 công tắc Tiện ích/4 khoá quét.
- **Ghi bộ mặc định ngay lần mở đầu**: màn `load()` rồi `save()` luôn khối vừa đọc (idempotent) ⇒ máy chưa từng cấu hình vẫn **có row ngay**, không chờ người dùng thao tác. Đọc-rồi-ghi cũng **chuẩn hoá** giá trị lạ về miền hợp lệ. DB **không seed** row này (chỉ màn mới tạo).
- **Parse tolerant, không bao giờ ném**: row vắng / JSON hỏng (rác, `null`, mảng) → **cả bộ mặc định**; từng trường sai kiểu hoặc ngoài miền (giờ ∉ 0–23, phút ∉ 0–59, % ∉ 0–100, ngày ∉ 0–30) → **mặc định của riêng trường đó**. DB là dữ liệu người dùng — hỏng không được làm trắng màn.
- **Tắt một loại không reset tham số của loại đó** (`copyWith` chỉ chạm trường được truyền) ⇒ bật lại đọc ra **đúng** giờ/ngưỡng/số ngày cũ; **tắt cả 6** vẫn là cấu hình hợp lệ, không giá trị nào tự bật lại. **Không có công tắc "bật/tắt tất cả"**.

**Kiến trúc code** (khuôn PBI 17): domain thuần `NotificationPrefs` (bất biến, `copyWith`, `toSettings`/`fromSettings` + `defaults`) ở `lib/core/notification/`; seam `NotificationStore` (load/save); `DriftNotificationStore` + `ensureNotificationStore()` (GetX singleton — **1** connection drift trên file sqlite); test bơm `FakeNotificationStore`. Màn là `StatefulWidget` + seam store, **không** GetX controller; **ghi bám đuôi** `_saveTail` để bật/tắt liên tiếp không bị save cũ đè save mới.

**Lệch doc đã ghi nhận (có lý do):**
- **Không dựng bảng `NotificationRule`/`NotificationLog`** như `docs/notification/notification-solution.md §3.1`: cả hai phục vụ **engine** (lịch, chống bắn trùng qua `lastFiredAt`) và **Trung tâm thông báo**. *(Cập nhật PBI 30: bảng lịch sử **đã** ra đời — nhưng tên là **`notifications`**, 7 cột phẳng, **không** `payload` JSON; xem mục "Trung tâm thông báo" bên dưới. `NotificationRule` vẫn chưa dựng — thuộc engine.)* Khi engine ra đời, row `notificationPrefs` là nguồn để migrate.
- **Không lưu** ~~"các ngày trong tuần" của nhắc hàng ngày~~ (**đã bổ sung ở PBI 29** — khoá `dailyWeekdays`, xem mục dưới), **chu kỳ + mốc % của mục tiêu** (là cấu hình **per-mục-tiêu** thuộc module GĐ3, không phải cấp màn), **thứ của tổng kết tuần** (mockup cố định Chủ nhật), ngưỡng riêng từng ngân sách. Thêm trường sau này **không phá** dữ liệu cũ nhờ parse tolerant.
- **Đường kẻ giữa các hàng** chỉ kẻ **trong** nhóm (khuôn màn Tiện ích) — mockup vẽ 4 đường không nhất quán; không bám lỗi đồ hoạ.

## Màn `02` "Nhắc nhập giao dịch" — đã triển khai PBI 29
> **PBI 29 (2026-09-13)**: dựng **màn cấu hình nhắc hàng ngày** theo mockup `docs/notification/02-cau-hinh-nhac-nhap-giao-dich.svg` (doc §3.1 `config.weekdays`, §4 mockup `02`). `SubPageScaffold` app bar teal + back, **không** bottom nav/FAB; `bottomNavigationBar` chỉ ghim nút **"Lưu thay đổi"**. Kế thừa PBI 28 (row `notificationPrefs` + seam `NotificationStore`). **Vẫn không có engine**: 0 plugin, 0 quyền, 0 lịch (FR-014/SC-009).

**Điểm vào — hai vùng chạm trên MỘT hàng** (FR-001): hàng "Nhắc nhập giao dịch hằng ngày" ở màn `01` nay **mở màn `02`** khi chạm **cụm icon + tiêu đề + dòng phụ**; **công tắc nằm ngoài** mọi `InkWell` ⇒ chạm công tắc **không** mở màn. Hệ quả đã chấp nhận: 2 hàng chevron (vẫn no-op) mất phản hồi mực ở đúng icon chevron. **Hàng này KHÔNG thêm chevron** (mockup `01` giữ nguyên).

**Bố cục màn `02` — 3 nhãn nhóm + 1 hàng công tắc + nút Lưu**:
- **THỜI GIAN NHẮC** — khối nền `softCardBg` bo `10` chứa **2 trục** giờ/phút ngăn bởi `:`; mỗi trục = **mũi tên ▲/▼ + lân cận trên + giá trị đang chọn (nền teal alpha 0.10, chữ 26px `tealOnNeutral`) + lân cận dưới**; mũi tên đổi **±1** và **quay vòng** `%24`/`%60` (23↔00, 00↔59). **Không** dùng trục cuộn quán tính/`showTimePicker`.
- **LẶP LẠI VÀO CÁC NGÀY** — **7 chip tròn `36px`** T2→CN trong `Wrap`: chọn = nền `AppColors.teal` + chữ trắng; không chọn = nền `colors.surface` + viền `divider` + chữ `tabInactive`. Nhãn chip **clamp cỡ chữ ≤1.4×** để 7 chip đủ chỗ một hàng ở 360px.
- *(hàng công tắc)* — "Chỉ nhắc nếu chưa ghi giao dịch" + dòng phụ mô tả; **đúng 1 công tắc** trên màn (màn `02` **không** có công tắc bật/tắt loại nhắc — việc đó vẫn ở màn `01`).
- **XEM TRƯỚC THÔNG BÁO** — thẻ bo `10` viền `divider`: vòng `28px` `tealLightBg` + chữ `'S'` + "Sora Thu Chi" (không dịch) + câu nội dung + **giờ góc phải** đọc **trực tiếp từ bản nháp** ⇒ đổi ngay cùng nhịp chạm mũi tên.

**Ngữ nghĩa ghi — bản nháp, chỉ ghi khi bấm Lưu** (FR-007/SC-014, chốt Q2=A): mở màn **chỉ đọc** (`load()`, **không** ghi lại như màn `01` — không cần seed); mọi thao tác chỉ đổi `_draft`; **back bỏ thay đổi, 0 hộp thoại hỏi lại**; bấm Lưu mới `save(_draft)` rồi pop (lỗi ghi bỏ qua, vẫn pop — đồng bộ cách chịu lỗi màn `01`); bấm Lưu khi không đổi gì vẫn pop, không thông báo. Về màn `01` có **đọc lại** store để dòng phụ phản ánh giá trị vừa lưu.

**Lưu trữ — vẫn 1 row JSON `notificationPrefs`, nay 17 khoá** (thêm `dailyWeekdays`; 16 khoá cũ **không đổi** miền/mặc định) — **schema giữ v8**, không migration, không `build_runner`, 0 dependency. `dailyWeekdays`: `List<int>`, **1 = Thứ Hai … 7 = Chủ Nhật** (ISO, tuần bắt đầu Thứ Hai — đồng bộ ngân sách/báo cáo), **khác rỗng, đã sắp tăng, không trùng**.
- **Parse tolerant** (không bao giờ ném): thiếu khoá / sai kiểu → **cả 7 ngày**; list rỗng / toàn phần tử sai (ngoài 1…7, `null`, số thực, chuỗi) → **cả 7 ngày**; **lọc bỏ** phần tử lạ, bỏ trùng, **sắp tăng**; ghi ra **không bao giờ** là `[]`. Row cũ PBI 28 (thiếu khoá) đọc ra **đủ 7 ngày** mà **không mất** giờ/cờ ⇒ không cần code migrate.
- **Bất biến "luôn ≥1 ngày" đặt ở tầng MODEL** (FR-009): `toggleDay(d)` — tắt ngày **bật cuối cùng** → trả về **chính object cũ** (`identical`), 0 thay đổi ⇒ **không tồn tại trạng thái 0 ngày** ở mọi đường ghi (màn hôm nay, engine/backup sau này). Thêm `isEveryDay` (đủ 7 ngày) và `isDayEnabled`.
- **Dòng phụ màn `01` nay theo tập ngày** (FR-011): đủ 7 ngày → giữ nguyên chuỗi cũ **"@giờ mỗi ngày"**; thiếu ngày → **"@giờ vào @ngày"**, `@ngày` **nén dải liên tiếp dài ≥3** (`[1..6]` → `T2–T7`, `[1,2,3,5]` → `T2–T4, T6`) và **Chủ Nhật luôn liệt kê riêng** (`[1..7]` → `T2–T7, CN`). Hậu tố " · chỉ nhắc nếu chưa ghi" giữ nguyên. Hai hàm thuần dùng chung cho **cả hai màn**: `dayLabel(int)` + `daysLabel(List<int>)` ở `lib/core/date_label.dart`; nhãn ngày viết **literal trước `.tr`** để test dịch còn ràng buộc (`T2`…`CN` → `Mon`…`Sun`).

**Lệch so với plan/kế hoạch kỹ thuật (có lý do, đã kiểm chứng bằng test)**:
1. **Điều hướng bằng `Navigator.push`/`pop`**, không `Get.to`/`Get.back` như plan viết — repo **không** dùng `Get.to` ở bất kỳ màn nào (GetX chỉ dùng cho state/DI/i18n) và test pump `MaterialApp` thường (không `GetMaterialApp`).
2. **Thêm bước đọc lại store khi về màn `01`** (`_openDailyConfig` await push rồi `load()` im lặng) — plan không nói, nhưng nếu không thì dòng phụ màn `01` giữ giá trị cũ sau khi Lưu (kịch bản 13/14 của spec đòi hiện giá trị mới ngay).
3. **Chủ Nhật không gộp vào dải nén** — phép nén "dải liên tiếp ≥3" thuần sẽ cho `[1..7]` → `T2–CN`; chốt theo đúng ví dụ của spec là `T2–T7, CN` (tuần đọc `T2…T7` + `CN`).
4. **Khối thời gian bọc `FittedBox(scaleDown)`** — bề rộng 2 trục là cố định theo mockup nên ở cỡ chữ hệ thống 2.0 sẽ tràn ngang (`RenderFlex overflowed by 89 pixels`); thu nhỏ cả khối giữ đúng bố cục (FR-017).
5. **Không dựng bảng `NotificationRule`** — giữ nguyên quyết định PBI 28 (bảng đó phục vụ engine, ngoài phạm vi); `dailyWeekdays` **chính là** `config.weekdays` của doc nhưng nằm trong row JSON đã có.

**Kiểm thử**: 1 file test mới (`daily_reminder_config_screen_test` 17 ca: bố cục, mũi tên ±1/quay vòng, chip, bản nháp–Lưu–back, nhánh lỗi, English, cỡ chữ 2.0@360×640) + sửa 4 file (`notification_prefs_test` +6 nhóm luật tập ngày, `date_label_test` +2 nhóm nhãn ngày, `notification_settings_screen_test` +7 ca hai vùng chạm/dòng phụ, `dark_theme_smoke_test` +1 màn 02). **`flutter analyze` sạch; 1052 pass + 1 test đỏ CÓ SẴN** `transactions_dao_test` (PBI 11) — baseline PBI 28 là 1004 pass, **số đỏ không tăng**.

**QA tay trên emulator nhóm A–M ĐÃ ĐẠT** (2026-09-13) — người dùng chạy theo `.specify/specs/29/quickstart.md` §2 (hai vùng chạm; đối chiếu mockup `02`; mũi tên quay vòng + xem trước tức thì; chip ngày & chip cuối không tắt được; bản nháp–Lưu–back; DB cũ **thiếu khoá** `dailyWeekdays`; dòng phụ nén dải; **0 thông báo & 0 lần hỏi quyền**; không ảnh hưởng dữ liệu/loại nhắc khác; English; theme Tối; cỡ chữ lớn/màn hẹp). **iOS chưa QA** (PBI không đụng native/config ⇒ Android là đủ).

## Trung tâm thông báo (màn `03`) — đã triển khai PBI 30
> **PBI 30 (2026-09-13)**: dựng **màn đọc lịch sử thông báo** theo mockup `docs/notification/03-trung-tam-thong-bao.svg` (doc §3.1 `NotificationLog`, §5 điểm vào "biểu tượng chuông ở màn hình Tổng quan"). Nguồn đặc tả `.specify/specs/30/`. Điểm vào: **chuông ở vùng tiêu đề màn Tổng quan** (không phải Cài đặt), `SubPageScaffold` app bar teal + back + **bánh răng**, **không** bottom nav/FAB (FR-002).

**Màn `03`** — 2 tab lọc **"Tất cả" / "Chưa đọc"** + danh sách nhóm theo thời gian **HÔM NAY / TUẦN NÀY / TRƯỚC ĐÓ**, mục = chấm teal 8px (chỉ khi chưa đọc) + vòng tròn 36px theo loại + tiêu đề + dòng mô tả + nhãn thời gian; **2 trạng thái rỗng khác câu** (rỗng chung vs tab "Chưa đọc" rỗng); bánh răng → màn `01` (PBI 28). Token/hình ở [[Design system]].

**Luật nghiệp vụ đã chốt (chốt Q1/Q2/Q3 = 1A/2A/3A, 2026-09-13):**
- **Q1=A — đợt này KHÔNG có engine ghi lịch sử** ⇒ trên máy thật bảng `notifications` **luôn rỗng**, màn ở trạng thái rỗng. PBI này bàn giao **điểm nối** (`append`) cho engine sau. Đây là **hành vi đã chốt, không phải lỗi**; QA nhóm có dữ liệu phải **chèn tay** vào DB theo quickstart §1.2.
- **Q2=A — không thao tác hàng loạt**: **không** nút "đánh dấu tất cả đã đọc", **không** xoá một mục, **không** xoá lịch sử. Thao tác đọc **duy nhất** = **chạm vào mục**.
- **Q3=A — trần lưu 200 mục gần nhất** (`kMaxNotifications = 200`, **hằng số**, không phải cấu hình người dùng); vượt trần → mục **cũ nhất tự bị dọn** theo `created_at` (khoá phụ `id` cho tất định), **không hỏi, không báo**, áp dụng **bất kể đã đọc hay chưa**.

**Chạm một mục (FR-007/FR-008, thứ tự bắt buộc):** đánh dấu **đã đọc trước** (lưu bền), **rồi** mới điều hướng theo loại — nhờ vậy loại **chưa có màn đích** vẫn được đánh dấu, chỉ là không đi đâu:
| Loại | Đích |
|---|---|
| `dailyReminder` | màn **Thêm giao dịch** (mặc định tab Chi) |
| `budgetAlert` | màn **Chi tiết ngân sách** theo `relatedId`; **thiếu `relatedId` ⇒ không điều hướng** (ngân sách đã xoá thì màn đích tự hiện "Danh mục đã bị xóa") |
| `periodSummary` | `popUntil(isFirst)` rồi đổi **tab Báo cáo** của shell (qua `onSelectTab`) |
| `recurringDue`, `goalReminder` | **im lặng**: 0 route, 0 SnackBar, 0 khung "sắp có" (module đích chưa tồn tại) |

**Trạng thái đã đọc — một chiều, gắn với BẢN GHI (không theo loại):** 2 bản ghi cùng loại đọc độc lập; `readAt` chỉ chuyển `null → giá trị`, không bao giờ ngược và **không bị ghi đè** (cưỡng chế trong câu SQL ở [[Stack kỹ thuật]]); lưu **bền** qua đóng app/khởi động lại thiết bị. Màn **chỉ** đọc + cập nhật `read_at` của bảng `notifications`: **0** ghi vào `wallets`/`transactions`/`categories`/`budgets`/`appSettings`, **0** đổi cấu hình màn `01`/`02` (FR-012).

**Chấm đỏ trên chuông Tổng quan (FR-001, SC-013):** chấm hiện ⟺ **có ≥1 mục chưa đọc**; lịch sử rỗng/lỗi đọc ⇒ **không chấm** (lỗi đọc **nuốt**, `_unread = 0`, không crash); chuông **luôn** bấm được; chấm cập nhật **ngay khi quay về** màn Tổng quan (đếm lại **sau** `await Navigator.push`, không đếm trước). State **cục bộ** ở `DashboardScreen` — **không** GetX controller, **không** stream (trạng thái chỉ đổi được ở màn Trung tâm, mà màn đó mở từ chính nó).

**Không làm (ngoài phạm vi):** engine bắn thông báo (PBI sau); `flutter_local_notifications`/`timezone`/quyền/channel (vẫn **0 plugin thông báo**, FR-013); màn `04` mẫu thông báo đẩy; đọc-tất-cả/xoá/ghim/tìm kiếm trong lịch sử/màn chi tiết một thông báo; **seed dữ liệu mẫu trong app** (spec cấm); đưa lịch sử vào backup/restore JSON (GĐ3); widget màn hình chính ([[Lộ trình phát triển]]).

**Lệch doc đã ghi nhận (có lý do):**
1. **Bảng thật là `notifications`, không phải `NotificationLog`** của doc §3.1 — 7 cột **phẳng** (`kind` + `title` + `body` + `created_at` + `read_at?` + `related_id?`), **không** cột `payload` JSON: đích điều hướng do `kind` quyết định nên chỉ cần mang **một** id. `kind` lưu `.name` (quy ước repo: `TxnSource.manual/aiScan`, `ScanEngine`), khác snake_case của doc. **Vẫn không dựng `NotificationRule`** (thuộc engine).
2. **"TUẦN NÀY" = 7 ngày gần nhất** (cuốn theo **ngày lịch**), **không** cắt theo tuần lịch bắt đầu Thứ Hai — spec §Giả định định nghĩa đúng như vậy; cắt theo tuần lịch thì mục **hôm qua** rơi vào "TRƯỚC ĐÓ" khi hôm nay là Thứ Hai. Mục **8 ngày** trước ⇒ TRƯỚC ĐÓ (khác cách đếm của ngân sách/báo cáo).
3. **Nhãn thời gian trong ngày là giờ TUYỆT ĐỐI `HH:mm`**, mockup vẽ "2 giờ trước" — spec §Giả định chốt cố ý (dễ đọc, dễ kiểm thử, mockup không nhất quán giữa các mục). Nhãn 1…7 ngày dùng **tên thứ đầy đủ** ("Thứ Năm"), không dùng `dayLabel` viết tắt (`T5`).
4. **Chấm trên chuông dùng `AppColors.coral` + viền trắng**, không phải đỏ tươi — xem ngoại lệ ở [[Design system]].
5. **`DashboardScreen` đổi từ `StatelessWidget` (khung rỗng) sang `StatefulWidget`** để giữ `_unread`; `AppShell` bơm thêm `onSelectTab` xuống màn Tổng quan (khuôn đang bơm cho màn Báo cáo).
6. **Nâng schema v8 → v9** (bảng mới `notifications`) ⇒ phải sửa `schemaVersion` ở **4 file test drift cũ** — bắt buộc, chỉ đổi con số khẳng định.

**Kiểm thử**: 3 file test mới (`app_notification_test` 15 ca hàm thuần; `notification_history_store_drift_test` 8 ca — **chạy thật trên drift in-memory**, không skip: trần 200, thứ tự, một chiều, không đụng bảng khác; `notification_center_screen_test` 19 ca màn) + 1 fake mới + sửa 6 file (`widget_test` +5 ca chuông/chấm, `dark_theme_smoke_test` +1, 4 file drift đổi version). **`flutter analyze` sạch; 1100 pass + 1 test đỏ CÓ SẴN** (`transactions_dao_test`, PBI 11) — baseline PBI 29 là 1052 pass, **số đỏ không tăng**.
> **QA tay trên emulator nhóm A–N ĐÃ ĐẠT** (2026-09-13) — người dùng chạy theo `.specify/specs/30/quickstart.md` §2, gồm cả nhóm có dữ liệu **chèn tay** vào DB theo §1.2 (app **không** có cơ chế seed). PBI 30 **hoàn tất 32/32 task**. **iOS chưa QA** (PBI **0** plugin native mới, chỉ thêm bảng sqlite ⇒ rủi ro thấp).

## Engine thông báo đẩy — đã triển khai PBI 31
> **PBI 31 (2026-09-13)**: **đóng mục ⚠ "engine bắn thông báo"** treo từ PBI 28. Nguồn đặc tả `.specify/specs/31/`; nghiệp vụ gốc `docs/notification/notification-solution.md` (§1 **không FCM** · §2 bảng 5 loại + tần suất + deep link · §3.2 cơ chế lên lịch · §3.3 quyền & giới hạn nền tảng) + mockup `04-mau-thong-bao-day.svg`. Spec chốt **Q1=A · Q2=C · Q3=A**. **0 màn mới** — đợt này chỉ thêm hạ tầng + 1 dòng trạng thái ở màn `01`.

**"Thông báo đẩy" ở app này = thông báo do CHÍNH THIẾT BỊ sinh ra** — app offline hoàn toàn, **không FCM**, **không server**, **0 lời gọi mạng** (FR-001/FR-031): `flutter_local_notifications` + `timezone` + `flutter_timezone` (3 dependency **đầu tiên kể từ PBI 27**; `timezone` là **bắt buộc đi kèm** — thiếu `flutter_timezone` thì `tz.local` mãi là **UTC** ⇒ nhắc 20:30 bắn lúc 3:30 sáng).

**3 loại có engine** (đúng Q1=A; 2 loại chưa có module — `recurringDue` hóa đơn định kỳ, `goalReminder` mục tiêu tiết kiệm — **không bao giờ** xuất hiện trong sổ):
| Loại | Khi nào | Chống trùng | Đích khi chạm |
|---|---|---|---|
| **Nhắc nhập giao dịch hằng ngày** | đúng **giờ:phút** đã cấu hình (màn `02`), **chỉ ngày trong tuần đã chọn** | 1 lần/ngày (khoá `daily:<yyyy-MM-dd>`) | màn **Thêm giao dịch** |
| **Cảnh báo ngân sách** | **ngay** sau khi lưu giao dịch **Chi** chạm ngưỡng (sớm/`budgetEarlyPercent`, vượt mức/`budgetOverPercent` — **đọc từ cấu hình**, không hard-code) | **1 lần/ngưỡng/ngân sách/kỳ** (khoá `budget:early\|over:<id>:<đầu kỳ>`) | màn **Chi tiết ngân sách** theo `relatedId` |
| **Tổng kết tuần / tháng** | Chủ Nhật `<giờ>` / **ngày cuối tháng** `<giờ>` (đúng **28/29/30/31**) | 1 lần/tuần, 1 lần/tháng (khoá mang kỳ) | tab **Báo cáo** (chọn sẵn kỳ vừa tổng kết) |

**Vì sao lịch nhắc hàng ngày là "một-lần cho từng mốc trong cửa sổ 30 ngày" (chứ không lặp vô hạn):** plugin **không huỷ được một mốc** của lịch lặp ⇒ cờ "**chỉ nhắc nếu chưa ghi**" (điều kiện chỉ lật được khi app đang mở) **không thể** thực hiện. Vì vậy mỗi mốc là một lịch riêng, cuốn lại mỗi lần app chạy; huỷ đúng mốc hôm nay + **đánh dấu chặn** khi người dùng vừa ghi giao dịch. **Hệ quả đã ghi nhận**: người dùng **không mở app > 30 ngày** thì hết nhắc (đây là người dùng đã bỏ app). Tổng kết tuần/tháng chỉ đăng ký **một mốc kế tiếp**, **nội dung tính lại mỗi lần app chạy** (số liệu + câu so sánh phải tươi).

**Cơ chế "GHI BÙ" bản ghi Trung tâm (điểm kỹ thuật cốt lõi):** hệ điều hành **không chạy Dart** khi app đóng ⇒ không thể vừa bắn vừa ghi. Thiết kế: **bảng sổ `notification_ledger`** (schema **v10**, 9 cột, `entry_key` = khoá chính, **thuần tạo — không seed**) ghi mốc **dự kiến**; mốc bắn lúc app đóng nằm lại trong sổ dưới dạng "**còn nợ bản ghi**"; lần mở app kế tiếp, `reconcile()` ghi bù vào `notifications` với **`created_at = mốc bắn** (không phải giờ mở app) ⇒ nhãn thời gian, nhóm ngày, chấm đỏ **quan sát được là như nhau**. Đổi lại **không** cần tiến trình nền (giữ FR-022) — phương án `workmanager`/`android_alarm_manager_plus` bị **loại có ghi nhận**.
- Sổ làm **3 việc** (không dựng bảng thứ hai): chống bắn trùng · biết mốc nào còn nợ bản ghi · tra ngược `history_id` để `markRead` khi chạm.
- **Khoá mang KỲ** ⇒ chống trùng **không vĩnh viễn**: sang kỳ mới (tháng mới, tuần mới, ngày mới) tự do báo lại.
- **Id thông báo hệ điều hành = FNV-1a 32-bit** của khoá, **tự viết** (`String.hashCode` **không** ổn định giữa các bản SDK, mà id phải tra lại đúng lịch sau khi khởi động lại). Cùng khoá ⇒ cùng id ⇒ thông báo **thay thế**, không xếp chồng.
- Dọn sổ: xoá dòng `scheduled_for < now − 90 ngày` **đã xử lý xong**; dòng **còn nợ không bao giờ bị xoá** (mất dấu = mất bản ghi).

**Không bắn bù mốc đã trôi qua (FR-028)** — cửa sổ chỉ chứa mốc **tương lai**: DB cũ nâng cấp (sổ rỗng), khởi động lại thiết bị, vừa bật công tắc, hay rời màn liên quan đều **không** dội thông báo cho quá khứ.

**Q3=A — "không bắn khi đang ở đúng màn liên quan" (FR-016):**
- **Cảnh báo ngân sách**: đang mở Chi tiết **đúng ngân sách đó** ⇒ **bỏ qua hoàn toàn** (0 thông báo, 0 bản ghi, **0 dòng sổ**). Đang ở Chi tiết ngân sách **khác** hoặc màn khác ⇒ **vẫn bắn**.
- **Tổng kết**: đang ở **tab Báo cáo** ⇒ **huỷ mốc rơi vào ĐÚNG NGÀY HÔM NAY** + chặn (mốc duy nhất có thể bắn trong lúc đang xem); rời tab ⇒ cuốn lịch lại nhưng mốc **đã trôi qua không ghi bù**, mốc tuần/tháng sau được đăng ký lại. **Cố ý KHÔNG chặn mốc ở tương lai xa hơn**: mốc cùng khoá đã bị chặn thì lần cuốn sau **bỏ qua**, nên chặn cả mốc tuần sau sẽ khiến **chỉ cần ghé tab Báo cáo một lần là mất luôn tổng kết tuần này**. *(Xem lệch 7 bên dưới: "đang ở màn Báo cáo" suy từ **tab đang chọn**, không từ vòng đời widget.)*

**Quyền thông báo (Q2=C) — màn `01`:**
- **Soft-ask MỘT LẦN** ở lần mở **đầu tiên**: hiện **lời giải thích trong app** (đồng ý / không đồng ý) **trước**; **chỉ** khi đồng ý mới gọi hộp thoại xin quyền của hệ điều hành; **dù kết quả nào cũng không hỏi lại** (cờ `notificationPermissionAsked` = row `AppSettings` riêng — **không** nằm trong khối JSON `notificationPrefs`, **không cần migration**). **Không** có màn onboarding mới, **không** hỏi ở màn `02`.
- **Dòng trạng thái quyền**: quyền **bị tắt** ⇒ màn `01` có **đúng một** dòng + nút mở cài đặt hệ điều hành, mọi công tắc/giá trị **giữ nguyên**; quyền đã cấp ⇒ **0** dòng thừa (đúng mockup `01`). Dòng này **không** dùng coral (không phải ngữ cảnh chi tiêu/cảnh báo số liệu).
- **Exact alarm**: khai `USE_EXACT_ALARM` (app phát hành qua **GitHub Releases**, không qua Play ⇒ ràng buộc chính sách Play không áp dụng) và **lùi về lịch inexact** khi `canScheduleExactNotifications() == false` — plugin khi bị từ chối **im lặng** (không báo lỗi) nên nếu không kiểm, thông báo **mất âm thầm**.

**Nội dung thông báo là SNAPSHOT theo ngôn ngữ LÚC BẮN** (FR-027, đồng bộ PBI 30): engine sinh câu chữ theo ngôn ngữ hiện hành rồi lưu **nguyên văn** vào sổ + `notifications`; **không** `.tr` lại khi hiển thị — nên bản ghi cũ giữ đúng ngôn ngữ lúc bắn. Câu chữ bám mockup `04` (có **số liệu cụ thể**: tên danh mục, %, kỳ, số tiền), "**sắp vượt**" vs "**đã vượt**" **phân biệt được bằng chữ**, và khi cờ "chỉ nhắc nếu chưa ghi" **tắt** thì câu chữ **không** khẳng định "hôm nay chưa ghi".

**Điểm nối (mỗi chỗ 1 dòng, fire-and-forget):** 3 đường lưu giao dịch (thêm giao dịch · xác nhận hóa đơn quét · chuyển khoản nội bộ) gọi engine **không `await`**, lỗi **nuốt bên trong engine** ⇒ lưu giao dịch **không** chậm/không đỏ vì thông báo (FR-024/SC-012). Cảnh báo ngân sách **chỉ** chạy khi giao dịch vừa lưu là **Chi** — nhưng **chuyển khoản VẪN** tính là "hôm nay đã ghi giao dịch" cho cờ nhắc hàng ngày (transfer không vào ngân sách nhưng là bằng chứng người dùng đã mở app ghi chép). Sửa cấu hình ở màn `01`/`02` ⇒ `onPrefsChanged()` ⇒ **hiệu lực ngay**, không cần mở lại app.

**Engine CHỈ ĐỌC dữ liệu nghiệp vụ** (FR-023/SC-013): mọi phép tính **tái dùng nguyên hàm** của module Ngân sách (`budgetPeriodRange`/`budgetScopeCategoryIds`/`budgetSpent`) và Báo cáo (`reportComparison` + câu insight ⇒ luật "kỳ trước rỗng ⇒ bỏ câu so sánh, không chia 0" **miễn phí**) — **không** viết lại phép lọc. Engine **chỉ GHI** 3 chỗ: **sổ** `notification_ledger` (bảng của chính PBI này) · **`notifications`** (bảng PBI 30, qua đúng `append`/`markRead`) · **1 row** `notificationPermissionAsked`. **0** ghi vào `wallets`/`transactions`/`categories`/`budgets`/`appSettings` (có test drift khẳng định 6 bảng nghiệp vụ nguyên vẹn).

**Không làm (ngoài phạm vi):** màn `03`–`04` của doc (đích 2 hàng chevron no-op) · engine cho `recurringDue`/`goalReminder` (chưa có module) · widget màn hình chính · đưa lịch sử vào backup JSON (GĐ3) · cơ chế chạy nền/isolate.

**Lệch có chủ ý đã ghi nhận (7 — đầy đủ ở `.specify/specs/31/quickstart.md` §5):**
1. **Bản ghi Trung tâm ghi BÙ** ở lần mở app kế tiếp (R0: hệ điều hành không chạy Dart) — `created_at` = mốc bắn nên quan sát được là như nhau.
2. **Cửa sổ 30 ngày** cho nhắc hàng ngày (cái giá bắt buộc để huỷ được đúng một mốc).
3. **Nội dung tổng kết tươi theo lần mở app cuối** — để app đóng suốt cả kỳ thì tổng kết kỳ đó có thể không bắn.
4. **Exact alarm lùi inexact** ⇒ lịch inexact có thể lệch vài phút so với AC#1.
5. **Engine không phân biệt được "hệ điều hành giết lịch" với "quyền bị chặn"** — cả hai đều sinh bản ghi (đúng FR-004 cho ca quyền bị chặn; ca giết lịch **có lợi** cho người dùng vì vẫn xem lại được).
6. **Chạm tổng kết TỪ TRUNG TÂM không chọn sẵn kỳ** — bảng `notifications` không mang thông tin tuần/tháng; chỉ chạm **thông báo hệ điều hành** (payload = khoá `summary:week:`/`summary:month:`) mới `setPeriod` trước khi mở tab Báo cáo.
7. **"Đang mở màn Báo cáo" suy từ TAB đang chọn, không từ vòng đời widget** — màn Báo cáo sống trong `IndexedStack` nên **mọi** tab được dựng từ lúc boot, `initState` không phản ánh việc người dùng đang nhìn nó. Vì vậy `AppShell._onTabSelected` khai báo/ngưng hiện diện `'report'` và gọi `onEnterRelatedScreen`/`onLeaveRelatedScreen` (thay cho việc bọc `ReportScreen` thành `StatefulWidget` như plan dự kiến).

**Cấu hình native lần đầu sau PBI 25 (R14)** — 4 thứ, thiếu cái nào cũng hỏng **âm thầm**: **core library desugaring** ở `build.gradle.kts` (FLN v10+ **bắt buộc**; thiếu là **đỏ build release ngay**) · **3 quyền** + **2 receiver** ở `AndroidManifest.xml` (thiếu `ScheduledNotificationBootReceiver` là **mất TOÀN BỘ lịch** sau khi khởi động lại thiết bị — Android xoá mọi alarm khi reboot) · **3 vector drawable đơn sắc** làm icon nhỏ (Android **buộc** icon nhỏ là drawable đơn sắc, không dùng `Icons.*`/ảnh launcher) · `ios/Runner/AppDelegate.swift` đặt `UNUserNotificationCenter.delegate` (thiếu ⇒ thông báo **không hiện khi app đang mở**). **3 kênh Android** (`sora_daily`/`sora_budget`/`sora_summary`) — coral **chỉ** ở cảnh báo ngân sách.

**Kiểm thử**: **5 file test mới** (`notification_schedule_test` 19 ca hàm thuần; `notification_content_test` 11 ca câu chữ vi+en; `notification_engine_test` 53 ca — 3 nhóm US1/US2/US3 + điều hướng + trần 200 **chạy thật trên drift**; `notification_ledger_drift_test` 10 ca) + **2 fake mới** (`FakeNotificationLedger`, `FakeNotificationPresenter`) + sửa `notification_settings_screen_test` (+7 ca US4), 5 file drift đổi `schemaVersion` 9→10, `FakeNotificationStore` thêm 2 hàm. **`flutter analyze` sạch; 1200 pass + 1 test đỏ CÓ SẴN** (`transactions_dao_test`, PBI 11) — baseline PBI 30 là 1100 pass, **số đỏ không tăng**.
- **Hai seam mới là điều kiện để test được**: `NotificationPresenter` (bọc hệ điều hành) + `NotificationLedger` (bọc sổ) ⇒ **toàn bộ** luật nghiệp vụ (sinh lịch, huỷ khi đã ghi, hoà giải ghi bù, chống bắn bù, lỗi không làm hỏng lưu, chống trùng theo kỳ, Q3) kiểm được **không cần plugin/thiết bị**.
- **Bẫy đã gặp**: (a) **tên lớp trùng** — bảng drift cũng tên `NotificationLedger` như seam ⇒ file impl phải `import 'db/app_database.dart' hide NotificationLedger`; (b) **`AndroidNotificationChannel` không có tham số `color`** ở FLN v22 (màu coral đặt ở `AndroidNotificationDetails.color`, tức theo **thông báo** chứ không theo kênh); (c) **soft-ask làm đỏ 21 test cũ** của màn `01` (hộp thoại chặn thao tác chạm công tắc) ⇒ `FakeNotificationStore.asked` mặc định **`true`** ("đã hỏi rồi"), test nào muốn kiểm lần mở đầu thì truyền `asked: false`; (d) `reconcile()` cuốn **cả 3 loại** ⇒ assertion kiểu `ledger.all()` / `history.stored` phải **lọc theo `kind`**, không khẳng định cả sổ.
> **⚠ QA TAY NHÓM A–P CHƯA CHẠY** — `.specify/specs/31/quickstart.md` §2 (16 nhóm, kèm 6 lệnh `adb`/`sqlite3` kiểm lịch/quyền/sổ **không phải chờ tới giờ**). **BẮT BUỘC gỡ app rồi cài lại** trước nhóm B (bẫy PBI 24/27: bản cài cũ thiếu plugin native ⇒ "0 thông báo, không lỗi" — **dữ liệu cũ sẽ mất**, ghi lại số liệu đối chiếu trước). **iOS chưa QA** (đợt này **có** cấu hình native).

## Hồ sơ cá nhân
| Trường | Chốt |
|---|---|
| Avatar | Ảnh từ thư viện/chụp, hoặc chữ viết tắt tên mặc định |
| Tên hiển thị | Tự do; chào mừng — không định danh/đăng nhập |
| Tiền tệ mặc định | Áp dụng ví mới + tổng hợp báo cáo đa ví; đổi **không hồi tố** tiền tệ ví đã tạo |
| Múi giờ | Gán ngày/giờ gd mới + mốc "đầu ngày/đầu tháng tài chính" |

⚠ QUYẾT ĐỊNH MỞ: đổi múi giờ khi đang có chuỗi định kỳ đã lên lịch → có tính lại thời điểm sinh gd tiếp theo không (auth doc §3).

## Đổi / quên PIN
- **Đổi** (còn nhớ): Cài đặt → Đổi mã PIN → xác thực PIN cũ (hoặc sinh trắc) → nhập/xác nhận PIN mới → lưu.
- **Quên PIN** — 2 hướng chưa chốt:
  - **A** (giữ dữ liệu): reset qua câu hỏi bảo mật đã đặt, hoặc khôi phục từ file JSON backup sau khi cài lại.
  - **B** (ưu tiên bảo mật): không đường vòng — mất PIN = xóa data + cài lại, khôi phục backup nếu có.
  - ⚠ QUYẾT ĐỊNH MỞ: doc nghiêng về **B** kèm khuyến khích backup định kỳ — cần chốt ở giai đoạn thiết kế.

## Bảo mật mở rộng (mục 13 tính năng tổng)
- Mã hóa dữ liệu local (SQLite/Hive mã hóa); không lưu số thẻ/ngân hàng thật (chỉ nhãn tham chiếu).
- Privacy mode: ẩn số dư màn chính (che `••••••`) — công tắc "Ẩn số dư" **đã lưu được** (PBI 17, `AppSettings` v5); hiệu ứng che ở các màn có số tiền là PBI sau — liên kết [[Ví & Tài khoản]].
- Yêu cầu sinh trắc trước khi xem/sửa dữ liệu nhạy cảm (tùy chọn).

## Màn hình bảo mật (khác biệt với shell)
- Khóa PIN / sinh trắc: **toàn màn hình, độc lập hoàn toàn** khỏi app shell — chạy trước khi vào app (PBI 3: cổng boot nền trung tính làm `home`, đẩy setup/lock trước nội dung để không flash data).
- Numpad: lưới `3×4`, nút tròn ~48–52px, viền mảnh `#E0E0E0`, không nền; hàng cuối: trái = **để trống** (vị trí vân tay, chưa có sinh trắc đợt này), giữa `0`, phải backspace. Dot indicator ~12px: đặc teal = đã nhập, rỗng xám = chưa.

## Liên kết
- [[Design system]] — màn bảo mật tách shell; numpad & dot PIN — phong cách numpad còn dùng ở màn xác nhận quét hóa đơn/khoảng số tiền lọc, nhưng màn Thêm giao dịch đã đổi sang bàn phím hệ thống (PBI 38, [[Giao dịch]]).
- [[Ví & Tài khoản]] — tiền tệ mặc định cấp ví mới; Privacy mode; tên ví **không** dịch theo ngôn ngữ.
- [[Ngân sách]] — tiền tệ mặc định & kỳ tài chính lệch bắt nguồn từ hồ sơ.
- [[Stack kỹ thuật]] — cơ chế i18n GetX Translations + `flutter_localizations` (PBI 19); seam quét hóa đơn + kênh native `device_probe` (PBI 24).
- [[Giao dịch]] — công tắc ở đây quyết định hàng "Quét hóa đơn (AI)" có hiện ở sheet FAB hay không.
- [[Danh mục]] — quy tắc dịch **tên danh mục mặc định** ở tầng hiển thị.
- [[Lộ trình phát triển]] — phụ thuộc backup GĐ3; PIN khóa app thuộc MVP.
- [[Design system]] — token màn Trung tâm (chấm 8px, vòng 36px, 2 tab tự vẽ, ngoại lệ chấm coral trên chuông).
