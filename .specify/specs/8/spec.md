# Đặc tả tính năng: Chuyển tiền giữa các ví

**Mã PBI**: 8
**Ngày tạo**: 2026-09-05
**Trạng thái**: Sẵn sàng lập kế hoạch

## Mô tả tổng quan

Người dùng cần di chuyển tiền giữa các ví của chính mình (ví dụ rút tiền mặt từ tài khoản ngân hàng nạp vào ví điện tử) mà không làm lệch tổng thu/chi. Tính năng này dựng **màn hình chuyển tiền giữa ví** theo thiết kế `docs/wallet/wallet-transfer-screen.svg`: chọn ví nguồn và ví đích, nhập số tiền, ngày giờ và ghi chú, xem trước số dư sau chuyển của cả hai ví rồi xác nhận. Màn mở từ hành động nhanh **"Chuyển tiền"** của màn chi tiết ví (PBI 6). Đợt này tập trung **thực hiện một lần chuyển tiền**: chỉ ghi nhận khoản chuyển làm thay đổi số dư hai ví, không phải thu/chi; việc sửa/xóa/hủy một khoản chuyển đã tạo thuộc module Giao dịch (PBI sau).

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã mở khóa app.

### Luồng chính

1. Người dùng đang ở màn chi tiết ví (PBI 6), chạm hành động nhanh **"Chuyển tiền"** → màn chuyển tiền mở ra (sub-page, app bar màu thương hiệu tiêu đề "Chuyển tiền giữa ví" có nút quay lại, không có thanh điều hướng đáy). Ô **"Từ ví"** được nạp sẵn đúng ví đang xem (tên, biểu tượng, số dư hiện tại), ô **"Đến ví"** chưa chọn.
2. Người dùng chạm ô **"Đến ví"** → danh sách chọn hiện ra liệt kê các ví đang hoạt động **cùng tiền tệ với ví nguồn** (mỗi dòng: tên, biểu tượng, số dư hiện tại), không bao gồm ví nguồn đang chọn và không bao gồm ví loại thẻ tín dụng. Chạm một ví → ví đó được chọn làm ví đích, ô "Đến ví" hiển thị tên + biểu tượng + số dư.
3. Nếu cần đổi chiều, người dùng chạm nút **hoán đổi** ở giữa hai ô ví → "Từ ví" và "Đến ví" đổi chỗ cho nhau (khi cả hai đã chọn).
4. Người dùng nhập **Số tiền chuyển** (bắt buộc, lớn hơn 0; gõ kèm phân tách nghìn tự động, đơn vị `đ`). Chạm **Ngày giờ** → chọn ngày và giờ của khoản chuyển (mặc định là thời điểm hiện tại, có thể đổi về quá khứ hoặc tương lai). **Ghi chú** là tùy chọn.
5. Ngay khi có đủ ví nguồn, ví đích và số tiền, dòng **"Số dư sau chuyển"** cập nhật trực tiếp: số dư ví nguồn trừ đi số tiền, số dư ví đích cộng thêm số tiền. Nếu số dư ví nguồn sau chuyển âm, hệ thống hiển thị cảnh báo mềm "Số dư sau chuyển sẽ âm" nhưng vẫn cho phép tiếp tục.
6. Người dùng chạm **"Xác nhận chuyển tiền"** → hệ thống ghi nhận khoản chuyển: trừ số dư ví nguồn, cộng số dư ví đích đúng số tiền, tạo một bút toán chuyển liên kết trên cả hai ví tại đúng ngày giờ đã chọn. Khoản chuyển xuất hiện trong nhóm "GIAO DỊCH GẦN ĐÂY" của cả hai ví, hiển thị màu trung tính (không phải thu/chi), **không** làm đổi tổng thu/tổng chi hay ảnh hưởng báo cáo thu/chi. Màn quay về màn chi tiết ví nguồn, số dư hiển thị đã cập nhật.

### Kịch bản chấp nhận

