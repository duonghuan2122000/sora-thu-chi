# Nghiên cứu kỹ thuật: PBI 48 — Privacy Mode Dashboard

## R1 — Nguồn lưu trữ trạng thái Privacy mode

**Quyết định**: Tái dùng nguyên trạng key `hideBalance` trong bảng `AppSettings` (đã có từ PBI 17, qua `UtilitiesStore`/`DriftUtilitiesStore`) — không thêm bảng, không thêm cột, không đổi tên key.
**Lý do**: Công tắc "Ẩn số dư (Privacy mode)" đã tồn tại ở Cài đặt → Tiện ích, chỉ chưa "kéo hiệu ứng màn khác" (ghi chú FR-007 cũ). PBI 48 chỉ cần làm nó có tác dụng, không phải xây lại state.
**Phương án khác đã xem xét**: Thêm bảng/khoá riêng cho "privacy mode" — bị loại vì trùng lặp dữ liệu, có nguy cơ lệch giữa 2 nguồn.

## R2 — Đồng bộ 2 chiều Dashboard ↔ Cài đặt (FR-006)

**Quyết định**: Thêm `PrivacyController extends GetxController` (singleton qua `ensurePrivacyController()`, cùng pattern `ThemeController`/`ensureUtilitiesStore`) làm nguồn chân lý duy nhất cho **cả hai** cờ trong `UtilitiesPrefs` (`hideBalance` **và** `amountCalculatorEnabled`), backed bởi `UtilitiesStore` sẵn có. `UtilitiesScreen` bỏ state cục bộ `_prefs`/`_load`/`_setPrefs`, chuyển sang đọc/ghi qua controller này (`Obx`). `DashboardScreen` chỉ đọc `controller.hideBalance` (không ghi).
**Lý do**: Nếu Dashboard và `UtilitiesScreen` giữ 2 bản cache riêng của `UtilitiesPrefs`, thao tác ghi ở màn này (dựa trên cache cũ) có thể ghi đè cờ vừa đổi ở màn kia — một nguồn chân lý loại bỏ hẳn nguy cơ này thay vì phải thêm cơ chế đồng bộ chắp vá.
**Phương án khác đã xem xét**: Giữ `UtilitiesScreen` như cũ (StatefulWidget đọc thẳng `UtilitiesStore`), Dashboard tự `load()` mỗi lần vào tab — bị loại vì tạo 2 nguồn cache độc lập, đúng lúc 2 màn thao tác gần nhau (ví dụ bật ở Dashboard rồi mở ngay Cài đặt) có thể thấy hoặc ghi giá trị cũ.

## R3 — Trạng thái "xem tạm thời" (FR-005)

**Quyết định**: Thêm `Rx<bool> revealed` trong `PrivacyController` — **không** lưu bền (không có key `AppSettings` tương ứng). `AppShell._onTabSelected` đặt `revealed.value = false` mỗi khi rời tab Tổng quan (index != 0), cùng cơ chế đang dùng để reset "report presence" khi rời tab Báo cáo (`_syncReportPresence`). Chạm biểu tượng con mắt đảo `revealed.value` khi `hideBalance == true`.
**Lý do**: `IndexedStack` trong `AppShell` giữ `DashboardScreen` sống xuyên suốt vòng đời app (không rebuild khi đổi tab) — không thể dựa vào `initState` để phát hiện "rời màn Tổng quan"; phải hook vào đúng điểm chuyển tab đã có sẵn (bám nguyên tắc tái dùng, đã có tiền lệ ở `_syncReportPresence`).
**Phương án khác đã xem xét**: `RouteAware`/`NavigatorObserver` để phát hiện rời màn — thừa phức tạp vì Dashboard không đổi route khi đổi tab (chỉ đổi `IndexedStack.index`), route observer sẽ không bắn sự kiện.

## R4 — Cách che số tiền (FR-002)

**Quyết định**: Thêm hàm `maskMoney(int value)` trong `money_format.dart`, trả về `'•' * số-chữ-số + ' đ'` (số chữ số = độ dài `value.abs().toString()`, tối thiểu 1) — bỏ dấu phân cách nghìn và dấu `+`/`-`/âm, chỉ giữ đơn vị `đ`.
**Lý do**: Đúng yêu cầu tài liệu nghiệp vụ "giữ định dạng độ dài tương đối, không lộ số chữ số" mà không cần tính lại logic định dạng dấu phân cách phức tạp; số lượng dấu chấm xấp xỉ theo độ lớn giá trị gốc như mockup `06`.
**Phương án khác đã xem xét**: Che bằng số ký tự cố định (VD luôn `••••••`) bất kể độ lớn — bị loại vì đơn giản quá mức, không khớp mô tả "tương đối" và làm mockup 2 khối thu/chi trông giống hệt bất kể số liệu.

## R5 — Nơi hiển thị mask (phạm vi Tổng quan, không ảnh hưởng Giao dịch)

**Quyết định**: `MonthStatRow` và `TxnRowTile` (đang dùng chung giữa `DashboardScreen` và `TransactionScreen`) nhận thêm tham số tuỳ chọn `masked` (mặc định `false`, giữ hành vi cũ). Chỉ `DashboardScreen` truyền `masked: hideBalance && !revealed`; `TransactionScreen` không đổi lời gọi → không đụng tới màn Giao dịch (đúng phạm vi spec).
**Lý do**: Tái dùng 2 widget sẵn có thay vì tạo bản sao riêng cho Dashboard (rung 2 — đã có trong codebase); tham số mặc định giữ nguyên hành vi nơi khác đang gọi.
**Phương án khác đã xem xét**: Nhân bản `MonthStatRow`/`TxnRowTile` thành phiên bản "ẩn được" riêng cho Dashboard — bị loại, trùng lặp code không cần thiết.

## R6 — Biểu tượng con mắt trên vùng tiêu đề

**Quyết định**: Thêm icon tròn 48px cạnh `_BellButton` trong `Row` truyền vào `ScreenHeader.trailing` của `DashboardScreen` — dùng đúng khả năng "nhiều nút cạnh nhau" mà `ScreenHeader` đã hỗ trợ (tiền lệ PBI 27: so sánh + xuất báo cáo).
**Lý do**: Không cần đổi `ScreenHeader`, chỉ đổi cách `DashboardScreen` dựng `trailing`.
**Phương án khác đã xem xét**: Đặt icon mắt tách biệt phía dưới tiêu đề (không chung hàng) — bị loại vì lệch mockup `06` (icon mắt nằm ngay cạnh tiêu đề "Tổng quan").
