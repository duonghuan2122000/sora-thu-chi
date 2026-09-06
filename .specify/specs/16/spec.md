# Đặc tả tính năng: Sắp xếp danh mục

**Mã PBI**: 16
**Ngày tạo**: 2026-09-06
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng cần **tự đặt thứ tự hiển thị** của các danh mục theo ý mình — đưa nhóm hay dùng lên đầu, nhóm ít dùng xuống cuối — thay vì chịu thứ tự mặc định khi cài app. Tính năng này dựng **màn "Sắp xếp danh mục"** theo đúng thiết kế `docs/category/04-sap-xep-danh-muc.svg`: một màn con mở từ màn danh sách danh mục (PBI 13) khi người dùng chạm **icon "Sắp xếp"** trên app bar; app bar thương hiệu có tiêu đề "Sắp xếp danh mục" và nút **"Xong"** bên phải; bên dưới là danh sách **các danh mục cha (cấp 1)** của đúng loại đang mở — mỗi dòng có **tay cầm kéo–thả (drag handle)** bên trái, người dùng kéo lên/xuống để đổi vị trí, thay đổi được **ghi nhận ngay khi thả**. Thứ tự mới quyết định vị trí hiển thị danh mục ở mọi nơi dùng thứ tự đó: danh sách danh mục, danh sách chọn nhanh khi nhập giao dịch, chú thích biểu đồ. Đợt này chỉ sắp **danh mục cha cấp 1** (đúng mockup — list phẳng không nhóm con); thứ tự con trong từng nhóm cha–con là phạm vi sau.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app, đang ở màn danh sách danh mục.

### Luồng chính — Sắp xếp lại danh mục cha bằng kéo–thả

1. Người dùng ở màn danh sách danh mục (PBI 13), đang ở tab "Chi tiêu" hoặc "Thu nhập", chạm **icon "Sắp xếp"** trên app bar → màn "Sắp xếp danh mục" mở ra: app bar teal có nút quay lại (trái), tiêu đề "Sắp xếp danh mục", nút **"Xong"** (phải); **không** có tab riêng, **không** có thanh điều hướng đáy.
2. Danh sách hiện ra chỉ gồm **danh mục cha (cấp 1) của đúng loại** đang mở ở màn danh sách khi vào (tab "Chi tiêu" → các cha chi tiêu; tab "Thu nhập" → các cha thu nhập), xếp theo **thứ tự hiện tại** từ trên xuống. Mỗi dòng gồm **tay cầm kéo–thả** (ba gạch ngang) bên trái, vòng tròn nền nhạt chứa **icon theo màu** danh mục và **tên** danh mục; danh mục đang **ẩn** vẫn xuất hiện đúng vị trí kèm dấu hiệu phân biệt (nhãn "Đã ẩn"/làm mờ) như màn quản lý.
3. Người dùng **kéo tay cầm** một danh mục lên/xuống; các dòng khác dạt ra chừa chỗ, dòng được kéo nổi lên theo ngón tay. **Thả** ở vị trí mong muốn → danh mục đứng yên tại vị trí mới và thứ tự mới được **ghi nhận ngay**; kéo tiếp dòng khác nếu muốn.
4. Đã ưng ý, người dùng chạm **"Xong"** (hoặc back hệ thống) → trở về màn danh sách danh mục tại **đúng tab** đang mở lúc trước; danh sách hiển thị **thứ tự mới** ngay, không cần thao tác làm mới. Vì mọi thay đổi đã ghi nhận khi thả nên không có bước hủy/xác nhận khi rời màn.

### Kịch bản chấp nhận

