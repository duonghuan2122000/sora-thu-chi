# Đặc tả tính năng: Thay đổi giao diện Sáng / Tối / Theo hệ thống

**Mã PBI**: 18
**Ngày tạo**: 2026-09-06
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng cần chọn giao diện hiển thị của app theo ý muốn — **Sáng** (nền trắng, chữ tối), **Tối** (nền tối, chữ sáng, đỡ mỏi mắt ban đêm) hoặc **Theo hệ thống** (tự đổi theo cài đặt sáng/tối của điện thoại). Tính năng này dựng **màn con "Giao diện"** theo đúng thiết kế `docs/tool/02-giao-dien.svg`: mở từ hàng **"Giao diện"** của màn Tiện ích & Cá nhân hóa (PBI 17 đã dựng), liệt kê 3 lựa chọn dạng radio, người dùng chọn cái nào app đổi sang giao diện đó **ngay lập tức** (không cần khởi động lại), lựa chọn **được nhớ** khi mở lại màn và cả sau khi tắt hẳn app. Khi mặc định chưa từng đổi, app hoạt động **Theo hệ thống**.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app, đang ở màn Tiện ích & Cá nhân hóa (màn `01`).

### Luồng chính — Chọn giao diện Sáng / Tối / Theo hệ thống

1. Người dùng ở màn Tiện ích & Cá nhân hóa, chạm hàng **"Giao diện"** (đang hiển thị giá trị "Hệ thống") → màn con **"Giao diện"** mở ra: app bar teal có nút quay lại (trái) và tiêu đề "Giao diện"; **không** có thanh điều hướng đáy.
2. Thân màn liệt kê **3 lựa chọn** theo mockup `02`, mỗi hàng là một card bo góc gồm: **icon minh họa** trong vòng nền nhạt (mặt trời vàng cho "Sáng", mặt trăng cho "Tối", hình thiết bị cho "Theo hệ thống"), **tên** lựa chọn, **dòng phụ** mô tả, và **nút radio** ở cuối hàng:
   - **Sáng** — "Nền trắng, chữ tối"
   - **Tối** — "Nền tối, chữ sáng, đỡ mỏi mắt ban đêm"
   - **Theo hệ thống** — "Tự đổi theo cài đặt điện thoại"
3. Lần đầu tiên người dùng vào màn này (chưa từng đổi theme), radio **"Theo hệ thống"** được chọn sẵn.
4. Người dùng chạm vào một hàng → radio của hàng đó chuyển thành đã chọn (chấm teal), lựa chọn trước đó bỏ chọn; **toàn bộ app đổi giao diện ngay lập tức** sang lựa chọn mới — cả màn đang đứng lẫn các màn khác, không cần khởi động lại. Ghi chú cuối màn nhắc "Thay đổi được áp dụng ngay lập tức, không cần khởi động lại ứng dụng."
5. Người dùng chọn **"Theo hệ thống"** → app hiển thị theo chế độ hiện tại của điện thoại; khi điện thoại đổi giữa sáng/tối, app tự đổi theo mà không cần mở lại màn.
6. Người dùng quay lại màn Tiện ích (nút quay lại hoặc back hệ thống) → hàng **"Giao diện"** ở màn `01` giờ hiển thị giá trị khớp lựa chọn vừa chọn (Sáng / Tối / Theo hệ thống).
7. Người dùng tắt hẳn app rồi mở lại → app vẫn ở giao diện đã chọn; vào lại màn "Giao diện" thấy radio vẫn nằm đúng lựa chọn đó.

### Kịch bản chấp nhận

