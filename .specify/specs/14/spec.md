# Đặc tả tính năng: Màn hình thêm / sửa danh mục

**Mã PBI**: 14
**Ngày tạo**: 2026-09-05
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng cần tạo danh mục mới và chỉnh sửa danh mục đang có để phân loại giao dịch thu/chi theo ý muốn — nhập/sửa tên, chọn loại (thu/chi), chọn biểu tượng + màu nhận diện, gắn vào danh mục cha, bật/tắt trạng thái ẩn. Tính năng này dựng **màn "Thêm danh mục" / "Sửa danh mục"** theo đúng thiết kế `docs/category/02-them-sua-danh-muc.svg` — một màn con truy cập từ màn danh sách danh mục (PBI 13): người dùng chạm **FAB "+"** để thêm mới (loại mặc định theo tab đang mở) hoặc chạm một **danh mục không có con** để sửa danh mục đó. Màn kiểm tra tính hợp lệ trước khi lưu (tên bắt buộc, không trùng tên trong cùng nhóm cha/loại, giữ cây tối đa 2 cấp, tôn trọng ràng buộc loại) rồi lưu và quay lại màn danh sách — dữ liệu hiển thị ở màn danh sách phản ánh ngay kết quả. Màn **không** chứa thao tác xóa danh mục (xóa/gộp thuộc PBI riêng).

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app, đang ở màn danh sách danh mục.

### Luồng chính — Thêm danh mục mới

1. Người dùng ở màn danh sách danh mục (tab nào đang mở cũng được) và chạm **FAB "+"** → màn "Thêm danh mục" hiện ra: app bar teal có nút quay lại và tiêu đề "Thêm danh mục", không có thanh điều hướng đáy; nút lưu nằm ở góc phải app bar và ở nút chính cuối màn.
2. Màn mặc định chọn sẵn **loại** theo tab của màn danh sách lúc nhấn FAB (đang ở tab "Thu nhập" thì mở sẵn loại thu nhập); người dùng có thể chuyển qua lại giữa **"Chi tiêu" / "Thu nhập"** bằng điều khiển dạng pill trước khi lưu.
3. Người dùng **nhập tên** danh mục (bắt buộc, tối đa 30 ký tự). Nếu tên trùng với một danh mục khác cùng nhóm cha + cùng loại (kể cả bản đang ẩn), màn báo lỗi ngay và chặn lưu.
4. Người dùng **chọn biểu tượng** từ bộ biểu tượng có sẵn (đã có một biểu tượng được chọn sẵn) và **chọn màu** từ bảng màu gợi ý (đã có một màu được chọn sẵn, có dấu kiểm).
5. Muốn biến danh mục mới thành **danh mục con**, người dùng chạm ô "Danh mục cha (tùy chọn)" và chọn một danh mục gốc **cùng loại** đang được chọn; để trống (mặc định "Không có — là danh mục gốc") nghĩa là tạo danh mục cấp 1.
6. Người dùng chạm **"Lưu danh mục"** → nếu hợp lệ, danh mục mới được thêm vào cuối nhóm tương ứng và màn quay lại danh sách danh mục, nơi danh mục mới xuất hiện đúng vị trí mà không cần làm mới thủ công. Nếu người dùng quay lại mà chưa lưu, không có gì được tạo.

### Luồng chính — Sửa danh mục (không có con)

1. Người dùng ở màn danh sách danh mục chạm một **danh mục không có con** → màn "Sửa danh mục" hiện ra với **tiêu đề "Sửa danh mục"** và các trường **điền sẵn dữ liệu hiện tại**: tên, biểu tượng, màu, danh mục cha (nếu có), trạng thái ẩn.
2. Người dùng sửa **tên / biểu tượng / màu / danh mục cha / trạng thái ẩn** theo nhu cầu. Ô **loại** hiển thị loại hiện tại của danh mục: người dùng **chỉ đổi được loại khi danh mục chưa từng gắn giao dịch nào, không có danh mục con, và đang là danh mục gốc**; ngoài các trường hợp đó điều khiển loại hiện ở dạng khóa (không đổi được).
3. Người dùng chạm **"Lưu danh mục"** (hoặc nút "Lưu" góc phải app bar) → nếu hợp lệ, thay đổi được lưu và màn quay lại danh sách danh mục; dòng danh mục phản ánh ngay tên/icon/màu/trạng thái mới. Nếu quay lại chưa lưu, danh mục giữ nguyên như cũ.

