# Khởi động nhanh & kiểm thử tay: Thông báo đẩy — engine bắn thông báo & nhắc nhở

**Mã PBI**: 31
**Liên kết**: [spec.md](./spec.md) · [plan.md](./plan.md) · [data-model.md](./data-model.md) · [research.md](./research.md)
**Ngày tạo**: 2026-09-13

---

## 1. Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get            # ⚠ 3 dependency MỚI: flutter_local_notifications · timezone · flutter_timezone
dart run build_runner build --delete-conflicting-outputs   # sinh lại app_database.g.dart (schema v10)
flutter analyze            # phải sạch
flutter test               # mốc trước PBI: 1100 pass + 1 test đỏ CÓ SẴN (xem §5)
flutter run                # chọn emulator/máy thật
flutter build apk --release   # BẮT BUỘC chạy: xác nhận proguard/desugaring không chặn release (R14)
```

> ⚠ **Cài lại app khi thêm plugin native** (bẫy đã gặp ở PBI 24/27): `flutter run`
> trên bản cài cũ có thể **không** đăng ký plugin mới ⇒ tình trạng "0 thông báo,
> không lỗi". **Gỡ app rồi cài lại** (hoặc `flutter run` từ đầu trên máy sạch)
> trước khi QA nhóm B trở đi. **Dữ liệu cũ sẽ mất** — ghi lại vài số liệu cần
> đối chiếu (nhóm N) trước khi gỡ.

**Trạng thái cần có để QA đủ nhóm**:

| Thứ cần có | Cách tạo | Dùng cho nhóm |
|---|---|---|
| App vừa cài, **chưa từng mở màn `01`** | Gỡ app + cài lại | B (soft-ask lần đầu) |
| 1 ngân sách tháng cho **Ăn uống** | Báo cáo → Ngân sách → thêm mới | E, F |
| Vài giao dịch **Chi** cho Ăn uống trong tháng | Tab Giao dịch → FAB | E, F |
| Giờ nhắc hàng ngày = **giờ hiện tại + 2 phút** | Cài đặt → Thông báo & nhắc nhở → Nhắc nhập giao dịch | C, D, M |
| Giờ tổng kết tuần = **giờ hiện tại + 2 phút**, **ngày thiết bị = Chủ nhật** | Màn `01` (chỉ đọc được giờ) + Cài đặt hệ điều hành (tắt "giờ tự động") | G, H |
| Quyền thông báo **bị chặn** | Cài đặt hệ điều hành → Ứng dụng → Sora Thu Chi → Thông báo → tắt | I |
| Email/tài liệu đối chiếu | `docs/notification/04-mau-thong-bao-day.svg` + `01-cai-dat-thong-bao.svg` | B, E, F, G |

### 1.2. Lệnh hữu ích khi QA

```bash
PKG=com.sorathuchi.sora_thu_chi

# Xem các lịch đã đăng ký với AlarmManager (kiểm FR-022 nhanh, không cần chờ tới giờ)
adb shell dumpsys alarm | grep -i sora

# Chặn / cấp lại quyền thông báo mà không cần vào cài đặt hệ điều hành
adb shell pm revoke $PKG android.permission.POST_NOTIFICATIONS
adb shell pm grant  $PKG android.permission.POST_NOTIFICATIONS

# Xem sổ + lịch sử (drift lưu DateTime bằng SỐ GIÂY unix, không phải mili-giây)
adb exec-out run-as $PKG cat app_flutter/sora_thu_chi.sqlite > sora.sqlite
sqlite3 sora.sqlite "SELECT entry_key, kind, datetime(scheduled_for,'unixepoch','localtime'),
  suppressed, history_id FROM notification_ledger ORDER BY scheduled_for;"
sqlite3 sora.sqlite "SELECT id, kind, title, body, datetime(created_at,'unixepoch','localtime'),
  read_at FROM notifications ORDER BY created_at DESC LIMIT 10;"
