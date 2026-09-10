# Đặc tả tính năng: Chọn ngôn ngữ hiển thị (Tiếng Việt / English)

**Mã PBI**: 19
**Ngày tạo**: 2026-09-10
**Trạng thái**: Nháp

## Mô tả tổng quan

Người dùng cần đổi **ngôn ngữ hiển thị của app** giữa **Tiếng Việt** và **English** — toàn bộ nhãn giao diện (điều hướng, tiêu đề, nút, nhãn trường, dòng phụ cài đặt, tên danh mục mặc định) hiển thị theo ngôn ngữ đã chọn. Tính năng này dựng **màn con "Ngôn ngữ"** theo đúng thiết kế `docs/tool/03-ngon-ngu.svg`: mở từ hàng **"Ngôn ngữ"** của màn Tiện ích & Cá nhân hóa (PBI 17 đã dựng), liệt kê **2 lựa chọn dạng radio**, người dùng chọn cái nào app đổi ngôn ngữ **ngay lập tức** (không cần khởi động lại), lựa chọn **được nhớ** khi mở lại màn và cả sau khi tắt hẳn app. Mặc định khi chưa từng đổi là **Tiếng Việt**. Đổi ngôn ngữ **không** đổi dữ liệu người dùng tự nhập và **không** đổi định dạng ngày/số tiền (định dạng là cài đặt riêng ở màn "Định dạng & Tiền tệ").

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app, đang ở màn Tiện ích & Cá nhân hóa (màn `01`).

### Luồng chính — Chọn ngôn ngữ Tiếng Việt / English

1. Người dùng ở màn Tiện ích & Cá nhân hóa, chạm hàng **"Ngôn ngữ"** (đang hiển thị giá trị "Tiếng Việt") → màn con **"Ngôn ngữ"** mở ra: app bar thương hiệu có nút quay lại (trái) và tiêu đề "Ngôn ngữ"; **không** có thanh điều hướng đáy.
2. Thân màn liệt kê **2 lựa chọn** theo mockup `03`, mỗi hàng là một card bo góc gồm: **vòng tròn chứa mã ngôn ngữ** (VI nền teal nhạt khi được chọn, EN nền nhạt khi chưa chọn), **tên ngôn ngữ**, **dòng phụ là tên ngôn ngữ đó bằng ngôn ngữ còn lại**, và **nút radio** ở cuối hàng:
   - **Tiếng Việt** — dòng phụ "Vietnamese"
   - **English** — dòng phụ "Tiếng Anh"
3. Lần đầu tiên người dùng vào màn này (chưa từng đổi ngôn ngữ), radio **"Tiếng Việt"** được chọn sẵn.
4. Người dùng chạm hàng **"English"** → radio hàng đó chuyển thành đã chọn (chấm teal), radio "Tiếng Việt" bỏ chọn; **toàn bộ nhãn giao diện của app đổi sang tiếng Anh ngay lập tức** — màn đang đứng (tiêu đề app bar đổi thành "Language", ghi chú cuối màn cũng đổi), thanh điều hướng đáy, và mọi màn khác — không cần khởi động lại.
5. Ghi chú cuối màn nhắc: thay đổi áp dụng ngay cho toàn bộ giao diện và nhãn danh mục mặc định; định dạng ngày/số vẫn giữ theo cài đặt "Định dạng & Tiền tệ".
6. Người dùng quay lại màn Tiện ích (nút quay lại hoặc back hệ thống) → hàng **"Ngôn ngữ"** ở màn `01` giờ hiển thị giá trị khớp lựa chọn vừa chọn, và tên hàng/dòng phụ của cả màn Tiện ích hiển thị bằng ngôn ngữ mới.
7. Người dùng tắt hẳn app rồi mở lại → app vẫn ở ngôn ngữ đã chọn (nhãn điều hướng, tiêu đề, nút đều bằng ngôn ngữ đó); vào lại màn "Ngôn ngữ" thấy radio vẫn nằm đúng lựa chọn.
8. Ở ngôn ngữ mới, dữ liệu người dùng tự nhập (tên giao dịch, ghi chú, tên ví, tag, tên danh mục người dùng tự tạo) **giữ nguyên** như đã nhập; tên **danh mục mặc định chưa bị đổi tên** hiển thị theo ngôn ngữ mới; số tiền và ngày **giữ nguyên định dạng cũ**.