1. **Given** người dùng đang ở màn chi tiết ví "Vietcombank" (số dư 14.800.000 đ) **When** chạm hành động nhanh "Chuyển tiền" **Then** mở màn "Chuyển tiền giữa ví" đúng bố cục `wallet-transfer-screen.svg`: ô "Từ ví" nạp sẵn Vietcombank kèm số dư, ô "Đến ví" trống, đủ các trường số tiền / ngày giờ / ghi chú, dòng "Số dư sau chuyển" và nút "Xác nhận chuyển tiền".
2. **Given** người dùng mở màn chuyển tiền với nguồn là Vietcombank **When** chạm ô "Đến ví" **Then** danh sách hiện ra gồm các ví đang hoạt động khác cùng tiền tệ (mỗi dòng tên + số dư), không chứa Vietcombank và không chứa ví thẻ tín dụng; chạm ví "Momo" **Then** ô "Đến ví" hiển thị Momo kèm số dư 1.450.000 đ.
3. **Given** đã chọn nguồn Vietcombank và đích Momo **When** chạm nút hoán đổi **Then** nguồn thành Momo, đích thành Vietcombank, số dư hai ô đổi theo.
4. **Given** nguồn Vietcombank 14.800.000 đ, đích Momo 1.450.000 đ **When** nhập số tiền 2.000.000 đ **Then** dòng "Số dư sau chuyển" hiển thị "12.800.000 đ / 3.450.000 đ"; số tiền nhập được phân tách nghìn đúng dạng 2.000.000.
5. **Given** nguồn và đích đã chọn **When** chạm "Xác nhận chuyển tiền" mà số tiền trống hoặc bằng 0 **Then** lưu bị chặn, báo lỗi rõ tại trường số tiền, không tạo khoản chuyển.
6. **Given** nguồn ví tiền mặt số dư 500.000 đ **When** nhập số tiền chuyển 1.000.000 đ **Then** dòng "Số dư sau chuyển" hiển thị "−500.000 đ / ..." kèm cảnh báo mềm "Số dư sau chuyển sẽ âm" nhưng nút xác nhận vẫn hoạt động.
7. **Given** người dùng đã chọn đủ nguồn/đích/số tiền hợp lệ **When** chạm "Xác nhận chuyển tiền" **Then** màn quay về màn chi tiết ví nguồn, số dư ví nguồn giảm đúng 2.000.000 (còn 12.800.000 đ); mở màn chi tiết ví đích **Then** số dư tăng lên 3.450.000 đ; khoản chuyển xuất hiện trong "GIAO DỊCH GẦN ĐÂY" của cả hai ví với màu trung tính.
8. **Given** một khoản chuyển 2.000.000 đ vừa thực hiện giữa Vietcombank và Momo **When** xem tổng thu và tổng chi của thiết bị (mọi màn báo cáo/tổng hợp) **Then** không có con số nào thay đổi do khoản chuyển này.
9. **Given** người dùng đang chỉnh sửa màn chuyển tiền **When** chạm nút quay lại chưa xác nhận **Then** không tạo khoản chuyển nào, trở về màn chi tiết ví đúng trạng thái như lúc rời đi.
10. **Given** người dùng đang ở màn chi tiết của một ví thẻ tín dụng **When** chạm hành động nhanh "Chuyển tiền" **Then** không mở màn chuyển tiền; hệ thống thông báo rõ rằng thẻ tín dụng chưa dùng để chuyển tiền, không gây lỗi.
11. **Given** người dùng bật cỡ chữ lớn nhất hỗ trợ hoặc dùng màn hình có vùng an toàn **When** mở màn chuyển tiền **Then** mọi trường, dòng "Số dư sau chuyển" và nút "Xác nhận chuyển tiền" hiển thị đầy đủ, màn cuộn được, không vỡ hay tràn.

### Trường hợp biên

