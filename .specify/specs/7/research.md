# Giai đoạn 0 — Nghiên cứu: Thêm/sửa ví

**Mã PBI**: 7

PBI 7 là **luồng ghi đầu tiên** của module Ví và là PBI **đặt hạ tầng drift + GetX cho dữ liệu ví**. Mọi quyết định dưới đây ưu tiên: diff nhỏ nhưng đúng kiến trúc đã chốt (drift + GetX), giữ liên tục các màn PBI 5/6, và chừa seam để PBI Giao dịch mở rộng (thêm bảng `transactions`, bỏ bộ mẫu).

---

## Q1. Lưu trữ ví — wire drift ngay hay store trong bộ nhớ?

- **Quyết định**: **Wire drift ngay** (theo lựa chọn của người dùng). Dựng bảng `wallets` trong drift làm nguồn sự thật: schema + migration + DAO/repository. Ví thêm/sửa **bền qua restart app**.
- **Lý do**: Đây là PBI ghi đầu tiên — nếu chọn bộ nhớ thì ví mới mất khi mở lại app, dữ liệu "thật" không tồn tại; người dùng xác nhận chịu phí hạ tầng đợt này để khỏi phải làm lại. `drift ^2.34.4` + `get ^4.7.3` đã khai báo sẵn trong `pubspec.yaml` (đúng stack [[Stack kỹ thuật]]), `get` đã chạy thật ở module PIN (`GetMaterialApp` + `PinController`).
- **Phương án khác**: Store trong bộ nhớ GetX seed từ `WalletSource` → đợt này nhẹ nhưng không bền, lệch bản chất "thêm ví" và chắc chắn phải thay lại khi PBI Giao dịch wire drift → làm hai lần.

## Q2. Kiến trúc state & class chịu trách nhiệm (đợt này)

- **Quyết định**: Tầng dữ liệu tách interface: `WalletRepository` (abstract) ← `DriftWalletRepository` (thật, drift) + `FakeWalletRepository` (chỉ dùng test). Controller **GetX** `WalletController extends GetxController` giữ danh sách ví `List<Wallet>` như cache reactive (`update()` sau mỗi lệnh ghi) — đúng pattern `PinController`. Screen **danh sách** đọc controller (reactive); screen **chi tiết** giữ nguyên nhận `Wallet` qua constructor (PBI 6) — chỉ đổi từ `StatelessWidget` → `StatefulWidget` để sau khi sửa xong cập nhật bằng kết quả form trả về.
- **Lý do**: Interface repo là seam để **mọi widget/unit test chạy với fake repo** → không cần sqlite native trên host (xem Q12), controller vẫn test được đầy đủ nghiệp vụ. Chi tiết không cần reactive theo từng phút (nút "Sửa ví" chỉ đến từ chính màn đó) → không phải đập lại toàn bộ test PBI 6.
- **Phương án khác**: Bắt cả list + detail đọc controller qua `Obx` → sạch hơn về lý thuyết nhưng phải viết lại gần hết widget test PBI 6 (bơm controller thay vì `Wallet`); chi phí cao, lợi ích chưa cần. Đưa repository vào `WalletController` ngay (không có interface) → test màn phải mở DB thật.

## Q3. Ví mẫu hiện có (WalletSource PBI 5) — xử lý ra sao khi chuyển sang drift?

