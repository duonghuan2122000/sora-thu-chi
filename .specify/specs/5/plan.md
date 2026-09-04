# Kế hoạch triển khai: Màn hình danh sách ví

**Mã PBI**: 5
**Liên kết spec**: .specify/specs/5/spec.md
**Ngày tạo**: 2026-09-04

## Ngữ cảnh kỹ thuật

| Hạng mục | Giá trị |
|---|---|
| Ngôn ngữ / Runtime | Dart 3.12.x (Flutter stable — máy Windows, theo PBI 1–4) |
| Framework / Thư viện chính | Flutter Material; UI thuần widget + model thuần Dart; **không** controller GetX mới (màn đọc tĩnh — PIN PBI 3 đã dùng GetX nhưng không cần ở đây); drift đã khai báo nhưng chưa dùng (đợt này không wire — xem rủi ro) |
| Lưu trữ dữ liệu | **Không thêm** — ví hiển thị từ model hằng + `WalletSource.all()` (5 ví mẫu, khớp SC-003); không đọc/ghi storage (xem `research.md` Q1) |
| Kiểm thử | `flutter analyze` sạch + `flutter test` (unit `formatMoney`/`formatAmount`/tổng & %; widget test màn list ví: 5 ví mẫu / thẻ tín dụng / ví ẩn / rỗng / số âm / cỡ chữ lớn & vùng an toàn / back; **sửa** test settings PBI 4 cho hành vi mới của hàng "Quản lý ví") + QA thủ công emulator theo `quickstart.md` |
| Nền tảng triển khai | Android (kiểm chứng chính); iOS (code thuần widget, rủi ro thấp — verify khi có máy macOS) |
| Ràng buộc hiệu năng | Không đặc thù; danh sách ngắn (đơn vị chục ví) build tĩnh mỗi lần mở, không cần cache/reactive |
| Ràng buộc khác | App offline; màn chỉ hiển thị sau mở khóa (FR-015 — PBI 3 đã đảm bảo, không làm thêm); sub-page không bottom nav; design system: 1 màu teal hành động, coral **chỉ** chi tiêu/cảnh báo (dùng cho thẻ tín dụng); số tiền căn phải, phân tách nghìn `.` + `đ`; card bo 10 / nút chính bo 8 cao 44; style tập trung token (widget không hex cứng); tài liệu & commit tiếng Việt có dấu |

## Kiểm tra theo hiến pháp dự án (trước thiết kế)

Không có `.specify/memory/constitution.md`. Đối chiếu `CLAUDE.md` + design system + wiki [[Ví & Tài khoản]]:

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Offline hoàn toàn, không đăng nhập/server | ✅ | Nguồn ví local (bộ mẫu hằng); không gọi mạng |
| Đúng stack đã chốt | ✅ | Không thêm dependency, không wire drift/GetX mới (research Q10) |
| Design system (1 teal; coral chỉ chi/cảnh báo; sub-page teal + back; card bo 10; định dạng tiền `đ`) | ✅ | Đối chiếu mockup `wallet-list-screen.svg` + [[Design system]]; coral đúng chỗ thẻ tín dụng (ngữ cảnh chi tiêu FR-007) |
| Style tập trung 1 nơi | ✅ | Thêm token `tealLightBg`/`softCardBg` vào `app_colors.dart`; formatter tiền 1 chỗ `money_format.dart`; widget không hex cứng |
| "Cấm số liệu minh họa giả" | ⚠️ | **Ngoại lệ có chủ đích**: spec §Thực thể chính/§Giả định **bắt buộc** bộ ví mẫu để kiểm chứng hiển thị (SC-003) vì chưa có luồng tạo ví & chưa có DB. Không dùng persona/tên người thật; số liệu mẫu phơi bày rõ là dữ liệu demo (xem Rủi ro, user duyệt) |
| Màn ví là sub-page, sau mở khóa | ✅ | Sub-page dùng `SubPageScaffold`; FR-015 thỏa bởi boot/lock PBI 3 — route list ví luôn nằm sau PinGate |
| Hàng/điểm vào chưa có chức năng = treo, không lỗi | ✅ | Chỉ hàng "Quản lý ví" (PBI 4) chuyển sang điều hướng thật theo FR-001; các điểm vào PBI sau (mỗi ví, "+ Thêm ví mới") giữ treo, chạm không lỗi (FR-010) |
| Tài liệu & commit tiếng Việt có dấu | ✅ | Toàn bộ file tiếng Việt |

## Giai đoạn 0 — Kết quả nghiên cứu

Xem chi tiết tại `research.md`. Quyết định chính:

