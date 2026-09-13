# Đặc tả tính năng: Logo ứng dụng & màn hình Splash

**Mã PBI**: 25
**Ngày tạo**: 2026-09-13
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Hiện tại app vẫn mang **icon mặc định của bộ khung khởi tạo** khi cài lên máy, và khi mở app người dùng chỉ thấy một **màn hình trống** trong lúc app nạp dữ liệu — nhìn không ra đây là app gì. PBI này đưa **bộ nhận diện thương hiệu** vào sản phẩm: thay **icon chính thức** trên màn hình chính của điện thoại (Android + iOS) và thêm **màn hình splash** mang logo + tên app, hiển thị ngay khi người dùng mở app.

Nguồn thiết kế: `docs/logo/logo-concepts-sora-thu-chi.md` (3 phương án A/B/C) và `docs/logo/logo-concept-a-coin-flow.svg` (Concept A — Coin Flow: đồng xu chia đôi, nửa trên teal + mũi tên lên = Thu, nửa dưới coral + mũi tên xuống = Chi). Logo dùng đúng bảng màu thương hiệu đã chốt ở design system: teal `#0F6E56`, coral `#D85A30`, trắng.

**Phạm vi đã chốt**: chỉ **icon trên màn hình chính** (Concept A) và **màn hình splash** (nền teal đặc, logo + tên app màu trắng); logo **không** đặt trong nội dung app. Đây là thay đổi **thuần trình bày** — không đụng tới dữ liệu, nghiệp vụ hay luồng chức năng nào của app.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị), thao tác trên màn hình chính của điện thoại.

### Luồng chính — Mở app từ trạng thái đóng (cold start)

1. Người dùng nhìn màn hình chính của điện thoại → thấy **icon app là logo thương hiệu** (không còn icon mặc định), tên app bên dưới vẫn là **"Sora Thu Chi"**.
2. Người dùng chạm icon → **màn hình splash hiện ra gần như tức thì**: logo thương hiệu + tên **“Sora Thu Chi”** đặt trên nền màu thương hiệu, căn giữa; **không** có thanh tiêu đề, không bottom nav, không nút bấm, không dòng chữ phụ.
3. Trong lúc splash đang hiển thị, app nạp dữ liệu local và các cấu hình đã lưu (ngôn ngữ, giao diện sáng/tối, trạng thái khóa app).
4. Khi app sẵn sàng → **splash tự biến mất**, không cần người dùng chạm. Màn kế tiếp là:
   - màn **khóa app** (nhập PIN / sinh trắc học) nếu người dùng có bật khóa, hoặc
   - màn **Tổng quan** nếu app không bật khóa.
5. Màn kế tiếp hiển thị đã đúng **ngôn ngữ** và **giao diện sáng/tối** người dùng đã chọn — không nháy đổi qua lại trước mắt người dùng.

### Luồng phụ — Quay lại app từ nền (resume)

Người dùng đang dùng app → thoát ra ngoài (home / chuyển app) → mở lại. **Splash không hiện lại**; app trở về đúng màn hình đang dùng trước đó (hoặc màn khóa nếu app đã tự khóa).

### Luồng phụ — Cài đè lên bản cũ

Người dùng cài bản mới đè lên bản cũ → icon trên màn hình chính **cập nhật thành logo mới** (không còn giữ icon cũ), splash hiển thị đúng như lần cài mới.

### Kịch bản chấp nhận

