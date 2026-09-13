# Đặc tả tính năng: Mở khóa bằng sinh trắc học

**Mã PBI**: 34
**Ngày tạo**: 2026-09-13
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

Bổ sung lớp mở khóa "tiện lợi" bằng vân tay/Face ID nằm **trên nền mã PIN đã có** (PBI 3): người dùng bật công tắc trong màn Cài đặt, sau đó mỗi lần vào màn khóa được tự động mời xác thực sinh trắc học thay vì phải gõ đủ 4 số, với lối thoát về PIN luôn sẵn có.

## Kịch bản & luồng người dùng

### Luồng chính

- **Given** người dùng đã thiết lập mã PIN (bắt buộc từ PBI 3) và thiết bị có cảm biến vân tay/Face ID đã đăng ký, **When** vào màn Cài đặt và bật công tắc "Mở khóa sinh trắc học", **Then** hệ thống xác thực lại bằng sinh trắc học của thiết bị để xác nhận, xác thực đúng thì công tắc bật và có hiệu lực từ lần khóa app kế tiếp.
- **Given** đã bật sinh trắc học, **When** mở app từ nền hoặc khởi động lại, **Then** màn khóa tự động hiện lời mời xác thực sinh trắc học (icon + "Chạm để xác thực") thay vì bàn phím PIN, kèm nút "Dùng mã PIN thay thế" luôn hiển thị.
- **Given** đang ở màn mời xác thực sinh trắc học, **When** xác thực thành công, **Then** vào thẳng đúng màn đang đứng trước khi khóa (giữ nguyên hành vi FR-007 của PBI 3).
- **Given** đang ở màn mời xác thực sinh trắc học, **When** xác thực thất bại (không nhận diện, người dùng huỷ) hoặc bấm "Dùng mã PIN thay thế", **Then** hệ thống chuyển sang màn nhập PIN quen thuộc, không tự thoát app.

### Kịch bản chấp nhận

1. **Given** thiết bị không có cảm biến sinh trắc học hoặc chưa đăng ký vân tay/khuôn mặt nào, **When** vào màn Cài đặt, **Then** công tắc "Mở khóa sinh trắc học" hiện ở trạng thái tắt và không bật được (có dòng phụ giải thích lý do).
2. **Given** công tắc sinh trắc học đang bật, **When** người dùng tắt công tắc trong Cài đặt, **Then** lần khóa kế tiếp trở lại hiện thẳng bàn phím PIN như trước khi có tính năng này, không mời sinh trắc học nữa.
3. **Given** công tắc đang bật, **When** người dùng thu hồi quyền sinh trắc học của app trong Cài đặt hệ điều hành rồi mở lại app, **Then** hệ thống phát hiện quyền đã mất, tự tắt công tắc, và màn khóa lần đó hiện bàn phím PIN (không tự mời sinh trắc học đã mất hiệu lực).
4. **Given** công tắc đang bật, **When** người dùng thêm hoặc xoá vân tay/khuôn mặt đã đăng ký trong Cài đặt hệ điều hành, **Then** lần khóa kế tiếp hệ thống không tự mời sinh trắc học nữa (tự tắt tạm thời), bắt xác thực lại bằng PIN; sau khi vào được app, công tắc trong Cài đặt hiện tắt và có thể bật lại (yêu cầu xác thực như bật lần đầu).
5. **Given** đang ở màn mời xác thực sinh trắc học, **When** bấm "Dùng mã PIN thay thế", **Then** chuyển ngay sang bàn phím PIN, không mất trạng thái chống dò brute-force hiện có của PIN (kế thừa nguyên vẹn từ PBI 3).

### Trường hợp biên

