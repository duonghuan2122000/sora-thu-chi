# Đặc tả tính năng: Màn hình danh sách danh mục con

**Mã PBI**: 15
**Ngày tạo**: 2026-09-06
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng cần xem và quản lý các **danh mục con** (cấp 2) của một danh mục cha đã chọn — biết nhóm mình đang sửa có những danh mục con nào, thêm con mới ngay trong nhóm, hoặc chạm vào một con để sửa nó. Tính năng này dựng nội dung **màn hình "Danh mục con"** theo đúng thiết kế `docs/category/03-danh-muc-con.svg` — một màn con truy cập từ màn danh sách danh mục (PBI 13) khi người dùng chạm một **danh mục có con**: app bar thương hiệu hiển thị tên danh mục cha kèm dòng phụ "Danh mục con", nút quay lại và điểm thêm danh mục con; bên dưới là danh sách toàn bộ danh mục con của cha đó theo thứ tự đã thiết lập — mỗi dòng gồm icon + màu nhận diện và tên, kèm dấu hiệu phân biệt nếu con đang ẩn; cuối danh sách có điểm "Thêm danh mục con". Chạm một danh mục con dẫn tới màn **sửa danh mục**; chạm vào **vùng tiêu đề** (khối tên danh mục cha + dòng phụ "Danh mục con") mở màn **sửa danh mục cha** — chính là điểm vào sửa cho danh mục **có con** mà PBI 14 để lại cho PBI này. Thao tác **thêm danh mục con** tái dùng màn thêm/sửa danh mục (PBI 14) với danh mục cha được chọn sẵn là cha đang xem — đây là luồng "thêm nhanh danh mục con" đã chốt ở PBI 14. Màn không hiển thị số tiền; chỉ quản lý cấu trúc danh mục.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app, đang ở màn danh sách danh mục.

### Luồng chính — Xem danh mục con của một danh mục cha

1. Người dùng ở màn danh sách danh mục (PBI 13), tab "Chi tiêu" đang mở, thấy dòng "Ăn uống" kèm dòng phụ "3 danh mục con" và chạm vào dòng đó → màn "Danh mục con" hiện ra: app bar teal có nút quay lại (trái), tiêu đề là **tên danh mục cha** ("Ăn uống") với dòng phụ nhỏ "Danh mục con", và nút thêm "+" (phải); không có thanh điều hướng đáy.
2. Người dùng đọc danh sách: chỉ có các danh mục **con của "Ăn uống"** (cùng loại chi tiêu), theo đúng thứ tự đã sắp xếp của nhóm này. Mỗi dòng hiển thị **icon + màu** (trong vòng tròn nền nhạt) và **tên** danh mục con; danh mục con không có con nên dòng không hiển thị dòng phụ đếm con, chỉ có chevron `›` bên phải.
3. Muốn chỉnh một danh mục con (ví dụ đổi tên "Cà phê", đổi icon, bỏ ẩn), người dùng **chạm dòng đó** → mở màn "Sửa danh mục" của danh mục con (màn 02, PBI 14). Sửa xong và lưu, màn quay lại danh sách danh mục con này với dữ liệu đã cập nhật (tên/icon/màu/trạng thái ẩn đổi ngay trên dòng). Nếu trong lúc sửa người dùng chuyển danh mục con sang một danh mục cha khác, sau khi lưu danh mục con đó không còn xuất hiện trong danh sách này nữa (đã thuộc nhóm khác).
4. Muốn chỉnh chính danh mục cha (ví dụ đổi tên "Ăn uống", đổi icon/màu, bỏ ẩn), người dùng **chạm vào vùng tiêu đề** (khối tên cha + dòng phụ "Danh mục con") → mở màn "Sửa danh mục" của danh mục cha. Vì cha đang có con, màn sửa khóa loại và không cho chọn cha mới (giữ cây 2 cấp — đúng ràng buộc PBI 14), nhưng sửa được tên/icon/màu/trạng thái ẩn. Lưu xong, màn quay lại danh sách danh mục con: tiêu đề phản ánh tên mới, danh sách con không đổi.
5. Muốn thêm một danh mục con mới, người dùng chạm **nút "+"** trên app bar hoặc hàng **"Thêm danh mục con"** ở cuối danh sách → mở màn "Thêm danh mục" với danh mục cha đã chọn sẵn là cha đang xem (không cần chọn lại). Điền tên/icon/màu rồi lưu → màn quay lại danh sách danh mục con, danh mục mới xuất hiện ở cuối nhóm.
6. Muốn rời màn, người dùng chạm **nút quay lại** (hoặc back hệ thống) → trở về màn danh sách danh mục tại đúng tab đang mở lúc trước.