- **Nguồn ví = model hằng + `WalletSource.all()` 5 ví mẫu** (3 thường + 1 thẻ + 1 ẩn); screen nhận `List<Wallet>` qua constructor — seam cho PBI form ví thay bằng drift sau (Q1).
- **Model `Wallet` subset đúng trường màn cần**; `WalletType` 5 loại; `balance` int VND (số dư suy ra ở đời thật, đợt này cấp thẳng) (Q2).
- **Tổng số dư = Σ balance ví hoạt động, không ẩn, KHÔNG phải thẻ tín dụng**; nhãn "N ví đang hoạt động" đếm mọi ví không ẩn (gồm thẻ). ⚠ Đánh dấu quyết định mở cho module tổng hợp (Q3).
- **Bố cục**: tái dùng `SubPageScaffold`; body = card tổng + ListView hàng/empty + nút "+ Thêm ví mới" cố định chân màn, bọc SafeArea đáy (Q4).
- **Formatter tiền thuần** `formatAmount`/`formatMoney` đặt `core/money_format.dart` (chưa có trong repo); % thẻ chia nguyên (`~/`) cho khớp mockup 32% (Q5).
- **2 token màu mới** `tealLightBg #E1F5EE`, `softCardBg #F1EFE8` (Q6); **nối điều hướng** qua `onManageWalletTap` seam trên SettingsScreen, default push route (Q7); **dòng phụ ví mặc định = nhãn "Mặc định" + tên loại** (FR thắng mockup — Q8); **empty state** giữ card "0 đ" + thông báo giữa list (Q9); **không dependency/controller/drift mới, bỏ contracts/** (Q10).

## Giai đoạn 1 — Thiết kế

- **Mô hình dữ liệu**: xem `data-model.md` — `Wallet` (id, name, type, icon, balance, isDefault, isHidden, sortOrder, creditLimit?, creditUsed?) + hàm thuần (thứ tự hiển thị, tổng, % thẻ, chuỗi "Đã dùng…", tên ví ẩn). Đợt này chỉ đọc từ `WalletSource`.
- **Hợp đồng giao diện**: **không tạo** — app nội bộ, offline, không API/CLI công khai.
- **Kịch bản khởi động nhanh**: xem `quickstart.md` — nhóm QA A–F đối chiếu SC-001..008; empty state & số âm phủ bằng widget test (chưa tạo được trên thiết bị).

## Kiểm tra theo hiến pháp dự án (sau thiết kế)

| Nguyên tắc | Tuân thủ? | Ghi chú |
|---|---|---|
| Không phình layer nghiệp vụ | ✅ | Không store/controller/service/repo thừa: 1 model + 1 hằng source + widget + 2 token + formatter tiền |
| Không vi phạm mới phát sinh | ✅ | Ngoại lệ duy nhất = bộ ví mẫu (spec bắt buộc, ghi rõ Rủi ro); lệch mockup dòng phụ mặc định do FR-006 thắng (research Q8) |
| Test không phụ thuộc thiết bị/lưu trữ | ✅ | UI pure widget, bơm `List<Wallet>` qua constructor; unit hàm thuần format/tổng/% |
| Shell, luồng PIN & màn Cài đặt cũ không vỡ | ✅ | Settings chỉ thêm tham số optional + row onTap; test PBI 4 loop "tap Quản lý ví không mở màn" được **cập nhật** đúng hành vi mới (FR-001) |
| Tái dùng hơn viết mới | ✅ | `SubPageScaffold`, `AppColors`, token chữ sẵn có; không thêm `intl`/icon lib (emoji theo mockup) |

## Cấu trúc dự án dự kiến

```text
app/sora_thu_chi/
├── lib/
│   ├── theme/app_colors.dart                    # [SỬA] thêm tealLightBg #E1F5EE, softCardBg #F1EFE8
│   ├── core/
│   │   ├── money_format.dart                    # [TẠO] formatAmount(int) / formatMoney(int) thuần (`.` nghìn + `đ`, âm có dấu trừ)
│   │   └── wallet/
│   │       ├── wallet.dart                      # [TẠO] Wallet + WalletType + hàm thuần:
│   │       │                                    #        displayOrder, activeTotal, activeCount, creditUsedPercent,
│   │       │                                    #        creditUsageLabel(used/limit), hiddenName, typeLabel
│   │       └── wallet_source.dart               # [TẠO] WalletSource.all() — 5 ví mẫu khớp SC-003
│   └── screens/
│       ├── wallet_list_screen.dart              # [TẠO] WalletListScreen(wallets=WalletSource.all()) — SubPageScaffold
│       │                                        #        'Quản lý ví' + _TotalCard + list/_WalletRow/_EmptyState + nút thêm chân màn
│       └── settings_screen.dart                 # [SỬA] _SettingsRow thêm onTap; hàng 'Quản lý ví' → chạm điều hướng
│                                                #        (tham số onManageWalletTap, default push WalletListScreen)
└── test/
    ├── money_format_test.dart                   # [TẠO] unit: 0 / dương / âm / giá trị lớn / không có số thừa
    ├── wallet_list_screen_test.dart             # [TẠO] widget: 5 ví mẫu đủ hàng+card (19.450.000 đ / "4 ví…"),
    │                                            #        thẻ hiển thị "Đã dùng…/…đ"+"32%" coral, ví ẩn mờ cuối list,
    │                                            #        đúng 1 nhãn "Mặc định", rỗng → empty state+nút còn, số âm,
    │                                            #        cỡ chữ lớn/back về, tap hàng/nút thêm không lỗi
    └── settings_screen_test.dart                # [SỬA] bỏ 'Quản lý ví' khỏi loop tap-không-mở; thêm case: tap → đẩy WalletListScreen
```

Không đổi: pubspec.yaml (không thêm dependency), main.dart, app.dart, shell/boot/PIN, `SubPageScaffold` (đủ dùng), android/, ios/.

## Rủi ro & ngoại lệ có lý do

- **Hiển thị 5 ví mẫu cố định trên thiết bị thật (quyết định cần user duyệt)**: nguyên tắc PBI 4 "cấm số liệu minh họa" được gỡ vì spec PBI 5 **bắt buộc** bộ mẫu để kiểm chứng (SC-003) và chưa tồn tại luồng tạo ví/DB. Đây là "dữ liệu thiết bị" giả lập; mọi số liệu rõ ràng là mẫu, không nhận dạng người thật. Khi PBI form ví (có drift) đến → thay `WalletSource` bằng đọc DB, interface trả `List<Wallet>` giữ nguyên (điểm bám research Q1). Nếu không muốn số mẫu trên máy thật → chỉ chạy khi có dữ liệu thật, tức màn luôn rỗng, mất kiểm chứng SC-003/004 bằng mắt.
- **Thẻ tín dụng không góp tổng số dư (⚠ quyết định mở)**: lệch đọc literal "tổng các ví đang hoạt động" (docs §5). Lý do: màn không hiển thị con số balance của thẻ (chỉ "đã dùng/hạn mức" — khoản phải trả); để tổng đối chiếu được với các số đang hiển thị (SC-003) và tránh đặt tiền lệ nợ thẻ trước khi có nghiệp vụ giao dịch thẻ. Muốn tổng net (trừ nợ thẻ) → sửa 1 predicate + bộ mẫu; báo trước khi implement. Cập nhật wiki khi PBI tổng hợp/thẻ tín dụng chốt.
- **Test PBI 4 về hàng "Quản lý ví" phải đổi**: PBI 4 quy định hàng này chưa kích hoạt (tap không mở); PBI 5 FR-001 bắt hàng phải điều hướng → test hiện có sửa theo hành vi mới, thêm case khẳng định đẩy được `WalletListScreen`. Đây là thay đổi có chủ đích theo spec, không phải hồi quy.
- **Empty state & số âm chỉ kiểm chứng bằng widget test**: thiết bị chưa tạo được 0 ví / ví âm (không có luồng tạo/xóa) — chấp nhận, đã có test + nêu quickstart; đánh giá định tính là đủ cho SC-006 (spec giao cách hiển thị cho kế hoạch).
- **Lệch mockup dòng phụ ví mặc định**: mockup vẽ "Mặc định" thay cho loại (vì ví mẫu trùng tên/loại "Tiền mặt"); spec FR-006 đòi hiển thị **cả** loại **lẫn** nhãn mặc định → thi công theo FR ("Mặc định • Tiền mặt"), ghi lệch ở research Q8.
- **Cỡ chữ lớn / tên dài / vùng an toàn**: tên/dòng phụ bó `Expanded` + ellipsis; nút thêm chân màn ngoài ListView + `SafeArea(top:false)`; widget test bơm textScale 2.0 + màn có safe inset kiểm không overflow. Nếu vẫn tràn trên thiết bị thật → điều chỉnh rồi ghi trạng thái sau thi công.
- **iOS chưa verify** (máy Windows): code thuần widget/material, rủi ro thấp; giữ trạng thái, verify khi có máy macOS.

## File đã tạo

- `.specify/specs/5/research.md`
- `.specify/specs/5/data-model.md`
- `.specify/specs/5/quickstart.md`
- `.specify/specs/5/plan.md`

Bước tiếp theo: chạy `/sora-task 5` để phân rã thành tasks.md.
