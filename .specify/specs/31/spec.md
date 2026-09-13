# Đặc tả tính năng: Thông báo đẩy — engine bắn thông báo & nhắc nhở

**Mã PBI**: 31
**Ngày tạo**: 2026-09-13
**Trạng thái**: Đã làm rõ

## Mô tả tổng quan

App đã có **màn cấu hình** nhắc nhở (PBI 28: 5 nhóm/6 công tắc; PBI 29: giờ + ngày trong tuần của nhắc hàng ngày) và **Trung tâm thông báo** (PBI 30: lịch sử + trạng thái đã đọc) — nhưng **chưa có gì bắn thông báo**: mọi công tắc hiện là cấu hình đặt trước, Trung tâm luôn rỗng trên máy thật.

PBI này dựng tầng còn thiếu — **engine thông báo**: tự tính điều kiện, tự lên lịch theo giờ, tự bắn **thông báo hệ điều hành** (mẫu ở mockup `docs/notification/04-mau-thong-bao-day.svg`, hiển thị trên màn hình khoá) và **ghi lịch sử vào Trung tâm** để người dùng xem lại kể cả khi bỏ lỡ.

Nguyên tắc nền: app **offline hoàn toàn — "thông báo đẩy" ở đây là thông báo do chính thiết bị sinh ra**, không có server/FCM (doc nghiệp vụ §1). Engine **chỉ đọc dữ liệu nghiệp vụ**, không bao giờ sửa; và **việc ghi chép thu chi không bao giờ bị chặn hay làm chậm** vì thông báo.

## Kịch bản & luồng người dùng

Tác nhân: người dùng cuối (chủ thiết bị) đã cấu hình nhắc nhở ở màn `01`/`02`.

### Luồng chính — Nhắc nhập giao dịch hằng ngày

1. Người dùng đã bật "Nhắc nhập giao dịch hằng ngày" với giờ **20:30**, các ngày T2→T7 + CN, cờ "chỉ nhắc nếu chưa ghi" **bật**. Trong ngày hôm đó người dùng **chưa ghi giao dịch nào**.
2. Đến **20:30**, khi app **không mở**, thiết bị hiện **thông báo hệ thống** đúng mẫu 2 của mockup `04`: tên app **"Sora Thu Chi"**, **icon chuông** (sắc teal), tiêu đề **"Nhắc ghi chép giao dịch"**, dòng mô tả **"Bạn chưa ghi giao dịch nào hôm nay."**, nhãn thời gian ở góc phải.
3. **Đồng thời**, một bản ghi tương ứng được thêm vào **Trung tâm thông báo** (PBI 30) ở trạng thái **chưa đọc** → biểu tượng chuông ở màn Tổng quan có **chấm đỏ**.
4. Người dùng **tap** thông báo trên màn hình khoá → app mở ra; nếu app đang khoá bằng **mã PIN** (PBI 3) thì màn mở khoá hiện trước, sau khi mở khoá app đi thẳng tới **màn Thêm giao dịch**; bản ghi lịch sử tương ứng chuyển **đã đọc**.
5. Sang ngày hôm sau, người dùng **đã ghi 2 giao dịch** trước 20:30 → đến 20:30 **không có thông báo nào** và **không có bản ghi** nào được thêm.

### Luồng chính — Cảnh báo ngân sách

1. Ngân sách tháng của danh mục **Ăn uống** đang ở **78%**; người dùng lưu một giao dịch **chi** khiến tổng chi của danh mục đạt **82%** (vượt ngưỡng sớm **80%**).
2. **Ngay sau khi giao dịch được lưu**, thiết bị hiện thông báo theo mẫu 1 của mockup `04`: **icon cảnh báo + sắc coral**, tiêu đề **"Sắp vượt ngân sách Ăn uống"**, dòng mô tả **"Bạn đã dùng 82% ngân sách tháng 9 cho danh mục Ăn uống."**; đồng thời ghi một bản ghi chưa đọc vào Trung tâm.
3. Người dùng **tap** thông báo → app mở màn **Chi tiết ngân sách** của đúng danh mục Ăn uống (PBI 21); bản ghi lịch sử chuyển đã đọc.
4. Người dùng tiếp tục thêm **3 giao dịch chi** cho Ăn uống trong cùng kỳ, đẩy tổng lên **89%** rồi **104%** → ở mốc **104%** có thêm **đúng một** thông báo ở ngưỡng **vượt mức**, còn các lần vượt lại của ngưỡng 80% **không** bắn lại.

### Luồng chính — Tổng kết tuần / tháng

1. Đến **Chủ nhật 20:00** (giờ đã cấu hình), khi app không mở, thiết bị hiện thông báo theo mẫu 4 của mockup `04`: **icon biểu đồ tròn** (teal), tiêu đề **"Tổng kết tuần"**, dòng mô tả kèm số liệu so sánh với tuần liền trước (VD **"Bạn đã chi nhiều hơn tuần trước 15%."**) và một dòng mời xem báo cáo.
2. Người dùng tap → app mở màn **Báo cáo** đã lọc sẵn theo **kỳ vừa kết thúc**; bản ghi lịch sử chuyển đã đọc.
3. Tổng kết tháng hoạt động tương tự vào **ngày cuối tháng**, giờ đã cấu hình, với kỳ là **tháng vừa kết thúc**.

### Luồng phụ — Không có quyền thông báo hệ thống

1. Người dùng **từ chối** (hoặc sau đó tắt) quyền thông báo của hệ điều hành.
2. Đến giờ nhắc, **không** có thông báo nào hiện trên màn hình khoá; app **không** hiện lỗi, **không** chặn gì, và người dùng vẫn ghi giao dịch bình thường.
3. Người dùng mở app → màn Tổng quan → chạm chuông → **Trung tâm thông báo vẫn có đầy đủ** các bản ghi đã phát sinh (đúng mục đích "xem lại khi bỏ lỡ" của doc §3.2).

### Luồng phụ — Tắt/bật lại một loại nhắc

1. Người dùng vào màn `01` và **tắt** "Cảnh báo vượt ngân sách" → từ đó về sau, vượt ngưỡng **không** bắn gì và **không** ghi lịch sử.
2. Người dùng **bật lại** → các ngưỡng **chưa từng được báo trong kỳ hiện tại** được tính lại và báo bình thường; ngưỡng **đã báo trước khi tắt** trong cùng kỳ **không** báo lại.

