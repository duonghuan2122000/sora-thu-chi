import '../core/budget/budget.dart';
import '../core/category/category.dart';
import '../core/scan/scan_result.dart';
import '../core/transaction/transaction.dart';
import '../core/wallet/wallet.dart';

/// Seam đọc/ghi ví & bút toán của ví — màn hình & controller chỉ phụ thuộc
/// interface này để test bơm fake (không cần sqlite native). Impl thật:
/// [DriftWalletRepository]. Transfer là thao tác domain **ví** chạm hai bảng
/// (`wallets` + `transactions`) trong một DB → đặt cùng một seam (research R6).
abstract class WalletRepository {
  /// Đọc toàn bộ ví, theo [Wallet.sortOrder] (ẩn không lọc — UI tự xử lý).
  Future<List<Wallet>> loadAll();

  /// Tạo ví mới từ [wallet] (id chưa dùng — repository gán) → trả ví đã lưu.
  Future<Wallet> insert(Wallet wallet);

  /// Cập nhật ví theo id; giữ nguyên trạng thái ẩn cũ (FR-012).
  Future<Wallet> update(Wallet wallet);

  /// Giao dịch của đúng ví [walletId], sắp mới nhất lên đầu (FR-008/014).
  /// Domain [Transaction] map 1-1 từ dòng `transactions` (không đổi model).
  Future<List<Transaction>> transactionsOf(int walletId);

  /// Toàn bộ giao dịch của thiết bị — mọi ví kể cả ví ẩn (giữ lịch sử, FR-004),
  /// sắp mới nhất lên đầu. Domain mang [Transaction.transferGroupId] để màn
  /// danh sách gộp 2 vế chuyển khoản thành 1 dòng (FR-007).
  Future<List<Transaction>> allTransactions();

  /// Ghi atomic một lần chuyển tiền (FR-012/015): trừ `balance` ví nguồn, cộng
  /// `balance` ví đích, ghi **2 dòng** `type=transfer` (vế nguồn `−amount`,
  /// vế đích `+amount`, cùng `date`/`note`) liên kết cùng `transfer_group_id`
  /// = id vế ghi trước (R7) — tất cả trong một `db.transaction()`.
  /// [amount] phải dương; validation nghiệp vụ do [transfer_rules]/UI đảm nhận,
  /// repository không tự chặn (T005).
  Future<void> performTransfer({
    required int fromWalletId,
    required int toWalletId,
    required int amount,
    required DateTime date,
    String note = '',
  });

  /// Sửa atomic một giao dịch **Chuyển khoản** đã có (PBI 39, FR-001…008 phần
  /// Chuyển khoản): [transferGroupId] = id vế nguồn (bất biến, không đổi) —
  /// đọc 2 vế hiện có, hoàn tác số dư 2 ví theo vế nguồn/đích **cũ**, áp số dư
  /// mới theo [fromWalletId]/[toWalletId]/[amount], rồi ghi đè tại chỗ 2 dòng
  /// (không xóa/insert) — trong một `db.transaction()` (bám mẫu
  /// `performTransfer`/`updateTransaction`). Đầu vào hợp lệ: [amount] > 0,
  /// `fromWalletId != toWalletId` — repository không tự validate (như
  /// `performTransfer`).
  Future<void> updateTransfer({
    required int transferGroupId,
    required int fromWalletId,
    required int toWalletId,
    required int amount,
    required DateTime date,
    String note = '',
  });

  /// Danh mục **đang hoạt động** (`!isHidden`) thuộc [type] — gồm cha & con;
  /// UI tự tách cha-con bằng [Category.parentId]. Sắp theo sortOrder. (R3/R5)
  Future<List<Category>> categories({required CategoryType type});

  /// Toàn bộ danh mục thuộc [type] cho **màn quản lý danh mục** (PBI 13): gồm
  /// cha cấp 1 **và** con cấp 2, đang hoạt động **và** đang ẩn (`isHidden` đúng
  /// với dòng — màn hiện cả ẩn để quản lý, FR-006); cần con để đếm dòng phụ
  /// "N danh mục con" gồm con ẩn (FR-005). Sắp tăng `sortOrder` (không đảm bảo
  /// cha trước con — UI tự tách qua [Category.isParent]/`parentId`).
  /// Khác [categories]: method đó chỉ trả danh mục **đang hoạt động** cho picker
  /// giao dịch mới (PBI 11) — giữ nguyên, không đổi ngữ nghĩa.
  Future<List<Category>> categoriesIncludingHidden({
    required CategoryType type,
  });

  /// Có ≥ 1 dòng `transactions.category_id == [categoryId]` không — nguồn khóa
  /// đổi loại khi Sửa danh mục (FR-002/008). Giao dịch cũ nâng cấp `< v4` giữ
  /// `category_id = null` → danh mục chỉ được text snapshot tham chiếu không tính.
  Future<bool> categoryHasTransactions(int categoryId);