- Chỉ mới chọn được ví nguồn (ví đích trống) hoặc ngược lại → nút "Xác nhận chuyển tiền" không cho thực hiện, hướng dẫn người dùng chọn đủ hai ví.
- Danh sách chọn ví đích đã loại ví nguồn; nếu người dùng muốn đổi ngược chiều thì dùng nút hoán đổi thay vì chọn trùng.
- Thiết bị chỉ có một ví đang hoạt động → không thể chuyển tiền: hành động nhanh "Chuyển tiền" cần thông báo rõ là chưa có ví đích để chuyển (không treo, không lỗi).
- Thiết bị chỉ có một ví đang hoạt động ngoài ví loại thẻ tín dụng → tương tự, thông báo chưa có ví đích phù hợp.
- Ví loại thẻ tín dụng → không xuất hiện trong danh sách chọn nguồn/đích; mở "Chuyển tiền" từ màn chi tiết thẻ tín dụng thì báo rõ chưa hỗ trợ.
- Ví loại sổ tiết kiệm → được chọn làm nguồn/đích như ví thường (gửi vào / rút ra để theo dõi); dòng "Số dư sau chuyển" hiển thị như số dư thường.
- Ví đã ẩn → không xuất hiện trong danh sách chọn nguồn/đích; nguồn là ví ẩn đang xem từ chi tiết thì vẫn được phép chuyển ra? → chốt: người dùng đến từ màn chi tiết của ví đó, ô "Từ ví" đã nạp sẵn nên vẫn chuyển được; ví ẩn khác không chọn làm đích.
- Số dư hiển thị trong ô ví và dòng "Số dư sau chuyển" là số dư tại thời điểm xem; nếu dữ liệu đổi (có giao dịch khác) thì số hiển thị cập nhật lại cho đúng khi mở/trở về.
- Số tiền nhập rất lớn hoặc vượt quá số dư ví nguồn nhiều lần → vẫn hiển thị đúng (kể cả âm), không làm tràn/tràn số định dạng.
- Không còn ví đích hợp lệ (cùng tiền tệ, hoạt động, không phải thẻ tín dụng, khác ví nguồn) → người dùng không thể hoàn tất chuyển; giao diện hướng dẫn rõ, không để người dùng "kẹt" ở nút xác nhận vô hiệu không rõ lý do.
- Ngày giờ chọn sai/không hợp lệ (ví dụ để trống) → chặn xác nhận và báo lỗi tại trường ngày giờ.
- Chạm nút "Xác nhận chuyển tiền" hai lần liên tiếp nhanh → chỉ tạo đúng một khoản chuyển, không tạo trùng.
- Mất kết nối/vòng đời app bị ngắt giữa chừng sau khi xác nhận → khoản chuyển hoặc được lưu đầy đủ (cả hai ví), hoặc không lưu gì; không xảy ra trạng thái chỉ một ví bị đổi.
- Khóa app đang có hiệu lực → màn chuyển tiền chỉ hiển thị sau khi mở khóa, không lộ số dư qua màn hình khóa.

## Yêu cầu chức năng