### Kịch bản chấp nhận

1. **Given** người dùng ở màn Tiện ích & Cá nhân hóa **When** chạm hàng "Ngôn ngữ" **Then** mở màn con "Ngôn ngữ" đúng bố cục `03-ngon-ngu.svg`: app bar thương hiệu có nút quay lại, tiêu đề "Ngôn ngữ", không có thanh điều hướng đáy.
2. **Given** màn "Ngôn ngữ" vừa mở **When** nhìn thân màn **Then** thấy đúng 2 lựa chọn theo thứ tự **Tiếng Việt – English**, mỗi hàng là card gồm vòng tròn mã ngôn ngữ (VI/EN), tên ngôn ngữ, dòng phụ (tên ngôn ngữ đó bằng ngôn ngữ còn lại) và nút radio ở cuối; nội dung tên/dòng phụ đúng mockup.
3. **Given** người dùng chưa từng đổi ngôn ngữ **When** mở màn "Ngôn ngữ" lần đầu **Then** radio "Tiếng Việt" được chọn sẵn, radio "English" bỏ trống.
4. **Given** app đang ở Tiếng Việt **When** người dùng chạm hàng "English" **Then** radio "English" chuyển thành chọn (chấm teal), radio "Tiếng Việt" bỏ chọn, và ngay trong lần chạm đó toàn bộ nhãn giao diện đổi sang tiếng Anh — tiêu đề màn đang mở, thanh điều hướng đáy, màn Tiện ích và các màn khác — không cần khởi động lại app.
5. **Given** người dùng chọn "English" rồi quay lại màn Tiện ích **When** nhìn hàng "Ngôn ngữ" **Then** giá trị hiển thị là "English"; tắt hẳn app mở lại, app vẫn hiển thị tiếng Anh, vào lại màn "Ngôn ngữ" thấy radio "English" đang chọn.
6. **Given** app đang ở English **When** xem các màn có danh mục **Then** tên **danh mục mặc định chưa bị đổi tên** hiển thị bằng tiếng Anh; danh mục người dùng tự tạo hoặc danh mục mặc định đã bị đổi tên giữ nguyên đúng tên người dùng đặt.
7. **Given** app đang ở English **When** xem tên/ghi chú giao dịch, tên ví, tag, và số tiền/ngày tháng **Then** dữ liệu người dùng tự nhập giữ nguyên không dịch; số tiền vẫn định dạng dấu chấm nghìn + đơn vị `đ`, ngày vẫn theo định dạng hiện hành — đổi ngôn ngữ KHÔNG làm đổi định dạng ngày/số.
8. **Given** cỡ chữ lớn nhất, màn hình nhỏ, nhãn tiếng Anh dài hơn tiếng Việt **When** người dùng cuộn và nhìn từng hàng **Then** màn không vỡ bố cục, mỗi hàng hiển thị đủ vòng tròn mã ngôn ngữ + tên + dòng phụ + radio, không cắt chữ, cuộn tới được hàng cuối.
9. **Given** app đang ở English **When** người dùng mở lại app và đi qua các màn hiện có (Cài đặt, Tiện ích & Cá nhân hóa, Giao diện, Ví, Giao dịch, Danh mục) **Then** không còn nhãn giao diện tĩnh nào còn tiếng Việt (trừ dữ liệu người dùng và tên riêng/thương hiệu).

### Trường hợp biên

