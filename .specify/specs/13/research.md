# Nghiên cứu & quyết định kỹ thuật — PBI 13

**Mã PBI**: 13
**Ngày**: 2026-09-05
**Trạng thái**: hoàn tất — mọi `NEEDS CLARIFICATION` đã chốt.

## Quyết định

### R1. Thêm seam đọc danh mục **gồm cả ẩn** — `categoriesIncludingHidden({type})`
- **Quyết định**: Thêm method mới vào `WalletRepository` (interface + `DriftWalletRepository` + `FakeWalletRepository`): `Future<List<Category>> categoriesIncludingHidden({required CategoryType type})` — trả **toàn bộ** danh mục của loại (cha + con, đang hoạt động **và** đang ẩn), sắp theo `sortOrder`.
- **Lý do**: Repository `categories({type})` hiện có (PBI 11) cố ý chỉ trả danh mục **đang hoạt động** cho picker giao dịch mới (drift lọc `is_hidden == false` ở SQL, fake lọc `!isHidden`). Màn PBI 13 (FR-006) **phải hiện cả danh mục ẩn** để quản lý → không tái dùng `categories()` được. Bảng nhỏ (vài trăm dòng local) nên một truy vấn `where type` + lọc/sort trong Dart là đủ (bám pattern drift hiện có). Additive — không đụng `categories()` nên picker PBI 11/12 không hồi quy.
- **Phương án khác đã xem xét**:
  - Đổi ngữ nghĩa `categories()` cho trả cả ẩn → phá luật "picker không chọn danh mục ẩn" (PBI 11 FR, giao dịch mới), phải sửa mọi caller/test. Loại.
  - Thêm method riêng chỉ trả danh mục **ẩn**, ghép client với `categories()` → 2 truy vấn mỗi tab + rủi ro sót con/cha, phức tạp hơn 1 method trả đủ. Loại.

### R2. Không dùng controller — màn StatefulWidget nạp 1 lần khi mở
- **Quyết định**: `CategoryListScreen` là `StatefulWidget` seam `WalletRepository? repository` (mặc định `ensureWalletRepository()`), nạp dữ liệu **1 lần trong `initState`** (pattern `SearchFilterScreen` PBI 12 / `CategoryPickerScreen` PBI 11) — không thêm `CategoryController`/GetX.
- **Lý do**: FR-008 (dữ liệu mới phản ánh khi quay lại) thoả mãn nhờ màn là sub-page **đẩy route mới mỗi lần** từ Cài đặt → `initState` chạy lại → đọc DB lại. Không có controller nghĩa là không phình state (PBI 13 chỉ đọc, điểm vào no-op); ít file, ít test, đúng seam cũ cho test bơm fake trực tiếp (như `CategoryPickerScreen`, không cần Get).
- **Phương án khác đã xem xét**:
  - GetX controller singleton + reactive cache (pattern ví PBI 5–6) → cần `category_deps.dart`, controller, test controller cho hành vi đọc-lại khi quay lại; nhưng màn không ở bottom-nav (không bị giữ sống), không có sửa-đổi-trong-stack ở PBI này → thừa. Loại.
  - Nạp lại DB mỗi lần chuyển tab → giật + không giữ thứ tự ổn định (FR-004). Loại (xem R3).

### R3. Nạp **cả 2 loại một lúc** khi mở, chuyển tab lọc local trong memory
- **Quyết định**: `initState` gọi `Future.wait([categoriesIncludingHidden(expense), categoriesIncludingHidden(income)])` giữ vào state `_expense`/`_income`; tab chỉ chọn hiển thị danh sách tương ứng, **không** đọc DB lại.
- **Lý do**: FR-004 yêu cầu thứ tự ổn định và chuyển qua lại hai tab không lẫn, không mất trạng thái; giữ cache trong vòng đời màn đảm bảo điều đó + chuyển tab tức thì (SC-003). SC-001: 2 truy vấn bảng danh mục (vài trăm dòng) hiển thị < 1s.
- **Phương án khác**: nạp từng tab lúc chọn (lazy) → chuyển tab phải chờ/spinner, vi phạm trải nghiệm "không giật" và phức tạp hơn. Loại.

### R4. FAB: thêm param `floatingActionButton` cho `SubPageScaffold` (cộng thêm, tái dùng)
- **Quyết định**: `SubPageScaffold` nhận thêm `Widget? floatingActionButton` truyền xuống `Scaffold`; `CategoryListScreen` dùng `SubPageScaffold` + FAB `Icons.add` (nền `AppColors.teal`, icon trắng, tròn).
- **Lý do**: Sub-page từ Cài đặt theo comment `SubPageScaffold` ("Cài đặt (sub-page) tái dùng sau") là khung chung app bar teal + back + actions — đúng nhu cầu PBI 13 (tiêu đề, nút back tự động, icon sắp xếp qua `actions`). FAB thiếu trong khung → thêm 1 param là 1 dòng, mọi màn phụ tương lai (PBI Danh mục sau) dùng chung. Không nhân đôi Scaffold/AppBar thủ công trong màn mới.
- **Phương án khác đã xem xét**: màn tự dựng `Scaffold(appBar: AppBar(...), floatingActionButton: ...)` như `CategoryPickerScreen` → trùng code app bar + lệch theme/back với các màn dùng `SubPageScaffold`. Loại. FAB theme mặc định (primary từ `ColorScheme.fromSeed`) lệch teal `#0F6E56` → set token `AppColors.teal` như nút `ElevatedButton` PBI 6.

