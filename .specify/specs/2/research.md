# Research — PBI 2: Khung điều hướng ứng dụng

**Ngày**: 2026-09-03
**Môi trường**: Flutter 3.44.6 (stable) / Dart 3.12.2, máy Windows 11, Android emulator API 37 (theo trạng thái PBI 1).
**Nguồn ràng buộc**: `spec.md`, `docs/design-system-app-thu-chi.md` (§2.1 Khung điều hướng, bảng màu, component), mockup `docs/auth/01-khung-dieu-huong.svg`, wiki `Design system` / `Stack kỹ thuật` / `Lộ trình phát triển`.

## Quyết định: điều hướng bằng Navigator chuẩn, chưa dùng GetX router

- **Quyết định**: Dùng `MaterialApp` + `Navigator` 1.0. Shell giữ 4 tab bằng `IndexedStack`; màn phụ mở bằng `Navigator.push(MaterialPageRoute)`.
- **Lý do**: PBI này là shell tĩnh — không có controller, state nghiệp vụ hay DI nào để GetX quản lý. Navigator chuẩn đã đáp ứng đủ: (1) push màn phụ **phủ toàn màn hình** → tự khối đi luôn bottom nav (FR-006, FR-008); (2) xử lý nút back hệ thống sẵn; (3) animation chuyển màn mặc định. Ít lớp nhất, dễ test widget thuần.
- **Phương án khác**: `GetMaterialApp` + `Get.to` (theo dòng "get = state & điều hướng" trong §Stack). Lý do từ chối ở đợt này: chưa có API GetX nào được dùng thật; thêm vỏ bọc + cách điều hướng thứ hai là chi phí thừa. **Điều kiện mở lại**: khi PBI module đầu tiên cần controller (ví, giao dịch…) hoặc khi có màn hình gốc chọn trước/sau khóa app → đổi `MaterialApp` → `GetMaterialApp` là 1 dòng, chỗ push sub-page tập trung nên migration cục bộ.

## Quyết định: giữ trạng thái tab bằng IndexedStack

- **Quyết định**: `body` của shell là `IndexedStack` bọc 4 màn chính; chỉ số tab = `int` trong `State` của `AppShell` (StatefulWidget), đổi bằng `setState`.
- **Lý do**: `IndexedStack` giữ nguyên tree + state của cả 4 con → khi chuyển tab rồi quay lại, màn không bị dựng lại từ đầu (FR-004, kịch bản 3). Không cần controller/reactive nào.
- **Phương án khác**: mỗi tab một `Navigator` riêng (state theo stack từng tab) — quá mức cho đợt khung trống; `PageView` — cho vuốt ngang, không trong yêu cầu. Từ chối cả hai (YAGNI).

## Quyết định: tự dựng bottom nav 5 vị trí, không dùng NavigationBar M3

- **Quyết định**: Thanh nav tự dựng: `Row` gồm **5 ô `Expanded` bằng nhau** — ô 0 Tổng quan, ô 1 Giao dịch, ô 2 **trống**, ô 3 Báo cáo, ô 4 Cài đặt; FAB của `Scaffold` (`FloatingActionButtonLocation.centerDocked`) nổi giữa, nhô lên trên mép thanh.
- **Lý do**: Khớp mockup `01-khung-dieu-huong.svg` + design doc §2.1 — thanh trắng cao ~64, đường kẻ trên `#E0E0E0`, mỗi tab icon + label nhỏ; tab chọn teal + label đậm, chưa chọn xám `#9B9B9B`; FAB tròn 52px teal `#0F6E56`, icon cộng trắng, nằm giữa nhô lên. `centerDocked` đưa FAB đúng vào ô giữa trống, nửa dưới chìm xuống thanh.
- **Phương án khác**: `NavigationBar` (Material 3) — không hỗ trợ FAB giữa nhô + khó ép màu/bo theo mock; `BottomAppBar` + `CircularNotchedRectangle` — notch cứng theo FAB, không khớp mock "5 ô đều", label quanh notch vướng. Tự dựng ~vài chục dòng, khớp mock, dễ test.
- **Icon**: dùng bộ gợi ý design doc §2.1 — Tổng quan `home`, Giao dịch `list`, Báo cáo `chart-pie`, Cài đặt `settings` (variant outlined, màu teal khi chọn / xám khi không).

## Quyết định: màn phụ dùng chung widget + push route phủ toàn màn

- **Quyết định**: Tạo `SubPageScaffold(title, child)` — `AppBar` teal, icon back + tiêu đề trắng (theo design doc §2.2 sub-page), không bottom nav. Mở bằng `Navigator.push(MaterialPageRoute)`. Đợt này áp dụng cho "Thêm giao dịch" (FR-006); Cài đặt PBI sau tái dùng widget này cho sub-page (FR-008).
- **Lý do**: Đảm bảo cảm giác điều hướng thống nhất, cấu hình app bar gom 1 chỗ thay vì lặp từng màn.
- **Phương án khác**: mở bằng modal bottom sheet / dialog — không khớp mock màn phụ full (sau là form dài); từ chối.

