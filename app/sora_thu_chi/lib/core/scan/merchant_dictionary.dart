import '../category/category.dart';

/// Bỏ dấu tiếng Việt + thường hoá + gộp khoảng trắng — dùng để khớp từ khoá
/// (OCR có thể trả thiếu dấu, rủi ro 3). Thuần, không phụ thuộc gì.
String stripDiacritics(String input) {
  final buffer = StringBuffer();
  for (final ch in input.toLowerCase().split('')) {
    buffer.write(_diacriticMap[ch] ?? ch);
  }
  return buffer.toString();
}

/// Chuỗi đã chuẩn hoá để so khớp: bỏ dấu, thường, gộp khoảng trắng.
String normalizeForMatch(String input) =>
    stripDiacritics(input).replaceAll(RegExp(r'\s+'), ' ').trim();

const Map<String, String> _diacriticMap = {
  'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
  'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
  'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
  'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
  'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
  'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
  'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
  'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
  'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
  'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
  'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
  'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
  'đ': 'd',
};

/// Từ điển **tĩnh** từ khoá cửa hàng → tên danh mục seed (doc §3.5, FR-024).
/// Khớp theo chuỗi con trên chuỗi đã bỏ dấu; **không** học theo người dùng,
/// **không** tự tạo danh mục. Khoá cụ thể (con cấp 2) đứng trước cha.
const Map<String, String> merchantKeywords = {
  // Cà phê
  'highlands': 'Cà phê',
  'phuc long': 'Cà phê',
  'starbucks': 'Cà phê',
  'katinat': 'Cà phê',
  'gong cha': 'Cà phê',
  'toco toco': 'Cà phê',
  'milano': 'Cà phê',
  'cafe': 'Cà phê',
  'coffee': 'Cà phê',
  // Ăn ngoài
  'kfc': 'Ăn ngoài',
  'lotteria': 'Ăn ngoài',
  'jollibee': 'Ăn ngoài',
  'mcdonald': 'Ăn ngoài',
  'pizza': 'Ăn ngoài',
  'buffet': 'Ăn ngoài',
  'nha hang': 'Ăn ngoài',
  'quan an': 'Ăn ngoài',
  'food court': 'Ăn ngoài',
  // Đi chợ
  'sieu thi': 'Đi chợ',
  'big c': 'Đi chợ',
  'coopmart': 'Đi chợ',
  'winmart': 'Đi chợ',
  'vinmart': 'Đi chợ',
  'bach hoa xanh': 'Đi chợ',
  'lotte mart': 'Đi chợ',
  'mega market': 'Đi chợ',
  'go!': 'Đi chợ',
  // Ăn uống (cha — gồm cửa hàng tiện lợi/bánh mì/quán ăn nhanh)
  'circle k': 'Ăn uống',
  'family mart': 'Ăn uống',
  'gs25': 'Ăn uống',
  'ministop': 'Ăn uống',
  'banh mi': 'Ăn uống',
  'bun ': 'Ăn uống',
  'pho ': 'Ăn uống',
  'com tam': 'Ăn uống',
  'tra sua': 'Ăn uống',
  'quan nuoc': 'Ăn uống',
  // Di chuyển
  'petrolimex': 'Di chuyển',
  'pvoil': 'Di chuyển',
  'shell': 'Di chuyển',
  'xang': 'Di chuyển',
  'grab': 'Di chuyển',
  'be group': 'Di chuyển',
  'xanh sm': 'Di chuyển',
  'taxi': 'Di chuyển',
  'mai linh': 'Di chuyển',
  'vinasun': 'Di chuyển',
  'gui xe': 'Di chuyển',
  've tau': 'Di chuyển',
  'vietjet': 'Di chuyển',
  'vietnam airlines': 'Di chuyển',
  // Nhà ở
  'tien dien': 'Nhà ở',
  'tien nuoc': 'Nhà ở',
  'evn': 'Nhà ở',
  'cap nuoc': 'Nhà ở',
  'phi quan ly': 'Nhà ở',
  'thue nha': 'Nhà ở',
  // Hóa đơn
  'hoa don': 'Hóa đơn',
  'internet': 'Hóa đơn',
  'wifi': 'Hóa đơn',
  'fpt': 'Hóa đơn',
  'viettel': 'Hóa đơn',
  'vnpt': 'Hóa đơn',
  'truyen hinh': 'Hóa đơn',
  'bao hiem': 'Hóa đơn',
  // Mua sắm
  'shopee': 'Mua sắm',
  'lazada': 'Mua sắm',
  'tiki': 'Mua sắm',
  'the gioi di dong': 'Mua sắm',
  'dien may xanh': 'Mua sắm',
  'fpt shop': 'Mua sắm',
  'uniqlo': 'Mua sắm',
  'zara': 'Mua sắm',
  'concung': 'Mua sắm',
  // Giải trí
  'cgv': 'Giải trí',
  'lotte cinema': 'Giải trí',
  'galaxy cinema': 'Giải trí',
  'netflix': 'Giải trí',
  'spotify': 'Giải trí',
  'karaoke': 'Giải trí',
  'steam': 'Giải trí',
  // Sức khỏe
  'nha thuoc': 'Sức khỏe',
  'pharmacy': 'Sức khỏe',
  'benh vien': 'Sức khỏe',
  'phong kham': 'Sức khỏe',
  'long chau': 'Sức khỏe',
  'an khang': 'Sức khỏe',
  'gym': 'Sức khỏe',
  'yoga': 'Sức khỏe',
  // Giáo dục
  'hoc phi': 'Giáo dục',
  'trung tam': 'Giáo dục',
  'nha sach': 'Giáo dục',
  'fahasa': 'Giáo dục',
  'udemy': 'Giáo dục',
  // Thu nhập
  'luong': 'Lương',
  'salary': 'Lương',
  'payroll': 'Lương',
  'thuong': 'Thưởng',
  'bonus': 'Thưởng',
  'hoa hong': 'Thưởng',
  'co phieu': 'Đầu tư',
  'chung khoan': 'Đầu tư',
  'co tuc': 'Đầu tư',
};

/// Tên danh mục gợi ý cho [merchant] — `null` khi không khớp từ khoá nào.
String? suggestCategoryName(String? merchant) {
  if (merchant == null || merchant.trim().isEmpty) return null;
  final haystack = normalizeForMatch(merchant);
  for (final entry in merchantKeywords.entries) {
    if (haystack.contains(entry.key)) return entry.value;
  }
  return null;
}

/// Tra tên gợi ý → [Category] trong danh sách **đang hoạt động** [active].
/// Không có trong danh sách (danh mục ẩn/đã xoá) → `null` — **không** tự tạo
/// danh mục mới và **không** ghi nhớ lựa chọn sửa (FR-024).
Category? resolveCategory(String? name, List<Category> active) {
  if (name == null) return null;
  for (final c in active) {
    if (c.name == name) return c;
  }
  return null;
}