### R5. Leading bubble: nền **nhạt phái sinh từ màu danh mục** + icon **màu đầy đủ của danh mục** (bám mockup 01)
- **Quyết định**: vòng tròn 36px nền `Color(c.color).withValues(alpha: ~0.14)` (pha trên nền trắng) chứa `Icon(categoryIcon(c.icon), color: Color(c.color))`. Bảng màu không cần token mới.
- **Lý do**: Mockup `01-danh-sach-danh-muc.svg`: nền tròn nhạt (`#FDEEE0`…) + ký tự/icon màu nhận diện đậm (`#F2994A`…); chữ A/D/N trong mockup là chỗ trống minh hoạ (giả định spec) → thay bằng icon thật + màu `categories.color` (dữ liệu, không hardcode). Khác lưới picker PBI 11 (nền = màu đậm, icon trắng) vì là 2 mockup khác nhau.
- **Phương án khác**: tô vòng tròn bằng màu đậm + icon trắng (pattern picker) → lệch mockup 01. Cần helper pha màu riêng để "nhạt hoá" → quá tay cho 1 màn. Loại.

### R6. Hàng tab "Chi tiêu / Thu nhập": tự dựng 2 nhãn + underline teal 3px (không Material `TabBar`)
- **Quyết định**: widget con cục bộ: hàng 2 `InkWell` text — tab chọn chữ teal đậm + thanh gạch chân teal bo 1.5 cao 3px dưới chữ, tab kia chữ xám `AppColors.tabInactive`; vạch chia ngang `AppColors.listDivider` dưới hàng; mặc định tab **Chi tiêu** (expense). Hai nhãn xếp trái từ lề (không chia đôi màn) — khớp mockup (nhãn tại x≈24 và x≈124).
- **Lý do**: Mockup tab không phải `TabBar` Material chuẩn (nhãn trái, gạch chân chỉ dưới tab chọn, không fill ngang); tự dựng ít code hơn điều chỉnh indicator của Material để khớp pixel, dễ test theo text. Tab là enum `CategoryType` trong state màn.
- **Phương án khác**: `DefaultTabController` + `TabBar(indicator: ...)` → style không khớp, vị trí/width indicator vặn vẹo, thêm controller. Loại.

### R7. Dòng danh mục & đếm con: tính client từ danh sách cùng loại đã nạp
- **Quyết định**: từ danh sách 1 loại (cha + con, gồm ẩn): `topLevelParents = list.where(isParent)` sắp `sortOrder`; con của cha = `list.where((c) => c.parentId == parent.id)` — **đếm gồm con ẩn** (FR-005, edge "con ẩn vẫn tính"). Đặt trong module **thuần** `lib/core/category/category_list.dart` + unit test (không widget).
- **Lý do**: "N danh mục con" là số danh mục con (không phải giao dịch), gồm con đang ẩn — việc tách cha/con + đếm là luật hiển thị có biên đáng test độc lập; module thuần giữ screen mỏng và PBI sau (danh sách con 03) tái dùng `childrenOf`.
- **Phương án khác**: tính inline trong screen → widget test phải phủ mọi biên, logic lẫn UI. Loại.

### R8. Điểm vào no-op có chủ đích (FR-002/007, SC-008) — không gây lỗi/treo
- **Quyết định**: dòng danh mục = `InkWell(onTap: () {})` (có ripple → "chạm được"); FAB `onPressed: () {}` (không disable — vẫn nhìn như nút sống); icon sắp xếp app bar = `IconButton(onPressed: () {})`. Không đẩy route, không hiện SnackBar.
- **Lý do**: Spec chốt phạm vi PBI này = hiển thị + dựng điểm vào; màn đích (thêm/sửa, danh mục con 03, sắp xếp 04) ở PBI sau. Chạm no-op đáp ứng "không lỗi/treo". Không SnackBar vì spec không yêu cầu và PBI sau sẽ thay onTap bằng navigation thật (như icon lọc PBI 9 → PBI 12).
- **Phương án khác**: để `onTap: null` (disable, mất ripple) → không "thể hiện rõ điểm vào tương tác" (FR-007). Hiện SnackBar "sắp ra mắt" → thêm chuỗi/UI không được spec đòi. Loại.

### R9. Điểm vào Cài đặt: hàng "Danh mục" trong nhóm KHÁC, sau "Quản lý ví"
- **Quyết định**: `SettingsScreen` thêm hàng "Danh mục" (chevron) ngay dưới "Quản lý ví" trong nhóm `KHÁC`; `SettingsScreen` nhận seam mới `VoidCallback? onManageCategoryTap` (mặc định push `CategoryListScreen()`; test bơm callback — bám `onManageWalletTap`).
- **Lý do**: Màn là sub-page quản lý cấu trúc (như "Quản lý ví") → cùng nhóm KHÁC; spec giả định vị trí "xử ở bước lập kế hoạch". Đặt sau "Quản lý ví" giữ nhóm công cụ quản lý liền nhau.
- **Phương án khác**: nhóm riêng "DANH MỤC" → chưa đủ hàng để tách nhóm. Đưa lên nhóm TÀI KHOẢN → sai ngữ nghĩa. Loại.

## Kết luận
- **Không đổi schema drift** (schemaVersion giữ **4**, không chạy `build_runner`) — PBI chỉ **đọc** danh mục, không thêm bảng/cột.
- **Không thêm dependency** — không package mới.
- Additive tối thiểu: 1 method đọc mới (interface + drift + fake), 1 param `SubPageScaffold`, 1 hàng Cài đặt, 1 module thuần + 1 màn.
