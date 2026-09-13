# Khởi động nhanh & kiểm thử tay: Trung tâm thông báo trong app (màn `03`)

**Mã PBI**: 30
**Liên kết**: [spec.md](./spec.md) · [plan.md](./plan.md) · [data-model.md](./data-model.md) · [research.md](./research.md)
**Ngày tạo**: 2026-09-13

---

## 1. Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get            # KHÔNG có dependency mới — không sửa pubspec.yaml
dart run build_runner build --delete-conflicting-outputs   # sinh lại app_database.g.dart (schema v9)
flutter analyze            # phải sạch
flutter test               # mốc trước PBI: 1052 pass + 1 test đỏ CÓ SẴN (xem §5)
flutter run                # chọn emulator/máy thật
```

> ⚠ **Đợt này màn Trung tâm ra đời mà chưa có engine ghi lịch sử** (Q1=A) ⇒ trên
> máy thật bảng `notifications` **luôn rỗng**: QA tay trên máy chỉ kiểm được
> **trạng thái rỗng + điểm vào + điều hướng + giao diện**. Mọi kịch bản cần **có
> dữ liệu** (đọc/chưa đọc, nhóm thời gian, lọc tab, trần 200) kiểm bằng **test tự
> động** (§3) hoặc bằng cách **chèn dòng thủ công vào DB** (§1.2).

**Trạng thái cần có để QA đủ nhóm**:

| Thứ cần có | Cách tạo | Dùng cho nhóm |
|---|---|---|
| App vừa cài, **lịch sử rỗng** | `flutter run` trên máy đã gỡ app (hoặc xoá dữ liệu app) | B, C, D |
| **Lịch sử có sẵn** (tuỳ chọn, xem §1.2) | Chèn dòng vào bảng `notifications` | E…J |
| 1 ngân sách + vài giao dịch Chi | Nhập tay (tab Báo cáo → Ngân sách) | H (đích điều hướng cảnh báo) |
| Ngôn ngữ = **English** | Cài đặt → Tiện ích & Cá nhân hóa → Ngôn ngữ | L |
| Giao diện = **Tối** | Cài đặt → Tiện ích & Cá nhân hóa → Giao diện | M |
| Cỡ chữ hệ thống = **lớn nhất** | Cài đặt hệ điều hành → Cỡ chữ | N |
| Mockup để đối chiếu | Mở `docs/notification/03-trung-tam-thong-bao.svg` | C |

### 1.2. (Tuỳ chọn) Chèn lịch sử mẫu để QA tay nhóm E–J

Chỉ làm được trên **build debug** (`flutter run`) + máy có `adb` + `sqlite3` trên host.
App **không** có cơ chế seed trong app (spec §Giả định) nên đây là cách duy nhất.

```bash
PKG=com.sorathuchi.sora_thu_chi
# 1) kéo DB ra host (`getApplicationDocumentsDirectory()` → app_flutter/sora_thu_chi.sqlite)
adb exec-out run-as $PKG cat app_flutter/sora_thu_chi.sqlite > sora.sqlite

# 2) chèn vài dòng (kind = dailyReminder | budgetAlert | recurringDue | goalReminder | periodSummary)
#    created_at là DateTime của drift → drift lưu bằng **số giây** unix (không phải mili-giây)
sqlite3 sora.sqlite "
INSERT INTO notifications (kind, title, body, created_at, read_at, related_id) VALUES
 ('dailyReminder','Nhắc ghi chép hôm nay','Bạn chưa ghi giao dịch nào hôm nay', strftime('%s','now'), NULL, NULL),
 ('budgetAlert','Sắp vượt ngân sách Ăn uống','Đã dùng 82% ngân sách tháng này', strftime('%s','now') - 7200, NULL, 1);"

# 3) đẩy lại + mở lại app
adb push sora.sqlite /data/local/tmp/sora.sqlite && \
  adb shell "run-as $PKG sh -c 'cat /data/local/tmp/sora.sqlite > app_flutter/sora_thu_chi.sqlite'"