1. **Given** người dùng ở màn danh sách danh mục, tab "Chi tiêu" đang mở **When** chạm icon "Sắp xếp" trên app bar **Then** mở màn "Sắp xếp danh mục" đúng bố cục `04-sap-xep-danh-muc.svg`: app bar teal có nút back (trái), tiêu đề "Sắp xếp danh mục", nút "Xong" (phải); danh sách là các **danh mục cha chi tiêu** (Ăn uống, Di chuyển, Nhà ở…) theo thứ tự hiện tại; mỗi dòng có tay cầm kéo–thả; màn không có tab riêng, không có thanh điều hướng đáy, không hiển thị số tiền.
2. **Given** danh sách cha chi tiêu đang theo thứ tự [Ăn uống, Di chuyển, Nhà ở, Hóa đơn] **When** người dùng kéo "Nhà ở" lên vị trí đầu tiên rồi thả **Then** danh sách thành [Nhà ở, Ăn uống, Di chuyển, Hóa đơn]; khi chạm "Xong" trở về màn danh sách, các dòng cha hiển thị theo đúng thứ tự mới này.
3. **Given** người dùng vào màn sắp xếp từ tab "Thu nhập" **When** nhìn danh sách **Then** chỉ thấy các danh mục cha thu nhập (Lương, Thưởng, Đầu tư…), không lẫn danh mục cha chi tiêu; kéo–thả chỉ hoán đổi trong nhóm cha thu nhập này.
4. **Given** danh mục cha "Di chuyển" đang ở trạng thái ẩn **When** người dùng xem màn sắp xếp **Then** "Di chuyển" vẫn xuất hiện đúng vị trí của nó trong danh sách, kèm nhãn "Đã ẩn"/làm mờ phân biệt với danh mục đang hoạt động, và kéo–thả được bình thường như các dòng khác.
5. **Given** danh mục cha "Ăn uống" đang có 3 danh mục con (Cà phê, Ăn ngoài, Đi chợ) **When** người dùng sắp xếp các danh mục cha trong màn sắp xếp **Then** các danh mục con không xuất hiện trong màn này; kéo "Ăn uống" chỉ đổi vị trí của chính nó giữa các cha, không làm thay đổi thứ tự/liên kết của các danh mục con bên trong.
6. **Given** danh sách dài nhiều danh mục cha và người dùng kéo một dòng xuống vượt ra ngoài vùng nhìn thấy **When** kéo gần mép màn hình **Then** danh sách tự cuộn theo, dòng được kéo thả đúng vào vị trí mong muốn mà không bị "bật ngược".
7. **Given** người dùng vừa đổi chỗ vài danh mục cha trong màn sắp xếp **When** chạm "Xong" (hoặc back hệ thống) **Then** trở về màn danh sách danh mục tại đúng tab đang mở trước khi vào; danh sách hiển thị thứ tự mới ngay lập tức, không cần làm mới thủ công.
8. **Given** người dùng đã sắp xếp lại danh mục và rời màn sắp xếp **When** mở lại màn sắp xếp (hoặc nhìn màn danh sách danh mục) ở lần sau **Then** thứ tự vẫn là thứ tự đã kéo lần trước — thứ tự được giữ ổn định giữa các lần mở cho tới khi người dùng chủ động thay đổi.
9. **Given** màn hình nhỏ / cỡ chữ lớn / danh sách rất nhiều danh mục cha với vài tên dài **When** người dùng cuộn và kéo–thả **Then** màn không vỡ bố cục, mỗi dòng hiển thị đầy đủ (không cắt tên/tay cầm), danh sách cuộn được tới dòng cuối.

### Trường hợp biên