- Vừa mở màn "Ngôn ngữ", chưa chạm gì đã quay lại → trở về màn Tiện ích bình thường, không hiện cảnh báo, ngôn ngữ không đổi.
- Người dùng chạm nhanh liên tiếp hai hàng qua lại → trạng thái cuối phản ánh đúng lần chạm cuối, radio không nhảy lung tung.
- Chọn ngôn ngữ mới rồi **tắt hẳn app ngay** trước khi rời màn → khi mở lại, app vẫn ở ngôn ngữ vừa chọn.
- Danh mục mặc định (do app tạo) đã bị người dùng **đổi tên** → giữ nguyên tên người dùng đặt ở mọi ngôn ngữ; đổi ngôn ngữ không làm mất tên đó và cũng không khôi phục lại tên mặc định.
- Danh mục do người dùng **tự tạo** → không bao giờ bị dịch.
- Tên riêng/thương hiệu trong dữ liệu mẫu (Vietcombank, Momo, VIB) → giữ nguyên, không dịch.
- Người dùng đổi ngôn ngữ rồi **đổi giao diện sáng/tối** (PBI 18) hoặc ngược lại → hai cài đặt độc lập, không cái nào ghi đè cái kia; lựa chọn còn lại vẫn được giữ.
- Chuỗi tiếng Anh dài hơn tiếng Việt ở nhãn nút/hàng cài đặt/nút điều hướng → hiển thị đủ nghĩa, không bị cắt cụt giữa từ, không đẩy tràn ra ngoài màn.
- Màn chỉ là khung chưa có nội dung nghiệp vụ (Tổng quan, Báo cáo) → tiêu đề của chúng cũng hiển thị theo ngôn ngữ đã chọn.
- Khóa app đang có hiệu lực → màn chỉ truy cập được sau khi mở khóa theo cơ chế chung; màn không chứa số tiền nên không phát sinh rủi ro lộ thêm. Nhãn màn khóa PIN cũng hiển thị theo ngôn ngữ đã chọn.

## Yêu cầu chức năng