### Luồng phụ — Lần đầu mở màn cấu hình: xin quyền thông báo

1. Người dùng **lần đầu tiên** vào **Cài đặt → Thông báo & nhắc nhở**.
2. Trước khi hệ điều hành hỏi, app hiện **lời giải thích ngắn** vì sao app cần gửi thông báo, kèm hai lựa chọn **đồng ý** / **không đồng ý**.
3. Người dùng chọn **đồng ý** → hệ điều hành hiện hộp thoại xin quyền → người dùng **cho phép** → màn `01` hiển thị **đúng như mockup** (không có dòng trạng thái nào về quyền).
4. Lần sau người dùng mở lại màn `01` → **không** có lời giải thích nào hiện lại (chỉ hỏi một lần).

### Luồng phụ — Quyền thông báo bị từ chối

1. Ở luồng trên, người dùng chọn **không đồng ý** (hoặc cho phép rồi sau đó tắt trong cài đặt hệ thống).
2. Màn `01` hiển thị **một dòng trạng thái** nêu rõ thông báo đang bị tắt, kèm lối **mở cài đặt thông báo của hệ điều hành**; các công tắc và tham số **giữ nguyên** giá trị đang lưu.
3. Người dùng bật lại quyền trong cài đặt hệ thống rồi quay lại app → dòng trạng thái **biến mất**, màn trở lại **đúng mockup `01`**; các mốc nhắc **đã trôi qua** trong lúc bị chặn **không** được bắn bù.

### Luồng phụ — Bỏ lỡ rồi xem lại

1. Người dùng bỏ qua/không để ý thông báo nhắc hàng ngày (hoặc đã vuốt xoá khỏi màn hình khoá) → mở app sau đó, biểu tượng chuông vẫn có **chấm đỏ**; vào Trung tâm thấy bản ghi với nội dung **nguyên văn như lúc bắn**.

### Kịch bản chấp nhận