1. **Given** app đã cài trên máy **When** người dùng xem màn hình chính của điện thoại **Then** icon app là **đồng xu Concept A** (nửa teal trên + nửa coral dưới + hai mũi tên trắng) ở **mọi kiểu hiển thị mà hệ điều hành áp dụng** (tròn, vuông bo góc, mềm) — hình đồng xu và hai mũi tên vẫn nhìn rõ, không bị cắt mất chi tiết chính, không có viền/nền lạ bao quanh.
2. **Given** app đang đóng **When** người dùng chạm icon **Then** tính từ lúc chạm, người dùng thấy **logo thương hiệu** thay vì một khung nền trống — không có khung hình trắng/đen trơ kéo dài đáng kể trước khi logo xuất hiện.
3. **Given** splash đang hiển thị **When** quan sát màn hình **Then** trên splash chỉ có **đồng xu Concept A + tên app “Sora Thu Chi” màu trắng** trên **nền teal đặc**: không thanh tiêu đề, không bottom nav, không nút bấm, và **không có dòng chữ chú thích của bản concept** (“Concept A — Coin Flow”, mô tả, danh sách file…).
4. **Given** splash đang hiển thị **When** nhìn vào logo **Then** người dùng nhận ra **đủ hai nửa đồng xu** (nửa teal không chìm mất vào nền teal) nhờ nét trắng phân tách.
5. **Given** splash đang hiển thị **When** app nạp xong dữ liệu và cấu hình **Then** splash **tự biến mất** mà người dùng không phải chạm vào đâu.
6. **Given** app có bật khóa app **When** splash kết thúc **Then** màn **khóa app** hiện ra (không vào thẳng Tổng quan); **Given** app không bật khóa **When** splash kết thúc **Then** màn **Tổng quan** hiện ra.
7. **Given** người dùng đang ở một tab bất kỳ **When** đưa app về nền rồi mở lại **Then** **không** thấy splash, app trở về màn hình đang dùng.
8. **Given** thiết bị đang ở giao diện Sáng hoặc Tối **When** mở app **Then** splash hiển thị **giống hệt nhau ở cả hai giao diện** (nền teal đặc, logo và tên app trắng), không có lần nào nền splash đổi sang trắng/đen theo giao diện.
9. **Given** thiết bị xoay ngang hoặc có tỉ lệ màn hình khác thường (màn nhỏ, màn dài, tablet) **When** mở app **Then** logo vẫn **căn giữa, đúng tỉ lệ, không méo, không tràn viền**.
10. **Given** người dùng đang dùng app **When** đi qua các màn hình chính (Tổng quan, Giao dịch, Báo cáo, Cài đặt) **Then** **không** có logo nào được thêm vào nội dung app — nhận diện thương hiệu chỉ xuất hiện ở icon màn hình chính và splash.

### Trường hợp biên

- **Máy yếu / dữ liệu lớn nên nạp lâu**: splash phải **giữ nguyên logo** trong suốt thời gian chờ (không nhấp nháy, không hiện màn trắng chen giữa), và **tự kết thúc muộn nhất sau vài giây** rồi vào app — không được treo ở splash vô hạn.
- **Hệ điều hành có màn hình khởi động hệ thống** (một số phiên bản Android hiển thị icon/nền của app trước khi app vẽ được gì): hình mà hệ điều hành vẽ và splash của app phải **liền mạch, không “nhảy” hình** (đổi màu nền / đổi cỡ logo đột ngột).
- **Hệ điều hành tự kill app khi ở nền**: lần mở kế tiếp được coi là mở từ trạng thái đóng → splash hiện lại, đúng như luồng chính.
- **Thay đổi cỡ chữ hệ thống ở mức lớn nhất**: tên app trên splash không được tràn ra ngoài mép màn hình.
- **Thiết bị không có kết nối mạng**: splash và icon phải hiển thị y hệt — phần nhận diện không phụ thuộc mạng.

## Yêu cầu chức năng