- Vừa mở màn sắp xếp, chưa kéo dòng nào đã chạm "Xong"/back → trở về màn danh sách, thứ tự không đổi, không hiện cảnh báo hay bước xác nhận.
- Kéo một dòng rồi thả về **đúng vị trí cũ** → không có thay đổi thừa; thứ tự giữ nguyên, không gây nhảy hoặc ghi đè nhiễu.
- Chỉ còn **một** danh danh mục cha trong loại đang mở (tình huống phòng thủ, bình thường không xảy ra vì danh mục hệ thống không xóa được) → màn vẫn mở, hiện một dòng, thao tác kéo không gây lỗi.
- Toàn bộ danh mục cha của loại đều đang ẩn → màn vẫn truy cập được và liệt kê đủ các dòng ẩn để người dùng sắp (đúng quy ước màn quản lý hiện cả danh mục ẩn); không hiện trạng thái rỗng gây hiểu nhầm "không có danh mục".
- Danh mục cha đang được giao dịch/báo cáo/ngân sách tham chiếu → việc đổi thứ tự chỉ thay đổi vị trí hiển thị, không phá vỡ tham chiếu hay làm sai lệch dữ liệu lịch sử.
- Người dùng kéo nhanh, liên tục nhiều dòng → mỗi lần thả là một kết quả thứ tự nhất quán; danh sách không rơi vào trạng thái lệch/trùng thứ tự.
- Khóa app đang có hiệu lực → màn chỉ hiển thị sau khi mở khóa theo cơ chế chung (màn không chứa số tiền nên không phát sinh rủi ro lộ thêm).

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI mở màn "Sắp xếp danh mục" khi người dùng chạm **icon "Sắp xếp"** trên app bar của màn danh sách danh mục (PBI 13); màn là màn con theo đúng bố cục `docs/category/04-sap-xep-danh-muc.svg` — app bar thương hiệu có nút quay lại, KHÔNG có thanh điều hướng đáy.
- **FR-002**: App bar của màn sắp xếp PHẢI hiển thị tiêu đề **"Sắp xếp danh mục"**, nút quay lại bên trái và nút **"Xong"** bên phải, đúng mockup.
- **FR-003**: Màn sắp xếp PHẢI liệt kê **các danh mục cha (cấp 1) của đúng loại đang mở** ở màn danh sách khi vào (loại chi tiêu khi vào từ tab "Chi tiêu", loại thu nhập khi vào từ tab "Thu nhập"), theo **thứ tự hiển thị hiện tại**; màn KHÔNG trộn hai loại và KHÔNG liệt kê danh mục con.
- **FR-004**: Mỗi dòng danh mục PHẢI hiển thị: **tay cầm kéo–thả** bên trái, vòng tròn nền nhạt chứa **icon theo màu** của danh mục và **tên** danh mục; danh mục **ẩn** PHẢI vẫn xuất hiện đúng vị trí kèm dấu hiệu phân biệt rõ (nhãn "Đã ẩn"/làm mờ); danh mục hệ thống PHẢI nằm trong danh sách và sắp xếp được như danh mục thường.
- **FR-005**: Người dùng PHẢI kéo–thả (qua tay cầm) để đổi vị trí một danh mục cha trong danh sách; thao tác chỉ tác động trong **cùng danh sách danh mục cha cùng loại**, không tạo thao tác kéo chéo loại, kéo lồng vào danh mục khác hay làm danh mục này trở thành con của danh mục kia.
- **FR-006**: Khi người dùng **thả** dòng tại vị trí mới, hệ thống PHẢI **ghi nhận ngay thứ tự mới** của danh sách (các dòng được đánh lại vị trí liên tục từ trên xuống); khi danh sách dài, việc kéo gần mép màn hình PHẢI tự cuộn danh sách để người dùng thả đúng vị trí.
- **FR-007**: Thứ tự đã ghi nhận PHẢI được giữ ổn định giữa các lần mở màn và PHẢI được dùng làm thứ tự hiển thị ở mọi nơi dùng thứ tự danh mục — danh sách danh mục, danh sách chọn nhanh khi nhập giao dịch, chú thích biểu đồ; khi trở về màn danh sách danh mục, thứ tự mới PHẢI hiển thị ngay mà không cần thao tác làm mới thủ công.
- **FR-008**: Nút **"Xong"** (hoặc back hệ thống) PHẢI đưa người dùng trở về màn danh sách danh mục tại **đúng tab đang mở** trước khi vào; vì thay đổi đã được ghi nhận khi thả (FR-006), màn KHÔNG được yêu cầu bước xác nhận/hủy khi rời.
- **FR-009**: Màn hình PHẢI hiển thị đầy đủ, cuộn được và không vỡ bố cục trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau (điện thoại); tên dài hoặc rất nhiều danh mục cha không làm tràn/cắt tay cầm, icon hay tên dòng.

## Tiêu chí thành công

- **SC-001**: Từ màn danh sách danh mục, chạm icon "Sắp xếp" và thấy màn sắp xếp hiển thị danh sách danh mục cha đúng loại trong không quá 1 giây với bộ dữ liệu lên tới vài trăm danh mục.
- **SC-002**: Đối chiếu trực quan với `04-sap-xep-danh-muc.svg`: vị trí app bar + nút back + tiêu đề "Sắp xếp danh mục" + nút "Xong", cấu trúc dòng (tay cầm trái, icon + tên) và dấu hiệu dòng đang kéo hiển thị đúng khi dữ liệu đầu vào tương ứng.
- **SC-003**: Kéo–thả một danh mục cha lên/xuống rồi chạm "Xong", màn danh sách danh mục phản ánh **đúng 100%** thứ tự mới; mở lại màn sắp xếp thấy thứ tự giữ nguyên — không bị hoàn về thứ tự cũ hay đảo lung tung giữa các lần.
- **SC-004**: Màn sắp xếp chỉ chứa **danh mục cha cấp 1 của đúng loại đang mở** — không lẫn loại kia, không lẫn danh mục con; thứ tự và liên kết của danh mục con trong từng nhóm không bị thay đổi sau khi sắp cha.
- **SC-005**: Người dùng nhìn danh sách sắp xếp phân biệt được ngay danh mục đang ẩn với danh mục đang hoạt động (nhãn "Đã ẩn"/mờ) và kéo–thả được cả danh mục ẩn.
- **SC-006**: Chạm "Xong" hoặc back hệ thống đưa người dùng về màn danh sách danh mục tại đúng tab, không mất trạng thái; thứ tự mới xuất hiện ngay không cần thao tác làm mới thủ công.
- **SC-007**: Với cỡ chữ lớn nhất, màn hình nhỏ và bộ dữ liệu lớn, danh sách cuộn mượt, không vỡ bố cục, không cắt tay cầm/icon/tên; kéo gần mép tự cuộn và thả đúng vị trí.
- **SC-008**: Thứ tự sau khi sắp được dùng nhất quán làm thứ tự hiển thị danh mục (xác nhận ít nhất ở màn danh sách danh mục — nơi người dùng nhìn thấy ngay; các nơi khác dùng chung nguồn thứ tự này được xác nhận qua kiểm tra tích hợp).