1. **Given** cấu hình nhắc hàng ngày 20:30, cờ "chỉ nhắc nếu chưa ghi" bật, hôm nay chưa có giao dịch nào **When** đến 20:30 **Then** đúng **một** thông báo hệ thống hiện ra đúng mẫu 2 mockup `04` (tên app + tiêu đề + dòng mô tả + nhãn thời gian, icon chuông teal) **và** đúng **một** bản ghi chưa đọc xuất hiện trong Trung tâm.
2. **Given** cờ "chỉ nhắc nếu chưa ghi" đang bật **When** hôm nay người dùng đã ghi ít nhất 1 giao dịch **Then** đến giờ nhắc **không** có thông báo và **không** có bản ghi mới nào (đếm trước/sau bằng nhau).
3. **Given** cờ "chỉ nhắc nếu chưa ghi" đang **tắt** **When** đến giờ nhắc (dù hôm nay đã ghi giao dịch) **Then** thông báo vẫn hiện, nhưng dòng mô tả **KHÔNG** được nói "bạn chưa ghi giao dịch nào hôm nay" — câu chữ phải đúng với thực tế.
4. **Given** cấu hình chỉ chọn các ngày T2, T4, T6 **When** đến giờ nhắc vào **Thứ Ba** **Then** thông báo hiện; **When** đến giờ nhắc vào **Thứ Tư** (ngày không chọn) **Then** **không** có thông báo và **không** có bản ghi.
5. **Given** ngân sách của một danh mục đang dưới ngưỡng sớm **When** người dùng lưu một giao dịch **chi** làm tổng chi của danh mục trong kỳ **vượt ngưỡng sớm** (mặc định 80%) **Then** thông báo đúng mẫu 1 mockup `04` (icon cảnh báo **coral**, tiêu đề nêu tên danh mục, dòng mô tả nêu **phần trăm cụ thể** và **kỳ**) hiện ra ngay sau khi lưu, kèm một bản ghi chưa đọc.
6. **Given** ngưỡng sớm của một danh mục **đã được báo** trong kỳ hiện tại **When** người dùng thêm **nhiều giao dịch chi** tiếp (82% → 89% → 95%) **Then** **không** có thêm thông báo nào cho ngưỡng sớm của danh mục đó (0 lần bắn lặp).
7. **Given** một danh mục **đã được báo** ngưỡng sớm trong kỳ **When** tổng chi vượt **ngưỡng vượt mức** (mặc định 100%) **Then** có **đúng một** thông báo cho ngưỡng vượt mức, nội dung thể hiện đã **vượt** ngân sách.
8. **Given** ngân sách đang áp dụng cho một kỳ **When** người dùng lưu giao dịch **thu** hoặc giao dịch **chi ngoài kỳ** của ngân sách đó **Then** **không** có thông báo và **không** có bản ghi.
9. **Given** nhiều danh mục cùng vượt ngưỡng **When** người dùng lưu giao dịch khiến cả hai vượt ngưỡng **Then** **mỗi** danh mục có **một** thông báo và **một** bản ghi riêng (0 thông báo nào bị mất).
10. **Given** người dùng đang ở **đúng màn hình liên quan** (VD đang mở Chi tiết ngân sách của danh mục đó; hoặc đang mở màn Báo cáo khi đến giờ tổng kết) **When** điều kiện bắn được thoả **Then** **không** có thông báo hệ thống nào hiện ra **và** **không** có bản ghi trùng nào được thêm — tránh trùng lặp vì người dùng đang nhìn đúng thông tin đó. [Q3 chọn A]
11. **Given** app đang mở ở **màn khác** với màn liên quan (VD đang ở danh sách Giao dịch) **When** điều kiện bắn được thoả **Then** thông báo **vẫn** hiện theo quy tắc Q3.
12. **Given** người dùng **tap** một thông báo trên màn hình khoá **When** app đang đóng (hoặc đang ở nền) **Then** app mở ra và đi tới **đúng** màn đích theo loại: nhắc hàng ngày → **màn Thêm giao dịch**; cảnh báo ngân sách → **Chi tiết ngân sách của đúng danh mục**; tổng kết → **màn Báo cáo đã lọc sẵn kỳ vừa tổng kết**; **và** bản ghi lịch sử tương ứng chuyển **đã đọc**.
13. **Given** app đang **khoá bằng mã PIN** **When** người dùng tap thông báo **Then** màn mở khoá hiện **trước**, và **chỉ sau khi** mở khoá thành công app mới đi tới màn đích; nếu mở khoá thất bại/huỷ thì **không** vào được màn đích.
14. **Given** quyền thông báo của hệ điều hành **bị chặn** **When** đến giờ nhắc **Then** **không** có thông báo nào hiện ra, app **không** báo lỗi, **không** chặn thao tác nào, **và** bản ghi lịch sử **vẫn** được thêm đầy đủ để xem lại trong Trung tâm.
15. **Given** người dùng **tắt** một công tắc ở màn `01` **When** dùng app tiếp trong ngày (không cần mở lại app) **Then** loại đó **không** bắn và **không** ghi lịch sử nữa; **When** bật lại **Then** loại đó hoạt động trở lại bình thường.
16. **Given** người dùng **đổi giờ** nhắc hàng ngày từ 20:30 sang **07:05** ở màn `02` **When** lưu **Then** lịch nhắc tính theo **giờ mới** (0 lần bắn ở giờ cũ sau đó), **không** cần mở lại app hay khởi động lại thiết bị.
17. **Given** người dùng **khởi động lại thiết bị** (app chưa từng mở lại) **When** đến giờ nhắc đã cấu hình **Then** thông báo **vẫn** hiện đúng giờ đó (0 lần mất nhắc do khởi động lại).
18. **Given** đến giờ tổng kết tuần **When** kỳ vừa kết thúc **có** giao dịch **Then** nội dung tổng kết nêu **số liệu cụ thể** của kỳ và **so sánh với kỳ liền trước** (nhiều hơn / ít hơn / tương đương, kèm phần trăm) — **và** kỳ phải là **tuần Thứ Hai → Chủ Nhật** vừa kết thúc.
19. **Given** đến giờ tổng kết **When** kỳ vừa kết thúc **không có giao dịch nào** **Then** vẫn có **một** thông báo tổng kết với nội dung **phản ánh đúng** việc kỳ đó chưa ghi giao dịch (không có câu so sánh phần trăm sai lệch).
20. **Given** đến giờ tổng kết **When** **tuần trước đó** không có giao dịch nào **Then** nội dung thông báo **không** hiển thị câu so sánh phần trăm vô nghĩa (không chia cho 0, không hiện "nhiều hơn ∞").
21. **Given** người dùng lưu một giao dịch bình thường **When** engine tính toán/cảnh báo gặp sự cố (dữ liệu thiếu, lỗi bất kỳ) **Then** giao dịch **vẫn được lưu thành công**, người dùng **không** thấy thông báo lỗi nào, và app **không** bị treo/chậm.
22. **Given** người dùng sử dụng app trong ngày **When** đối chiếu trước/sau (giao dịch, ví, danh mục, ngân sách) **Then** **0** thay đổi do engine gây ra — engine chỉ đọc dữ liệu nghiệp vụ và chỉ ghi **lịch sử thông báo** + **trạng thái đã bắn** của chính nó.
23. **Given** app đang ở **English** **When** một thông báo được bắn **Then** nội dung thông báo và bản ghi lịch sử bằng **tiếng Anh**; **When** sau đó người dùng đổi sang tiếng Việt **Then** bản ghi **đã lưu giữ nguyên văn** tiếng Anh (không dịch lại), còn thông báo **bắn sau đó** dùng tiếng Việt.
24. **Given** người dùng đã cài app từ trước (cấu hình cũ, chưa từng có engine) **When** mở app sau khi cập nhật **Then** engine chạy với **đúng cấu hình đang lưu** (không reset mặc định), app **không** báo lỗi, và **không** bắn bù một loạt thông báo của các kỳ/ngày đã qua.
25. **Given** Trung tâm thông báo đã có **200** bản ghi **When** engine ghi thêm bản ghi mới **Then** số bản ghi xem được **≤ 200** và **200** bản ghi còn lại là **mới nhất** (trần lưu của PBI 30 vẫn đúng).
26. **Given** người dùng mở màn `01` **When** xem 2 hàng chevron "Ngưỡng cảnh báo" và "Nhắc trước" **Then** hành xử **như cũ** (chỉ hiển thị giá trị đang lưu, chạm không mở gì) — engine **đọc** ngưỡng/số ngày từ cấu hình này nhưng **không** thêm luồng chỉnh sửa.
27. **Given** người dùng **chưa từng** mở màn "Thông báo & nhắc nhở" **When** mở màn lần đầu **Then** lời giải thích lý do của app hiện ra **trước**, và hộp thoại xin quyền của hệ điều hành chỉ hiện **sau khi** người dùng đồng ý ở bước giải thích; **When** mở màn lần thứ hai trở đi **Then** **không** có lời giải thích nào hiện lại.
28. **Given** quyền thông báo **không được cấp** **When** mở màn `01` **Then** có **đúng một** dòng trạng thái nêu thông báo đang bị tắt kèm lối mở cài đặt hệ điều hành, và **mọi** công tắc/giá trị cấu hình giữ nguyên như đang lưu; **When** quyền được cấp lại **Then** dòng trạng thái **biến mất** và màn hiển thị đúng mockup `01` (0 dòng thừa).
29. **Given** quyền thông báo bị chặn trong một khoảng thời gian **When** người dùng cấp lại quyền **Then** **không** có loạt thông báo bắn bù cho các mốc đã trôi qua; chỉ các mốc **ở tương lai** mới được nhắc.

### Trường hợp biên