### Kịch bản chấp nhận

1. **Given** người dùng ở màn danh sách danh mục, tab "Chi tiêu" đang mở **When** chạm FAB "+" **Then** mở màn "Thêm danh mục" đúng bố cục `02-them-sua-danh-muc.svg`: app bar teal tiêu đề "Thêm danh mục" + nút back, điều khiển loại đang chọn "Chi tiêu", trường tên rỗng, bộ chọn biểu tượng & màu có mục chọn sẵn, ô "Danh mục cha" mặc định "Không có — là danh mục gốc", công tắc "Ẩn khỏi danh sách nhanh" tắt, nút chính "Lưu danh mục"; màn KHÔNG có thanh điều hướng đáy.
2. **Given** người dùng đang mở tab "Thu nhập" trên màn danh sách **When** chạm FAB "+" **Then** màn "Thêm danh mục" mở với loại "Thu nhập" được chọn sẵn (người dùng vẫn chuyển được sang "Chi tiêu" trước khi lưu).
3. **Given** người dùng đang ở màn "Thêm danh mục" **When** nhập tên hợp lệ, chọn biểu tượng + màu và chạm "Lưu danh mục" **Then** danh mục mới xuất hiện ở cuối nhóm tương ứng trên màn danh sách danh mục (đúng tab loại, đúng nhóm cha nếu chọn cha), không cần làm mới thủ công.
4. **Given** đã có danh mục "Ăn uống" (chi, gốc) **When** người dùng thêm một danh mục chi khác tên "Ăn uống" và bấm lưu **Then** màn báo lỗi trùng tên ngay dưới ô tên, không lưu; trường hợp tên trùng với một danh mục **đang ẩn** cùng nhóm cũng bị chặn tương tự.
5. **Given** người dùng đang thêm danh mục loại chi **When** chuyển sang loại "Thu nhập" **Then** ô "Danh mục cha" chỉ còn liệt kê các danh mục **gốc thu nhập**, không lẫn danh mục chi; nếu đang chọn cha chi thì lựa chọn được đưa về "Không có — là danh mục gốc".
6. **Given** người dùng ở màn danh sách chạm danh mục "Cà phê" (con của "Ăn uống", không có con) **When** màn "Sửa danh mục" mở **Then** các trường điền sẵn đúng dữ liệu "Cà phê"; ô loại hiển thị "Chi tiêu" và ở dạng khóa vì "Cà phê" là danh mục con (phải cùng loại cha).
7. **Given** một danh mục chưa từng gắn giao dịch, không con, đang là gốc **When** người dùng sửa nó và đổi loại từ "Chi tiêu" sang "Thu nhập" rồi lưu **Then** danh mục chuyển sang loại thu nhập, xuất hiện ở cuối danh sách thu nhập trên màn danh mục; không còn ở tab chi tiêu.
8. **Given** một danh mục **đã từng gắn giao dịch** **When** người dùng mở màn sửa **Then** ô loại hiện ở dạng khóa (không đổi được), các trường tên/icon/màu/cha/ẩn vẫn sửa bình thường.
9. **Given** người dùng sửa một danh mục và bật công tắc "Ẩn khỏi danh sách nhanh" rồi lưu **Then** danh mục đó hiển thị trạng thái "Đã ẩn" trên màn danh sách danh mục (đúng quy ước PBI 13) và không còn xuất hiện trong danh sách chọn nhanh khi nhập giao dịch, nhưng giao dịch lịch sử gắn với nó không đổi.
10. **Given** người dùng đang sửa danh mục **không có con** và chọn một danh mục cha khác (hoặc bỏ cha để thành danh mục gốc) **When** lưu **Then** danh mục chuyển về đúng nhóm cha mới, xếp ở cuối nhóm đó; tên mới không trùng với danh mục cùng nhóm đích.
11. **Given** người dùng đang sửa một danh mục **có con** **When** nhìn màn **Then** ô loại bị khóa và ô "Danh mục cha" không cho chọn cha mới (danh mục có con phải luôn là danh mục gốc để giữ cây 2 cấp); vẫn sửa được tên/icon/màu/trạng thái ẩn.
12. **Given** người dùng nhập tên chỉ gồm khoảng trắng hoặc bỏ trống tên **When** bấm lưu **Then** màn báo "tên danh mục không được để trống", không lưu.
13. **Given** người dùng bỏ trống lựa chọn biểu tượng hoặc màu (không xảy ra với lựa chọn mặc định) **When** bấm lưu **Then** màn báo cần chọn biểu tượng/màu, không lưu.
14. **Given** người dùng chỉnh xong và lưu thành công **When** màn quay lại danh sách danh mục **Then** danh sách phản ánh ngay dữ liệu mới (dòng mới xuất hiện / tên, icon, màu, trạng thái ẩn đổi), không cần làm mới thủ công; chạm back trước khi lưu thì không có thay đổi nào được ghi nhận.