1. **Given** người dùng ở màn Tiện ích & Cá nhân hóa **When** chạm hàng "Giao diện" **Then** mở màn con "Giao diện" đúng bố cục `02-giao-dien.svg`: app bar teal có nút quay lại, tiêu đề "Giao diện", không có thanh điều hướng đáy.
2. **Given** màn "Giao diện" vừa mở **When** nhìn thân màn **Then** thấy đủ 3 lựa chọn theo đúng thứ tự **Sáng – Tối – Theo hệ thống**, mỗi hàng là card gồm icon trong vòng nền nhạt, tên, dòng phụ và nút radio ở cuối; nội dung tên/dòng phụ đúng mockup.
3. **Given** người dùng chưa từng đổi theme **When** mở màn "Giao diện" lần đầu **Then** radio "Theo hệ thống" được chọn sẵn, các radio khác bỏ trống.
4. **Given** giao diện đang "Sáng" **When** người dùng chạm hàng "Tối" **Then** radio "Tối" chuyển thành chọn (chấm teal), radio "Sáng" bỏ chọn, toàn bộ app đổi sang nền tối/chữ sáng ngay trong lần chạm đó — màn đang mở và màn khác đều đổi, không cần khởi động lại app.
5. **Given** người dùng chọn "Tối" rồi quay lại màn Tiện ích **When** nhìn hàng "Giao diện" **Then** giá trị hiển thị là "Tối"; tắt hẳn app mở lại, app vẫn giao diện tối, vào lại màn "Giao diện" thấy radio "Tối" đang chọn.
6. **Given** người dùng chọn "Theo hệ thống" **When** điện thoại đổi giữa chế độ sáng và tối **Then** app tự đổi giao diện theo, người dùng không cần thao tác gì.
7. **Given** giao diện tối đang hiển thị **When** nhìn màu sắc và số liệu của app **Then** màu thương hiệu (teal) và màu phân biệt thu/chi (teal/coral) vẫn giữ được nhận diện, số tiền vẫn định dạng đúng (dấu chấm nghìn, đơn vị `đ`), nội dung người dùng tự nhập và ảnh đính kèm không bị đổi màu/đảo màu.
8. **Given** cỡ chữ lớn nhất, màn hình nhỏ, tên/dòng phụ dài **When** người dùng cuộn và nhìn từng hàng **Then** màn không vỡ bố cục, mỗi hàng hiển thị đủ icon + tên + dòng phụ + radio, cuộn tới được hàng cuối.

### Trường hợp biên

- Vừa mở màn "Giao diện", chưa chạm gì đã quay lại → trở về màn Tiện ích bình thường, không hiện cảnh báo, giá trị không đổi.
- Người dùng chạm nhanh liên tiếp các hàng khác nhau → trạng thái cuối phản ánh đúng lần chạm cuối, radio không nhảy lung tung.
- Chọn giao diện mới rồi **tắt hẳn app ngay** trước khi rời màn → khi mở lại, app vẫn giữ giao diện vừa chọn.
- Thiết bị được đặt ở chế độ cố định (không tự đổi sáng/tối theo giờ) và người dùng chọn "Theo hệ thống" → app hiển thị theo chế độ hiện hành của thiết bị và hoạt động bình thường; chỉ là không có sự kiện tự đổi trong ngày.
- Ở giao diện tối, có màn/ứng dụng dùng màu cứng chưa đổi theo theme → màn đó phải vẫn đọc được, không "chìm" hẳn trên nền tối.
- Khóa app đang có hiệu lực → màn chỉ truy cập được sau khi mở khóa theo cơ chế chung; màn không chứa số tiền nên không phát sinh rủi ro lộ thêm.

## Yêu cầu chức năng