### Kịch bản chấp nhận

1. **Given** người dùng ở màn danh sách danh mục, tab "Chi tiêu" đang mở, "Ăn uống" là danh mục có 3 con **When** chạm dòng "Ăn uống" **Then** mở màn danh sách danh mục con đúng bố cục `03-danh-muc-con.svg`: app bar teal có nút back (trái), tiêu đề "Ăn uống" + dòng phụ "Danh mục con", nút "+" (phải); danh sách chỉ gồm 3 con của "Ăn uống"; màn không có thanh điều hướng đáy và không hiển thị số tiền.
2. **Given** danh mục cha "Di chuyển" có con nhưng không phải đang xem **When** người dùng chạm "Ăn uống" **Then** danh sách chỉ chứa con của "Ăn uống", không lẫn con của danh mục cha khác và không lẫn danh mục thu nhập.
3. **Given** danh mục con "Cà phê" (con của "Ăn uống") có tên dài và một danh mục con khác có tên ngắn **When** xem danh sách **Then** mỗi dòng hiển thị đầy đủ icon + màu + tên (tên dài không tràn/không cắt chevron), danh sách giữ thứ tự đã thiết lập giữa các lần xem.
4. **Given** danh mục con "Đi chợ" đang ở trạng thái ẩn **When** xem danh sách danh mục con của "Ăn uống" **Then** "Đi chợ" vẫn xuất hiện đúng vị trí nhưng có dấu hiệu phân biệt rõ ràng (nhãn "Đã ẩn" và/hoặc làm mờ), khác biệt với con đang hoạt động; không bị loại khỏi màn quản lý.
5. **Given** người dùng đang xem danh sách con của "Ăn uống" **When** chạm dòng "Cà phê" **Then** mở màn "Sửa danh mục" (PBI 14) với các trường điền sẵn dữ liệu hiện tại của "Cà phê"; ô loại hiển thị đúng loại của cha và bị khóa vì danh mục con phải cùng loại cha.
6. **Given** người dùng đang xem danh sách con của "Ăn uống" **When** chạm nút "+" trên app bar (hoặc hàng "Thêm danh mục con") **Then** mở màn "Thêm danh mục" với danh mục cha chọn sẵn là "Ăn uống" và loại tương ứng; người dùng chỉ cần nhập tên/chọn icon/màu là lưu được, không bắt buộc chọn lại cha.
7. **Given** người dùng vừa thêm danh mục con "Cà phê sữa" (hoặc vừa sửa tên/ẩn một danh mục con ở màn thêm/sửa) **When** quay lại màn danh sách danh mục con của "Ăn uống" **Then** danh sách phản ánh đúng dữ liệu mới — dòng mới xuất hiện cuối nhóm, tên/trạng thái con đã sửa đổi — không cần thao tác làm mới thủ công.
8. **Given** người dùng đang xem danh sách con của "Ăn uống" **When** chạm nút quay lại (hoặc back hệ thống) **Then** quay về màn danh sách danh mục tại đúng tab đang mở trước khi vào (vd tab "Chi tiêu"), danh mục cha "Ăn uống" hiển thị số danh mục con đã cập nhật nếu có thay đổi.
9. **Given** người dùng đang xem danh sách con của "Ăn uống" **When** chạm vào **vùng tiêu đề** (khối "Ăn uống" + "Danh mục con") **Then** mở màn "Sửa danh mục" của "Ăn uống" — danh mục cha đang có con nên ô loại bị khóa và không chọn được danh mục cha mới, nhưng sửa được tên/icon/màu/trạng thái ẩn; sửa xong và lưu, quay lại màn danh sách con với tiêu đề phản ánh tên mới, danh sách con không đổi, không cần làm mới thủ công.
10. **Given** người dùng đang xem danh sách con của "Ăn uống" **When** chạm vùng tiêu đề để sửa cha, đổi tên cha rồi lưu **Then** khi quay về màn danh sách danh mục (nút back) dòng "Ăn uống" hiển thị tên mới và vẫn giữ số danh mục con đúng.

