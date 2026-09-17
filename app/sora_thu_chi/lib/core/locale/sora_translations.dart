import 'package:get/get.dart';

/// Bộ nhãn dịch của app — **khóa là chính chuỗi tiếng Việt đang hiển thị**
/// (R1), nên chỉ cần nhánh `'en'`: thiếu nhánh `'vi'`/thiếu khóa/`Get.locale ==
/// null` thì `String.tr` trả lại khóa (xem `get_utils` `Trans.tr`).
///
/// Vì thế mặc định tiếng Việt không cần bản đồ nào, và 436 test cũ (pump
/// `MaterialApp` thường, `Get.locale == null`) giữ nguyên kết quả.
///
/// KHÔNG đưa vào đây: dữ liệu seed (tên giao dịch/ví/danh mục mẫu), chuỗi dùng
/// làm `ValueKey`, tên riêng/thương hiệu, ký hiệu định dạng (`đ`, `dd/MM/yyyy`) — R9.
class SoraTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {'en': _en};

  static const Map<String, String> _en = {
    // ---------------------------------------------------------------------
    // Điều hướng & khung app
    // ---------------------------------------------------------------------
    'Tổng quan': 'Overview',
    'Giao dịch': 'Transactions',
    'Báo cáo': 'Reports',
    'Cài đặt': 'Settings',

    // ---------------------------------------------------------------------
    // Màn 03 — Ngôn ngữ (tên/dòng phụ 2 hàng là hằng số, KHÔNG dịch — R8)
    // ---------------------------------------------------------------------
    'Ngôn ngữ': 'Language',
    'Áp dụng ngay cho toàn bộ giao diện, nhãn danh mục mặc định và định dạng ngày/số vẫn giữ theo cài đặt Định dạng & Tiền tệ.':
        'Applies immediately to the whole interface and default category names; date/number formats still follow the Format & Currency settings.',

    // ---------------------------------------------------------------------
    // Màn 02 — Giao diện
    // ---------------------------------------------------------------------
    'Giao diện': 'Appearance',
    'Sáng': 'Light',
    'Tối': 'Dark',
    'Theo hệ thống': 'System',
    'Nền trắng, chữ tối': 'White background, dark text',
    'Nền tối, chữ sáng, đỡ mỏi mắt ban đêm':
        'Dark background, light text — easier on the eyes at night',
    'Tự đổi theo cài đặt điện thoại': "Follows your phone's setting",
    'Thay đổi được áp dụng ngay lập tức, không cần khởi động lại ứng dụng.':
        'Changes apply immediately — no need to restart the app.',

    // ---------------------------------------------------------------------
    // Màn Cài đặt
    // ---------------------------------------------------------------------
    'TÀI KHOẢN': 'ACCOUNT',
    'KHÁC': 'OTHER',
    'Tiền tệ mặc định': 'Default currency',
    'Đổi mã PIN': 'Change PIN',
    'Mở khóa sinh trắc học': 'Biometric unlock',
    'Thiết bị chưa hỗ trợ hoặc chưa đăng ký vân tay/khuôn mặt':
        'Device unsupported or no fingerprint/face registered',
    'Chạm để xác thực': 'Tap to authenticate',
    'Sử dụng vân tay hoặc Face ID để mở khóa ứng dụng':
        'Use fingerprint or Face ID to unlock the app',
    'Dùng mã PIN thay thế': 'Use PIN instead',
    'Quản lý ví': 'Manage wallets',
    'Danh mục': 'Categories',
    'Chạm để đổi ảnh đại diện': 'Tap to change avatar',

    // ---------------------------------------------------------------------
    // Màn 01 — Tiện ích & Cá nhân hóa
    // ---------------------------------------------------------------------
    'Tiện ích & Cá nhân hóa': 'Utilities & Personalization',
    'HIỂN THỊ': 'DISPLAY',
    'TRẢI NGHIỆM': 'EXPERIENCE',
    'DỮ LIỆU & TÌM KIẾM': 'DATA & SEARCH',
    'Sáng / Tối / Theo hệ thống': 'Light / Dark / System',
    'Ngôn ngữ hiển thị trong ứng dụng': 'Language used in the app',
    'Định dạng & Tiền tệ': 'Format & Currency',
    'Ngày, tiền tệ, tuần, kỳ tài chính':
        'Dates, currency, week, financial period',
    'Widget màn hình chính': 'Home screen widget',
    'Hiện số dư & chi tiêu hôm nay': "Shows balance & today's spending",
    'Ẩn số dư (Privacy mode)': 'Hide balance (Privacy mode)',
    'Che số tiền trên màn hình chính': 'Masks amounts on the home screen',
    'Máy tính khi nhập số tiền': 'Calculator while entering amounts',
    'Cho phép +, -, x, / khi nhập': 'Allows +, -, x, / while entering',
    'Tìm kiếm toàn cục': 'Global search',
    'Giao dịch, danh mục, ví': 'Transactions, categories, wallets',
    'Quản lý Tag': 'Manage tags',
    'Gắn nhãn cho giao dịch': 'Label your transactions',
    'Không đọc được cài đặt.': 'Could not read settings.',
    'Thử lại': 'Retry',

    // Dialog hướng dẫn ghim widget (ghép từng dòng, không nối chuỗi thủ công).
    'Hướng dẫn ghim widget': 'How to pin the widget',
    'Đóng': 'Close',
    'App không tự ghim widget lên màn hình chính được.':
        'The app cannot pin the widget to your home screen by itself.',
    'Cách ghim trên Android:': 'How to pin on Android:',
    'Chọn "Widgets"': 'Choose "Widgets"',
    'Kéo widget của app ra màn hình chính':
        "Drag the app's widget onto the home screen",
    'Cách ghim trên iPhone/iPad:': 'How to pin on iPhone/iPad:',
    'Chạm nút "+" phía trên': 'Tap the "+" button at the top',
    'Chọn app rồi thêm widget': 'Pick the app, then add the widget',
    'Chạm-giữ màn hình chính': 'Touch and hold the home screen',

    // ---------------------------------------------------------------------
    // Tên danh mục mặc định (CategorySource) — khớp TỪNG KÝ TỰ với `name:`
    // trong `lib/core/category/category_source.dart`. Dịch ở tầng hiển thị:
    // tên khớp khoá ⇒ dịch (FR-009); người dùng đổi tên/tự tạo ⇒ không khớp
    // khoá ⇒ giữ nguyên văn (FR-010). DB không đổi.
    // ---------------------------------------------------------------------
    'Ăn uống': 'Food & Drink',
    'Di chuyển': 'Transport',
    'Nhà ở': 'Housing',
    'Hóa đơn': 'Bills',
    'Mua sắm': 'Shopping',
    'Giải trí': 'Entertainment',
    'Sức khỏe': 'Health',
    'Giáo dục': 'Education',
    'Lương': 'Salary',
    'Thưởng': 'Bonus',
    'Đầu tư': 'Investment',
    'Khác': 'Other',
    'Cà phê': 'Coffee',
    'Ăn ngoài': 'Dine out',
    'Đi chợ': 'Groceries',

    // ---------------------------------------------------------------------
    // Ví — loại ví & nhãn suy ra (core/wallet/wallet.dart)
    // ---------------------------------------------------------------------
    'Tiền mặt': 'Cash',
    'Tài khoản ngân hàng': 'Bank account',
    'Thẻ tín dụng': 'Credit card',
    'Ví điện tử': 'E-wallet',
    'Sổ tiết kiệm': 'Savings account',
    'Đã dùng @used / @limit đ': 'Used @used / @limit đ',
    '(đã ẩn)': '(hidden)',

    // Ví — màn danh sách
    'VÍ CỦA BẠN': 'YOUR WALLETS',
    'TỔNG SỐ DƯ TẤT CẢ VÍ': 'TOTAL BALANCE OF ALL WALLETS',
    '@count ví đang hoạt động': '@count active wallets',
    'Không tính vào tổng': 'Not counted in total',
    'Mặc định': 'Default',
    'Chưa có ví nào.': 'No wallets yet.',
    "Chạm '+ Thêm ví mới' để tạo ví đầu tiên.":
        "Tap '+ Add wallet' to create your first wallet.",
    '+ Thêm ví mới': '+ Add wallet',

    // Ví — màn chi tiết
    'Thẻ tín dụng chưa dùng để chuyển tiền.':
        'Credit cards cannot be used for transfers.',
    'Chưa có ví đích hợp lệ để chuyển tiền.':
        'No eligible destination wallet for a transfer.',
    'GIAO DỊCH GẦN ĐÂY': 'RECENT TRANSACTIONS',
    '@percent% hạn mức đã dùng': '@percent% of limit used',
    'Chuyển tiền': 'Transfer',
    'Sửa ví': 'Edit wallet',
    'Ẩn ví': 'Hide wallet',
    'Chưa có giao dịch nào.': 'No transactions yet.',
    'Giao dịch của ví sẽ xuất hiện tại đây.':
        "This wallet's transactions will appear here.",

    // Ví — màn thêm/sửa ví
    'Ngân hàng': 'Bank',
    'Tổ chức': 'Issuer',
    'Vui lòng nhập tên ví': 'Please enter a wallet name',
    'Vui lòng nhập số dư ban đầu': 'Please enter an initial balance',
    'Số tiền không hợp lệ': 'Invalid amount',
    'Hạn mức phải lớn hơn 0': 'Limit must be greater than 0',
    'Không lưu được ví. Vui lòng thử lại.':
        'Could not save the wallet. Please try again.',
    'Thêm ví mới': 'Add wallet',
    'Lưu ví': 'Save wallet',
    'Tên ví': 'Wallet name',
    'VD: Tiền mặt, Vietcombank…': 'E.g.: Cash, Vietcombank…',
    'Loại ví': 'Wallet type',
    'Số dư ban đầu': 'Initial balance',
    'Số dư': 'Balance',
    'Biểu tượng & màu sắc': 'Icon & color',
    'Hạn mức tín dụng': 'Credit limit',
    'Ngày sao kê (tùy chọn)': 'Statement date (optional)',
    'Ngày đến hạn (tùy chọn)': 'Due date (optional)',
    'Kỳ hạn (tháng, tùy chọn)': 'Term (months, optional)',
    'tháng': 'months',
    'Ngày đáo hạn (tùy chọn)': 'Maturity date (optional)',
    '@org (tùy chọn)': '@org (optional)',
    'VD: Momo, ZaloPay…': 'E.g.: Momo, ZaloPay…',
    'VD: Vietcombank…': 'E.g.: Vietcombank…',
    'Số cuối tài khoản (tùy chọn)': 'Last 4 digits (optional)',
    'Vài số cuối, chỉ để đối chiếu': 'A few last digits, for reference only',
    'Tiền tệ: VND': 'Currency: VND',
    'Ví đã có giao dịch nên không đổi được loại ví và số dư ban đầu. Muốn đổi số dư → tạo giao dịch Điều chỉnh số dư.':
        'This wallet has transactions, so its type and initial balance cannot be changed. To change the balance → create a Balance adjustment transaction.',
    'Chọn ngày': 'Select date',
    'Đặt làm ví mặc định': 'Set as default wallet',
    'Ví này là ví mặc định duy nhất đang hoạt động nên không thể tắt.':
        'This is the only active default wallet, so it cannot be turned off.',

    // Ví — màn chuyển tiền
    'Vui lòng nhập số tiền lớn hơn 0': 'Please enter an amount greater than 0',
    'Không chuyển được tiền. Vui lòng thử lại.':
        'Could not complete the transfer. Please try again.',
    'Chuyển tiền giữa ví': 'Transfer between wallets',
    'Xác nhận chuyển tiền': 'Confirm transfer',
    'Từ ví': 'From wallet',
    'Đến ví': 'To wallet',
    'Số tiền chuyển': 'Transfer amount',
    'Ngày giờ': 'Date & time',
    'Ghi chú': 'Note',
    'Ghi chú (không bắt buộc)': 'Note (optional)',
    'Số dư: @amount': 'Balance: @amount',
    'Chọn ví': 'Select wallet',
    'Chọn ví đến': 'Select destination wallet',
    'Số dư sau chuyển': 'Balance after transfer',
    'Số dư sau chuyển sẽ âm': 'Balance after transfer will be negative',

    // ---------------------------------------------------------------------
    // Giao dịch — màn danh sách
    // ---------------------------------------------------------------------
    'Không đọc được dữ liệu giao dịch.': 'Could not read transaction data.',
    '@n kết quả · Tổng: @total': '@n results · Total: @total',
    'Bỏ lọc': 'Clear filters',
    'Không có giao dịch khớp bộ lọc.': 'No transactions match the filter.',
    'Bỏ lọc để xem toàn bộ.': 'Clear filters to see everything.',
    'Thu tháng này': 'Income this month',
    'Chi tháng này': 'Expense this month',
    "Chạm nút '+' giữa thanh dưới để ghi giao dịch đầu tiên.":
        "Tap the '+' button in the bottom bar to record your first transaction.",

    // Giao dịch — màn thêm giao dịch
    'Không đọc được danh sách ví.': 'Could not read the wallet list.',
    'Chưa có ví hoạt động để chuyển tiền.':
        'No active wallet to transfer money from.',
    'Không lưu được giao dịch. Vui lòng thử lại.':
        'Could not save the transaction. Please try again.',
    'Hủy giao dịch?': 'Discard transaction?',
    'Dữ liệu đã nhập sẽ bị mất.': 'Your entered data will be lost.',
    'Hủy': 'Cancel',
    'Thoát': 'Exit',
    'Thêm giao dịch': 'Add transaction',
    'Sửa giao dịch': 'Edit transaction',
    'Không mở được màn sửa giao dịch.': 'Could not open the edit screen.',
    'Sửa chuyển khoản': 'Edit transfer',
    'Hủy sửa chuyển khoản?': 'Discard transfer changes?',
    'Dữ liệu đã sửa sẽ bị mất.': 'Your edits will be lost.',
    'Lưu giao dịch': 'Save transaction',
    'Chọn danh mục': 'Select category',
    'Chưa chọn danh mục': 'Please select a category',
    'Chưa chọn ví': 'Please select a wallet',
    'Chưa chọn ngày giờ': 'Please select date & time',
    'Ví': 'Wallet',
    'Chi': 'Expense',
    'Thu': 'Income',
    'Chuyển khoản': 'Transfer',
    'Chưa có ví hoạt động — hãy tạo ví trong Quản lý ví.':
        'No active wallet — create one in Manage wallets.',
    'Thêm ghi chú (tùy chọn)': 'Add a note (optional)',
    // Tag & Ảnh hóa đơn — màn Thêm giao dịch (PBI 38)
    'Thêm tag (tùy chọn)': 'Add tags (optional)',
    'Chọn tag': 'Select tags',
    'Tạo tag mới': 'Create new tag',
    'Xác nhận': 'Confirm',
    'Chưa có tag nào — tạo tag mới ở ô trên.':
        'No tags yet — create one in the field above.',
    'Đính kèm ảnh (tùy chọn)': 'Attach a photo (optional)',
    'Đã đính kèm': 'Attached',
    'Chọn từ thư viện': 'Choose from library',

    // Giao dịch — chi tiết & danh sách domain
    'Chi tiết giao dịch': 'Transaction details',
    'Không tìm thấy giao dịch.': 'Transaction not found.',
    'Ví nguồn': 'Source wallet',
    'Ví đích': 'Destination wallet',
    'Nhân bản': 'Duplicate',
    'Sửa': 'Edit',
    'Ảnh hóa đơn': 'Receipt',
    'Vị trí': 'Location',
    'Tag': 'Tag',
    'Điều chỉnh số dư': 'Balance adjustment',

    // Giao dịch — màn tìm kiếm & lọc
    'Không đọc được dữ liệu.': 'Could not read data.',
    'Tìm kiếm giao dịch...': 'Search transactions...',
    'BỘ LỌC NÂNG CAO': 'ADVANCED FILTERS',
    'Khoảng thời gian': 'Date range',
    'Sắp xếp theo': 'Sort by',
    'Khoảng số tiền': 'Amount range',
    'Số tiền tối thiểu không được lớn hơn tối đa':
        'Minimum amount cannot be greater than the maximum',
    'Số tiền tối thiểu': 'Minimum amount',
    'Số tiền tối đa': 'Maximum amount',
    'Xóa giới hạn': 'Clear limit',
    'Không áp dụng cho Chuyển khoản': 'Not applicable to transfers',
    'Toàn bộ': 'All',
    'Tất cả các ví': 'All wallets',
    'Từ': 'From',
    'Đến': 'To',
    'Thêm': 'Add',
    'Đặt lại': 'Reset',
    'Áp dụng': 'Apply',
    'Xong': 'Done',
    '@name (gồm con)': '@name (includes children)',

    // Giao dịch — nhãn bộ lọc (core/transaction/transaction_filter.dart)
    'Tất cả': 'All',
    'Ngày mới nhất': 'Newest first',
    'Ngày cũ nhất': 'Oldest first',
    'Số tiền tăng dần': 'Amount: low to high',
    'Số tiền giảm dần': 'Amount: high to low',
    'Tuần này': 'This week',
    'Tháng này': 'This month',
    'Tùy chọn': 'Custom',
    'Hôm nay': 'Today',
    'Hôm qua': 'Yesterday',
    'HÔM NAY': 'TODAY',
    'HÔM QUA': 'YESTERDAY',

    // ---------------------------------------------------------------------
    // Danh mục (nhãn tĩnh — tên danh mục xem nhóm "Tên danh mục mặc định")
    // ---------------------------------------------------------------------
    'Không đọc được danh mục.': 'Could not read categories.',
    'Sắp xếp': 'Sort',
    'Đã ẩn': 'Hidden',
    'Thêm danh mục': 'Add category',
    'Chi tiêu': 'Expense',
    'Thu nhập': 'Income',
    'chi tiêu': 'expense',
    'thu nhập': 'income',
    'Chưa có danh mục @loại nào.': 'No @loại categories yet.',
    'Bạn có thể thêm mới bằng nút "+" góc dưới.':
        'You can add one with the "+" button at the bottom.',
    '@n danh mục con': '@n subcategories',
    'Chọn danh mục cha': 'Select parent category',
    'Không có — là danh mục gốc': 'None — top-level category',
    'Không lưu được danh mục. Vui lòng thử lại.':
        'Could not save the category. Please try again.',
    'Sửa danh mục': 'Edit category',
    'Lưu': 'Save',
    'Lưu danh mục': 'Save category',
    'Tên danh mục': 'Category name',
    'VD: Ăn sáng, Xăng xe…': 'e.g. Breakfast, Fuel…',
    'Biểu tượng': 'Icon',
    'Màu sắc': 'Color',
    'Loại danh mục': 'Category type',
    'Danh mục cha (tùy chọn)': 'Parent category (optional)',
    'Ẩn khỏi danh sách nhanh': 'Hide from quick list',
    'Vẫn giữ trên giao dịch lịch sử và màn danh mục.':
        'Still kept on past transactions and in the Categories screen.',
    'Tên danh mục không được để trống': 'Category name cannot be empty',
    'Tên danh mục đã tồn tại trong nhóm này':
        'Category name already exists in this group',
    'Danh mục con': 'Subcategory',
    'Thêm danh mục con': 'Add subcategory',
    'Chưa có danh mục con nào.': 'No subcategories yet.',
    'Thêm bằng nút "+" góc phải hoặc hàng bên dưới.':
        'Add one with the "+" button at the top right or the row below.',
    'Sắp xếp danh mục': 'Sort categories',
    'Không có danh mục @loại nào để sắp xếp.': 'No @loại categories to sort.',
    'Chưa có danh mục cho loại này.': 'No categories for this type yet.',
    'Bạn có thể thêm mới từ màn danh mục.':
        'You can add one from the Categories screen.',
    'Thêm mới': 'Add new',
    'DANH MỤC CON: @tên': 'SUBCATEGORIES: @tên',

    // ---------------------------------------------------------------------
    // Ngân sách (PBI 20) — màn Tổng quan `01`, màn Thêm/Sửa `02`, chu kỳ &
    // thông báo lỗi ở `core/budget` (gọi `.tr` qua biến nên test quét không bắt)
    // ---------------------------------------------------------------------
    'Ngân sách': 'Budgets',
    'Giới hạn chi tiêu theo danh mục': 'Spending limits by category',
    'Tuần': 'Week',
    'Tháng': 'Month',
    'Năm': 'Year',
    'Tháng @tháng, @năm': '@tháng/@năm',
    'Tổng ngân sách tháng này': "This month's total budget",
    'Còn lại @số đ': '@số đ remaining',
    '@n ngày còn lại': '@n days left',
    'DANH MỤC': 'CATEGORIES',
    'Sao chép tháng trước': 'Copy last month',
    'Đã kết thúc': 'Ended',
    'Danh mục đã bị xóa': 'Category deleted',
    'Không đọc được ngân sách.': 'Could not read budgets.',
    'Chưa có ngân sách nào.': 'No budgets yet.',
    'Đặt giới hạn chi tiêu cho một danh mục để theo dõi tiến độ.':
        'Set a spending limit for a category to track progress.',
    'Thêm ngân sách': 'Add budget',
    'Sửa ngân sách': 'Edit budget',
    'Lưu ngân sách': 'Save budget',
    'PHẠM VI NGÂN SÁCH': 'BUDGET SCOPE',
    'Theo danh mục': 'By category',
    'Tổng cộng': 'Overall',
    'SỐ TIỀN GIỚI HẠN': 'LIMIT AMOUNT',
    'CHU KỲ': 'PERIOD',
    'Ví áp dụng': 'Applies to wallets',
    'Tất cả ví': 'All wallets',
    'Lặp lại tự động mỗi kỳ': 'Auto-repeat every period',
    'Cộng dồn phần chưa dùng hết': 'Roll over unused amount',
    'Ngưỡng cảnh báo': 'Alert thresholds',
    '80% và 100%': '80% and 100%',
    'Vui lòng chọn danh mục.': 'Please select a category.',
    'Vui lòng nhập số tiền lớn hơn 0.':
        'Please enter an amount greater than 0.',
    'Đã có ngân sách cho danh mục này trong kỳ. Hãy sửa ngân sách đang có.':
        'A budget already exists for this category in this period. Please edit the existing budget.',
    'Không lưu được ngân sách. Vui lòng thử lại.':
        'Could not save the budget. Please try again.',

    // ---------------------------------------------------------------------
    // Ngân sách (PBI 21) — màn Chi tiết `03`
    // ---------------------------------------------------------------------
    'Ngân sách tháng • @kỳ': 'Monthly budget • @kỳ',
    'Ngân sách tuần • @kỳ': 'Weekly budget • @kỳ',
    'Ngân sách năm • @kỳ': 'Yearly budget • @kỳ',
    'Tuần @từ – @đến': '@từ – @đến',
    '@tháng, @năm': '@tháng/@năm',
    'Năm @năm': '@năm',
    'Đã dùng': 'Used',
    'Trạng thái': 'Status',
    'trên @số đ giới hạn': 'of @số đ limit',
    'Bình thường @p%': 'Normal @p%',
    'Sắp đạt @p%': 'Almost @p%',
    'Vượt @p%': 'Over @p%',
    'Vượt @số đ': 'Over @số đ',
    'Tốc độ chi tiêu nhanh hơn dự kiến': 'Spending faster than planned',
    'Đã dùng @p% ngày nhưng chi @q% ngân sách':
        '@p% of days passed but @q% of budget spent',
    'GIAO DỊCH TRONG KỲ': 'TRANSACTIONS IN PERIOD',
    'Tổng số dư': 'Total balance',
    'Giao dịch gần đây': 'Recent transactions',
    'Xem tất cả': 'See all',
    'Chưa có giao dịch Chi nào trong kỳ.': 'No expenses in this period.',
    'Chi tiêu thuộc danh mục này sẽ hiện tại đây.':
        'Spending in this category will show up here.',
    'Danh mục của ngân sách đã bị xóa.': "This budget's category was deleted.",
    'Chạm "Chỉnh sửa" để gán lại danh mục khác.':
        'Tap "Edit" to assign another category.',
    'Chọn kỳ': 'Select period',
    'Chỉnh sửa': 'Edit',
    'Lưu trữ ngân sách': 'Archive budget',
    'Lưu trữ ngân sách?': 'Archive this budget?',
    'Ngân sách sẽ ngừng theo dõi. Các giao dịch đã ghi vẫn còn nguyên.':
        'The budget stops being tracked. Recorded transactions stay untouched.',
    'Lưu trữ': 'Archive',
    'SO SÁNH DỰ KIẾN • THỰC TẾ': 'PLANNED • ACTUAL',
    'Dự kiến': 'Planned',
    'Thực tế': 'Actual',
    'Dự kiến @số đ': 'Planned @số đ',
    'T@tháng': 'M@tháng',
    '@ngày/@tháng': '@ngày/@tháng',
    '@năm': '@năm',

    // ---------------------------------------------------------------------
    // Báo cáo (PBI 22) — màn Tổng quan `01`
    // ---------------------------------------------------------------------
    'Ngày': 'Day',
    'Tổng thu': 'Total income',
    'Tổng chi': 'Total expense',
    'Dòng tiền 6 ngày gần đây': 'Cash flow, last 6 days',
    'Dòng tiền 6 tuần gần đây': 'Cash flow, last 6 weeks',
    'Dòng tiền 6 tháng gần đây': 'Cash flow, last 6 months',
    'Dòng tiền 6 năm gần đây': 'Cash flow, last 6 years',
    'Phân bổ chi tiêu theo danh mục': 'Spending by category',
    'Top danh mục chi tiêu': 'Top spending categories',
    'Chưa có giao dịch nào trong kỳ này': 'No transactions in this period',
    'Chưa có chi tiêu nào trong kỳ này': 'No spending in this period',
    'Không đọc được dữ liệu báo cáo.': 'Could not read report data.',

    // ---------------------------------------------------------------------
    // Báo cáo (PBI 23) — màn Chi tiết `02`
    // ---------------------------------------------------------------------
    'Chi tiêu theo danh mục': 'Spending by category',
    'DANH MỤC (@n)': 'CATEGORIES (@n)',
    'Tổng chi ngày': 'Day total',
    'Tổng chi tuần': 'Week total',
    'Tổng chi tháng': 'Month total',
    'Tổng chi năm': 'Year total',
    'Chạm vào một danh mục để xem các giao dịch':
        'Tap a category to see its transactions',

    // ---------------------------------------------------------------------
    // Báo cáo (PBI 26) — màn So sánh kỳ `03`
    // ---------------------------------------------------------------------
    'So sánh kỳ': 'Compare periods',
    'So sánh': 'Compare',
    'Xu hướng chi tiêu theo ngày': 'Daily spending trend',
    'Nhận xét': 'Insight',
    'Kỳ đối chiếu không có dữ liệu để so sánh':
        'The reference period has no data to compare',
    'Chưa có giao dịch nào trong hai kỳ này':
        'No transactions in either period',
    'Chưa có dữ liệu để so sánh': 'No data to compare yet',
    'Hai kỳ đều chưa có chi tiêu.': 'Neither period has spending yet.',
    'Kỳ này bạn chi @amount, kỳ đối chiếu chưa có chi tiêu để so sánh.':
        'You spent @amount this period; the reference period has no spending to compare.',
    'Bạn chi nhiều hơn @ref @percent%.': 'You spent @percent% more than @ref.',
    'Bạn chi ít hơn @ref @percent%.': 'You spent @percent% less than @ref.',
    'Bạn chi tiêu bằng @ref.': 'Your spending matches @ref.',
    ' Chủ yếu do danh mục @category tăng mạnh.':
        ' Mostly driven by a sharp rise in @category.',
    'kỳ trước': 'the previous period',
    'kỳ sau': 'the following period',

    // ---------------------------------------------------------------------
    // Báo cáo (PBI 27) — màn Xuất báo cáo `04`
    // ---------------------------------------------------------------------
    'Xuất báo cáo': 'Export report',
    'Xuất': 'Export',
    'KHOẢNG THỜI GIAN': 'TIME RANGE',
    'Từ ngày': 'From',
    'Đến ngày': 'To',
    'VÍ': 'WALLETS',
    'TAG': 'TAG',
    'Nhập tag để lọc (VD: #dulich)': 'Enter a tag to filter (e.g. #travel)',
    'ĐỊNH DẠNG XUẤT': 'EXPORT FORMAT',
    'Có biểu đồ': 'With charts',
    'Bảng dữ liệu': 'Spreadsheet',
    'Dữ liệu thô': 'Raw data',
    '@count giao dịch • @from – @to': '@count transactions • @from – @to',
    '@from – @to': '@from – @to',
    'Định dạng: @format (@hint)': 'Format: @format (@hint)',
    '@count khác': '@count more',
    'Bộ lọc hiện không có giao dịch nào':
        'No transactions match the current filters',
    'Tệp xuất ra không còn được app bảo vệ. Hãy cẩn thận khi chia sẻ.':
        'Exported files are no longer protected by the app. Share with care.',
    'Đang tạo tệp…': 'Creating file…',
    'Đã tạo tệp': 'File created',
    'Không tạo được tệp báo cáo': 'Could not create the report file',
    'Không đọc được dữ liệu để xuất báo cáo':
        'Could not read data to export the report',
    'Báo cáo thu chi': 'Income & expense report',
    'Chênh lệch': 'Difference',
    'Danh sách giao dịch': 'Transactions',
    'Tổng hợp': 'Summary',
    'Phân bổ chi theo danh mục': 'Spending by category',
    'Dòng tiền': 'Cash flow',
    'Số tiền': 'Amount',
    'Loại': 'Type',

    // ---------------------------------------------------------------------
    // Bảo mật PIN & khung Tổng quan/Báo cáo
    // ---------------------------------------------------------------------
    'Nhập lại mã PIN': 'Re-enter PIN',
    'Thiết lập mã PIN': 'Set up PIN',
    'Nhập lại mã PIN lần hai để xác nhận': 'Re-enter your PIN to confirm',
    'Tạo mã PIN 4 số để bảo vệ dữ liệu':
        'Create a 4-digit PIN to protect your data',
    'Mã PIN không khớp. Vui lòng thử lại.':
        "PINs don't match. Please try again.",
    'Mã PIN này dễ đoán. Vẫn dùng mã PIN này?':
        'This PIN is easy to guess. Use it anyway?',
    'Tiếp tục': 'Continue',
    'Nhập mã PIN': 'Enter PIN',
    'Mã PIN không đúng': 'Incorrect PIN',
    'Mở khóa Sora Thu Chi': 'Unlock Sora Thu Chi',
    'Nhiều lần nhập sai. Thử lại sau @giây giây.':
        'Too many failed attempts. Try again in @giây seconds.',

    // ---------------------------------------------------------------------
    // Quét hóa đơn (PBI 24) — sheet `scan-01`, chụp `scan-02`, xử lý `scan-03`,
    // xác nhận `scan-04`, kiểm tra cấu hình `scan-10`, Cài đặt `scan-11`
    // ---------------------------------------------------------------------
    // Sheet "Thêm giao dịch"
    'Khoản Thu': 'Income',
    'Lương, thưởng, thu nhập khác': 'Salary, bonus, other income',
    'Khoản Chi': 'Expense',
    'Ăn uống, mua sắm, hóa đơn...': 'Food, shopping, bills...',
    'Giữa các ví/tài khoản': 'Between wallets/accounts',
    'Quét hóa đơn (AI)': 'Scan receipt (AI)',
    'Tự động đọc số tiền, ngày, cửa hàng':
        'Automatically reads amount, date, merchant',
    'MỚI': 'NEW',

    // Màn chụp `scan-02`
    'Quét hóa đơn': 'Scan receipt',
    'Đặt hóa đơn vừa khung, tránh bóng đổ':
        'Fit the receipt in the frame, avoid shadows',
    'Thư viện': 'Library',
    'Chụp ảnh': 'Take photo',
    'Bật/tắt đèn flash': 'Toggle flash',
    'Không mở được camera. Bạn vẫn có thể chọn ảnh từ thư viện.':
        'Could not open the camera. You can still pick a photo from your library.',
    'Không chụp được ảnh. Vui lòng thử lại.':
        'Could not take the photo. Please try again.',

    // Màn xử lý `scan-03`
    'Đang xử lý hóa đơn...': 'Processing receipt...',
    'Toàn bộ xử lý diễn ra ngay trên máy của bạn':
        'All processing happens right on your device',
    'Đọc & xử lý ảnh hóa đơn': 'Read & prepare the receipt image',
    'Nhận diện chữ (OCR on-device)': 'Text recognition (on-device OCR)',
    'Phân tích số tiền, ngày, danh mục': 'Analyse amount, date, category',
    'Chuẩn bị màn hình xác nhận': 'Prepare the confirmation screen',
    'Không gửi dữ liệu lên bất kỳ máy chủ nào': 'No data is sent to any server',
    'Không nhận diện được nội dung hóa đơn. Vui lòng chụp lại hoặc nhập tay.':
        'Could not read the receipt. Please retake the photo or enter it manually.',
    'Chụp lại': 'Retake',
    'Nhập tay': 'Enter manually',

    // Màn xác nhận `scan-04`
    'Xác nhận hóa đơn': 'Confirm receipt',
    'Xem ảnh gốc': 'View original',
    'Chạm vào 1 trường bên dưới để khoanh vùng đối chiếu trên ảnh':
        'Tap a field below to highlight it on the image',
    'LOẠI GIAO DỊCH': 'TRANSACTION TYPE',
    'SỐ TIỀN': 'AMOUNT',
    'NGÀY GIỜ': 'DATE & TIME',
    'CỬA HÀNG / GHI CHÚ': 'MERCHANT / NOTE',
    'Tên cửa hàng': 'Merchant name',
    'DANH MỤC GỢI Ý': 'SUGGESTED CATEGORY',
    'VÍ ÁP DỤNG': 'WALLET',
    'Đang tải...': 'Loading...',
    'Nguồn: Quét hóa đơn (AI) • xử lý hoàn toàn trên máy':
        'Source: AI receipt scan • processed entirely on device',
    'Kiểm tra lại': 'Review',
    'Độ tin cậy cao': 'High confidence',
    'Độ tin cậy trung bình': 'Medium confidence',
    'Có thể trùng với giao dịch đã nhập. Bạn vẫn có thể lưu.':
        'This may duplicate an existing transaction. You can still save it.',
    'Vui lòng chọn ví trước khi lưu.': 'Please choose a wallet before saving.',

    // Màn kiểm tra cấu hình `scan-10`
    'Kiểm tra cấu hình máy': 'Check device capability',
    'ĐANG KIỂM TRA': 'CHECKING',
    'Bộ nhớ RAM': 'RAM',
    'Dung lượng trống': 'Free storage',
    'Hỗ trợ AI trên máy (AICore)': 'On-device AI (AICore)',
    'Phiên bản hệ điều hành': 'OS version',
    'Đạt': 'Pass',
    'Không đạt': 'Fail',
    'Có': 'Yes',
    'Không': 'No',
    'Đủ điều kiện — Tier A': 'Eligible — Tier A',
    'Dùng ngay Gemini Nano': 'Use Gemini Nano now',
    'Model do hệ thống Android quản lý — không cần tải thêm, sẵn sàng dùng ngay.':
        'The model is managed by Android — nothing to download, ready to use.',
    'Kích hoạt Gemini Nano': 'Activate Gemini Nano',
    'Gemini Nano không tốt? Dùng Gemma 4 (Tier B) thay thế':
        'Gemini Nano not working well? Use Gemma 4 (Tier B) instead',
    'Đủ điều kiện dùng Gemma 4 E2B': 'Eligible for Gemma 4 E2B',
    'Cần tải model khoảng 3GB qua Wifi':
        'Needs a ~3GB model download over Wifi',
    'Tải model (3GB)': 'Download model (3GB)',
    'Chưa đủ điều kiện dùng AI nâng cao': 'Not eligible for advanced AI',
    'Bạn vẫn dùng được ở Chế độ cơ bản': 'You can still use Basic mode',
    'Dùng chế độ cơ bản': 'Use Basic mode',
    'Hỗ trợ AI trên máy — Không': 'On-device AI — No',
    'Chip không hỗ trợ tăng tốc AI': 'Chip does not support AI acceleration',
    'RAM @gb GB — cần tối thiểu 4 GB': 'RAM @gb GB — 4 GB required',
    'Dung lượng trống @gb GB — cần tối thiểu 2 GB':
        'Free storage @gb GB — 2 GB required',
    'Đang tải model... @percent%': 'Downloading model... @percent%',
    'Tải model thất bại. Bạn vẫn dùng được Chế độ cơ bản.':
        'Model download failed. You can still use Basic mode.',

    // Mục Cài đặt `scan-11`
    'QUÉT HÓA ĐƠN AI': 'AI RECEIPT SCAN',
    'Quét hóa đơn bằng AI': 'AI receipt scan',
    'Trạng thái AI': 'AI status',
    'Chế độ cơ bản': 'Basic mode',
    'Chế độ cơ bản (Tier C)': 'Basic mode (Tier C)',
    'Lần kiểm tra gần nhất': 'Last checked',
    'Chưa kiểm tra': 'Not checked yet',
    'Không xác định': 'Unknown',
    'Kiểm tra lại cấu hình máy': 'Check device capability again',
    'Dung lượng model': 'Model size',
    'Xoá model': 'Delete model',
    'Kiểm tra cập nhật model': 'Check for model update',
    'Đã xoá model': 'Model deleted',

    // ---------------------------------------------------------------------
    // Thông báo & nhắc nhở (PBI 28) — hàng điểm vào màn Cài đặt + màn cấu hình
    // 5 nhóm/8 hàng. Giờ/số/% giữ nguyên định dạng (không dịch — FR-015).
    // ---------------------------------------------------------------------
    'Thông báo & nhắc nhở': 'Notifications & reminders',
    'NHẮC NHỞ HÀNG NGÀY': 'DAILY REMINDER',
    'NGÂN SÁCH': 'BUDGET',
    'GIAO DỊCH ĐỊNH KỲ': 'RECURRING TRANSACTIONS',
    'MỤC TIÊU TIẾT KIỆM': 'SAVINGS GOALS',
    'TỔNG KẾT TỰ ĐỘNG': 'AUTOMATIC SUMMARIES',
    'Nhắc nhập giao dịch hằng ngày': 'Daily transaction reminder',
    'Cảnh báo vượt ngân sách': 'Budget overspend alert',
    // 'Ngưỡng cảnh báo' đã có ở nhóm Ngân sách (PBI 21) — tái dùng, không thêm.
    'Nhắc hóa đơn sắp đến hạn': 'Upcoming bill reminder',
    'Nhắc trước': 'Remind ahead',
    'Nhắc đóng góp mục tiêu': 'Goal contribution reminder',
    'Tổng kết cuối tuần': 'Weekly summary',
    'Tổng kết cuối tháng': 'Monthly summary',
    '@giờ mỗi ngày': 'Every day at @giờ',
    ' · chỉ nhắc nếu chưa ghi': ' · only if nothing logged yet',
    'Khi đạt @sớm% và khi vượt @vượt%':
        'When reaching @sớm% and when over @vượt%',
    'Sớm: @sớm% · Vượt mức: @vượt%': 'Early: @sớm% · Over: @vượt%',
    'Tiền điện, tiền nhà, trả nợ...': 'Electricity, rent, loan payments...',
    '@n ngày trước hạn thanh toán': '@n days before the due date',
    'Theo chu kỳ đã đặt cho từng mục tiêu':
        'Follows the schedule set for each goal',
    'Chủ nhật hằng tuần, @giờ': 'Every Sunday, @giờ',
    'Ngày cuối tháng, @giờ': 'Last day of the month, @giờ',

    // ---------------------------------------------------------------------
    // Cấu hình nhắc nhập giao dịch hằng ngày (PBI 29) — màn `02`. Nhãn ngày
    // T2…CN viết literal trước `.tr` trong `date_label.dart`; giờ `HH:mm`,
    // dấu `:`/`–`, tên app "Sora Thu Chi" **không** dịch (FR-015).
    // ---------------------------------------------------------------------
    'T2': 'Mon',
    'T3': 'Tue',
    'T4': 'Wed',
    'T5': 'Thu',
    'T6': 'Fri',
    'T7': 'Sat',
    'CN': 'Sun',
    'Nhắc nhập giao dịch': 'Transaction reminder',
    '@giờ vào @ngày': 'At @giờ on @ngày',
    'THỜI GIAN NHẮC': 'REMINDER TIME',
    'LẶP LẠI VÀO CÁC NGÀY': 'REPEAT ON DAYS',
    'Chỉ nhắc nếu chưa ghi giao dịch': 'Only remind if nothing is logged',
    'Bỏ qua nhắc nhở nếu hôm nay bạn đã nhập':
        'Skip the reminder if you already logged today',
    'XEM TRƯỚC THÔNG BÁO': 'NOTIFICATION PREVIEW',
    'Đừng quên ghi lại thu chi hôm nay nhé!':
        "Don't forget to log today's income and expenses!",
    'Lưu thay đổi': 'Save changes',

    // ---------------------------------------------------------------------
    // Trung tâm thông báo (PBI 30) — màn `03` + chuông màn Tổng quan. Nội dung
    // thông báo đã lưu (`title`/`body`) là **snapshot**, KHÔNG dịch lại
    // (FR-014) ⇒ không có khoá nào ở đây dành cho chúng. Giờ `HH:mm`, ngày
    // `dd/MM`, dấu `:`/`·` không dịch. Tái dùng 'Tất cả', 'HÔM NAY', 'Thử lại',
    // 'Thông báo & nhắc nhở' — không thêm lại.
    // ---------------------------------------------------------------------
    'Thông báo': 'Notifications',
    'Chưa đọc': 'Unread',
    'TUẦN NÀY': 'THIS WEEK',
    'TRƯỚC ĐÓ': 'EARLIER',
    'Chưa có thông báo nào': 'No notifications yet',
    'Thông báo và nhắc nhở sẽ hiện ở đây.':
        'Notifications and reminders will show up here.',
    'Không có thông báo chưa đọc': 'No unread notifications',
    'Bạn đã đọc hết thông báo.': 'You have read every notification.',
    'Không đọc được thông báo.': 'Could not read notifications.',
    'Mở cài đặt thông báo': 'Open notification settings',
    'Thứ Hai': 'Monday',
    'Thứ Ba': 'Tuesday',
    'Thứ Tư': 'Wednesday',
    'Thứ Năm': 'Thursday',
    'Thứ Sáu': 'Friday',
    'Thứ Bảy': 'Saturday',
    'Chủ Nhật': 'Sunday',

    // ---------------------------------------------------------------------
    // Câu chữ thông báo đẩy (PBI 31) — engine sinh lúc bắn theo ngôn ngữ hiện
    // hành rồi LƯU NGUYÊN VĂN (snapshot, FR-027). Tên app "Sora Thu Chi" và
    // chuỗi số liệu (`82%`, `42.500.000 đ`, `HH:mm`) không dịch. Tái dùng
    // 'Đừng quên ghi lại thu chi hôm nay nhé!' — không thêm lại.
    // ---------------------------------------------------------------------
    'Nhắc ghi chép giao dịch': 'Log your transactions',
    'Bạn chưa ghi giao dịch nào hôm nay.':
        "You haven't logged any transaction today.",
    'tuần @ngày/@tháng': 'week @ngày/@tháng',
    'tháng @tháng': 'month @tháng',
    'năm @năm': 'year @năm',
    'Sắp vượt ngân sách @danh_mục': 'Approaching @danh_mục budget',
    'Đã vượt ngân sách @danh_mục': '@danh_mục budget exceeded',
    'Bạn đã dùng @phần_trăm% ngân sách @kỳ cho danh mục @danh_mục.':
        'You have used @phần_trăm% of your @kỳ budget for @danh_mục.',
    'Tổng kết tuần': 'Weekly summary',
    'Tổng kết tháng': 'Monthly summary',
    'Xem chi tiết báo cáo.': 'See the full report.',

    // ---------------------------------------------------------------------
    // Quyền thông báo ở màn `01` (PBI 31) — soft-ask + dòng trạng thái. Tên app
    // "Sora Thu Chi" trong lời giải thích KHÔNG dịch (N4).
    // ---------------------------------------------------------------------
    'Bật thông báo nhắc nhở?': 'Turn on reminders?',
    'Sora Thu Chi cần quyền thông báo để nhắc bạn ghi chép giao dịch, cảnh báo vượt ngân sách và gửi tổng kết tuần/tháng. Bạn có thể tắt lại bất cứ lúc nào trong Cài đặt.':
        'Sora Thu Chi needs notification permission to remind you to log transactions, warn you about budget overruns, and send weekly/monthly summaries. You can turn it off again anytime in Settings.',
    'Đồng ý': 'Agree',
    'Không đồng ý': 'Not now',
    'Thông báo đang bị tắt trong cài đặt hệ điều hành.':
        'Notifications are turned off in your device settings.',
    'Mở cài đặt': 'Open settings',

    // ---------------------------------------------------------------------
    // Sao lưu & Khôi phục (PBI 35) — màn `01`, sheet `02`/`03`, màn `04`.
    // ---------------------------------------------------------------------
    'Sao lưu & Khôi phục': 'Backup & Restore',
    'Tạo bản sao lưu mới': 'Create a new backup',
    'Chọn file khôi phục': 'Choose a file to restore',
    'File backup từ phiên bản app mới hơn, không tương thích':
        'This backup is from a newer app version and is not compatible',
    'File backup không hợp lệ hoặc đã bị hỏng':
        'The backup file is invalid or corrupted',
    'Không đọc được file backup': 'Could not read the backup file',
    'Sao lưu gần nhất': 'Last backup',
    'Chưa từng sao lưu': 'Never backed up',
    '@wallets ví · @categories danh mục · @transactions giao dịch':
        '@wallets wallets · @categories categories · @transactions transactions',
    'Tự động sao lưu': 'Automatic backup',
    'Hàng ngày': 'Daily',
    'Hàng tuần': 'Weekly',
    'Hàng tháng': 'Monthly',
    'CÁC BẢN SAO LƯU': 'BACKUPS',
    'Chưa có bản sao lưu nào': 'No backups yet',
    'Tự động': 'Auto',
    'Tạo bản sao lưu': 'Create backup',
    'Đặt mật khẩu bảo vệ file': 'Protect file with a password',
    'Nhập mật khẩu': 'Enter password',
    'Không tạo được file sao lưu': 'Could not create the backup file',
    'Tạo & Chia sẻ': 'Create & Share',
    'Xác nhận khôi phục': 'Confirm restore',
    'File này được bảo vệ bằng mật khẩu. Nhập mật khẩu để xem trước khi khôi phục.':
        'This file is password-protected. Enter the password to preview it before restoring.',
    'Xác nhận mật khẩu': 'Confirm password',
    'Sai mật khẩu, vui lòng thử lại': 'Wrong password, please try again',
    'Không đọc được file': 'Could not read the file',
    'Dữ liệu hiện tại trên máy sẽ bị ghi đè hoàn toàn và không thể hoàn tác.':
        'Your current data will be completely overwritten and cannot be undone.',
    'Tôi hiểu và muốn tiếp tục': 'I understand and want to continue',
    'Khôi phục dữ liệu': 'Restore data',
    'Khôi phục thất bại, vui lòng thử lại':
        'Restore failed, please try again',
    'Đã tạo bản sao lưu': 'Backup created',
    'Khôi phục dữ liệu thành công': 'Data restored successfully',
    'Bạn có thể lưu file này ở nơi an toàn.':
        'You can save this file somewhere safe.',
    'Dữ liệu trên máy đã được cập nhật theo file đã chọn.':
        'Your data has been updated to match the selected file.',
    'Chia sẻ lại file': 'Share file again',
    'Về Tổng quan': 'Back to Overview',
  };
}
