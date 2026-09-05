# Đặc tả tính năng: Màn hình danh sách danh mục

**Mã PBI**: 13
**Ngày tạo**: 2026-09-05
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng cần một màn quản lý toàn bộ danh mục (phân loại thu/chi) của app — xem, tìm nhanh và đi tới các thao tác như thêm, sửa, sắp xếp. Tính năng này dựng nội dung **màn hình "Danh mục"** theo đúng thiết kế `docs/category/01-danh-sach-danh-muc.svg` — một màn con truy cập từ Cài đặt: app bar thương hiệu có tiêu đề "Danh mục", nút quay lại và điểm vào sắp xếp; bên dưới là hai tab **Chi tiêu / Thu nhập**, mỗi tab liệt kê các danh mục cấp 1 (không có danh mục cha) theo thứ tự đã thiết lập — mỗi dòng gồm icon + màu nhận diện, tên, số danh mục con (nếu có) và chevron điều hướng; góc phải dưới có FAB thêm mới. Đợt này tập trung **hiển thị đúng dữ liệu danh mục hiện có** và **dựng các điểm vào điều hướng** của màn (chạm một dòng, FAB, icon sắp xếp) — các luồng thao tác sâu (thêm/sửa, danh sách con, kéo–thả sắp xếp) chưa kích hoạt vì màn đích nằm ở PBI riêng. Màn không hiển thị số tiền; chỉ quản lý cấu trúc danh mục.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính

1. Người dùng vào **Cài đặt** và chạm mục **"Danh mục"** → màn danh sách danh mục hiện ra: app bar teal tiêu đề "Danh mục" với nút quay lại (trái) và biểu tượng sắp xếp (phải); bên dưới là hàng tab **Chi tiêu / Thu nhập** với tab "Chi tiêu" đang chọn (chữ teal đậm + gạch chân teal); phần thân là danh sách danh mục cấp 1 của loại đang xem.
2. Người dùng đọc danh sách: mỗi dòng hiển thị **icon + màu** của danh mục (trong vòng tròn nền nhạt), **tên** danh mục, dòng phụ **"N danh mục con"** (khi danh mục có con) hoặc để trống (khi không có con), và chevron `›` bên phải. Nhờ màu + icon người dùng nhận diện nhanh từng danh mục.
3. Muốn xem loại còn lại, người dùng chạm tab **"Thu nhập"** → danh sách đổi sang các danh mục thu nhập cấp 1, giữ thứ tự riêng của loại đó; chạm lại tab "Chi tiêu" để quay về.
4. Khi cần thao tác tiếp: người dùng chạm một **dòng** (dẫn tới danh sách danh mục con nếu dòng có con, hoặc sửa trực tiếp nếu không có con), chạm **FAB "+"** để thêm danh mục mới (đúng loại của tab đang mở), hoặc chạm **biểu tượng sắp xếp** ở app bar để đổi thứ tự — đây là các điểm vào dẫn tới màn được xây ở PBI sau.

### Kịch bản chấp nhận

1. **Given** người dùng đã mở khóa app và ở Cài đặt **When** chạm mục "Danh mục" **Then** màn hiển thị đúng bố cục `01-danh-sach-danh-muc.svg`: app bar teal tiêu đề "Danh mục" + nút back + biểu tượng sắp xếp, tab "Chi tiêu" đang chọn (teal, gạch chân), danh sách danh mục cấp 1 chi tiêu; màn là màn con, KHÔNG có thanh điều hướng đáy.
2. **Given** thiết bị có danh mục "Ăn uống" (chi) với 3 danh mục con, "Di chuyển" (chi) không có con **When** xem tab "Chi tiêu" **Then** dòng "Ăn uống" hiển thị icon+màu, tên và dòng phụ "3 danh mục con"; dòng "Di chuyển" hiển thị icon+màu và tên, dòng phụ để trống; cả hai có chevron bên phải và được liệt kê theo đúng thứ tự đã sắp xếp.
3. **Given** danh mục "Lương", "Thưởng" thuộc loại thu nhập **When** chạm tab "Thu nhập" **Then** danh sách chỉ còn các danh mục thu nhập cấp 1, không lẫn danh mục chi tiêu; chạm lại tab "Chi tiêu" thì danh sách chi tiêu trở lại đúng như trước.
4. **Given** danh mục "Giải trí" đang ở trạng thái ẩn **When** xem danh sách **Then** "Giải trí" vẫn xuất hiện đúng vị trí nhưng có dấu hiệu phân biệt rõ ràng (nhãn "Đã ẩn" và/hoặc icon/tên mờ), khác biệt với danh mục đang hoạt động; không bị loại khỏi màn quản lý.
5. **Given** một danh mục vừa được thêm mới ở nơi khác trong app (hoặc được sửa tên/ẩn) **When** người dùng quay lại màn "Danh mục" **Then** danh sách phản ánh đúng dữ liệu mới — dòng mới xuất hiện đúng vị trí, tên/trạng thái đã đổi — không cần thao tác làm mới thủ công.
6. **Given** danh mục không có danh mục con **When** người dùng chạm vào dòng đó **Then** dòng được xác định là điểm vào màn sửa danh mục; đợt này màn đích chưa dựng nên chạm KHÔNG gây lỗi hay treo.
7. **Given** danh mục có danh mục con **When** người dùng chạm vào dòng đó **Then** dòng được xác định là điểm vào màn danh sách danh mục con; đợt này màn đích chưa dựng nên chạm KHÔNG gây lỗi hay treo.
8. **Given** danh mục có tên dài hoặc số danh mục con nhiều chữ số **When** xem danh sách ở cỡ chữ lớn nhất hỗ trợ hoặc màn hình có vùng an toàn **Then** mỗi dòng hiển thị đầy đủ, không vỡ bố cục hay tràn, chevron và FAB không bị che/cắt.