- **Múi giờ thiết bị đổi** (đi công tác, đổi giờ hệ thống) → giờ:phút đã cấu hình là **giờ địa phương**; đổi múi giờ làm giờ bắn đổi theo giờ địa phương mới. Không bắn bù các mốc đã trôi qua.
- **Thiết bị tắt nguồn đúng lúc đến giờ nhắc** → bỏ lỡ mốc đó; khi bật lại **không** bắn bù. Riêng các mốc **còn ở tương lai** vẫn phải hoạt động bình thường.
- **Người dùng mở app đúng lúc đến giờ** → áp dụng quy tắc Q3 (chặn khi đang ở đúng màn liên quan); các màn khác không chặn.
- **Nhiều thông báo trong cùng một ngày** (nhắc hàng ngày + cảnh báo ngân sách + tổng kết) → mỗi loại là một thông báo riêng và một bản ghi riêng; **không** gộp, **không** mất cái nào.
- **Ngân sách bị lưu trữ hoặc bị xoá ngay sau khi vượt ngưỡng** → bản ghi lịch sử **không** bị mất (PBI 30 chốt: lịch sử thuộc người dùng); chạm vào bản ghi đó không được gây lỗi.
- **Giao dịch bị sửa hoặc xoá** sau khi đã bắn cảnh báo → **không** hồi tố, **không** thu hồi thông báo đã bắn, **không** tính lại lịch sử; tổng chi mới chỉ ảnh hưởng các lần tính **sau đó**.
- **Cùng một ngưỡng của cùng một danh mục ở kỳ mới** → được báo lại bình thường (trạng thái chống trùng gắn với **kỳ**, không phải danh mục vĩnh viễn).
- **Người dùng tắt hết công tắc** → **0** thông báo, **0** bản ghi mới; mọi chức năng khác của app không bị ảnh hưởng.
- **Bộ nhớ lịch sử đã đầy trần 200** → engine ghi bình thường, bản ghi cũ nhất bị dọn (PBI 30), không hỏi, không báo.
- **Quyền thông báo bị chặn rồi được cấp lại** → từ đó thông báo hiện lại; **không** bắn bù các mốc đã bỏ lỡ.
- **Người dùng từ chối ở bước giải thích rồi tắt/bật công tắc vài lần** → **không** có lời giải thích nào hiện lại, **không** có hộp thoại hệ thống nào bật lên đột ngột; màn chỉ có dòng trạng thái (FR-032) và cấu hình vẫn lưu bình thường.
- **Quyền bị tắt ở cài đặt hệ thống trong lúc app đang mở** → lần quay lại màn `01` kế tiếp đã thấy dòng trạng thái; engine vẫn tính và ghi lịch sử (FR-004), chỉ không hiện thông báo.
- **Thông báo của app bị người dùng tắt riêng một loại trong cài đặt hệ điều hành** → loại đó im lặng, các loại khác vẫn bắn, lịch sử vẫn đầy đủ.
- **Dữ liệu cấu hình hỏng/thiếu trường** → engine dùng mặc định **của riêng trường đó** (đồng bộ cách chịu lỗi của PBI 28/29), **không** dừng toàn bộ engine.
- **Điện thoại bị tối ưu pin giết tiến trình** → đây là giới hạn của hệ điều hành; xem "Ngoài phạm vi" (chưa có UI hướng dẫn autostart trong đợt này).
- **Không có mạng** → không ảnh hưởng gì: toàn bộ engine chạy trên thiết bị.

## Yêu cầu chức năng