### Trường hợp biên

- Danh mục cha không có danh mục con nào → theo luồng PBI 13, chạm danh mục không con mở màn sửa (không vào màn danh sách con); nếu vì lý do nào đó mở tới màn này khi không còn con, vùng danh sách hiển thị trạng thái rỗng có hướng dẫn thêm danh mục con, không báo lỗi.
- Toàn bộ danh mục con của cha đều đang ẩn → tab/cha vẫn truy cập được và danh sách hiển thị đầy đủ các con (cả con ẩn) theo đúng quy ước màn quản lý; không xuất hiện trạng thái rỗng gây hiểu nhầm "không có danh mục con".
- Danh mục cha đang ở trạng thái ẩn nhưng vẫn có con → vẫn truy cập được màn danh sách con từ màn danh sách danh mục (nơi hiển thị cả danh mục ẩn); màn danh sách con không cần nhắc lại trạng thái ẩn của cha ở khu vực danh sách.
- Hai danh mục con cùng tên nhưng khác cha → mỗi màn danh sách con chỉ hiển thị con của một cha nên không gộp, không xung đột.
- Rất nhiều danh mục con / tên dài / màn hình nhỏ / cỡ chữ lớn → danh sách cuộn được, dòng không tràn hay cắt, nút thêm không bị che.
- Chạm thêm/sửa nhanh nhiều lần, hoặc vừa thêm con xong lại thêm tiếp → mỗi lần chỉ tạo/sửa đúng một danh mục, không trùng lặp; màn danh sách con phản ánh đúng trạng thái sau mỗi lần quay lại.
- Trong lúc sửa một danh mục con, có thay đổi trạng thái ở nơi khác (vd danh mục vừa phát sinh giao dịch đầu tiên) → khi lưu, màn thêm/sửa (PBI 14) đánh giá lại ràng buộc theo trạng thái hiện tại; màn danh sách con chỉ phản ánh kết quả sau khi lưu.
- Chạm **vùng tiêu đề** để sửa cha không được đè lên nút quay lại (trái) hay nút "+" (phải) — vùng chạm nằm riêng giữa hai nút; chạm nhầm một trong hai nút vẫn thực hiện đúng hành động của nút đó.
- Sửa danh mục cha chỉ đổi tên/icon/màu/trạng thái ẩn (loại và cha khóa vì có con) → danh sách con không bị ảnh hưởng; danh mục cha đang ẩn vẫn mở màn danh sách con và sửa được như bình thường (màn quản lý hiển thị cả danh mục ẩn).
- Khóa app đang có hiệu lực → màn chỉ hiển thị sau khi mở khóa theo cơ chế chung của app (màn không chứa số tiền nên không có rủi ro lộ thêm).

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI mở màn danh sách danh mục con khi người dùng chạm một **danh mục có danh mục con** trên màn danh sách danh mục (PBI 13); màn là màn con theo đúng bố cục `docs/category/03-danh-muc-con.svg` — app bar thương hiệu có nút quay lại, KHÔNG có thanh điều hướng đáy.
- **FR-002**: App bar PHẢI hiển thị tiêu đề là **tên của danh mục cha** đang xem, kèm dòng phụ **"Danh mục con"** và nút quay lại ở bên trái, theo đúng mockup.
- **FR-003**: Vùng tiêu đề trên app bar (khối tên danh mục cha + dòng phụ "Danh mục con", nằm giữa nút quay lại và nút "+") PHẢI là một **điểm chạm mở màn "Sửa danh mục" của danh mục cha**. Vì danh mục cha đang có con, màn sửa PHẢI khóa loại và không cho chọn danh mục cha mới (giữ cây 2 cấp) nhưng PHẢI cho sửa tên/icon/màu/trạng thái ẩn; vùng chạm KHÔNG được đè lên nút quay lại hay nút "+".
- **FR-004**: Dưới app bar, hệ thống PHẢI liệt kê các **danh mục con của danh mục cha đang xem** (có danh mục cha trỏ tới danh mục này, cùng loại), theo đúng **thứ tự đã thiết lập** của nhóm đó; danh sách PHẢI giữ thứ tự ổn định giữa các lần xem.
- **FR-005**: Mỗi dòng danh mục con PHẢI hiển thị: vòng tròn nền nhạt chứa **icon** theo màu nhận diện của danh mục, **tên** danh mục con, và chevron bên phải; vì danh mục con không thể có con (cây tối đa 2 cấp), dòng KHÔNG hiển thị dòng phụ đếm số danh mục con.
- **FR-006**: Danh mục con đang ở trạng thái **ẩn** PHẢI vẫn xuất hiện trong danh sách đúng vị trí của nó, kèm dấu hiệu phân biệt rõ ràng với danh mục đang hoạt động (nhãn "Đã ẩn" và làm mờ icon/tên); danh mục con ẩn KHÔNG bị loại khỏi màn quản lý.
- **FR-007**: Khi người dùng chạm một **danh mục con**, hệ thống PHẢI mở màn "Sửa danh mục" (PBI 14) của chính danh mục con đó — các trường điền sẵn dữ liệu hiện tại; danh mục con là cấp 2 nên loại của nó bị khóa (luôn cùng loại cha).
- **FR-008**: Màn PHẢI thể hiện **điểm thêm danh mục con** đúng mockup: nút "+" ở app bar (góc phải) và hàng **"Thêm danh mục con"** ở cuối danh sách. Cả hai PHẢI mở màn "Thêm danh mục" (PBI 14) với **danh mục cha chọn sẵn là danh mục đang xem** và loại tương ứng.
- **FR-009**: Danh sách PHẢI phản ánh đúng dữ liệu danh mục con hiện có; khi một danh mục con được thêm mới / sửa tên / đổi icon-màu / bật-tắt ẩn (qua màn thêm/sửa PBI 14), khi quay lại màn này dữ liệu PHẢI đã cập nhật, không yêu cầu thao tác làm mới thủ công. Sau khi sửa danh mục cha (FR-003) và lưu, tiêu đề màn PHẢI phản ánh tên/trạng thái mới mà không cần làm mới thủ công.
- **FR-010**: Khi một danh mục con được chuyển sang danh mục cha khác trong lúc sửa, sau khi lưu danh mục con đó PHẢI rời khỏi danh sách của cha cũ (thuộc nhóm mới); nếu danh mục cha đang xem không còn con nào, màn PHẢI hiển thị trạng thái phù hợp, không lỗi.
- **FR-011**: Nút quay lại (và back hệ thống) PHẢI đưa người dùng trở về màn danh sách danh mục tại **đúng tab đang mở** trước khi vào, với số danh mục con của cha đã phản ánh thay đổi (nếu có).
- **FR-012**: Màn hình PHẢI hiển thị đầy đủ, cuộn được và không vỡ bố cục trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau (điện thoại); tên dài hoặc rất nhiều danh mục con không làm tràn/cắt nội dung hay che mất điểm thêm.