- Bật công tắc nhưng huỷ/xác thực sai ở bước xác nhận → công tắc giữ nguyên trạng thái tắt, không ghi nhận gì.
- Sinh trắc học bị khoá tạm thời ở tầng hệ điều hành (quá nhiều lần sai liên tiếp ngoài app) → màn mời sinh trắc học báo lỗi chung rồi tự chuyển về PIN, không hiển thị chi tiết lỗi hệ điều hành.
- Người dùng thoát hẳn app ngay khi hộp thoại sinh trắc học của hệ điều hành đang hiện → lần mở app sau vẫn ở đúng màn khóa (không được coi là đã mở khoá).
- Đổi thiết bị/khôi phục từ file backup JSON → công tắc sinh trắc học về mặc định tắt (danh tính sinh trắc học gắn với phần cứng, không nằm trong dữ liệu backup).

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI chỉ cho bật công tắc "Mở khóa sinh trắc học" khi thiết bị có cảm biến hỗ trợ **và** đã đăng ký ít nhất một vân tay/khuôn mặt; nếu không, công tắc hiện tắt và không bật được, kèm giải thích ngắn.
- **FR-002**: Hệ thống PHẢI yêu cầu xác thực sinh trắc học thành công (chỉ sinh trắc học, không bắt nhập lại PIN) ngay tại thời điểm bật công tắc lần đầu (hoặc bật lại sau khi bị vô hiệu hoá) trước khi ghi nhận trạng thái "đã bật" (chốt 2026-09-13, phương án A).
- **FR-003**: Khi công tắc đang bật, mỗi lần vào màn khóa (khởi động app hoặc quay lại từ nền) hệ thống PHẢI tự động hiện lời mời xác thực sinh trắc học trước, thay cho bàn phím PIN.
- **FR-004**: Màn mời xác thực sinh trắc học PHẢI luôn có nút "Dùng mã PIN thay thế" đưa ngay sang bàn phím PIN đang có (PBI 3), không phá trạng thái chống dò PIN.
- **FR-005**: Xác thực sinh trắc học thất bại (không nhận diện được, người dùng huỷ, hệ thống báo lỗi) PHẢI tự động chuyển sang bàn phím PIN, không tự thoát app và không tính là một lần nhập PIN sai.
- **FR-006**: Xác thực sinh trắc học thành công PHẢI đưa vào đúng màn người dùng đang đứng trước khi khóa (giữ hành vi FR-007 của PBI 3), không reset về màn đầu.
- **FR-007**: Hệ thống PHẢI phát hiện khi quyền sinh trắc học của app bị thu hồi ở cấp hệ điều hành và tự tắt công tắc trong Cài đặt, đồng thời màn khóa lần kế tiếp không mời sinh trắc học nữa mà hiện thẳng bàn phím PIN.
- **FR-008**: Hệ thống PHẢI phát hiện khi tập vân tay/khuôn mặt đã đăng ký trên thiết bị thay đổi (thêm/xoá) kể từ lúc bật, tự vô hiệu hoá tạm thời tính năng (tắt công tắc, không tự mời sinh trắc học ở lần khóa kế tiếp) và bắt xác thực lại bằng PIN; muốn dùng lại phải bật lại thủ công theo đúng luồng FR-002.
- **FR-009**: Tắt công tắc trong Cài đặt PHẢI có hiệu lực ngay từ lần khóa kế tiếp — không cần xác thực gì thêm để tắt.
- **FR-010**: Mã PIN PHẢI luôn là lớp bảo mật gốc — sinh trắc học không bao giờ thay thế hoàn toàn hay vô hiệu hoá được luồng đổi PIN/chống dò PIN đã có.
- **FR-011**: Trạng thái bật/tắt công tắc sinh trắc học PHẢI là cấu hình gắn với thiết bị hiện tại — không đưa vào backup/restore JSON, không tự động bật lại sau khi khôi phục dữ liệu trên thiết bị khác.

*Mỗi yêu cầu phải kiểm thử được (testable) và không mơ hồ.*

## Tiêu chí thành công

- **SC-001**: Với thiết bị đã đăng ký sinh trắc học và đã bật tính năng, mở khóa app bằng vân tay/Face ID mất dưới 2 giây thao tác (không phải gõ đủ 4 số).
- **SC-002**: 100% trường hợp xác thực sinh trắc học thất bại đều đưa được người dùng vào bàn phím PIN mà không phải thoát/mở lại app.
- **SC-003**: 100% trường hợp quyền sinh trắc học bị thu hồi hoặc dữ liệu sinh trắc học đăng ký trên máy thay đổi đều khiến app tự quay về yêu cầu PIN, không có trường hợp app bị khóa cứng ngoài khả năng mở lại bằng PIN.
- **SC-004**: Không có đường nào trong luồng mở khóa sinh trắc học cho phép vào app mà không qua xác thực thành công (sinh trắc học hoặc PIN).

## Giả định

- Nút "Hủy" trên màn mời xác thực sinh trắc học (mockup `03-sinh-trac-hoc.svg`) chỉ huỷ **lượt xác thực sinh trắc học hiện tại** (đóng hộp thoại của hệ điều hành), người dùng vẫn đứng ở màn mời và có thể chạm lại icon vân tay để thử tiếp; đây không phải là lối tắt vào app và không tương đương "Dùng mã PIN thay thế".
- Danh sách thiết bị/quyền sinh trắc học do hệ điều hành quản lý; app chỉ đọc trạng thái tại các thời điểm: mở app, quay lại từ nền, và khi người dùng bật công tắc — không theo dõi liên tục nền.
- Onboarding hoàn chỉnh (mời bật sinh trắc học ngay khi thiết lập PIN lần đầu, theo `docs/auth §2.1`) vẫn **chưa tồn tại** trong app (đúng thực trạng đã ghi ở PBI 3) — đợt này chỉ bổ sung điểm bật trong Cài đặt, không đụng luồng thiết lập PIN lần đầu.
- Numpad màn khóa PIN đã để trống ô vân tay ở hàng cuối bên trái từ PBI 3 (theo wiki) — đợt này không cần đổi bố cục bàn phím PIN, chỉ thêm màn mời sinh trắc học đứng **trước** màn khóa PIN khi tính năng đang bật.
- Hàng "Đổi mã PIN" trong mockup `04-ho-so-ca-nhan.svg` là mục có sẵn trong màn Cài đặt hiện tại (`settings_screen.dart`) nhưng vẫn ở trạng thái no-op chưa kích hoạt — **ngoài phạm vi** PBI này (không nằm trong tiêu đề PBI 34).

## Ngoài phạm vi

- Luồng đổi mã PIN (mục "Đổi mã PIN" trong mockup `04`) — thuộc PBI riêng.
- Luồng quên PIN / đặt lại PIN qua backup JSON (docs/auth §4.2).
- Onboarding hoàn chỉnh lần đầu mở app (chọn tiền tệ, tạo ví, mời bật sinh trắc học ngay từ đầu).
- Tuỳ chọn độ dài PIN 4/6 số.
- Cấu hình khoảng thời gian timeout trước khi tự khóa app.