- **FR-001**: App PHẢI **tự sinh thông báo hệ điều hành** theo cấu hình đã lưu ở màn `01`/`02`, **không** cần server, **không** cần tài khoản, **không** cần mạng. "Thông báo đẩy" trong đặc tả này **KHÔNG** bao gồm bất kỳ thông báo nào đến từ bên ngoài thiết bị.
- **FR-002**: Trong đợt này engine PHẢI bắn **3 loại**: **nhắc nhập giao dịch hằng ngày**, **cảnh báo ngân sách**, **tổng kết cuối tuần / cuối tháng**. Hai loại **nhắc giao dịch định kỳ** và **nhắc mục tiêu tiết kiệm** **KHÔNG** bắn trong đợt này vì hai module dữ liệu tương ứng chưa tồn tại — công tắc của chúng ở màn `01` giữ nguyên hành vi hiện có (lưu được, không báo lỗi, không ghi "sắp có"). [Q1 chọn A]
- **FR-003**: Mỗi lần một loại nhắc **được kích hoạt**, hệ thống PHẢI đồng thời: (a) hiển thị **đúng một** thông báo hệ điều hành, và (b) thêm **đúng một** bản ghi **chưa đọc** vào **Trung tâm thông báo** (PBI 30). **KHÔNG** tồn tại trường hợp có thông báo mà không có bản ghi, hoặc ngược lại — **trừ** trường hợp bị chặn bởi quy tắc FR-013 (khi đó **không** có cả hai).
- **FR-004**: Khi quyền thông báo của hệ điều hành **bị chặn**, hệ thống PHẢI **vẫn** tính điều kiện và **vẫn** ghi bản ghi lịch sử, chỉ **bỏ** phần hiển thị thông báo; app **KHÔNG** hiện lỗi, **KHÔNG** cảnh báo, **KHÔNG** chặn thao tác nào.
- **FR-005**: Nội dung mỗi thông báo PHẢI theo đúng mẫu mockup `04`: có **tên app "Sora Thu Chi"**, **tiêu đề** ngắn, **dòng mô tả chứa số liệu cụ thể** (số tiền / phần trăm / tên danh mục / kỳ), và **nhãn thời gian**. Nội dung **KHÔNG** được chung chung kiểu "bạn có thông báo mới".
- **FR-006**: **Icon và màu theo loại** PHẢI đúng mockup `04`: cảnh báo/vượt ngân sách → **icon cảnh báo + sắc coral** (ngữ cảnh cảnh báo chi tiêu); nhắc nhập giao dịch → **icon chuông** (teal); tổng kết kỳ → **icon biểu đồ tròn** (teal).
- **FR-007**: Nội dung **cảnh báo ngân sách** PHẢI nêu **tên danh mục**, **phần trăm đã dùng** và **kỳ ngân sách**; khi ở ngưỡng **sớm** thì diễn đạt là **sắp vượt**, khi ở ngưỡng **vượt mức** thì diễn đạt là **đã vượt** — hai mức PHẢI phân biệt được bằng chữ, không chỉ bằng con số.
- **FR-008**: Nội dung **nhắc nhập giao dịch hằng ngày** PHẢI **phản ánh đúng thực tế cờ "chỉ nhắc nếu chưa ghi"**: khi cờ bật, câu chữ nói rõ hôm nay **chưa ghi giao dịch**; khi cờ **tắt**, câu chữ **KHÔNG** được khẳng định điều đó (chỉ là lời nhắc chung).
- **FR-009**: Nội dung **tổng kết** PHẢI nêu **số liệu của kỳ vừa kết thúc** và **so sánh với kỳ liền trước** (nhiều hơn / ít hơn / tương đương, kèm phần trăm khi tính được) và một dòng mời **xem báo cáo**. Khi **không** tính được so sánh (kỳ trước rỗng) → **bỏ** câu so sánh, **KHÔNG** hiển thị giá trị vô nghĩa. Khi **kỳ vừa kết thúc rỗng** → vẫn bắn một thông báo tổng kết với câu chữ phản ánh đúng việc kỳ đó chưa ghi giao dịch.
- **FR-010**: **Nhắc nhập giao dịch hằng ngày** PHẢI bắn đúng **giờ:phút** đã cấu hình (PBI 29) và **chỉ vào các ngày trong tuần đã chọn**; ngày không được chọn → **không** bắn, **không** ghi lịch sử. Tần suất tối đa: **1 lần/ngày**.
- **FR-011**: Khi cờ "chỉ nhắc nếu chưa ghi giao dịch trong ngày" **bật**, hệ thống PHẢI kiểm tra dữ liệu giao dịch **của chính ngày hôm đó** trước khi bắn; đã có **ít nhất một** giao dịch → **không** bắn và **không** ghi lịch sử. Giao dịch thuộc bất kỳ loại nào (thu, chi, chuyển khoản) đều tính là "đã ghi".
- **FR-012**: **Cảnh báo ngân sách** PHẢI được tính **ngay sau khi một giao dịch chi được lưu**, bằng cách so **tổng chi luỹ kế của kỳ ngân sách** với các ngưỡng trong cấu hình (**sớm 80%**, **vượt mức 100%** — đọc từ cấu hình đang lưu, không hard-code). Ngưỡng PHẢI được đọc từ cấu hình của màn `01`.
- **FR-013**: Hệ thống PHẢI **chống bắn trùng** cho cảnh báo ngân sách theo quy tắc: **tối đa 1 lần cho mỗi ngưỡng, cho mỗi ngân sách, trong mỗi kỳ ngân sách**. Thêm nhiều giao dịch liên tiếp vượt cùng một ngưỡng → **0** thông báo lặp. Trạng thái đã bắn PHẢI **lưu bền** — đóng/mở lại app hay khởi động lại thiết bị **KHÔNG** làm bắn lại.
- **FR-014**: Cảnh báo ngân sách PHẢI **chỉ** tính từ giao dịch **chi** thuộc **đúng danh mục** của ngân sách và **trong kỳ** của ngân sách đó; giao dịch **thu**, giao dịch **ngoài kỳ**, và giao dịch của danh mục **khác** **KHÔNG** được tính vào.
- **FR-015**: **Tổng kết cuối tuần** PHẢI bắn **1 lần/tuần** vào thời điểm đã cấu hình; **tổng kết cuối tháng** PHẢI bắn **1 lần/tháng** vào ngày **cuối tháng** theo thời điểm đã cấu hình. **Kỳ** của tổng kết tuần là **Thứ Hai → Chủ Nhật vừa kết thúc** (đồng bộ quy ước tuần của module Báo cáo); kỳ của tổng kết tháng là **tháng dương lịch vừa kết thúc**.
- **FR-016**: Khi app đang mở **và đang ở đúng màn hình liên quan của loại thông báo đó** (VD đang mở Chi tiết ngân sách của chính danh mục sắp cảnh báo; đang mở màn Báo cáo khi đến giờ tổng kết), hệ thống PHẢI **không bắn** và **không ghi** bản ghi — tránh trùng lặp vì người dùng đang nhìn đúng thông tin đó. App đang mở ở **màn khác** → vẫn bắn bình thường. [Q3 chọn A]
- **FR-017**: App PHẢI hỏi quyền thông báo của hệ điều hành **đúng một lần**, tại **lần đầu tiên người dùng mở màn "Thông báo & nhắc nhở"** (`01`): trước khi hệ điều hành hiện hộp thoại xin quyền, app PHẢI hiện **lời giải thích ngắn vì sao cần quyền** kèm hai lựa chọn đồng ý / không đồng ý; chỉ khi người dùng đồng ý ở bước giải thích thì hộp thoại xin quyền của hệ điều hành mới được gọi. Nếu người dùng **không đồng ý**, app **KHÔNG** hỏi lại ở những lần mở màn sau và màn vẫn dùng bình thường. [Q2 chọn C]
- **FR-018**: **Tap một thông báo** PHẢI mở app và đi tới **đúng màn đích**: nhắc nhập giao dịch → **màn Thêm giao dịch**; cảnh báo ngân sách → **màn Chi tiết ngân sách của đúng danh mục**; tổng kết → **màn Báo cáo đã lọc sẵn kỳ vừa tổng kết**. Đồng thời bản ghi lịch sử tương ứng PHẢI chuyển sang **đã đọc**.
- **FR-019**: Nếu app đang **khoá bằng mã PIN** (PBI 3), tap thông báo PHẢI đưa qua **màn mở khoá trước**; chỉ sau khi mở khoá thành công mới đi tới màn đích. Mở khoá thất bại/huỷ → **KHÔNG** vào được màn đích và **KHÔNG** lộ dữ liệu.
- **FR-020**: Nếu màn đích **không còn tồn tại** (VD danh mục của cảnh báo đã bị xoá, ngân sách đã bị lưu trữ), tap thông báo PHẢI **không gây lỗi, không màn trắng**: hệ thống vẫn đánh dấu bản ghi **đã đọc** và xử lý an toàn (mở app ở màn mặc định hoặc không điều hướng), **KHÔNG** hiện khung "sắp có".
- **FR-021**: Thay đổi cấu hình ở màn `01`/`02` (bật/tắt công tắc, đổi giờ, đổi ngày trong tuần, đổi ngưỡng) PHẢI **có hiệu lực ngay**, **không** cần đóng/mở lại app hay khởi động lại thiết bị. **Tắt** một công tắc → loại đó **không** bắn, **không** ghi lịch sử; **bật lại** → hoạt động trở lại và các ngưỡng **chưa từng báo trong kỳ hiện tại** vẫn được báo.
- **FR-022**: Lịch nhắc của các loại **theo giờ cố định** PHẢI **tồn tại độc lập với việc app có đang chạy hay không**: thông báo vẫn tới đúng giờ **khi app đã bị đóng** và **sau khi thiết bị khởi động lại**; app KHÔNG được yêu cầu chạy nền liên tục.
- **FR-023**: Engine **KHÔNG** được gây bất kỳ thay đổi nào lên dữ liệu nghiệp vụ (giao dịch, ví, danh mục, ngân sách) — nó chỉ **đọc** dữ liệu nghiệp vụ và chỉ **ghi** lịch sử thông báo + trạng thái đã bắn của chính nó.
- **FR-024**: Engine **KHÔNG** được làm hỏng hay chậm luồng lưu giao dịch: nếu việc tính toán/cảnh báo gặp sự cố bất kỳ, giao dịch PHẢI **vẫn lưu thành công**, người dùng **KHÔNG** thấy lỗi, app **KHÔNG** treo. Mọi tính toán phải hoàn tất trong thời gian không làm người dùng cảm nhận được độ trễ.
- **FR-025**: Hệ thống PHẢI **tách nhóm thông báo theo loại** ở cấp hệ điều hành để người dùng có thể **tắt riêng từng loại** ngay trong cài đặt của hệ điều hành mà không ảnh hưởng các loại khác; việc tắt ở đó **KHÔNG** làm mất bản ghi trong Trung tâm.
- **FR-026**: Một **thông báo mới của cùng loại và cùng đối tượng trong cùng kỳ** PHẢI **thay thế** thông báo cũ đang nằm trên màn hình khoá thay vì xếp một loạt thông báo trùng nội dung; **bản ghi lịch sử** thì vẫn **đầy đủ** theo từng lần phát sinh.
- **FR-027**: Nội dung thông báo và bản ghi lịch sử PHẢI sinh theo **ngôn ngữ đang chọn tại thời điểm bắn** (PBI 19), và **giữ nguyên văn** như lúc lưu — đổi ngôn ngữ sau đó **KHÔNG** dịch lại nội dung đã lưu (đồng bộ PBI 30). Số tiền và thời gian dùng đúng định dạng của app (phân tách nghìn bằng dấu chấm, đơn vị `đ`; giờ `HH:mm` 24 giờ).
- **FR-028**: Engine PHẢI **không bắn bù** các mốc đã trôi qua khi app/quyền thông báo/thời gian hệ thống bị gián đoạn (thiết bị tắt nguồn qua giờ nhắc, quyền bị chặn rồi cấp lại, cấu hình vừa được bật): chỉ các mốc **ở tương lai** mới được lên lịch. Người dùng đã cài app từ bản trước, khi mở app sau khi cập nhật, **KHÔNG** bị dội một loạt thông báo của các kỳ/ngày đã qua.
- **FR-029**: Trần lưu lịch sử **200** bản ghi của PBI 30 PHẢI vẫn đúng khi engine ghi liên tục: số bản ghi xem được **không bao giờ vượt 200**, và bản ghi bị dọn luôn là **cũ nhất**.
- **FR-030**: Bật/tắt, ngưỡng, số ngày nhắc trước và giờ nhắc PHẢI được đọc từ **cấu hình đang lưu** (PBI 28/29) ở **mỗi lần** engine tính toán — màn `01`/`02` vẫn là **nơi duy nhất** người dùng chỉnh cấu hình; engine **KHÔNG** thêm màn hình hay luồng chỉnh tham số mới.
- **FR-031**: Engine PHẢI hoạt động **đầy đủ khi không có mạng** và **KHÔNG** gửi bất kỳ dữ liệu nào ra khỏi thiết bị (kể cả số liệu chi tiêu trong nội dung thông báo).
- **FR-032**: Khi quyền thông báo của hệ điều hành **không được cấp** (người dùng từ chối ở FR-017, hoặc tắt sau đó trong cài đặt hệ thống), màn "Thông báo & nhắc nhở" (`01`) PHẢI hiển thị **một dòng trạng thái** nêu rõ thông báo đang bị tắt, kèm lối **mở cài đặt thông báo của hệ điều hành** để bật lại; dòng này **CHỈ** xuất hiện khi quyền không được cấp. Khi quyền **đã** được cấp, màn hiển thị **đúng như mockup `01`** — **KHÔNG** thêm dòng nào. Việc hiện/ẩn dòng trạng thái **KHÔNG** làm đổi trạng thái công tắc hay tham số cấu hình.