### Trường hợp biên

- Không còn danh mục cấp 1 nào thuộc loại của tab (loại đó không có danh mục nào) → vùng danh sách hiển thị trạng thái rỗng có hướng dẫn thêm danh mục, không báo lỗi.
- Mọi danh mục cấp 1 của một loại đều đang ẩn → tab vẫn hiển thị đầy đủ các dòng (danh mục ẩn vẫn nằm trong màn quản lý), không xuất hiện trạng thái rỗng gây hiểu nhầm "không có danh mục".
- Danh mục con bị ẩn → vẫn được tính vào số "N danh mục con" của danh mục cha trên dòng cấp 1 (màn quản lý hiển thị cấu trúc đầy đủ).
- Hai danh mục cùng tên nhưng khác loại/khác cha → mỗi dòng hiển thị độc lập, không gộp.
- Danh mục hệ thống mặc định → hiển thị bình thường như danh mục tự tạo (đặc quyền "không xóa được" chỉ thể hiện khi xử lý xóa ở màn sau).
- Chuyển tab nhanh nhiều lần → danh sách hiển thị đúng loại của tab cuối, không nhầm lẫn, không giật.
- Khóa app đang có hiệu lực → màn chỉ hiển thị sau khi mở khóa theo cơ chế chung của app (màn không chứa số tiền nên không có rủi ro lộ thêm).

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI mở màn danh sách danh mục khi người dùng chạm mục "Danh mục" từ Cài đặt; màn là màn con theo đúng bố cục `docs/category/01-danh-sach-danh-muc.svg` — app bar thương hiệu có tiêu đề "Danh mục", nút quay lại, KHÔNG có thanh điều hướng đáy.
- **FR-002**: App bar PHẢI hiển thị điểm vào sắp xếp (biểu tượng bên phải theo mockup) dẫn tới màn "Sắp xếp lại thứ tự danh mục"; đợt này màn đích nằm ở PBI riêng nên điểm vào CHƯA kích hoạt luồng sâu, chạm KHÔNG gây lỗi hay treo.
- **FR-003**: Dưới app bar, hệ thống PHẢI hiển thị hàng **tab "Chi tiêu" / "Thu nhập"**; tab đang chọn PHẢI có chữ teal đậm kèm gạch chân teal, tab còn lại hiển thị mờ hơn; mặc định mở tab "Chi tiêu". Hai tab PHẢI hiển thị nội dung độc lập: "Chi tiêu" chỉ các danh mục chi, "Thu nhập" chỉ các danh mục thu.
- **FR-004**: Mỗi tab PHẢI liệt kê các **danh mục cấp 1** (không có danh mục cha) thuộc loại tương ứng, theo đúng **thứ tự đã sắp xếp** của loại đó; danh sách PHẢI giữ thứ tự ổn định giữa các lần xem và khi chuyển qua lại giữa hai tab.
- **FR-005**: Mỗi dòng danh mục PHẢI hiển thị: vòng tròn nền nhạt chứa **icon** theo màu nhận diện của danh mục, **tên** danh mục, và chevron bên phải. Khi danh mục có con, dòng PHẢI hiển thị dòng phụ **"N danh mục con"** (N là số danh mục con hiện có, gồm cả con đang ẩn); khi không có con, dòng phụ PHẢI để trống.
- **FR-006**: Danh mục đang ở trạng thái **ẩn** PHẢI vẫn xuất hiện trong danh sách đúng vị trí của nó, kèm dấu hiệu phân biệt rõ ràng với danh mục đang hoạt động (nhãn "Đã ẩn" và làm mờ icon/tên); danh mục ẩn KHÔNG bị loại khỏi màn quản lý.
- **FR-007**: Màn PHẢI thể hiện rõ ba điểm vào tương tác theo đúng mockup: **dòng danh mục** có thể chạm (có con → dẫn tới danh sách danh mục con; không con → dẫn tới sửa danh mục), **FAB "+"** thêm danh mục mới (loại theo tab đang chọn), và **biểu tượng sắp xếp** ở app bar. Đợt này các điểm vào CHƯA kích hoạt luồng sâu vì màn đích (thêm/sửa, danh sách con, sắp xếp) nằm ở PBI riêng; người dùng chạm vào KHÔNG được gây lỗi hay treo.
- **FR-008**: Danh sách PHẢI phản ánh đúng dữ liệu danh mục hiện có; khi danh mục được thêm mới / sửa tên / đổi icon-màu / chuyển cha / ẩn-hiện ở nơi khác trong app, khi người dùng quay lại màn này dữ liệu PHẢI đã cập nhật, không yêu cầu thao tác làm mới thủ công.
- **FR-009**: Khi tab không còn danh mục cấp 1 nào thuộc loại của nó, hệ thống PHẢI hiển thị trạng thái danh sách rỗng có hướng dẫn thêm danh mục, không xảy ra lỗi.
- **FR-010**: Tên danh mục dài hoặc số danh mục con nhiều chữ số PHẢI hiển thị đầy đủ, không tràn vượt vùng chứa hay làm xô lệch chevron/FAB.
- **FR-011**: Màn hình PHẢI hiển thị đầy đủ, cuộn được và không vỡ bố cục trên các kích thước màn hình, vùng an toàn và thiết lập cỡ chữ khác nhau (điện thoại).

