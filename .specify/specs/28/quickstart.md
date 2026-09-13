# Khởi động nhanh & kiểm thử tay: Cài đặt Thông báo & nhắc nhở

**Mã PBI**: 28
**Liên kết**: [spec.md](./spec.md) · [plan.md](./plan.md) · [data-model.md](./data-model.md) · [research.md](./research.md)
**Ngày tạo**: 2026-09-13

---

## 1. Chuẩn bị

```bash
cd app/sora_thu_chi
flutter pub get            # KHÔNG có dependency mới — không sửa pubspec.yaml
flutter analyze            # phải sạch
flutter test               # mốc trước PBI: 960 pass + 1 test đỏ CÓ SẴN (xem §5)
flutter run                # chọn emulator/máy thật
```

**Trạng thái cần có để QA đủ nhóm**:

| Thứ cần có | Cách tạo | Dùng cho nhóm |
|---|---|---|
| App mới cài, **chưa từng mở** màn Thông báo & nhắc nhở | Gỡ app rồi cài lại (`flutter run` sạch dữ liệu) | D (mặc định lần đầu) |
| Vài giao dịch bất kỳ + 1 ví + 1 danh mục | Nhập tay hoặc dùng dữ liệu seed sẵn có | G (không ảnh hưởng chức năng khác) |
| Ngôn ngữ = **English** | Cài đặt → Tiện ích & Cá nhân hóa → Ngôn ngữ | H |
| Giao diện = **Tối** | Cài đặt → Tiện ích & Cá nhân hóa → Giao diện | I |
| Cỡ chữ hệ thống = **lớn nhất** | Cài đặt hệ điều hành → Cỡ chữ | J |
| Mockup để đối chiếu | Mở `docs/notification/01-cai-dat-thong-bao.svg` | B |

---

## 2. Kịch bản kiểm thử tay

### Nhóm A — Điểm vào & khung màn (FR-001, FR-002, SC-002)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| A1 | Tab **Cài đặt** → tìm hàng **"Thông báo & nhắc nhở"** | Hàng nằm trong nhóm **KHÁC**, **ngay sau** "Tiện ích & Cá nhân hóa", có chevron bên phải |
| A2 | Chạm hàng **đúng 1 lần** | Màn **Thông báo & nhắc nhở** mở ra: app bar **teal**, nút back, tiêu đề "Thông báo & nhắc nhở" |
| A3 | Nhìn đáy màn | **Không** có thanh điều hướng đáy, **không** có nút thêm giao dịch |
| A4 | Chạm nút back | Về màn **Cài đặt**; các hàng khác của Cài đặt **không đổi** |

### Nhóm B — Đối chiếu mockup `01` (FR-003, FR-004, FR-005, SC-001)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| B1 | Đếm nhãn nhóm (viết hoa, mờ) | **Đủ 5** đúng thứ tự: NHẮC NHỞ HÀNG NGÀY → NGÂN SÁCH → GIAO DỊCH ĐỊNH KỲ → MỤC TIÊU TIẾT KIỆM → TỔNG KẾT TỰ ĐỘNG |
| B2 | Đếm hàng | **Đủ 8 hàng**; hàng nào cũng có **icon tròn nền nhạt + tiêu đề + dòng phụ** |
| B3 | Xem sắc icon | **2 hàng nhóm NGÂN SÁCH** = **coral**; **6 hàng còn lại** = **teal** |
| B4 | Xem bên phải từng hàng | **6 công tắc** (Nhắc nhập giao dịch hằng ngày; Cảnh báo vượt ngân sách; Nhắc hóa đơn sắp đến hạn; Nhắc đóng góp mục tiêu; Tổng kết cuối tuần; Tổng kết cuối tháng) + **2 chevron** (Ngưỡng cảnh báo; Nhắc trước) — **không** hàng nào có cả hai, **không** hàng nào trống |
| B5 | Đọc từng dòng phụ | `20:30 mỗi ngày · chỉ nhắc nếu chưa ghi` · `Khi đạt 80% và khi vượt 100%` · `Sớm: 80% · Vượt mức: 100%` · `Tiền điện, tiền nhà, trả nợ...` · `3 ngày trước hạn thanh toán` · `Theo chu kỳ đã đặt cho từng mục tiêu` · `Chủ nhật hằng tuần, 20:00` · `Ngày cuối tháng, 20:00` |
| B6 | So trực tiếp với mockup | Bố cục, thứ tự nhóm/hàng, vị trí công tắc/chevron **khớp** (đường kẻ giữa các hàng **trong** nhóm — phần lệch nhỏ về đường kẻ xem §4) |