- **FR-001**: Hàng **"Ngôn ngữ"** của màn Tiện ích & Cá nhân hóa (màn `01`, PBI 17) PHẢI mở được màn con **"Ngôn ngữ"** — điểm vào no-op ở PBI 17 nay kích hoạt thành màn con này; màn mở theo đúng bố cục `docs/tool/03-ngon-ngu.svg`: app bar thương hiệu có nút quay lại, tiêu đề "Ngôn ngữ", KHÔNG có thanh điều hướng đáy.
- **FR-002**: Màn PHẢI liệt kê đúng **2 lựa chọn theo thứ tự Tiếng Việt, English**, mỗi hàng là card gồm **vòng tròn chứa mã ngôn ngữ (VI / EN)**, **tên ngôn ngữ**, **dòng phụ là tên ngôn ngữ đó bằng ngôn ngữ còn lại** ("Vietnamese" / "Tiếng Anh") và **nút radio** ở cuối — đối chiếu trực quan với mockup `03`.
- **FR-003**: Mỗi lựa chọn PHẢI chọn được **duy nhất một** (radio): chạm một hàng làm hàng đó chuyển thành đã chọn (chấm teal) và hàng trước đó bỏ chọn; không cho phép hai lựa chọn cùng lúc.
- **FR-004**: Lần đầu người dùng mở màn (chưa từng chọn ngôn ngữ) PHẢI có radio **"Tiếng Việt"** được chọn sẵn — giá trị mặc định là Tiếng Việt.
- **FR-005**: Khi người dùng chọn một lựa chọn, **toàn bộ nhãn giao diện tĩnh của app** PHẢI đổi sang ngôn ngữ đó **ngay lập tức**, bao gồm màn đang mở (kể cả tiêu đề app bar và ghi chú cuối màn của chính màn "Ngôn ngữ"), thanh điều hướng đáy, và mọi màn khác, **không yêu cầu khởi động lại app**.
- **FR-006**: Lựa chọn ngôn ngữ PHẢI **được nhớ**: quay lại màn rồi mở lại, và sau khi tắt hẳn app rồi mở lại, app PHẢI hiển thị theo ngôn ngữ đã chọn và màn "Ngôn ngữ" PHẢI hiển thị radio đúng lựa chọn hiện hành.
- **FR-007**: Hàng **"Ngôn ngữ"** ở màn Tiện ích & Cá nhân hóa (màn `01`) PHẢI hiển thị giá trị khớp lựa chọn hiện hành ("Tiếng Việt" / "English") và PHẢI được cập nhật lại sau mỗi lần đổi — thay cho giá trị "Tiếng Việt" cố định như ở PBI 17. Tên hàng và dòng phụ của màn `01` cũng PHẢI hiển thị theo ngôn ngữ đã chọn.
- **FR-008**: **Phạm vi dịch**: PHẢI phủ **toàn bộ nhãn giao diện tĩnh của các màn hiện có** — tiêu đề màn, nhãn thanh điều hướng đáy, nút, nhãn trường nhập liệu, nhãn/giá trị nhóm cài đặt (gồm cả các giá trị của hàng "Giao diện": Sáng / Tối / Theo hệ thống — PBI 18), dòng phụ, trạng thái rỗng, thông báo/hộp thoại trong app, và nhãn màn khóa app.
- **FR-009**: PHẢI dịch **tên danh mục mặc định do app tạo khi người dùng chưa đổi tên** (cả danh mục cha lẫn danh mục con) sang ngôn ngữ đã chọn.
- **FR-010**: **KHÔNG được dịch**: dữ liệu người dùng tự nhập — tên giao dịch, ghi chú, tag, tên ví, tên danh mục do người dùng tự tạo hoặc đã đổi tên; và tên riêng/thương hiệu (Vietcombank, Momo, VIB). Đổi ngôn ngữ KHÔNG làm thay đổi, mất hay khôi phục lại bất kỳ dữ liệu nào của người dùng.
- **FR-011**: Đổi ngôn ngữ **KHÔNG được** làm đổi **định dạng ngày và số tiền**: số tiền vẫn giữ quy tắc hiện hành (phân tách nghìn bằng dấu chấm, đơn vị `đ` đặt sau), ngày tháng vẫn theo định dạng hiện hành — định dạng là cài đặt riêng của màn "Định dạng & Tiền tệ" (PBI khác).
- **FR-012**: Ngôn ngữ PHẢI **độc lập** với giao diện sáng/tối (PBI 18) và với các cài đặt cá nhân hóa khác: đổi ngôn ngữ không làm thay đổi các lựa chọn đó và ngược lại.
- **FR-013**: Màn "Ngôn ngữ" PHẢI hiển thị đầy đủ, cuộn được và không vỡ bố cục trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau; nhãn tiếng Anh dài hơn không được làm tràn/cắt vòng tròn mã ngôn ngữ, tên, dòng phụ hay radio.

## Tiêu chí thành công

