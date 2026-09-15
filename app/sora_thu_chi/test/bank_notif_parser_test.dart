import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/category/category.dart';
import 'package:sora_thu_chi/core/category/category_source.dart';
import 'package:sora_thu_chi/core/scan/bank_notif_parser.dart';
import 'package:sora_thu_chi/core/scan/scan_result.dart';
import 'package:sora_thu_chi/core/transaction/transaction.dart';

List<ScanTextLine> lines(List<String> texts) => [
  for (var i = 0; i < texts.length; i++)
    ScanTextLine(
      text: texts[i],
      rect: ScanRect(left: 0.1, top: 0.05 + i * 0.06, right: 0.9, bottom: 0.1 + i * 0.06),
    ),
];

/// Dựng dòng với chiều cao chỉ định riêng từng dòng (mô phỏng cỡ chữ khác
/// nhau trên app/email — số tiền thường hiển thị to hơn hẳn phần còn lại).
List<ScanTextLine> linesWithHeights(List<(String, double)> entries) {
  var top = 0.02;
  final result = <ScanTextLine>[];
  for (final (text, height) in entries) {
    result.add(
      ScanTextLine(text: text, rect: ScanRect(left: 0.1, top: top, right: 0.9, bottom: top + height)),
    );
    top += height + 0.01;
  }
  return result;
}

final expenseCategories = CategorySource.all
    .where((c) => c.type == CategoryType.expense && !c.isHidden)
    .toList();
final incomeCategories = CategorySource.all
    .where((c) => c.type == CategoryType.income && !c.isHidden)
    .toList();

/// Fixture 1 — SMS biến động số dư, ghi có (thu): dấu `+` ngay trước số tiền
/// cùng dòng với thời gian/ngày; số dư (lớn hơn) không được chọn.
final smsCreditFixture = lines([
  'Kinh Bank: Thong bao bien dong so du tai khoan',
  'TK 1900...1234 + 29.896.000 luc 13:49 12/09/2026',
  'Noi dung: CTY ABC CHUYEN LUONG THANG 9',
  'So du: 38.677.245',
]);

/// Fixture 2 — thông báo app, ghi nợ (chi): nhãn `(Debit)` nằm dòng khác dòng
/// số tiền; số tiền nhận qua từ khoá "So tien" cùng dòng.
final appDebitFixture = lines([
  'MBBank - (Debit) Giao dich thanh toan',
  'So tien: 44.100',
  'Thoi gian: 10/09/2026 09:15',
  'Den: SHOPEE VIETNAM',
  'So du kha dung: 12.540.601',
]);

/// Fixture 3 — email, ghi nợ rõ ràng: dấu `-` và nhãn "Ghi no" cùng dòng số
/// tiền.
final emailDebitFixture = lines([
  'Thong bao giao dich tu Vietcombank',
  'Ghi no: -40.000',
  'Ngay: 08/09/2026',
  'Ma giao dich: GD123456',
  'So du moi: 30.691.405',
]);

/// Fixture 4 — "Chuyển tiền thành công" không có ghi nợ/ghi có rõ ràng ⇒ suy
/// chi theo R4 mục 3 (tin cậy trung bình, không bật cờ xem lại).
final transferSuccessFixture = lines([
  'Chuyen tien thanh cong',
  'Tu tai khoan: 19001234',
  'So tien: 55.000',
  'Den: CONG TY CO PHAN ZION',
  'Noi dung: Thanh toan don hang',
  'Thoi gian: 05/09/2026 14:20',
]);

/// Fixture 5 — ảnh ngân hàng nhưng không đủ căn cứ suy loại GD ⇒ mặc định chi
/// + `typeNeedsReview = true`.
final ambiguousFixture = lines([
  'Ngan hang thong bao giao dich',
  'So tien: 20.000',
  'Ma giao dich: XYZ789',
  'Thoi gian: 01/09/2026',
]);

/// Fixture 6 — ảnh xác nhận chuyển tiền ACB thật (ảnh mẫu người dùng báo lỗi):
/// dòng "Nội dung" chứa mã tham chiếu `CHUYEN KHOAN-150926-08:34:59` — số
/// trần `150926` dính ngay sau dấu `-` từng bị nhận nhầm thành số tiền
/// (đúng phải là `55.000` ở dòng đầu).
final acbTransferFixture = lines([
  'Thong bao thay doi so du ACB: TK 750561(VN...',
  'Chuyen tien thanh cong!',
  '55.000 VND',
  'Nam muoi lam nghin dong',
  'Tu',
  'DUONG BANG HUAN',
  '******61',
  'Den',
  'CONG TY CO PHAN ZION-HLC MIPEC XUAN THUY HN DYNAMIC',
  'VPBank - NH TMCP Viet Nam Thinh Vuong',
  'ZLP26258102452090',
  'Chuyen luc',
  '15/09/2026, 08:35:00',
  'Phi',
  'Mien phi',
  'Ma giao dich',
  '4349',
  'Noi dung',
  'DUONG BANG HUAN CHUYEN KHOAN-150926-08:34:59',
  '6258ASCB02UK171D',
]);

/// Fixture 7 — mã tham chiếu trong "Nội dung" đứng **trước** dòng số tiền
/// thật trong văn bản OCR (không dấu +/-, không từ khoá, không đơn vị đi
/// kèm số tiền) ⇒ rơi vào fallback cuối; phải bỏ qua dòng có giờ:phút thay
/// vì vơ nhầm số trong mã tham chiếu.
final noteBeforeAmountFixture = lines([
  'Ngan hang thong bao giao dich',
  'Ma giao dich: ABC123',
  'Noi dung: CHUYEN KHOAN-150926-08:34:59',
  '45000',
]);