## Tiêu chí thành công

- **SC-001**: Đối chiếu với `04-mau-thong-bao-day.svg`: **4/4** mẫu (cảnh báo ngân sách, nhắc nhập giao dịch, nhắc hóa đơn định kỳ, tổng kết tuần) có **đúng cấu trúc nội dung** (tên app + tiêu đề + dòng mô tả kèm số liệu + nhãn thời gian) và **đúng màu ngữ nghĩa** (coral **chỉ** ở cảnh báo ngân sách) — mẫu thứ 3 không áp dụng trong đợt này vì chưa có module.
- **SC-002**: Với cấu hình 20:30, thông báo nhắc hàng ngày tới **đúng phút đã cấu hình**, trong **100%** số ngày được chọn qua 1 tuần thử.
- **SC-003**: Trên các ngày **không** được chọn trong tuần: **0** thông báo và **0** bản ghi.
- **SC-004**: Khi cờ "chỉ nhắc nếu chưa ghi" bật và hôm nay **đã** ghi giao dịch: **0** thông báo, **0** bản ghi (kiểm chứng qua 3 ngày liên tiếp).
- **SC-005**: Mỗi ngân sách, mỗi kỳ: **tối đa 1** thông báo cho ngưỡng sớm và **tối đa 1** cho ngưỡng vượt mức — thêm **5** giao dịch liên tiếp vượt cùng ngưỡng → đúng **1** thông báo (0 lần bắn lặp).
- **SC-006**: Tổng kết: **1** thông báo/tuần và **1** thông báo/tháng; nội dung chứa **đúng** số liệu của kỳ vừa kết thúc và **đúng** chiều so sánh với kỳ liền trước (0 trường hợp sai chiều, 0 giá trị chia cho 0).
- **SC-007**: **100%** thông báo đã bắn có **đúng một** bản ghi tương ứng trong Trung tâm (đối chiếu số lượng trước/sau: 0 lệch).
- **SC-008**: **100%** lần tap thông báo tới **đúng** màn đích theo loại, sau khi vượt qua màn mở khoá PIN khi app đang khoá; **0** trường hợp vào sai màn.
- **SC-009**: Khi quyền thông báo bị chặn: **0** thông báo hiện ra, **100%** bản ghi vẫn được ghi, **0** lỗi/cảnh báo hiện cho người dùng.
- **SC-010**: Sau **khởi động lại thiết bị** (không mở app): thông báo theo giờ vẫn tới **đúng giờ** trong **100%** lần thử (0 mốc bị mất).
- **SC-011**: Tắt một công tắc rồi dùng app tiếp: **0** thông báo và **0** bản ghi mới của loại đó; bật lại: loại đó hoạt động lại (0 trường hợp phải khởi động lại app).
- **SC-012**: Lưu giao dịch khi engine chạy: thao tác hoàn tất **dưới 1 giây**, **0** lỗi hiện ra cho người dùng, kể cả khi engine gặp sự cố.
- **SC-013**: Sau một tuần dùng app: **0** thay đổi về số bản ghi giao dịch/ví/danh mục/ngân sách so với khi chưa có engine.
- **SC-014**: Ở **English**, **100%** thông báo và bản ghi mới dùng tiếng Anh; bản ghi cũ giữ **nguyên văn** ngôn ngữ lúc bắn (**0** bản ghi bị dịch lại).
- **SC-015**: Người dùng bình thường (không hướng dẫn trước) **nhận ra** thông báo thuộc loại nào và **biết cần làm gì tiếp** chỉ từ nội dung — đo bằng việc **100%** người thử nêu đúng hành động gợi ý.
- **SC-016**: Trong 1 tuần dùng thật: số thông báo nhận được **≤ 2/ngày** với cấu hình mặc định (0 trường hợp bị dội thông báo).
- **SC-017**: **0** dữ liệu (nội dung chi tiêu, tên danh mục, số tiền) được gửi ra khỏi thiết bị — kiểm chứng bằng việc app hoạt động đầy đủ ở chế độ máy bay.
- **SC-018**: **100%** trường hợp quyền chưa được cấp: lời giải thích của app hiện **trước** hộp thoại hệ thống (0 lần hộp thoại hệ thống bật lên đột ngột), và lời giải thích chỉ xuất hiện **đúng 1 lần** qua nhiều lần mở màn (0 lần lặp).
- **SC-019**: Dòng trạng thái quyền: hiện **100%** khi quyền không được cấp, **0** lần hiện khi quyền đã được cấp; việc hiện/ẩn dòng này làm thay đổi **0** giá trị công tắc/tham số cấu hình.

