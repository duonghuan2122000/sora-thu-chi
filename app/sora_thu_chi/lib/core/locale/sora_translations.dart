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
    // Bảo mật PIN & khung Tổng quan/Báo cáo
    // ---------------------------------------------------------------------
    'Nhập lại mã PIN': 'Re-enter PIN',
    'Thiết lập mã PIN': 'Set up PIN',
    'Nhập lại mã PIN lần hai để xác nhận': 'Re-enter your PIN to confirm',
    'Tạo mã PIN 4 số để bảo vệ dữ liệu':
        'Create a 4-digit PIN to protect your data',
    'Mã PIN không khớp. Vui lòng thử lại.': "PINs don't match. Please try again.",
    'Mã PIN này dễ đoán. Vẫn dùng mã PIN này?':
        'This PIN is easy to guess. Use it anyway?',
    'Tiếp tục': 'Continue',
    'Nhập mã PIN': 'Enter PIN',
    'Mã PIN không đúng': 'Incorrect PIN',
    'Mở khóa Sora Thu Chi': 'Unlock Sora Thu Chi',
    'Nhiều lần nhập sai. Thử lại sau @giây giây.':
        'Too many failed attempts. Try again in @giây seconds.',
  };
}