- **FR-001**: Hàng **"Giao diện"** của màn Tiện ích & Cá nhân hóa (màn `01`, PBI 17) PHẢI mở được màn con **"Giao diện"** — điểm vào no-op ở PBI 17 nay kích hoạt thành màn con này; màn mở theo đúng bố cục `docs/tool/02-giao-dien.svg`: app bar thương hiệu có nút quay lại, tiêu đề "Giao diện", KHÔNG có thanh điều hướng đáy.
- **FR-002**: Màn PHẢI liệt kê đúng **3 lựa chọn theo thứ tự Sáng, Tối, Theo hệ thống**, mỗi hàng là card gồm **icon minh họa trong vòng nền nhạt** (mặt trời / mặt trăng / thiết bị), **tên**, **dòng phụ** và **nút radio** ở cuối — đối chiếu trực quan với mockup `02`.
- **FR-003**: Mỗi lựa chọn PHẢI chọn được **duy nhất một** (radio): chạm một hàng làm hàng đó chuyển thành đã chọn (chấm teal) và hàng trước đó bỏ chọn; không cho phép hai lựa chọn cùng lúc.
- **FR-004**: Lần đầu người dùng mở màn (chưa từng chọn theme) PHẢI có radio **"Theo hệ thống"** được chọn sẵn — giá trị mặc định là "Theo hệ thống".
- **FR-005**: Khi người dùng chọn một lựa chọn, toàn bộ app PHẢI đổi giao diện (sáng/tối/theo hệ thống) **ngay lập tức** theo lựa chọn đó, bao gồm màn đang mở và các màn khác, **không yêu cầu khởi động lại app**.
- **FR-006**: Lựa chọn giao diện PHẢI **được nhớ**: quay lại màn rồi mở lại, và sau khi tắt hẳn app rồi mở lại, app PHẢI ở giao diện đã chọn và màn "Giao diện" PHẢI hiển thị radio đúng lựa chọn hiện hành.
- **FR-007**: Hàng **"Giao diện"** ở màn Tiện ích & Cá nhân hóa (màn `01`) PHẢI hiển thị giá trị khớp lựa chọn hiện hành ("Sáng" / "Tối" / "Theo hệ thống") thay cho giá trị cũ, và PHẢI được cập nhật lại sau mỗi lần đổi — thay vì giá trị "Hệ thống" cố định như ở PBI 17.
- **FR-008**: Khi lựa chọn là **"Theo hệ thống"** và điện thoại đổi giữa sáng/tối, app PHẢI tự đổi giao diện theo mà người dùng không cần mở lại màn hay thao tác gì.
- **FR-009**: Giao diện **tối** PHẢI giữ nhận diện thương hiệu: màu chính (teal) dùng cho hành động/trạng thái chọn, màu thu = teal và chi = coral vẫn phân biệt rõ, số tiền giữ nguyên quy tắc định dạng (dấu chấm nghìn, đơn vị `đ`); ảnh hóa đơn đính kèm và nội dung do người dùng tự nhập KHÔNG được đổi màu theo theme.
- **FR-010**: Màn PHẢI hiển thị đầy đủ, cuộn được và không vỡ bố cục trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; tên/dòng phụ dài không làm tràn/cắt icon, tên, dòng phụ hay radio.

## Tiêu chí thành công

- **SC-001**: Từ màn Tiện ích & Cá nhân hóa, chạm hàng "Giao diện" và thấy màn hiển thị đủ 3 lựa chọn trong không quá 1 giây.
- **SC-002**: Đối chiếu trực quan với `02-giao-dien.svg`: app bar + nút quay lại + tiêu đề "Giao diện", đủ 3 hàng đúng thứ tự Sáng – Tối – Theo hệ thống, cấu trúc mỗi hàng (icon trong vòng nhạt trái, tên + dòng phụ, radio phải) và ghi chú cuối màn hiển thị đúng.
- **SC-003**: Mở màn "Giao diện" khi chưa từng đổi theme → radio "Theo hệ thống" được chọn sẵn, không có lựa chọn thứ hai cùng chọn.
- **SC-004**: Chọn lần lượt "Tối", "Sáng", "Theo hệ thống" → app đổi giao diện đúng theo từng lần chạm, 100% số lần thử, ở màn đang mở lẫn màn khác, không cần khởi động lại app.
- **SC-005**: Chọn "Tối", tắt hẳn app rồi mở lại → app ở giao diện tối; hàng "Giao diện" màn `01` hiển thị "Tối"; vào lại màn "Giao diện" thấy radio "Tối" đang chọn — giữ đúng qua mọi lần kiểm tra.
- **SC-006**: Ở chế độ "Theo hệ thống", đổi thiết bị giữa sáng ↔ tối → app tự đổi theo đúng, không cần mở lại màn, không cần khởi động lại.
- **SC-007**: Ở giao diện tối, màu teal/coral, chữ chính/chữ phụ và nền card đạt đủ tương phản để đọc rõ; không có vùng chữ/nền nào bị "chìm" gây khó đọc nội dung và số liệu.
- **SC-008**: Với cỡ chữ lớn nhất, màn hình nhỏ và tên/dòng phụ dài, danh sách cuộn mượt, không vỡ bố cục, không cắt icon/tên/dòng phụ/radio.