## Quyết định: theme/token tập trung 1 nơi, chỉ kê màu thực dùng

- **Quyết định**: Tạo `lib/theme/app_colors.dart` (hằng token màu đợt này: teal `#0F6E56`, trắng `#FFFFFF`, teal nhạt chữ phụ trên header `#CDE9DF`, xám tab chưa chọn `#9B9B9B`, divider `#E0E0E0`, chữ chính `#1A1A1A`) + `lib/theme/app_theme.dart` (`AppTheme` → `ThemeData`: scaffold nền trắng, `colorScheme` gieo từ teal, `appBarTheme` teal + chữ trắng 16/600). Widget chỉ đọc token/theme, **không** nhúng hex cứng (rule "style tập trung 1 nơi" trong design doc §Triển khai + wiki).
- **Lý do**: header/nav/appbar của shell cần đúng màu thương hiệu; token 1 chỗ để sau này đổi style là sửa đúng 1 file. Kê tối thiểu token **đang tiêu thụ**, tránh dựng cả bảng palette/typography từ trước (thừa — bổ sung khi module sau cần, thêm vào cùng file token).
- **Phương án khác**: dựng ngay bộ token đầy đủ theo bảng thiết kế — YAGNI; hardcode trong từng widget — vi phạm rule tập trung. Cả hai từ chối.

## Quyết định: 4 màn chính là file riêng, chỉ header + body trống

- **Quyết định**: Mỗi màn chính 1 file: `DashboardScreen` (Tổng quan), `TransactionScreen` (Giao dịch), `ReportScreen` (Báo cáo), `SettingsScreen` (Cài đặt). Mỗi màn = header teal (vùng tiêu đề, tên màn) + vùng nội dung trống; **không** số liệu/hình minh họa giả (FR-007).
- **Lý do**: Đúng loại "Màn hình chính" trong design doc §2.2 (header thương hiệu chứa tiêu đề). Để 4 file riêng làm chỗ bám cho PBI module sau gắn nội dung vào từng vùng (giả định spec).
- **Phương án khác**: 1 widget dùng chung render 4 lần với tham số title — ít file hơn nhưng module sau vẫn phải tách file để chèn body; tách sẵn từ đầu, mỗi file nhỏ (chỉ ~header + body trống), không đắt.

## Quyết định: kiểm chứng bằng widget test + QA thủ công trên thiết bị

- **Quyết định**: Thay `test/widget_test.dart` (test counter demo cũ — sẽ hỏng khi bỏ `MyHomePage`) bằng smoke widget test shell: boot → thấy header Tổng quan + đủ 4 nhãn tab + FAB; tap từng tab → header đổi tương ứng; tap FAB → màn "Thêm giao dịch" có nút back, **không còn** bottom nav; tap back → về shell đúng tab cũ. Chạy `flutter analyze` + `flutter test`.
- **Lý do**: Toàn bộ FR-001..010 đều là hành vi UI thuần, widget test chạy host không cần plugin nền tảng → bắt lỗi nhanh, rẻ, không phụ thuộc emulator. Các SC cần thiết bị thật (vùng an toàn FR-009/SC-004, cỡ chữ lớn SC-005) → QA thủ công theo `quickstart.md`.
- **Phương án khác**: `integration_test` chạy emulator — phụ thuộc thiết bị, chậm; giữ cho phase QA thủ công + (sau này) khi có pipeline.

## Quyết định: chống vỡ khi cỡ chữ lớn (SC-005)

- **Quyết định**: Mỗi ô tab bọc label trong vùng co được (`FittedBox`/ellipsis, 1 dòng, cỡ nhỏ theo token); FAB không chứa chữ nên không vỡ; toàn bộ vùng nav nằm trong `SafeArea` (chân) để không bị phím điều hướng hệ thống che (SC-004).
- **Lý do**: Nhãn "Giao dịch"/"Tổng quan" dài, ô ngang hẹp; mock label cỡ ~9px. Với tỉ lệ text hệ thống tối đa, nhãn co lại thay vì tràn.
- **Phương án khác**: cấm co (maxLines=1 + ellipsis trần) — có thể cắt chữ; để 2 dòng — lệch mock. Chọn co mềm, verify SC-005 trên emulator.

## Ghi chú quyết định mở liên quan

Không còn điểm `NEEDS CLARIFICATION`. Không đóng/không mở thêm ⚠ quyết định mở nào của wiki.