## Tiêu chí thành công

- **SC-001**: Từ màn danh sách danh mục, chạm một danh mục có con và thấy màn danh sách con hiển thị đầy đủ trong không quá 1 giây với bộ dữ liệu lên tới vài trăm danh mục.
- **SC-002**: Đối chiếu trực quan với `03-danh-muc-con.svg`: vị trí app bar + nút back + tiêu đề (tên cha + dòng phụ "Danh mục con") + nút thêm, cấu trúc dòng (icon/tên/chevron) và điểm "Thêm danh mục con" hiển thị đúng khi dữ liệu đầu vào tương ứng.
- **SC-003**: Với bộ dữ liệu mẫu khớp mockup ("Ăn uống" có Cà phê, Ăn ngoài, Đi chợ), danh sách chỉ chứa đúng danh mục con của cha đang xem, đúng loại và đúng thứ tự — đối chiếu 100% với dữ liệu; không lẫn con của cha khác, không lẫn loại khác.
- **SC-004**: Người dùng nhìn danh sách phân biệt được ngay danh mục con đang ẩn với danh mục con đang hoạt động mà không cần giải thích; danh mục con ẩn vẫn sửa/bỏ ẩn được qua màn thêm/sửa.
- **SC-005**: Chạm một danh mục con mở đúng màn "Sửa danh mục" của con đó với 100% dữ liệu hiện tại được điền sẵn; sửa xong và lưu, quay lại màn danh sách con thấy dữ liệu đã đúng, không cần thao tác làm mới thủ công.
- **SC-006**: Chạm nút "+" app bar hoặc hàng "Thêm danh mục con" mở màn "Thêm danh mục" với danh mục cha đã chọn sẵn là cha đang xem; người dùng hoàn tất việc thêm một con (từ lúc chạm điểm thêm đến khi con mới xuất hiện ở cuối danh sách con) trong dưới 1 phút.
- **SC-007**: Nút quay lại (hoặc back hệ thống) đưa người dùng về màn danh sách danh mục tại đúng tab đang mở, không mất vị trí/thứ tự; số danh mục con của cha phản ánh đúng sau các thao tác thêm/sửa.
- **SC-008**: Với cỡ chữ lớn nhất và vùng an toàn khác nhau, danh sách hiển thị đầy đủ, cuộn được, không vỡ bố cục hay cắt mất nội dung dòng / điểm thêm.
- **SC-009**: Chạm vùng tiêu đề mở đúng màn "Sửa danh mục" của danh mục cha đang xem (danh mục có con): loại bị khóa, không chọn được cha mới, sửa được tên/icon/màu/ẩn; lưu xong quay lại màn danh sách con thấy tiêu đề đã đổi, danh sách con giữ nguyên — người dùng không cần thao tác làm mới thủ công.