- **FR-001**: Hệ thống PHẢI mở màn "Chuyển tiền giữa ví" khi người dùng chạm hành động nhanh "Chuyển tiền" ở màn chi tiết ví (PBI 6); màn là sub-page có nút quay lại, không có thanh điều hướng đáy; ô "Từ ví" nạp sẵn đúng ví đang xem kèm số dư hiện tại.
- **FR-002**: Màn PHẢI có đủ thành phần theo thiết kế `docs/wallet/wallet-transfer-screen.svg`: ô "Từ ví" và "Đến ví" (tên + biểu tượng + số dư hiện tại, có nút mở danh sách chọn), nút hoán đổi chiều giữa hai ví, trường Số tiền chuyển, bộ chọn Ngày giờ, trường Ghi chú, dòng "Số dư sau chuyển" và nút "Xác nhận chuyển tiền".
- **FR-003**: Danh sách chọn ví đích PHẢI liệt kê các ví đang hoạt động (không ẩn), cùng tiền tệ với ví nguồn, gồm tên và số dư hiện tại từng ví; PHẢI loại ví nguồn đang chọn và PHẢI loại toàn bộ ví loại thẻ tín dụng ra khỏi danh sách.
- **FR-004**: Nút hoán đổi PHẢI đổi chỗ ví nguồn và ví đích khi cả hai đã được chọn; số dư hiển thị ở hai ô đổi theo đúng ví mới.
- **FR-005**: Trường Số tiền chuyển PHẢI bắt buộc nhập, PHẢI là số lớn hơn 0, hiển thị phân tách nghìn bằng dấu chấm và đơn vị `đ` đúng định dạng tiền tệ của app.
- **FR-006**: Hệ thống PHẢI mặc định ngày giờ của khoản chuyển là thời điểm hiện tại và cho phép người dùng đổi sang ngày/giờ khác; ngày giờ là bắt buộc trước khi xác nhận.
- **FR-007**: Trường Ghi chú PHẢI là tùy chọn.
- **FR-008**: Dòng "Số dư sau chuyển" PHẢI tính và hiển thị trực tiếp khi có đủ ví nguồn, ví đích và số tiền: số dư nguồn sau chuyển = số dư nguồn hiện tại − số tiền, số dư đích sau chuyển = số dư đích hiện tại + số tiền; khi thiếu một trong ba yếu tố thì dòng này ở trạng thái trống/không xác định.
- **FR-009**: Khi số dư ví nguồn sau chuyển âm, hệ thống PHẢI hiển thị cảnh báo mềm rõ ràng (ví dụ "Số dư sau chuyển sẽ âm") nhưng KHÔNG chặn người dùng tiếp tục xác nhận.
- **FR-010**: Hệ thống PHẢI chặn xác nhận khi: thiếu ví nguồn hoặc ví đích, số tiền trống/không lớn hơn 0, hoặc ngày giờ thiếu/không hợp lệ; PHẢI báo lỗi rõ ràng tại đúng trường.
- **FR-011**: Hệ thống PHẢI không cho phép chọn ví nguồn và ví đích trùng nhau (loại trừ khỏi danh sách chọn; nếu phát sinh thì báo lỗi).
- **FR-012**: Khi người dùng xác nhận, hệ thống PHẢI ghi nhận khoản chuyển đúng số tiền và ngày giờ đã nhập: trừ số dư ví nguồn và cộng số dư ví đích, đồng thời tạo một bút toán chuyển liên kết trên cả hai ví — hai vế phải đi cùng nhau, không bao giờ chỉ một ví bị thay đổi.
- **FR-013**: Khoản chuyển KHÔNG được tính vào tổng thu, tổng chi, báo cáo thu/chi hay ngân sách; nó chỉ làm thay đổi số dư của đúng hai ví nguồn và đích.
- **FR-014**: Sau khi xác nhận thành công, hệ thống PHẢI quay về màn chi tiết ví nguồn với số dư đã cập nhật; khoản chuyển PHẢI xuất hiện trong nhóm "GIAO DỊCH GẦN ĐÂY" của cả ví nguồn và ví đích với màu ngữ cảnh trung tính của loại chuyển khoản (không nhầm với thu/chi).
- **FR-015**: Nếu việc xác nhận thất bại hoặc bị gián đoạn giữa chừng, hệ thống PHẢI không để lại trạng thái lưu nửa chừng (cả hai ví cùng đổi hoặc không đổi gì) và báo lỗi để người dùng thử lại mà không mất dữ liệu đã nhập.
- **FR-016**: Màn chuyển tiền PHẢI hiển thị đầy đủ, cuộn được và không vỡ bố cục trên các kích thước màn hình, vùng an toàn và thiết lập cỡ chữ khác nhau (điện thoại).
- **FR-017**: Màn chuyển tiền PHẢI chỉ hiển thị khi app đã được mở khóa; không được để người dùng nhìn thấy số dư qua màn hình khóa.
- **FR-018**: Hệ thống PHẢI không cho phép ví loại thẻ tín dụng xuất hiện trong danh sách chọn nguồn/đích của khoản chuyển. Khi người dùng chạm hành động nhanh "Chuyển tiền" ở màn chi tiết của một ví thẻ tín dụng, hệ thống PHẢI thông báo rõ ràng rằng thẻ tín dụng chưa dùng để chuyển tiền và không mở màn chuyển tiền.
- **FR-019**: Khoản chuyển PHẢI chỉ thực hiện được giữa hai ví **cùng tiền tệ**. Nếu không còn ví đích nào hợp lệ (cùng tiền tệ với ví nguồn, đang hoạt động, khác ví nguồn, không phải thẻ tín dụng), hệ thống PHẢI báo rõ và không cho hoàn tất chuyển.

## Tiêu chí thành công