### Nhóm C — Công tắc độc lập & giữ tham số (FR-006, FR-010, SC-003, SC-005)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| C1 | Tắt **"Cảnh báo vượt ngân sách"** | **Chỉ** công tắc đó sang trái/xám; **5 công tắc còn lại giữ nguyên** |
| C2 | Nhìn hàng **"Ngưỡng cảnh báo"** ngay dưới | Dòng phụ **vẫn** `Sớm: 80% · Vượt mức: 100%` — không bị xoá, không mờ, không reset |
| C3 | Bật lại **"Cảnh báo vượt ngân sách"** | Công tắc bật lại; ngưỡng **vẫn** 80%/100% |
| C4 | Tắt/bật lần lượt **cả 6 công tắc**, sau mỗi lần đối chiếu 5 hàng còn lại | **0 sai lệch** — không có công tắc nào tự đổi theo |
| C5 | Tìm công tắc "bật/tắt tất cả" | **Không** tồn tại |

### Nhóm D — Mặc định & lưu bền (FR-007, FR-008, SC-004, SC-006)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| D1 | Gỡ app → cài lại → mở màn **lần đầu** | Bật: Nhắc nhập giao dịch hằng ngày (20:30, có cờ "chỉ nhắc nếu chưa ghi") · Cảnh báo vượt ngân sách (80%/100%) · Nhắc hóa đơn sắp đến hạn (3 ngày) · Tổng kết cuối tuần (Chủ nhật 20:00) · Tổng kết cuối tháng (cuối tháng 20:00). **Tắt**: Nhắc đóng góp mục tiêu |
| D2 | Không chạm gì, thoát app, mở lại → vào màn | Trạng thái **y hệt** D1 (mặc định đã được lưu ngay lần mở đầu) |
| D3 | Đổi vài công tắc → **thoát hẳn app** (kill) → mở lại → vào màn | Đúng trạng thái đã đặt; dòng phụ đúng giá trị đang lưu |
| D4 | **Khởi động lại thiết bị** → vào màn | Vẫn đúng trạng thái đã đặt |
| D5 | **Tắt cả 6** công tắc → kill app → mở lại | **Tất cả vẫn tắt** (0 trường hợp tự bật lại về mặc định) |

### Nhóm E — Hai hàng chevron (FR-011, SC-008)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| E1 | Chạm hàng **"Ngưỡng cảnh báo"** | **Không** màn nào mở ra; **không** thông báo lỗi; **không** khung "sắp có"/"chưa hỗ trợ"; app không treo |
| E2 | Chạm hàng **"Nhắc trước"** | Giống E1 |
| E3 | Chạm liên tục 5–10 lần vào 2 hàng đó | Không lỗi, không treo, không mở gì |

### Nhóm F — Không bắn thông báo & không xin quyền (FR-012, SC-007)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| F1 | Bật/tắt công tắc rồi dùng app cả ngày (thêm giao dịch, xem báo cáo, để app ở nền) | **0** thông báo nào được bắn ra |
| F2 | Trong suốt quá trình trên | **0** lần app hỏi quyền thông báo; màn **không** dòng nào nhắc tới quyền hệ thống |
| F3 | Cấp quyền thông báo ở cài đặt HĐH → mở màn; rồi **chặn** quyền → mở lại màn | Màn hiển thị **giống nhau** ở cả hai trường hợp |

### Nhóm G — Không ảnh hưởng chức năng khác (FR-013, SC-009, SC-012)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| G1 | Tắt **cả 6** công tắc → thêm 1 giao dịch mới | Lưu bình thường, không cảnh báo, không chặn |
| G2 | Tiếp tục: xem ví, danh mục, ngân sách, báo cáo | Tất cả hoạt động bình thường, **0** thông báo lỗi |
| G3 | Ghi lại số bản ghi (giao dịch/ví/danh mục/ngân sách) trước và sau khi dùng màn này | **0** thay đổi |

### Nhóm H — Tiếng Anh (FR-015, SC-010)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| H1 | Đổi ngôn ngữ = **English** → mở màn | Tiêu đề app bar, **5 nhãn nhóm**, **8 tiêu đề hàng**, mọi **dòng phụ dạng mô tả** đều **tiếng Anh**; **0** nhãn tĩnh tiếng Việt sót lại |
| H2 | So giờ/số trên dòng phụ | `20:30`, `80%`, `100%`, `3`, `20:00` giữ **nguyên định dạng**, **không** đổi theo ngôn ngữ |
| H3 | Kéo tới cuối danh sách khi ở English | **0** chuỗi tiếng Việt lẫn vào (tiêu đề hàng cuối, dòng phụ, nhãn nhóm) |

### Nhóm I — Chế độ Tối (FR-016, SC-010)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| I1 | Đổi giao diện = **Tối** → mở màn | Nền tối, **không** vùng trắng chói; chữ đủ tương phản |
| I2 | Xem vòng tròn icon (teal + coral) | Vòng nền và glyph đọc được trên nền tối, coral vẫn phân biệt được với teal |
| I3 | Xem công tắc **bật** và **tắt** | Phân biệt rõ bật/tắt, chấm và nền đều thấy được |
| I4 | Đổi lại giao diện = Sáng → mở màn | Về đúng bộ màu sáng, không lẫn màu tối |

