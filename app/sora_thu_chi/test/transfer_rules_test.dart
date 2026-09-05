import 'package:flutter_test/flutter_test.dart';

import 'package:sora_thu_chi/core/wallet/transfer_rules.dart';
import 'package:sora_thu_chi/core/wallet/wallet.dart';

Wallet _w(
  int id,
  WalletType type, {
  String currency = 'VND',
  bool isHidden = false,
}) => Wallet(
  id: id,
  name: 'Ví $id',
  type: type,
  icon: '💵',
  balance: 1000000,
  currency: currency,
  isHidden: isHidden,
  sortOrder: id,
);

/// Bộ ví mẫu tĩnh giống seed mặc định: cash(1), bank(2), credit(3), ewallet(4),
/// savings ẩn(5).
final List<Wallet> _wallets = [
  _w(1, WalletType.cash),
  _w(2, WalletType.bank),
  _w(3, WalletType.credit),
  _w(4, WalletType.eWallet),
  _w(5, WalletType.savings, isHidden: true),
];

void main() {
  group('eligibleDestinations — lọc ví đích hợp lệ', () {
    test('loại thẻ tín dụng, ví ẩn và chính ví nguồn (spec acceptance 2)', () {
      // Nguồn Vietcombank (id 2): chỉ còn Tiền mặt + Momo hợp lệ.
      final result = eligibleDestinations(_wallets, 2);
      expect(result.map((w) => w.id), [1, 4]);
    });

    test('loại ví khác tiền tệ với ví nguồn (FR-003/019)', () {
      final list = [..._wallets, _w(6, WalletType.bank, currency: 'USD')];

      // Nguồn USD bank (id 6): đích là ví USD hoạt động, không phải credit/ẩn.
      final usdOnly = eligibleDestinations(list, 6);
      expect(usdOnly.map((w) => w.id), isEmpty);

      // Nguồn VND: ví USD không xuất hiện trong danh sách đích.
      final vnd = eligibleDestinations(list, 2);
      expect(vnd.map((w) => w.id).contains(6), isFalse);
    });

    test('nguồn là ví ẩn đang xem ở chi tiết vẫn có đích (spec §Giả định)', () {
      // Sổ tiết kiệm (id 5) dù ẩn vẫn là nguồn hợp lệ khi đứng từ chi tiết.
      final result = eligibleDestinations(_wallets, 5);
      expect(result.map((w) => w.id), [1, 2, 4]);
    });

    test('không tìm thấy ví nguồn → danh sách rỗng (an toàn)', () {
      expect(eligibleDestinations(_wallets, 99), isEmpty);
    });
  });

  group('canTransferFromWallet — nguồn không phải thẻ tín dụng (FR-018)', () {
    test('thẻ tín dụng → false', () {
      expect(canTransferFromWallet(_w(3, WalletType.credit)), isFalse);
    });

    test('cash/bank/ewallet/savings (kể cả ẩn) → true (acceptance 10)', () {
      expect(canTransferFromWallet(_w(1, WalletType.cash)), isTrue);
      expect(canTransferFromWallet(_w(2, WalletType.bank)), isTrue);
      expect(canTransferFromWallet(_w(4, WalletType.eWallet)), isTrue);
      expect(
        canTransferFromWallet(_w(5, WalletType.savings, isHidden: true)),
        isTrue,
      );
    });
  });

  group('hasEligibleDestination — còn ví đích không (FR-019)', () {
    test('chỉ 1 ví hoạt động → false (spec biên)', () {
      expect(hasEligibleDestination([_w(1, WalletType.cash)], 1), isFalse);
    });

    test('ví active còn lại toàn thẻ tín dụng → false', () {
      final list = [_w(1, WalletType.cash), _w(2, WalletType.credit)];
      expect(hasEligibleDestination(list, 1), isFalse);
    });

    test('có ví đích hợp lệ → true', () {
      expect(hasEligibleDestination(_wallets, 2), isTrue);
    });
  });
}