## Thực thể chính

- **Cài đặt giao diện (theme)**: lựa chọn hiển thị của app, một trong ba giá trị **Sáng / Tối / Theo hệ thống**, mặc định **Theo hệ thống**. Được lưu trên thiết bị, giữ nguyên qua các lần mở app; là một mục trong nhóm cài đặt cá nhân hóa (cùng chỗ lưu các lựa chọn tiện ích khác của PBI 17). Giá trị này là nguồn cho cả màn chọn (radio đang chọn) lẫn giá trị hiển thị ở hàng "Giao diện" màn `01`.

## Giả định

- **Giá trị mặc định là "Theo hệ thống"** — đã chốt với người dùng để khớp giá trị "Hệ thống" màn `01` (PBI 17). Trạng thái "Sáng" được tô chọn trong mockup `02` chỉ minh họa một lúc app đang sáng, không phải yêu cầu mặc định.
- **Tên gọi thống nhất**: "Theo hệ thống" (màn `02`) và "Hệ thống" (giá trị cũ màn `01`) chỉ cùng một lựa chọn; từ PBI này màn `01` hiển thị đúng tên "Theo hệ thống".
- **Bảng màu tối kế thừa design system đã chốt**: giữ teal thương hiệu và cặp teal (thu) / coral (chi), chỉ điều chỉnh độ sáng/độ tương phản cần thiết cho nền tối; việc chọn mã màu cụ thể là chi tiết triển khai, không thuộc đặc tả này.
- Màn "Giao diện" (`02`) là màn con của shell, không chứa số tiền nên không phát sinh rủi ro lộ thông tin thêm; khóa app tuân theo cơ chế chung.
- Các màn Flutter hiện có được dựng theo design system sẽ tự hiển thị đúng ở cả hai giao diện; màn nào dùng màu cứng cần được xử lý để đọc được ở giao diện tối (yêu cầu chất lượng ở SC-007, không phải tính năng riêng).

## Quyết định đã chốt

- **Giá trị mặc định là "Theo hệ thống"** khi người dùng chưa từng đổi theme. (đã chốt với người dùng)

## Ngoài phạm vi

- Các màn con tiện ích khác — Ngôn ngữ (`03`), Định dạng & Tiền tệ (`04`), Máy tính nhập tiền (`05`), Tìm kiếm toàn cục (`06`), Quản lý Tag (`07`) — vẫn là các PBI sau; PBI này chỉ dựng màn Giao diện (`02`).
- Hiệu ứng chức năng của các công tắc ở màn `01` (Ẩn số dư thật sự che số tiền, Máy tính thay bàn phím nhập tiền) — PBI sau.
- Đa ngôn ngữ giao diện (i18n) — PBI riêng.
- Phát triển thêm lựa chọn giao diện ngoài 3 chế độ Sáng/Tối/Theo hệ thống (vd theme màu tùy biến).
- Hỗ trợ thiết bị màn hình lớn/tablet riêng.