## Thực thể chính

- **Danh mục (category)**: dữ liệu nguồn của từng dòng. Mỗi danh mục có tên (tối đa 30 ký tự), loại (thu / chi), icon, màu nhận diện, danh mục cha (nếu là danh mục con), thứ tự hiển thị, trạng thái hệ thống và trạng thái ẩn. Màn này chỉ thao tác trên tập **danh mục cha (cấp 1, không có cha) của một loại**: kéo–thả để đặt lại thứ tự hiển thị của chúng; danh mục con (cấp 2) không xuất hiện và không bị thay đổi thứ tự trong phạm vi này.
- **Giao dịch / Ngân sách / Báo cáo**: không xuất hiện trên màn; chỉ là nơi "tiêu thụ" thứ tự hiển thị danh mục (danh sách chọn danh mục khi nhập giao dịch, chú thích biểu đồ) — đổi thứ tự danh mục không làm thay đổi dữ liệu của chúng.

## Giả định

- Điểm vào màn này là **icon "Sắp xếp" trên app bar màn danh sách danh mục (PBI 13)** — hiện đang là điểm không hành động (no-op), PBI này gắn hành vi mở màn sắp xếp. Màn sắp xếp **chỉ** dành cho danh mục cấp 1; màn danh sách danh mục con (PBI 15) chưa có điểm vào sắp xếp trong phạm vi này.
- Màn sắp xếp sắp theo **đúng loại của tab đang mở** ở màn danh sách khi vào (Chi tiêu → cha chi tiêu; Thu nhập → cha thu nhập) và **không có tab riêng** — mockup `04` không vẽ tab, phù hợp luồng "vào từ tab nào thì sắp nhóm đó".
- **Mọi thay đổi thứ tự được ghi nhận ngay khi thả dòng** — không có trạng thái "bản nháp chờ lưu" hay nút hủy (mockup chỉ có "Xong"); nút "Xong" (hoặc back hệ thống) chỉ đưa người dùng về màn danh sách. App offline nên không cần cảnh báo mất thay đổi khi rời.
- Danh sách sắp xếp hiển thị **toàn bộ danh mục cha cấp 1 của loại** — gồm danh mục đang ẩn và danh mục hệ thống — theo quy ước màn quản lý (hiện cả ẩn để còn đường sắp vị trí và bỏ ẩn sau). Vị trí mới của mỗi dòng là vị trí trong danh sách sau khi kéo; toàn bộ các dòng trong danh sách được đánh lại thứ tự liên tục từ trên xuống.
- Do seed danh mục hệ thống không xóa được, mỗi loại luôn có ít nhất một danh mục cha — danh sách sắp xếp thực tế không bao giờ rỗng; trạng thái rỗng chỉ là phòng thủ cho dữ liệu bất thường.
- Kéo–thả trong màn này **chỉ hoán đổi vị trí trong cùng danh sách cha cùng loại**; mọi thao tác cấu trúc cây (kéo danh mục gốc thành con, đổi cha, thăng cấp con) nằm ngoài màn này.
- Thứ tự danh mục con trong từng nhóm cha–con giữ nguyên và sẽ được sắp xếp ở đợt sau.

## Quyết định đã chốt

- **Phạm vi đợt này = sắp danh mục cha (cấp 1)** theo đúng mockup `04` (list phẳng, không nhóm con); thứ tự danh mục con trong từng nhóm cha–con để PBI sau. (đã chốt với người dùng)
- **Danh mục đang ẩn vẫn xuất hiện trong màn sắp xếp** để kéo–thả, kèm dấu hiệu phân biệt — nhất quán với màn quản lý danh mục. (đã chốt với người dùng)

## Ngoài phạm vi

- Sắp xếp lại thứ tự **danh mục con trong từng nhóm cha–con** (kéo–thả trong nhóm; cần điểm vào từ màn danh sách danh mục con hoặc màn riêng — PBI sau).
- Cấu trúc lại cây danh mục: kéo danh mục gốc thành con của danh mục khác, đổi danh mục cha, "thăng cấp" danh mục con thành gốc ngay trong màn sắp xếp.
- Xóa / gộp / ẩn–hiện danh mục ngay trong màn sắp xếp (các thao tác này đã có ở màn thêm/sửa PBI 14).
- Sắp xếp tự động theo tiêu chí (tên, ngày tạo…) — tính năng chỉ là sắp xếp thủ công bằng kéo–thả.
- Giao diện cho thiết bị lớn/tablet, dark mode, đa ngôn ngữ, hiển thị số tiền.