## Thực thể chính

- **Danh mục (category)**: dữ liệu nguồn của từng dòng. Mỗi danh mục gồm tên (tối đa 30 ký tự), loại (thu / chi), icon, màu nhận diện, danh mục cha (`parent_id`), thứ tự sắp xếp, trạng thái hệ thống (`is_system`) và trạng thái ẩn. Màn này chỉ liệt kê các danh mục **con** (có `parent_id` trỏ tới danh mục cha đang xem); danh mục con thuộc cấp 2 nên không có con tiếp theo. Danh mục cha là một danh mục cấp 1 (gốc) đã chốt là "có con" để vào được màn này. Danh mục con ẩn vẫn hiển thị trên màn quản lý này.
- **Giao dịch (transaction)**: không xuất hiện trên màn này; chỉ là lý do ràng buộc tồn tại (danh mục gắn giao dịch thì loại bị khóa khi sửa, xử lý ở màn thêm/sửa PBI 14).

## Giả định

- Điểm vào màn này là **màn danh sách danh mục (PBI 13)**: chạm một danh mục **có danh mục con** → mở màn danh sách danh mục con; chạm danh mục **không có con** → vẫn mở màn sửa trực tiếp (đúng luồng đã chốt PBI 13/14, không đổi).
- Màn danh sách con chỉ hiển thị danh mục **con trực tiếp** của cha đang xem; đã có con trước khi vào nên vùng danh sách thường không rỗng — trạng thái rỗng chỉ là phòng thủ (vd toàn bộ con chuyển cha/xóa ở đợt sau).
- "Thêm nhanh danh mục con" tái dùng màn Thêm (PBI 14) với cha preset; đây là luồng PBI 14 đã chốt sẽ dùng ở màn danh sách con. Màn thêm/sửa vẫn cho người dùng đổi cha/loại theo đúng ràng buộc của nó; màn danh sách con chỉ quyết định giá trị khởi tạo.
- Chạm một danh mục con → mở **màn sửa** (danh mục con cấp 2 không thể có con nên không có trường hợp "chạm con có con" đi tiếp). Sửa danh mục con vận hành theo đúng ràng buộc màn sửa PBI 14 (loại khóa do là con; vẫn đổi được tên/icon/màu/cha cùng loại/ẩn).
- Ký tự chữ đơn (C, Ă, Đ…) vẽ trong vòng tròn ở mockup chỉ là chỗ trống minh họa; dữ liệu thật hiển thị bằng icon và màu nhận diện sẵn có của từng danh mục con. Màu cam trong mockup chỉ minh họa, không phải màu cố định.
- Thứ tự hiển thị danh mục con lấy theo `sort_order` hiện có của nhóm; việc kéo–thả sắp xếp lại thuộc màn riêng (PBI sau), màn này không hiển thị điều khiển sắp xếp.
- Màn không hiển thị số tiền nên không phụ thuộc quy ước tiền tệ / chế độ che tiền; chỉ hiển thị sau khi mở khóa theo cơ chế chung.
- App dùng chủ yếu theo chiều dọc trên điện thoại, giao diện tiếng Việt; tablet/đa ngôn ngữ chưa phải mục tiêu đợt này.