- **FR-001**: App PHẢI dùng **Concept A — Coin Flow** (đồng xu chia đôi: nửa trên teal `#0F6E56` + mũi tên hướng lên, nửa dưới coral `#D85A30` + mũi tên hướng xuống, đường phân tách và hai mũi tên màu trắng) làm **icon trên màn hình chính** của cả Android và iOS, thay thế **hoàn toàn** icon mặc định của bộ khung khởi tạo.
- **FR-002**: Icon PHẢI giữ đúng hình dạng và chi tiết chính (đồng xu chia đôi + hai mũi tên) khi hệ điều hành áp các kiểu cắt tròn / vuông bo góc / mềm khác nhau, ở mọi mật độ màn hình.
- **FR-003**: Tên app hiển thị dưới icon trên màn hình chính PHẢI giữ nguyên **“Sora Thu Chi”**.
- **FR-004**: App PHẢI hiển thị **màn hình splash** ở **mỗi lần mở app từ trạng thái đóng** (cold start), gồm **logo Concept A + tên app “Sora Thu Chi” màu trắng** trên **nền teal thương hiệu `#0F6E56` đặc**, căn giữa màn hình; nền splash **giống nhau ở cả giao diện Sáng và Tối** (không đổi theo giao diện).
- **FR-005**: Splash **KHÔNG** hiển thị lại khi người dùng quay lại app từ nền.
- **FR-006**: Splash PHẢI **tự kết thúc** ngay khi app sẵn sàng; người dùng **không** phải chạm để đi tiếp; và PHẢI kết thúc muộn nhất sau **5 giây** kể cả khi app nạp chậm.
- **FR-007**: Splash **KHÔNG** chứa thanh tiêu đề, bottom nav, nút bấm, chỉ báo tải tròn, hay văn bản mô tả phụ.
- **FR-008**: Mọi hình ảnh nhận diện (icon, logo splash) PHẢI dùng đúng bảng màu thương hiệu — teal `#0F6E56`, coral `#D85A30`, trắng — **không gradient, không đổ bóng, không hiệu ứng**, đúng tinh thần Material phẳng của design system.
- **FR-009**: Logo PHẢI **sắc nét ở mọi kích thước hiển thị** (từ icon launcher nhỏ nhất tới splash toàn màn hình) — không vỡ nét, không nhoè thành khối màu đặc.
- **FR-010**: Khi mở app, PHẢI **không có khung hình nền trống** (trắng hoặc đen) kéo dài đáng kể trước khi người dùng thấy logo, và không có hiện tượng **nhấp nháy/“nhảy” hình** giữa các bước hiển thị.
- **FR-011**: Hình ảnh logo đưa vào app PHẢI là **bản sạch**: chỉ có biểu tượng (và tên app khi cần), **không** chứa dòng chú thích của bản concept, không chứa khung nền/nhãn của file trình bày thiết kế.
- **FR-012**: Sau khi splash kết thúc, app PHẢI vào đúng luồng hiện có: có bật khóa → **màn khóa app**; không bật khóa → **màn Tổng quan**.
- **FR-013**: **Ngôn ngữ** và **giao diện sáng/tối** người dùng đã chọn PHẢI được áp dụng **trước khi** màn hình kế tiếp của splash hiển thị — người dùng không thấy app nháy đổi ngôn ngữ hoặc đổi màu giao diện.
- **FR-014**: Splash và icon PHẢI hiển thị đầy đủ khi **không có mạng** — phần nhận diện không được phụ thuộc vào bất kỳ tài nguyên trực tuyến nào.
- **FR-015**: Thời gian từ lúc chạm icon trên màn hình chính tới lúc logo xuất hiện PHẢI ở mức **cảm nhận là tức thì** trên thiết bị tầm trung (mục tiêu ≤ 1 giây).
- **FR-016**: Trên splash nền teal, **nửa teal của đồng xu PHẢI được phân tách khỏi nền** bằng nét trắng (viền/đường bao) — người dùng vẫn phải nhìn ra **hình đồng xu chia đôi hai màu**, không được để nửa teal chìm vào nền thành cảm giác “hình bị khuyết”.
- **FR-017**: Logo trên splash PHẢI giữ đúng tỉ lệ và bố cục của Concept A; được phép **tinh chỉnh nét cho kích thước nhỏ** (icon launcher) miễn giữ đủ **hai nửa màu + đường phân tách + hai mũi tên**.

## Tiêu chí thành công