  /// Ghi một danh mục **mới** — bỏ qua `category.id` (DB sinh), ghi
  /// `name/type/icon/color/parentId/sortOrder/isHidden`, `isSystem = false`
  /// (danh mục tự tạo). Trả [Category] đã lưu (id + đủ trường). Repository
  /// **không** tự validate trùng tên/khóa loại/cây 2 cấp/tính sortOrder —
  /// validation & sort thuộc module thuần + UI (bám seam `addTransaction`).
  Future<Category> insertCategory(Category category);

  /// Ghi **tất cả** trường nghiệp vụ của dòng `id == category.id` — gồm
  /// `isHidden` (công tắc) và `isSystem` (giữ giá trị dòng đang sửa, không tự
  /// đổi). Trả [Category] đã lưu. Không tự validate/tính sortOrder (xem trên).
  Future<Category> updateCategory(Category category);

  /// Ghi atomic thứ tự mới cho danh sách **đủ danh mục cha cấp 1 của đúng một
  /// loại** (màn sắp xếp `04`): đặt `sort_order = 0..n−1` cho từng id theo thứ
  /// tự [orderedIds] trong một transaction (bám mẫu `performTransfer`). Con cấp
  /// 2 & cha loại kia bất biến — mọi consumer xếp theo từng nhóm con
  /// (research R4). Không sửa tên/ẩn/hệ thống.
  Future<void> reorderCategories({required List<int> orderedIds});

  /// Ghi atomic một giao dịch **thu/chi** mới (FR-012/SC-003): bù `balance` ví
  /// (`income` +, `expense` −) và insert 1 dòng `transactions` có dấu theo loại
  /// (`income` `+x`, `expense` `−x`), `category_id = category.id`,
  /// `category = category.name`, trong một `db.transaction()` — không lệch phía.
  /// Đầu vào hợp lệ: [type] income/expense, [amount] > 0, `category.type` khớp
  /// [type], `category.id` > 0. Giao dịch mới để trống transferGroupId/location
  /// (R3); [tags]/[receiptImage] (PBI 38) ghi thẳng nếu người dùng có chọn —
  /// mặc định rỗng giữ hành vi cũ.
  Future<void> addTransaction({
    required int walletId,
    required TxnType type,
    required int amount,
    required Category category,
    required DateTime date,
    String note = '',
    String tags = '',
    String receiptImage = '',
  });

  /// Sửa atomic một giao dịch **thu/chi** đã có (PBI 39, FR-001…007): hoàn tác
  /// `original.amount` (đã có dấu) khỏi `original.walletId`, áp `amount` mới có
  /// dấu theo [type] vào [walletId] (có thể trùng ví cũ), rồi ghi đè đủ cột
  /// nghiệp vụ của dòng `id == original.id` — trong một `db.transaction()`
  /// (bám mẫu `addTransaction`). `transferGroupId`/`location`/`source` giữ
  /// nguyên giá trị cũ. Đầu vào hợp lệ: [type] income/expense, [amount] > 0,
  /// `category.type` khớp [type] — repository không tự validate (như
  /// `addTransaction`).
  Future<void> updateTransaction({
    required Transaction original,
    required int walletId,
    required TxnType type,
    required int amount,
    required Category category,
    required DateTime date,
    String note = '',
    String tags = '',
    String receiptImage = '',
  });

  /// Ghi atomic một giao dịch **quét hóa đơn** (PBI 24, FR-033/FR-034): một
  /// `db.transaction()` gồm bù `balance` ví theo loại + insert 1 dòng
  /// `transactions` (`source = aiScan`, `receipt_image`, `note` = merchant,
  /// `categoryId`/`category` có thể rỗng) + insert 1 dòng `scan_sessions`
  /// (`transaction_id` vừa sinh, `engine` đã dùng). Ảnh phải được lưu vào kho
  /// **trước** khi gọi (FR-036) — repository chỉ ghi đường dẫn.
  Future<void> addScannedTransaction({
    required int walletId,
    required TxnType type,
    required int amount,
    required DateTime date,
    required String receiptImage,
    required ScanEngine engine,
    required String rawText,
    required String parsedJson,
    Category? category,
    String note = '',
    DateTime? createdAt,
  });

  /// Toàn bộ ngân sách của thiết bị (PBI 20) — **không lọc** theo kỳ/danh mục
  /// **và không lọc ngân sách đã lưu trữ** (PBI 21): tầng view tự bỏ qua dòng
  /// `isArchived` (màn Tổng quan, `buildBudgetOverview`).
  Future<List<Budget>> budgets();

  /// Ghi một ngân sách **mới** — bỏ qua `budget.id` (DB sinh), ghi đủ 7 cột.
  /// Trả [Budget] đã lưu. Repository **không** tự validate chồng lấn — luật
  /// thuộc `budget_rules` + UI (bám nếp `insertCategory`).
  Future<Budget> insertBudget(Budget budget);

  /// Ghi đủ 7 cột của dòng `id == budget.id` — dùng cả khi sửa danh mục/số
  /// tiền/chu kỳ, khi bật-tắt lặp lại lẫn khi **lưu trữ** (`isArchived = true`).
  /// Trả [Budget] đã lưu.
  Future<Budget> updateBudget(Budget budget);
}
