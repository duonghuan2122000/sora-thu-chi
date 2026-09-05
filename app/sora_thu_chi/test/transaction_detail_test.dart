import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/transaction/transaction.dart';
import 'package:sora_thu_chi/core/transaction/transaction_detail.dart';
import 'package:sora_thu_chi/core/transaction/transaction_list.dart'
    show categoryGlyph;

void main() {
  final now = DateTime(2026, 9, 5, 12, 15);

  Transaction txn(
    int id,
    int walletId,
    TxnType type,
    int amount, {
    DateTime? date,
    String note = '',
    String category = '',
    int? group,
    String tags = '',
    String receiptImage = '',
    String location = '',
  }) => Transaction(
    id: id,
    walletId: walletId,
    type: type,
    amount: amount,
    date: date ?? now,
    note: note,
    category: category,
    transferGroupId: group,
    tags: tags,
    receiptImage: receiptImage,
    location: location,
  );

  const names = {1: 'Tiền mặt', 2: 'Vietcombank', 4: 'Momo'};

  TransactionDetailView? build(
    List<Transaction> all,
    TransactionDetailRef ref, {
    Map<int, String> walletName = const {},
  }) => buildTransactionDetail(all: all, walletName: walletName.isEmpty ? names : walletName, ref: ref);

  group('buildTransactionDetail theo ref.transactionId — view đơn', () {
    test('thu: loại/tiền giữ dấu +, tên danh mục, tên ví (acceptance 2)', () {
      final all = [
        txn(3, 2, TxnType.income, 12000000, category: 'Lương',
            note: 'Lương tháng 8', date: DateTime(2026, 9, 4)),
      ];
      final v = build(all, const TransactionDetailRef(transactionId: 3))!;

      expect(v.type, TxnType.income);
      expect(v.summaryTitle, 'Lương');
      expect(v.summaryGlyph, categoryGlyph('Lương'));
      expect(v.amount, 12000000); // giữ dấu — màn thêm `+` teal.
      expect(v.singleWalletName, 'Vietcombank');
      expect(v.sourceWalletName, isNull);
      expect(v.note, 'Lương tháng 8');
    });

    test('chi: tiền âm, tên danh mục giữ chuỗi "cha · con" (acceptance 1/5)', () {
      final all = [
        txn(1, 1, TxnType.expense, -85000,
            category: 'Ăn uống · Ăn ngoài',
            note: 'Ăn trưa cùng đồng nghiệp',
            tags: 'côngty, ăn trưa',
            location: '123 Láng Hạ, Đống Đa, Hà Nội',
            date: DateTime(2026, 9, 3, 12, 15)),
      ];
      final v = build(all, const TransactionDetailRef(transactionId: 1))!;

      expect(v.type, TxnType.expense);
      expect(v.amount, -85000);
      // Tên danh mục chi tiết hiển thị đúng chuỗi cha·con lưu (R5).
      expect(v.summaryTitle, 'Ăn uống · Ăn ngoài');
      expect(v.singleWalletName, 'Tiền mặt');
      expect(v.tags, ['côngty', 'ăn trưa']);
      expect(v.location, '123 Láng Hạ, Đống Đa, Hà Nội');
    });

    test('category rỗng → summaryTitle = typeLabel, glyph fallback', () {
      final all = [txn(9, 2, TxnType.income, 500000, note: 'Lì xì')];
      final v = build(all, const TransactionDetailRef(transactionId: 9))!;

      expect(v.summaryTitle, 'Thu');
      expect(v.summaryGlyph, Icons.receipt_long); // categoryGlyph('Thu') fallback.
    });

    test('ref không khớp dòng nào → null (màn báo trạng thái)', () {
      final all = [txn(1, 1, TxnType.expense, -85000)];
      expect(
        build(all, const TransactionDetailRef(transactionId: 999)),
        isNull,
      );
      expect(
        build(const [], const TransactionDetailRef(transactionId: 1)),
        isNull,
      );
    });
  });

  group('transfer — gộp 2 vế theo group (FR-006/SC-005)', () {
    test('đủ 2 vế → 1 view: nguồn/đích đúng chiều, |amount|, nhãn trung tính', () {
      final all = [
        txn(1, 1, TxnType.expense, -85000),
        txn(8, 2, TxnType.transfer, -700000, group: 8,
            note: 'Chuyển sang Momo', date: DateTime(2026, 9, 2)),
        txn(11, 4, TxnType.transfer, 700000, group: 8,
            note: 'Chuyển sang Momo', date: DateTime(2026, 9, 2)),
      ];
      final v = build(all, const TransactionDetailRef(transferGroupId: 8))!;

      expect(v.type, TxnType.transfer);
      expect(v.summaryTitle, 'Chuyển khoản'); // không tên danh mục thu/chi.
      expect(v.summaryGlyph, Icons.swap_horiz);
      expect(v.amount, 700000); // abs, không dấu.
      expect(v.sourceWalletName, 'Vietcombank'); // vế âm = nguồn.
      expect(v.destWalletName, 'Momo'); // vế dương = đích.
      expect(v.singleWalletName, isNull);
      expect(v.note, 'Chuyển sang Momo');
      expect(v.date, DateTime(2026, 9, 2));
    });

    test('nhóm thiếu vế → fallback view đơn không crash (edge)', () {
      final all = [
        txn(6, 2, TxnType.transfer, -999000, group: 60),
        txn(1, 1, TxnType.expense, -85000),
      ];
      final v = build(all, const TransactionDetailRef(transferGroupId: 60))!;

      expect(v.type, TxnType.transfer);
      expect(v.amount, 999000);
      expect(v.singleWalletName, 'Vietcombank'); // vế tìm được duy nhất.
      expect(v.sourceWalletName, isNull);
    });

    test('group không có bất kỳ vế nào → null', () {
      final all = [txn(1, 1, TxnType.expense, -85000)];
      expect(
        build(all, const TransactionDetailRef(transferGroupId: 999)),
        isNull,
      );
    });
  });

  group('adjustment — trung tính như transfer (FR-004, edge)', () {
    test('nhãn typeLabel + glyph tune + |amount| không dấu', () {
      final all = [
        txn(7, 2, TxnType.adjustment, -3000, note: 'Điều chỉnh phí'),
      ];
      final v = build(all, const TransactionDetailRef(transactionId: 7))!;

      expect(v.type, TxnType.adjustment);
      expect(v.summaryTitle, 'Điều chỉnh số dư');
      expect(v.summaryGlyph, Icons.tune);
      expect(v.amount, 3000); // abs — không dấu, không màu thu/chi.
      expect(v.singleWalletName, 'Vietcombank');
    });
  });

  group('ẩn hàng rỗng — field trống → view không chứa dữ liệu dòng đó (FR-007)', () {
    test('note/tags/receiptImage/location rỗng → giá trị rỗng (màn tự ẩn)', () {
      final all = [txn(2, 2, TxnType.expense, -45000, category: 'Xăng xe')];
      final v = build(all, const TransactionDetailRef(transactionId: 2))!;

      expect(v.note, '');
      expect(v.tags, isEmpty);
      expect(v.receiptImage, '');
      expect(v.location, '');
    });

    test('có dữ liệu → map đủ lên view (tags list, image path)', () {
      final all = [
        txn(1, 1, TxnType.expense, -85000, tags: 'côngty',
            receiptImage: '/tmp/hoa-don.jpg', location: 'Láng Hạ'),
      ];
      final v = build(all, const TransactionDetailRef(transactionId: 1))!;

      expect(v.tags, ['côngty']);
      expect(v.receiptImage, '/tmp/hoa-don.jpg');
      expect(v.location, 'Láng Hạ');
    });
  });

  group('parseTags — split `,`, trim, bỏ rỗng (R4)', () {
    test('nhiều tag + khoảng trắng → trim từng tag', () {
      expect(parseTags('côngty,ăntrưa'), ['côngty', 'ăntrưa']);
      expect(parseTags(' côngty ,  ăn trưa , '), ['côngty', 'ăn trưa']);
    });

    test('rỗng / chỉ phẩy → []', () {
      expect(parseTags(''), isEmpty);
      expect(parseTags('   '), isEmpty);
      expect(parseTags(',,'), isEmpty);
      expect(parseTags('côngty,,'), ['côngty']);
    });
  });
}