## Tiêu chí thành công

- **SC-001**: Từ Cài đặt, chạm mục "Danh mục" và thấy danh sách + tab hiển thị đầy đủ trong không quá 1 giây với bộ dữ liệu lên tới vài trăm danh mục.
- **SC-002**: Với bộ dữ liệu mẫu khớp mockup (Ăn uống – 3 con, Di chuyển, Nhà ở…), từng tab chỉ chứa đúng danh mục cấp 1 của loại tương ứng; số dòng, tên, số danh mục con và thứ tự hiển thị khớp 100% với đối chiếu thủ công theo dữ liệu.
- **SC-003**: Chuyển qua lại giữa tab "Chi tiêu" và "Thu nhập" hiển thị đúng, không lẫn danh mục giữa hai loại, không mất vị trí/thứ tự riêng của từng tab.
- **SC-004**: Người dùng nhìn danh sách phân biệt được ngay danh mục đang ẩn với danh mục đang hoạt động mà không cần giải thích; danh mục ẩn vẫn quản lý/bỏ ẩn được ở các màn sau.
- **SC-005**: Đối chiếu trực quan với `01-danh-sach-danh-muc.svg`: vị trí app bar, nút back, biểu tượng sắp xếp, tab + gạch chân, cấu trúc dòng (icon/tên/dòng phụ/chevron) và FAB hiển thị đúng khi dữ liệu đầu vào tương ứng.
- **SC-006**: Sau khi danh mục được thêm/sửa/ẩn ở nơi khác, quay lại màn "Danh mục" thấy dữ liệu đã đúng — người dùng không phải thực hiện bất kỳ thao tác làm mới thủ công nào.
- **SC-007**: Với cỡ chữ lớn nhất và vùng an toàn khác nhau, danh sách hiển thị đầy đủ, cuộn được, không vỡ bố cục hay cắt mất nội dung dòng.
- **SC-008**: Chạm vào bất kỳ điểm vào nào (dòng danh mục, FAB, biểu tượng sắp xếp) không gây lỗi hay treo ứng dụng ở giai đoạn màn đích chưa được xây.

## Thực thể chính

- **Danh mục (category)**: dữ liệu nguồn của từng dòng và từng tab. Mỗi danh mục gồm tên (tối đa 30 ký tự), loại (thu / chi), icon, màu nhận diện, danh mục cha (cha = rỗng nghĩa là danh mục cấp 1), thứ tự sắp xếp, trạng thái hệ thống (`is_system`) và trạng thái ẩn. Danh mục có thể chứa các danh mục con (tối đa 2 cấp); số con được đếm để hiển thị trên dòng phụ. Danh mục ẩn vẫn hiển thị trên màn quản lý này.
- **Giao dịch (transaction)**: không xuất hiện trên màn này, nhưng là lý do danh mục tồn tại — giao dịch thu/chi bắt buộc gắn một danh mục; danh mục ẩn vẫn giữ nguyên trên giao dịch lịch sử (chỉ rút khỏi danh sách chọn nhanh khi nhập giao dịch).