### Trường hợp biên

- Sửa danh mục **giữ nguyên tên hiện tại** → không báo trùng tên với chính nó; lưu bình thường.
- Sửa danh mục **đang ẩn** → mở màn sửa bình thường, công tắc "Ẩn khỏi danh sách nhanh" đang bật; tắt công tắc rồi lưu để bỏ ẩn.
- Nhập tên dài đúng 30 ký tự → hợp lệ; quá 30 → không nhập thêm được.
- Danh mục gốc có con đang được sửa: không cho đổi loại lẫn chọn cha (giữ cây 2 cấp), nhưng đổi tên/icon/màu/ẩn đều hợp lệ.
- Thêm/sửa khi danh mục cha dự định chọn là một danh mục **cấp 2** → danh sách cha chỉ liệt kê cấp 1 nên không chọn được (không thể tạo cấp 3).
- Mở màn sửa một danh mục mà giữa chừng có thay đổi trạng thái ở nơi khác (ví dụ danh mục vừa phát sinh giao dịch đầu tiên) → khi lưu hệ thống đánh giá lại theo trạng thái hiện tại, không lưu sai ràng buộc loại.
- Hai danh mục cùng tên khác loại hoặc khác cha → hợp lệ (không trùng nhóm), lưu được.
- Tên danh mục dài / màn hình nhỏ / cỡ chữ lớn → màn cuộn được, các trường và nút lưu không vỡ bố cục, nút chính không bị che.
- Chạm lưu nhiều lần nhanh → chỉ lưu một lần, không tạo trùng danh mục.
- Khóa app đang có hiệu lực → màn chỉ hiển thị sau khi mở khóa theo cơ chế chung của app (màn không hiển thị số tiền).

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI mở màn thêm/sửa danh mục theo đúng bố cục `docs/category/02-them-sua-danh-muc.svg` khi người dùng khởi tạo thao tác từ màn danh sách danh mục: **FAB "+"** mở chế độ **Thêm**, chạm một **danh mục không có con** mở chế độ **Sửa** với tiêu đề tương ứng ("Thêm danh mục" / "Sửa danh mục"); màn là màn con — app bar thương hiệu có nút quay lại, KHÔNG có thanh điều hướng đáy.
- **FR-002**: Màn PHẢI hiển thị điều khiển chọn **loại** "Chi tiêu" / "Thu nhập" ở đầu màn. Ở chế độ Thêm, người dùng PHẢI chọn được cả hai loại và loại mặc định PHẢI theo tab của màn danh sách lúc chạm FAB; ở chế độ Sửa, màn PHẢI hiển thị loại hiện tại và chỉ cho đổi khi danh mục thỏa cả ba điều kiện: chưa từng gắn giao dịch, không có danh mục con, đang là danh mục gốc.
- **FR-003**: Người dùng PHẢI nhập được **tên** danh mục, bắt buộc, tối đa 30 ký tự (tính sau khi cắt khoảng trắng thừa ở hai đầu); tên chỉ toàn khoảng trắng được coi là để trống.
- **FR-004**: Hệ thống PHẢI chặn **trùng tên** trong cùng nhóm (cùng loại + cùng danh mục cha; danh mục gốc tính theo từng loại) — kể cả khi bản trùng đang ở trạng thái ẩn — và báo lỗi ngay dưới ô tên, không cho lưu; danh mục đang sửa không bị tính là trùng với chính nó.
- **FR-005**: Người dùng PHẢI chọn được **biểu tượng** từ bộ biểu tượng có sẵn (một mục luôn được chọn sẵn, thể hiện rõ mục đang chọn) và chọn được **màu nhận diện** từ bảng màu gợi ý (một màu luôn được chọn sẵn, có dấu kiểm); việc chọn biểu tượng và màu PHẢI phản ánh ngay lên nội dung ô tên/mục chọn nếu thiết kế yêu cầu.
- **FR-006**: Người dùng PHẢI chọn được **danh mục cha (tùy chọn)**: mặc định "Không có — là danh mục gốc"; danh sách cha PHẢI chỉ gồm các danh mục **gốc cùng loại** đang chọn (không liệt kê danh mục cấp 2, không lẫn loại khác) và PHẢI được lọc lại khi người dùng đổi loại (lựa chọn cha không còn hợp loại phải được đưa về "Không có").
- **FR-007**: Người dùng PHẢI bật/tắt được **"Ẩn khỏi danh sách nhanh"** bằng công tắc; ở chế độ Thêm công tắc mặc định tắt, ở chế độ Sửa phản ánh trạng thái ẩn hiện tại của danh mục.
- **FR-008**: Hệ thống PHẢI chặn việc phá vỡ cây 2 cấp khi lưu: ở chế độ Sửa, danh mục **có con** PHẢI không cho chọn danh mục cha mới và không cho đổi loại; danh mục **là con** PHẢI không cho đổi loại khác loại cha (loại của nó luôn bằng loại cha).
- **FR-009**: Khi người dùng chạm lưu (nút chính "Lưu danh mục" hoặc nút "Lưu" góc phải app bar) và dữ liệu hợp lệ: chế độ Thêm PHẢI tạo danh mục mới xếp vào **cuối** nhóm tương ứng (đúng loại, đúng cha); chế độ Sửa PHẢI cập nhật các trường được sửa và, khi danh mục chuyển nhóm cha/loại, xếp vào cuối nhóm đích. Sau lưu màn PHẢI quay lại màn danh sách danh mục với dữ liệu mới đã phản ánh, không cần làm mới thủ công.
- **FR-010**: Khi dữ liệu không hợp lệ (tên trống, trùng tên, thiếu biểu tượng/màu, phá vỡ ràng buộc cây/loại), hệ thống PHẢI chặn lưu và hiển thị thông báo lỗi cụ thể gần trường liên quan; người dùng quay lại (back) ở bất kỳ lúc nào trước khi lưu PHẢI rời màn mà không thay đổi dữ liệu danh mục.
- **FR-011**: Hệ thống PHẢI chạm lưu nhiều lần nhanh chỉ ghi nhận một lần (không tạo/ghi trùng) và PHẢI đánh giá lại các ràng buộc theo trạng thái dữ liệu hiện tại tại thời điểm lưu.
- **FR-012**: Màn hình PHẢI hiển thị đầy đủ, cuộn được và không vỡ bố cục trên các kích thước màn hình, vùng an toàn và cỡ chữ khác nhau (điện thoại); tên dài hoặc nhiều danh mục cha không làm tràn/cắt nội dung.