- **SC-001**: Từ màn Tiện ích & Cá nhân hóa, chạm hàng "Ngôn ngữ" và thấy màn hiển thị đủ 2 lựa chọn trong không quá 1 giây.
- **SC-002**: Đối chiếu trực quan với `03-ngon-ngu.svg`: app bar + nút quay lại + tiêu đề, đủ 2 hàng đúng thứ tự Tiếng Việt – English, cấu trúc mỗi hàng (mã ngôn ngữ trong vòng tròn trái, tên + dòng phụ, radio phải) và ghi chú cuối màn hiển thị đúng.
- **SC-003**: Mở màn "Ngôn ngữ" khi chưa từng đổi ngôn ngữ → radio "Tiếng Việt" được chọn sẵn, không có lựa chọn thứ hai cùng chọn.
- **SC-004**: Chọn lần lượt English rồi Tiếng Việt → 100% số lần chọn, toàn bộ nhãn giao diện đổi đúng ngay lần chạm đó, ở màn đang mở lẫn màn khác, không cần khởi động lại app.
- **SC-005**: Chọn "English", tắt hẳn app rồi mở lại → app hiển thị tiếng Anh; hàng "Ngôn ngữ" màn `01` hiển thị "English"; vào lại màn "Ngôn ngữ" thấy radio "English" đang chọn — giữ đúng qua mọi lần kiểm tra.
- **SC-006**: Ở ngôn ngữ English, đi qua tất cả các màn hiện có → không còn nhãn giao diện tĩnh nào hiển thị tiếng Việt (ngoại trừ dữ liệu người dùng tự nhập và tên riêng/thương hiệu); tỉ lệ nhãn tĩnh được dịch đạt 100%.
- **SC-007**: Ở ngôn ngữ English, danh mục mặc định chưa đổi tên hiển thị bằng tiếng Anh; danh mục người dùng tự tạo/đã đổi tên, tên giao dịch, ghi chú, tên ví, tag hiển thị nguyên văn như trước khi đổi — 100% không bị dịch hay biến đổi.
- **SC-008**: Sau khi đổi ngôn ngữ, số tiền hiển thị vẫn đúng định dạng cũ (dấu chấm nghìn, đơn vị `đ`) và ngày tháng không đổi định dạng ở cả hai ngôn ngữ.
- **SC-009**: Đổi ngôn ngữ rồi đổi giao diện sáng/tối (và ngược lại) → cả hai lựa chọn đều được giữ đúng, không cái nào ghi đè cái kia, qua các lần mở lại app.
- **SC-010**: Với cỡ chữ lớn nhất và màn hình nhỏ, màn "Ngôn ngữ" và các màn có nhãn tiếng Anh dài không vỡ bố cục, không cắt chữ, cuộn tới được phần tử cuối.

## Thực thể chính

- **Cài đặt ngôn ngữ**: lựa chọn ngôn ngữ hiển thị của app, một trong hai giá trị **Tiếng Việt / English**, mặc định **Tiếng Việt**. Được lưu trên thiết bị và giữ nguyên qua các lần mở app; là một mục trong nhóm cài đặt cá nhân hóa (cùng chỗ lưu lựa chọn giao diện và các công tắc tiện ích của PBI 17/18). Giá trị này là nguồn cho cả màn chọn (radio đang chọn) lẫn giá trị hiển thị ở hàng "Ngôn ngữ" màn `01`, và là nguồn cho toàn bộ nhãn giao diện của app.
- **Bộ nhãn dịch**: hai bộ nhãn tĩnh song song (Tiếng Việt và English) phủ toàn bộ chuỗi giao diện của các màn hiện có; mỗi nhãn tĩnh trong app tương ứng một mục ở cả hai bộ. Đây là dữ liệu của app, không phải dữ liệu của người dùng.
- **Ánh xạ tên danh mục mặc định**: quan hệ giữa danh mục mặc định do app tạo và nhãn dịch tương ứng ở từng ngôn ngữ; chỉ áp dụng khi danh mục **chưa bị người dùng đổi tên** — danh mục đã đổi tên hoặc do người dùng tạo thì luôn hiển thị tên người dùng đặt.

## Giả định

- **Mặc định là Tiếng Việt**: đã thể hiện ở mockup `03` (radio "Tiếng Việt" được tô chọn) và ở giá trị "Tiếng Việt" của hàng Ngôn ngữ màn `01` (PBI 17). Người dùng hiện hữu đang dùng app tiếng Việt nên mặc định này không làm đổi hành vi sẵn có.
- **Chỉ có 2 ngôn ngữ, không có lựa chọn "Theo hệ thống"**: mockup `03` chỉ có Tiếng Việt và English, không có lựa chọn tự đổi theo ngôn ngữ điện thoại (khác với theme ở PBI 18).
- **Phạm vi đợt này là toàn bộ app**: tài liệu giải pháp §2.1 chốt "phạm vi dịch: toàn bộ label giao diện tĩnh" — nên PBI này phủ tất cả màn hiện có, không dịch dần theo từng đợt. Các module chưa dựng (Báo cáo có nội dung, thông báo đẩy, insight tự động, Widget) sẽ tự tuân thủ khi được dựng.
- **Nội dung tiếng Anh do đội dự án biên soạn**, không phải bản dịch chuyên nghiệp có kiểm duyệt; yêu cầu là đúng nghĩa, nhất quán thuật ngữ và không còn sót tiếng Việt ở nhãn tĩnh.
- **Tách bạch ngôn ngữ và định dạng**: theo tài liệu giải pháp §2.2, định dạng ngày/số **không** đổi theo ngôn ngữ (một người có thể dùng English UI nhưng vẫn muốn định dạng ngày kiểu Việt Nam) — nên ở đợt này số tiền vẫn hiển thị kiểu `42.500.000 đ` ngay cả khi giao diện là English, cho tới khi màn "Định dạng & Tiền tệ" (PBI sau) được dựng.
- **Tên ví mẫu do app tạo** (Tiền mặt, Thẻ tín dụng VIB, Sổ tiết kiệm…) là **dữ liệu người dùng → không dịch** (đã chốt, xem mục Điểm cần làm rõ).
- **Màn "Ngôn ngữ" (`03`) là màn con của shell**, không chứa số tiền nên không phát sinh rủi ro lộ thông tin thêm; khóa app tuân theo cơ chế chung.
- Nhãn màn khóa app (PIN/sinh trắc học) cũng nằm trong phạm vi dịch, vì người dùng cần hiểu màn đó trước khi vào được app.