/// Fixture 8 — số tiền hiển thị **cỡ chữ to nổi bật** (như màn xác nhận
/// chuyển tiền của app ngân hàng), trong khi một mã tham chiếu chứa số dễ
/// nhầm đứng **trước** nó trong văn bản OCR, cỡ chữ thường. Không dấu +/-,
/// không đơn vị, không từ khoá đi kèm số tiền — chỉ cỡ chữ phân biệt được.
final visuallyProminentAmountFixture = linesWithHeights([
  ('Ngan hang thong bao giao dich', 0.03),
  ('Ma giao dich: 999888', 0.03),
  ('45.000', 0.09),
  ('Noi dung thanh toan', 0.03),
]);

void main() {
  group('looksLikeBankNotification', () {
    test('dưới 2 từ khoá ⇒ false', () {
      expect(looksLikeBankNotification(lines(['Giao dich thanh cong'])), isFalse);
    });

    test('đủ ≥2 từ khoá ⇒ true', () {
      expect(looksLikeBankNotification(smsCreditFixture), isTrue);
      expect(looksLikeBankNotification(appDebitFixture), isTrue);
      expect(looksLikeBankNotification(emailDebitFixture), isTrue);
      expect(looksLikeBankNotification(transferSuccessFixture), isTrue);
    });

    test('text hóa đơn thường ⇒ false', () {
      final receipt = lines([
        'CIRCLE K VIET NAM',
        'Ca phe sua da 25.000',
        'TONG CONG 55.000',
        '12/09/2026 08:24',
        'DT: 0909123456',
        'MST: 0123456789',
      ]);
      expect(looksLikeBankNotification(receipt), isFalse);
    });
  });

  group('parseBankNotification', () {
    ScanExtraction parse(List<ScanTextLine> input) => parseBankNotification(
      lines: input,
      now: DateTime(2026, 9, 13, 10),
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    );

    test('SMS ghi có ⇒ thu, đúng số tiền giao dịch (khác số dư)', () {
      final result = parse(smsCreditFixture);
      expect(result.type, TxnType.income);
      expect(result.typeNeedsReview, isFalse);
      expect(result.amount.value, 29896000);
      expect(result.date.value, DateTime(2026, 9, 12, 13, 49));
      expect(result.merchant.value, 'CTY ABC CHUYEN LUONG THANG 9');
    });

    test('App (Debit) ⇒ chi, đúng số tiền giao dịch (khác số dư khả dụng)', () {
      final result = parse(appDebitFixture);
      expect(result.type, TxnType.expense);
      expect(result.typeNeedsReview, isFalse);
      expect(result.amount.value, 44100);
      expect(result.date.value, DateTime(2026, 9, 10, 9, 15));
      expect(result.merchant.value, 'SHOPEE VIETNAM');
    });

    test('Email "Ghi nợ" ⇒ chi, đúng số tiền giao dịch (khác số dư mới)', () {
      final result = parse(emailDebitFixture);
      expect(result.type, TxnType.expense);
      expect(result.typeNeedsReview, isFalse);
      expect(result.amount.value, 40000);
      expect(result.date.value, DateTime(2026, 9, 8));
    });

    test('"Chuyển tiền thành công" không rõ ghi nợ/có ⇒ chi, không bật cờ xem lại', () {
      final result = parse(transferSuccessFixture);
      expect(result.type, TxnType.expense);
      expect(result.typeNeedsReview, isFalse);
      expect(result.amount.value, 55000);
      expect(result.merchant.value, 'CONG TY CO PHAN ZION');
    });

    test('không đủ căn cứ ⇒ mặc định chi + typeNeedsReview = true', () {
      final result = parse(ambiguousFixture);
      expect(result.type, TxnType.expense);
      expect(result.typeNeedsReview, isTrue);
      expect(result.amount.value, 20000);
    });

    test(
        'ảnh xác nhận chuyển tiền ACB thật: mã tham chiếu "-150926-" trong '
        'Nội dung và số tài khoản "750561" trong banner không bị nhận nhầm '
        'thành số tiền — số có đơn vị "VND" thắng',
        () {
      final result = parse(acbTransferFixture);
      expect(result.amount.value, 55000);
      expect(result.type, TxnType.expense);
    });

    test(
        'mã tham chiếu "Nội dung" đứng trước dòng số tiền thật (fallback) '
        '⇒ vẫn lấy đúng 45000, không lấy 150926 dính trong mã',
        () {
      final result = parse(noteBeforeAmountFixture);
      expect(result.amount.value, 45000);
    });

    test(
        'số tiền cỡ chữ nổi bật thắng mã tham chiếu đứng trước (dù không '
        'dấu/đơn vị/từ khoá) ⇒ đúng 45.000, không lấy 999888',
        () {
      final result = parse(visuallyProminentAmountFixture);
      expect(result.amount.value, 45000);
    });

    test('không bao giờ trả transfer/adjustment (FR-004)', () {
      for (final fixture in [
        smsCreditFixture,
        appDebitFixture,
        emailDebitFixture,
        transferSuccessFixture,
        ambiguousFixture,
        acbTransferFixture,
        noteBeforeAmountFixture,
      ]) {
        final result = parse(fixture);
        expect(result.type, isNot(TxnType.transfer));
        expect(result.type, isNot(TxnType.adjustment));
      }
    });
  });
}