## Tiêu chí thành công

- **SC-001**: Từ màn danh sách danh mục, chạm FAB "+" hoặc chạm một danh mục không con thấy màn thêm/sửa hiển thị đầy đủ trong không quá 1 giây.
- **SC-002**: Với bộ dữ liệu mẫu khớp mockup, đối chiếu trực quan với `02-them-sua-danh-muc.svg`: vị trí app bar + tiêu đề theo chế độ, điều khiển loại, trường tên, bộ chọn biểu tượng/màu, ô danh mục cha, công tắc ẩn và nút lưu hiển thị đúng; chế độ Sửa điền sẵn 100% dữ liệu hiện tại của danh mục được chọn.
- **SC-003**: Người dùng thêm mới hoàn tất (từ mở màn đến lưu xong, quay lại danh sách) trong dưới 1 phút khi đã biết tên/icon/màu muốn dùng; danh mục mới xuất hiện đúng vị trí cuối nhóm trên màn danh sách mà không cần thao tác làm mới.
- **SC-004**: 100% các ca tạo trùng tên (kể cả trùng với danh mục ẩn cùng nhóm) bị chặn kèm thông báo; không ghi nhận trường hợp dữ liệu lưu xuống vi phạm ràng buộc tên/loại/cây (2 cấp).
- **SC-005**: Một danh mục **đã gắn giao dịch** không thể đổi loại qua màn sửa trong mọi thao tác thử; danh mục **có con** không thể đổi loại hay chuyển cha — đúng quy tắc nghiệp vụ, không sinh trạng thái danh mục "mồ côi" hay cấp 3.
- **SC-006**: Sau khi sửa tên/icon/màu/cha/ẩn và lưu, quay lại màn danh sách thấy danh mục đổi đúng và danh mục ẩn hiển thị trạng thái "Đã ẩn" (quy ước PBI 13); người dùng không cần bất kỳ thao tác làm mới thủ công nào.
- **SC-007**: Người dùng quay lại (back) trước khi lưu không làm thay đổi dữ liệu danh mục hiện có; chạm lưu nhanh nhiều lần chỉ tạo/ghi một lần.
- **SC-008**: Với cỡ chữ lớn nhất và vùng an toàn khác nhau, màn hiển thị đầy đủ, cuộn được, không vỡ bố cục hay che mất nút lưu.