```

> **Xem bản ghi có `created_at` = mốc bắn** (không phải giờ mở app) là **đúng thiết
> kế** (hoà giải R6) — nhãn thời gian trên màn Trung tâm vì thế khớp lúc thông báo
> hiện ra, dù bản ghi được ghi bù ở lần mở app kế tiếp.

---

## 2. Kiểm thử tay (nhóm A–P)

### Nhóm A — Môi trường & build (R1, R14)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| A1 | `flutter pub get` | 3 package mới resolve được, không xung đột version |
| A2 | `flutter analyze` | **0** issue |
| A3 | `flutter test` | 1100 pass + 1 đỏ **có sẵn** (`transactions_dao_test` — host thiếu sqlite native; **không** phải lỗi PBI này) |
| A4 | `flutter build apk --release` | **Thành công** (không vướng proguard/desugaring — R14) |
| A5 | `adb shell dumpsys package $PKG \| grep -i "POST_NOTIFICATIONS\|USE_EXACT_ALARM\|RECEIVE_BOOT"` | Cả 3 quyền đã khai báo |
| A6 | Đổi ngôn ngữ sang English rồi chạy `flutter test` | Vẫn xanh (mọi khoá dịch mới đã có bản `_en` — `sora_translations_test`) |

### Nhóm B — Soft-ask quyền ở lần đầu mở màn `01` (FR-017/FR-032, SC-018/SC-019, AC#27/#28)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| B1 | Máy sạch (chưa từng mở màn `01`) → Cài đặt → **Thông báo & nhắc nhở** | Hộp thoại **giải thích trong app** hiện **trước**, có 2 lựa chọn đồng ý / không đồng ý; **chưa** thấy hộp thoại hệ điều hành |
| B2 | Chọn **đồng ý** | Hộp thoại **hệ điều hành** mới hiện; cho phép → màn `01` hiện **đúng mockup**, **0** dòng thừa về quyền |
| B3 | Thoát màn, mở lại màn `01` (vài lần) | **Không** lời giải thích nào hiện lại; **không** hộp thoại hệ thống nào tự bật lên |
| B4 | Vào cài đặt hệ điều hành **tắt** quyền thông báo → quay lại app → mở màn `01` | Có **đúng 1** dòng trạng thái "thông báo đang bị tắt" + lối **mở cài đặt thông báo của hệ điều hành**; **mọi** công tắc/giá trị giữ nguyên |
| B5 | Chạm lối mở cài đặt | Mở đúng màn cài đặt thông báo của app trong cài đặt hệ điều hành |
| B6 | Bật lại quyền → quay lại màn `01` | Dòng trạng thái **biến mất**, màn đúng mockup `01` (0 dòng thừa) |
| B7 | Máy sạch lại → chọn **không đồng ý** ở B1, rồi tắt/bật vài công tắc | **Không** lời giải thích nào hiện lại, **không** hộp thoại hệ thống đột ngột; dòng trạng thái hiện; cấu hình vẫn lưu bình thường |

### Nhóm C — Nhắc hàng ngày: chỉ ngày được chọn (FR-010, SC-002/SC-003, AC#1/#4)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| C1 | Màn `02`: đặt giờ = **bây giờ + 2 phút**, **7 ngày bật**, cờ **bật**; **chưa** ghi giao dịch nào hôm nay; Lưu; để app ở nền | Đúng **phút** đó: **1** thông báo hệ thống — tên app **"Sora Thu Chi"**, icon **chuông**, tiêu đề **"Nhắc ghi chép giao dịch"**, dòng mô tả **"Bạn chưa ghi giao dịch nào hôm nay."**, nhãn thời gian |
| C2 | Mở app → chuông màn Tổng quan | Có **chấm chưa đọc**; Trung tâm có **đúng 1** bản ghi mới (chưa đọc), nội dung **nguyên văn** như C1 |
| C3 | Chạm thông báo đó trên màn hình khoá (hoặc chạm bản ghi trong Trung tâm) | App mở → (PIN nếu có) → màn **Thêm giao dịch**; bản ghi chuyển **đã đọc**, chấm đỏ mất sau khi quay về Tổng quan |
| C4 | Màn `02`: bỏ chọn **một** ngày (VD Thứ Tư) → Lưu → kiểm `dumpsys alarm` | **Không** còn lịch nào rơi vào Thứ Tư; các ngày còn lại vẫn có lịch |
| C5 | Đặt giờ nhắc vào **ngày không được chọn** (đổi ngày thiết bị hoặc chọn ngày khác) | **0** thông báo và **0** bản ghi mới (đếm trước/sau bằng nhau) |

### Nhóm D — Nhắc hàng ngày: cờ "chỉ nhắc nếu chưa ghi" (FR-008/FR-011, SC-004, AC#2/#3)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| D1 | Cờ **bật**, giờ nhắc = **bây giờ + 3 phút**; ghi **1** giao dịch (thu/chi/chuyển khoản — thử lần lượt) trước giờ nhắc | Đến giờ: **0** thông báo, **0** bản ghi mới |
| D2 | Lặp D1 trong **3 ngày** liên tiếp | **0/0** cả 3 ngày |
| D3 | Cờ **tắt**, giờ nhắc = **bây giờ + 3 phút**, **đã ghi** giao dịch hôm nay | Thông báo **vẫn hiện**; dòng mô tả **KHÔNG** được nói "bạn chưa ghi giao dịch nào hôm nay" (FR-008/AC#3) |
| D4 | Cờ **bật**, giờ nhắc = **bây giờ + 3 phút**, **chưa ghi** gì | Thông báo hiện **và** câu chữ nói rõ hôm nay chưa ghi |
| D5 | Ghi giao dịch **sau** giờ nhắc (VD 20:35 khi nhắc 20:30) | Nhắc của **ngày mai** vẫn hoạt động bình thường (không bị huỷ lây) |

### Nhóm E — Cảnh báo ngân sách: ngưỡng sớm (FR-007/FR-012/FR-014, SC-005, AC#5)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| E1 | Ngân sách **Ăn uống** tháng = 1.000.000; chi lũy kế 780.000 (78%) | Chưa có thông báo nào |
| E2 | Lưu thêm **1** giao dịch Chi 40.000 (→ 82%) | **Ngay sau khi lưu**: thông báo — icon **cảnh báo + sắc coral**, tiêu đề nêu **tên danh mục**, dòng mô tả nêu **82%** và **kỳ** ("ngân sách tháng 9"); **không** chặn/không làm chậm thao tác lưu; Trung tâm có **1** bản ghi chưa đọc |
| E3 | Chạm thông báo | App mở **đúng Chi tiết ngân sách của Ăn uống**; bản ghi chuyển đã đọc |
| E4 | Lưu thêm 3 giao dịch Chi nữa (89%, 95%, 99%) | **0** thông báo thêm cho ngưỡng **sớm** (chống bắn trùng theo kỳ) |
| E5 | Lưu tiếp đến **104%** | **Đúng 1** thông báo cho ngưỡng **vượt mức**, câu chữ nói **đã vượt** (phân biệt được với "sắp vượt" bằng chữ — FR-007) + 1 bản ghi |
| E6 | Lưu giao dịch **Thu** cho Ăn uống; lưu giao dịch Chi của danh mục **khác**; lưu giao dịch Chi **ngoài kỳ** ngân sách | **0** thông báo và **0** bản ghi cho cả 3 ca (FR-014/AC#8) |
| E7 | Tạo **2** ngân sách cùng lúc vượt ngưỡng bằng 1 giao dịch | **Mỗi** ngân sách có **1** thông báo + **1** bản ghi riêng (0 cái nào bị mất — AC#9) |
| E8 | **Tắt** công tắc "Cảnh báo vượt ngân sách" ở màn `01` → lưu giao dịch vượt ngưỡng | **0** thông báo, **0** bản ghi (AC#15) |
| E9 | **Bật lại** rồi lưu giao dịch vượt **ngưỡng chưa từng báo** trong kỳ | Báo bình thường; ngưỡng **đã báo trước khi tắt** trong cùng kỳ **không** báo lại |

### Nhóm F — Cảnh báo ngân sách: chống trùng bền & biên (FR-013, AC#6/#7, §Trường hợp biên)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| F1 | Sau E5 (đã vượt mức trong tháng) → **kill app**, **mở lại**, lưu thêm giao dịch Chi | **0** thông báo lặp cho cả 2 ngưỡng đã báo |
| F2 | **Khởi động lại thiết bị** → lưu thêm giao dịch Chi vượt ngưỡng | **0** thông báo lặp |
| F3 | Sang **tháng mới** (đổi ngày thiết bị hoặc lùi `start_date` ngân sách) → đẩy vượt ngưỡng sớm | **Được** báo lại (trạng thái chống trùng gắn với **kỳ**, không vĩnh viễn) |
| F4 | **Sửa** số tiền giao dịch đã làm vượt ngưỡng xuống dưới ngưỡng, rồi lưu giao dịch khác vượt lại | **0** thông báo lặp; **0** thu hồi thông báo đã bắn; lịch sử **không** bị tính lại |
| F5 | **Lưu trữ / xoá** ngân sách ngay sau khi đã báo → mở Trung tâm, chạm bản ghi cảnh báo đó | Bản ghi **vẫn còn** trong lịch sử; chạm **không** gây lỗi, **không** màn trắng, **không** khung "sắp có" (FR-020) |
| F6 | Xem bảng sổ trong DB sau F1–F5 | **Đúng 1** dòng cho mỗi cặp `(ngưỡng, ngân sách, kỳ)`; không dòng rác |

### Nhóm G — Tổng kết tuần/tháng (FR-009/FR-015, SC-006, AC#18/#19/#20)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| G1 | Đặt ngày thiết bị = **Chủ nhật**; giờ tổng kết tuần = **bây giờ + 2 phút**; có giao dịch trong tuần Thứ Hai→Chủ Nhật vừa kết thúc; để app ở nền | Thông báo icon **biểu đồ tròn (teal)**, tiêu đề **"Tổng kết tuần"**, dòng mô tả có **số liệu so sánh** với tuần liền trước + câu mời xem báo cáo (đúng mockup `04` mẫu 4) |
| G2 | Chạm thông báo | App mở **tab Báo cáo** với kỳ là **tuần vừa kết thúc**; bản ghi chuyển đã đọc |
| G3 | Đặt ngày thiết bị = **ngày cuối tháng**, giờ tổng kết tháng = **bây giờ + 2 phút** | Thông báo **"Tổng kết tháng"** với số liệu **tháng dương lịch vừa kết thúc** |
| G4 | Kỳ vừa kết thúc **không có giao dịch nào** | **Vẫn** có 1 thông báo tổng kết, câu chữ phản ánh đúng việc kỳ đó chưa ghi giao dịch; **không** câu so sánh sai lệch |
| G5 | **Tuần trước đó** không có giao dịch (kỳ này có) | **Không** hiện câu so sánh vô nghĩa: **0** "nhiều hơn ∞", **0** chia cho 0 |
| G6 | Đối chiếu số trên thông báo với số ở màn Báo cáo cùng kỳ | **Khớp** từng con số |
| G7 | Trong **cùng một ngày** có: nhắc hàng ngày + cảnh báo ngân sách + tổng kết | **3** thông báo riêng và **3** bản ghi riêng — không gộp, không mất cái nào |

### Nhóm H — Q3: đang ở đúng màn liên quan (FR-016, AC#10/#11)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| H1 | Mở **Chi tiết ngân sách của Ăn uống** rồi (từ máy khác/script hoặc chờ giờ) lưu giao dịch khiến ngân sách đó vượt ngưỡng | **0** thông báo hệ thống **và** **0** bản ghi mới |
| H2 | Lặp lại khi đang ở **màn khác** (VD danh sách Giao dịch) | Thông báo **vẫn** hiện bình thường + có bản ghi (AC#11) |
| H3 | Đang mở **màn Báo cáo** đúng lúc đến **giờ tổng kết** | **0** thông báo, **0** bản ghi |
| H4 | Rời màn Báo cáo sau đó → kiểm `dumpsys alarm` + bảng sổ | Mốc đã trôi qua **không** được ghi bù; mốc **tuần sau** đã được đăng ký lại |
| H5 | Đang ở Chi tiết ngân sách của **danh mục khác** (không phải danh mục vượt ngưỡng) | Thông báo **vẫn** hiện |

### Nhóm I — Quyền bị chặn / tắt ở cài đặt hệ điều hành (FR-004/FR-025/FR-032, SC-009/SC-019, AC#14)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| I1 | `adb shell pm revoke $PKG android.permission.POST_NOTIFICATIONS` → đặt giờ nhắc = bây giờ + 2 phút | **0** thông báo hiện ra; app **không** lỗi, **không** cảnh báo, **không** chặn gì; ghi giao dịch vẫn bình thường |
| I2 | Mở app → Trung tâm thông báo | Bản ghi cho mốc đó **vẫn có đầy đủ** |
| I3 | `pm grant` lại quyền rồi đặt mốc kế tiếp = bây giờ + 2 phút | Thông báo hiện lại; các mốc **đã trôi qua** trong lúc bị chặn **không** được bắn bù (đếm số thông báo) |
| I4 | Trong cài đặt hệ điều hành tắt **riêng kênh** cảnh báo ngân sách | Ngân sách **im lặng**, nhắc hàng ngày & tổng kết **vẫn bắn**; lịch sử **vẫn đầy đủ** |
| I5 | Bật lại kênh đó | Thông báo ngân sách hoạt động trở lại |

### Nhóm J — Bắn đúng giờ khi app đóng & sau khởi động lại (FR-022, SC-010, AC#17)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| J1 | Đặt giờ nhắc = bây giờ + 3 phút → **kill app** (vuốt khỏi recents) | Đúng giờ đó thông báo vẫn hiện |
| J2 | Đặt giờ nhắc = bây giờ + 5 phút → **khởi động lại thiết bị** (`adb reboot`), **không** mở app | Sau khi máy lên, đến giờ: thông báo vẫn hiện (SC-010, 0 mốc mất) |
| J3 | Sau J2 mở app lần đầu | Bản ghi của mốc J2 có `created_at` = **mốc bắn** (không phải giờ mở app); **0** loạt thông báo/bản ghi bắn bù |
| J4 | Tắt app trong **vài ngày** (không mở) rồi mở lại | Số bản ghi mới **đúng bằng** số mốc nhắc thật đã trôi qua; **không** dội thêm thông báo |

### Nhóm K — Đổi cấu hình có hiệu lực ngay (FR-021, SC-011, AC#15/#16, AC#26)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| K1 | Đổi giờ nhắc 20:30 → **07:05** ở màn `02`, Lưu, **không** mở lại app | `dumpsys alarm` cho thấy lịch **đã tính theo giờ mới**; **0** mốc bắn ở giờ cũ sau đó |
| K2 | **Tắt** công tắc nhắc hàng ngày ở màn `01` → dùng app tiếp | **0** thông báo, **0** bản ghi của loại đó; các loại khác không bị ảnh hưởng |
| K3 | **Bật lại** | Loại đó hoạt động lại; **không** cần khởi động lại app/thiết bị |
| K4 | Đổi tập ngày (bỏ/ thêm ngày) → Lưu | Lịch cập nhật ngay; ngày bị bỏ **không** còn mốc nào |
| K5 | Quan sát 2 hàng chevron "Ngưỡng cảnh báo" / "Nhắc trước" ở màn `01` | Hành xử **như cũ**: chỉ hiển thị giá trị đang lưu, chạm **không** mở gì (FR-030/AC#26) |

### Nhóm L — Điều hướng khi chạm & khoá PIN (FR-018/FR-019/FR-020, SC-008, AC#12/#13)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| L1 | App **đã đóng**, chạm thông báo nhắc hàng ngày trên màn hình khoá | App mở → màn **Thêm giao dịch**; bản ghi tương ứng **đã đọc** |
| L2 | Chạm thông báo cảnh báo ngân sách | Mở **đúng Chi tiết ngân sách của danh mục đó** |
| L3 | Chạm thông báo tổng kết | Mở **tab Báo cáo** đã lọc sẵn kỳ vừa tổng kết |
| L4 | Bật **khoá PIN** → app đóng → chạm thông báo | Màn **mở khoá hiện trước**; mở khoá **thành công** mới tới màn đích |
| L5 | Ở L4, nhập sai PIN / huỷ mở khoá | **Không** vào được màn đích; **0** dữ liệu lộ ra |
| L6 | Xoá danh mục (hoặc lưu trữ ngân sách) của cảnh báo đã bắn → chạm bản ghi đó trong Trung tâm | **Không** lỗi, **không** màn trắng; bản ghi vẫn chuyển **đã đọc** |

### Nhóm M — Không làm hỏng luồng lưu & không chạm dữ liệu nghiệp vụ (FR-023/FR-024, SC-012/SC-013, AC#21/#22)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| M1 | Ghi lại số bản ghi của `transactions`/`wallets`/`categories`/`budgets` trước và sau 1 tuần dùng engine | **0** thay đổi (SC-013) |
| M2 | Lưu giao dịch khi engine đang chạy (bấm Lưu liên tục 10 lần) | Thao tác hoàn tất **dưới 1 giây**; **0** lỗi hiện ra; **0** treo |
| M3 | Lưu giao dịch khi ngân sách có dữ liệu bất thường (VD `budgets` trỏ `category_id` không tồn tại; sửa tay `notificationPrefs` thành JSON hỏng) | Giao dịch **vẫn lưu thành công**; người dùng **không** thấy lỗi; engine dùng **mặc định từng trường** (không dừng toàn bộ) |
| M4 | Kiểm bảng `notifications` sau M2/M3 | Chỉ có bản ghi hợp lệ; **không** bản ghi rác/trùng do lỗi |
| M5 | Bật **chế độ máy bay** rồi dùng app cả ngày | Engine hoạt động **đầy đủ** (FR-031/SC-017); **0** lời gọi mạng |
| M6 | Kiểm tra: engine ghi vào đúng 3 chỗ — `notification_ledger` (sổ), `notifications` (lịch sử + `read_at`), `AppSettings` (row `notificationPermissionAsked`) | **0** ghi vào bảng nào khác |

### Nhóm N — Trần 200, tiếng Anh, Theme Tối, dữ liệu cũ (FR-027/FR-029, SC-014, AC#23/#24/#25)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| N1 | Đặt giờ nhắc **chỉ 1 phút nữa** nhiều lần để tích lũy bản ghi (hoặc chèn tay vào bảng `notifications` cho tới 200) rồi để engine ghi thêm | Số bản ghi xem được **≤ 200**; **200** dòng còn lại là **mới nhất** |
| N2 | Ngôn ngữ = **English** → để một thông báo bắn ra | Tiêu đề + dòng mô tả **tiếng Anh**; bản ghi lưu cũng tiếng Anh |
| N3 | Đổi sang **Tiếng Việt** → mở Trung tâm | Bản ghi cũ **giữ nguyên văn tiếng Anh** (0 dòng bị dịch lại); thông báo bắn **sau đó** dùng tiếng Việt |
| N4 | Ngôn ngữ = English, mở màn `01` | Dòng trạng thái quyền (nếu có) + mọi nhãn **đều tiếng Anh**; tên app **"Sora Thu Chi"** không dịch |
| N5 | Đặt giao diện = **Tối**, để một thông báo bắn + mở Trung tâm | Không lỗi, màu đúng token; thông báo hệ điều hành vẫn hiện bình thường |
| N6 | Dùng **DB từ bản trước** (nâng cấp, chưa từng có engine) → mở app sau khi cập nhật | Engine chạy với **đúng cấu hình đang lưu** (không reset mặc định), app **không** lỗi, **0** loạt thông báo bắn bù của các kỳ/ngày đã qua (AC#24) |
| N7 | Sau N6, kiểm bảng `notification_ledger` | Chỉ có dòng cho các mốc **tương lai** (0 dòng mang mốc đã trôi qua) |

### Nhóm O — Múi giờ & giới hạn nền tảng (spec §Trường hợp biên)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| O1 | Đổi múi giờ thiết bị (VD từ `GMT+7` sang `GMT+9`) → mở app | `dumpsys alarm` cho thấy lịch **dịch theo giờ địa phương mới**; **0** bắn bù mốc đã trôi qua |
| O2 | Đổi giờ hệ thống về **quá khứ** (VD lùi 1 ngày) rồi mở app | **0** bản ghi trùng/lạ; app không lỗi |
| O3 | Tắt nguồn đúng lúc đến giờ nhắc → bật lại | Mốc đó **bỏ lỡ**, **không** bắn bù; các mốc **còn ở tương lai** vẫn hoạt động bình thường |
| O4 | Cài đặt hệ điều hành → **tối ưu pin** chặn app (máy Xiaomi/Oppo nếu có) | Hành vi đã biết & chấp nhận: có thể lỡ nhắc; **không** có UI hướng dẫn autostart trong đợt này (ngoài phạm vi) |

### Nhóm P — iOS (ngoài phạm vi QA đợt này — chỉ ghi nhận)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| P1 | `flutter build ios --no-codesign` | **Biên dịch được** (AppDelegate có `UNUserNotificationCenter.delegate` — R14) |
| P2 | Chạy thật trên iPhone: bắn 1 thông báo nhắc hàng ngày | **Chưa QA trong đợt này** — bám tiền lệ PBI 28/29/30 ("iOS chưa QA"); ghi nhận nếu chạy được thì càng tốt |

---

## 3. Kiểm thử tự động (thay cho QA tay ở các ca khó dựng trên máy)

| Nhóm | File test | Phủ |
|---|---|---|
| Tính lịch | `test/notification_schedule_test.dart` | Cửa sổ 30 ngày · ngày trong tuần (AC#4) · mốc cuối tháng 28/29/30/31 · khoá chống trùng theo kỳ · id ổn định (FNV) |
| Câu chữ | `test/notification_content_test.dart` | 2 ngôn ngữ · câu "sắp vượt"/"đã vượt" phân biệt bằng chữ · cờ bật/tắt (AC#3) · kỳ rỗng / kỳ trước rỗng (AC#19/#20) · định dạng tiền & giờ |
| Điều phối | `test/notification_engine_test.dart` | FR-003 (1 thông báo + 1 bản ghi) · chống trùng (SC-005) · Q3 (AC#10/#11) · huỷ khi đã ghi (AC#2) · hoà giải ghi bù · tắt/bật công tắc · lỗi không làm hỏng lưu (AC#21) |
| Sổ drift | `test/notification_ledger_drift_test.dart` | Upsert theo khoá (không nhân đôi) · `dueBefore` · `suppress` · `pruneBefore` · schema **v10** |
| Màn `01` | `test/notification_settings_screen_test.dart` (sửa) | Soft-ask **1 lần** (AC#27) · dòng trạng thái hiện/ẩn (AC#28) · công tắc/tham số không đổi |
| Vỏ | `test/widget_test.dart`, các `*_dao_test`/`*_store_drift_test` (sửa) | Đổi `schemaVersion` 9 → 10 ở các file drift |

---

## 4. Đối chiếu nhanh FR ↔ nhóm QA

| FR | Nhóm | FR | Nhóm |
|---|---|---|---|
| FR-001/FR-002 | A, E | FR-017 | B |
| FR-003 | C2, E2, G7 | FR-018 | L1–L3 |
| FR-004 | I1–I2 | FR-019 | L4–L5 |
| FR-005/FR-006 | C1, E2, G1 | FR-020 | F5, L6 |
| FR-007 | E2, E5 | FR-021 | K1–K4 |
| FR-008 | D3–D4 | FR-022 | C1, J1–J2 |
| FR-009 | G1–G6 | FR-023 | M1, M6 |
| FR-010 | C1, C4–C5 | FR-024 | M2–M3 |
| FR-011 | D1–D2 | FR-025 | I4–I5 |
| FR-012/FR-014 | E1–E3, E6 | FR-026 | F1–F2 |
| FR-013 | E4, F1–F4 | FR-027 | N2–N4 |
| FR-015 | G1, G3 | FR-028 | I3, J3, N6–N7 |
| FR-016 | H1–H5 | FR-029 | N1 |
| | | FR-030/FR-031/FR-032 | K5, M5, B4–B6 |

---

## 5. Mốc test & các lệch đã biết

- **Mốc trước PBI**: **1100 pass + 1 test đỏ CÓ SẴN** (`transactions_dao_test` — host
  thiếu sqlite native; **không** liên quan PBI này, giữ nguyên khi kết thúc).
- **Lệch có chủ ý 1 — bản ghi Trung tâm ghi bù**: khi app đóng lúc thông báo bắn,
  bản ghi được ghi ở **lần mở app kế tiếp** với `created_at = mốc bắn` (R0/R6).
  Trên màn Trung tâm **không phân biệt được** với ghi tại chỗ; đổi lại là **không**
  cần thêm tiến trình nền (FR-022).
- **Lệch có chủ ý 2 — cửa sổ 30 ngày**: nhắc hàng ngày được đăng ký trước 30 ngày
  và cuốn lại mỗi lần app chạy. Người dùng **không mở app > 30 ngày** sẽ hết nhắc
  (R2) — đây là người dùng đã bỏ app.
- **Lệch có chủ ý 3 — nội dung tổng kết tươi theo lần mở app cuối**: tổng kết tuần/
  tháng chỉ đăng ký **một mốc kế tiếp** và tính lại nội dung mỗi lần app chạy (R3).
  Vì giao dịch chỉ phát sinh khi app mở, nội dung trên thực tế luôn khớp; nếu
  người dùng để app đóng suốt **cả kỳ** thì tổng kết kỳ đó có thể không bắn (mốc
  chưa được đăng ký).
- **Lệch có chủ ý 4 — exact alarm**: khai `USE_EXACT_ALARM` (app phát hành qua
  GitHub Releases, không qua Play) và **lùi về lịch inexact** nếu hệ điều hành từ
  chối (R10) — lịch inexact có thể lệch vài phút so với AC#1/SC-002.
- **Lệch có chủ ý 5 — engine không phân biệt được "hệ điều hành giết lịch" với
  "quyền bị chặn"**: cả hai đều sinh bản ghi lịch sử (đúng FR-004/AC#14 cho ca
  quyền bị chặn; ca giết lịch nhận cùng hành vi — chấp nhận, và **có lợi** cho
  người dùng vì vẫn xem lại được).
- **Lệch có chủ ý 6 — chạm tổng kết TỪ TRUNG TÂM không chọn sẵn kỳ**: bản ghi lịch
  sử không mang thông tin tuần/tháng (bảng `notifications` của PBI 30 không đổi),
  nên chỉ khi chạm **thông báo hệ điều hành** (payload = khoá `summary:week:`/
  `summary:month:`) mới `setPeriod` trước khi mở tab Báo cáo; chạm mục trong Trung
  tâm giữ nguyên hành vi PBI 30 (kỳ mặc định) — FR-018/AC#12 vẫn đạt qua đường chạm
  thông báo.
- **Lệch có chủ ý 7 — "đang mở màn Báo cáo" suy từ TAB đang chọn, không từ vòng đời
  widget**: màn Báo cáo sống trong `IndexedStack` của `AppShell` nên **mọi** tab được
  dựng từ lúc boot — `initState` của màn không phản ánh việc người dùng đang nhìn nó.
  Vì vậy `AppShell._onTabSelected` khai báo/ngưng hiện diện `'report'` và gọi
  `onEnterRelatedScreen`/`onLeaveRelatedScreen` (thay cho việc bọc `ReportScreen`
  thành `StatefulWidget` như plan.md §Kiến trúc dự kiến). Hành vi quan sát được
  đúng FR-016/AC#10: đang ở tab Báo cáo ⇒ không bắn, không ghi, không ghi bù.
- **Chưa QA**: iOS (P1/P2 — tiền lệ 3 PBI gần nhất).