## Quyết định đã chốt

- **Điểm sửa danh mục cha đang có con = chạm vùng tiêu đề trên app bar** — màn 03 mockup không vẽ nút sửa cha riêng; giữ mockup nguyên, biến khối tiêu đề (tên cha + dòng phụ "Danh mục con", giữa nút back và nút "+") thành điểm chạm mở màn "Sửa danh mục" của cha. Đây là điểm vào sửa cho danh mục **có con** mà PBI 14 để lại cho PBI này (danh mục có con không mở được màn sửa từ màn danh sách). Vì cha có con, màn sửa khóa loại và không cho chọn cha mới, chỉ sửa tên/icon/màu/trạng thái ẩn. (đã chốt với người dùng)

## Ngoài phạm vi

- Màn sắp xếp lại thứ tự danh mục kéo–thả (`04-sap-xep-danh-muc.svg`), gồm cả sắp xếp trong nhóm cha–con.
- Xóa / gộp danh mục (kể cả xóa danh mục con, xử lý con khi xóa cha, hạn chế xóa danh mục hệ thống).
- Cấu trúc lại cây danh mục ngoài luồng sửa đã có (vd kéo danh mục gốc thành con của danh mục khác ở màn này).
- Hiển thị/liên kết ngân sách hoặc số giao dịch theo danh mục con; báo cáo/thống kê.
- Danh sách chọn nhanh danh mục khi nhập giao dịch (thuộc PBI 11); chỉ chịu ảnh hưởng gián tiếp khi danh mục bị ẩn/hiện.
- Đa tiền tệ/quy đổi, dark mode, chế độ riêng tư che số tiền, tablet/đa ngôn ngữ.