## Thực thể chính

- **Danh mục (category)**: thực thể được tạo/sửa trên màn này. Gồm tên (≤ 30 ký tự), loại (thu / chi), biểu tượng, màu nhận diện, danh mục cha (rỗng = danh mục gốc cấp 1), trạng thái ẩn; có danh mục gốc và danh mục con (tối đa 2 cấp). Ràng buộc áp dụng lúc lưu: tên duy nhất trong cùng nhóm (loại + cha), con cùng loại cha, danh mục có con luôn là danh mục gốc. Danh mục **hệ thống** (tạo sẵn khi cài app) vẫn sửa được tên/icon/màu/ẩn như danh mục tự tạo; việc cấm xóa vĩnh viễn danh mục hệ thống không thuộc màn này (không có thao tác xóa).
- **Giao dịch (transaction)**: không hiển thị trên màn này nhưng quyết định ràng buộc loại — một danh mục **đã gắn ít nhất một giao dịch** (thu/chi lịch sử tham chiếu tới nó) thì loại bị khóa khi sửa; danh mục ẩn vẫn giữ nguyên trên giao dịch lịch sử (chỉ rút khỏi danh sách chọn nhanh khi nhập giao dịch).

## Giả định

- Điểm vào màn này là **màn danh sách danh mục (PBI 13)**: FAB "+" → chế độ Thêm; chạm danh mục **không có con** → chế độ Sửa. Danh mục **có con** khi chạm vẫn đi tới màn danh sách danh mục con (PBI riêng) như luồng đã chốt ở PBI 13 — đợt này chưa có điểm vào sửa danh mục có con; điểm đó nằm ở màn danh mục con (PBI sau) và sẽ tái dùng chính màn sửa này.
- Loại mặc định ở chế độ Thêm lấy từ tab đang mở của màn danh sách lúc chạm FAB (đúng chốt PBI 13 "FAB thêm đúng loại tab"); nếu không xác định được thì mặc định "Chi tiêu" như mockup.
- Người dùng chọn danh mục cha tùy ý để tạo danh mục con ngay từ màn thêm này (theo doc §4.2), dù điểm vào phổ biến hiện tại (FAB từ màn danh sách cấp 1) tạo danh mục gốc; màn danh sách con (PBI sau) sẽ dùng luồng "thêm nhanh con" và tái dùng màn này.
- Danh mục mới / danh mục đổi nhóm được xếp vào **cuối** nhóm tương ứng (loại + cha), nhất quán doc §4.2 "thêm vào cuối danh sách"; việc sắp xếp kéo-thả thuộc màn riêng (PBI sau).
- Ký tự chữ đơn (A, D, N…) vẽ trong vòng tròn ở mockup chỉ là chỗ trống minh họa; dữ liệu thật hiển thị bằng bộ biểu tượng và bảng màu sẵn có của app. Các văn bản khác trong mockup (tên "Ăn uống", công tắc) minh họa trạng thái, dữ liệu thật lấy từ danh mục đang thao tác.
- Màn không hiển thị số tiền nên không phụ thuộc quy ước tiền tệ / chế độ che tiền; chỉ hiển thị sau khi mở khóa theo cơ chế chung.
- App dùng chủ yếu theo chiều dọc trên điện thoại, giao diện tiếng Việt; tablet/đa ngôn ngữ chưa phải mục tiêu đợt này.