```

**Xong QA thì xoá dữ liệu mẫu** (giữ đúng nghiệp vụ máy thật = lịch sử rỗng):
`adb shell pm clear $PKG` (xoá sạch dữ liệu app) hoặc `DELETE FROM notifications;`.

---

## 2. Kịch bản kiểm thử tay

### Nhóm A — Điểm vào & chấm đỏ trên chuông (FR-001, SC-002, SC-013)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| A1 | Mở app ở màn **Tổng quan** | Vùng tiêu đề teal có **biểu tượng chuông** ở góc phải (ô nút tròn 48 px), **không** chấm đỏ khi lịch sử rỗng |
| A2 | Chạm chuông (đúng **1** lần chạm) | Màn **Thông báo** mở ra; app bar teal có **nút back**, tiêu đề "Thông báo", **icon bánh răng** góc phải; **không** bottom nav, **không** FAB |
| A3 | Chạm back | Quay lại màn **Tổng quan**, chuông vẫn bấm được |
| A4 | (§1.2 có ≥1 mục **chưa đọc**) Mở lại màn Tổng quan | Chuông có **chấm đỏ nhỏ viền trắng** góc trên-phải |
| A5 | Vào Trung tâm, chạm mục **chưa đọc cuối cùng**, back về Tổng quan | Chấm **biến mất**; mục vừa chạm vẫn đã đọc |
| A6 | Chạm chuông khi **lịch sử rỗng** | Màn Trung tâm vẫn mở bình thường (không vô hiệu hoá, không lỗi) |

### Nhóm B — Trạng thái rỗng (FR-011, SC-007)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| B1 | Lịch sử rỗng → mở Trung tâm | Biểu tượng trung tính + "**Chưa có thông báo nào**" + 1 dòng phụ giải thích; **không** danh sách, **không** nhãn nhóm, **không** lỗi, **không** nút "sắp có" |
| B2 | Ở trạng thái rỗng, chuyển sang tab "**Chưa đọc**" | Vẫn là câu **của trạng thái rỗng chung** (lịch sử rỗng), **không** nhãn nhóm |
| B3 | (§1.2 có dữ liệu, **mọi mục đã đọc**) sang tab "Chưa đọc" | Câu **riêng**: "**Không có thông báo chưa đọc**" — **khác** câu ở B1 |

### Nhóm C — Đối chiếu mockup `03` (FR-002, FR-004, FR-005, SC-001)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| C1 | (§1.2 có dữ liệu) mở Trung tâm, đối chiếu `03-trung-tam-thong-bao.svg` | App bar teal 64 px (back + "Thông báo" + bánh răng); dưới app bar là **2 tab** trên nền sáng |
| C2 | Tab "Tất cả" (đang chọn) | Chữ **teal** w600 + **gạch chân 2 px teal** ngay dưới chữ; tab "Chưa đọc" màu xám; có đường kẻ mờ chạy ngang dưới hàng tab |
| C3 | Nhãn nhóm | `HÔM NAY` / `TUẦN NÀY` / `TRƯỚC ĐÓ` viết hoa, cỡ nhỏ, màu **mờ** (khác tiêu đề mục); nhóm **không có mục** thì **không** hiện nhãn |
| C4 | Một mục | Chấm teal 8 px (chỉ khi chưa đọc) → vòng tròn 36 px nền nhạt + icon → tiêu đề đậm + dòng mô tả → nhãn thời gian góc phải, cùng hàng với tiêu đề |
| C5 | Mục **đã đọc** vs **chưa đọc** | Chưa đọc: có chấm + tiêu đề **đậm, màu chữ chính**, mô tả màu chữ phụ; Đã đọc: **không** chấm + tiêu đề nhạt hơn, mô tả mờ hơn (khác biệt **cả** chấm **lẫn** độ đậm/màu — không chỉ màu) |
| C6 | Đường kẻ giữa các mục | Có, màu mờ, **thụt lề 20 px** hai bên (giống mockup) |
| C7 | Icon theo loại | nhắc nhập giao dịch → **chuông**; cảnh báo ngân sách → **cảnh báo** trên nền **coral nhạt**; định kỳ → **lịch**; mục tiêu → **bullseye**; tổng kết → **biểu đồ tròn**. Coral **chỉ** xuất hiện ở loại cảnh báo ngân sách |

### Nhóm D — Đọc / chưa đọc & lọc tab (FR-003, FR-007, FR-009, SC-005, SC-006)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| D1 | Chạm một mục **chưa đọc** | Mục **mất chấm** + tiêu đề chuyển sắc mờ; **và** app mở màn hình liên quan (xem nhóm H) |
| D2 | Back về Trung tâm | Mục vừa chạm **vẫn** ở trạng thái đã đọc; nhãn thời gian + các mục khác **không đổi** |
| D3 | Chạm một mục **đã đọc** | Không có gì đổi về trạng thái (vẫn đã đọc); app **vẫn** điều hướng tới màn liên quan |
| D4 | Sang tab "Chưa đọc" | Danh sách **chỉ** còn mục chưa đọc, **giữ nguyên** cách nhóm theo thời gian; mục đã đọc **biến mất** |
| D5 | Về tab "Tất cả" | Mục đã đọc **vẫn còn** (chỉ tab "Chưa đọc" ẩn nó) |
| D6 | Đọc lần lượt **từng** mục ở tab "Chưa đọc" | Sau mỗi lần đọc, mục đó rời khỏi danh sách; hết mục → trạng thái rỗng riêng (B3) |
| D7 | Đóng app (hoặc khởi động lại thiết bị) rồi mở lại | **100%** trạng thái đã đọc giữ đúng; **0** mục tự quay về chưa đọc; **0** mục mất khỏi lịch sử |
| D8 | Tìm nút "đánh dấu tất cả đã đọc" / thao tác xoá một mục / xoá cả lịch sử | **Không có** (chỉ chạm mục mới đọc được) |

> D7 cần dữ liệu thật trong DB (§1.2) — dữ liệu chèn thủ công cũng lưu bền như dữ liệu engine.

### Nhóm E — Nhóm & nhãn thời gian (FR-004, SC-001)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| E1 | Chèn 3 bản ghi: hôm nay, 3 ngày trước, 20 ngày trước (§1.2) | 3 nhóm theo thứ tự **HÔM NAY → TUẦN NÀY → TRƯỚC ĐÓ**, mới nhất trước trong mỗi nhóm |
| E2 | Nhãn thời gian mục hôm nay | Giờ **tuyệt đối** `HH:mm` (không phải "x giờ trước") |
| E3 | Nhãn thời gian mục 3 ngày trước | **Tên thứ** đầy đủ (VD "Thứ Năm") |
| E4 | Nhãn thời gian mục 20 ngày trước | `dd/MM` |
| E5 | Mục 8 ngày trước | Rơi vào **TRƯỚC ĐÓ** (không phải TUẦN NÀY) — xem §4 |

### Nhóm F — Không có thao tác ghi dữ liệu nghiệp vụ (FR-012, FR-019, SC-008)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| F1 | Ghi lại (ảnh chụp màn hình) số dư ví + danh sách giao dịch + ngân sách trước khi dùng màn | — |
| F2 | Dùng Trung tâm (đọc vài mục, đổi tab, mở bánh răng rồi back) | — |
| F3 | Đối chiếu lại sau khi dùng | **0** thay đổi số bản ghi/số dư giao dịch, ví, danh mục, ngân sách |
| F4 | Đối chiếu cấu hình thông báo (màn `01`/`02`) | **0** thay đổi |

### Nhóm G — Không bắn thông báo, không xin quyền (FR-013, SC-009)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| G1 | Dùng app cả ngày với Trung tâm | **0** thông báo hệ thống được bắn ra |
| G2 | Cài lại app, mở Trung tâm lần đầu | **0** hộp thoại xin quyền thông báo |
| G3 | Chặn quyền thông báo của app trong Cài đặt hệ điều hành → mở Trung tâm | Màn hiển thị **giống hệt** lúc quyền được cấp (không cảnh báo, không banner) |

### Nhóm H — Điều hướng khi chạm mục (FR-008, SC-006)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| H1 | Chạm mục loại **nhắc nhập giao dịch** | Mở màn **Thêm giao dịch** (đang ở tab **Chi**) |
| H2 | Chạm mục **cảnh báo ngân sách** (có `related_id` = id ngân sách) | Mở **Chi tiết ngân sách** của **đúng** danh mục đó |
| H3 | Chạm mục **tổng kết kỳ** | Về **shell** và mở tab **Báo cáo**, có đủ app bar + bottom nav (không phải màn con mới) |
| H4 | Chạm mục loại **nhắc đến hạn định kỳ** / **nhắc mục tiêu** | **Không** điều hướng, **không** lỗi, **không** khung "sắp có"; chỉ mục đó chuyển sang đã đọc |
| H5 | (Nâng cao) Chèn 1 `budgetAlert` với `related_id` **không tồn tại** rồi chạm | Mở màn Chi tiết ngân sách hiện "**Danh mục đã bị xóa**" — không crash |
| H6 | Chạm **bánh răng** trên app bar Trung tâm | Mở màn **Thông báo & nhắc nhở** (PBI 28); back quay lại Trung tâm |
| H7 | Back từ màn đích của H1/H2 | Về **Trung tâm** (không nhảy về Tổng quan) |

### Nhóm I — Trần 200 mục (FR-010, SC-014)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| I1 | (§1.2) chèn 205 dòng rồi mở Trung tâm | Danh sách có **≤ 200** mục; **200 mục còn lại là mới nhất** (mục cũ nhất đã bị dọn, **không** mục mới nào bị dọn) |
| I2 | Kiểm ở §6 (`SELECT COUNT(*)`) | `≤ 200` |

> Nhóm này **chỉ chắc chắn kiểm được** bằng test tự động (`notification_history_store_drift_test.dart`,
> chạy được trên host này vì có sqlite native) — chèn tay 205 dòng theo §1.2 là tuỳ chọn.

### Nhóm J — Nhiều mục: phản hồi tức thì (FR-017, SC-012)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| J1 | (§1.2 có ~200 mục) mở Trung tâm | Mở **dưới 1 giây**, không khựng |
| J2 | Đổi tab qua lại liên tục | Lọc lại **ngay**, không tải lại màn, không nháy trắng |

### Nhóm K — Dữ liệu người dùng vẫn nguyên vẹn (FR-010)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| K1 | Sau khi nâng cấp từ bản trước PBI 30 (DB **v8**) lên bản này | Ví/danh mục/giao dịch/ngân sách/cài đặt **còn nguyên**; mở Trung tâm không lỗi; lịch sử **rỗng** (bảng mới tạo) |
| K2 | Xoá 1 danh mục có ngân sách rồi mở Trung tâm | Lịch sử **không** mất mục nào (bản ghi độc lập với đối tượng nghiệp vụ) |

### Nhóm L — Tiếng Anh (FR-014, SC-010)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| L1 | Đổi ngôn ngữ sang **English** rồi mở Trung tâm | **0** nhãn tĩnh tiếng Việt còn sót: tiêu đề app bar, 2 nhãn tab, 3 nhãn nhóm, 2 câu trạng thái rỗng, nhãn trợ năng của chuông/bánh răng |
| L2 | (§1.2) xem một mục có **nội dung tiếng Việt** | Tiêu đề/mô tả hiện **nguyên văn như lúc lưu** — **không** bị dịch lại |
| L3 | Nhãn thời gian + giờ ở English | Giờ `HH:mm` và ngày `dd/MM` **không** đổi định dạng |

### Nhóm M — Chế độ Tối (FR-015, SC-010)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| M1 | Đổi giao diện sang **Tối** rồi mở Trung tâm | Nền tối, chữ sáng, nhãn nhóm + dòng mô tả + nhãn thời gian + đường kẻ đều **đọc được** (đủ tương phản) |
| M2 | Mục chưa đọc ở chế độ tối | Chấm teal **thấy rõ** trên nền tối; vòng nền icon vẫn phân biệt được teal nhạt / coral nhạt |
| M3 | App bar + 2 tab ở chế độ tối | App bar vẫn teal thương hiệu; tab đang chọn **teal sáng hơn nền**, tab kia mờ — không chìm |

### Nhóm N — Cỡ chữ lớn & màn hẹp (FR-016, SC-011)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| N1 | Cỡ chữ hệ thống **lớn nhất**, máy nhỏ (360 px) → mở Trung tâm | Không vỡ bố cục, không cắt chữ, tiêu đề/mô tả dài **xuống dòng gọn**, **không** đè lên icon hay nhãn thời gian |
| N2 | Cuộn danh sách | Cuộn tới **mục cuối** được; hàng tab vẫn ở nguyên vị trí |
| N3 | Trạng thái rỗng ở cỡ chữ lớn | Câu chính + câu phụ hiển thị trọn, không tràn |

---

## 3. Kiểm thử tự động (kỳ vọng)

```bash
flutter test test/app_notification_test.dart
flutter test test/notification_history_store_drift_test.dart
flutter test test/notification_center_screen_test.dart
flutter test test/widget_test.dart
flutter test test/sora_translations_test.dart
flutter test test/dark_theme_smoke_test.dart
flutter test
```

| File | Phủ |
|---|---|
| `app_notification_test.dart` | `notificationGroup` (cùng ngày / 1 / 7 / 8 ngày; mốc nửa đêm; khác tháng/năm), `notificationTimeLabel` (3 dạng), `weekdayName` (7 giá trị + ngoài miền), `isRead`, `kMaxNotifications == 200` |
| `notification_history_store_drift_test.dart` | `schemaVersion == 9`; bảng rỗng → `[]`; thứ tự mới nhất trước; **trần 200** (205 → 200, giữ mục mới nhất); `markRead` một chiều + idempotent + id lạ; không đụng bảng khác |
| `notification_center_screen_test.dart` | FR-002…FR-008, FR-011, FR-019 ở tầng widget: đủ thành phần mockup; chấm chỉ ở mục chưa đọc; 2 sắc icon; 5 nhánh điều hướng khi chạm; lọc tab; 2 trạng thái rỗng; bánh răng; loading/error + Thử lại; cỡ chữ 2.0 + 360×640 |
| `widget_test.dart` | Chuông ở màn Tổng quan: có/không chấm theo dữ liệu; 1 chạm mở Trung tâm; quay lại → chấm cập nhật |
| `sora_translations_test.dart` | Mọi khoá mới có bản EN (test tự quét `lib/`) |
| `dark_theme_smoke_test.dart` | Màn Trung tâm ở theme tối: không overflow, token tối thật sự áp |

## 4. Lệch nhỏ đã biết (có lý do)

| # | Lệch | Lý do |
|---|---|---|
| 1 | **Chấm đỏ trên chuông dùng `AppColors.coral`** (đỏ-cam) + viền trắng, không phải đỏ tươi | Bảng màu dự án **không có token đỏ** (Design System: teal + coral + xám); chấm nằm trên nền teal nên cần viền trắng mới đủ tương phản — research R12. Muốn đỏ thật ⇒ thêm 1 hằng số ở PBI sau, đổi 1 dòng |
| 2 | **"TUẦN NÀY" = 7 ngày gần nhất** (cuốn theo ngày), **không** cắt theo tuần lịch bắt đầu Thứ Hai | Spec §Giả định định nghĩa nhóm như vậy; cắt theo tuần lịch thì mục **hôm qua** rơi vào "TRƯỚC ĐÓ" khi hôm nay là Thứ Hai — research R8. Mục **8 ngày** trước ⇒ TRƯỚC ĐÓ (nhóm E5) |
| 3 | Nhãn thời gian trong ngày là **giờ tuyệt đối** `HH:mm`, mockup vẽ "2 giờ trước" | Spec §Giả định chốt **cố ý** (dễ đọc, dễ kiểm thử) |
| 4 | **Trên máy thật màn luôn ở trạng thái rỗng** (chưa có engine ghi lịch sử) | Q1=A của spec — đã chấp nhận; nhóm E–J kiểm bằng §1.2 hoặc test tự động |
| 5 | Không có **đường kẻ dọc** giữa chấm/icon/nội dung; mockup chỉ có kẻ ngang | Bám mockup: chỉ kẻ ngang giữa các mục (thụt lề 20 px) |
| 6 | Bề rộng gạch chân tab theo **nội dung chữ**, không cố định 42 px | Mockup đo theo chữ "Tất cả"; theo nội dung thì đúng cho cả bản dịch EN |

## 5. Mốc test trước PBI

```
flutter test  →  1052 pass + 1 test đỏ CÓ SẴN
```

Test đỏ có sẵn (từ PBI 11, **không** phải lỗi của PBI này):

```
test/transactions_dao_test.dart: Transactions drift — schema v4: categories seed +
  category_id (PBI 11, R1/R2/R4) addTransaction: income/expense bù đúng balance
  + dòng đúng dấu/id/tên
```

Mục tiêu: **không tăng** số test đỏ. 4 file test drift có khẳng định
`schemaVersion == 8` được sửa thành **9** (schema lên v9 ở PBI này).

## 6. Kiểm tra schema & dữ liệu không bị đụng

```bash
# Sau khi dùng màn, đối chiếu DB (tuỳ chọn, cần sqlite3):
sqlite3 <documents>/sora_thu_chi.sqlite \
  "SELECT COUNT(*) FROM notifications;"                       # ≤ 200 (I2)
sqlite3 <documents>/sora_thu_chi.sqlite \
  "SELECT key, value FROM app_settings WHERE key IN ('notificationPrefs','hideBalance','scanEnabled');"
  # → notificationPrefs còn nguyên (màn 03 KHÔNG ghi cấu hình — FR-012)
sqlite3 <documents>/sora_thu_chi.sqlite \
  "SELECT COUNT(*) FROM wallets; SELECT COUNT(*) FROM transactions;"
  # → không đổi so với trước khi dùng màn
```