### Nhóm J — Cỡ chữ lớn & màn hình nhỏ (FR-017, SC-011)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| J1 | Cỡ chữ hệ thống **lớn nhất** + màn hình nhỏ → mở màn | Tiêu đề hàng và dòng phụ **xuống dòng gọn**; **không** đè lên công tắc/chevron |
| J2 | Cuộn xuống cuối danh sách | Tới được **hàng cuối** ("Tổng kết cuối tháng"); không cắt chữ |
| J3 | Xoay ngang (nếu máy hỗ trợ) | Không vỡ bố cục, không tràn ngang |

### Nhóm K — Hai nhóm chưa có module (FR-014)

| # | Bước | Kết quả mong đợi |
|---|---|---|
| K1 | Bật **"Nhắc đóng góp mục tiêu"** (MỤC TIÊU TIẾT KIỆM — module GĐ3 chưa có) | Bật được, lưu được; **không** dòng "sắp có"/"chưa hỗ trợ"; công tắc **không** bị vô hiệu hoá |
| K2 | Tắt **"Nhắc hóa đơn sắp đến hạn"** (GIAO DỊCH ĐỊNH KỲ — chưa có) | Tắt được, lưu được, y như mọi hàng khác |
| K3 | Kill app → mở lại | Hai trạng thái trên **đúng như đã đặt** |

---

## 3. Kiểm thử tự động (kỳ vọng)

| File test | Nội dung chính |
|---|---|
| `test/notification_prefs_test.dart` | 17 luật §2 data-model: mặc định, parse tolerant (JSON rác/thiếu khoá/sai kiểu/ngoài miền), round-trip, bất biến `copyWith` (chỉ đổi 1 loại, giữ tham số khi tắt), `formatClock` |
| `test/notification_store_drift_test.dart` | DB in-memory (skip-guard khi host thiếu sqlite native): schema vẫn **8**; key vắng → mặc định; round-trip; **không** xoá khoá `hideBalance`/`scanEnabled` của PBI 17/24 |
| `test/notification_settings_screen_test.dart` | Màn với `FakeNotificationStore`: 5 nhóm + 8 hàng; 6 công tắc + 2 chevron; sắc icon theo nhóm; bật/tắt chỉ đổi 1 hàng + ghi store; chevron no-op (0 route, 0 dialog); mở lần đầu ghi mặc định; cỡ chữ lớn (2.0) + màn 360×640 không tràn |
| `test/settings_screen_test.dart` (**sửa**) | +1 hàng "Thông báo & nhắc nhở" đúng vị trí; chạm mở `NotificationSettingsScreen`; back về; seam `onManageNotificationsTap` |
| `test/dark_theme_smoke_test.dart` (**sửa**) | Màn mới vào danh sách smoke giao diện tối: không overflow, token tối thật sự áp |

---

## 4. Lệch nhỏ đã biết (có lý do)

1. **Đường kẻ giữa các hàng**: chỉ kẻ **giữa các hàng trong cùng nhóm** (khuôn màn
   Tiện ích – PBI 17); mockup `01` vẽ 4 đường kẻ không nhất quán (có đường sau hàng
   cuối nhóm NGÂN SÁCH, thiếu ở nhóm MỤC TIÊU) — không bám theo lỗi đồ hoạ.
2. **Hai hàng chevron chạm không mở gì** (chốt Q2=A) — mockup không nói gì về
   hành vi chạm; đợt này là **điểm nối** cho PBI chỉnh tham số.
3. **Dòng phụ "mỗi ngày"** không phản ánh danh sách ngày trong tuần (chưa có UI
   chọn ngày — research R3); mockup cũng ghi "mỗi ngày".
4. **Công tắc dùng màu mặc định của `ColorScheme`** (seed teal) như 2 công tắc
   màn Tiện ích và công tắc "Quét hóa đơn bằng AI" — không thêm `switchTheme`.

---

## 5. Mốc test trước PBI

```
flutter test   →   960 pass + 1 FAIL CÓ SẴN
                   (test/transactions_dao_test.dart — "addTransaction: income/expense
                    bù đúng balance + dòng đúng dấu/id/tên", tồn tại từ PBI 11,
                    KHÔNG liên quan PBI 28)
```

Mục tiêu: số test **pass tăng**, số test **đỏ không tăng** (vẫn đúng 1). Nếu thấy
test đỏ khác `transactions_dao_test` ⇒ là hồi quy của PBI này.

---

## 6. Kiểm tra schema & dữ liệu không bị đụng

```bash
# Sau khi dùng màn, mở DB để đối chiếu (tuỳ chọn, cần sqlite3):
#   sqlite3 <documents>/sora_thu_chi.sqlite \
#     "SELECT key, value FROM app_settings WHERE key = 'notificationPrefs';"
#   → đúng 1 row JSON, 16 khoá
#   → các row khác (hideBalance, amountCalculatorEnabled, scanEnabled…) còn nguyên
```

- `schemaVersion` **vẫn 8** — không migration, không bảng mới.
- Số bản ghi `transactions`/`wallets`/`categories`/`budgets` **không đổi** sau khi
  dùng màn (nhóm G3).