- **SC-001**: Từ màn chi tiết ví, mở được màn chuyển tiền chỉ trong không quá 1 thao tác chạm; một lần chuyển tiền giữa hai ví hoàn tất trong chưa đầy 1 phút với người dùng đã quen.
- **SC-002**: Với bộ dữ liệu mẫu (nguồn 14.800.000 đ, đích 1.450.000 đ, chuyển 2.000.000 đ), số dư sau chuyển hiển thị khớp 100% với tính thủ công (12.800.000 đ và 3.450.000 đ); sau khi xác nhận, số dư hai ví trong màn chi tiết khớp đúng và khoản chuyển xuất hiện ở cả hai ví.
- **SC-003**: Một khoản chuyển giữa hai ví không làm thay đổi bất kỳ con số tổng thu/tổng chi nào trên toàn app — kiểm tra đối chiếu trước/sau khi chuyển bằng 0 (đánh giá định tính + đối chiếu số liệu).
- **SC-004**: Không thể tạo khoản chuyển thiếu ví nguồn/ví đích, số tiền không hợp lệ hay hai ví trùng nhau; mọi lỗi nhập đều báo rõ tại đúng trường, người dùng tự sửa được không cần trợ giúp.
- **SC-005**: Trường hợp nguồn không đủ số dư: người dùng vẫn chuyển được nhưng luôn nhìn thấy cảnh báo trước khi xác nhận (không xảy ra chuyển vượt số dư mà không được cảnh báo).
- **SC-006**: Không tồn tại thao tác nào trên màn này tạo ra trạng thái lệch một phía (chỉ một ví đổi số dư) hoặc tạo khoản chuyển trùng khi chạm nút liên tiếp.
- **SC-007**: Bật cỡ chữ lớn nhất hỗ trợ hoặc xem trên màn hình có vùng an toàn → mọi trường và nút "Xác nhận chuyển tiền" hiển thị đầy đủ, cuộn mượt, không vỡ.
- **SC-008**: Đối chiếu trực quan với thiết kế `wallet-transfer-screen.svg`: bố cục, nhãn trường, ô ví kèm số dư, dòng "Số dư sau chuyển" và nút xác nhận hiển thị đúng vị trí, đúng màu thương hiệu và đúng định dạng tiền tệ khi dữ liệu đầu vào tương ứng.

## Thực thể chính

- **Ví (wallet)**: hai ví tham gia khoản chuyển — ví nguồn (tiền đi ra) và ví đích (tiền vào). Mỗi ví có tên, loại ví, tiền tệ và số dư hiện tại (đại lượng suy ra từ giao dịch, không sửa tay). Khoản chuyển làm giảm số dư ví nguồn và tăng số dư ví đích đúng số tiền.
- **Giao dịch chuyển khoản (transfer)**: một sự kiện di chuyển tiền giữa hai ví của cùng một người dùng, gồm ví nguồn, ví đích, số tiền, ngày giờ và ghi chú tùy chọn. Không phải thu/chi: không gắn danh mục, không vào tổng thu/chi/báo cáo. Được biểu diễn bằng **hai bút toán liên kết** ghi trên hai ví — hai vế phải đi cùng nhau khi tạo và khi xử lý sau này.

## Giả định