## Giả định

- Điểm vào là mục "Danh mục" trong Cài đặt (dạng sub-page — nhất quán doc §7 và các màn con đã dựng); vị trí cụ thể của mục này trong khung Cài đặt sẽ xử ở bước lập kế hoạch nếu khung Cài đặt chưa có sẵn.
- Danh sách trong mỗi tab chỉ gồm **danh mục cấp 1** (không có cha); danh mục con được truy cập bằng cách chạm vào danh mục cha (màn danh sách con, PBI sau) — theo đúng doc §4.1.
- "N danh mục con" là số **danh mục con**, không phải số giao dịch; đếm gồm cả các danh mục con đang ẩn (màn quản lý phản ánh cấu trúc đầy đủ).
- Các ký tự chữ đơn (A, D, N…) vẽ trong vòng tròn ở mockup chỉ là chỗ trống minh họa; dữ liệu thật hiển thị icon và màu sẵn có của từng danh mục. Các con số trong mockup chỉ minh họa; số hiển thị lấy trực tiếp từ dữ liệu thiết bị.
- Tab mặc định khi mở màn là "Chi tiêu" (đúng mockup, tab này được chọn sẵn).
- FAB thêm danh mục mới ghi nhận đúng loại của tab đang chọn (đang ở tab "Thu nhập" thì thêm danh mục thu).
- Màn này không hiển thị số tiền nên không phụ thuộc quy ước tiền tệ; giai đoạn hiện tại app dùng một đơn vị tiền thống nhất, đa tiền tệ thuộc đợt sau.
- Chưa áp dụng chế độ riêng tư che số tiền (không liên quan vì màn không hiện tiền); màn chỉ hiển thị sau khi app được mở khóa theo cơ chế chung.
- App dùng chủ yếu theo chiều dọc trên điện thoại, giao diện tiếng Việt; tablet/đa ngôn ngữ chưa phải mục tiêu đợt này.

## Quyết định đã chốt

- **Hiển thị đầy đủ danh mục đang ẩn trên màn quản lý, phân biệt rõ trạng thái** — màn này là nơi quản lý danh mục, nên danh mục ẩn vẫn xuất hiện đúng vị trí kèm nhãn "Đã ẩn" và làm mờ để người dùng còn đường bỏ ẩn/sửa; trạng thái ẩn không làm tab rỗng giả. (đã chốt với người dùng)
- **Biểu tượng góc phải app bar là điểm vào màn "Sắp xếp lại thứ tự danh mục"** (màn `04`); đợt này chỉ dựng điểm vào, chưa kích hoạt luồng. (đã chốt với người dùng)
- **Phạm vi đợt này = hiển thị + dựng điểm vào, chưa kích hoạt luồng sâu** — thống nhất convention "mỗi PBI = một màn" đã dùng ở PBI 9/10/11/12. Chạm dòng (có con / không con), FAB và biểu tượng sắp xếp là điểm vào cho PBI màn thêm/sửa danh mục, màn danh sách con và màn sắp xếp (module Danh mục, làm sau); đợt này chạm vào không lỗi, không treo.

## Ngoài phạm vi

- Màn thêm / sửa danh mục (`02-them-sua-danh-muc.svg`): chọn loại, nhập tên, chọn icon/màu, chọn danh mục cha, validate trùng tên, bật/tắt ẩn.
- Màn danh sách danh mục con của một danh mục cha (`03-danh-muc-con.svg`).
- Màn sắp xếp lại thứ tự danh mục kéo–thả (`04-sap-xep-danh-muc.svg`).
- Xóa / gộp danh mục đã phát sinh giao dịch, xóa danh mục cha kèm xử lý danh mục con, hạn chế xóa danh mục hệ thống.
- Thay đổi loại (thu ↔ chi) của danh mục đã gắn giao dịch.
- Quản lý ngân sách theo danh mục, hiển thị danh mục trong báo cáo/thống kê.
- Danh sách chọn nhanh danh mục khi nhập giao dịch (đã thuộc luồng thêm giao dịch).
- Đa tiền tệ/quy đổi, dark mode, chế độ riêng tư che số tiền, tablet/đa ngôn ngữ.