## Thực thể chính

- **Cấu hình nhắc nhở** (đã có từ PBI 28/29, lưu bền trên thiết bị): engine **đọc** trạng thái bật/tắt, giờ/phút, tập ngày trong tuần, cờ "chỉ nhắc nếu chưa ghi", ngưỡng sớm/vượt mức, giờ tổng kết tuần/tháng. Engine **KHÔNG** ghi vào đây.
- **Bản ghi lịch sử thông báo** (đã có từ PBI 30): loại, tiêu đề, nội dung, thời điểm phát sinh, trạng thái đã đọc, liên kết tới đối tượng liên quan. PBI này là **nguồn ghi** cho bảng đó; trần 200 bản ghi gần nhất vẫn được giữ.
- **Trạng thái chống bắn trùng** (mới): với mỗi **cặp (loại nhắc + đối tượng liên quan + kỳ/ngưỡng)**, ghi nhận **đã bắn lúc nào** để bảo đảm tần suất tối đa (1 lần/ngày với nhắc hàng ngày; 1 lần/ngưỡng/ngân sách/kỳ với cảnh báo ngân sách; 1 lần/tuần và 1 lần/tháng với tổng kết). Phải **lưu bền** qua các lần đóng/mở app và khởi động lại thiết bị.
- **Lịch nhắc đã đăng ký với hệ điều hành** (mới): các mốc thời gian đã đặt trước cho những loại theo giờ cố định, để hệ điều hành bắn đúng giờ **kể cả khi app không chạy**; được **đăng ký lại** khi cấu hình đổi, khi app khởi động và sau khi thiết bị khởi động lại.

## Giả định