- **Quyết định**: `WalletSource.all()` trở thành **hằng seed**: giữ nguyên file làm nguồn dữ liệu demo, được nạp vào DB trong `onCreate` (migration) đúng 1 lần khi DB mới tạo → trên thiết bị sau cài, danh sách ví vẫn 5 ví mẫu như giai đoạn PBI 5/6 (tổng `19.450.000 đ` không đổi → QA cũ vẫn đúng). Ví mới do người dùng tạo được thêm vào DB sau các ví mẫu.
- **Lý do**: Chuyển sang DB mà bỏ seed → app mở ra danh sách rỗng, các màn/mock giao dịch (tham chiếu `walletId` 1..5) không còn chỗ hiển thị, đứt liên tục QA PBI 5/6. Seed chỉ chạy ở `onCreate` nên **không** tự chèn lại sau khi user đã có dữ liệu.
- **Phương án khác**: Không seed → app "trống thật" nhưng phá vỡ pha demo hiện tại và mock giao dịch; chuyển demo sang cờ bật riêng → thêm khái niệm, chưa cần.
- ⚠ Hệ quả để mở: seed demo nằm trong **DB thật** của người dùng. Gỡ khi PBI Giao dịch tới (lúc đó có luồng xóa ví + dữ liệu thật). Acceptance 3 "tạo ví đầu tiên tự mặc định" **không QA được trên thiết bị** (DB luôn có ví mẫu) → phủ bằng unit test nghiệp vụ (xem Q6). (Quyết định mở #1.)

## Q4. Tiền tệ — chỉ VND đợt này (theo lựa chọn của người dùng)

- **Quyết định**: Thêm cột `currency` (text, mặc định `'VND'`) vào bảng + trường `Wallet.currency`. Form hiển thị dòng "Tiền tệ" **đọc-only hiện `Việt Nam Đồng (VND)`** kèm chú thích "Đa tiền tệ sẽ bật ở bản sau" — không có danh sách chọn.
- **Lý do**: Người dùng chọn phương án "Chỉ VND đợt này". Hiển thị số dư theo đơn vị tiền tệ ví (`1.000 USD`) chưa có nguồn sự thật (chưa có module tỷ giá/quy đổi), đổi toàn bộ `formatMoney` đang gắn `đ` ở hàng loạt màn/test → ngoài phạm vi. Lưu cột `currency` để bản sau (module tiền tệ) không phải migration thêm cột.
- **Lệch spec đã ghi nhận**: FR-006 "cho đổi sang tiền tệ khác trong danh sách có sẵn" + edge "chọn tiền tệ khác mặc định → ví mang đúng tiền tệ" **không thực hiện** đợt này — hoãn có chủ đích, ghi rõ trong plan (Rủi ro). Không QA được edge đó.
- **Phương án khác**: Cho chọn vài mã + render đơn vị theo ví → đúng FR-006 nhưng kéo theo helper tiền tệ & câu hỏi mô hình số lẻ/tỷ giá; người dùng đã bác.

## Q5. "Đã có giao dịch" (khóa trường khi sửa) — xác định ở đâu?

- **Quyết định**: Cờ `hasTransactions` **truyền vào form từ người gọi**, không để form tự suy: chế độ **thêm** luôn `false`; chế độ **sửa** từ màn chi tiết = `transactions.isNotEmpty` (chính là tham số màn chi tiết đang giữ — default `TransactionSource.forWallet(id)`). Wallet `Wallet`/controller **không** phụ thuộc `TransactionSource` (tránh vòng import; giao dịch vẫn chưa vào DB).
- **Lý do**: "Đã có giao dịch" = có ≥1 giao dịch gắn ví (spec §Giả định). Hiện giao dịch là mock theo `walletId` (PBI 6) nên ví mẫu 1..4 → khóa, ví mới/sổ tiết kiệm (id 5, trống) → mở. Truyền tham số giúp test bơm tùy ý mà không cần DB giao dịch.
- **Phương án khác**: Form tự gọi `TransactionSource.forWallet` → dính implementation giao dịch vào form, test khó bơm tình huống tùy ý.

## Q6. Bất biến "ví mặc định" — logic đặt đâu?

- **Quyết định**: Hàm **thuần** trong file mới `core/wallet/wallet_rules.dart`, thao tác trên `List<Wallet>` (không phụ thuộc controller/DB), unit test trực tiếp:
  - `hasActiveDefault(list)` — ví active (`!isHidden`) mang `isDefault` ≥? đúng 1.
  - `resolveDefaultOnCreate(list, {required bool wantDefault})` — tạo trong danh sách **chưa có ví active nào** → ép mặc định; muốn mặc định & đã có default khác → dời cờ.
  - `resolveDefaultOnUpdate(list, old, new)` — bật cờ lên 1 ví → gỡ cờ ví default cũ; **tắt** cờ của ví default: còn ≥1 ví active khác → tự chọn thay thế (ví active đầu theo thứ tự hiển thị — xấp xỉ "số dư dương được dùng gần nhất", vì chưa có khái niệm "dùng gần nhất"); chỉ còn mình nó active → **chặn** (giữ mặc định).
- **Lý do**: Rule nghiệp vụ đặc thù (FR-007/008 + edge) nên tách thuần để unit test phủ mọi nhánh — đặc biệt acceptance 3 "ví đầu tiên" chỉ test được ở lớp này (xem Q3). Controller chỉ gọi hàm rồi ghi DB; UI dựa kết quả để chặn/cho tắt.
- **Phương án khác**: Nhúng logic trong form → test nghiệp vụ phải qua widget; nhúng trong controller → khó test thuần nếu controller kẹp DB. Rule "tự chọn thay thế ưu tiên số dư dương & dùng gần nhất" (spec §Giả định) **xấp xỉ bằng thứ tự hiển thị** — ghi nhận là giản lược (Quyết định mở #2).

## Q7. Mở rộng model `Wallet` — thêm trường gì?

- **Quyết định**: Thêm vào `Wallet` các trường **optional có giá trị mặc định** để không phá constructor/hằng hiện có (seed, test PBI 5/6 vẫn biên dịch): `initialBalance` (int), `currency` ('VND'), `color` (int ARGB? — mã màu preset), `statementDate`/`dueDate` (DateTime? — thẻ tín dụng), `termMonths` (int?) + `maturityDate` (DateTime? — sổ tiết kiệm), `institutionName` (String? — ngân hàng/ví điện tử: ngân hàng/tổ chức), `lastDigits` (String? — số cuối, chỉ hiển thị). Kèm `Wallet copyWith(...)`.
- **Lý do**: Các trường này chính là nội dung form (FR-002/003) và cột bảng drift. `color` lưu **int ARGB** (không lưu đối tượng `Color`) để model thuần Dart không import Material. `copyWith` phục vụ sửa (Wallet bất biến).
- **Phương án khác**: Dựng class riêng `WalletDraft` cho form rồi map sang `Wallet` → thêm lớp trung gian; `copyWith` + immutable đủ dùng (ghi toàn bộ 1 bản mới từ store sau mỗi lần sửa).
- Trường `created_at/updated_at` (doc §7) **không thêm** đợt này — chưa có consumer (YAGNI), thêm khi PBI cần audit/backup.

## Q8. Trường riêng theo loại ví — hiển thị & ràng buộc

- **Quyết định**: Form hiển thị động khối trường riêng theo `WalletType` đang chọn (FR-003): Tiền mặt → không có; Ngân hàng / Ví điện tử → `institutionName` (nhãn "Ngân hàng" / "Tổ chức") + `lastDigits` (số cuối, chỉ hiển thị); Thẻ tín dụng → `creditLimit` (**bắt buộc, > 0** — FR-004/SC-002) + `statementDate`, `dueDate` (ngày, chọn bằng date picker, tùy chọn); Sổ tiết kiệm → `termMonths` (số tháng, tùy chọn) + `maturityDate` (tùy chọn). Khi đổi loại ví chưa lưu → xóa giá trị trường riêng loại cũ (edge spec) — form giữ draft riêng theo loại.
- **Lý do**: Đúng đặc tả + doc nghiệp vụ §2. `creditLimit` thẻ phải validate >0 để không tạo thẻ thiếu hạn mức (acceptance 8). Nhãn `institutionName` mềm theo loại ("ngân hàng" bank / "tổ chức" eWallet).
- **Phương án khác**: Một form con riêng mỗi loại → trùng lặp lớn; bộ widget động theo loại là đủ.

## Q9. Icon & màu sắc ví (FR-002, phần "Biểu tượng & màu sắc")

- **Quyết định**: File mới `core/wallet/wallet_presets.dart` chứa: danh sách icon (emoji, ≥8, tái dùng bộ ví hiện có 💵🏦💳📱🏷️ + mở rộng vài emoji trung tính), bảng **8 mã màu tint sáng** (ARGB) phù hợp design system (không màu "chói", lấy tông gần `tealLightBg`/`coralLightBg`/`softCardBg` sẵn có làm tham chiếu), và `defaultIconFor(WalletType)` (khớp seed: cash 💵, bank 🏦, credit 💳, eWallet 📱, savings 🏷️). `Wallet.color` nullable; hàng ví màn danh sách tô tròn icon bằng màu ví (fallback `tealLightBg` khi null).
- **Lý do**: Mockup chưa vẽ bảng màu chi tiết (spec §Giả định giao cho triển khai). Design system: 1 teal hành động / coral chi tiêu — nên màu ví là **tint nền trang trí**, không đụng ngữ nghĩa màu hành động. Emoji nhất quán với `Wallet.icon` hiện tại (String emoji).
- **Phương án khác**: Material icon cho màu/icon ví → đổi kiểu dữ liệu `icon` đang là emoji ở khắp seed/test; bảng màu 16 ô → thừa.

## Q10. Cấu trúc form & nút "Lưu ví" (SC-007 — cỡ chữ lớn/vùng an toàn)

- **Quyết định**: Form là sub-page dùng `SubPageScaffold` (app bar teal + back — FR-001/002), body = **một scroll duy nhất**, nút **"Lưu ví" cố định chân màn** (không cuộn theo) → mở rộng `SubPageScaffold` thêm tham số `bottomNavigationBar` (forward sang `Scaffold`). Validate khi chạm Lưu: báo lỗi **tại đúng trường** (tên trống/khoảng trắng, số dư trống lúc tạo, hạn mức thẻ ≤0); số dư = 0 hợp lệ.
- **Lý do**: FR-005/SC-006 yêu cầu chặn + báo lỗi đúng vị trí; SC-007 yêu cầu nút Lưu luôn với tới (cố định chân) dù body dài/cỡ chữ lớn. Scroll toàn phần chống overflow cỡ chữ lớn.
- **Phương án khác**: Lưu nằm cuối scroll → cỡ chữ lớn phải cuộn xa mới tới nút; mở rộng `SubPageScaffold` bằng tham số chung, không phá màn cũ.

## Q11. Điểm vào — nối form vào màn nào?

- **Quyết định**: (a) Màn **danh sách ví**: nút `_AddWalletButton` (đang `onPressed: (){}`) → đổi thành push `WalletFormScreen()` chế độ thêm; sau lưu pop về list — list reactive đọc controller nên tự cập nhật tổng + số lượng + hàng mới (FR-013). (b) Màn **chi tiết ví**: hành động nhanh **"Sửa ví"** (đang no-op) → push `WalletFormScreen(wallet, hasTransactions)` chế độ sửa; nhận kết quả (`Navigator.pop` trả `Wallet` đã lưu hoặc cờ) → `setState` cập nhật hero/tên. Hai nút còn lại (Chuyển tiền, Ẩn ví) **giữ no-op** (PBI khác).
- **Lý do**: FR-001 bắt mở form đúng chế độ từ đúng điểm vào; FR-013 bắt màn gọi cập nhật ngay. List reactive nên không cần `await push` để tự refresh; detail nhận kết quả là đủ (chỉ mình nó sửa đổi ví đang xem trong phiên).
- **Phương án khác**: Detail đọc controller `Obx` theo `walletId` → đúng reactive nhưng đập lại toàn bộ test PBI 6 (xem Q2).

## Q12. Dependency drift & chiến lược test (không lệ thuộc sqlite native trên host)

- **Quyết định**: Thêm runtime deps: `sqlite3_flutter_libs`, `path_provider`, `path`. Thêm dev deps: `drift_dev` (cùng dòng 2.x với `drift ^2.34.4`), `build_runner`. Chạy codegen: `dart run build_runner build --delete-conflicting-outputs`; commit file `.g.dart`. Mở DB file qua `NativeDatabase.createInBackground(path)` (đường dẫn `path_provider`).
  - **Test**: widget/unit/controller test dùng `FakeWalletRepository` (map trong bộ nhớ) → **không** mở DB drift → `flutter test` không cần sqlite native. Controller test kiểm nghiệp vụ ghi đọc qua fake. Widget test màn (list/detail/form) seed controller fake từ hằng ví mẫu.
  - Một test **tích hợp DAO** (`wallets_dao_test.dart`) dùng `NativeDatabase.memory()` để kiểm migration + seed + CRUD thật; nếu host không nạp được `sqlite3.dll` (Windows thuần, chưa cài sqlite) → `markTestSkipped` ghi rõ lý do, phần còn lại của bộ DAO xác minh bằng QA trên emulator/thiết bị (app chạy thật dùng `sqlite3_flutter_libs` nên DAO luôn được thực thi).
- **Lý do**: `sqlite3_flutter_libs`/`path_provider`/`path` là bộ chuẩn để drift chạy file DB trên Android/iOS. Tách fake repo giữ bộ test màn nhanh & chạy được trên mọi host; đúng seam Q2. drift không có backend thuần Dart (không codegen thủ công) nên DAO muốn unit-test cần sqlite native.
- **Phương án khác**: Mọi test mở DB drift `memory` → vướng `sqlite3.dll` trên host, bộ test dễ đỏ lan (bài học PBI 3 có thể dùng secure storage giả). Bỏ test tích hợp DAO hoàn toàn → hở migration/seed.

## Q13. Trình tự khởi tạo controller trong app (không phá luồng PIN)

- **Quyết định**: Không đụng `PinGate`/`main`. Thêm helper `WalletDeps.ensure()` (tầng assemble): nếu `Get.isRegistered<WalletController>()` → trả về controller đang có; ngược lại tạo repo drift + controller, `Get.put` (permanent) và **khởi động load nền** (không await ở điểm gọi). Màn **danh sách** gọi `ensure()` trong `initState` (pattern giống `PinGate` put `PinController`) rồi `Obx` đọc; màn form nhận controller qua constructor (từ người gọi) để ghi.
- **Lý do**: Màn danh sách chỉ mở được **sau** mở khóa (PBI 3) nên đặt khởi tạo dữ liệu ví ở đây là đủ, tránh chặn màn khóa PIN khi mở DB. Test bơm controller fake **trước** khi pump → `ensure()` không tạo DB thật.
- **Phương án khác**: Mở DB + put controller trong `main()`/`PinGate` → mọi test pump `SoraApp` phải có DB, và khởi động chậm hơn; tạo controller không ai dùng khi chưa mở màn ví.

## Q14. Nguồn giao dịch & dashboard/report — có đổi không?

- **Quyết định**: **Không đổi**. Giao dịch vẫn là mock `TransactionSource` (PBI 6); `WalletDetailScreen` vẫn nhận `List<Transaction>` qua constructor. Dashboard (Tổng quan), Report, Transaction shell **không tham chiếu** `WalletSource`/ví (đã grep) → không chạm. Chỉ 3 chỗ ví đổi: danh sách (đọc controller), chi tiết (cập nhật sau sửa), mới: form.
- **Lý do**: Phạm vi PBI 7 là form thêm/sửa + hạ tầng lưu ví; giao dịch/DB `transactions` thuộc PBI sau. Đổi màn khác = phình scope không cần.
- **Phương án khác**: Đưa dashboard đọc tổng ví reactive → chưa có nhu cầu (dashboard chưa hiển thị số dư ví).

## Quyết định mở / cần người dùng duyệt

1. **Seed ví mẫu vào DB thật** (Q3): để giữ liên tục pha demo PBI 5/6, 5 ví mẫu được nạp vào `wallets` ở lần tạo DB đầu. Hệ quả: app sau cài không "trống thật"; acceptance 3 (tạo ví đầu tiên tự mặc định) chỉ test được ở lớp unit test nghiệp vụ. **Gỡ seed khi PBI Giao dịch tới** (khi có luồng xóa + dữ liệu thật). Nghiêng giữ seed đợt này.
2. **"Tự chọn ví mặc định thay thế" xấp xỉ bằng thứ tự hiển thị** (Q6): spec §Giả định nói "ưu tiên số dư dương & được dùng gần nhất" — chưa có trường `last_used_at` nên chọn ví active đầu theo `sortOrder`. Khi có khái niệm "dùng gần nhất" (luồng chọn ví) → bổ sung.
3. **Chỉ VND đợt này** (Q4): lệch FR-006 có chủ đích, đã được người dùng chốt qua câu hỏi. Đa tiền tệ + render đơn vị theo ví → PBI riêng (module tiền tệ/tỷ giá). Cột `currency` lưu sẵn `'VND'` để không migration sau.
4. **Test tích hợp DAO drift phụ thuộc sqlite native trên host** (Q12): nếu máy dev Windows chưa có `sqlite3.dll`, test đó `skip`; phủ bằng QA emulator. Đóng điểm này khi thi công nếu cài được sqlite cho host.