## Quyết định đã chốt

- **Đổi loại khi sửa chỉ được phép khi danh mục "sạch"** — người dùng đổi được loại (thu ↔ chi) ở chế độ Sửa chỉ khi danh mục chưa từng gắn giao dịch, không có danh mục con và đang là danh mục gốc; ngoài ra điều khiển loại hiện ở dạng khóa. (đã chốt với người dùng)
- **Sửa danh mục có con qua màn danh mục con (PBI sau), không thêm entry mới ở đợt này** — giữ đúng luồng PBI 13: chạm danh mục có con → mở màn danh sách con; màn thêm/sửa (02) đợt này mở cho danh mục không con (chạm dòng) và cho thao tác thêm mới (FAB). Màn sửa vẫn dựng đầy đủ để PBI danh sách con tái dùng. (đã chốt với người dùng)
- **Không đưa thao tác xóa vào đợt này** — màn thêm/sửa chỉ tạo, sửa và bật/tắt ẩn; toàn bộ xóa (kể cả xóa cứng danh mục chưa dùng) thuộc PBI riêng, nhất quán phạm vi PBI 13. (đã chốt với người dùng)

## Ngoài phạm vi

- Xóa / gộp danh mục: xóa cứng danh mục chưa dùng, ẩn hoặc gộp & xóa danh mục đã phát sinh giao dịch, xử lý danh mục con khi xóa danh mục cha, hạn chế xóa danh mục hệ thống.
- Điểm vào sửa danh mục **có con** (nằm ở màn danh sách danh mục con, PBI sau) và màn danh sách danh mục con (`03-danh-muc-con.svg`).
- Màn sắp xếp lại thứ tự danh mục kéo–thả (`04-sap-xep-danh-muc.svg`).
- Danh sách chọn nhanh danh mục khi nhập giao dịch (thuộc luồng thêm giao dịch, PBI 11), chỉ chịu ảnh hưởng gián tiếp khi danh mục bị ẩn/hiện.
- Thay đổi loại danh mục đã gắn giao dịch (bị khóa), phục hồi/khôi phục dữ liệu khi restore backup.
- Đa tiền tệ/quy đổi, dark mode, chế độ riêng tư che số tiền, tablet/đa ngôn ngữ.