- **"Thông báo đẩy" của PBI này = thông báo hệ điều hành do chính thiết bị sinh ra** (local notification hiển thị trên màn hình khoá đúng như mockup `04`) — doc nghiệp vụ §1 chốt rõ **không có push từ server/FCM** và app offline hoàn toàn; **KHÔNG** có đăng ký thiết bị, **KHÔNG** có máy chủ gửi tin.
- **Mockup `04` là mẫu NỘI DUNG thông báo, không phải màn hình cần dựng** (đồng bộ kết luận của PBI 28 ngoài phạm vi và PBI 30) — đợt này chỉ dựng engine bắn ra thông báo đúng các mẫu đó.
- **Phạm vi loại thông báo**: chỉ 3 loại có dữ liệu để tính (nhắc hàng ngày, cảnh báo ngân sách, tổng kết tuần/tháng); 2 loại **giao dịch định kỳ** và **mục tiêu tiết kiệm** chờ module tương ứng (GĐ2/GĐ3) — công tắc của chúng ở màn `01` **giữ nguyên** hành vi hiện có. [Q1 chọn A]
- **Cảnh báo ngân sách tính theo NGÂN SÁCH THEO DANH MỤC** — phạm vi ngân sách duy nhất đang tồn tại trong app (PBI 20/21). Doc nghiệp vụ §2 ghi "danh mục/ví" nhưng **ngân sách theo ví** thuộc GĐ2, **không** thuộc đợt này; ngưỡng dùng **cấu hình chung** ở màn `01` (không có ngưỡng riêng cho từng ngân sách — đồng bộ PBI 28).
- **Hai hàng chevron "Ngưỡng cảnh báo" và "Nhắc trước"** ở màn `01` **vẫn là điểm nối no-op**: engine **đọc** giá trị đang lưu nhưng đợt này **không** dựng luồng chỉnh sửa chúng.
- **Thời điểm bắn là giờ địa phương của thiết bị**; đổi múi giờ làm giờ bắn dịch theo giờ địa phương mới (không bắn bù). Cách xử lý múi giờ là quyết định mở đã biết của dự án.
- **Kỳ của tổng kết**: tuần = **Thứ Hai → Chủ Nhật vừa kết thúc** (đồng bộ module Báo cáo); tháng = **tháng dương lịch vừa kết thúc**; "ngày cuối tháng" theo lịch của tháng đó.
- **Giao dịch chuyển khoản nội bộ không tính là chi** trong mọi phép tính của engine (đồng bộ nguyên tắc nghiệp vụ xuyên module); giao dịch đã bị xoá không được tính.
- **Bản ghi lịch sử là ảnh chụp tại thời điểm bắn**: sửa/xoá giao dịch sau đó **không** tính lại nội dung đã lưu và **không** thu hồi thông báo đã bắn (đồng bộ PBI 30).
- **Nội dung câu chữ lấy đúng văn phong mockup `04`** (tiếng Việt) và bản dịch tiếng Anh tương ứng; số tiền dùng định dạng của app (`42.500.000 đ`), giờ dạng `HH:mm`.
- **Thông báo không đánh thức/khoá màn hình, không phát âm thanh tuỳ chỉnh** — dùng hành vi mặc định của hệ điều hành (màn `04` chỉ là mẫu minh hoạ).
- **Khoá app (PIN) không chặn engine**: engine vẫn tính và ghi lịch sử khi app đang khoá; chỉ **điều hướng từ thông báo** mới phải qua màn mở khoá trước.
- **Trần 200 bản ghi lịch sử** do tầng lưu lịch sử cưỡng chế (PBI 30) — engine ghi qua đúng đường đó, **không** tự dọn.
- **Không có đồng bộ/tài khoản**: cấu hình và lịch sử thông báo **không** đi kèm backup/restore JSON (GĐ3).
- **Giới hạn nền tảng là điều đã biết và chấp nhận**: một số máy Android tối ưu pin có thể giết tiến trình và làm lỡ nhắc — đợt này **chưa** có UI hướng dẫn autostart/cảnh báo tối ưu pin (xem "Ngoài phạm vi").
- **Màn `01` được bổ sung DUY NHẤT một dòng trạng thái quyền** (FR-032) so với mockup `01` của PBI 28 — và **chỉ** khi quyền thông báo không được cấp. Đây là *lệch nhỏ có chủ ý*: PBI 28 chốt "màn không hiển thị nhắc nhở gì về quyền" **trong đợt đó** vì engine chưa tồn tại và công tắc chỉ là cấu hình đặt trước; nay engine đã có, im lặng hoàn toàn sẽ khiến người dùng tưởng thông báo hỏng. Khi quyền đã cấp, màn vẫn đúng mockup `01` **không thêm gì**.
- **Lời giải thích xin quyền (soft-ask) là nội dung trong app**, hiện **1 lần** ở lần mở màn `01` đầu tiên — không phải màn hình riêng, không có màn onboarding mới, không hỏi lại ở màn `02` hay chỗ nào khác.

## Ngoài phạm vi

- **Mọi thông báo đến từ bên ngoài thiết bị**: server/FCM, tài khoản, đồng bộ, đăng ký thiết bị, gửi tin từ xa — trái với nguyên tắc offline của dự án.
- **Hai loại nhắc chưa có dữ liệu**: nhắc **giao dịch định kỳ** sắp đến hạn và nhắc **mục tiêu tiết kiệm** (đóng góp định kỳ / mốc 50–75–100%) [Q1 chọn A] — cùng với việc dựng hai module đó (GĐ2/GĐ3). Công tắc ở màn `01` vẫn lưu được, không báo lỗi, không ghi "sắp có".
- **Màn hình chỉnh tham số còn thiếu**: chỉnh **ngưỡng cảnh báo** và **nhắc trước N ngày** (2 hàng chevron vẫn no-op), và các màn cấu hình của 2 loại chưa có module.
- **UI cảnh báo/hướng dẫn giới hạn nền tảng**: hướng dẫn thêm app vào danh sách autostart, cảnh báo khi hệ điều hành chặn lịch nhắc chính xác, phát hiện tiết kiệm pin — điểm nối cho PBI sau. (**Không** bao gồm dòng trạng thái quyền thông báo ở FR-032 — đó **thuộc** đợt này.)
- **Widget màn hình chính và Quick Add từ thông báo** (quyết định mở #6 của dự án).
- **Tuỳ chỉnh hiển thị thông báo**: âm thanh, rung, kiểu hiển thị, ảnh lớn, nút hành động nhanh trên thông báo.
- **Nhắc thêm lần hai trong ngày, nhiều khung giờ cho cùng một loại, nhắc theo khoảng** — doc nghiệp vụ §2 chốt 1 lần/ngày cho nhắc hàng ngày.
- **Ngưỡng cảnh báo riêng cho từng ngân sách** và **cảnh báo "tốc độ tiêu nhanh hơn dự kiến"** (2c còn lại của module Ngân sách).
- **Xoá lịch sử thông báo, đánh dấu tất cả đã đọc, ghim/tìm kiếm trong lịch sử** — PBI 30 đã chốt không có.
- **Ghi cấu hình và lịch sử thông báo vào file backup/restore JSON** (GĐ3).
- **Loại thông báo khác ngoài 5 loại** trong doc nghiệp vụ §2 (nợ đến hạn, nhắc backup định kỳ...).

## Quyết định đã chốt

- **Q1 — chọn A: engine đợt này bắn 3 loại** (nhắc nhập giao dịch hằng ngày, cảnh báo ngân sách, tổng kết tuần/tháng) — hai loại **nhắc giao dịch định kỳ** và **nhắc mục tiêu tiết kiệm** chưa có module dữ liệu (GĐ2/GĐ3) nên **không** bắn; công tắc của chúng ở màn `01` giữ nguyên hành vi hiện có (lưu được, không báo lỗi, không ghi "sắp có"). Không dựng "khuôn chung" cho loại chưa có dữ liệu. (chốt 2026-09-13)
- **Q2 — chọn C: hỏi quyền thông báo ở lần đầu mở màn "Thông báo & nhắc nhở"** — có lời giải thích lý do (soft-ask) hiện **trước** hộp thoại của hệ điều hành, chỉ hỏi **một lần**; kèm dòng trạng thái khi quyền không được cấp (FR-032). (chốt 2026-09-13)
- **Q3 — chọn A: chỉ chặn bắn khi app đang mở VÀ đang ở đúng màn liên quan** (theo doc nghiệp vụ §2) — app đang mở ở màn khác thì vẫn bắn bình thường; trường hợp bị chặn thì **không** ghi bản ghi lịch sử (tránh trùng lặp với thông tin người dùng đang nhìn). (chốt 2026-09-13)