## Quyết định đã chốt

- **Giá trị mặc định là "Tiếng Việt"** khi người dùng chưa từng đổi ngôn ngữ. (theo mockup `03` + giá trị sẵn có ở màn `01` PBI 17)
- **Đổi ngôn ngữ không đổi định dạng ngày/số tiền** — định dạng thuộc màn "Định dạng & Tiền tệ" (PBI sau). (theo tài liệu giải pháp §2.2)

## Điểm cần làm rõ

*(Không còn điểm mở — cả hai điểm dưới đây đã được người dùng chốt ngày 2026-09-10.)*

- [ĐÃ CHỐT: **Tên ví mẫu do app tạo** ("Tiền mặt", "Thẻ tín dụng VIB", "Sổ tiết kiệm") — **KHÔNG dịch**, coi là dữ liệu người dùng và giữ nguyên như tài liệu §2.1. Lý do: bảng ví không có cờ "do app tạo"; bộ ví mẫu sẽ bị gỡ khi có dữ liệu thật. (⇒ R7 trong `research.md`)]
- [ĐÃ CHỐT: **Nhãn 2 hàng màn `03`** (tên ngôn ngữ + dòng phụ) — **cố định như mockup** ở cả hai chế độ (`Tiếng Việt`/`Vietnamese`, `English`/`Tiếng Anh`), không đi qua bản đồ dịch; chỉ tiêu đề app bar và ghi chú chân màn mới dịch. Lý do: đây là tên riêng của ngôn ngữ, đúng mockup ở cả hai chế độ. (⇒ R8 trong `research.md`)]

## Ngoài phạm vi

- Các màn con tiện ích khác — Định dạng & Tiền tệ (`04`), Máy tính nhập tiền (`05`), Tìm kiếm toàn cục (`06`), Quản lý Tag (`07`) — vẫn là các PBI sau; PBI này chỉ dựng màn Ngôn ngữ (`03`).
- Đổi **định dạng ngày, tiền tệ, đầu tuần, kỳ tài chính** theo ngôn ngữ hoặc theo vùng — thuộc màn `04`.
- Thêm ngôn ngữ thứ ba hoặc cơ chế tải gói ngôn ngữ từ ngoài; lựa chọn "theo ngôn ngữ hệ thống".
- Dịch **dữ liệu người dùng tự nhập** (tên giao dịch, ghi chú, tag, tên ví, tên danh mục người dùng tạo/đã đổi tên).
- Dịch **thông báo đẩy** và **insight tự động** — hai module này chưa được dựng; sẽ tuân thủ ngôn ngữ đã chọn khi được dựng ở PBI sau.
- Hiệu ứng chức năng của các công tắc ở màn `01` (Ẩn số dư, Máy tính nhập tiền) và Widget màn hình chính.
- Hỗ trợ thiết bị màn hình lớn/tablet riêng.