- Màn chuyển tiền này là màn con thuộc nhóm màn quản lý ví (`wallet-transfer-screen.svg`), mở từ hành động nhanh "Chuyển tiền" của màn chi tiết ví (PBI 6). Nhánh "Chuyển khoản" trong màn thêm giao dịch của module Giao dịch là điểm vào khác của cùng nghiệp vụ, triển khai ở PBI Giao dịch sau và dùng chung ràng buộc nghiệp vụ.
- Ô "Từ ví" luôn được nạp sẵn ví đang xem trên màn chi tiết (người dùng không cần chọn lại). Ô "Đến ví" mặc định trống và người dùng chọn từ danh sách; chưa chọn thì hiển thị trạng thái "chọn ví".
- Danh sách chọn ví chỉ gồm các ví **đang hoạt động** (không ẩn); ví ẩn không được chọn làm nguồn/đích mới, trừ trường hợp người dùng đang đứng ở màn chi tiết của chính ví đó (ô "Từ ví" đã nạp sẵn).
- Khoản chuyển ghi theo ngày giờ người dùng nhập (mặc định hiện tại), không buộc là thời điểm thực hiện; nó ảnh hưởng số dư hai ví kể từ ngày giờ đó theo cùng quy tắc số dư suy ra.
- "Số dư hiện tại" hiển thị trong ô ví và dòng "Số dư sau chuyển" là số dư suy ra của ví tại thời điểm xem; số liệu lấy đúng từ dữ liệu thiết bị, con số trong mockup chỉ mang tính minh họa.
- App dùng chủ yếu theo chiều dọc trên điện thoại; tablet/đa cửa sổ chưa phải mục tiêu. Ngôn ngữ giao diện là tiếng Việt.
- Đợt này chưa có luồng xem/sửa/xóa một khoản chuyển đã tạo; khoản chuyển tạo ra chỉ xuất hiện dưới dạng dòng trong "GIAO DỊCH GẦN ĐÂY" của hai ví.
- Đợt này **không có phí chuyển khoản**: số tiền ra khỏi ví nguồn đúng bằng số tiền nhập, số tiền vào ví đích đúng bằng số tiền nhập. Phí chuyển (và danh mục "Phí giao dịch") là mở rộng ở PBI sau.
- Ví loại **thẻ tín dụng không thuộc phạm vi chuyển tiền** (nguồn/đích); loại **sổ tiết kiệm vẫn chuyển được** như ví thường (gửi vào / rút ra, bản chất chỉ là di chuyển tiền để theo dõi, không phải chi tiêu).
- Khoản chuyển chỉ xảy ra giữa hai ví **cùng tiền tệ**. Thực tế hiện tại mọi ví đều là VND nên đây là trường hợp duy nhất gặp; chuyển giữa hai ví khác tiền tệ (nhập tỷ giá, lưu tỷ giá) thuộc đợt đa tiền tệ sau — nếu xuất hiện ví khác tiền tệ trước đó, hệ thống chặn chuyển kèm thông báo.

## Ngoài phạm vi

- Sửa, xóa, hủy hoặc hoàn tác một khoản chuyển đã tạo (gồm xóa đồng bộ hai vế) — thuộc module Giao dịch (PBI sau), cùng luồng Undo.
- Nhánh "Chuyển khoản" trong màn thêm giao dịch và các luồng giao dịch khác của module Giao dịch.
- Điều chỉnh số dư ví, ghi nhận thu/chi, gắn danh mục cho khoản chuyển — khoản chuyển không có danh mục.
- Chuyển tiền giữa hai ví **khác tiền tệ** và nhập/lưu tỷ giá quy đổi (gồm nguồn tỷ giá offline) — đợt này chỉ hỗ trợ hai ví cùng tiền tệ; làm cùng đợt đa tiền tệ sau.
- **Phí chuyển khoản** và khoản Chi riêng danh mục "Phí giao dịch" (kèm bổ sung danh mục mặc định) — làm ở PBI sau.
- Chuyển tiền liên quan ví **thẻ tín dụng** (trả nợ / rút ứng) — thẻ tín dụng không nằm trong phạm vi chuyển tiền của đợt này.
- Kéo-thả sắp xếp ví, chế độ riêng tư ẩn số dư, đa ngôn ngữ.

## Quyết định đã chốt

- **Không có phí chuyển khoản trong đợt này** — bám đúng mockup (màn chỉ có số tiền + ghi chú). Phí chuyển và khoản Chi danh mục "Phí giao dịch" là mở rộng PBI sau, gộp với việc đóng quyết định mở #3 về seed danh mục.
- **Loại trừ thẻ tín dụng khỏi phạm vi chuyển tiền** — danh sách chọn nguồn/đích chỉ gồm ví "số dư dương" (tiền mặt, ngân hàng, ví điện tử, sổ tiết kiệm). Mở "Chuyển tiền" từ màn chi tiết thẻ tín dụng → báo rõ chưa hỗ trợ. Sổ tiết kiệm được chuyển như ví thường (gửi/rút để theo dõi).
- **Chỉ hỗ trợ chuyển giữa hai ví cùng tiền tệ** — hiện mọi ví là VND nên không gặp trường hợp khác tiền tệ; nhập/lưu tỷ giá quy đổi làm ở đợt đa tiền tệ sau (gộp quyết định mở #5 về nguồn tỷ giá).