- **SC-001**: 100% máy cài app (Android và iOS) hiển thị **logo mới** trên màn hình chính; **không còn** bất kỳ chỗ nào lộ icon mặc định của bộ khung.
- **SC-002**: Trên thiết bị tầm trung, từ lúc chạm icon tới lúc thấy logo **dưới 1 giây** trong ít nhất 95% lần mở app; không lần nào có khung nền trống kéo dài quá 0,3 giây.
- **SC-003**: Splash tự kết thúc **trong 5 giây** ở 100% lần mở app, kể cả trên máy yếu nhất mà app còn hỗ trợ.
- **SC-004**: Ở kích thước icon nhỏ nhất mà hệ điều hành dùng, người xem vẫn **nhận ra hình đồng xu chia hai nửa màu** và **hai mũi tên** — không bị nhoè thành một khối màu (điều kiện bắt buộc vì icon dùng Concept A hai màu).
- **SC-005**: 100% lần quay lại app từ nền **không** hiển thị splash (không gây cảm giác app khởi động lại).
- **SC-006**: Tên app và logo trên splash **không xuất hiện lỗi thị giác** (chữ chìm vào nền teal, logo mất tương phản, viền lạ quanh hình) ở cả giao diện Sáng và Tối — kiểm tra bằng mắt đạt 100% kịch bản.
- **SC-007**: Người dùng nhìn màn hình chính và splash **không thấy bất kỳ văn bản chú thích thiết kế** nào (tên concept, mô tả, danh sách file) — 0 lần xuất hiện.
- **SC-008**: Trên splash, **cả hai nửa đồng xu đều nhìn thấy được** — 100% người xem mô tả được logo là “đồng xu chia hai nửa khác màu”, không ai mô tả là “nửa hình tròn bị khuyết”.

## Giả định

- Phạm vi nền tảng là **hai nền tảng di động Android và iOS** đúng như định hướng sản phẩm; bản web/desktop của bộ khung không thuộc phạm vi.
- Splash **không** cố tình giữ người dùng thêm thời gian: không có thời gian chờ tối thiểu nhân tạo, chỉ chờ vừa đủ để app sẵn sàng.
- Splash nằm **trước** màn khóa app (khóa app là nghiệp vụ đã có, không thay đổi trong PBI này).
- Thời điểm kết thúc splash gắn với việc **app đã sẵn sàng hiển thị màn kế tiếp**, không gắn với một khoảng thời gian cố định.
- Hình ảnh sản xuất sẽ được **dựng lại từ chính file thiết kế trong `docs/logo/`**, loại bỏ phần trình bày concept; không vẽ logo mới, không đổi hình dạng/màu so với Concept A.
- **Cả icon launcher và splash đều dùng Concept A** (người dùng chốt), dù doc nghiệp vụ khuyến nghị Concept C cho icon launcher vì lý do rõ nét ở kích thước nhỏ. Vì vậy việc kiểm tra độ rõ ở kích thước icon là điều kiện bắt buộc, không phải tuỳ chọn (xem SC-004).
- Logo có **tên app “Sora Thu Chi”** đi kèm trên splash; tên app trên launcher giữ nguyên như hiện tại.
- Splash dùng **một phương án màu duy nhất (nền teal)** cho cả giao diện Sáng và Tối — không cần bộ asset riêng theo giao diện.
- Không cần hỗ trợ **logo động/animation** ở đợt này.
- Người dùng có thể đang ở **bất kỳ chế độ giao diện nào** (Sáng / Tối / Theo hệ thống) khi mở app.

## Ngoài phạm vi

- **Màn hình onboarding** giới thiệu tính năng cho người dùng mới.
- **Bộ nhận diện ngoài app**: favicon website, ấn phẩm marketing, ảnh đại diện mạng xã hội, banner cửa hàng ứng dụng.
- **Thay đổi tên app, tên gói ứng dụng, hay mã định danh** của app.
- **Logo trong nội dung app** — header màn Tổng quan, màn Giới thiệu trong Cài đặt, trạng thái rỗng, ảnh chia sẻ… (đã chốt là ngoài phạm vi).
- **Phương án logo B (Wallet Pulse)** và **phương án C (chữ “Đ”)** — không dùng trong PBI này.
- **Thiết kế lại màu sắc/typography** — PBI này chỉ áp dụng bộ màu đã chốt trong design system.
